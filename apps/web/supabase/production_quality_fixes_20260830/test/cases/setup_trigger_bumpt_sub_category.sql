-- ============================================================================
-- SETUP — Triggervertrag verletzt: shop_sub_category loest einen Bump aus
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
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at is not distinct from old.updated_at
     and (new.name, new.shop_sub_category)
         is distinct from (old.name, old.shop_sub_category)
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
