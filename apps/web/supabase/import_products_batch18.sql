-- Batch 18 — 3 Produkte — is_published = TRUE (sofort live)
-- ON CONFLICT DO UPDATE → Upsert

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'SUPCASE MagSafe Wallet iPhone',
  'supcase-magsafe-wallet-iphone',
  E'MagSafe-Kartenhalter für iPhone 12 bis 17. Hält bis zu 5 Karten, RFID-Blockierung, verstellbarer Ständer — haftet magnetisch, kein Kleben, kein Aufreißen.\n\nFür alle, die ihre Geldbörse und ihr Handy zu einem Gerät machen wollen. Kein separates Portemonnaie mehr in der Hosentasche, kein Suchen vor dem Kassiervorgang.',
  'MagSafe-Kartenhalter für 5 Karten mit RFID-Schutz und Ständer — für iPhone 12–17',
  4799,
  'https://m.media-amazon.com/images/I/71QGjQP9jgL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0F8VJNT72?coliid=I114CQBG2P4DAG&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=1d7333e00dde58acaacf9ca96f0568fc&ref_=as_li_ss_tl',
  true, false, 'babo', 'tech', 'setup'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'CBDYWVR 2-in-1 Ladekabel mit Ständer',
  'cbdywvr-2in1-ladekabel-mit-staender',
  E'Ladekabel und Handyständer in einem. Typ-C, 240 Watt Schnellladung, 1,5 Meter, mehrfach verstellbar — das Kabel steht aufgestellt, damit das Telefon beim Laden nicht flach liegt.\n\nFür alle, die ihren Schreibtisch oder Nachttisch aufgeräumt halten wollen, ohne auf einen separaten Ständer zu verzichten. Funktioniert auch für Tablets, Laptops und Gaming-Geräte.',
  '240W Schnellladekabel mit eingebautem Ständer — Typ-C, 1,5m, für Handy, Tablet und Laptop',
  1289,
  'https://m.media-amazon.com/images/I/61P467fTrrL._SL1500_.jpg',
  'https://www.amazon.de/dp/B0G63HGHGV?coliid=I1VH5FPO3FLKX8&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=ff250a4b2272fd1d3ed2bfaf580ea438&ref_=as_li_ss_tl',
  true, false, 'babo', 'tech', 'setup'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'NIFBANG iPhone 17 Pro Max Hülle mit Magnetständer',
  'nifbang-iphone-17-pro-max-huelle-magnetstaender',
  E'Rahmenlose Aluminium-Hülle für das iPhone 17 Pro Max — 360° drehbarer Magnetständer, militärisch stoßfest, dünn. Kein Plastik-Bumper-Look, kein Masseklotz.\n\nFür alle, die eine Hülle wollen, die das Telefon schützt und gleichzeitig aussieht, als käme es direkt aus einer Produktpräsentation. Mit eingebautem Ständer für Schreibtisch und Küche.',
  'Rahmenlose Aluminium-Hülle mit 360°-Magnetständer — militärischer Schutz, minimales Design',
  2999,
  'https://m.media-amazon.com/images/I/71K7UA9iaYL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FRZ9TGZC?coliid=I24X3BTJNG5B9T&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=5afda6275706898279f95ede089a5393&ref_=as_li_ss_tl',
  true, false, 'babo', 'tech', 'setup'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;
