-- ============================================================================
-- ASSERT — vollstaendiger Vorzustand
-- ============================================================================
-- Wird zweimal benutzt:
--   * als Abschluss des Fixture-Aufbaus,
--   * nach jedem erwarteten Abbruch, um zu belegen, dass wirklich nichts
--     geschrieben wurde.
-- Bricht bei der ersten Abweichung mit einer Exception ab (psql Exit 3).
-- ============================================================================

do $$
declare
  n integer;
  m integer;
begin
  select count(*) into n from public.products;
  if n < 300 then
    raise exception 'Fixture: nur % Produkte (< 300).', n;
  end if;

  -- Alle Zeilen entsprechen exakt der Baseline.
  select count(*) into n
  from cbb_test.baseline_products b
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck from public.products p
  ) p on p.id = b.id
  where b.id is null or p.id is null
     or p.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 0 then
    raise exception 'Vorzustand: % Produktzeilen weichen von der Baseline ab.', n;
  end if;

  select count(*) into n
  from cbb_test.baseline_lists b
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck from public.lists l
  ) l on l.id = b.id
  where b.id is null or l.id is null
     or l.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 0 then
    raise exception 'Vorzustand: % Listenzeilen weichen von der Baseline ab.', n;
  end if;

  -- Die belegten Vorwerte, noch einmal ausdruecklich und unabhaengig von der
  -- Baseline: eine falsche Baseline wuerde sonst mit sich selbst uebereinstimmen.
  select count(*) into n
  from public.products p
  where p.is_published is true
    and p.shop_persona = 'unknown'
    and p.shop_main_category = 'sonstiges'
    and p.shop_sub_category = 'ungeordnet'
    and p.slug in ('fingerabdruck-vorhaengeschloss-eseesmart',
                   'flauschige-handschuhe-weihnachten',
                   'pizza-socks-box-pepperoni');
  if n <> 3 then
    raise exception 'Vorzustand B2: %/3 Produkte auf unknown/sonstiges/ungeordnet.', n;
  end if;

  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and price_cents is null and is_published is true;
  if n <> 1 then
    raise exception 'Vorzustand B5a: %/1 Zeile mit price_cents IS NULL.', n;
  end if;

  select count(*) into n
  from public.products
  where slug = 'divoom-minitoo-retro-pc-lautsprecher-pixel'
    and image_url = 'https://divoom.com/cdn/shop/files/minitoo-1.jpg'
    and image_urls = array['https://divoom.com/cdn/shop/files/minitoo-1.jpg']
    and is_published is true;
  if n <> 1 then
    raise exception 'Vorzustand B5b: %/1 Zeile mit dem einzelnen Divoom-Bild.', n;
  end if;

  select count(*) into n
  from public.products
  where slug = 'cream-noise-machine-baby-tragbar'
    and name = 'Cream Noise Machine Baby Tragbar'
    and description like 'Tragbare Cream Noise Machine%'
    and editorial_note like 'Die tragbare Cream-Noise-Machine%'
    and is_published is true;
  if n <> 1 then
    raise exception 'Vorzustand D6: %/1 Zeile mit Cream Noise Machine.', n;
  end if;

  select count(*) into n
  from public.lists
  where slug = 'verrueckte-amazon-gadgets'
    and product_slugs[4] = 'plasmakugel-8-zoll-beruehlungsempfindlich'
    and array_length(product_slugs, 1) = 16;
  if n <> 1 then
    raise exception 'Vorzustand A4a: %/1 Liste mit Fehlerslug an Position 4.', n;
  end if;

  select count(*) into n
  from public.lists
  where slug = 'witzige-geschenke-maenner'
    and product_slugs[2] = 'bug-a-salt-3-0-fliegenjager-salzgewehr'
    and array_length(product_slugs, 1) = 12;
  if n <> 1 then
    raise exception 'Vorzustand A4b: %/1 Liste mit Fehlerslug an Position 2.', n;
  end if;

  select array_length(product_slugs, 1),
         (select count(distinct t.s) from unnest(product_slugs) as t(s))
  into n, m
  from public.lists where slug = 'geschenke-fuer-gamer';
  if n <> 16 or m <> 13 then
    raise exception 'Vorzustand A5: % Eintraege, davon % eindeutig (erwartet 16/13).', n, m;
  end if;

  -- A4 (Kategorie): die siebte Zielzeile steht im belegten Vorzustand.
  -- Persona, Hauptkategorie und Tags sind hier Vorwerte und bleiben spaeter
  -- unveraendert; nur shop_sub_category wird von 'basteln' auf 'gadgets'
  -- korrigiert.
  select count(*) into n
  from public.products
  where slug = 'plasmakugel-8-zoll-beruehrungsempfindlich'
    and shop_persona = 'babo'
    and shop_main_category = 'tech'
    and shop_sub_category = 'basteln'
    and shop_tags = array['babo:tech','preis:unter50','preis:unter100']
    and is_published is true;
  if n <> 1 then
    raise exception 'Vorzustand A4-Kategorie: %/1 Zeile auf babo/tech/basteln.', n;
  end if;

  -- Die beiden korrekten Zielprodukte existieren, die Fehlerslugs nicht.
  select count(*) into n
  from public.products
  where slug in ('plasmakugel-8-zoll-beruehrungsempfindlich',
                 'bug-a-salt-3-0-fliegenjaeger-salzgewehr')
    and is_published is true;
  if n <> 2 then
    raise exception 'Vorzustand A4: %/2 korrekte Zielprodukte published.', n;
  end if;

  select count(*) into n
  from public.products
  where slug in ('plasmakugel-8-zoll-beruehlungsempfindlich',
                 'bug-a-salt-3-0-fliegenjager-salzgewehr');
  if n <> 0 then
    raise exception 'Vorzustand A4: % Produkte tragen einen Fehlerslug.', n;
  end if;

  -- Sieben verschiedene historische updated_at-Werte: der Restore muss sie
  -- einzeln treffen und kann sich nicht auf einen Einheitswert stuetzen.
  select count(distinct p.updated_at) into n
  from public.products p
  join cbb_test.zielprodukte z on z.slug = p.slug;
  if n <> 7 then
    raise exception 'Fixture: nur % verschiedene updated_at bei den sieben Zielprodukten.', n;
  end if;

  -- Kein Zielprodukt darf updated_at IS NULL tragen. Sonst waere der
  -- Negativtest fuer den updated_at-Guard nicht von der Ausgangslage
  -- unterscheidbar.
  select count(*) into n
  from public.products p
  join cbb_test.zielprodukte z on z.slug = p.slug
  where p.updated_at is null;
  if n <> 0 then
    raise exception 'Fixture: % Zielprodukte haben updated_at IS NULL.', n;
  end if;

  raise notice 'Vorzustand vollstaendig bestaetigt.';
end $$;
