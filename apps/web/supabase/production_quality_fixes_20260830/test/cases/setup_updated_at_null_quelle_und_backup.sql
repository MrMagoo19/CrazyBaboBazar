-- ============================================================================
-- SETUP — updated_at IS NULL in Quelle UND Backup (nach 02, vor 04)
-- ============================================================================
-- Der schwierigere Zwischenstand: die Spalte ist auf BEIDEN Seiten NULL. Damit
-- laufen alle vorgelagerten Pruefungen von 04 sauber durch —
--   * die Vorzustandspruefung sieht nur Werte, die sie ohnehin nicht abfragt,
--   * der vollstaendige to_jsonb-Vergleich Backup gegen Quelle findet KEINE
--     Abweichung, weil beide Seiten denselben NULL-Wert tragen.
-- Ohne den eigenen Guard wuerde 04 also schreiben und erst an der
-- lastmod-Nachbedingung 5 mit einer irrefuehrenden Meldung scheitern
-- ("updated_at wurde nur bei 5/6 lastmod-Zielprodukten neu gesetzt") — oder,
-- diese Nachbedingung je gelockert wuerde, still ein falsches lastmod
-- hinterlassen.
--
-- Erwartet wird deshalb ein Abbruch mit klarer Ursache VOR dem ersten UPDATE.
-- ============================================================================

update public.products
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

update cbb_private_backup.quality_fixes_20260830_products_v1
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  n integer;
  m integer;
begin
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and updated_at is null;
  select count(*) into m
  from cbb_private_backup.quality_fixes_20260830_products_v1
  where slug = 'divoom-pixoo-led-panel' and updated_at is null;
  if n <> 1 or m <> 1 then
    raise exception 'Setup fehlgeschlagen: Quelle %/1, Backup %/1 mit updated_at IS NULL.', n, m;
  end if;

  -- Gegenprobe: Backup und Quelle sind trotz der Aenderung weiterhin
  -- vollstaendig deckungsgleich. Nur so ist bewiesen, dass 04 nicht schon am
  -- Drift-Vergleich abbricht, sondern wirklich am updated_at-Guard.
  select count(*) into n
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where to_jsonb(p) is distinct from to_jsonb(b);
  if n <> 0 then
    raise exception 'Setup fehlgeschlagen: % Zeilen driften zwischen Quelle und Backup.', n;
  end if;
end $$;
