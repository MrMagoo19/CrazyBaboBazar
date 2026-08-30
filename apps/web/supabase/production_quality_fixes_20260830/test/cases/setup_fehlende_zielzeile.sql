-- ============================================================================
-- SETUP — eine Zielzeile fehlt
-- ============================================================================
-- Loescht divoom-pixoo-led-panel aus public.products. Danach kann weder ein
-- vollstaendiges Backup entstehen noch die Korrektur laufen: die Zielmenge ist
-- 5 statt 6.
--
-- Der Fall ist kein Hirngespinst — ein unveroeffentlichtes oder geloeschtes
-- Produkt ist genau das, was zwischen Audit und Ausfuehrung passieren kann.
-- ============================================================================

delete from public.products where slug = 'divoom-pixoo-led-panel';

do $$
declare
  n integer;
begin
  select count(*) into n from public.products where slug = 'divoom-pixoo-led-panel';
  if n <> 0 then
    raise exception 'Setup fehlgeschlagen: Zielzeile noch vorhanden.';
  end if;
end $$;
