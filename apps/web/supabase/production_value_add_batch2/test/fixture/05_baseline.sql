-- ============================================================================
-- FIXTURE 05 — Unveraenderliche Baseline-Kopien fuer den Round-Trip-Beweis
-- ============================================================================
-- products_before  kopiert ALLE 376 Produktzeilen mit editorial_note,
--                  updated_at und den acht Value-Add-Feldern. Nach 05_restore
--                  muss der Bestand Zeile fuer Zeile wieder hierzu passen —
--                  nicht nur die zehn Batch-2-Zielprodukte, sondern auch die
--                  366 Zeilen, die kein Skript anfassen darf, und insbesondere
--                  die zehn befuellten Batch-1-Zeilen.
--
-- v1_snapshot_before / v1_payload_before kopieren die BATCH-1-Artefakte. Jede
--                  spaetere Pruefung vergleicht Zeile fuer Zeile gegen diese
--                  Kopien: Batch 2 darf an Batch 1 nichts aendern, auch nicht
--                  eine einzelne Zelle.
--
-- Das Schema heisst bewusst nicht wie ein Pilot- oder Backup-Artefakt, damit
-- kein Guard in 01-05 es sieht: geprueft werden ausschliesslich
--   pilot_meta.environment_guard, pilot_backup.value_add_pre_backfill,
--   public.pilot_value_add_backup_20260823 sowie cbb_private_backup.*
-- ============================================================================

create schema cbb_test_baseline;
revoke all on schema cbb_test_baseline from public, anon, authenticated;

create table cbb_test_baseline.products_before as
select
  id, slug, editorial_note, updated_at, created_at, is_published,
  fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind
from public.products;

alter table cbb_test_baseline.products_before add primary key (id);

create table cbb_test_baseline.v1_snapshot_before as
select * from cbb_private_backup.value_add_pre_backfill_v1;

alter table cbb_test_baseline.v1_snapshot_before add primary key (id);

create table cbb_test_baseline.v1_payload_before as
select * from cbb_private_backup.value_add_payload_v1;

alter table cbb_test_baseline.v1_payload_before add primary key (slug);

do $$
declare
  n integer;
  s integer;
  p integer;
begin
  select count(*) into n from cbb_test_baseline.products_before;
  select count(*) into s from cbb_test_baseline.v1_snapshot_before;
  select count(*) into p from cbb_test_baseline.v1_payload_before;
  if n <> 376 then
    raise exception 'Baseline kaputt: % Produktzeilen, erwartet 376.', n;
  end if;
  if s <> 10 or p <> 10 then
    raise exception 'Baseline kaputt: v1-Snapshot %/10, v1-Payload %/10.', s, p;
  end if;
  raise notice 'Baseline OK: 376 Produktzeilen, v1-Snapshot 10, v1-Payload 10.';
end $$;
