-- Ein ANDERS benannter Job ruft denselben Loeschpfad auf. Der Name kollidiert
-- nicht, der Zweck sehr wohl: es gaebe dann zwei Planungen fuer eine Frist,
-- moeglicherweise mit unterschiedlichen Monatszahlen, und keine davon waere
-- die dokumentierte.
--
-- 04a muss deshalb abbrechen, statt daneben einen zweiten Job anzulegen.
-- 05 muss ebenfalls abbrechen: ein Drop der Funktion liesse diesen Job ab dann
-- jede Nacht scheitern.
select cron.schedule(
  'irgendein-alter-purge',
  '0 4 * * *',
  'select cbb_private_analytics.purge_click_outs(24)'
);

do $$
declare
  jobs integer;
begin
  select count(*) into jobs from cron.job j where j.command like '%purge_click_outs%';
  if jobs <> 1 then
    raise exception 'Setup kaputt: % fremde purge-Job(s) (erwartet 1).', jobs;
  end if;
end $$;
