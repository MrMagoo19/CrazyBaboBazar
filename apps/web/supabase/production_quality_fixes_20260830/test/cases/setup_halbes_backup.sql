-- ============================================================================
-- SETUP — halbes Backup
-- ============================================================================
-- Entfernt die Listen-Backup-Tabelle und laesst die Produkt-Backup-Tabelle
-- stehen. Ein Wiederholungslauf von 02 darf diesen Zustand NICHT stillschweigend
-- ergaenzen: die verbliebene Tabelle stammt aus einem anderen Lauf, und ein
-- halbes Backup ist kein Backup.
--
-- DROP steht hier im Testaufbau, nicht im Paket. Keine der sechs SQL-Dateien
-- des Pakets enthaelt ein DROP oder DELETE.
-- ============================================================================

drop table cbb_private_backup.quality_fixes_20260830_lists_v1;

do $$
begin
  if to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1') is not null then
    raise exception 'Setup fehlgeschlagen: Listen-Backup existiert noch.';
  end if;
  if to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1') is null then
    raise exception 'Setup fehlgeschlagen: Produkt-Backup fehlt ebenfalls.';
  end if;
end $$;
