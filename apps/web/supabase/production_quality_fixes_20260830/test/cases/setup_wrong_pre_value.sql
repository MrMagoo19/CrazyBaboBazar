-- ============================================================================
-- SETUP — ein Vorwert weicht ab
-- ============================================================================
-- Verstellt shop_tags von pizza-socks-box-pepperoni. Bewusst diese Spalte:
-- shop_tags steht NICHT in der Spaltenliste des Triggers
-- products_set_updated_at (supabase/seo_updated_at_trigger.sql), updated_at
-- bleibt also unveraendert. Ein reiner Zeitstempelvergleich wuerde die
-- Aenderung deshalb nicht bemerken — die Vorzustandspruefung des Pakets muss
-- sie ueber den Wert selbst finden.
--
-- Wird zweimal benutzt:
--   * VOR 02   -> 02 muss abbrechen, kein Backup entsteht,
--   * NACH 02  -> 04 muss abbrechen, nichts wird geschrieben.
-- ============================================================================

update public.products
set shop_tags = array['preis:unter20','preis:unter50']
where slug = 'pizza-socks-box-pepperoni';

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.products
  where slug = 'pizza-socks-box-pepperoni'
    and shop_tags = array['preis:unter20','preis:unter50'];
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Zeile verstellt.', n;
  end if;
end $$;
