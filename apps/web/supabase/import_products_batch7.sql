-- ============================================================
-- Import Batch 7: Sense Robot Schachroboter
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Schachroboter mit KI & Roboterarm Sense Robot',
  'schachroboter-mit-ki-roboterarm-sense-robot',
  'Schachbrett mit echtem Roboterarm und KI — 25 Schwierigkeitsstufen, 1200+ Übungen, Endspieltrainer und Sprach-Coaching. Verbindet sich mit Lichess und der App. Schach auf einem völlig neuen Level.',
  'Schach gegen einen Arm, der zurückspielt.',
  72165,
  'https://m.media-amazon.com/images/I/41u5OkD2TNL._AC_.jpg',
  'https://www.amazon.de/dp/B0F5YVFY1B?tag=geeklist-21',
  false, false, 'babo', 'gaming', 'tabletop'
) ON CONFLICT (slug) DO NOTHING;
