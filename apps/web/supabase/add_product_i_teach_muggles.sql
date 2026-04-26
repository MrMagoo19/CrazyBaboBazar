-- ============================================================
-- Neues Produkt: "I Teach Muggles" Jutebeutel – Lehrer Geschenk
-- ASIN: B09RB6YNLV | Affiliate-Tag: geeklist-21
-- image_url muss noch manuell ergänzt werden
-- ============================================================

insert into products (
  slug,
  name,
  tagline,
  description,
  price_cents,
  currency,
  affiliate_url,
  image_url,
  is_published,
  is_featured,
  shop_persona,
  shop_main_category,
  shop_sub_category,
  amazon_category,
  brand
) values (
  'tradercat-i-teach-muggles-jutebeutel-lehrer',

  '"I Teach Muggles" Jutebeutel – Geschenk für Lehrer',

  'Das Geschenk für Lehrer mit Sinn für Humor',

  'Wer kennt das nicht: Man sucht ein Geschenk für Lehrer und landet bei Kaffeetassen oder Pralinen. Nicht mehr. Dieser Jutebeutel von tradercat trifft genau den Nerv von Lehrerinnen und Lehrern, die Harry Potter lieben – mit dem Aufdruck „I Teach Muggles". Handgemacht und in Deutschland gedruckt, aus 100 % Baumwolle, 200 g/m². Der Beutel ist 38 × 42 cm groß, fasst 10 Liter und hat 67 cm lange Henkel – passt über die Schulter. Stabiles Material, das auch nach vielen Wäschen noch gut aussieht. Ein Geschenk das bleibt, nicht im Schrank verstaubt.',

  999,
  'EUR',

  'https://www.amazon.de/dp/B09RB6YNLV?tag=geeklist-21',

  'https://m.media-amazon.com/images/I/51JjPRE2rYL._AC_SY879_.jpg',

  false, -- erst nach Review veröffentlichen
  false,

  'queen',
  'geschenke',
  'lehrer',

  'Taschen & Accessoires',
  'tradercat'
);
