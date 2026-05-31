-- Batch 19 — 4 Produkte — is_published = TRUE (sofort live)
-- ON CONFLICT DO UPDATE → Upsert

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'BRA Dupla Premiere Omelette-Pfanne 24cm',
  'bra-dupla-premiere-omelette-pfanne-24cm',
  E'Doppelpfanne für die perfekte spanische Tortilla: beide Hälften erhitzen, Ei-Masse rein, umklappen — kein Wenden, kein Reißen, kein Chaos. 24 cm Durchmesser, dreifache Antihaftschicht, PFOA-frei, für alle Herdarten inklusive Induktion.\n\nFür alle, die Omelettes und Tortillas lieben, aber die Wendeaktion beim Braten hassen. Oder die einfach aufgehört haben, Kompromisse bei Küchengeräten zu machen.',
  'Doppelte Klapp-Bratpfanne für Tortilla und Omelette — kein Wenden, kein Reißen',
  5619,
  'https://m.media-amazon.com/images/I/61-mKAJmQgL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B07NGG8GTN?coliid=IWH4XS07WZFDC&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=053e4e6dd036d9b987e6669890749d73&ref_=as_li_ss_tl',
  true, false, 'queen', 'kueche', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents, image_url = EXCLUDED.image_url, affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published, shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category, shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Tefal Ixeo Power All-in-One Dampfglätter',
  'tefal-ixeo-power-allinone-dampfglaetter',
  E'Dampfglätter und Smart Board in einem Gerät — kein separates Bügelbrett aufstellen, kein Umräumen. Tefal Ixeo Power bügelt hängend oder liegend, mit Dampfstoß für hartnäckige Falten.\n\nFür alle, die Bügeln als notwendiges Übel betrachten und das wenigstens so effizient wie möglich erledigen wollen. Weniger Aufwand, weniger Platzbedarf, gleich gutes Ergebnis.',
  'Dampfbügeleisen und Board in einem — kein separates Aufstellen, sofort einsatzbereit',
  28530,
  'https://m.media-amazon.com/images/I/71F+vcEruSL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0C6MNFT27?coliid=I5ZQB8R7LBJU6&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=45fcd5ce38a230043ebc65dd80092a68&ref_=as_li_ss_tl',
  true, false, 'queen', 'lifestyle', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents, image_url = EXCLUDED.image_url, affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published, shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category, shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Aarke Wasserkocher Edelstahl 1,2L',
  'aarke-wasserkocher-edelstahl-1-2l',
  E'Wasserkocher aus Edelstahl mit mehreren Temperatureinstellungen, 360°-Sockel, leisem Kochvorgang und tropffreiem Ausgießer. 1,2 Liter. Von Aarke — dem schwedischen Designlabel, das auch den ikonischen Carbonator baut.\n\nFür alle, die aufgehört haben, sich mit billigen Wasserkochern abzufinden, die tropfen, laut sind und nach drei Jahren auseinanderfallen. Ein Gerät, das auf der Küchenzeile stehen und dort auch gut aussehen soll.',
  'Schwedischer Design-Wasserkocher mit Temperaturwahl — leise, tropffrei, 1,2L Edelstahl',
  25000,
  'https://m.media-amazon.com/images/I/61xiKg6PPoL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CG9K6NX3?coliid=I1F68ORYIBQ3A7&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=df68da5ffe88b5ce707c87703b4491e5&ref_=as_li_ss_tl',
  true, true, 'queen', 'kueche', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents, image_url = EXCLUDED.image_url, affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published, shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category, shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Bartesian Cocktailmaschine mit Kapseln',
  'bartesian-cocktailmaschine-mit-kapseln',
  E'Cocktailmaschine nach dem Kapsel-Prinzip — Kapsel rein, Spirituose rein, Stärke wählen, fertig. Vier Stärkeoptionen, vier verschiedene Spirituosen gleichzeitig befüllbar. Kein Mixen, kein Abmessen, keine Unordnung.\n\nDie Nespresso-Logik auf die Hausbar angewendet. Für alle, die Cocktails mögen, aber keine Barkeeper-Ausbildung haben wollen. Oder für alle, die Gäste beeindrucken wollen, ohne drei Stunden vorher in der Küche zu stehen.',
  'Cocktailmaschine per Kapsel — 4 Spirituosen, 4 Stärken, Barqualität ohne Barkeeper',
  34999,
  'https://m.media-amazon.com/images/I/71lCpSoOyJL._SL1500_.jpg',
  'https://www.amazon.de/dp/B07PJ5Q943?coliid=I31U0SLGR8Z9XF&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=bc6441eed5ed48fcf77076c87327dfc1&ref_=as_li_ss_tl',
  true, true, 'babo', 'lifestyle', 'gadgets'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents, image_url = EXCLUDED.image_url, affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published, shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category, shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;
