-- ============================================================================
-- SETUP — Triggervertrag verletzt: shop_sub_category loest einen Bump aus,
--          versteckt hinter einem nur scheinbaren Blockkommentar
-- ============================================================================
-- Der deployte Trigger products_set_updated_at nimmt shop_sub_category bewusst
-- NICHT in seine Vergleichsliste auf (Beleg: supabase/seo_updated_at_trigger.sql,
-- Abschnitt "Bewusst NICHT aufgenommen"). Genau darauf stuetzt sich die Zusage
-- des Pakets, dass die A4-Unterkategorie kein neues lastmod bekommt.
--
-- Hier wird die Funktion so ersetzt, dass shop_sub_category doch zaehlt. Der
-- Trigger selbst bleibt unveraendert — nur sein Rumpf weicht ab. Ein reiner
-- Namens- oder Existenzcheck wuerde das nicht sehen; die Preflight-Zeile
-- products_updated_at_triggervertrag liest deshalb pg_get_functiondef.
--
-- ZWEITE SCHAERFE DIESES FALLS — die Reihenfolge der Kommentarbereinigung.
--   Der gefaehrliche Block steht zwischen zwei ZEILENKOMMENTAREN, von denen
--   der erste auf "/*" und der zweite auf "*/" endet. Beide sind Kommentartext
--   und kein Blockkommentar; der Code dazwischen wird von PL/pgSQL wirklich
--   ausgefuehrt.
--
--   * Richtige Reihenfolge (erst Zeilen-, dann Blockkommentare, wie in 01):
--     beide Markerzeilen verschwinden vollstaendig, der Bump-Code bleibt
--     sichtbar, shop_sub_category wird gefunden -> FAIL. Das ist das erwartete
--     Ergebnis dieses Falls.
--   * Falsche Reihenfolge (erst Block-, dann Zeilenkommentare): der Ausdruck
--     fuer Blockkommentare spannt vom "/*" der ersten Markerzeile bis zum "*/"
--     der zweiten und frisst den gesamten Bump-Code dazwischen. Uebrig bliebe
--     ein Rumpf, der wie der vertragskonforme aussieht — korrekter Guard,
--     genau eine Zuweisung, genau ein END IF, kein shop_sub_category. 01
--     meldete dann faelschlich PASS und liesse 04 auf eine Datenbank los, die
--     die A4-Unterkategorie sehr wohl mit einem neuen lastmod bumpt.
--
--   Der Fall ist damit die Gegenprobe auf die Reihenfolge selbst, nicht nur
--   auf das Vorkommen von shop_sub_category.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  -- Pflegehinweis, Beginn eines nur scheinbaren Blockkommentars: /*
  if new.shop_sub_category is distinct from old.shop_sub_category then
    new.updated_at := now();
  end if;
  -- Pflegehinweis, Ende des nur scheinbaren Blockkommentars: */

  if new.updated_at is not distinct from old.updated_at
     and (new.name) is distinct from (old.name)
  then
    new.updated_at := now();
  end if;

  return new;
end
$$;

do $$
declare
  treffer integer;
begin
  select count(*) into treffer
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at'
    and pg_catalog.pg_get_functiondef(p.oid) ~* 'shop_sub_category';
  if treffer <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 aktive Triggerfunktion nennt shop_sub_category.', treffer;
  end if;
end $$;

-- Gegenprobe auf die Falle selbst: beide Marker muessen wirklich im Rumpf
-- stehen, sonst prueft dieser Fall die Reihenfolge gar nicht mehr.
do $$
declare
  marker integer;
begin
  select count(*) into marker
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at'
    and pg_catalog.pg_get_functiondef(p.oid) ~ '--[^\n\r]*/\*'
    and pg_catalog.pg_get_functiondef(p.oid) ~ '--[^\n\r]*\*/';
  if marker <> 1 then
    raise exception 'Setup fehlgeschlagen: die Marker -- /* und -- */ stehen nicht beide im Rumpf (%/1).', marker;
  end if;
end $$;
