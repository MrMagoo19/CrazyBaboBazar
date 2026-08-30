-- ============================================================================
-- SETUP (POSITIV) — der minimal gueltige Guard, ganz ohne Tupelbedingung
-- ============================================================================
-- Der Vertragscheck in 01 muss zwei Formen akzeptieren:
--   * die reale Funktion mit zusaetzlicher AND-Tupelbedingung, und
--   * den minimalen Guard, der gar keine Zusatzbedingung traegt:
--       if new.updated_at is not distinct from old.updated_at then
--         new.updated_at := now();
--       end if;
--
-- Bisher war das nur durch Lesen des regulaeren Ausdrucks belegt. Dieser Fall
-- belegt es am laufenden Katalog: unmittelbar danach muss 01 weiterhin exakt
-- 23 PASS und 0 FAIL liefern.
--
-- Die Gegenproben unten sind der eigentliche Punkt der Datei. Ohne sie koennte
-- der Rumpf unbemerkt doch eine AND-Tupelbedingung enthalten — dann waere der
-- Fall eine zweite Kopie des Kommentarfalls und wuerde ueber den minimalen
-- Guard nichts aussagen. Gepruefte Punkte:
--   1. genau eine updated_at-Zuweisung,
--   2. genau ein END IF,
--   3. zwischen Guard und THEN steht NICHTS — der Abschnitt ist wirklich leer,
--   4. der Rumpf enthaelt keine Tupelbedingung "is distinct from" und nennt
--      keine der Spalten aus der realen Bedingung,
--   5. die geordnete Struktur Guard -> THEN -> Zuweisung -> END IF passt.
--
-- shop_sub_category kommt im Rumpf nicht vor; der Fall soll ausschliesslich die
-- minimale Guard-Form pruefen.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at is not distinct from old.updated_at then
    new.updated_at := now();
  end if;

  return new;
end
$$;

-- 1. + 2. Zaehlungen: genau eine Zuweisung, genau ein END IF.
do $$
declare
  zuweisungen    integer;
  end_if_bloecke integer;
begin
  select count(*) into zuweisungen
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'new\.updated_at[[:space:]]*(:=|=)',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if zuweisungen <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 updated_at-Zuweisungen im Rumpf der aktiven Triggerfunktion.', zuweisungen;
  end if;

  select count(*) into end_if_bloecke
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'end[[:space:]]+if;',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if end_if_bloecke <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 END IF im Rumpf der aktiven Triggerfunktion.', end_if_bloecke;
  end if;
end $$;

-- 3. + 4. Der Fall ist wirklich MINIMAL: zwischen Guard und THEN steht nichts,
-- es gibt keine Tupelbedingung und keine der Spalten der realen Bedingung.
-- Ohne diese Gegenproben koennte der Rumpf versehentlich die reale
-- AND-Bedingung tragen und der Fall waere ein Blindgaenger.
do $$
declare
  bereinigt text;
begin
  select regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g')
    into bereinigt
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';

  if bereinigt is null then
    raise exception 'Setup fehlgeschlagen: keine aktive Triggerfunktion products_set_updated_at gefunden.';
  end if;

  if bereinigt !~* 'if new\.updated_at is not distinct from old\.updated_at[[:space:]]+then[[:space:]]' then
    raise exception 'Setup fehlgeschlagen: zwischen Guard und THEN steht Text — der Fall waere nicht minimal.';
  end if;

  if bereinigt ~* 'is[[:space:]]+distinct[[:space:]]+from' then
    raise exception 'Setup fehlgeschlagen: der Rumpf enthaelt doch eine Tupelbedingung "is distinct from".';
  end if;

  if bereinigt ~* '(new|old)\.(name|tagline|description|editorial_note|image_url|is_published|shop_persona|shop_main_category|brand|category_id)' then
    raise exception 'Setup fehlgeschlagen: der Rumpf nennt eine Spalte der realen AND-Bedingung.';
  end if;

  if bereinigt ~* 'shop_sub_category' then
    raise exception 'Setup fehlgeschlagen: shop_sub_category darf in diesem positiven Fall nicht vorkommen.';
  end if;
end $$;

-- 5. Die geordnete Struktur Guard -> THEN -> Zuweisung -> END IF passt. Damit
-- ist belegt, dass der anschliessende 23er-PASS von dieser Form kommt und nicht
-- davon, dass 01 die Funktion gar nicht mehr findet.
do $$
declare
  geordnet integer;
begin
  select count(*) into geordnet
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at'
    and regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g')
        ~* ('if new\.updated_at is not distinct from old\.updated_at'
            || '.*[[:space:]]then[[:space:]]+new\.updated_at[[:space:]]*(:=|=)'
            || '[[:space:]]*now\(\);[[:space:]]*end[[:space:]]+if;');
  if geordnet <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Triggerfunktion mit geordneter Guard-Zuweisungs-Struktur.', geordnet;
  end if;
end $$;
