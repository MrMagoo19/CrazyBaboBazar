-- Negativfall: ein Vorgaenger-Artefakt fehlt. Batch 3 darf dann nichts
-- schreiben — wenn die Rollback-Grundlage einer frueheren Charge verschwindet,
-- stimmt etwas Grundlegendes nicht.
--
-- Die Baseline-Kopie in cbb_test_baseline bleibt absichtlich stehen: der
-- Harness soll den Zustand danach noch pruefen koennen.
drop table cbb_private_backup.value_add_payload_v2;

do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v2') is not null then
    raise exception 'Setup kaputt: value_add_payload_v2 existiert weiterhin.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Setup kaputt: der Snapshot v2 wurde ebenfalls entfernt.';
  end if;
end $$;
