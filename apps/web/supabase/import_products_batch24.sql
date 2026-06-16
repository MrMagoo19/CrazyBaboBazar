-- =============================================================================
-- import_products_batch24.sql
-- 5 virale Irrenhaus-Produkte — Batch 1: Babo's Irrenhaus
-- Erstellt: 2026-06-16
-- HINWEIS: Preise mit *** markiert — bitte auf Amazon.de prüfen bevor Ausführung
-- HINWEIS: image_url leer lassen — Bilder manuell via Amazon-Produktseite ergänzen
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BABO'S IRRENHAUS — Virale Gadgets & WTF-Produkte
-- -----------------------------------------------------------------------------

-- Preis: 25,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'coddies-fisch-schlappen-flip-flops',
  'Coddies Fisch-Schlappen',
  'Hausschuhe in Fischform — das Original seit Millionen viraler Klicks',
  E'Manche Produkte erklären sich selbst. Diese hier nicht — und genau deshalb funktionieren sie.\n\nCoddies ist die Original-Marke hinter den Fisch-Flip-Flops die seit Jahren auf TikTok, Reddit und Pinterest viral gehen. Realistischer 3D-Barsch-Look, leichtes EVA-Material, flexibel und tatsächlich tragbar als Badeschlappen, Strandschuh oder Duschsandale.\n\nUnisex, verfügbar in 5 Farben und allen Größen. 4,4 Sterne bei über 12.000 Bewertungen. Eines der meistgekauften WTF-Artikel auf Amazon weltweit. Gekauft wegen des Witzes — getragen wegen des Komforts.',
  2599,
  'EUR',
  'https://www.amazon.de/dp/B07CSZNLWZ?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'irrenhaus',
  'viral-gadgets',
  ARRAY['irrenhaus', 'viral', 'fisch', 'schlappen', 'hausschuhe', 'wtf', 'geschenke-maenner', 'tiktok-viral', 'geschenk', 'lustig']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;

-- Preis: 10,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'flaschenoffner-pistole-kronkorken-2er-pack',
  'Kronkorken-Pistole Flaschenöffner (2er-Pack)',
  'Flasche aufmachen. Kronkorken wegschießen. Repeat.',
  E'Normale Flaschenöffner öffnen Flaschen. Dieser macht daraus ein Spektakel.\n\nDie Cap Gun funktioniert wie eine Pistole: Flasche ansetzen, drücken — der Kronkorken fliegt bis zu 5 Meter weit. Federmechanismus aus Metall und ABS-Kunststoff, kein Treibgas, kein Akku nötig. Magnet greift den Kronkorken, Feder katapultiert ihn weg.\n\nIm 2er-Set: Grau + Rot. Das Geschenk das sofort eine Demo verlangt — und spätestens beim dritten Mal gegen die Küchenlampe geschossen hat. Für Partys, Grillabende und Männer die nie aufgehört haben Sachen wegzuschießen.',
  1099,
  'EUR',
  'https://www.amazon.de/dp/B0DPJSVVFL?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'irrenhaus',
  'viral-gadgets',
  ARRAY['irrenhaus', 'viral', 'flaschenoffner', 'pistole', 'kronkorken', 'geschenke-maenner', 'party', 'wtf', 'gadget', 'unter-20-euro', 'lustig']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;

