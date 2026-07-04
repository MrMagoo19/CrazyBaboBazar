-- =============================================================================
-- IMAGE_URLS ARRAY INITIALISIEREN
-- Produkte mit image_url aber leerem image_urls Array bekommen image_urls[0]
-- gesetzt, damit die Datenstruktur konsistent ist.
-- Der ImageSlider aktiviert sich erst bei image_urls.length > 1.
-- Für mehrere Bilder: ASIN im Amazon-Katalog nachschlagen und weitere URLs
-- manuell ergänzen, z.B.:
--   UPDATE products SET image_urls = ARRAY['url1','url2','url3']
--   WHERE slug = 'produkt-slug';
-- =============================================================================

UPDATE products
SET image_urls = ARRAY[image_url]
WHERE image_url IS NOT NULL
  AND (image_urls IS NULL OR array_length(image_urls, 1) = 0);

-- Prüfen
SELECT
  COUNT(*) FILTER (WHERE image_urls IS NULL OR array_length(image_urls, 1) = 0) AS ohne_image_urls,
  COUNT(*) FILTER (WHERE array_length(image_urls, 1) = 1)                       AS mit_einem_bild,
  COUNT(*) FILTER (WHERE array_length(image_urls, 1) > 1)                       AS mit_mehreren_bildern
FROM products
WHERE is_published = true;
