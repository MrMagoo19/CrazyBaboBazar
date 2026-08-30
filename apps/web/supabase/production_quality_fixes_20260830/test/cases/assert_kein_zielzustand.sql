-- ============================================================================
-- ASSERT — keine einzige Zeile steht im Zielzustand
-- ============================================================================
-- Nach jedem erwarteten Abbruch: die Korrektur darf nicht teilweise
-- durchgesickert sein. Geprueft werden alle neun Zielmerkmale einzeln.
--
-- Diese Datei setzt bewusst NICHT den kompletten Vorzustand voraus — sie wird
-- auch in Faellen benutzt, in denen ein Setup-Skript absichtlich einen Vorwert
-- verstellt hat.
-- ============================================================================

do $$
declare
  n integer;
begin
  select
    (select count(*) from public.products
      where slug in ('fingerabdruck-vorhaengeschloss-eseesmart',
                     'flauschige-handschuhe-weihnachten',
                     'pizza-socks-box-pepperoni')
        and shop_persona in ('babo', 'queen'))
    + (select count(*) from public.products
        where slug = 'divoom-pixoo-led-panel' and price_cents = 4249)
    + (select count(*) from public.products
        where slug = 'divoom-minitoo-retro-pc-lautsprecher-pixel'
          and image_url = 'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg')
    + (select count(*) from public.products
        where slug = 'cream-noise-machine-baby-tragbar'
          and name = 'White Noise Machine Baby Tragbar')
    + (select count(*) from public.lists
        where slug = 'verrueckte-amazon-gadgets'
          and product_slugs[4] = 'plasmakugel-8-zoll-beruehrungsempfindlich')
    + (select count(*) from public.lists
        where slug = 'witzige-geschenke-maenner'
          and product_slugs[2] = 'bug-a-salt-3-0-fliegenjaeger-salzgewehr')
    + (select count(*) from public.lists
        where slug = 'geschenke-fuer-gamer'
          and array_length(product_slugs, 1) = 13)
  into n;
  if n <> 0 then
    raise exception '% Zielmerkmale sind bereits gesetzt, erwartet waren 0.', n;
  end if;
  raise notice 'Keine Zeile im Zielzustand — der Abbruch hat nichts durchsickern lassen.';
end $$;
