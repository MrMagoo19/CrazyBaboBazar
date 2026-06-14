-- =============================================================================
-- update_images_batch23.sql
-- Bilder für 10 von 11 Produkten aus import_products_batch23.sql
-- Erstellt: 2026-06-14
-- HINWEIS: monodeal-mini-fussball-2in1-tor-torwand fehlt noch (Link ausstehend)
-- =============================================================================

-- Bedsure Satin Kissenbezug
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/81uuaZZWxIL._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/81uuaZZWxIL._AC_SL1500_.jpg']
WHERE slug = 'bedsure-satin-kissenbezug-doppelpack';

-- Fujifilm Instax Mini 12
UPDATE products SET
  image_url  = 'https://asset.fujifilm.com/www/us/files/2023-02/b1a3e1e92bdb57535543849b294c654c/pic_mini12_ov_01.png',
  image_urls = ARRAY['https://asset.fujifilm.com/www/us/files/2023-02/b1a3e1e92bdb57535543849b294c654c/pic_mini12_ov_01.png']
WHERE slug = 'fujifilm-instax-mini-12-sofortbildkamera';

-- envami Rubbelkarte Weltkarte
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/81qiGpxEdfL._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/81qiGpxEdfL._AC_SL1500_.jpg']
WHERE slug = 'envami-rubbelkarte-weltkarte';

-- Kindle Paperwhite 16GB 2024
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/61iHqdmJXrL._AC_SL1000_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/61iHqdmJXrL._AC_SL1000_.jpg']
WHERE slug = 'kindle-paperwhite-16gb-2024';

-- Panini WM 2026 Sticker Album XXL Set
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/71bFNkb56kL._AC_SL1254_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/71bFNkb56kL._AC_SL1254_.jpg']
WHERE slug = 'panini-wm-2026-sticker-album-xxl-set';

-- Fußball Rebounder Trainingswand faltbar
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/81DzwsXkRGL._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/81DzwsXkRGL._AC_SL1500_.jpg']
WHERE slug = 'fussball-rebounder-trainingswand-faltbar';

-- WM 2026 Tippspiel Buch ganze Familie
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/71KO4VVyM4L._SL1499_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/71KO4VVyM4L._SL1499_.jpg']
WHERE slug = 'wm-2026-tippspiel-buch-ganze-familie';

-- MONODEAL Mini Fußballtor 2in1 — BILD FEHLT NOCH
-- UPDATE products SET
--   image_url  = '...',
--   image_urls = ARRAY['...']
-- WHERE slug = 'monodeal-mini-fussball-2in1-tor-torwand';
