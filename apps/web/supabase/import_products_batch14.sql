-- Batch 14 — 11 Produkte
-- is_published = false → nach Review manuell publishen

-- 1. Glocusent Leselampe Hals — queen · lifestyle · gadgets — 23,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Glocusent Leselampe Hals',
  'glocusent-leselampe-hals',
  E'Nackenlampe statt Stehlampe. Sitzt am Hals, beleuchtet genau das, was du gerade liest — ohne Schatten, ohne Kabel, ohne Aufwand. Drei Farbtemperaturen, sechs Helligkeitsstufen, 80 Stunden Akkulaufzeit.\n\nFür alle, die abends lesen, stricken oder basteln, ohne die ganze Deckenbeleuchtung anschmeißen zu wollen. Oder für alle, die neben einer schlafenden Person liegen und trotzdem noch ein Kapitel wollen.',
  'Nackenlampe mit 80h Akku — 3 Farben, 6 Stufen, beide Hände bleiben frei',
  2399,
  'https://m.media-amazon.com/images/I/614xoTCz--L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B07WNRN9WQ?coliid=I3T0LBESDXLFU3&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=b14e8b3221e33e06dc224b16f990a0f3&ref_=as_li_ss_tl',
  false, false, 'queen', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 2. Ollny Camping Lichterkette 10M — babo · outdoor · gadgets — 16,xx€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Ollny Camping Lichterkette 10M',
  'ollny-camping-lichterkette-10m',
  E'Zehn Meter aufrollbare Lichterkette, die gleichzeitig Campinglampe und Taschenlampe ist. USB-aufladbar, wasserdicht, acht Leuchtmodi, Timer und Dimmfunktion — alles in einem kompakten Aufrollsystem.\n\nFür Zelt, Wohnwagen, Balkon, Gartenparty oder den Kofferraum für alle Fälle. Kein Kabelsalat, kein separates Gerät für jeden Zweck.',
  '4-in-1 Outdoor-Lichterkette — 10m, aufrollbar, Campinglampe und Taschenlampe in einem',
  1600,
  'https://m.media-amazon.com/images/I/71KbFqYX5QL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0DNW8P9HY?coliid=I1S5ZWR6K6PGNR&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=b55e14e83ab2def67087926d78cedade&ref_=as_li_ss_tl',
  false, false, 'babo', 'outdoor', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 3. SAMHOUSING Tablet-Ständer 360° — babo · tech · setup — 22,94€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'SAMHOUSING Tablet-Ständer 360°',
  'samhousing-tablet-staender-360',
  E'Universeller Ständer für Tablets und Handys von 4,5 bis 13 Zoll. Vollständig drehbar, höhenverstellbar, stabil genug für iPad Pro. Kein Wackeln beim Tippen, kein Verrutschen beim Streamen.\n\nFür den Schreibtisch, die Küche oder das Sofa. Wer sein Tablet ständig irgendwo anlehnt und hofft, dass es nicht kippt, kennt das Problem.',
  'Universeller Tablet- und Handyständer — 360° drehbar, für Geräte bis 13 Zoll',
  2294,
  'https://m.media-amazon.com/images/I/61f3zclgx3L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B09ZLCFF9F?coliid=I1DX5VZL56QKC2&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=db64b6800ed7704a15ed010abc498b4f&ref_=as_li_ss_tl',
  false, false, 'babo', 'tech', 'setup'
) ON CONFLICT (slug) DO NOTHING;

