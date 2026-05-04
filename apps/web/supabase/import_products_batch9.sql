-- ============================================================
-- Import Batch 9: 6 Produkte
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'ROKR 3D Holzpuzzle Raumfähre Modellbausatz',
  'rokr-3d-holzpuzzle-raumfaehre-modellbausatz',
  'Detaillierter 3D-Holzbausatz einer Raumfähre im STEM-Design — alle Teile vorgestanzt, kein Kleber nötig. Mit beweglichen Elementen, ideal als Schreibtischdeko und Bauspaß für Erwachsene.',
  'Bau dir deine eigene Raumfähre.',
  5995,
  'https://m.media-amazon.com/images/I/51jAp6XaOjL._AC_.jpg',
  'https://www.amazon.de/dp/B0FKMX974Q?tag=geeklist-21',
  false, false, 'babo', 'diy', 'basteln'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'D&D Starter Set Helden der Grenzlande Deutsch',
  'dnd-starter-set-helden-der-grenzlande-deutsch',
  'Das offizielle Dungeons & Dragons Starter Set auf Deutsch — inklusive Abenteuer, Charakterbögen, Würfeln und Regelübersicht. Perfekter Einstieg ins Rollenspiel für 2–6 Spieler.',
  'Dein erstes D&D-Abenteuer beginnt hier.',
  5200,
  'https://m.media-amazon.com/images/I/41OgxYPqVJL._AC_.jpg',
  'https://www.amazon.de/dp/B0GNM7TTKZ?tag=geeklist-21',
  false, false, 'babo', 'gaming', 'tabletop'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Bialetti Moka Express Stranger Things Edition',
  'bialetti-moka-express-stranger-things-edition',
  'Die ikonische Bialetti Moka Express im offiziellen Stranger Things Design — 3 Tassen, mit musikalischem Knauf und Ladefunktion. Induktionsgeeignet, limitierte Collector''s Edition.',
  'Kaffee aus dem Upside Down.',
  5199,
  'https://m.media-amazon.com/images/I/41d4s+HIFqL._AC_.jpg',
  'https://www.amazon.de/dp/B0FJ9SM388?tag=geeklist-21',
  false, false, 'queen', 'küche', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Stranger Things Lucas T-Shirt Offiziell',
  'stranger-things-lucas-t-shirt-offiziell',
  'Offiziell lizenziertes Stranger Things T-Shirt mit Lucas WSQK Squawk Print. Hochwertiger Baumwolldruck, verschiedene Größen — für alle Fans der Hawkins-Gang.',
  'Represent Hawkins.',
  1939,
  'https://m.media-amazon.com/images/I/81T-4BY7OpL.png',
  'https://www.amazon.de/dp/B0GFBDWB2W?tag=geeklist-21',
  false, false, 'babo', 'lifestyle', 'fashion'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Masters of the Universe T-Shirt 80er Jahre',
  'masters-of-the-universe-t-shirt-80er-jahre',
  'He-Man T-Shirt im Retro-Design — "Hergestellt in den 80ern". Offiziell lizenziertes Masters of the Universe Merch für alle, die mit He-Man aufgewachsen sind.',
  'By the power of Grayskull.',
  1559,
  'https://m.media-amazon.com/images/I/91bUedNVHBL.png',
  'https://www.amazon.de/dp/B0CXBS2CTD?tag=geeklist-21',
  false, false, 'babo', 'lifestyle', 'fashion'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Ramen Katze Japan Y2K Kawaii T-Shirt',
  'ramen-katze-japan-y2k-kawaii-t-shirt',
  'Kawaii T-Shirt mit Ramen-Katze im Y2K-Japan-Retro-Style — Anime-Manga-Ästhetik trifft Street-Fashion. Weicher Baumwolldruck, verschiedene Größen und Farben.',
  'Kawaii Noodle Energy.',
  1798,
  'https://m.media-amazon.com/images/I/A1DQdYd8EfL.png',
  'https://www.amazon.de/dp/B0CQD1Q8WC?tag=geeklist-21',
  false, false, 'queen', 'accessoires', 'fashion'
) ON CONFLICT (slug) DO NOTHING;
