-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- Inserts/aktualisiert 4 neue Produkte fuer den ueberarbeiteten Guide
-- "wichtelgeschenke-unter-20-euro" (16-Produkte-Refresh, 2026-09-14).
-- Reine Produkt-Einfuegung/-Aktualisierung, keine Listenaenderung.
-- Ausgefuehrt am 2026-09-14 nach ausdruecklicher Benutzerfreigabe;
-- Postflight und oeffentliche Produktseiten anschliessend erfolgreich geprueft.

BEGIN;

-- Preflight: keine der 4 ASINs darf bereits unter einem ANDEREN Slug existieren.
-- (Ein Treffer unter dem jeweils erwarteten Ziel-Slug ist erlaubt, damit dieses
-- Skript idempotent per ON CONFLICT (slug) DO UPDATE wiederholt werden kann.)
DO $$
DECLARE
  expected_asins CONSTANT text[] := ARRAY[
    'B088646PWY', 'B097YRJ27K', 'B01N9FCJHA', 'B07V9BGBGY'
  ];
  expected_slugs CONSTANT text[] := ARRAY[
    'debug-duck-problemloeser-ente',
    'snagger-snackspender-schwarz-rot',
    'getdigital-retro-kochloeffel-arcade',
    'raetselbox-holz-geheime-faecher'
  ];
  i integer;
  conflicting_slug text;
