-- ============================================================
-- Import Batch 8: 12 Produkte
-- ============================================================

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Makeblock Codey Rocky Programmierbarer Roboter',
  'makeblock-codey-rocky-programmierbarer-roboter',
  'Programmierbarer MINT-Roboter für Kinder ab 6 Jahren — mit Scratch und Python steuerbar. Codey ist der Controller, Rocky das fahrende Chassis. Ideal für den spielerischen Einstieg ins Programmieren.',
  'Programmieren lernen mit echtem Roboter.',
  14999,
  'https://m.media-amazon.com/images/I/51cSS9kVlsL._AC_.jpg',
  'https://www.amazon.de/dp/B07CGH8NZ7?tag=geeklist-21',
  false, false, 'miniboss', 'spielzeug', 'lernspielzeug'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Mammotion LUBA 3 AWD Mähroboter LiDAR',
  'mammotion-luba-3-awd-maehroboter-lidar',
  'Profi-Mähroboter mit 360° LiDAR und Dual-Kamera für bis zu 1500 m² — kein Begrenzungskabel nötig. AWD-Antrieb für Hanglagen bis 80%, App-Steuerung und autonome Navigation.',
  'Mähen ohne Kabel. Ohne Kompromisse.',
  199900,
  'https://m.media-amazon.com/images/I/41fXPz0r7QL._AC_.jpg',
  'https://www.amazon.de/dp/B0GQ6YMBJJ?tag=geeklist-21',
  false, false, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Shashibo Formwechsel-Box Magnetisch',
  'shashibo-formwechsel-box-magnetisch',
  'Preisgekrönter, patentierter Zauberwürfel mit 36 Magneten — verwandelt sich in über 70 verschiedene Formen. Unendlich umformbar, faszinierend für alle Altersgruppen.',
  'Ein Würfel. 70+ Formen.',
  2000,
  'https://m.media-amazon.com/images/I/41ZBx7UvTML._AC_.jpg',
  'https://www.amazon.de/dp/B07W7FLKRW?tag=geeklist-21',
  false, false, 'babo', 'diy', 'basteln'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'TOSY Flying Disc 108 RGB-LEDs Leuchtfrisbee',
  'tosy-flying-disc-108-rgb-leds-leuchtfrisbee',
  'Leuchtende Frisbee mit 108 RGB-LEDs — automatisch aktiviert beim Werfen, spektakuläre Lichtshow in der Luft. USB aufladbar, für Strand, Park und Festivals.',
  'Die Frisbee, die leuchtet wenn sie fliegt.',
  3599,
  'https://m.media-amazon.com/images/I/51+3VUFiE8L._AC_.jpg',
  'https://www.amazon.de/dp/B0B1YMNGS2?tag=geeklist-21',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Bitzee Disney Interaktives Digital-Haustier',
  'bitzee-disney-interaktives-digital-haustier',
  'Digitales Haustier zum echten Anfassen — berühre das Gehäuse und die Disney/Pixar-Charaktere reagieren darauf. Mit über 15 verschiedenen Charakteren zum Freischalten.',
  'Dein Disney-Charakter zum Streicheln.',
  2499,
  'https://m.media-amazon.com/images/I/51h35mD7IFL._AC_.jpg',
  'https://www.amazon.de/dp/B0CQN38M8W?tag=geeklist-21',
  false, false, 'miniboss', 'spielzeug', 'lernspielzeug'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  '4K Mini Überwachungskamera WLAN Nachtsicht',
  '4k-mini-ueberwachungskamera-wlan-nachtsicht',
  'Kompakte 4K-WLAN-Kamera mit Nachtsicht und Bewegungserkennung — diskret, einfach einzurichten, per App steuerbar. Ideal zur Haussicherung, Babykamera oder Haustierüberwachung.',
  'Klein. Scharf. Immer wachsam.',
  3799,
  'https://m.media-amazon.com/images/I/41sKGNfLmwL._AC_.jpg',
  'https://www.amazon.de/dp/B0GQMGSZ2H?tag=geeklist-21',
  false, false, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LED Leuchtbrille Aufladbar Party',
  'led-leuchtbrille-aufladbar-party',
  'Kabellose, aufladbare LED-Partybrille mit wechselnden Lichteffekten — perfekt für Festivals, Partys und Events. USB aufladbar, verschiedene Leuchtmodi, komfortables Gestell.',
  'Die Brille, die die Party startet.',
  1299,
  'https://m.media-amazon.com/images/I/51DPWH0lq0L._AC_.jpg',
  'https://www.amazon.de/dp/B09JZ716FM?tag=geeklist-21',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Welpen USB-Ladekabel Hunde-Design',
  'welpen-usb-ladekabel-hunde-design',
  'USB-Ladekabel im süßen Hunde-Welpen-Design — funktionales Alltagsaccessoire mit Niedlichkeitsfaktor. Kompatibel mit gängigen Anschlüssen, perfektes kleines Geschenk für Tierliebhaber.',
  'Aufladen mit Wow-Faktor.',
  1519,
  'https://m.media-amazon.com/images/I/41PZE3kDX3L.jpg',
  'https://www.amazon.de/dp/B0F28L9Z2K?tag=geeklist-21',
  false, false, 'queen', 'lifestyle', 'deko'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'COSRX PDRN Exosome Skinplaning Glaze Mask',
  'cosrx-pdrn-exosome-skinplaning-glaze-mask',
  'Koreanische Glass-Skin-Maske mit Lachs-DNA PDRN und Exosomen — verfeinert das Hautbild, spendet intensive Feuchtigkeit und verleiht der Haut einen glasigen Glow. 50ml mit Silikonpinsel.',
  'Korean Skincare für Glass Skin.',
  1445,
  'https://m.media-amazon.com/images/I/41PZE3kDX3L.jpg',
  'https://www.amazon.de/dp/B0FWK57DL4?tag=geeklist-21',
  false, false, 'wellness', 'beauty', 'kosmetik'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Ninabella Haarbürste ohne Ziepen',
  'ninabella-haarbuerste-ohne-ziepen',
  'Entwirrbürste für Damen, Herren und Kinder — speziell entwickelt, um Haare sanft zu entwirren ohne Schmerzen. Für alle Haartypen geeignet, auch nasses Haar.',
  'Bürsten ohne Schmerz.',
  999,
  'https://m.media-amazon.com/images/I/51kJdEcHRGL._AC_.jpg',
  'https://www.amazon.de/dp/B0BXDPJMQK?tag=geeklist-21',
  false, false, 'wellness', 'beauty', 'haarpflege'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LEGO FIFA Fußball-WM Pokal Editions Set',
  'lego-fifa-fussball-wm-pokal-editions-set',
  'Das offizielle LEGO Editions Set mit dem FIFA Fußball-Weltmeisterschaftspokal — detailgetreue Nachbildung des begehrten Trophäe. Für Fußball-Fans und LEGO-Sammler.',
  'Der WM-Pokal als LEGO-Modell.',
  13649,
  'https://m.media-amazon.com/images/I/41zRQrUMxFL._AC_.jpg',
  'https://www.amazon.de/dp/B0FPXDRR63?tag=geeklist-21',
  false, false, 'babo', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'FIFA World Cup 2026 Ballers Minifiguren 2er-Pack',
  'fifa-world-cup-2026-ballers-minifiguren-2er-pack',
  'Offiziell lizenzierte FIFA World Cup 2026 Minifiguren von ZURU — zufällige Spieler aus 2er-Blind-Pack. Sammelbare Fußball-Figuren zur WM 2026.',
  'Sammel dein WM-Dream-Team.',
  1898,
  'https://m.media-amazon.com/images/I/51P0dU0YNPL._AC_.jpg',
  'https://www.amazon.de/dp/B0FJJ9KFBC?tag=geeklist-21',
  false, false, 'miniboss', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;
