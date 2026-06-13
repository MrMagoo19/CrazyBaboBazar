-- Geeklist: 7 Geek-Produkte + kuratierte Liste
-- Affiliate-Tag: geeklist-21

-- ── PRODUKTE ─────────────────────────────────────────────────────────────────

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES
(
  'flipper-zero',
  'Flipper Zero',
  'Das Schweizer Taschenmesser für Maker & Tüftler',
  E'NFC-Tags lesen, IR-Fernbedienungen emulieren, RFID klonen, Funksignale analysieren – der Flipper Zero kann alles davon gleichzeitig. Das kleine orange Gerät in Delfin-Form ist das Lieblingsspielzeug von Pentestern, Sicherheitsforschern und allen, die verstehen wollen wie die Welt um sie herum wirklich funktioniert.\n\nOpen-Source, hackbar, mit einer riesigen Community. Einmal in der Hand, nie wieder wegelegen.',
  21900, 'EUR',
  'https://www.amazon.de/dp/B0BFXKSFNT?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/613mclIMw1L._SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/613mclIMw1L._SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61fD7EkJBwL._SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61n3DffA+hL._SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61UZ9WfUCRL._SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71uNfIA1kJL._SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'gadget', ARRAY['tech', 'gaming', 'geeklist']
),
(
  'anbernic-rg35xx-h',
  'Anbernic RG35XX H',
  'Retro-Handheld mit 5.500+ Games vorinstalliert',
  E'NES, SNES, Game Boy, Mega Drive, PSP – alles auf einem 3,5-Zoll-IPS-Display in der Handfläche. Der Anbernic RG35XX H kommt mit einer 64GB-Karte und über 5.000 Spielen vorinstalliert.\n\nHDMI-Output für den TV, WiFi für Multiplayer-Sessions, Bluetooth für Controller. Linux-basiert, vollständig hackbar. Für alle, die ihre Kindheit in einer Hosentasche tragen wollen.',
  10860, 'EUR',
  'https://www.amazon.de/dp/B0CQSXPKQ6?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71HHiaSGZHL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71HHiaSGZHL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71hF50n0FhL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71EnLat5FoL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71XzduQK3fL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/712dciIwfRL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'gaming', 'retro', ARRAY['gaming', 'tech', 'geeklist']
),
(
  'pinecil-usbc-loetkolben',
  'PINECIL USB-C Lötkolben',
  'Der smarteste Lötkolben der Welt – in 6 Sekunden heiß',
  E'30 Gramm, USB-C betrieben, in 6 Sekunden auf Temperatur. Der PINECIL ist Open-Source, per Firmware erweiterbar und läuft mit jedem USB-C-Netzteil oder Powerbank.\n\nTemperaturgenauigkeit auf 1°C, automatischer Schlafmodus, präzises Spitzensystem. Für Maker, Reparatur-Enthusiasten und alle, die nie wieder einen alten Kolben anfassen wollen.',
  6326, 'EUR',
  'https://www.amazon.de/dp/B096X6SG13?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61IX8eET+dL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61IX8eET+dL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61x4Y3VEHZL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/51g--Z2xTRL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61CSh+xhtzL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/41Z8NiOnxML._AC_SL1000_.jpg'
  ],
  true, false, 'babo', 'tech', 'maker', ARRAY['tech', 'geeklist']
),
(
  'divoom-pixoo-led-panel',
  'Divoom Pixoo LED-Panel',
  'Pixel-Art-Display für den Schreibtisch',
  E'16×16 Pixel, unendliche Möglichkeiten. Zeigt Spotify-Visualizer, Krypto-Kurse, eigene Pixel-Art, GIFs, Uhrzeit oder Social-Media-Benachrichtigungen – alles konfigurierbar per App.\n\nDer Divoom Pixoo ist das perfekte Desk-Accessoire für alle, die ihren Workspace ein bisschen mehr nach Arcade-Halle aussehen lassen wollen.',
  NULL, 'EUR',
  'https://www.amazon.de/dp/B07HHXWN3C?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61YCcPzXvGL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61YCcPzXvGL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71EpB2y5MRL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71KSji1QLnL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71G0HBXGi0L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71E5oVo5XbL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'setup', ARRAY['tech', 'gaming', 'geeklist']
),
(
  'seek-thermal-compact-usbc',
  'Seek Thermal Compact USB-C',
  'Dein Smartphone wird zur Wärmebildkamera',
  E'Steck es in den USB-C-Port – und plötzlich siehst du Wärme. Wärmeverluste in Wänden aufspüren, überhitzte Elektronik erkennen, Tiere in der Nacht beobachten oder einfach Menschen wie Predator aussehen lassen.\n\nDie Seek Thermal Compact hat 206×156 Pixel Auflösung und funktioniert ohne App-Kauf direkt mit Android. Für alle, die einen echten Geek-Superhero-Moment wollen.',
  28900, 'EUR',
  'https://www.amazon.de/dp/B07RQ3J27Y?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71NC0C51nUL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71NC0C51nUL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71m3nE2cnOL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71e3kM7+zXL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61+Y-5sqDKL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71lvwv3OIEL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'gadget', ARRAY['tech', 'outdoor', 'geeklist']
),
(
  'sculpfun-s9-laser-engraver',
  'SCULPFUN S9 Laser-Graviermaschine',
  'Graviert Holz, Acryl & Metall – Maker-Einstieg ohne Riesenetat',
  E'Holz, Acryl, Leder, anodisiertes Aluminium – der SCULPFUN S9 graviert alles mit 90W-Laserleistung (Spitzenleistung). Open-Source-Software (LaserGRBL, LightBurn), einfacher Aufbau in 20 Minuten.\n\nPerfekt für alle die eigene Schilder, Schmuck, Geschenke oder einfach coole Sachen mit Laser brennen wollen – ohne 5-stelliges Budget.',
  21500, 'EUR',
  'https://www.amazon.de/dp/B09MFQQ9VC?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71kUSK2oZUL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71kUSK2oZUL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71r3RjF+yKL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71lbQQ2jChL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71l8k40wa4L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71T3ukGpyeL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'maker', ARRAY['tech', 'geeklist']
),
(
  'hhkb-professional-hybrid',
  'HHKB Professional Hybrid Type-S',
  'Die Heilige Schrift unter den Tastaturen',
  E'Wer einmal auf Topre-Switches getippt hat, will nie zurück. Das HHKB Professional Hybrid Type-S verbindet das ikonische 60%-Layout mit lautlosen Topre-Switches, Bluetooth (4 Geräte gleichzeitig) und USB-C.\n\nDesigned in Japan seit 1996, geliebt von Programmierern, Schriftstellern und allen, die verstehen, dass eine Tastatur kein Accessoire ist – sondern ein Werkzeug mit Charakter.',
  35999, 'EUR',
  'https://www.amazon.de/dp/B0BLVWQKPQ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61uKu9eagBL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61uKu9eagBL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61VigmGAeML._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/51mD7lKqHvL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/41NdDF+S0iL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/41kDAzbBgoL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'setup', ARRAY['tech', 'geeklist']
)
,
(
  'arc-reaktor-mk1-schwebend',
  'Arc Reaktor MK1 – Schwebend & Rotierend',
  'Tony Starks Herzstück – 1:1 Replika die wirklich schwebt',
  E'Kein Poster, kein 3D-Druck – sondern ein magnetisch schwebender, rotierender Arc Reactor in originalgetreuer 1:1-Größe. Die LED-Beleuchtung ist exakt wie im Film, das Schwebefeld stabil genug für den Dauerbetrieb.\n\nDas ultimative Desk-Objekt für jeden Marvel-Fan und Iron-Man-Enthusiasten. Sieht aus als hätte Stark Industries geliefert.',
  12900, 'EUR',
  'https://www.amazon.de/dp/B0D2HLTT4Y?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71KnOHrLGbL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71KnOHrLGbL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71yLY03uzbL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81waVzEtDkL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61n66XQcW4L._AC_SL1000_.jpg',
    'https://m.media-amazon.com/images/I/61t38hKybtL._AC_SL1000_.jpg',
    'https://m.media-amazon.com/images/I/61VrTwzOzdL._AC_SL1000_.jpg'
  ],
  true, false, 'babo', 'tech', 'setup', ARRAY['tech', 'gaming', 'geeklist']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  affiliate_url      = EXCLUDED.affiliate_url,
  image_url          = EXCLUDED.image_url,
  image_urls         = EXCLUDED.image_urls,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags;

-- ── LISTE ────────────────────────────────────────────────────────────────────

INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'geeklist',
  'Geeklist',
  'Für alle, die Technik nicht nur benutzen – sondern verstehen, aufmachen und besser machen wollen.',
  E'Kein Amazon-Bestseller-Einheitsbrei. Diese Liste ist für echte Geeks: Tools die Türen öffnen, Gadgets die zum Tüfteln einladen und Gear das Legenden-Status hat.\n\nJedes Produkt hier hat eine Geschichte – und du wirst sie jedem erzählen wollen der es sieht.',
  ARRAY[
    'flipper-zero',
    'anbernic-rg35xx-h',
    'hhkb-professional-hybrid',
    'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver',
    'seek-thermal-compact-usbc',
    'pinecil-usbc-loetkolben',
    'arc-reaktor-mk1-schwebend'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;
