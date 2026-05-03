-- ============================================================
-- Import Batch 4: LEGO Technic Ferrari SF-24
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LEGO Technic Ferrari SF-24 F1 Rennauto 1:8',
  'lego-technic-ferrari-sf-24-f1-rennauto',
  'Das offizielle LEGO Technic Ferrari SF-24 Formel-1-Modell im Maßstab 1:8 — mit funktionierendem V6-Motor, Getriebe, Lenkung und DRS. Über 1400 Teile, für Erwachsene, als Ausstellungsstück konzipiert.',
  'Scuderia Ferrari in deinen Händen.',
  17198,
  'https://m.media-amazon.com/images/I/51fR7dVI-PL._AC_.jpg',
  'https://www.amazon.de/dp/B0DHSCYDL2?tag=geeklist-21',
  false, false, 'babo', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;
