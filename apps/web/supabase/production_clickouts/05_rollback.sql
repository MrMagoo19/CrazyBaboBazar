-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 05 ROLLBACK (SCHREIBEND, DESTRUKTIV)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene, ausdrueckliche Benutzerfreigabe und sichtbare
-- Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WARNUNG — DIESE DATEI IST DESTRUKTIV:
--   Sie entfernt public.click_outs samt aller bereits erfassten Ereignisse,
--   die Auswertungs-View, die Retention-Funktion und das Schema
--   cbb_private_analytics. Es gibt danach KEINE Kopie der Ereignisse. Das ist
--   Absicht: ein Rollback der Klick-out-Messung soll die Daten nicht in ein
--   Schattenarchiv verschieben, sondern beseitigen — sonst waere er datenschutz-
--   rechtlich kein Rollback.
--
--   Wer die Zahlen vorher retten will, exportiert VORHER bewusst die AGGREGATE
--   aus cbb_private_analytics.click_outs_daily. Der Export der Rohereignisse ist
--   ausdruecklich nicht vorgesehen.
--
-- WAS SIE NICHT ANFASST: Produktdaten, page_content, discovery_queue, swipes
-- und saemtliche Value-Add-Artefakte v1/v2. Der Guard-Block prueft das vorab
-- und bricht ab, wenn eines dieser Artefakte fehlt — dann stimmt etwas anderes
-- nicht und ein destruktiver Lauf waere fahrlaessig.
--
-- REIHENFOLGE: erst der geplante Job, dann Funktion, dann View, dann Tabelle,
-- dann Schema. Ohne CASCADE, damit ein unerwartetes abhaengiges Objekt den Lauf
-- stoppt statt stillschweigend mitgerissen zu werden.
--
-- WARUM DER JOB ZUERST GEHT: `cron.job` haengt nicht per Katalog an der
-- Funktion. Ein Drop der Funktion laesst einen eingetragenen Job also
-- unberuehrt zurueck — er wuerde ab dann jede Nacht scheitern und die
-- Fehlerzaehler fuellen, ohne dass irgendetwas darauf hinweist. Deshalb wird
-- ein vorhandener Retention-Job in DERSELBEN Transaktion abbestellt, bevor die
-- Funktion faellt, und danach noch einmal geprueft.
--
--   Jobname:  cbb-click-outs-retention-12m
--   Command:  select cbb_private_analytics.purge_click_outs(12);
--
-- Beide Werte stehen wortgleich in 04a_schedule_retention.sql und in
-- 04b_verify_retention_schedule_read_only.sql. Der lokale Harness prueft diese
-- Gleichheit statisch.
--
-- OHNE pg_cron UND OHNE JOB laeuft der Rollback unveraendert durch: fehlt
-- `cron.job`, wird der Abschnitt uebersprungen und lediglich als NOTICE
-- vermerkt. Trifft der Abschnitt dagegen auf einen GLEICHNAMIGEN Job mit
-- fremdem Command, fremder Datenbank oder auf mehrere gleichnamige Eintraege,
-- bricht er fail-closed ab — ein fremder Job wird hier nicht stillschweigend
-- abbestellt, und die Funktion faellt dann auch nicht.
--
-- VORHER ERLEDIGEN: Die Anwendung darf nicht mehr schreiben. Praktisch heisst
-- das: SUPABASE_SERVICE_ROLE_KEY aus der Vercel-Umgebung entfernen und den
-- Deploy abwarten. Ohne diese Variable ueberspringt der Route-Handler das
-- Logging und leitet unveraendert weiter — es entstehen also keine Fehler,
-- sondern nur keine Daten mehr.
-- ============================================================================

begin;

set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  ereignisse bigint;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Rollback abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Rollback abgebrochen: Production-Fingerprint fehlt.';
  end if;

  -- ---------------------------------------------------------------------
  -- Fremde Artefakte muessen unversehrt sein, sonst wird hier nichts geloescht.
  -- ---------------------------------------------------------------------
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null
     or to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null
     or to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Rollback abgebrochen: ein Value-Add-Artefakt fehlt — Zustand erst klaeren.';
  end if;

  -- ---------------------------------------------------------------------
  -- Es muss ueberhaupt etwas zurueckzurollen geben.
  -- ---------------------------------------------------------------------
  if to_regclass('public.click_outs') is null then
    raise exception 'Rollback abgebrochen: public.click_outs existiert nicht.';
  end if;

  select count(*) into ereignisse from public.click_outs;
  raise notice 'Rollback: % Klick-out-Ereignis(se) werden unwiderruflich entfernt.', ereignisse;
end $$;

-- ---------------------------------------------------------------------------
-- Geplanten Retention-Job abbestellen — VOR dem Drop der Funktion, in
-- DERSELBEN Transaktion. Scheitert irgendetwas weiter unten, ist auch das
-- Abbestellen wieder zurueckgerollt.
--
-- Alle Zugriffe auf cron.job liegen hinter der Verfuegbarkeitspruefung. Ohne
-- pg_cron wird keiner von ihnen je geplant — der Rollback laeuft dann genau so
-- wie vor der Einfuehrung von 04a.
-- ---------------------------------------------------------------------------
do $$
declare
  soll_name    constant text := 'cbb-click-outs-retention-12m';
  soll_command constant text := 'select cbb_private_analytics.purge_click_outs(12);';

  unschedule_funktion integer;
  namensgleiche       integer;
  fremde_purge_jobs   integer;

  job_id        bigint;
  job_command   text;
  job_datenbank text;
  entfernt      boolean;
  rest          integer;
