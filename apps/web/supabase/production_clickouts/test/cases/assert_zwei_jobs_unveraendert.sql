-- Nach dem fail-closed Abbruch bei doppeltem Jobnamen muessen BEIDE Eintraege
-- unveraendert stehen. Haette 04a einen davon ueberschrieben oder 05 einen
-- davon abbestellt, waere genau der Schaden eingetreten, den der Guard
-- verhindern soll.
do $$
declare
  jobs bigint;
begin
  select count(*) into jobs from cron.job j
  where j.jobname::text = 'cbb-click-outs-retention-12m';
  if jobs <> 2 then
    raise exception 'Nach dem Abbruch: % gleichnamige Job(s) (erwartet 2).', jobs;
  end if;
  raise notice 'Nach dem Abbruch OK: beide gleichnamigen Eintraege stehen unveraendert.';
end $$;
