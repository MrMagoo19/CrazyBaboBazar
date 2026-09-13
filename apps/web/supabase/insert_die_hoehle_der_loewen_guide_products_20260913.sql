-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit user approval before production execution.
-- Adds the 12 products for /guide/die-hoehle-der-loewen-produkte.
--
-- DATA-VERIFICATION CAVEATS (read before execution):
-- 1) Prices are snapshots from the German Amazon listings on 2026-09-13 and
--    can change after publication.
-- 2) "Deal geplatzt" (Koawach) and "nie einen Deal bekommen" (einhorn) are
--    taken as given facts from the task brief, not independently re-verified
--    against press sources in this session.
-- 3) No collision check against the live products table could be run in this
--    session (DB read access unavailable). The preflight block below still
--    guards against ASIN reuse under a different slug at execution time.

BEGIN;

DO $$
DECLARE
  expected_asins CONSTANT text[] := ARRAY[
    'B00NEG6SX0', 'B0FGJR3CBJ', 'B075W3YLVY', 'B0BS3Z4VNG',
    'B0C4LNX9FF', 'B07PVC7MFF', 'B08YK2VGM7', 'B0DCTN7D2Q',
    'B086XFC7DC', 'B01C2X6A1K', 'B0DMSYZW4T', 'B07GWT7NFJ'
  ];
  expected_slugs CONSTANT text[] := ARRAY[
    'ankerkraut-magic-dust-bbq-rub-230g',
    'waschies-abschminkpads-6er-set',
    'rokittas-rostschreck-geschirrspueler',
    'waterdrop-starter-set',
    'yfood-trinkmahlzeit-probierpaket',
    'happybrush-schallzahnbuerste-eco-vibe-3',
    '3bears-porridge-feiner-kakao-6-x-400g',
    'einhorn-kondome-classico-49er',
    'duschbrocken-duschseife-2in1-3er-set',
    'koawach-kakaopulver-pur-schoko-500g',
    'little-lunch-bio-suppen-kennenlernbox',
    'bitterliebe-original-bittertropfen-50ml'
  ];
  i integer;
  conflicting_slug text;
BEGIN
  FOR i IN 1..array_length(expected_asins, 1) LOOP
    SELECT slug INTO conflicting_slug
    FROM public.products
    WHERE affiliate_url ~ ('/(' || expected_asins[i] || ')([/?]|$)')
      AND slug <> expected_slugs[i]
    LIMIT 1;

    IF conflicting_slug IS NOT NULL THEN
      RAISE EXCEPTION 'ASIN % already exists under slug % (expected %)',
        expected_asins[i], conflicting_slug, expected_slugs[i];
    END IF;
  END LOOP;
END
$$;

