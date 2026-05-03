-- ============================================================
-- Import Batch 3: 5 einzelne Produkte
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Skullcandy Crusher ANC 2 Wireless Kopfhörer',
  'skullcandy-crusher-anc-2-wireless-kopfhoerer',
  'Over-Ear-Kopfhörer mit aktiver Geräuschunterdrückung und eingebautem Bassregler — du spürst den Bass buchstäblich. Multipoint-Bluetooth für zwei Geräte gleichzeitig, bis zu 50h Akku.',
  'Bass, den du fühlst.',
  20999,
  'https://m.media-amazon.com/images/I/31SRV7tHoOL._AC_.jpg',
  'https://www.amazon.de/dp/B0DZC8H6X9?tag=geeklist-21',
  false, false, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Personalisiertes Malen nach Zahlen Eigenes Foto',
  'personalisiertes-malen-nach-zahlen-eigenes-foto',
  'Malen nach Zahlen mit deinem eigenen Foto — einfach Bild hochladen, fertige Leinwand mit Farben und Pinsel kommt per Post. Perfektes Geschenk oder kreatives Hobby für Erwachsene.',
  'Dein Lieblingsfoto als Gemälde.',
  1498,
  'https://m.media-amazon.com/images/I/51hHmmCrFML._AC_.jpg',
  'https://www.amazon.de/dp/B0GBWQYS1K?tag=geeklist-21',
  false, false, 'queen', 'lifestyle', 'deko'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Personalisiertes Foto-Puzzle 1000 Teile',
  'personalisiertes-foto-puzzle-1000-teile',
  'Puzzle aus deinem eigenen Foto — in 100, 200, 500 oder 1000 Teilen. Hochwertiger Druck auf stabilem Karton, perfekt als persönliches Geschenk für jeden Anlass.',
  'Dein Foto zum Zusammensetzen.',
  2499,
  'https://m.media-amazon.com/images/I/41OAQ6rxKkL._AC_.jpg',
  'https://www.amazon.de/dp/B0CW3KG73F?tag=geeklist-21',
  false, false, 'queen', 'lifestyle', 'deko'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Wurfzelt 3-4 Personen 2-Sekunden-Aufbau',
  'wurfzelt-3-4-personen-2-sekunden-aufbau',
  'Pop-Up-Zelt für 3-4 Personen mit 2-Sekunden-Aufbau — einfach auswerfen, fertig. 4000mm Wassersäule, UV-Schutz, inklusive Packsack. Ideal für Festivals, Camping und Spontanausflüge.',
  'Zelt in 2 Sekunden. Wirklich.',
  12999,
  'https://m.media-amazon.com/images/I/51T31-O4qeL._AC_.jpg',
  'https://www.amazon.de/dp/B0D8FN25FY?tag=geeklist-21',
  false, false, 'wellness', 'outdoor', 'camping'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Tipi Zelt 4-6 Personen mit Stehhöhe',
  'tipi-zelt-4-6-personen-mit-stehoehe',
  'Großes Tipi-Campingzelt für 4-6 Personen mit 2-3 m Stehhöhe und eingenähtem Zeltboden. Stabil, wetterfest, mit Belüftungssystem — perfekt für Familien-Camping und Festivals.',
  'Zelt mit echtem Stehraum.',
  19900,
  'https://m.media-amazon.com/images/I/31VfXNxC6YL._AC_.jpg',
  'https://www.amazon.de/dp/B0D546F7ZV?tag=geeklist-21',
  false, false, 'wellness', 'outdoor', 'camping'
) ON CONFLICT (slug) DO NOTHING;
