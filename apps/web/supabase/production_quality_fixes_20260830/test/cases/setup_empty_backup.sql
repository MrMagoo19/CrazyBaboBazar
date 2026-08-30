-- ============================================================================
-- SETUP — Backup-Tabelle existiert, ist aber leer
-- ============================================================================
-- Der gefaehrlichste Zwischenstand: to_regclass meldet "vorhanden", der Inhalt
-- ist aber weg. Eine Datei, die nur auf Existenz prueft, wuerde weiterlaufen
-- und haette danach keinen Rollback-Pfad mehr.
-- ============================================================================

delete from cbb_private_backup.quality_fixes_20260830_products_v1;

do $$
declare
  n integer;
begin
  select count(*) into n from cbb_private_backup.quality_fixes_20260830_products_v1;
  if n <> 0 then
    raise exception 'Setup fehlgeschlagen: Backup enthaelt noch % Zeilen.', n;
  end if;
end $$;
