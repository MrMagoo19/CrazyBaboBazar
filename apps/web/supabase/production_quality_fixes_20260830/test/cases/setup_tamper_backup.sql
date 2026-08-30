-- ============================================================================
-- SETUP — manipuliertes Backup
-- ============================================================================
-- Veraendert den Inhalt der Backup-Tabelle, ohne public.products anzufassen.
--
-- Das Backup ist in 06 die DATENQUELLE des Schreibvorgangs. Ein manipuliertes
-- Backup wuerde ungeprueft zu Seiteninhalt. 04 und 06 muessen es deshalb beide
-- gegen den bekannten Vorzustand pruefen und abbrechen.
-- ============================================================================

update cbb_private_backup.quality_fixes_20260830_products_v1
set name = 'CBB-TEST: manipulierter Backup-Inhalt'
where slug = 'cream-noise-machine-baby-tragbar';

do $$
declare
  n integer;
begin
  select count(*) into n
  from cbb_private_backup.quality_fixes_20260830_products_v1
  where name = 'CBB-TEST: manipulierter Backup-Inhalt';
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Backup-Zeile manipuliert.', n;
  end if;
end $$;
