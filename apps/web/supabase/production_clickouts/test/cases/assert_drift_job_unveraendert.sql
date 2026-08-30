-- Der eigentliche Beweis des Drift-Falls: nach dem Abbruch von 04a bzw. 05
-- steht der fremde Eintrag NOCH GENAU SO da. Waere er ueberschrieben oder
-- abbestellt worden, waere still fremde Arbeit vernichtet worden.
do $$
declare
  jobs   bigint;
  drift  integer;
begin
  select count(*) into jobs from cron.job;
  if jobs <> 1 then
    raise exception 'Nach dem Abbruch: % Job(s) im Katalog (erwartet 1).', jobs;
  end if;

  select count(*) into drift
  from cron.job j
  where j.jobname::text = 'cbb-click-outs-retention-12m'
    and j.schedule = '0 0 * * 0'
    and j.command = 'select 1';
  if drift <> 1 then
    raise exception 'Nach dem Abbruch: der vorhandene Job wurde veraendert.';
  end if;

  raise notice 'Nach dem Abbruch OK: der fremde gleichnamige Job steht unveraendert.';
end $$;
