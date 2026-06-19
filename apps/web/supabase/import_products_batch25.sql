-- =============================================================================
-- import_products_batch25.sql
-- 4 Produkte: Baby Mop Strampler (Irrenhaus) + 3 Schreibtisch-Setup Gadgets
-- Erstellt: 2026-06-19
-- =============================================================================

-- Preis: 13,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'baby-mop-strampler-krabbeln-putzen',
  'Baby Mop Strampler',
  'Das Kind krabbelt. Der Boden glänzt. Win-Win.',
  E'Irgendwann hat jemand gefragt: Was wenn das Baby beim Krabbeln gleichzeitig den Boden putzt? Und dann hat er es gemacht.\n\nDer Baby Mop Strampler hat Mopp-Material an den Armen und Beinen — beim Krabbeln wischt das Baby automatisch den Boden. Aus weichem, waschbarem Stoff, verfügbar in mehreren Farben und Größen von 0 bis 24 Monate.\n\nNatürlich ist das kein ernsthaftes Putzgerät. Aber als Geschenk zur Babyparty, als erstes Outfit für den Familienchat oder einfach als Beweis dass das Internet manchmal Wunder vollbringt — absolute Topklasse. Eines der meistgeklickten Baby-Produkte auf Amazon.',
  1399,
  'EUR',
  'https://www.amazon.de/dp/B0FY3D8VJY?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'miniboss',
  'irrenhaus',
  'viral-gadgets',
  ARRAY['irrenhaus', 'viral', 'baby', 'strampler', 'mop', 'wtf', 'geschenk', 'babyparty', 'lustig', 'tiktok-viral', 'unter-20-euro']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  affiliate_url      = EXCLUDED.affiliate_url,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags,
  is_published       = EXCLUDED.is_published;

-- Preis: 19,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'farerkass-pomodoro-timer-cube-countdown',
  'Pomodoro Timer Cube',
  'Umdrehen. Timer läuft. Prokrastination hat keine Chance.',
  E'Kein App-Setup. Kein Handy entsperren. Kein Ablenkungspotenzial. Einfach den Würfel umdrehen — und arbeiten.\n\nDer Pomodoro Timer Cube von Farerkass hat vier Seiten mit voreingestellten Zeiten: 5, 10, 20 und 25 Minuten. LED-Display, USB-C-Ladefunktion, leiser Vibrationsalarm. Für Büro, Homeoffice, Küche, Sport — überall wo Zeitmanagement zählt ohne dass das Smartphone die Konzentration sabotiert.\n\n4,4 Sterne bei 137 Bewertungen. Das Gadget das Produktivitäts-Nerds und ADHS-Gehirne gleichermassen lieben. Passt auf jeden Schreibtisch und macht optisch mehr her als ein Küchenwecker.',
  1999,
  'EUR',
  'https://www.amazon.de/dp/B0DZ5SNRKD?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'tech',
  'schreibtisch-setup',
  ARRAY['tech', 'schreibtisch-setup', 'produktivitaet', 'timer', 'pomodoro', 'homeoffice', 'büro', 'gadget', 'unter-20-euro', 'fokus', 'zeitmanagement']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  affiliate_url      = EXCLUDED.affiliate_url,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags,
  is_published       = EXCLUDED.is_published;

-- Preis: 101,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'yunzii-ql75-retro-schreibmaschinen-tastatur',
  'YUNZII QL75 Retro Schreibmaschinen Tastatur',
  'Schreibmaschinenlook. Mechanical Soul. QMK-Freiheit.',
  E'Wer sagt dass ein Schreibtisch-Setup funktional und langweilig sein muss, hat diese Tastatur noch nicht gesehen.\n\nDie YUNZII QL75 sieht aus wie eine Schreibmaschine aus den 1950ern — und verhält sich wie eine moderne Enthusiasten-Tastatur. Runde Punk-Keycaps, Hot-Swap-Switches (Onyx Tactile), QMK/VIA-kompatibel für vollständige Tastenprogrammierung, RGB-Beleuchtung. Verbindung via 2,4 GHz Dongle, USB-C oder Bluetooth 5.0 — wechselt zwischen bis zu drei Geräten.\n\n4,4 Sterne bei 218 Bewertungen. Für alle die ihren Schreibtisch zur Aussage machen wollen. Holz-Finish, verfügbar in mehreren Farbvarianten. Das Einzelstück unter den Tastaturen.',
  10199,
  'EUR',
  'https://www.amazon.de/dp/B0FFN19KR9?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'tech',
  'schreibtisch-setup',
  ARRAY['tech', 'schreibtisch-setup', 'tastatur', 'mechanical', 'retro', 'qmk', 'schreibmaschine', 'gaming', 'homeoffice', 'setup', 'premium']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  affiliate_url      = EXCLUDED.affiliate_url,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags,
  is_published       = EXCLUDED.is_published;

-- Preis: 69,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'divoom-minitoo-retro-pc-lautsprecher-pixel',
  'Divoom MiniToo Retro PC-Lautsprecher',
  'Sieht aus wie ein Rechner von 1985. Klingt wie 2026.',
  E'Divoom hat einen Bluetooth-Lautsprecher gebaut der aussieht wie ein Retro-PC der 80er — komplett mit Pixel-Display auf dem du eigene Animationen, Uhren, Wetter oder Nachrichten anzeigen kannst.\n\nBluetooth und USB-Audio, Wecker mit weißem Rauschen, DIY Pixelmotive via App. Das Display ist programmierbar — perfekt für Schreibtisch-Setups die auffallen sollen. Beige-Gehäuse im klassischen Computer-Look, ca. 11 cm groß.\n\n4,4 Sterne bei 168 Bewertungen. Für Gaming-Setups, Homeoffice-Tische und alle die Nostalgie mit moderner Technik verbinden wollen. Eines der besten Schreibtisch-Gadgets wenn man nicht einfach nur einen Lautsprecher will — sondern eine Persönlichkeit.',
  6999,
  'EUR',
  'https://www.amazon.de/dp/B0FRF3XGQ4?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'tech',
  'schreibtisch-setup',
  ARRAY['tech', 'schreibtisch-setup', 'lautsprecher', 'bluetooth', 'retro', 'pixel', 'divoom', 'gaming', 'homeoffice', 'setup', 'geschenk']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  affiliate_url      = EXCLUDED.affiliate_url,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags,
  is_published       = EXCLUDED.is_published;
