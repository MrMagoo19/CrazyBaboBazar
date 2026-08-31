-- =============================================================================
-- update_american_football_food_stadium_images_2026.sql
-- Nachtrag zu draft_american_football_food_stadium_2026.sql
--
-- Aktualisiert ausschliesslich Bilder fuer die sechs bereits publizierten
-- Food-Stadium-Produkte. Keine Affiliate-URLs oder Produktdaten werden veraendert.
-- Die ersten fuenf Motive stammen vom offiziellen 40YARDS-CDN. Das Servietten-
-- Motiv ist die Amazon-CDN-Abbildung, die in einem indexierten Produkt-Listing
-- fuer denselben 40YARDS-Artikel verwendet wird.
-- =============================================================================

UPDATE products SET
  image_url  = 'https://www.40yards.de/cdn/shop/files/american-football-snack-stadium-holz_2048x2048.jpg?v=1735915975',
  image_urls = ARRAY['https://www.40yards.de/cdn/shop/files/american-football-snack-stadium-holz_2048x2048.jpg?v=1735915975']
WHERE slug = '40yards-american-football-snack-stadium-bambus';

UPDATE products SET
  image_url  = 'https://www.40yards.de/cdn/shop/products/40yards-american-football-schusselschale-aus-keramik-massstabsgetreu-434703_2048x.jpg?v=1701705909',
  image_urls = ARRAY['https://www.40yards.de/cdn/shop/products/40yards-american-football-schusselschale-aus-keramik-massstabsgetreu-434703_2048x.jpg?v=1701705909']
WHERE slug = '40yards-american-football-bowl-keramik-xxl';

UPDATE products SET
  image_url  = 'https://www.40yards.de/cdn/shop/files/dipschalen-football-form_2048x.jpg?v=1704985684',
  image_urls = ARRAY['https://www.40yards.de/cdn/shop/files/dipschalen-football-form_2048x.jpg?v=1704985684']
WHERE slug = '40yards-american-football-dipschalen-3er-set';

UPDATE products SET
  image_url  = 'https://www.40yards.de/cdn/shop/products/40yards-american-football-bierglas-2er-set-mit-erhabener-naht-307179_2048x2048.jpg?v=1675610056',
  image_urls = ARRAY['https://www.40yards.de/cdn/shop/products/40yards-american-football-bierglas-2er-set-mit-erhabener-naht-307179_2048x2048.jpg?v=1675610056']
WHERE slug = '40yards-american-football-bierglaeser-2er-set';

UPDATE products SET
  image_url  = 'https://www.40yards.de/cdn/shop/products/40yards-american-football-zahnstocher-cocktail-spiesse-burger-spiesse-50-stuck-488326.jpg?v=1675609526',
  image_urls = ARRAY['https://www.40yards.de/cdn/shop/products/40yards-american-football-zahnstocher-cocktail-spiesse-burger-spiesse-50-stuck-488326.jpg?v=1675609526']
WHERE slug = '40yards-american-football-zahnstocher-30er';

UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/61YcFrB%2BU5L._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/61YcFrB%2BU5L._AC_SL1500_.jpg']
WHERE slug = '40yards-american-football-servietten-spielfeld';

-- Read-only verification: expected result is 6 rows with non-empty image_url
-- and one-element image_urls arrays.
SELECT slug, image_url, cardinality(image_urls) AS image_count
FROM products
WHERE slug IN (
  '40yards-american-football-snack-stadium-bambus',
  '40yards-american-football-bowl-keramik-xxl',
  '40yards-american-football-dipschalen-3er-set',
  '40yards-american-football-bierglaeser-2er-set',
  '40yards-american-football-zahnstocher-30er',
  '40yards-american-football-servietten-spielfeld'
)
ORDER BY slug;
