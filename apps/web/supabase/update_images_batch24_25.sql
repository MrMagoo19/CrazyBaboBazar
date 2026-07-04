-- =============================================================================
-- update_images_batch24_25.sql
-- Bilder für batch24 + batch25 Produkte
-- Erstellt: 2026-06-20
-- STATUS: 6 von 9 gefunden — 3 noch offen (Kronkorken-Pistole, Boxsack, Multitool)
-- =============================================================================

-- ✅ Coddies Fisch-Schlappen (via coddies.com)
UPDATE products SET
  image_url  = 'https://www.coddies.com/cdn/shop/files/1_16_1800x1800.jpg?v=1731513687',
  image_urls = ARRAY['https://www.coddies.com/cdn/shop/files/1_16_1800x1800.jpg?v=1731513687']
WHERE slug = 'coddies-fisch-schlappen-flip-flops';

-- ✅ Coddies Blobfish Plüsch-Hausschuhe (via coddies.com)
UPDATE products SET
  image_url  = 'https://www.coddies.com/cdn/shop/files/1_11_1800x1800.jpg?v=1731509217',
  image_urls = ARRAY['https://www.coddies.com/cdn/shop/files/1_11_1800x1800.jpg?v=1731509217']
WHERE slug = 'coddies-blobfish-hausschuhe-plusch';

-- ✅ Divoom MiniToo Retro PC-Lautsprecher (via divoom.com)
UPDATE products SET
  image_url  = 'https://divoom.com/cdn/shop/files/minitoo-1.jpg',
  image_urls = ARRAY['https://divoom.com/cdn/shop/files/minitoo-1.jpg']
WHERE slug = 'divoom-minitoo-retro-pc-lautsprecher-pixel';

-- TODO: Kronkorken-Pistole (B0DPJSVVFL) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'flaschenoffner-pistole-kronkorken-2er-pack';

-- TODO: Schreibtisch-Boxsack (B07CXMHX7G) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'schreibtisch-boxsack-saugnapf-buero';

-- TODO: IKAAR Multitool Kreditkarte (B07TG1YTG4) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'ikaar-multitool-kreditkarte-11in1-edelstahl';

-- ✅ Baby Mop Strampler (via Amazon CDN)
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/61eSDn+yc6L._AC_SX679_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/61eSDn+yc6L._AC_SX679_.jpg']
WHERE slug = 'baby-mop-strampler-krabbeln-putzen';

-- ✅ Pomodoro Timer Cube (via Amazon CDN)
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/61MYYMQvzDL._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/61MYYMQvzDL._AC_SL1500_.jpg']
WHERE slug = 'farerkass-pomodoro-timer-cube-countdown';

-- ✅ YUNZII QL75 Tastatur (via Amazon CDN)
UPDATE products SET
  image_url  = 'https://m.media-amazon.com/images/I/81p7yy-k2HL._AC_SL1500_.jpg',
  image_urls = ARRAY['https://m.media-amazon.com/images/I/81p7yy-k2HL._AC_SL1500_.jpg']
WHERE slug = 'yunzii-ql75-retro-schreibmaschinen-tastatur';
