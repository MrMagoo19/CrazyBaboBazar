-- Zustand nach 04a_schedule_retention.sql: GENAU EIN Job, exakt so wie
-- vereinbart, in dieser Datenbank, aktiv — und kein zweiter Job, der denselben
-- Loeschpfad aufruft.
--
-- Diese Datei ist bewusst redundant zu 04b: 04b ist der Report fuer Menschen,
-- diese Datei ist die harte Zusicherung fuer den Harness. Ein Report, den
-- niemand auswertet, ist kein Test.
do $$
declare
  soll_name     constant text := 'cbb-click-outs-retention-12m';
  soll_schedule constant text := '15 3 * * *';
  soll_command  constant text := 'select cbb_private_analytics.purge_click_outs(12);';

  namensgleiche integer;
  purge_jobs    integer;
  exakt         integer;
  ereignisse    bigint;
begin
  select count(*) into namensgleiche from cron.job j where j.jobname::text = soll_name;
  if namensgleiche <> 1 then
    raise exception 'Nach 04a: % Job(s) namens % (erwartet 1).', namensgleiche, soll_name;
  end if;

  select count(*) into exakt
  from cron.job j
  where j.jobname::text = soll_name
    and j.schedule = soll_schedule
    and j.command = soll_command
    and j.database = current_database()::text
    and j.active is true;
  if exakt <> 1 then
    raise exception 'Nach 04a: Job % weicht ab (0 exakte Treffer).', soll_name;
  end if;

  select count(*) into purge_jobs from cron.job j where j.command like '%purge_click_outs%';
  if purge_jobs <> 1 then
    raise exception 'Nach 04a: % Job(s) rufen purge_click_outs auf (erwartet 1).', purge_jobs;
  end if;

  -- Die Planung loescht nichts und legt nichts an.
  if to_regclass('public.click_outs') is null
     or to_regclass('cbb_private_analytics.click_outs_daily') is null
     or to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Nach 04a: die Planung hat Struktur veraendert.';
  end if;
  select count(*) into ereignisse from public.click_outs;

  raise notice 'Nach 04a OK: genau ein exakter Retention-Job, % Klick-out-Ereignis(se) unveraendert.',
    ereignisse;
end $$;
