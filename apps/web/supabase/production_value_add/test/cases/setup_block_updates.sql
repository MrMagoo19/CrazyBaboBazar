-- Erzwingt einen Fehler MITTEN in der 04-Transaktion: nach dem CREATE TABLE
-- cbb_private_backup.value_add_payload_v1, aber im selben BEGIN...COMMIT.
-- Beweist, dass ein Abbruch auch bereits erzeugtes DDL zurueckrollt.
create function cbb_test_block_update() returns trigger
language plpgsql as $$
begin
  raise exception 'CBB-TEST: UPDATE auf products absichtlich blockiert.';
end $$;

create trigger zzz_cbb_test_block_update
  before update on public.products
  for each row execute function cbb_test_block_update();