-- Preis: 24,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'schreibtisch-boxsack-saugnapf-buero',
  'Schreibtisch-Boxsack mit Saugnapf',
  'Meeting zu lang. Chef nervt. Einfach draufhauen.',
  E'Es gibt Momente im Büroalltag die nach einer körperlichen Antwort verlangen. Dieser Boxsack ist dafür gebaut.\n\nSaugnapf-Montage in Sekunden auf jedem glatten Untergrund — Schreibtisch, Glas, Fliesen. Hochwertige PU-Leder-Schlagfläche, verbesserte Hochleistungsfeder mit mehr Rückprall als billige Alternativen. Kein Aufpumpen nötig, sofort einsatzbereit.\n\nDas Gadget das gleichzeitig Stresskiller und Gesprächsstarter ist. Keiner der vorbeiläuft ignoriert einen Boxsack auf dem Schreibtisch. Für Büro, Homeoffice und alle die ihre Frustration lieber in einen Ball stecken als in eine E-Mail.',
  2499,
  'EUR',
  'https://www.amazon.de/dp/B07CXMHX7G?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'irrenhaus',
  'buero-gadgets',
  ARRAY['irrenhaus', 'viral', 'boxsack', 'büro', 'stress', 'anti-stress', 'gadget', 'geschenke-maenner', 'homeoffice', 'lustig']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;

-- Preis: 34,99 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'coddies-blobfish-hausschuhe-plusch',
  'Coddies Blobfish Plüsch-Hausschuhe',
  'Das hässlichste Tier der Welt — jetzt an deinen Füßen',
  E'Der Blobfish ist offiziell das hässlichste Tier der Welt. Gewählt per Abstimmung. Zertifiziert. Und jetzt gibt es ihn als Plüsch-Hausschuhe.\n\nCoddies Blobfish Slippers: Memory-Foam-Sohle die sich an deinen Fuß anpasst, Plüschoberfläche in perfektem Blobfish-Rosa, rutschfeste Antirutsch-Sohle. Unisex in drei Größen (S/M/L). Das Tier das aussieht wie ein trauriger Mensch — außerhalb von Tiefseedruck sieht er wirklich nicht gut aus.\n\nIdeal für alle die ihre Schuhe als Gesprächsstarter nutzen wollen. Oder einfach für alle die den Blobfish lieben. Die gibt es.',
  3499,
  'EUR',
  'https://www.amazon.de/dp/B0B9CFVYJH?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'irrenhaus',
  'viral-gadgets',
  ARRAY['irrenhaus', 'viral', 'blobfish', 'hausschuhe', 'plusch', 'wtf', 'geschenk', 'tiktok-viral', 'lustig', 'kawaii']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;

-- Preis: 7,49 € (bestätigt via Screenshot)
INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'ikaar-multitool-kreditkarte-11in1-edelstahl',
  'IKAAR Multitool Kreditkarte 11-in-1',
  '11 Werkzeuge. Kreditkartenformat. Immer dabei.',
  E'Der Typ der immer ein Werkzeug dabei hat gewinnt. Diese Karte macht dich zu diesem Typ.\n\n11 Funktionen in Kreditkartengröße (6,9 x 4,5 x 0,2 cm) aus 420er Edelstahl: Dosenöffner, Flaschenöffner, Sägezahn, Lineal, zwei Sechskantschlüssel, Schraubendreher, Seilschneider, Schlüsselloch und mehr. Kommt mit Schutzhülle aus Kunststoff — passt in jede Geldbörse.\n\nDas Gadget das sofort jemanden beeindruckt der dich damit nie gerechnet hätte. Bestes Preis-Leistungs-Verhältnis für einen echten Gesprächsstarter. Männergeschenk unter 10€ das kein Plastikschrott ist.',
  749,
  'EUR',
  'https://www.amazon.de/dp/B07TG1YTG4?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'irrenhaus',
  'edc',
  ARRAY['irrenhaus', 'viral', 'multitool', 'kreditkarte', 'werkzeug', 'gadget', 'geschenke-maenner', 'edc', 'unter-10-euro', 'camping', 'outdoor']
)
ON CONFLICT (slug) DO UPDATE SET
  name              = EXCLUDED.name,
  tagline           = EXCLUDED.tagline,
  description       = EXCLUDED.description,
  price_cents       = EXCLUDED.price_cents,
  affiliate_url     = EXCLUDED.affiliate_url,
  shop_persona      = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  shop_tags         = EXCLUDED.shop_tags,
  is_published      = EXCLUDED.is_published;
