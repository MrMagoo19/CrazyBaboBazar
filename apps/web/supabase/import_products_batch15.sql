-- Batch 15 — 2 Produkte
-- is_published = false → nach Review manuell publishen

-- B0D9KLY174 — Rosenstein & Söhne Warmhalteplatte — queen · kueche · gadgets — 49,54€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Rosenstein & Söhne Rollbare Warmhalteplatte',
  'rosenstein-soehne-rollbare-warmhalteplatte',
  E'Rollbare Silikonmatte, die Speisen und Getränke warm hält — einstellbar zwischen 55 und 100°C, 61 × 40 cm groß, 250 Watt. Keine Töpfe auf der Platte, keine Teelichter unter dem Fondue-Set. Einfach drauflegen, Temperatur einstellen, fertig.\n\nFür Buffets, Spieleabende, lange Tafelrunden oder alle, die aufgehört haben zu essen, bevor das Essen kalt wird. Rollbar — passt in eine Schublade, wenn man sie nicht braucht.',
  'Rollbare Silikon-Warmhalteplatte — 55–100°C, 61×40cm, kein kaltes Essen mehr',
  4954,
  'https://m.media-amazon.com/images/I/61SQaDw-ETL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0D9KLY174?coliid=IVOOEQTGL6SDU&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=0d8f8b1cf8baa6fca121c574b5503613&ref_=as_li_ss_tl',
  false, false, 'queen', 'kueche', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- B0CQ48XS39 — FAELNK Toilettengolf Set — babo · lifestyle · gadgets — 10,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'FAELNK Toilettengolf Set 7-teilig',
  'faelnk-toilettengolf-set',
  E'Sieben Teile, ein Ziel: den Besuch der Toilette in eine Golfrunde verwandeln. Schläger (65 cm), Puttingmatte, zwei Bälle, Türhänger — alles dabei, nichts fehlt.\n\nDas Geschenk für alle, die ohnehin zu lange auf der Toilette sitzen und das wenigstens produktiv nutzen wollen. Funktioniert auch als Bürogeschenk. Oder als ehrliche Aussage über die Freizeit eines Menschen.',
  '7-teiliges Mini-Golf-Set fürs Badezimmer — Schläger, Matte, Bälle, Türhänger inklusive',
  1099,
  'https://m.media-amazon.com/images/I/81N65GE6HDL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CQ48XS39?coliid=I1GQ71YPCJNA0B&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=294573afe06a49d310b770114d9f214f&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;
