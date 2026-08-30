-- ============================================================================
-- SETUP — Triggervertrag verletzt: ein explizit gesetztes updated_at wird
--          ueberschrieben
-- ============================================================================
-- 04 schreibt updated_at bei den sechs sichtbaren Produktseiten ausdruecklich
-- mit. Dass dieser Wert stehen bleibt, garantiert allein der Guard
--   if new.updated_at is not distinct from old.updated_at ...
-- im deployten Trigger. Faellt er weg, setzt der Trigger bei JEDEM UPDATE
-- now() — der ausdruecklich gesetzte Wert waere verloren, und die
-- A4-Unterkategorie bekaeme zusaetzlich ein neues lastmod.
--
-- shop_sub_category kommt im Rumpf hier absichtlich NICHT vor: der Fall muss
-- genau an der fehlenden Guard-Bedingung scheitern, nicht an einer zweiten
-- Abweichung.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

do $$
declare
  ohne_guard integer;
begin
  select count(*) into ohne_guard
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at'
    and regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g')
        !~* 'if new\.updated_at is not distinct from old\.updated_at';
  if ohne_guard <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 aktive Triggerfunktion ohne den updated_at-Guard.', ohne_guard;
  end if;
end $$;
