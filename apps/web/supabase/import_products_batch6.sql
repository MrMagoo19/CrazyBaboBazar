-- ============================================================
-- Import Batch 6: Sense Robot Go KI-Go-Brett
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'KI Go-Brett mit Roboterarm Sense Robot',
  'ki-go-brett-mit-roboterarm-sense-robot',
  'Das erste Go-Brett mit KI und echtem Roboterarm — der Arm platziert die Steine automatisch. Interaktives Lernsystem für Anfänger bis Fortgeschrittene, mit Spielwiederholung und KI-Trainer. Weiqi auf einem neuen Level.',
  'Go spielen gegen echte KI mit Roboterarm.',
  87900,
  'https://m.media-amazon.com/images/I/41hoP+KJZjL._AC_.jpg',
  'https://www.amazon.de/dp/B0F2FHGYLX?tag=geeklist-21',
  false, false, 'babo', 'gaming', 'tabletop'
) ON CONFLICT (slug) DO NOTHING;
