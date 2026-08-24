-- ============================================================================
-- TEARDOWN — Hilfsrolle und geerbtes Recht wieder entfernen
-- ============================================================================
-- Rollen und Rollenmitgliedschaften sind CLUSTERWEIT, nicht datenbanklokal.
-- Bliebe die Mitgliedschaft anon -> cbb_test_backup_reader bestehen, wuerde das
-- geerbte Recht in jede spaeter aus cbb_fixture erzeugte Testdatenbank
-- hineinwirken und dort andere Faelle verfaelschen.
-- ============================================================================

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'cbb_test_backup_reader') then
    execute 'revoke cbb_test_backup_reader from anon';
    -- Loest alle Grants der Hilfsrolle in DIESER Datenbank. Andere hat sie nie
    -- bekommen; DROP ROLE wuerde sonst mit "privileges depend on it" scheitern.
    execute 'drop owned by cbb_test_backup_reader';
    execute 'drop role cbb_test_backup_reader';
  end if;
end $$;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'cbb_test_backup_reader') then
    raise exception 'Teardown: Hilfsrolle cbb_test_backup_reader existiert weiterhin.';
  end if;
  if has_table_privilege(
       'anon', 'cbb_private_backup.n4_content_pre_fix_v1', 'SELECT') then
    raise exception 'Teardown: anon hat weiterhin effektives SELECT auf das Backup.';
  end if;
  raise notice 'OK: Hilfsrolle entfernt, anon ohne effektive Rechte.';
end $$;
