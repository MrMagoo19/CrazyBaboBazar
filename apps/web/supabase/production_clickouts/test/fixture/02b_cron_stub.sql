-- ============================================================================
-- FIXTURE 02b — pg_cron-kompatible Nachbildung (NUR fuer den lokalen Harness)
-- ============================================================================
-- WARUM EINE NACHBILDUNG UND KEINE ECHTE EXTENSION:
--   pg_cron ist eine kompilierte Erweiterung mit Hintergrundprozess. Sie laesst
--   sich in einem wegwerfbaren Cluster ohne Paketinstallation nicht anlegen —
--   und selbst dort wuerde sie einen Scheduler starten, den ein Test nicht
--   haben will. Diese Datei bildet deshalb genau den Teil nach, den
--   04a_schedule_retention.sql, 04b_verify_retention_schedule_read_only.sql und
--   05_rollback.sql tatsaechlich benutzen:
--     * cron.job                                   (Katalog der Jobs)
--     * cron.job_run_details                       (Laufhistorie)
--     * cron.schedule(text, text, text) -> bigint  (anlegen/ueberschreiben)
--     * cron.unschedule(bigint)         -> boolean (abbestellen)
--     * cron.unschedule(text)           -> boolean (abbestellen ueber Namen)
--
-- WAS SIE NACHBILDET UND WAS AUSDRUECKLICH NICHT:
--   Nachgebildet ist die Katalogform (Spaltennamen, Spaltentypen, der
--   eindeutige Index auf (jobname, username)) und — der eigentliche Grund
--   dieser Datei — das UEBERSCHREIB-VERHALTEN von cron.schedule: ein zweiter
--   Aufruf mit demselben Jobnamen legt KEINEN zweiten Job an, sondern ersetzt
--   den vorhandenen. Genau davor schuetzt der Vorab-Guard in 04a, und genau das
--   muss der Harness ausloesen koennen.
--   NICHT nachgebildet ist die Ausfuehrung: hier laeuft nichts zu irgendeiner
--   Zeit. Laufhistorie entsteht im Test ausschliesslich durch
--   cases/setup_seed_job_runs.sql. Ein gruener Harness belegt deshalb die
--   Planung und ihre Guards, NICHT dass auf Production tatsaechlich geloescht
--   wird — das belegt allein die protokollierte Kontrolle der echten
--   Job-History (RUNBOOK Abschnitt 7).
--
-- ABGRENZUNG ZU PRODUCTION: dort steht in pg_extension eine Zeile fuer
-- pg_cron. Hier nicht — pg_extension laesst sich ohne echte Extension nicht
-- befuellen. 04b meldet diesen Unterschied als INFO-Zeile `pg_cron_extension`
-- (lokal 0, auf Production muss dort 1 stehen). Der Pre-enable-Gate im Runbook
-- verlangt genau deshalb den Blick auf diese Zeile am echten Ziel.
-- ============================================================================

create schema cron;

-- Spaltensatz und Typen wie in pg_cron: jobname ist `name`, nicht `text`.
-- Die Originaldateien vergleichen darum ueberall ueber `jobname::text`.
create table cron.job (
  jobid    bigserial primary key,
  schedule text not null,
  command  text not null,
  nodename text not null default 'localhost',
  nodeport integer not null default 5432,
  database text not null default current_database(),
  username text not null default current_user,
  active   boolean not null default true,
  jobname  name
);

-- Der eindeutige Index ist der Grund, warum ein gleichnamiger zweiter Job
-- ueberschreibt statt zu koexistieren.
create unique index job_jobname_username_uniq on cron.job (jobname, username);

create table cron.job_run_details (
  jobid          bigint not null,
  runid          bigserial primary key,
  job_pid        integer,
  database       text,
  username       text,
  command        text,
  status         text,
  return_message text,
  start_time     timestamptz,
  end_time       timestamptz
);

-- ---------------------------------------------------------------------------
-- cron.schedule — legt an ODER ueberschreibt den gleichnamigen Job.
-- Die Parameter heissen in pg_cron job_name, schedule, command. Hier tragen sie
-- ein p_-Praefix, damit sie in PL/pgSQL nicht mit den gleichnamigen Spalten
-- kollidieren. Die Parameternamen sind dabei egal: 04a/04b pruefen die Signatur
-- ueber oidvectortypes(p.proargtypes), also rein ueber die Typenliste
-- 'text, text, text'. Die Signatur bleibt (text, text, text) -> bigint.
-- Aufgerufen wird ausschliesslich positionell.
-- ---------------------------------------------------------------------------
create function cron.schedule(p_job_name text, p_schedule text, p_command text)
returns bigint
language plpgsql
as $fn$
declare
  neue_id bigint;
begin
  insert into cron.job (jobname, schedule, command, database, username, active)
  values (p_job_name, p_schedule, p_command, current_database(), current_user, true)
  on conflict (jobname, username) do update
    set schedule = excluded.schedule,
        command  = excluded.command,
        database = excluded.database,
        active   = true
  returning jobid into neue_id;

  return neue_id;
end $fn$;

-- ---------------------------------------------------------------------------
-- cron.unschedule — pg_cron scheitert hart, wenn der Job nicht existiert.
-- Die Laufhistorie bleibt bewusst stehen, genau wie im Original.
-- ---------------------------------------------------------------------------
create function cron.unschedule(p_job_id bigint)
returns boolean
language plpgsql
as $fn$
declare
  weg integer;
begin
  delete from cron.job where jobid = p_job_id;
  get diagnostics weg = row_count;
  if weg = 0 then
    raise exception 'could not find valid entry for job %', p_job_id;
  end if;
  return true;
end $fn$;

create function cron.unschedule(p_job_name text)
returns boolean
language plpgsql
as $fn$
declare
  weg integer;
begin
  delete from cron.job where jobname = p_job_name and username = current_user;
  get diagnostics weg = row_count;
  if weg = 0 then
    raise exception 'could not find valid entry for job %', p_job_name;
  end if;
  return true;
end $fn$;

-- Wie auf Supabase: das Schema gehoert nicht den App-Rollen.
revoke all on schema cron from public, anon, authenticated;
revoke all on all tables in schema cron from public, anon, authenticated;
