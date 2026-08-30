-- Ergaenzt die Historie um einen FEHLGESCHLAGENEN Lauf.
--
-- Ohne diesen Fall waere die harte Zeile
-- `retention_job_ohne_fehlgeschlagene_laeufe` in 04b vakuum-gruen: sie waere
-- nie gegen einen echten Fehlschlag getestet worden und koennte still kaputt
-- sein. Ein stillgelegter Retention-Job ist genau der Zustand, den die
-- Datenschutzerklaerung nicht aushaelt — er muss auffallen.
insert into cron.job_run_details
  (jobid, job_pid, database, username, command, status, return_message, start_time, end_time)
select
  j.jobid, 4713, j.database, j.username, j.command,
  'failed', 'ERROR: canceling statement due to statement timeout',
  now() - interval '4 hours', now() - interval '4 hours' + interval '30 seconds'
from cron.job j
where j.jobname::text = 'cbb-click-outs-retention-12m';

do $$
declare
  schlecht integer;
begin
  select count(*) into schlecht from cron.job_run_details where status = 'failed';
  if schlecht <> 1 then
    raise exception 'Setup kaputt: % fehlgeschlagene(r) Lauf/Laeufe (erwartet 1).', schlecht;
  end if;
end $$;
