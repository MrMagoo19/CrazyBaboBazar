-- ============================================================================
-- SETUP — Backup fuer anon lesbar gemacht (direkter GRANT auf die Tabelle)
-- ============================================================================
-- Das private Backup enthaelt vollstaendige Produktzeilen. Wird es fuer die
-- oeffentliche PostgREST-Rolle lesbar, ist es kein privates Artefakt mehr.
-- 03 muss das als FAIL-Zeile melden, 04 und 06 muessen hart abbrechen.
--
-- Bewusst NUR auf der Tabelle, nicht auf dem Schema: so laeuft die
-- Schemapruefung sauber durch und der Fall trifft genau die Tabellenpruefung.
-- Ein direkter GRANT ist dort gleichzeitig ein direkter ACL-Eintrag UND ein
-- effektives Recht — beide Zaehler springen auf 1.
-- ============================================================================

grant select on cbb_private_backup.quality_fixes_20260830_products_v1 to anon;

do $$
begin
  if not has_table_privilege('anon',
        'cbb_private_backup.quality_fixes_20260830_products_v1', 'SELECT') then
    raise exception 'Setup fehlgeschlagen: anon hat kein SELECT auf das Backup.';
  end if;
end $$;
