-- =============================================================================
-- fix_monodeal_replace_littletom.sql
-- MONODEAL-Link war defekt — ersetzt durch LittleTom 2-in-1 Fussballtor
-- Erstellt: 2026-06-14
-- =============================================================================

-- 1. MONODEAL deaktivieren
UPDATE products SET is_published = false
WHERE slug = 'monodeal-mini-fussball-2in1-tor-torwand';

-- 2. LittleTom 2-in-1 Fussballtor einfügen
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'littletom-2in1-fussballtor-pop-up-torwand',
  'LittleTom 2in1 Pop-Up Fußballtor mit Torwand',
  'Vorderseite: Tor mit Netz. Rückseite: Torwand mit 5 Zielöffnungen — in Sekunden aufgebaut',
  E'Wenn WM-Fieber das Wohnzimmer verlässt und in den Garten zieht, braucht man das Richtige. Das LittleTom 2-in-1 Pop-Up Fußballtor ist in Sekunden aufgebaut — wie ein Wurfzelt, einfach ausklappen und fertig.\n\nVorderseite: vollwertiges Fußballtor (125x80 cm) mit robustem Netz. Rückseite umdrehen: Torwand mit 5 unterschiedlich großen Zielöffnungen für präzises Schusstraining. Faltbar für Transport und Lagerung, geeignet für Rasen, Beton und Kunstrasen.\n\nFür Kinder ab 3 Jahren und Erwachsene. Perfekt für WM-Fanabende im Garten, Grillpartys und alle die lieber schießen als zuschauen.',
  3999,
  'EUR',
  'https://www.amazon.de/dp/B0CNS6BGR7?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'miniboss',
  'sport',
  'fussball',
  ARRAY['sport', 'fussball', 'tor', 'garten', 'outdoor', 'kinder', 'wm-2026', 'training', 'spielen', 'pop-up']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;