BEGIN
  FOR i IN 1..array_length(expected_asins, 1) LOOP
    SELECT slug INTO conflicting_slug
    FROM public.products
    WHERE affiliate_url LIKE '%/dp/' || expected_asins[i] || '?%'
      AND slug <> expected_slugs[i]
    LIMIT 1;

    IF conflicting_slug IS NOT NULL THEN
      RAISE EXCEPTION
        'Preflight failed: ASIN % already present under unexpected slug % (expected %)',
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
  'debug-duck-problemloeser-ente',
  'DEBUG DUCK – die Problemlöser-Ente',
  'Der Kollege, der nie widerspricht, aber trotzdem hilft.',
  E'Die DEBUG DUCK greift ein echtes Ritual aus der Programmierwelt auf: Rubber-Duck-Debugging, bei dem man ein Problem laut einer Gummiente erklärt und dabei oft selbst auf die Lösung kommt.\n\nAls Wichtelgeschenk ist sie ein Insider-Gag für Entwickler und IT-Kollegen, ganz ohne Batterie oder App.',
  1499, 'EUR',
  'https://www.amazon.de/dp/B088646PWY?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71p-wLbIFQL._AC_SX679_.jpg', ARRAY['https://m.media-amazon.com/images/I/71p-wLbIFQL._AC_SX679_.jpg'],
  true, false, 'babo', 'tech', 'buero-gadget', 'Bürobedarf & Schreibwaren', 'neonquelle',
  ARRAY['babo:tech', 'wichteln', 'buero-gadget', 'debug-duck', 'nerdy'],
  'Ergänzt die Wichtelliste um einen Insider-Gag für Entwickler statt generischer Bürodeko.',
  'Entwickler, IT-Kollegen und alle, die Probleme gern laut vor sich hin erklären.',
  'Wer auf gesicherte Material- oder Herstellerangaben Wert legt — die Datenlage auf Amazon ist hier noch dünn.',
  'Gummienten-Figur nach dem Rubber-Duck-Debugging-Prinzip, Marke neonquelle.',
  ARRAY['klarer Insider-Bezug zur Programmierwelt', 'kompaktes Schreibtisch-Format', 'günstiger Wichtel-Preis'],
  ARRAY['noch wenige Kundenbewertungen auf Amazon', 'Material- und Fertigungsangaben nicht unabhängig bestätigt']
),
(
  'snagger-snackspender-schwarz-rot',
  'snagger Snackspender, schwarz-rot',
  'Snacks griffbereit, Tüte bleibt zu.',
  E'Der snagger Snackspender in Schwarz-Rot ist ein kompakter Behälter für kleine Snacks wie Nüsse, Chips oder Gummibärchen, der die übliche aufgerissene Tüte ersetzt.\n\nAls Wichtelgeschenk ist er ein unauffälliger Praxis-Helfer zwischen den lauteren Gag-Geschenken einer Wichtelrunde.',
  1990, 'EUR',
  'https://www.amazon.de/dp/B097YRJ27K?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81WiRQZZ9nL._AC_SY300_SX300_QL70_ML2_.jpg', ARRAY['https://m.media-amazon.com/images/I/81WiRQZZ9nL._AC_SY300_SX300_QL70_ML2_.jpg'],
  true, false, 'queen', 'haushalt', 'aufbewahrung', 'Küche & Haushalt', 'snagger',
  ARRAY['queen:haushalt', 'wichteln', 'snackspender', 'aufbewahrung'],
  'Der praktische Gegenpol zu den Gag-Geschenken dieser Liste — kein Lacher, aber Dauereinsatz.',
  'Snack-Fans, die unterwegs oder am Schreibtisch öfter in aufgerissene Tüten greifen.',
  'Wer konkrete Herkunfts- oder Bewertungsangaben erwartet — diese sind für dieses Listing aktuell nicht unabhängig bestätigt.',
  'Kompakter Snackbehälter der Marke snagger in Schwarz-Rot.',
  ARRAY['hält Snacks griffbereit und ordentlich', 'kompaktes Format', 'unter 20 Euro'],
  ARRAY['reines Nützlichkeits-Geschenk ohne Gag-Faktor', 'Herstellerangaben wie Fertigungsort nicht unabhängig geprüft']
),
(
  'getdigital-retro-kochloeffel-arcade',
  'getDigital Retro-Kochlöffel im Arcade-Design, 2er-Set',
  'Joystick-Optik, klassische Rührfunktion.',
  E'Die Retro-Kochlöffel von getDigital im Arcade-Design bringen als 2er-Set aus Buchenholz die Optik alter Spielhallen-Joysticks an den Herd.\n\nFür Gaming-Fans in der Küche ist das ein klarer Fandom-Bezug, funktional bleiben es aber ganz normale Kochlöffel zum Rühren und Wenden.',
  1690, 'EUR',
  'https://www.amazon.de/dp/B01N9FCJHA?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71Rcruu9iEL._AC_SY300_SX300_QL70_ML2_.jpg', ARRAY['https://m.media-amazon.com/images/I/71Rcruu9iEL._AC_SY300_SX300_QL70_ML2_.jpg'],
  true, false, 'babo', 'kueche', 'kochzubehoer', 'Küche & Haushalt', 'getDigital',
  ARRAY['babo:kueche', 'nerdy', 'gaming', 'kochloeffel', 'retro'],
  'Bringt Gaming-Fandom an den Herd, als Gegenstück zu den reinen Deko-Objekten dieser Liste.',
  'Gamer und Retro-Fans, die auch beim Kochen nicht auf ihr Thema verzichten wollen.',
  'Wer explizit spülmaschinenfeste Küchenutensilien sucht — dafür liegt keine gesicherte Herstellerangabe vor.',
  '2er-Set Kochlöffel aus Buchenholz im Arcade-Design, Marke getDigital.',
  ARRAY['klarer Gaming-Bezug', 'Material Buchenholz', '2er-Set'],
  ARRAY['Spülmaschinenfestigkeit nicht angegeben, daher besser von Hand spülen', 'Nischenprodukt für Fandom-Fans']
),
(
  'raetselbox-holz-geheime-faecher',
  'Magische Rätselbox aus Holz mit zwei Geheimfächern',
  'Die Verpackung, die selbst zum Rätsel wird.',
  E'Die magische Rätselbox aus Holz öffnet ihre zwei Geheimfächer erst nach einem kleinen Kniff und funktioniert damit selbst als Geschenkverpackung mit Überraschungseffekt.\n\nEin Geldschein, Gutschein oder eine kleine Süßigkeit im Geheimfach machen aus der Box ein zweites Mini-Geschenk, bevor das eigentliche Wichtelgeschenk überhaupt ausgepackt ist.',
  1599, 'EUR',
  'https://www.amazon.de/dp/B07V9BGBGY?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81XfuUJYDRL._AC_SX679_.jpg', ARRAY['https://m.media-amazon.com/images/I/81XfuUJYDRL._AC_SX679_.jpg'],
  true, false, 'queen', 'deko', 'geschenkverpackung', 'Spielzeug', 'HD-Store',
  ARRAY['queen:deko', 'wichteln', 'raetselbox', 'geschenkverpackung', 'holz'],
  'Funktioniert als Verpackung mit eigenem Überraschungsmoment statt als klassisches Zusatzgeschenk.',
  'Wer die Verpackung selbst zum kleinen Geschenk machen will, statt nur Papier drumzuwickeln.',
  'Wer eine reine Aufbewahrungsbox ohne Rätsel-Mechanik sucht.',
  'Holzbox mit zwei versteckten Geheimfächern, Marke HD-Store.',
  ARRAY['doppelte Funktion als Verpackung und Geschenk', 'zwei Geheimfächer', 'wiederverwendbar'],
  ARRAY['Innenmaße der Fächer sind klein, für großes Zusatzgeschenk ungeeignet', 'Öffnungsmechanik muss man einmal herausfinden']
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

-- Postflight: exakt 4 Zielprodukte veroeffentlicht, jede ASIN unter dem
-- richtigen Slug mit korrekter affiliate_url.
DO $$
DECLARE
  expected_asins CONSTANT text[] := ARRAY[
    'B088646PWY', 'B097YRJ27K', 'B01N9FCJHA', 'B07V9BGBGY'
  ];
  expected_slugs CONSTANT text[] := ARRAY[
    'debug-duck-problemloeser-ente',
    'snagger-snackspender-schwarz-rot',
    'getdigital-retro-kochloeffel-arcade',
    'raetselbox-holz-geheime-faecher'
  ];
  published_count integer;
  i integer;
  match_count integer;
BEGIN
  SELECT count(*) INTO published_count
  FROM public.products
  WHERE slug = ANY(expected_slugs) AND is_published = true;

  IF published_count <> 4 THEN
    RAISE EXCEPTION 'Postflight failed: expected 4 published products, got %', published_count;
  END IF;

  FOR i IN 1..array_length(expected_asins, 1) LOOP
    SELECT count(*) INTO match_count
    FROM public.products
    WHERE slug = expected_slugs[i]
      AND affiliate_url LIKE '%/dp/' || expected_asins[i] || '?%'
      AND is_published = true;

    IF match_count <> 1 THEN
      RAISE EXCEPTION
        'Postflight failed: ASIN % not found under expected slug % with correct affiliate_url',
        expected_asins[i], expected_slugs[i];
    END IF;
  END LOOP;
END
$$;

COMMIT;

SELECT slug, name, price_cents, shop_persona, shop_main_category, affiliate_url, is_published
FROM public.products
WHERE slug = ANY(ARRAY[
  'debug-duck-problemloeser-ente',
  'snagger-snackspender-schwarz-rot',
  'getdigital-retro-kochloeffel-arcade',
  'raetselbox-holz-geheime-faecher'
])
ORDER BY array_position(ARRAY[
  'debug-duck-problemloeser-ente',
  'snagger-snackspender-schwarz-rot',
  'getdigital-retro-kochloeffel-arcade',
  'raetselbox-holz-geheime-faecher'
], slug);
