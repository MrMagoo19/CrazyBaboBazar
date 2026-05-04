-- ============================================================
-- Import Batch 10: 2 Lehrergeschenke
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Lehrergeschenk Stofftasche Abschiedsgeschenk',
  'lehrergeschenk-stofftasche-abschiedsgeschenk',
  'Hochwertige Stofftasche als Lehrergeschenk oder Abschiedsgeschenk — mit witzigem Spruch bedruckt. Langlebige Baumwolle, ideal zum Schuljahresende oder als Dankeschön für die Lieblingslehrerin.',
  'Danke sagen mit Stil.',
  899,
  'https://m.media-amazon.com/images/I/41Qkbj36+0L._AC_.jpg',
  'https://www.amazon.de/dp/B0F5QH41X8?tag=geeklist-21',
  false, false, 'queen', 'accessoires', 'geschenke'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Lehrergeschenk Baumwollbeutel Klassenarbeit Spruch',
  'lehrergeschenk-baumwollbeutel-klassenarbeit-spruch',
  'Baumwollbeutel mit witzigem Lehrerspruch: "Vielleicht ist es deine Klassenarbeit." Perfektes Geschenk für Lehrer, Erzieher und Ausbilder — zum Schulabschluss oder als Dankeschön.',
  'Der ehrlichste Beutel im Lehrerzimmer.',
  899,
  'https://m.media-amazon.com/images/I/31PQHcPyb0L._AC_.jpg',
  'https://www.amazon.de/dp/B0D633J9WM?tag=geeklist-21',
  false, false, 'queen', 'accessoires', 'geschenke'
) ON CONFLICT (slug) DO NOTHING;
