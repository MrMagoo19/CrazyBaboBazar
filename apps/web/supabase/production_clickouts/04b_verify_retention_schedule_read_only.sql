-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 04b NACHPRUEFUNG DER RETENTION-PLANUNG
-- ============================================================================
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 04a.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE, keine
--      Rechtevergabe, kein CALL, kein DO-Block, keine Transaktionssteuerung,
--      kein cron.schedule und kein cron.unschedule. Nichts wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu.
--   4. Fehlt pg_cron vollstaendig, scheitert das Statement bewusst hart mit
--      `schema "cron" does not exist` bzw. `relation "cron.job" does not
--      exist`. Das ist der gewollte fail-closed Ausgang — genau wie in 03, wenn
--      public.click_outs fehlt. Ein Report, der eine fehlende Planung als
--      hoefliche Zeile meldet, waere hier die schlechtere Antwort.
--   5. Bei IRGENDEINEM FAIL: nichts nachplanen, nichts korrigieren, nichts
--      abbestellen. Befund melden und Ursache klaeren. Insbesondere NICHT
--      04a "nochmal drueberlaufen lassen" — 04a bricht bei Drift ohnehin ab.
--
-- ERWARTETES ERGEBNIS: 16 Zeilen — 9 harte PASS-Zeilen (Sortierung 30 bis 110)
-- und 7 INFO-Zeilen (10, 20, 200 bis 240).
--
-- DIE DREI SOLL-WERTE stehen wortgleich in 04a_schedule_retention.sql und in
-- 05_rollback.sql. Der lokale Harness prueft diese Gleichheit statisch.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon AUSSERHALB von Text-Literalen, am Dateiende. Anders als
-- 01 und 03 enthaelt hier EIN Text-Literal ein Semikolon: der zu pruefende
-- Command `select cbb_private_analytics.purge_click_outs(12);`. Das ist
-- unvermeidbar — es ist der exakte Wert in cron.job.command, und ein
-- Vergleich gegen eine gekuerzte Fassung waere kein Vergleich. Der statische
-- Test entfernt Text-Literale, bevor er Semikolons zaehlt; die Aussage "genau
-- ein Statement" bleibt damit pruefbar. Trenner in Ausgabetexten ist ' | '.
-- Es kommen ausschliesslich lesende Konstrukte vor (with, select, values, from,
-- join, cross join, where, filter, case, union all, order by, limit) sowie die
-- lesenden Katalogfunktionen to_regclass und oidvectortypes.
-- ============================================================================

with
soll as (
  select
    'cbb-click-outs-retention-12m'::text as soll_name,
    '15 3 * * *'::text as soll_schedule,
    'select cbb_private_analytics.purge_click_outs(12);'::text as soll_command
),

-- ---------------------------------------------------------------------------
-- Der eine Job, um den es geht. Diese CTE kann 0, 1 oder mehr Zeilen liefern
-- und wird deshalb ausschliesslich in Skalar-Unterabfragen benutzt, nie
-- cross-gejoint.
-- ---------------------------------------------------------------------------
job_row as (
  select j.jobid, j.schedule, j.command, j.database, j.username, j.active,
         j.nodename, j.nodeport
  from cron.job j
  cross join soll s
  where j.jobname::text = s.soll_name
),

-- ---------------------------------------------------------------------------
-- Nutzbarkeit von pg_cron (Pruefung 1)
-- Geprueft wird die API, die 04a und 05 tatsaechlich benutzen. Die
-- Extensionszeile selbst ist eine INFO-Zeile: sie ist auf Production der
-- Beleg dafuer, dass die Jobs auch wirklich von pg_cron ausgefuehrt werden.
-- ---------------------------------------------------------------------------
cron_api as (
  select
    (to_regclass('cron.job') is not null) as job_relation,
    (to_regclass('cron.job_run_details') is not null) as run_relation,
    (select count(*)
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'cron' and p.proname = 'schedule'
       and oidvectortypes(p.proargtypes) = 'text, text, text')::integer
      as schedule_funktion,
    (select count(*)
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'cron' and p.proname = 'unschedule'
       and oidvectortypes(p.proargtypes) = 'bigint')::integer
      as unschedule_funktion,
    (select count(*) from pg_extension where extname = 'pg_cron')::integer
      as cron_extension
),

