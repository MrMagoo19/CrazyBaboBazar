-- Schreibt eine SAUBERE Laufhistorie fuer den eingerichteten Retention-Job:
-- zwei erfolgreiche Laeufe, kein Fehlschlag.
--
-- Warum von Hand: die Nachbildung in fixture/04_cron_stub.sql fuehrt nichts
-- aus. Ohne diese Zeilen bliebe die Laufhistorie im Harness immer leer, und
-- 04b haette die Historien-Zeilen nie an echten Daten gezeigt.
insert into cron.job_run_details
  (jobid, job_pid, database, username, command, status, return_message, start_time, end_time)
select
  j.jobid, 4711, j.database, j.username, j.command,
  'succeeded', 'DELETE 0',
  now() - interval '2 days', now() - interval '2 days' + interval '80 milliseconds'
from cron.job j
where j.jobname::text = 'cbb-click-outs-retention-12m'
union all
select
  j.jobid, 4712, j.database, j.username, j.command,
  'succeeded', 'DELETE 3',
  now() - interval '1 day', now() - interval '1 day' + interval '95 milliseconds'
from cron.job j
where j.jobname::text = 'cbb-click-outs-retention-12m';

do $$
declare
  laeufe integer;
  schlecht integer;
begin
  select count(*) into laeufe from cron.job_run_details;
  select count(*) into schlecht from cron.job_run_details where status = 'failed';
  if laeufe <> 2 or schlecht <> 0 then
    raise exception 'Setup kaputt: % Lauf/Laeufe (erwartet 2), davon % fehlgeschlagen (erwartet 0).',
      laeufe, schlecht;
  end if;
end $$;
