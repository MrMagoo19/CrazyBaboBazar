-- Batch 22: 5 neue Produkte (Switch 2, Nagelknipser, Futterbeutel, Sena 50S, Dashcam)

INSERT INTO products (
  slug, name, tagline, description,
  price_cents, currency, affiliate_url,
  image_url, image_urls,
  is_published, is_featured,
  shop_persona, shop_main_category, shop_sub_category,
  shop_tags
) VALUES

-- 1. FASTSNAIL RGB Ladestation Switch 2
(
  'fastsnail-ladestation-switch2-controller',
  'FASTSNAIL RGB Ladestation für Switch 2 Controller',
  'Ladestation mit 9 RGB-Modi für Joy-Con 2',
  E'Kein Kabelchaos mehr. Die FASTSNAIL RGB Ladestation lädt bis zu 4 Nintendo Switch 2 Joy-Con 2 gleichzeitig – mit 9 verschiedenen RGB-Lichtmodi die deinen Setup-Vibe setzen.\n\nEinfach einstecken, leuchten lassen, spielen. Kompatibel ausschließlich mit Switch 2 Joy-Con 2 – nicht für die alte Switch oder OLED-Version.',
  1499, 'EUR',
  'https://www.amazon.de/dp/B0F2MXRRN5?tag=geeklist-21&linkCode=ll2',
  'https://m.media-amazon.com/images/I/71QnV+5MVLL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71QnV+5MVLL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81tTW16DbeL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71MhhD7s3hL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/710v5yjtJCL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81+ifuQ2mTL._AC_SL1500_.jpg'
  ],
  true, false,
  'babo', 'gaming', 'setup',
  ARRAY['gaming', 'nintendo', 'switch', 'gadget']
),

-- 2. Lictin Elektrischer Nagelknipser
(
  'lictin-elektrischer-nagelknipser',
  'Lictin Elektrischer Nagelknipser Set',
  'Nägel schneiden mit Lupe, LED und Auffangbehälter',
  E'Schluss mit dem Nägel-überall-Disaster. Der Lictin Elektrische Nagelschneider hat eine eingebaute Lupe, LED-Licht und einen Auffangbehälter – kein Krümel landet mehr auf dem Sofa.\n\nIdeal für Babys, Senioren und alle, die sich beim normalen Knipser jedes Mal fast verletzen. USB-C aufladbar, leise, präzise. Das unscheinbarste Gadget mit dem größten Aha-Moment.',
  2799, 'EUR',
  'https://www.amazon.de/dp/B0GX5G3QHW?tag=geeklist-21&linkCode=ll2',
  'https://m.media-amazon.com/images/I/61U1m7bLTOL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61U1m7bLTOL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71lZRPsumML._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/711c3zmyLAL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71XEGw7qixL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61HO1BnG4dL._AC_SL1500_.jpg'
  ],
  true, false,
  'queen', 'wellness', 'gadget',
  ARRAY['haushalt', 'gadget', 'geschenk']
),

-- 3. Rudelkönig Futterbeutel Hunde
(
  'rudelkoenig-futterbeutel-hunde',
  'Rudelkönig Futterbeutel für Hunde',
  'Apportierbeutel für Hundetraining – robust & schnell griffbereit',
  E'Training ohne Fummeln. Der Rudelkönig Futterbeutel öffnet und schließt mit einer Hand – Leckerli raus, Lob geben, weitermachen. Robustes Material, leicht zu reinigen, passt an jeden Gürtel oder Rucksack.\n\nFür alle die ihren Hund ernsthaft trainieren wollen – ob Welpe oder alter Hase. Klein genug für die Jackentasche, groß genug für eine ganze Trainingseinheit.',
  1095, 'EUR',
  'https://www.amazon.de/dp/B07JB7HBYZ?tag=geeklist-21&linkCode=ll2',
  'https://m.media-amazon.com/images/I/71xWdF4yA5L._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71xWdF4yA5L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81HVSmwwSoL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81d0aVZ4e2L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/91iK8ubfpBL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/81+cFlj0jQL._AC_SL1500_.jpg'
  ],
  true, false,
  'babo', 'outdoor', 'haustier',
  ARRAY['outdoor', 'haustier', 'hund', 'geschenk']
),

-- 4. Sena 50S Motorrad Bluetooth Headset
(
  'sena-50s-motorrad-bluetooth-headset',
  'Sena 50S Motorrad Bluetooth Headset',
  'Mesh-Intercom mit Harman Kardon Sound – Doppelpack',
  E'Kommunizieren wie ein Profi. Das Sena 50S verbindet bis zu 24 Fahrer gleichzeitig über Mesh-Intercom – ohne Pairing, ohne Reichweitenprobleme, mit Sound by Harman Kardon.\n\nDrehrad-Bedienung mit dem Handschuh, Premium-Mikrofon für klare Stimme auch bei 130 km/h, und Bluetooth für Musik und Telefon gleichzeitig. Der Goldstandard unter den Motorrad-Headsets – als Doppelpack für dich und deinen Mitfahrer.',
  44900, 'EUR',
  'https://www.amazon.de/dp/B09NXCLRMR?tag=geeklist-21&linkCode=ll2',
  'https://m.media-amazon.com/images/I/61l1C+DexxL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61l1C+DexxL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/719T9doiVXL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71LnK+FUelL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/518mOM6Ze5L._AC_SL1200_.jpg',
    'https://m.media-amazon.com/images/I/71VsDas9E1L._AC_SL1500_.jpg'
  ],
  true, false,
  'babo', 'outdoor', 'motorrad',
  ARRAY['outdoor', 'motorrad', 'tech', 'gadget']
),

-- 5. Dashcam 4K 360° Vorne Hinten
(
  'dashcam-4k-360-vorne-hinten',
  'Dashcam Auto 4K/1080P Vorne & Hinten',
  '4-Kanal 360°-Dashcam mit 64GB SD, WiFi & Parküberwachung',
  E'Rundum abgesichert. Diese 4-Kanal-Dashcam filmt gleichzeitig vorne, hinten, links und rechts – in 4K vorne und 1080P überall sonst. 64GB SD-Karte inklusive, WiFi-App für direkten Abruf am Smartphone.\n\nG-Sensor erkennt Unfälle automatisch und sichert die Aufnahme. 8 Infrarot-LEDs für glasklare Nachtsicht, 3-Zoll IPS-Bildschirm, Parküberwachung bei ausgeschaltetem Motor. Wer einmal eine braucht, will nie ohne fahren.',
  9349, 'EUR',
  'https://www.amazon.de/dp/B0H1GR1435?tag=geeklist-21&linkCode=ll2',
  'https://m.media-amazon.com/images/I/71LieHPXnsL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/71LieHPXnsL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71zUMeaVSEL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/714JXS7dltL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71DEaMjNCuL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/7153G0-l86L._AC_SL1500_.jpg'
  ],
  true, false,
  'babo', 'tech', 'auto',
  ARRAY['tech', 'auto', 'gadget', 'sicherheit']
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
