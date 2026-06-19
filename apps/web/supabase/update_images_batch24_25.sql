-- =============================================================================
-- update_images_batch24_25.sql
-- Bilder für batch24 + batch25 Produkte
-- Erstellt: 2026-06-20
-- STATUS: 3 von 9 gefunden — 6 noch offen (mit TODO markiert)
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

-- TODO: Baby Mop Strampler (B0FY3D8VJY) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'baby-mop-strampler-krabbeln-putzen';

-- TODO: Pomodoro Timer Cube (B0DZ5SNRKD) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'farerkass-pomodoro-timer-cube-countdown';

-- TODO: YUNZII QL75 Tastatur (B0FFN19KR9) — Bild noch ausstehend
-- UPDATE products SET image_url = '...', image_urls = ARRAY['...'] WHERE slug = 'yunzii-ql75-retro-schreibmaschinen-tastatur';
