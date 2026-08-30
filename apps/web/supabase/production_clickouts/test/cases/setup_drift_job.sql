-- Legt einen Job mit dem RICHTIGEN Namen, aber falschem Schedule und falschem
-- Command an. Genau dieser Fall ist der Grund fuer den Vorab-Guard in 04a:
-- `cron.schedule` wuerde diesen Eintrag stillschweigend ueberschreiben.
--
-- Der Command ruft absichtlich NICHT purge_click_outs auf — sonst greife schon
-- der Guard gegen fremde Loeschjobs, und der Drift-Zweig bliebe ungetestet.
select cron.schedule(
  'cbb-click-outs-retention-12m',
  '0 0 * * 0',
  'select 1'
);

do $$
declare
  jobs integer;
begin
  select count(*) into jobs
  from cron.job j
  where j.jobname::text = 'cbb-click-outs-retention-12m'
    and j.schedule = '0 0 * * 0'
    and j.command = 'select 1';
  if jobs <> 1 then
    raise exception 'Setup kaputt: % Drift-Job(s) (erwartet 1).', jobs;
  end if;
end $$;
