-- ============================================================================
-- ASSERT — keine der beiden Backup-Tabellen existiert
-- ============================================================================
-- Belegt nach einem erwarteten Abbruch in 02, dass die Transaktion wirklich
-- vollstaendig zurueckgerollt wurde und kein halbes Artefakt zurueckblieb.
-- ============================================================================

do $$
declare
  vorhanden integer;
begin
  vorhanden :=
      case when to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1') is null then 0 else 1 end
    + case when to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1') is null then 0 else 1 end;
  if vorhanden <> 0 then
    raise exception 'Es existieren % der beiden Backup-Tabellen, erwartet waren 0.', vorhanden;
  end if;
  raise notice 'Beide Backup-Tabellen fehlen wie erwartet.';
end $$;
