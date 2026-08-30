-- Zwei Eintraege mit DEMSELBEN Jobnamen. Auf pg_cron ist das moeglich, weil der
-- eindeutige Index auf (jobname, username) liegt — nicht auf jobname allein.
-- Ein zweiter Datenbanknutzer kann also denselben Jobnamen belegen.
--
-- Fuer 04a und 05 ist dieser Zustand nicht entscheidbar: welcher der beiden ist
-- "unserer"? Beide Dateien muessen hier fail-closed abbrechen, statt zu raten.
--
-- Der Eintrag wird direkt geschrieben und nicht ueber cron.schedule angelegt:
-- cron.schedule schreibt immer unter current_user und koennte den zweiten Fall
-- gar nicht erzeugen.
insert into cron.job (jobname, schedule, command, database, username, active)
values (
  'cbb-click-outs-retention-12m',
  '15 3 * * *',
  'select cbb_private_analytics.purge_click_outs(12);',
  current_database(),
  'anon',
  true
), (
  'cbb-click-outs-retention-12m',
  '15 3 * * *',
  'select cbb_private_analytics.purge_click_outs(12);',
  current_database(),
  'authenticated',
  true
);

do $$
declare
  jobs integer;
begin
  select count(*) into jobs from cron.job j
  where j.jobname::text = 'cbb-click-outs-retention-12m';
  if jobs <> 2 then
    raise exception 'Setup kaputt: % gleichnamige Job(s) (erwartet 2).', jobs;
  end if;
end $$;