begin
  if to_regclass('cron.job') is null then
    raise notice 'Rollback: pg_cron nicht vorhanden — es gibt keinen Retention-Job abzubestellen.';
    return;
  end if;

  select count(*) into fremde_purge_jobs
  from cron.job j
  where j.jobname::text is distinct from soll_name
    and j.command like '%purge_click_outs%';
  if fremde_purge_jobs <> 0 then
    raise exception 'Rollback abgebrochen: fremder purge_click_outs-Job. % Job(s) rufen die Loeschfunktion unter anderem Namen auf und liefen nach dem Drop ins Leere. Zustand erst klaeren, nichts wurde geloescht.',
      fremde_purge_jobs;
  end if;

  select count(*) into namensgleiche
  from cron.job j
  where j.jobname::text = soll_name;

  if namensgleiche = 0 then
    raise notice 'Rollback: kein Job namens % eingetragen — nichts abzubestellen.', soll_name;
    return;
  end if;
  if namensgleiche > 1 then
    raise exception 'Rollback abgebrochen: doppelter Jobname. % Eintraege heissen % — welcher gemeint ist, ist nicht entscheidbar. Nichts wurde geloescht.',
      namensgleiche, soll_name;
  end if;

  select j.jobid, j.command, j.database
    into job_id, job_command, job_datenbank
  from cron.job j
  where j.jobname::text = soll_name;

  if job_command is distinct from soll_command
     or job_datenbank is distinct from current_database()::text then
    raise exception 'Rollback abgebrochen: Drift. Job % (jobid %) fuehrt <%> in Datenbank <%> aus, erwartet <%> in <%>. Ein fremder Job wird hier nicht stillschweigend abbestellt, nichts wurde geloescht.',
      soll_name, job_id, job_command, job_datenbank, soll_command, current_database();
  end if;

  select count(*) into unschedule_funktion
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'cron'
    and p.proname = 'unschedule'
    and oidvectortypes(p.proargtypes) = 'bigint';
  if unschedule_funktion <> 1 then
    raise exception 'Rollback abgebrochen: cron.unschedule/1 fehlt — der Job % liesse sich nicht sauber abbestellen. Nichts wurde geloescht.',
      soll_name;
  end if;

  -- Abbestellen ueber die jobid, nicht ueber den Namen: die Namensvariante von
  -- pg_cron trifft nur Jobs der aufrufenden Rolle und koennte damit still
  -- danebengreifen.
  select cron.unschedule(job_id) into entfernt;
  if entfernt is not true then
    raise exception 'Rollback abgebrochen: das Abbestellen von jobid % hat kein Ergebnis gemeldet. Nichts wurde geloescht.',
      job_id;
  end if;

  select count(*) into rest
  from cron.job j
  where j.jobname::text = soll_name
     or j.command like '%purge_click_outs%';
  if rest <> 0 then
    raise exception 'Rollback inkonsistent: nach cron.unschedule sind noch % Retention-Job(s) eingetragen.',
      rest;
  end if;

  raise notice 'Rollback: Retention-Job % (jobid %) abbestellt.', soll_name, job_id;
end $$;

-- Funktion zuerst: sie haengt an der Tabelle.
drop function if exists cbb_private_analytics.purge_click_outs(integer);

-- Dann die View.
drop view if exists cbb_private_analytics.click_outs_daily;

-- Dann die Tabelle. Bewusst OHNE CASCADE: gibt es ein unerwartetes abhaengiges
-- Objekt, soll der Lauf hier scheitern und nicht stillschweigend aufraeumen.
drop table public.click_outs;

-- Zum Schluss das Schema. `restrict` ist der Default und bleibt hier explizit
-- stehen, damit ein weiteres Objekt im Schema den Lauf stoppt.
drop schema cbb_private_analytics restrict;

do $$
declare
  cron_reste integer;
begin
  if to_regclass('public.click_outs') is not null then
    raise exception 'Rollback inkonsistent: public.click_outs existiert weiterhin.';
  end if;
  if exists (select 1 from pg_namespace where nspname = 'cbb_private_analytics') then
    raise exception 'Rollback inkonsistent: Schema cbb_private_analytics existiert weiterhin.';
  end if;
  -- Letzter Beleg innerhalb derselben Transaktion: fremde Artefakte leben.
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null
     or to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null
     or to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Rollback inkonsistent: ein Value-Add-Artefakt ist verschwunden.';
  end if;
  -- Kein Job darf auf die soeben geloeschte Funktion zeigen. Ohne diese Zeile
  -- koennte ein uebersehener Eintrag ab jetzt jede Nacht scheitern.
  if to_regclass('cron.job') is not null then
    select count(*) into cron_reste
    from cron.job j
    where j.jobname::text = 'cbb-click-outs-retention-12m'
       or j.command like '%purge_click_outs%';
    if cron_reste <> 0 then
      raise exception 'Rollback inkonsistent: % Job(s) verweisen weiterhin auf die geloeschte Loeschfunktion.',
        cron_reste;
    end if;
  end if;
  raise notice 'Rollback abgeschlossen: Klick-out-Artefakte entfernt, kein Retention-Job mehr eingetragen, Value-Add unangetastet.';
end $$;

commit;