INSERT INTO public.products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, fuer_wen, nicht_fuer, key_fact, pros, cons
)
VALUES
(
  'ankerkraut-magic-dust-bbq-rub-230g', 'Ankerkraut Magic Dust BBQ Rub 230 g',
  'Eine Gewürzmischung, zehn Dosen weniger im Schrank.',
  'Ankerkraut Magic Dust ist eine BBQ-Gewürzmischung (230 g) aus dem Sortiment einer Marke, die aus der Sendung hervorgegangen ist.',
  849, 'EUR', 'https://www.amazon.de/dp/B00NEG6SX0?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41e9AZCzWLL.jpg', ARRAY['https://m.media-amazon.com/images/I/41e9AZCzWLL.jpg'],
  true, false, 'babo', 'kueche', 'grillen', 'Lebensmittel & Getränke', 'Ankerkraut',
  ARRAY['babo:kueche', 'hoehle-der-loewen', 'grillgewuerz', 'bbq'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die am Grill schnell würzen wollen, ohne mehrere Gläser zu kombinieren.',
  'Nichts für Puristen, die Rubs grundsätzlich selbst anmischen.',
  'Ankerkraut Magic Dust BBQ Rub, 230 g.',
  ARRAY['Fertige Gewürzmischung spart Zeit am Grill', 'Handliche 230-g-Dose', 'Für Grill und Pfanne einsetzbar'],
  ARRAY['Fixe Geschmacksrichtung ohne individuelle Anpassung', 'Dose ist irgendwann leer, Nachkauf nötig']
),
(
  'waschies-abschminkpads-6er-set', 'Waschies waschbare Abschminkpads 6er-Set',
  'Wattepads, die man wäscht statt wegwirft.',
  'Waschies sind waschbare Abschminkpads im 6er-Set, gedacht als Ersatz für Einweg-Wattepads.',
  2499, 'EUR', 'https://www.amazon.de/dp/B0FGJR3CBJ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41zK4IXzp4L.jpg', ARRAY['https://m.media-amazon.com/images/I/41zK4IXzp4L.jpg'],
  true, false, 'queen', 'beauty', 'abschminken', 'Drogerie & Körperpflege', 'Waschies',
  ARRAY['queen:beauty', 'hoehle-der-loewen', 'nachhaltigkeit', 'abschminkpads'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt". ASIN und Produktzuordnung wurden am 13.09.2026 geprüft.',
  'Für alle, die beim Abschminken nicht ständig Nachschub kaufen wollen.',
  'Nichts für alle, die Wattepads grundsätzlich lieber wegwerfen als waschen.',
  'Waschies waschbare Abschminkpads, 6er-Set.',
  ARRAY['Wiederverwendbar statt Einwegware', 'Set mit 6 Pads für mehrere Anwendungen', 'Reduziert Wattepad-Müll im Bad'],
  ARRAY['Waschen vor Wiederverwendung nötig', 'Set-Größe begrenzt bei täglicher Nutzung']
),
(
  'rokittas-rostschreck-geschirrspueler', 'Rokitta''s Rostschreck für den Geschirrspüler',
  'Damit Flugrost am Besteck keinen Stammplatz bekommt.',
  'Rokitta''s Rostschreck ist ein Rostschutz-Magnet für den Geschirrspüler. Er soll Flugrost binden, entfernt aber keinen bereits vorhandenen Rost.',
  2499, 'EUR', 'https://www.amazon.de/dp/B075W3YLVY?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71wB2ghOWrL.jpg', ARRAY['https://m.media-amazon.com/images/I/71wB2ghOWrL.jpg'],
  true, false, 'queen', 'kueche', 'geschirrspueler', 'Küche & Haushalt', 'Rokitta''s Rostschreck',
  ARRAY['queen:kueche', 'hoehle-der-loewen', 'flugrost', 'geschirrspueler', 'besteck'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für Haushalte, die regelmäßig Flugrost am Besteck entdecken.',
  'Nichts für alle, die bereits vorhandenen Rost von Metallteilen entfernen möchten.',
  'Rostschutz-Magnet für den Geschirrspüler; kein Rostentferner.',
  ARRAY['Ohne Reiniger direkt im Geschirrspüler verwendbar', 'Für Besteck und Spülmaschinen-Innenraum gedacht'],
  ARRAY['Entfernt keinen bereits vorhandenen Rost', 'Wirkung hängt von Ursache und Stärke des Flugrosts ab']
),
(
  'waterdrop-starter-set', 'waterdrop Starter Set',
  'Wasser mit Geschmack, ganz ohne Kasten.',
  'Das waterdrop Starter Set kombiniert eine Trinkflasche mit Microdrinks zum Aromatisieren von Wasser. Es erzeugt keine Kohlensäure und ist kein Wasserfilter.',
  3950, 'EUR', 'https://www.amazon.de/dp/B0BS3Z4VNG?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41uclnhqBnL.jpg', ARRAY['https://m.media-amazon.com/images/I/41uclnhqBnL.jpg'],
  true, false, 'queen', 'kueche', 'trinkwasser', 'Getränke', 'waterdrop',
  ARRAY['queen:kueche', 'hoehle-der-loewen', 'trinkwasser', 'starter-set'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die Wasser trinken wollen, aber pur zu fad finden.',
  'Nichts für Leitungswasser-Puristen ohne Zusatzwunsch.',
  'waterdrop Starter Set.',
  ARRAY['Einstiegsset zum unkomplizierten Ausprobieren', 'Flasche und Geschmacksvarianten in einem Set'],
  ARRAY['Zusatzkosten für Nachfüllprodukte möglich', 'Geschmack ist Gewöhnungssache']
),
(
  'yfood-trinkmahlzeit-probierpaket', 'YFood Trinkmahlzeit-Pulver Probierpaket',
  'Eine Mahlzeit, wenn keine Zeit für eine ist.',
  'YFood Trinkmahlzeit-Pulver Probierpaket ist ein Sortiment zum Kennenlernen aus dem Angebot einer Marke, die aus der Sendung hervorgegangen ist.',
  3199, 'EUR', 'https://www.amazon.de/dp/B0C4LNX9FF?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41-nUx1t3AL.jpg', ARRAY['https://m.media-amazon.com/images/I/41-nUx1t3AL.jpg'],
  true, false, 'babo', 'lifestyle', 'trinkmahlzeit', 'Lebensmittel & Getränke', 'YFood',
  ARRAY['babo:lifestyle', 'hoehle-der-loewen', 'trinkmahlzeit', 'probierpaket'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für Tage, an denen ein richtiges Mittagessen sonst ausfallen würde.',
  'Nichts für alle, denen eine warme Mahlzeit wichtiger ist als Tempo.',
  'YFood Trinkmahlzeit-Pulver, Probierpaket.',
  ARRAY['Probierpaket zum Kennenlernen verschiedener Sorten', 'Schnell zubereitet ohne Kochen', 'Praktisch für unterwegs'],
  ARRAY['Ersetzt kein gekochtes Essen dauerhaft', 'Geschmack der Sorten ist Geschmackssache']
),
(
  'happybrush-schallzahnbuerste-eco-vibe-3', 'Happybrush Schallzahnbürste Eco Vibe 3',
  'Der Umstieg von Hand- auf Schallzahnbürste.',
  'Happybrush Eco Vibe 3 ist eine Schallzahnbürste aus dem Sortiment einer Marke, die aus der Sendung hervorgegangen ist.',
  6995, 'EUR', 'https://www.amazon.de/dp/B07PVC7MFF?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/51ko5hZ6yrL.jpg', ARRAY['https://m.media-amazon.com/images/I/51ko5hZ6yrL.jpg'],
  true, false, 'queen', 'beauty', 'zahnpflege', 'Drogerie & Körperpflege', 'Happybrush',
  ARRAY['queen:beauty', 'hoehle-der-loewen', 'zahnpflege', 'schallzahnbuerste'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die von der Handzahnbürste auf elektrisch umsteigen wollen.',
  'Nichts für alle, die ihrer klassischen Handzahnbürste treu bleiben.',
  'Happybrush Schallzahnbürste Eco Vibe 3.',
  ARRAY['Elektrische Alternative zur Handzahnbürste', 'Für den täglichen Umstieg gedacht'],
  ARRAY['Umstieg auf elektrisch braucht etwas Gewöhnung', 'Ersetzt nicht die eigene Putztechnik']
),
(
  '3bears-porridge-feiner-kakao-6-x-400g', '3Bears Porridge Feiner Kakao 6 x 400 g',
  'Porridge ohne Kochtopf am Morgen.',
  '3Bears Porridge Feiner Kakao ist eine vorbereitete Haferflockenmischung im 6er-Set (6 × 400 g). Die Mischung spart das Abwiegen, muss aber noch zubereitet werden.',
  2524, 'EUR', 'https://www.amazon.de/dp/B08YK2VGM7?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41y9q4kNbhL.jpg', ARRAY['https://m.media-amazon.com/images/I/41y9q4kNbhL.jpg'],
  true, false, 'queen', 'kueche', 'fruehstueck', 'Lebensmittel & Getränke', '3Bears',
  ARRAY['queen:kueche', 'hoehle-der-loewen', 'porridge', 'fruehstueck'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die morgens keine Zutaten abwiegen und mischen möchten.',
  'Nichts für alle, die ihre Porridge-Mischung lieber selbst zusammenstellen.',
  '3Bears Porridge Feiner Kakao, 6 × 400 g.',
  ARRAY['6er-Set für mehrere Frühstücke', 'Fertig gemischte Zutaten sparen Vorbereitung'],
  ARRAY['Fixe Geschmacksrichtung im Set', 'Verpackungsgröße nicht für Einzeltest gedacht']
),
(
  'einhorn-kondome-classico-49er', 'einhorn Kondome Classico 49er-Jahresvorrat',
  'Nie einen Deal bekommen, trotzdem groß geworden.',
  'einhorn Kondome Classico ist ein 49er-Jahresvorrat aus dem Sortiment einer Marke, die in der Sendung nie einen Deal bekam und dennoch zu einer der bekanntesten TV-Marken wurde.',
  4200, 'EUR', 'https://www.amazon.de/dp/B0DCTN7D2Q?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/51V0alUPpmL.jpg', ARRAY['https://m.media-amazon.com/images/I/51V0alUPpmL.jpg'],
  true, false, 'babo', 'lifestyle', 'intimprodukte', 'Drogerie & Körperpflege', 'einhorn',
  ARRAY['babo:lifestyle', 'hoehle-der-loewen', 'kondome', 'jahresvorrat'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt". ASIN und Produktzuordnung wurden am 13.09.2026 geprüft.',
  'Für alle, die einmal im Jahr einkaufen und dann Ruhe haben wollen.',
  'Nichts für alle, die lieber einzeln statt im Jahresvorrat kaufen.',
  'einhorn Kondome Classico, 49er-Jahresvorrat.',
  ARRAY['Jahresvorrat in einer Packung', 'Kein Deal nötig für den Erfolg der Marke'],
  ARRAY['Großpackung nicht für Gelegenheitsbedarf gedacht', 'Fixe Variante ohne Sortenmix']
),
(
  'duschbrocken-duschseife-2in1-3er-set', 'Duschbrocken feste Duschseife 2-in-1 3er-Set',
  'Duschgel ohne Flasche, im 3er-Set.',
  'Duschbrocken feste Duschseife 2-in-1 ist ein 3er-Set aus dem Sortiment einer Marke, die aus der Sendung hervorgegangen ist.',
  2998, 'EUR', 'https://www.amazon.de/dp/B086XFC7DC?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41nm15xrLLL.jpg', ARRAY['https://m.media-amazon.com/images/I/41nm15xrLLL.jpg'],
  true, false, 'queen', 'beauty', 'duschseife', 'Drogerie & Körperpflege', 'Duschbrocken',
  ARRAY['queen:beauty', 'hoehle-der-loewen', 'duschseife', 'plastikfrei'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die Kosmetik ohne Flakon im Bad wollen.',
  'Nichts für alle, die feste Seife für ein Auslaufmodell halten.',
  'Duschbrocken feste Duschseife 2-in-1, 3er-Set.',
  ARRAY['3er-Set ohne Nachbestellung nach der ersten Anwendung', 'Ohne Plastikflasche im Bad'],
  ARRAY['Seifenschale oder Ablage separat nötig', 'Andere Handhabung als Flüssigduschgel']
),
(
  'koawach-kakaopulver-pur-schoko-500g', 'Koawach Kakaopulver Pur Schoko 500 g',
  'Der Deal platzte, der Kakao blieb.',
  'Koawach Kakaopulver Pur Schoko (500 g) stammt von einer Marke, die in der Sendung zunächst einen Deal erhielt, der im Nachgang jedoch nicht zustande kam.',
  1899, 'EUR', 'https://www.amazon.de/dp/B01C2X6A1K?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41agQopYe0L.jpg', ARRAY['https://m.media-amazon.com/images/I/41agQopYe0L.jpg'],
  true, false, 'babo', 'kueche', 'kakao', 'Lebensmittel & Getränke', 'Koawach',
  ARRAY['babo:kueche', 'hoehle-der-loewen', 'kakao', 'wach'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für alle, die morgens lieber Kakao als Filterkaffee trinken.',
  'Nichts für alle, die bei Kakao lieber zur bunten Instant-Dose greifen.',
  'Koawach Kakaopulver Pur Schoko, 500 g.',
  ARRAY['500-g-Packung für längere Nutzung', 'Pur-Variante ohne weitere Sorten im Set'],
  ARRAY['Fixe Geschmacksrichtung ohne Sortenmix', '500-g-Packung ist irgendwann aufgebraucht']
),
(
  'little-lunch-bio-suppen-kennenlernbox', 'Little Lunch Bio-Suppen- und Eintöpfe-Kennenlernbox',
  'Eine Box zum Kennenlernen, keine Bevorratung.',
  'Die Little Lunch Bio-Suppen- und Eintopf-Kennenlernbox enthält verschiedene fertige Mahlzeiten für Erwachsene zum Aufwärmen und Probieren.',
  2274, 'EUR', 'https://www.amazon.de/dp/B0DMSYZW4T?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71vLMJGCXLL.jpg', ARRAY['https://m.media-amazon.com/images/I/71vLMJGCXLL.jpg'],
  true, false, 'queen', 'kueche', 'fertiggerichte', 'Lebensmittel & Getränke', 'Little Lunch',
  ARRAY['queen:kueche', 'hoehle-der-loewen', 'suppe', 'eintopf', 'bio'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt".',
  'Für Erwachsene, die mehrere Suppen- und Eintopfsorten ausprobieren möchten.',
  'Nichts für alle, die Suppen grundsätzlich frisch selbst kochen.',
  'Little Lunch Bio-Suppen- und Eintöpfe-Kennenlernbox.',
  ARRAY['Kennenlernbox statt Einzelkauf pro Sorte', 'Bio-Kennzeichnung laut Hersteller'],
  ARRAY['Kennenlernbox nicht für dauerhafte Vorratshaltung gedacht', 'Sortenauswahl durch die Box vorgegeben']
),
(
  'bitterliebe-original-bittertropfen-50ml', 'BitterLiebe Original Bittertropfen 50 ml',
  'Bitter, weil manche das mögen.',
  'BitterLiebe Original Bittertropfen (50 ml) sind ein Geschmacksprodukt mit bitterem Aroma. Eine gesundheitliche Wirkung wird nicht behauptet.',
  1495, 'EUR', 'https://www.amazon.de/dp/B07GWT7NFJ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/318U1kJJukL.jpg', ARRAY['https://m.media-amazon.com/images/I/318U1kJJukL.jpg'],
  true, false, 'babo', 'lifestyle', 'bittertropfen', 'Lebensmittel & Getränke', 'BitterLiebe',
  ARRAY['babo:lifestyle', 'hoehle-der-loewen', 'bittertropfen', 'geschmack'],
  'Teil des Guides "Die Höhle der Löwen: Diese 12 Produkte haben den Hype überlebt". Ausschließlich als Geschmacks-/Lifestyleprodukt beschrieben, keine Wirkaussage.',
  'Für alle, die Bitterstoffe geschmacklich in Getränken oder Speisen mögen.',
  'Nichts für alle, die es lieber süß halten.',
  'BitterLiebe Original Bittertropfen, 50 ml; ohne gesundheitliche Wirkaussage.',
  ARRAY['Kompakte 30-ml-Flasche', 'Vielseitig in Getränken und Speisen einsetzbar'],
  ARRAY['Geschmack ist klar Geschmackssache', 'Kleine Flasche ist schnell aufgebraucht']
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  tagline = EXCLUDED.tagline,
  description = EXCLUDED.description,
  price_cents = EXCLUDED.price_cents,
  currency = EXCLUDED.currency,
  affiliate_url = EXCLUDED.affiliate_url,
  image_url = EXCLUDED.image_url,
  image_urls = EXCLUDED.image_urls,
  is_published = EXCLUDED.is_published,
  is_featured = EXCLUDED.is_featured,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  amazon_category = EXCLUDED.amazon_category,
  brand = EXCLUDED.brand,
  shop_tags = EXCLUDED.shop_tags,
  editorial_note = EXCLUDED.editorial_note,
  fuer_wen = EXCLUDED.fuer_wen,
  nicht_fuer = EXCLUDED.nicht_fuer,
  key_fact = EXCLUDED.key_fact,
  pros = EXCLUDED.pros,
  cons = EXCLUDED.cons;

DO $$
DECLARE
  wanted_slugs CONSTANT text[] := ARRAY[
    'ankerkraut-magic-dust-bbq-rub-230g', 'waschies-abschminkpads-6er-set',
    'rokittas-rostschreck-geschirrspueler', 'waterdrop-starter-set',
    'yfood-trinkmahlzeit-probierpaket', 'happybrush-schallzahnbuerste-eco-vibe-3',
    '3bears-porridge-feiner-kakao-6-x-400g', 'einhorn-kondome-classico-49er',
    'duschbrocken-duschseife-2in1-3er-set', 'koawach-kakaopulver-pur-schoko-500g',
    'little-lunch-bio-suppen-kennenlernbox', 'bitterliebe-original-bittertropfen-50ml'
  ];
  inserted_count integer;
BEGIN
  SELECT count(*) INTO inserted_count
  FROM public.products
  WHERE slug = ANY(wanted_slugs);

  IF inserted_count <> array_length(wanted_slugs, 1) THEN
    RAISE EXCEPTION 'Postflight failed: expected 12 products, found %', inserted_count;
  END IF;
END
$$;

COMMIT;

-- All 12 rows are prepared as published because price and image data have been
-- filled in and reviewed. Production execution still requires explicit approval.
SELECT slug, name, price_cents, affiliate_url, is_published
FROM public.products
WHERE slug IN (
  'ankerkraut-magic-dust-bbq-rub-230g', 'waschies-abschminkpads-6er-set',
  'rokittas-rostschreck-geschirrspueler', 'waterdrop-starter-set',
  'yfood-trinkmahlzeit-probierpaket', 'happybrush-schallzahnbuerste-eco-vibe-3',
  '3bears-porridge-feiner-kakao-6-x-400g', 'einhorn-kondome-classico-49er',
  'duschbrocken-duschseife-2in1-3er-set', 'koawach-kakaopulver-pur-schoko-500g',
  'little-lunch-bio-suppen-kennenlernbox', 'bitterliebe-original-bittertropfen-50ml'
)
ORDER BY slug;
