-- Geeklist Batch 2: 3 neue Produkte + Liste aktualisieren

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES
(
  'hoverair-x1-pro-drohne',
  'HOVERAir X1 PRO 4K Drohne',
  'Die Drohne die sich selbst fliegt',
  E'Kein Führerschein, kein Stress. Die HOVERAir X1 PRO startet aus der Hand, erkennt dein Gesicht und filmt dich automatisch in 4K – mit 15 vorprogrammierten Flugmodi wie Orbit, Follow-Me oder Zoom-Out.\n\nRückkollisionserkennung, faltbares Design das in jede Hosentasche passt, und kein DJI-Kurs nötig. Die Drohne für alle, die Content wollen – nicht einen Pilotenschein.',
  49900, 'EUR',
  'https://www.amazon.de/dp/B0DGTHCKKS?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/51202O2hrJL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/51202O2hrJL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71eO46tlwKL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/714t95-4JRL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71k5qhy4MTL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71ZrV-IUvOL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'gadget', ARRAY['tech', 'outdoor', 'geeklist']
),
(
  'ragnok-ergostrike7-gaming-maus',
  'RAGNOK ErgoStrike7 Gaming-Maus',
  'FPS-Maus mit echtem Rückstoß beim Schießen',
  E'Eine Maus die zurückschlägt – buchstäblich. Die RAGNOK ErgoStrike7 hat eine eingebaute Rückstoßfunktion die bei jedem Schuss vibriert und kickt, genau wie ein echtes Gewehr. Pistolengriff-Design für maximale Kontrolle.\n\nKabellos oder per USB, ergonomisch vertikales Design für ermüdungsfreies Spielen. Für FPS-Spieler die Immersion ernst nehmen.',
  9900, 'EUR',
  'https://www.amazon.de/dp/B0F7LN26V7?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61jrL+lQTgL._AC_SL1248_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61jrL+lQTgL._AC_SL1248_.jpg',
    'https://m.media-amazon.com/images/I/71asGSM7GTL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61MrbU0mIOL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/61qd3TJByDL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/51boAzf-J-L._AC_SL1248_.jpg'
  ],
  true, false, 'babo', 'gaming', 'setup', ARRAY['gaming', 'tech', 'geeklist']
),
(
  'phonesoap-3-uv-desinfektion',
  'PhoneSoap 3 UV-Smartphone-Desinfektion',
  'Dein Handy ist dreckiger als eine Toilette – fix it',
  E'Studien zeigen: das Smartphone hat 10x mehr Bakterien als ein Toilettensitz. Die PhoneSoap 3 desinfiziert es in 10 Minuten mit UV-C-Licht – klinisch geprüft, 99,99% der Keime eliminiert.\n\nGleichzeitig lädt es dein Handy auf. Passt für alle Smartphones bis Größe XL. Einmal benutzt, nie wieder ohne.',
  6889, 'EUR',
  'https://www.amazon.de/dp/B07G8Q8L1R?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61X1SsENUlL._AC_SL1500_.jpg',
  ARRAY[
    'https://m.media-amazon.com/images/I/61X1SsENUlL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71olxbomq+L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71B9snNoPpL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/713ymuWQV3L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/51hOu57UEvL._AC_SL1500_.jpg'
  ],
  true, false, 'babo', 'tech', 'gadget', ARRAY['tech', 'haushalt', 'geeklist']
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

-- Geeklist aktualisieren
UPDATE lists
SET product_slugs = ARRAY[
  'flipper-zero',
  'hoverair-x1-pro-drohne',
  'anbernic-rg35xx-h',
  'hhkb-professional-hybrid',
  'ragnok-ergostrike7-gaming-maus',
  'arc-reaktor-mk1-schwebend',
  'divoom-pixoo-led-panel',
  'sculpfun-s9-laser-engraver',
  'seek-thermal-compact-usbc',
  'phonesoap-3-uv-desinfektion',
  'pinecil-usbc-loetkolben'
]
WHERE slug = 'geeklist';
