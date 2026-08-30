-- ============================================================================
-- ASSERT — die konkurrierende Aenderung hat ueberlebt
-- ============================================================================
-- Nach dem Nebenlaeufigkeitstest gegen 02: die zweite Session hat shop_tags von
-- pizza-socks-box-pepperoni gesetzt und committet. 02 muss abgebrochen sein,
-- ohne diesen Wert zu ueberschreiben und ohne ihn in einen Snapshot zu
-- uebernehmen.
--
-- shop_tags steht nicht in der Spaltenliste des Triggers
-- products_set_updated_at — updated_at ist also unveraendert. 02 konnte die
-- Aenderung deshalb nur ueber die vollstaendige Vorzustandspruefung nach dem
-- Lock bemerken, nicht ueber einen Zeitstempelvergleich.
-- ============================================================================

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.products
  where slug = 'pizza-socks-box-pepperoni'
    and shop_tags = array['CBB-TEST: konkurrierende Aenderung an shop_tags'];
  if n <> 1 then
    raise exception 'Die konkurrierende Aenderung an shop_tags fehlt (%/1).', n;
  end if;

  select count(*) into n
  from public.products
  where slug = 'pizza-socks-box-pepperoni'
    and updated_at = timestamptz '2026-07-06 00:00:00+00';
  if n <> 1 then
    raise exception 'updated_at von pizza-socks wurde veraendert — der Fall belegt dann nicht mehr, was er belegen soll.';
  end if;
end $$;
