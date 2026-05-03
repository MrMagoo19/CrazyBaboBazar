-- ============================================================
-- Import Batch 5: Bierbrauset
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Bierbrauset Pils 5 Liter Fass',
  'bierbrauset-pils-5-liter-fass',
  'Bier selber brauen im 5-Liter-Fass — in nur 7 Tagen fertig. Alles inklusive: Fass, Hefe, Malzextrakt, Zapfhahn. Kein Vorwissen nötig, perfektes Geschenk für Bierliebhaber und Hobbybrauer.',
  'Eigenes Bier in 7 Tagen.',
  3490,
  'https://m.media-amazon.com/images/I/41gTS+4LHXL._AC_.jpg',
  'https://www.amazon.de/dp/B07JQXGP88?tag=geeklist-21',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;
