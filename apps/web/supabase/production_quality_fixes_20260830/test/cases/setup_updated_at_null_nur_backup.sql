-- ============================================================================
-- SETUP — updated_at IS NULL nur im Backup (nach 04, vor 06)
-- ============================================================================
-- In 06 ist das Backup die DATENQUELLE des Schreibvorgangs: der Restore setzt
-- updated_at = b.updated_at. Ist dieser Wert NULL, waere das Ergebnis eine
-- Produktzeile ganz ohne lastmod — die Sitemap fiele fuer sie auf created_at
-- zurueck, und der versprochene "exakte Round-Trip" waere in Wahrheit ein
-- Datenverlust.
--
-- Die uebrigen Pruefungen von 06 laufen bei diesem Setup durch:
--   * der Backup-Inhalt entspricht weiterhin dem bekannten Vorzustand
--     (updated_at gehoert zu keiner der Vorzustandspruefungen),
--   * die Zielzeilen stehen nach 04 vollstaendig im Zielzustand,
--   * ausserhalb der von 04 geaenderten Spalten gibt es keine Abweichung —
--     updated_at steht in genau dieser Ausnahmeliste.
-- Erwartet wird deshalb der Abbruch am eigenen updated_at-Guard, VOR dem ersten
-- Restore-UPDATE.
-- ============================================================================

update cbb_private_backup.quality_fixes_20260830_products_v1
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  n integer;
begin
  select count(*) into n
  from cbb_private_backup.quality_fixes_20260830_products_v1
  where slug = 'divoom-pixoo-led-panel' and updated_at is null;
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Backup-Zeile mit updated_at IS NULL.', n;
  end if;

  -- Die Quelle behaelt ihren nach 04 gesetzten Zeitstempel. Nur so ist der
  -- Fall vom Fall "beide Seiten NULL" unterscheidbar.
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and updated_at is not null;
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: die Quellzeile hat kein updated_at mehr.';
  end if;
end $$;
