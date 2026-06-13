-- Batch 21: OIKKEI KI Wireless Maus (B0FR573N45)
INSERT INTO products (
  slug, name, tagline, description,
  price_cents, currency, affiliate_url,
  image_url, image_urls,
  is_published, is_featured,
  shop_persona, shop_main_category, shop_sub_category,
  shop_tags
) VALUES (
  'oikkei-ki-maus',
  'OIKKEI KI Wireless Maus',
  'Maus mit eingebautem KI-Assistenten & Laserpointer',
  E'Eine Maus, die mitdenkt – und mitschreibt. Die OIKKEI KI Wireless Maus hat ein eingebautes Mikrofon für Sprachaufnahmen direkt am Gerät: Meeting tippen, vorlesen lassen, KI-Zusammenfassung abrufen.\n\nPer Bluetooth oder 2,4-GHz-Funk verbunden, funktioniert sie als Presenter mit Laserpointer – ideal für alle, die Präsentationen halten oder hybrid arbeiten. USB-C wiederaufladbar, kein Akkukauf nötig.',
  9999,
  'EUR',
  'https://www.amazon.de/dp/B0FR573N45?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81mf6nQBTLL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/81mf6nQBTLL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61nS7x-eExL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71gpAgi2MdL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71CPp7vasDL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71Ee9A9cN1L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71OBP0pNu0L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/710bBTyKB8L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71myGlxSESL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61EQHOBb50L._AC_SL1500_.jpg'
  ],
  true, false,
  'babo', 'tech', 'setup',
  ARRAY['tech', 'ki', 'gadget', 'home-office']
)
ON CONFLICT (slug) DO UPDATE SET
  name          = EXCLUDED.name,
  tagline       = EXCLUDED.tagline,
  description   = EXCLUDED.description,
  price_cents   = EXCLUDED.price_cents,
  affiliate_url = EXCLUDED.affiliate_url,
  image_url     = EXCLUDED.image_url,
  image_urls    = EXCLUDED.image_urls,
  shop_persona  = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags     = EXCLUDED.shop_tags;
