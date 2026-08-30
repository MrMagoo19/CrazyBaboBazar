-- ============================================================================
-- SETUP — Backup mit fremder Zeilen-id
-- ============================================================================
-- Der INHALT des Backups bleibt exakt der bekannte Vorzustand. Veraendert wird
-- nur die IDENTITAET einer Backup-Zeile: ihre id zeigt auf keine Zeile in
-- public.products mehr.
--
-- Warum das ein eigener Fall ist und setup_tamper_backup.sql nicht ersetzt:
--   * setup_tamper_backup.sql aendert den INHALT — jede inhaltliche Pruefung
--     gegen den bekannten Vorzustand schlaegt dort an.
--   * Hier ist der Inhalt korrekt. Nur die Zuordnung stimmt nicht. 06 schreibt
--     ueber die id zurueck und 04 sperrt Zeilenpaare ueber id UND slug — ein
--     solches Backup ist als Rollback-Pfad wertlos, sieht aber bei einem reinen
--     Inhaltsvergleich je slug unauffaellig aus.
--
-- Die id ist fest verdrahtet und traegt einen Marker, damit sie nicht mit einer
-- Fixture-id kollidieren kann.
-- ============================================================================

update cbb_private_backup.quality_fixes_20260830_products_v1
set id = '00000000-0000-4000-8000-0000cbb70001'::uuid
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  fremd integer;
  inhalt integer;
  in_quelle integer;
begin
  select count(*) into fremd
  from cbb_private_backup.quality_fixes_20260830_products_v1
  where id = '00000000-0000-4000-8000-0000cbb70001'::uuid
    and slug = 'divoom-pixoo-led-panel';
  if fremd <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Backup-Zeile traegt die fremde id.', fremd;
  end if;

  -- Die fremde id darf in public.products nicht existieren, sonst waere der
  -- Fall kein Identitaetsbruch.
  select count(*) into in_quelle
  from public.products
  where id = '00000000-0000-4000-8000-0000cbb70001'::uuid;
  if in_quelle <> 0 then
    raise exception 'Setup fehlgeschlagen: die fremde id existiert in public.products (%).', in_quelle;
  end if;

  -- Gegenprobe: der Inhalt ist unveraendert. Der Fall prueft ausschliesslich
  -- die Identitaet, nicht noch einmal die Inhaltsmanipulation.
  select count(*) into inhalt
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join public.products p on p.slug = b.slug
  where to_jsonb(b) - array['id'] is not distinct from to_jsonb(p) - array['id'];
  if inhalt <> 7 then
    raise exception 'Setup fehlgeschlagen: %/7 Backup-Zeilen sind inhaltlich noch identisch.', inhalt;
  end if;
end $$;
