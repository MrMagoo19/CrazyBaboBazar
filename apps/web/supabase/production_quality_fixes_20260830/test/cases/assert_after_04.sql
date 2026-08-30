-- ============================================================================
-- ASSERT — Zustand nach 04_apply_quality_fixes.sql
-- ============================================================================
-- Prueft unabhaengig von den Nachbedingungen in 04 selbst:
--   1. alle sieben Produktzeilen tragen exakt den Zielzustand,
--   2. alle drei Listenzeilen tragen exakt den Zielzustand,
--   3. genau zehn Zeilen weichen von der Baseline ab — keine einzige mehr,
--   4. an den Zielzeilen wurde nur geaendert, was geaendert werden durfte,
--   5. updated_at ist bei den sechs sichtbar geaenderten Produkten neu; bei
--      der nicht gerenderten A4-Unterkategorie bleibt es exakt historisch,
--   6. die Fremdliste mit demselben Fehlerslug ist unberuehrt geblieben.
-- ============================================================================

do $$
declare
  n integer;
  m integer;
begin
  -- 1 — B2
  select count(*) into n
  from public.products p
  where (p.slug = 'fingerabdruck-vorhaengeschloss-eseesmart'
         and p.shop_persona = 'babo' and p.shop_main_category = 'tech'
         and p.shop_sub_category = 'gadgets'
         and p.shop_tags = array['babo:tech','preis:unter50','preis:unter100'])
     or (p.slug = 'flauschige-handschuhe-weihnachten'
         and p.shop_persona = 'queen' and p.shop_main_category = 'lifestyle'
         and p.shop_sub_category = 'mode'
         and p.shop_tags = array['queen:lifestyle','preis:unter50','preis:unter100'])
     or (p.slug = 'pizza-socks-box-pepperoni'
         and p.shop_persona = 'queen' and p.shop_main_category = 'lifestyle'
         and p.shop_sub_category = 'mode'
         and p.shop_tags = array['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100']);
  if n <> 3 then
    raise exception 'Nach 04: %/3 B2-Zeilen im Zielzustand.', n;
  end if;

  -- 1 — B5a
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and price_cents = 4249;
  if n <> 1 then
    raise exception 'Nach 04: %/1 Zeile mit price_cents = 4249.', n;
  end if;

  -- 1 — B5b
  select count(*) into n
  from public.products
  where slug = 'divoom-minitoo-retro-pc-lautsprecher-pixel'
    and image_url = 'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg'
    and image_urls = array[
      'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71v8gQDca6L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/714WnHwLo9L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71jxiRQdS5L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71GkuzGfSGL._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71VTCrKHb0L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71r9B960j6L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71-2D0RTF4L._AC_SL1500_.jpg',
      'https://m.media-amazon.com/images/I/71C2JOSo0IL._AC_SL1500_.jpg'
    ];
  if n <> 1 then
    raise exception 'Nach 04: %/1 Zeile mit den neun Amazon-Bildern.', n;
  end if;

  -- 1 — D6, inklusive des Nachweises, dass "Cream" nirgends mehr steht und der
  --     Slug absichtlich unveraendert geblieben ist.
  select count(*) into n
  from public.products
  where slug = 'cream-noise-machine-baby-tragbar'
    and name = 'White Noise Machine Baby Tragbar'
    and description like 'Tragbare White Noise Machine%'
    and editorial_note like 'Die tragbare White-Noise-Machine%'
    and description not like '%Cream%'
    and editorial_note not like '%Cream%'
    and name not like '%Cream%';
  if n <> 1 then
    raise exception 'Nach 04: %/1 D6-Zeile im Zielzustand.', n;
  end if;

  -- 1 — A4-Kategorie: nur die Unterkategorie darf gewandert sein. Persona,
  --     Hauptkategorie und Tags stehen ausdruecklich mit im Vergleich, damit
  --     ein zu breites UPDATE hier auffaellt.
  select count(*) into n
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.slug = 'plasmakugel-8-zoll-beruehrungsempfindlich'
    and p.shop_persona = 'babo'
    and p.shop_main_category = 'tech'
    and p.shop_sub_category = 'gadgets'
    and p.shop_tags = array['babo:tech','preis:unter50','preis:unter100']
    and p.updated_at is not distinct from b.updated_at;
  if n <> 1 then
    raise exception 'Nach 04: %/1 A4-Kategorie-Zeile im Zielzustand.', n;
  end if;

  -- 2 — Listen
  select count(*) into n
  from public.lists
  where slug = 'verrueckte-amazon-gadgets'
    and product_slugs[4] = 'plasmakugel-8-zoll-beruehrungsempfindlich'
    and array_length(product_slugs, 1) = 16;
  if n <> 1 then
    raise exception 'Nach 04: A4a nicht korrigiert (%/1).', n;
  end if;

  select count(*) into n
  from public.lists
  where slug = 'witzige-geschenke-maenner'
    and product_slugs[2] = 'bug-a-salt-3-0-fliegenjaeger-salzgewehr'
    and array_length(product_slugs, 1) = 12;
  if n <> 1 then
    raise exception 'Nach 04: A4b nicht korrigiert (%/1).', n;
  end if;

  select array_length(product_slugs, 1),
         (select count(distinct t.s) from unnest(product_slugs) as t(s))
  into n, m
  from public.lists where slug = 'geschenke-fuer-gamer';
  if n <> 13 or m <> 13 then
    raise exception 'Nach 04: A5 hat % Eintraege, davon % eindeutig (erwartet 13/13).', n, m;
  end if;

  -- Reihenfolge und erste Vorkommen erhalten.
  select count(*) into n
  from public.lists
  where slug = 'geschenke-fuer-gamer'
    and product_slugs = array[
      'street-fighter-arcade-machine',
      'dnd-starter-set-helden-der-grenzlande-deutsch',
      'mayflash-f300-arcade-joystick',
      'nintendo-classic-mini-snes',
      'mad-monkey-retro-spielekonsole',
      'gan-356me-speed-cube-3x3-magnetisch',
      'krimispiel-escape-room-detektivspiel-erwachsene',
      'ps5-horizontale-tasche-tragetasche',
      'kytok-controller-staender-4-etagen',
      'shashibo-formwechsel-box-magnetisch',
      'weiminli-switch-skull-case',
      'giiker-super-slide-puzzle',
      'dealkit-3d-labyrinth-wuerfel'
    ];
  if n <> 1 then
    raise exception 'Nach 04: A5-Reihenfolge stimmt nicht.';
  end if;

  -- 3 — genau sieben Produktzeilen und drei Listenzeilen weichen von der
  --     Baseline ab.
  select count(*) into n
  from cbb_test.baseline_products b
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck from public.products p
  ) p on p.id = b.id
  where b.id is null or p.id is null
     or p.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 7 then
    raise exception 'Nach 04: % Produktzeilen weichen von der Baseline ab (erwartet genau 7).', n;
  end if;

  select count(*) into n
  from cbb_test.baseline_products b
  join public.products p on p.id = b.id
  join cbb_test.zielprodukte z on z.slug = p.slug
  where md5(to_jsonb(p)::text) is distinct from b.fingerabdruck;
  if n <> 7 then
    raise exception 'Nach 04: nur % der sieben abweichenden Zeilen sind Zielprodukte.', n;
  end if;

  select count(*) into n
  from cbb_test.baseline_lists b
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck from public.lists l
  ) l on l.id = b.id
  where b.id is null or l.id is null
     or l.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 3 then
    raise exception 'Nach 04: % Listenzeilen weichen von der Baseline ab (erwartet genau 3).', n;
  end if;

  -- 4 — an den Zielzeilen wurde nur das Erlaubte geaendert.
  select count(*) into n
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where to_jsonb(p) - case p.slug
      when 'divoom-pixoo-led-panel'
        then array['price_cents','updated_at']
      when 'divoom-minitoo-retro-pc-lautsprecher-pixel'
        then array['image_url','image_urls','updated_at']
      when 'cream-noise-machine-baby-tragbar'
        then array['name','description','editorial_note','updated_at']
      when 'plasmakugel-8-zoll-beruehrungsempfindlich'
        then array['shop_sub_category']
      else array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']
    end
    is not distinct from to_jsonb(b) - case p.slug
      when 'divoom-pixoo-led-panel'
        then array['price_cents','updated_at']
      when 'divoom-minitoo-retro-pc-lautsprecher-pixel'
        then array['image_url','image_urls','updated_at']
      when 'cream-noise-machine-baby-tragbar'
        then array['name','description','editorial_note','updated_at']
      when 'plasmakugel-8-zoll-beruehrungsempfindlich'
        then array['shop_sub_category']
      else array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']
    end;
  if n <> 7 then
    raise exception 'Nach 04: nur %/7 Zielprodukte sind ausserhalb der erlaubten Spalten unveraendert.', n;
  end if;

  -- 5 — neues lastmod bei den sechs sichtbar geaenderten Produkten.
  select count(*) into n
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b on b.id = p.id
  where p.slug <> 'plasmakugel-8-zoll-beruehrungsempfindlich'
    and p.updated_at > b.updated_at;
  if n <> 6 then
    raise exception 'Nach 04: nur %/6 lastmod-Zielprodukte haben ein neues updated_at.', n;
  end if;

  -- 6 — die Fremdliste mit demselben Fehlerslug wurde NICHT angefasst.
  select count(*) into n
  from public.lists
  where slug = 'fixture-fremdliste-mit-fehlerslug'
    and product_slugs = array['plasmakugel-8-zoll-beruehlungsempfindlich', 'flipper-zero'];
  if n <> 1 then
    raise exception 'Nach 04: die Fremdliste wurde veraendert.';
  end if;

  raise notice 'Zielzustand nach 04 vollstaendig bestaetigt.';
end $$;