-- 4. BBQ Würstchenhalter Männchen (3er Set) — babo · lifestyle · gadgets — 13,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'BBQ Würstchenhalter Männchen (3er Set)',
  'bbq-wuerstchenhalter-maennchen-3er-set',
  E'Drei Edelstahl-Würstchenhalter im stehenden Männchen-Design — für Grill, Camping und alle, die ihre Hot Dogs mit Haltung servieren wollen. Stabil, hitzebeständig, leicht zu reinigen.\n\nEin Grillabend-Gadget, das niemand braucht, aber jeder will, sobald er es sieht. Für Erwachsene, die wissen, dass Grillen auch Unterhaltung ist.',
  'Edelstahl-Würstchenhalter im Männchen-Design — 3er Set für Grill und Camping',
  1399,
  'https://m.media-amazon.com/images/I/7189O01DqiL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0D4TZNPP7?coliid=INK5XO73INXT0&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=29d9819502681a601b6fbc7ac146fc6d&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 5. Prisma-Brille Lazy Glasses — babo · lifestyle · gadgets — 14,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Prisma-Brille Lazy Glasses',
  'prisma-brille-lazy-glasses',
  E'Brille mit 90°-Prismengläsern — liegend lesen, TV schauen oder Handy scrollen, ohne den Kopf zu heben. Kein Nackenknicken, kein Arm hochhalten, kein Unbehagen nach zehn Minuten Sofa.\n\nTechnisch gesehen ein optisches Instrument. Praktisch gesehen das ehrlichste Produkt im gesamten Sortiment: Es löst ein Problem, das alle haben und das niemand offiziell zugeben will.',
  'Liegend lesen ohne Nackenknicken — Prismengläser für Sofa, Bett und ehrliche Faulheit',
  1499,
  'https://m.media-amazon.com/images/I/51+I0iKtfaL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B09PTGN4XM?coliid=I36DKOK5XEPG5O&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=a3c5877738268ee6b1e4694f0085f76a&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 6. XGIMI Horizon Ultra 4K Projektor — babo · tech · gadgets — 1199,00€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'XGIMI Horizon Ultra 4K Projektor',
  'xgimi-horizon-ultra-4k-projektor',
  E'4K-Projektor mit Dolby Vision, 2.300 ISO Lumen und zwei Harman-Kardon-Lautsprechern mit je 12 Watt. Android TV 11, optischer Zoom, automatische Trapezkorrektur. Kein separater Soundbar nötig.\n\nFür alle, die ein Heimkino wollen, aber keinen Fernseher. Oder einen zweiten Bildschirm in Übergröße. Oder die endlich wieder einen Filmabend veranstalten wollen, ohne dass alle auf ein 55-Zoll-Panel starren.',
  '4K mit Dolby Vision und Harman Kardon Sound — XGIMI macht jede Wand zum Kino',
  119900,
  'https://m.media-amazon.com/images/I/61F3zYqHqiL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CB3FN1FM?coliid=I192MXH272HJD2&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=6ee9e762d4f9bfff2604b83d4eff77fe&ref_=as_li_ss_tl',
  false, true, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 7. Deadpool Auto-Anhänger — babo · lifestyle · gadgets — 12,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Deadpool Auto-Anhänger Ornament',
  'deadpool-auto-anhaenger-ornament',
  E'Deadpool am Rückspiegel — für alle, die auch beim Fahren nicht auf Charakter verzichten wollen. Kleines Anime-Ornament, großes Statement.\n\nKein Nutzen außer dem, den man nicht unterschätzen sollte: ein Grinsen beim Einsteigen. Für Deadpool-Fans, Anime-Liebhaber oder alle, die ihrem Auto einfach eine Persönlichkeit geben wollen.',
  'Deadpool bewacht deinen Rückspiegel — Anime-Ornament für Fahrer mit Geschmack',
  1299,
  'https://m.media-amazon.com/images/I/61W3hYpoCFL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0BXKGP3V4?coliid=I1PG8R6QDRH0VA&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=b1307509b11d1b4e24fdf969840180d8&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 8. Ninja StaySharp Messerset 6-teilig — queen · kueche · gadgets — 164,90€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Ninja StaySharp Messerset 6-teilig',
  'ninja-staysharp-messerset-6-teilig',
  E'Sechs Edelstahlmesser mit eingebautem Schärfer direkt im Block — kein separates Schärfgerät, kein Herausziehen vergessen. Dazu Küchen- und Kräuterschere. Alles in Weiß.\n\nFür alle, die irgendwann aufgehört haben, ihre Messer zu schärfen, weil es zu umständlich war. Ninja löst das Problem durch Einbau: Der Schärfer sitzt im Schlitz, beim Herausziehen wird automatisch geschärft.',
  '6 Messer mit eingebautem Schärfer im Block — scharf halten ohne extra Aufwand',
  16490,
  'https://m.media-amazon.com/images/I/711eOYNO9vL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CLP63P3G?coliid=I2DHPQSEUSHM7D&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=9450c9fd00103b8c65801863c441608e&ref_=as_li_ss_tl',
  false, false, 'queen', 'kueche', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 9. Shark TurboBlade Turmventilator — babo · lifestyle · gadgets — 199,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Shark TurboBlade Turmventilator TF200SEU',
  'shark-turboblade-turmventilator-tf200seu',
  E'Turmlüfter ohne Flügel — 10 Geschwindigkeitsstufen, 180°-Oszillation, Fernbedienung, Timer, Luftzirkulation bis 20 Meter. Leise genug fürs Schlafzimmer, stark genug für den Sommer ohne Klimaanlage.\n\nKein rotierendes Plastik, kein Staub in den Flügeln, keine Reinigung mit dem Bleistift. Shark hat hier ein Gerät gebaut, das wie ein Turmventilator aussieht und sich wie eines anfühlt — nur ohne die bekannten Schwächen.',
  'Flügelloser Turmventilator mit 20m Reichweite — leise, 10 Stufen, Fernbedienung',
  19999,
  'https://m.media-amazon.com/images/I/61W8AfZJFOL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0F3XKQC3W?coliid=I2BYEGNPXIGKAJ&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=ab0b8740b9fb205ce6db294a4bc6fb3a&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 10. vivo X300 Ultra Smartphone — babo · tech · gadgets — 2.667,00€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'vivo X300 Ultra Smartphone',
  'vivo-x300-ultra-smartphone',
  E'ZEISS Triple-Prime-Objektive, 4K-Video mit 120 Frames pro Sekunde, 16 GB RAM, 1 TB Speicher, 2K ZEISS Master Color Display und 6.600 mAh Akku. Dazu ein Foto-Kit im Lieferumfang.\n\nFür alle, die ein Telefon wollen, das in jedem Bereich die Frage beantwortet: Was ist das Maximum? Nicht das Mittelfeld, nicht der Kompromiss — sondern das Gerät, das man kauft, wenn man aufgehört hat zu suchen.',
  'ZEISS Triple-Objektiv, 4K/120fps, 1TB Speicher — das vollständigste Kamera-Smartphone',
  266700,
  'https://m.media-amazon.com/images/I/716NskZMIiL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0GX5G77WW?coliid=IM5F2NDOHBVJ3&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=0563e304ee6748875ffbb3471198bdb3&ref_=as_li_ss_tl',
  false, true, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

-- 11. Couchbar Snackbox Bambus — babo · lifestyle · gadgets — 29,90€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Couchbar Snackbox aus Bambus',
  'couchbar-snackbox-bambus',
  E'Couch-Tablett aus Bambus mit zwei Snackschalen, zwei Getränkehaltern mit Untersetzer, magnetischem Deckel und Handyhalterung. Alles an einem Ort, alles griffbereit — kein Balancieren mehr auf der Sofalehne.\n\nFür den Sofaabend, der wirklich entspannt sein soll. Personalisierbar und mit Geschenkbox — das Geschenk für alle, die ihr Zuhause ernst nehmen und trotzdem wissen, wie man richtig Pause macht.',
  'Bambus-Couchbar mit Snackschalen, Getränkehaltern und Handyhalterung — alles in Griffweite',
  2990,
  'https://m.media-amazon.com/images/I/81XBarVFxsL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0DDLH865P?coliid=IP76OXI69LSU5&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=7716a410a297c3568b14cbbdae4dd95f&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;
