-- Nimmt der Testdatenbank ein Batch-1-Artefakt weg. 02 muss fail-closed
-- abbrechen, statt Batch 2 auf einer halb dokumentierten Historie aufzusetzen.
--
-- Das betrifft ausschliesslich die lokale Wegwerf-Testdatenbank dieses Falls.
-- Die Dateien unter production_value_add/ und die Production-Tabellen werden
-- vom Harness nie angefasst.
drop table cbb_private_backup.value_add_payload_v1;

do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v1') is not null then
    raise exception 'Setup kaputt: value_add_payload_v1 existiert noch.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Setup kaputt: value_add_pre_backfill_v1 wurde mitgeloescht.';
  end if;
end $$;
