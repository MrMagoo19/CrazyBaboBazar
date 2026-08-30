-- Nach dem Abbruch steht ausschliesslich der fremde purge-Job da. Kein zweiter
-- Loeschjob wurde danebengelegt.
do $$
declare
  jobs   bigint;
  fremd  integer;
begin
  select count(*) into jobs from cron.job;
  if jobs <> 1 then
    raise exception 'Nach dem Abbruch: % Job(s) im Katalog (erwartet 1).', jobs;
  end if;

  select count(*) into fremd from cron.job j
  where j.jobname::text = 'irgendein-alter-purge'
    and j.command = 'select cbb_private_analytics.purge_click_outs(24)';
  if fremd <> 1 then
    raise exception 'Nach dem Abbruch: der fremde purge-Job wurde veraendert.';
  end if;

  raise notice 'Nach dem Abbruch OK: nur der fremde purge-Job steht, unveraendert.';
end $$;
