-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 04a RETENTION-PLANUNG (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene, ausdrueckliche Benutzerfreigabe und sichtbare
-- Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Erst nach FAIL-freiem 03_verify_read_only.sql ausfuehren.
--
-- WAS DIESE DATEI TUT: sie traegt GENAU EINEN wiederkehrenden pg_cron-Job ein,
-- der den einzigen Loeschpfad der Tabelle aufruft.
--
--   Jobname:   cbb-click-outs-retention-12m
--   Schedule:  15 3 * * *        (taeglich 03:15 UTC)
--   Command:   select cbb_private_analytics.purge_click_outs(12);
--
-- Die drei Werte sind hier die Quelle. Dieselben drei Werte stehen wortgleich in
-- 04b_verify_retention_schedule_read_only.sql, in 05_rollback.sql und im
-- RUNBOOK. Der lokale Harness prueft diese Gleichheit statisch — eine
-- Abweichung an einer Stelle faellt damit auf, statt still zu driften.
--
-- WARUM TAEGLICH UND NICHT MONATLICH: der Job loescht ausschliesslich Zeilen
-- jenseits der 12-Monats-Grenze. Taeglich heisst deshalb nicht "mehr Loeschung",
-- sondern "die zugesagte Frist ist hoechstens einen Tag ueberschritten, nicht
-- hoechstens einen Monat". Ein ausgefallener Lauf wird ausserdem am naechsten
-- Tag von selbst nachgeholt, ohne dass jemand eingreift. Die Uhrzeit 03:15 UTC
-- liegt ausserhalb der Lastspitzen und bewusst nicht auf einer vollen Stunde.
--
-- WAS SIE NICHT TUT: sie loescht selbst keine einzige Zeile, legt keine Struktur
-- an, aendert keine Rechte, fasst weder Produktdaten noch die Value-Add-
-- Artefakte v1/v2 an. Sie schreibt genau eine Zeile in cron.job.
--
-- WIEDERHOLUNGSVERHALTEN — und warum das hier eine harte Pruefung braucht:
--   `cron.schedule(jobname, schedule, command)` legt bei einem BEREITS
--   VORHANDENEN gleichnamigen Job KEINEN zweiten Job an, sondern ueberschreibt
--   den vorhandenen (dokumentiertes Verhalten laut Supabase-Cron-Quickstart).
--   Ein blindes cron.schedule waere damit kein "idempotenter Rollout", sondern
--   ein stiller Ueberschreiber: ein fremder oder veraenderter Job mit demselben
--   Namen verschwaende spurlos.
--   Deshalb prueft diese Datei VOR dem Schreiben:
--     * Job existiert nicht            -> genau einen anlegen
--     * Job existiert und ist exakt der unsrige (Schedule, Command, Datenbank,
--       aktiv)                         -> NO-OP mit NOTICE, kein Schreibvorgang
--     * Job existiert, weicht aber ab  -> ABBRUCH (Drift), nichts wird geaendert
--     * Name kommt mehrfach vor        -> ABBRUCH, nichts wird geaendert
--     * ein anders benannter Job ruft purge_click_outs auf -> ABBRUCH
--   Ein Abbruch rollt die Transaktion vollstaendig zurueck. Es bleibt in keinem
--   Fall ein halb eingerichteter Zustand zurueck.
--
-- VERHAELTNIS ZU 04_retention.sql: 04 bleibt der manuelle, einzeln
-- freizugebende Loeschlauf. 04a ersetzt ihn nicht, sondern automatisiert
-- denselben Aufruf. Beide gehen durch dieselbe Funktion — es gibt weiterhin nur
-- einen Loeschpfad.
--
-- DATENSCHUTZ-BEZUG: die 12 Monate sind keine freie Wahl. Genau diese Frist
-- steht in der Datenschutzerklaerung (apps/web/app/datenschutz, Abschnitt 6).
-- Wird die Zahl hier geaendert, MUSS sie dort im selben Schritt mitgeaendert
-- werden — und umgekehrt.
--
-- PRE-ENABLE-GATE (RUNBOOK Abschnitt 7): diese Datei ALLEIN erfuellt das Gate
-- NICHT. Vorbereitet ist nicht eingerichtet. Erfuellt ist es erst, wenn
--   1. diese Datei auf Production ausgefuehrt wurde,
--   2. 04b_verify_retention_schedule_read_only.sql dort FAIL-frei laeuft und
--   3. die Job-History spaeter mindestens einmal nachweislich kontrolliert und
--      im Runbook protokolliert wurde.
-- Bis dahin bleibt SUPABASE_SERVICE_ROLE_KEY in Vercel ungesetzt.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen erste Abfrage fasst public.products an und wuerde sonst
-- mit dem Session-Default lock_timeout = 0 unbegrenzt auf einen konkurrierenden
-- AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  soll_name     constant text := 'cbb-click-outs-retention-12m';
  soll_schedule constant text := '15 3 * * *';
  soll_command  constant text := 'select cbb_private_analytics.purge_click_outs(12);';

  produkte          bigint;
  purge_funktionen  integer;
  cron_funktionen   integer;
  cron_extension    integer;
  namensgleiche     integer;
  fremde_purge_jobs integer;

  ist_jobid     bigint;
  ist_schedule  text;
  ist_command   text;
  ist_datenbank text;
  ist_aktiv     boolean;

  neu_jobid  bigint;
  kontrolle  integer;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung: Production-Fingerprint, keine Pilot-Artefakte
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Retention-Planung abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Retention-Planung abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into produkte from public.products;
  if produkte < 300 then
    raise exception 'Retention-Planung abgebrochen: nur % Produkte (< 300).', produkte;
  end if;

  -- ---------------------------------------------------------------------
  -- Das zu planende Ziel muss existieren. Ein Job auf eine fehlende Funktion
  -- waere ein Job, der jede Nacht scheitert — und eine Frist, die niemand
  -- durchsetzt.
  -- ---------------------------------------------------------------------
  if to_regclass('public.click_outs') is null then
    raise exception 'Retention-Planung abgebrochen: public.click_outs fehlt.';
  end if;

  select count(*) into purge_funktionen
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'cbb_private_analytics'
    and p.proname = 'purge_click_outs'
    and oidvectortypes(p.proargtypes) = 'integer';
  if purge_funktionen <> 1 then
    raise exception 'Retention-Planung abgebrochen: cbb_private_analytics.purge_click_outs(integer) fehlt (% gefunden).',
      purge_funktionen;
  end if;

  -- ---------------------------------------------------------------------
  -- pg_cron muss nutzbar sein. Geprueft wird die API, die diese Datei und
  -- 05_rollback.sql tatsaechlich benutzen — nicht nur ein Extensionseintrag.
  -- Alle spaeteren Zugriffe auf cron.job liegen HINTER dieser Pruefung; ohne
  -- pg_cron wird kein einziger davon je geplant.
  -- ---------------------------------------------------------------------
  if to_regclass('cron.job') is null or to_regclass('cron.job_run_details') is null then
    raise exception 'Retention-Planung abgebrochen: pg_cron ist nicht nutzbar (cron.job oder cron.job_run_details fehlt).';
  end if;

  select count(*) into cron_funktionen
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'cron'
    and (
      (p.proname = 'schedule'   and oidvectortypes(p.proargtypes) = 'text, text, text')
      or
      (p.proname = 'unschedule' and oidvectortypes(p.proargtypes) = 'bigint')
    );
  if cron_funktionen <> 2 then
    raise exception 'Retention-Planung abgebrochen: pg_cron ist nicht nutzbar — cron.schedule/3 und cron.unschedule/1 ergeben zusammen % statt 2.',
      cron_funktionen;
  end if;

  select count(*) into cron_extension from pg_extension where extname = 'pg_cron';
  raise notice 'Retention-Planung: Ziel project/ydiihvzcxaaoqhmgoqvu | Datenbank % | Rolle % | pg_cron als Extension registriert: % (auf Production muss hier 1 stehen).',
    current_database(), current_user, cron_extension;

  -- ---------------------------------------------------------------------
  -- Vorzustand. cron.schedule wuerde einen gleichnamigen Job UEBERSCHREIBEN —
  -- deshalb wird hier entschieden und nicht dort.
  -- ---------------------------------------------------------------------
  select count(*) into namensgleiche
  from cron.job j
  where j.jobname::text = soll_name;

  if namensgleiche > 1 then
    raise exception 'Retention-Planung abgebrochen: doppelter Jobname. % Eintraege heissen % — cron.schedule wuerde einen davon still ueberschreiben. Zustand erst klaeren, nichts wurde geaendert.',
      namensgleiche, soll_name;
  end if;

  select count(*) into fremde_purge_jobs
  from cron.job j
  where j.jobname::text is distinct from soll_name
    and j.command like '%purge_click_outs%';
  if fremde_purge_jobs <> 0 then
    raise exception 'Retention-Planung abgebrochen: fremder purge_click_outs-Job. % Job(s) rufen die Loeschfunktion unter anderem Namen auf. Zwei Planungen fuer denselben Loeschpfad sind nicht gewollt, nichts wurde geaendert.',
      fremde_purge_jobs;
  end if;

  if namensgleiche = 1 then
    select j.jobid, j.schedule, j.command, j.database, j.active
      into ist_jobid, ist_schedule, ist_command, ist_datenbank, ist_aktiv
    from cron.job j
    where j.jobname::text = soll_name;

    if ist_schedule is distinct from soll_schedule
       or ist_command is distinct from soll_command
       or ist_datenbank is distinct from current_database()::text
       or ist_aktiv is distinct from true then
      raise exception 'Retention-Planung abgebrochen: Drift. Job % (jobid %) ist eingetragen als schedule <%>, command <%>, datenbank <%>, aktiv <%>. Erwartet: schedule <%>, command <%>, datenbank <%>, aktiv <true>. Nichts wurde geaendert.',
        soll_name, ist_jobid, ist_schedule, ist_command, ist_datenbank, ist_aktiv,
        soll_schedule, soll_command, current_database();
    end if;

    raise notice 'Retention-Planung: Job % (jobid %) ist bereits exakt so eingerichtet — kein Schreibvorgang.',
      soll_name, ist_jobid;
  else
    select cron.schedule(soll_name, soll_schedule, soll_command) into neu_jobid;
    raise notice 'Retention-Planung: Job % angelegt (jobid %).', soll_name, neu_jobid;
  end if;

  -- ---------------------------------------------------------------------
  -- Kontrolle INNERHALB derselben Transaktion. Scheitert sie, wird auch der
  -- soeben angelegte Job wieder verworfen.
  -- ---------------------------------------------------------------------
  select count(*) into kontrolle
  from cron.job j
  where j.jobname::text = soll_name
    and j.schedule = soll_schedule
    and j.command = soll_command
    and j.database = current_database()::text
    and j.active is true;
  if kontrolle <> 1 then
    raise exception 'Retention-Planung inkonsistent: % exakt passende(r) Job(s) nach dem Lauf, erwartet genau 1.',
      kontrolle;
  end if;

  select count(*) into kontrolle
  from cron.job j
  where j.jobname::text = soll_name;
  if kontrolle <> 1 then
    raise exception 'Retention-Planung inkonsistent: % Job(s) tragen den Namen % nach dem Lauf, erwartet genau 1.',
      kontrolle, soll_name;
  end if;

  select count(*) into kontrolle
  from cron.job j
  where j.command like '%purge_click_outs%';
  if kontrolle <> 1 then
    raise exception 'Retention-Planung inkonsistent: % Job(s) rufen purge_click_outs auf, erwartet genau 1.',
      kontrolle;
  end if;

  -- Die Planung darf nichts geloescht haben. Loeschen tut ausschliesslich der
  -- Job selbst, zu seiner Zeit, ueber die Funktion.
  if to_regclass('public.click_outs') is null
     or to_regclass('cbb_private_analytics.click_outs_daily') is null then
    raise exception 'Retention-Planung inkonsistent: die Planung hat Struktur veraendert.';
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit. Die ausfuehrliche Nachpruefung
-- ist 04b_verify_retention_schedule_read_only.sql.
select
  j.jobid,
  j.jobname,
  j.schedule,
  j.command,
  j.database,
  j.active
from cron.job j
where j.jobname::text = 'cbb-click-outs-retention-12m';