-- ---------------------------------------------------------------------------
-- Das Ziel der Planung (Pruefung 2)
-- Ein Job ohne Funktion waere ein Job, der jede Nacht scheitert.
-- ---------------------------------------------------------------------------
ziel_state as (
  select
    (select count(*)
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
       and oidvectortypes(p.proargtypes) = 'integer')::integer
      as purge_funktionen,
    (to_regclass('public.click_outs') is not null) as tabelle_da
),

-- ---------------------------------------------------------------------------
-- Zustand des Jobs (Pruefungen 3 bis 8)
-- ---------------------------------------------------------------------------
job_state as (
  select
    (select count(*) from job_row)::integer as namensgleiche,
    (select count(*) from cron.job j where j.command like '%purge_click_outs%')::integer
      as purge_jobs,
    (select count(*) from cron.job j)::integer as jobs_gesamt,
    coalesce((select bool_and(r.active) from job_row r), false) as aktiv,
    coalesce((select string_agg(r.jobid::text, ' | ' order by r.jobid) from job_row r), 'keine')
      as ist_jobid,
    coalesce((select string_agg(r.schedule, ' | ' order by r.jobid) from job_row r), 'keiner')
      as ist_schedule,
    coalesce((select string_agg(r.command, ' | ' order by r.jobid) from job_row r), 'keiner')
      as ist_command,
    coalesce((select string_agg(r.database, ' | ' order by r.jobid) from job_row r), 'keine')
      as ist_datenbank,
    coalesce((select string_agg(r.username, ' | ' order by r.jobid) from job_row r), 'keine')
      as ist_username,
    coalesce((select string_agg(r.nodename || ':' || r.nodeport::text, ' | ' order by r.jobid)
              from job_row r), 'keiner') as ist_knoten
),

-- ---------------------------------------------------------------------------
-- Laufhistorie (Pruefung 9 und INFO)
-- Direkt nach 04a ist die Historie erwartungsgemaess LEER. Genau deshalb ist
-- "0 fehlgeschlagene Laeufe" die harte Zeile und "es gab ueberhaupt Laeufe"
-- eine INFO-Zeile: eine leere Historie ist kein Fehler, aber auch kein Beleg.
-- Der Pre-enable-Gate im Runbook verlangt darum eine spaetere, protokollierte
-- Kontrolle dieser Zeilen — nicht nur einen gruenen Lauf am Einrichtungstag.
-- ---------------------------------------------------------------------------
run_state as (
  select
    (select count(*)
     from cron.job_run_details d
     join job_row r on r.jobid = d.jobid)::bigint as laeufe,
    (select count(*)
     from cron.job_run_details d
     join job_row r on r.jobid = d.jobid
     where d.status = 'failed')::bigint as fehlgeschlagen,
    (select count(*)
     from cron.job_run_details d
     join job_row r on r.jobid = d.jobid
     where d.status = 'succeeded')::bigint as erfolgreich,
    coalesce((select max(d.start_time)::text
              from cron.job_run_details d
              join job_row r on r.jobid = d.jobid), 'keiner') as letzter_lauf,
    coalesce((select d.status
              from cron.job_run_details d
              join job_row r on r.jobid = d.jobid
              order by d.start_time desc nulls last, d.runid desc
              limit 1), 'keiner') as letzter_status,
    coalesce((select d.return_message
              from cron.job_run_details d
              join job_row r on r.jobid = d.jobid
              where d.status = 'failed'
              order by d.start_time desc nulls last, d.runid desc
              limit 1), 'keine') as letzte_meldung
),

-- Jede der obigen CTEs ausser job_row liefert genau eine Zeile.
summary as (
  select *
  from soll
  cross join cron_api
  cross join ziel_state
  cross join job_state
  cross join run_state
),

