-- Import Batch 11: bite away Two Insektenstichheiler

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'bite away Two Elektronischer Insektenstichheiler',
  'bite-away-two-elektronischer-insektenstichheiler',
  'Elektronischer Stichheiler der Marke bite away — behandelt Insektenstiche sofort mit gezielter Wärme ohne Chemie. Dermatologisch getestet, für Kinder und Erwachsene, wiederaufladbar per USB.',
  'Kein Jucken. Keine Chemie. Nur Wärme.',
  2295,
  'https://m.media-amazon.com/images/I/41CLMvk36YL._AC_.jpg',
  'https://www.amazon.de/dp/B0CX5N9X9Z?tag=geeklist-21',
  false, false, 'wellness', 'outdoor', 'camping'
) ON CONFLICT (slug) DO NOTHING;
