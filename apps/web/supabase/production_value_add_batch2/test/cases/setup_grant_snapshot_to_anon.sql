-- Absichtliches Loch in der Absicherung des Snapshots: anon bekommt SELECT auf
-- cbb_private_backup.value_add_pre_backfill_v2 und USAGE auf das Schema.
--
-- Zweck: beweisen, dass 02b_verify_snapshot_read_only.sql diesen Zustand als
-- FAIL meldet und nicht still durchwinkt. Ohne diesen Fall waere ein PASS von
-- 02b nur die Aussage "die Pruefung laeuft", nicht "die Pruefung greift".
--
-- Laeuft ausschliesslich in der lokalen Wegwerf-Testdatenbank dieses Falls.
grant usage on schema cbb_private_backup to anon;
grant select on cbb_private_backup.value_add_pre_backfill_v2 to anon;

do $$
declare
  n integer;
begin
  select count(*) into n
  from information_schema.role_table_grants
  where table_schema = 'cbb_private_backup'
    and table_name = 'value_add_pre_backfill_v2'
    and grantee = 'anon';
  if n <> 1 then
    raise exception 'Setup kaputt: % Grants fuer anon (erwartet 1).', n;
  end if;
end $$;
