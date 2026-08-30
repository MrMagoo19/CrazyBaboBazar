-- ============================================================================
-- SETUP — gemischter Zustand
-- ============================================================================
-- Setzt EINE der zehn Zielzeilen von Hand auf den Zielzustand. Danach stehen
-- sechs Produkte im Vorzustand, eines im Zielzustand, alle drei Listen im
-- Vorzustand.
--
-- Genau dieser Zustand ist gefaehrlich: eine Datei, die einfach "alles auf den
-- Zielwert setzt", wuerde hier stillschweigend durchlaufen und den Unterschied
-- nie melden. 04 muss stattdessen fail-closed abbrechen, weil weder "alles
-- Vorzustand" noch "alles Zielzustand" gilt.
-- ============================================================================

update public.products
set price_cents = 4249
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and price_cents = 4249;
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Zeile auf den Zielwert gesetzt.', n;
  end if;
end $$;
