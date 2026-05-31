-- Batch 17 — 3 Produkte
-- ON CONFLICT DO UPDATE → sofortiger Upsert, überschreibt vorhandene Einträge
-- is_published = false → nach Review manuell publishen

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Monster High Skullector Shorty — Killer Klowns',
  'monster-high-skullector-shorty-killer-klowns',
  E'Offizielle Monster High Skullector-Puppe aus der Killer Klowns from Outer Space-Kollaboration. Grüne Haare, gelbes Clown-Outfit, Ballonschuhe, Puppenständer — limitiertes Sammlerstück für Horror- und Popkultur-Fans.\n\nDie Skullector-Serie ist nicht für Kinder gedacht, sondern für Erwachsene, die wissen, dass gute Sammlerstücke aus den dunkelsten Ecken der Popkultur kommen. Und Killer Klowns from Outer Space ist genau die richtige Ecke.',
  'Limitierter Killer Klowns-Skullector — Sammelfigur für Horror-Fans mit Stil',
  8873,
  'https://m.media-amazon.com/images/I/81qiJkv6q2L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FK856NFW?coliid=I23DDW0PIPY3X4&colid=1VQK9PCRQEC5P&psc=0&linkCode=ll2&tag=geeklist-21&linkId=191d48a536bbed48ad195fad63c0db4f&ref_=as_li_ss_tl',
  false, false, 'babo', 'gaming', 'collectibles'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Jarlson Edelstahl-Trinkflasche Kinder 350ml',
  'jarlson-trinkflasche-kinder-350ml',
  E'Edelstahl-Trinkflasche für Kinder mit Strohhalm, auslaufsicher, 350 ml — Motiv Baustelle. Hält Getränke kalt oder warm, passt in die meisten Schulranzen-Flaschenhalter.\n\nKein Plastik, kein BPA, kein Umkippen im Rucksack. Für alle, die eine Kinderflasche suchen, die mehr als eine Saison überlebt.',
  'Auslaufsichere Edelstahl-Kinderflasche mit Strohhalm — 350ml, Motiv Baustelle',
  2595,
  'https://m.media-amazon.com/images/I/819U+KLuI5L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0G2T3DY8C?coliid=IQQTZTD6BW5EX&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=d1280598c34719f2bbe0160f42bf8652&ref_=as_li_ss_tl',
  false, false, 'miniboss', 'spielzeug', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Elektrische Wasserpistole mit LED',
  'elektrische-wasserpistole-mit-led',
  E'Automatische Wasserpistole mit LED-Lichtern, selbstansaugend, große Kapazität, ultralange Reichweite. Kein manuelles Pumpen — einmal ins Wasser tauchen, Abzug halten, fertig.\n\nFür alle, die Wasserkämpfe endlich auf ernstzunehmendem Niveau führen wollen. Funktioniert für Erwachsene und Kinder — und ist ehrlich gesagt für Erwachsene lustiger.',
  'Selbstansaugende Elektro-Wasserpistole mit LED — große Reichweite, kein Pumpen nötig',
  2519,
  'https://m.media-amazon.com/images/I/71n9jOdcgoL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0DL5S57FD?coliid=IDVAEA91AI2ZI&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=003b7afc03f5cebed126ff84c85eeb32&ref_=as_li_ss_tl',
  false, false, 'babo', 'outdoor', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents,
  image_url = EXCLUDED.image_url,
  affiliate_url = EXCLUDED.affiliate_url,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;