checks as (
  select
    10 as sortierung,
    'current_user'::text as pruefung,
    current_user::text as ist,
    'INFO'::text as erwartet,
    'INFO'::text as status
  union all
  select 20, 'current_database', current_database()::text, 'INFO', 'INFO'
  union all
  -- 1
  select 30, 'cron_api_nutzbar',
    'cron.job ' || job_relation::text
      || ' | cron.job_run_details ' || run_relation::text
      || ' | cron.schedule ' || schedule_funktion::text
      || ' | cron.unschedule ' || unschedule_funktion::text,
    'alle vorhanden | cron.schedule 1 | cron.unschedule 1',
    case when job_relation and run_relation
           and schedule_funktion = 1 and unschedule_funktion = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'loeschpfad_vorhanden',
    'purge_click_outs(integer) ' || purge_funktionen::text
      || ' | public.click_outs ' || tabelle_da::text,
    'purge_click_outs(integer) 1 | public.click_outs true',
    case when purge_funktionen = 1 and tabelle_da then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'retention_job_genau_einmal',
    namensgleiche::text || ' Job(s) namens ' || soll_name,
    'genau 1',
    case when namensgleiche = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'retention_job_aktiv', aktiv::text, 'true',
    case when namensgleiche = 1 and aktiv is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'retention_job_schedule', ist_schedule, soll_schedule,
    case when namensgleiche = 1 and ist_schedule = soll_schedule
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'retention_job_command', ist_command, soll_command,
    case when namensgleiche = 1 and ist_command = soll_command
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'retention_job_datenbank', ist_datenbank, current_database()::text,
    case when namensgleiche = 1 and ist_datenbank = current_database()::text
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'kein_zweiter_loeschjob',
    purge_jobs::text || ' Job(s) rufen purge_click_outs auf | '
      || jobs_gesamt::text || ' Job(s) insgesamt eingetragen',
    'genau 1 Job ruft purge_click_outs auf',
    case when purge_jobs = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'retention_job_ohne_fehlgeschlagene_laeufe',
    fehlgeschlagen::text || ' fehlgeschlagen von ' || laeufe::text
      || ' | letzte Fehlermeldung: ' || letzte_meldung,
    '0 fehlgeschlagen',
    case when namensgleiche = 1 and fehlgeschlagen = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 200, 'job_kennung',
    'jobid ' || ist_jobid || ' | username ' || ist_username
      || ' | knoten ' || ist_knoten,
    'INFO: reine Beobachtung', 'INFO'
  from summary
  union all
  select 210, 'laufhistorie',
    laeufe::text || ' Lauf/Laeufe | ' || erfolgreich::text || ' erfolgreich | '
      || fehlgeschlagen::text || ' fehlgeschlagen | letzter Lauf ' || letzter_lauf
      || ' | letzter Status ' || letzter_status,
    'INFO: direkt nach 04a erwartungsgemaess 0 Laeufe. Der Pre-enable-Gate verlangt eine spaetere, protokollierte Kontrolle dieser Zeile',
    'INFO'
  from summary
  union all
  select 220, 'pg_cron_extension', cron_extension::text,
    'INFO: auf Production muss hier 1 stehen. 0 heisst, dass cron.job zwar existiert, die Jobs aber von niemandem ausgefuehrt werden — dann ist der Gate NICHT erfuellt',
    'INFO'
  from summary
  union all
  select 230, 'zielprojekt', 'ydiihvzcxaaoqhmgoqvu',
    'INFO: vor jedem Schritt sichtbar im SQL-Editor gegenpruefen', 'INFO'
  from summary
  union all
  select 240, 'gate_hinweis',
    'vorbereitet ist nicht eingerichtet',
    'INFO: ein FAIL-freier Lauf dieser Datei erfuellt den Pre-enable-Gate allein NOCH NICHT. Es fehlt die spaetere, im Runbook protokollierte Kontrolle der Job-History',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
