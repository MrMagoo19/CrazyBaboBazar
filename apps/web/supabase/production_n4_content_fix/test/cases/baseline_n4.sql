-- ============================================================================
-- BASELINE — unveraenderliche Kopie ALLER 376 Produktzeilen
-- ============================================================================
-- Kopiert genau die Spalten, die 04_correct_n4_content.sql und
-- 06_restore_n4_content.sql theoretisch anfassen koennten, plus die vier
-- Value-Add-Felder, die unveraendert bleiben muessen.
--
-- Damit ist beweisbar:
--   * nach 04 weicht GENAU EINE Zeile ab und 375 Zeilen sind Bit fuer Bit
--     unveraendert (inklusive updated_at — sonst meldet die Sitemap Google
--     Aenderungen, die es nie gab),
--   * nach 06 sind wieder alle 376 Zeilen identisch zur Baseline.
--
-- Das Schema heisst bewusst nicht wie ein Pilot- oder Backup-Artefakt, damit es
-- kein Guard in 01 bis 06 sieht. Geprueft werden dort ausschliesslich
--   pilot_meta.environment_guard, pilot_backup.value_add_pre_backfill,
--   public.pilot_value_add_backup_20260823 sowie cbb_private_backup.*
-- ============================================================================

create schema cbb_test_n4_baseline;
revoke all on schema cbb_test_n4_baseline from public, anon, authenticated;

create table cbb_test_n4_baseline.products_before as
select
  id, slug, tagline, description,
  nicht_fuer, key_fact, pros, cons, editorial_note, updated_at,
  fuer_wen, alternative_slug, alternative_reason, alternative_kind,
  is_published, created_at
from public.products;

alter table cbb_test_n4_baseline.products_before add primary key (id);

do $$
declare
  n integer;
  n4 integer;
begin
  select count(*) into n from cbb_test_n4_baseline.products_before;
  if n <> 376 then
    raise exception 'Baseline kaputt: % Zeilen, erwartet 376.', n;
  end if;

  select count(*) into n4 from cbb_test_n4_baseline.products_before
  where slug = 'n4-nussmilchbereiter-pflanzenmilch';
  if n4 <> 1 then
    raise exception 'Baseline kaputt: %/1 N4-Zeile.', n4;
  end if;
end $$;
