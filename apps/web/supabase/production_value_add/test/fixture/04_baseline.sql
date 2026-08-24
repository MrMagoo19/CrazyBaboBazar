-- ============================================================================
-- FIXTURE 04 — Unveraenderliche Baseline-Kopie fuer den Round-Trip-Beweis
-- ============================================================================
-- Kopiert slug / editorial_note / updated_at ALLER 376 Produkte in ein eigenes
-- Testschema. Nach 06_restore und nach 07_down muss der Bestand wieder Zeile
-- fuer Zeile hierzu passen — nicht nur die zehn Zielprodukte, sondern auch die
-- 366 Zeilen, die kein Skript anfassen darf.
--
-- Das Schema heisst bewusst nicht wie ein Pilot- oder Backup-Artefakt, damit
-- kein Guard in 01-07 es sieht: geprueft werden ausschliesslich
--   pilot_meta.environment_guard, pilot_backup.value_add_pre_backfill,
--   public.pilot_value_add_backup_20260823 sowie cbb_private_backup.*
-- ============================================================================

create schema cbb_test_baseline;
revoke all on schema cbb_test_baseline from public, anon, authenticated;

create table cbb_test_baseline.products_before as
select id, slug, editorial_note, updated_at, created_at, is_published
from public.products;

alter table cbb_test_baseline.products_before add primary key (id);

do $$
declare
  n integer;
begin
  select count(*) into n from cbb_test_baseline.products_before;
  if n <> 376 then
    raise exception 'Baseline kaputt: % Zeilen, erwartet 376.', n;
  end if;
end $$;
