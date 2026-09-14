-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit user approval before production execution.
-- Adds the 16 products for /guide/k-beauty-vs-deutsche-kosmetik.
-- Sources and evidence tiers: SOURCES_k_beauty_vs_deutsche_kosmetik_20260914.md
--
-- Idempotent by slug. Preflight aborts on collision in EITHER direction:
--   1) an ASIN already exists under a different slug, or
--   2) a slug already exists pointing at a different ASIN
-- so this script never silently overwrites unrelated existing product data.
-- On re-run, ON CONFLICT DO UPDATE never overwrites an existing image_url /
-- image_urls with NULL/empty — it only replaces them when the new value is
-- non-empty.

BEGIN;

DO $$
DECLARE
  expected_asins CONSTANT text[] := ARRAY[
    'B0D2J9JQRJ', 'B01M0TG9FH',
    'B016NRXO06', 'B08WH2MTRD',
    'B07B65NJLV', 'B088RFQ68M',
    'B0CLD1T6MB', 'B07YQG4M32',
    'B07WZ2YTDP', 'B085HFJ1LQ',
    'B0DKXWDCKF', 'B0CX936R3K',
    'B086VKZZZY', 'B0GWMZBMSY',
    'B0BJPKX14D', 'B06XQTTWL9'
  ];
  expected_slugs CONSTANT text[] := ARRAY[
    'dr-jart-ceramidin-handcreme-100ml', 'eucerin-urearepair-5-urea-handcreme-75ml',
    'cosrx-low-ph-good-morning-gel-cleanser-150ml', 'eucerin-dermatoclean-hyaluron-reinigungsgel-200ml',
    'dear-klairs-supple-preparation-unscented-toner-180ml', 'eucerin-dermatoclean-klaerendes-gesichtswasser-200ml',
    'illiyoon-ceramide-ato-concentrate-cream-75ml', 'nivea-creme-150ml',
    'torriden-dive-in-hyaluronic-acid-serum-50ml', 'lavera-hydro-refresh-serum',
    'dr-jart-ceramidin-skin-barrier-eye-cream-15ml', 'sebamed-anti-aging-augencreme-q10-15ml',
    'beauty-of-joseon-glow-serum-propolis-niacinamide-30ml', 'sebamed-clear-face-pflege-gel-aloe-vera-50ml',
    'beauty-of-joseon-red-bean-refreshing-pore-mask-140ml', 'colibri-skincare-bha-mask-150ml'
  ];
  i integer;
  conflicting_slug text;
  conflicting_url text;
BEGIN
  FOR i IN 1..array_length(expected_asins, 1) LOOP
    SELECT slug INTO conflicting_slug
    FROM public.products
    WHERE affiliate_url ~ ('/(' || expected_asins[i] || ')([/?]|$)')
      AND slug <> expected_slugs[i]
    LIMIT 1;

    IF conflicting_slug IS NOT NULL THEN
      RAISE EXCEPTION 'Preflight failed: ASIN % already exists under slug % (expected %)',
        expected_asins[i], conflicting_slug, expected_slugs[i];
    END IF;

    SELECT affiliate_url INTO conflicting_url
    FROM public.products
    WHERE slug = expected_slugs[i]
      AND affiliate_url !~ ('/(' || expected_asins[i] || ')([/?]|$)')
    LIMIT 1;

    IF conflicting_url IS NOT NULL THEN
      RAISE EXCEPTION 'Preflight failed: slug % already exists with a different ASIN (found affiliate_url %, expected ASIN %)',
        expected_slugs[i], conflicting_url, expected_asins[i];
    END IF;
  END LOOP;
END
$$;

INSERT INTO public.products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, key_fact, pros, cons
)
VALUES
(
  'dr-jart-ceramidin-handcreme-100ml', 'Dr.Jart+ Ceramidin Moisturizing Hand Cream 100 ml',
  'Ceramidpflege für raue Hände – parfümiert.',
  E'Die Ceramidin Moisturizing Hand Cream von Dr.Jart+ ist eine reichhaltige Handcreme auf Ceramid-Basis, gedacht für trockene, beanspruchte Hände.\n\nDie Rezeptur enthält Parfum sowie den Farbstoff CI 19140.',
  1367, 'EUR', 'https://www.amazon.de/dp/B0D2J9JQRJ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61xZNZ0j7UL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61xZNZ0j7UL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'handcreme', 'Drogerie & Körperpflege', 'Dr.Jart+',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'handcreme', 'k-beauty'],
  'Im Handcreme-Duell gegen Eucerin unterliegt sie knapp wegen Parfum und Farbstoff.',
  'Handcreme, 100 ml, mit Parfum und Farbstoff CI 19140.',
  ARRAY['Ceramidbasierte Rezeptur', 'Reichhaltige Textur für trockene Hände'],
  ARRAY['Enthält Parfum', 'Enthält den Farbstoff CI 19140']
),
(
  'eucerin-urearepair-5-urea-handcreme-75ml', 'Eucerin UreaRepair 5% Urea Handcreme 75 ml',
  '5% Urea, ohne Parfum, ohne Farbstoff.',
  E'Die UreaRepair Handcreme von Eucerin setzt auf 5 % Urea als Feuchthaltefaktor für raue, trockene Hände.\n\nDie Rezeptur kommt ohne Parfum und ohne Farbstoff aus.',
  698, 'EUR', 'https://www.amazon.de/dp/B01M0TG9FH?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61KmHlSkAdL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61KmHlSkAdL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'handcreme', 'Drogerie & Körperpflege', 'Eucerin',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'handcreme', 'drogerie-kosmetik'],
  'Gewinnt das Handcreme-Duell gegen Dr.Jart+ durch den Verzicht auf Duftstoff und Farbstoff.',
  'Handcreme, 75 ml, 5 % Urea, ohne Parfum und Farbstoff.',
  ARRAY['Ohne Parfum', 'Ohne Farbstoff', '5 % Urea als Feuchthaltefaktor'],
  ARRAY['Einschränkung: Amazon-INCI weicht bei Pentylene Glycol leicht von der Hersteller-INCI ab', 'Kleinere Füllmenge als Dr.Jart+']
),
(
  'cosrx-low-ph-good-morning-gel-cleanser-150ml', 'COSRX Low pH Good Morning Gel Cleanser 150 ml',
  'Sanftes Morgen-Gel mit Teebaumöl.',
  E'Der Low pH Good Morning Gel Cleanser von COSRX ist ein mildes Reinigungsgel mit niedrigem pH-Wert für die morgendliche Routine.\n\nDie Rezeptur enthält Teebaumöl und Betaine Salicylate.',
  899, 'EUR', 'https://www.amazon.de/dp/B016NRXO06?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61p4e9MbPiL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61p4e9MbPiL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'reinigung', 'Drogerie & Körperpflege', 'COSRX',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'reinigung', 'k-beauty'],
  'Unterliegt im Waschgel-Duell gegen Eucerin knapp wegen Teebaumöl und Betaine Salicylate.',
  'Gel-Reiniger, 150 ml, niedriger pH-Wert, mit Teebaumöl.',
  ARRAY['Niedriger pH-Wert', 'Milde Gel-Textur'],
  ARRAY['Enthält Teebaumöl', 'Enthält Betaine Salicylate']
),
(
  'eucerin-dermatoclean-hyaluron-reinigungsgel-200ml', 'Eucerin DermatoCLEAN HYALURON Reinigungsgel 200 ml',
  'Reinigungsgel mit Hyaluron, ohne Duftstoffe.',
  E'Das DermatoCLEAN HYALURON Reinigungsgel von Eucerin reinigt das Gesicht und enthält Hyaluron in der Rezeptur.\n\nDie Formel kommt ohne Duftstoffe und ohne ätherische Öle aus.',
  1390, 'EUR', 'https://www.amazon.de/dp/B08WH2MTRD?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41CE8NUBIUL._SL1200_.jpg', ARRAY['https://m.media-amazon.com/images/I/41CE8NUBIUL._SL1200_.jpg'],
  true, false, 'queen', 'beauty', 'reinigung', 'Drogerie & Körperpflege', 'Eucerin',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'reinigung', 'drogerie-kosmetik'],
  'Gewinnt das Waschgel-Duell gegen COSRX durch den Verzicht auf Duftstoffe und ätherische Öle.',
  'Reinigungsgel, 200 ml, mit Hyaluron, ohne Duftstoffe und ätherische Öle.',
  ARRAY['Ohne Duftstoffe', 'Ohne ätherische Öle', 'Enthält Hyaluron'],
  ARRAY['Keine Angaben zu weiteren Wirkstoffen in den Rohfakten', 'Größere Verpackung als COSRX (reiner Mengenunterschied)']
),
(
  'dear-klairs-supple-preparation-unscented-toner-180ml', 'Dear Klairs Supple Preparation Unscented Toner 180 ml',
  'Unscented Toner ohne Parfum und Alkohol.',
  E'Der Supple Preparation Unscented Toner von Dear Klairs ist ein feuchtigkeitsspendender Toner aus der K-Beauty-Pflege, wie der Name schon andeutet ohne Duftstoff konzipiert.\n\nDie Rezeptur kommt ohne Parfum und ohne Alcohol denat. aus.',
  1323, 'EUR', 'https://www.amazon.de/dp/B07B65NJLV?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71zEdo3JyDL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71zEdo3JyDL._AC_SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'gesichtswasser', 'Drogerie & Körperpflege', 'Dear Klairs',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'gesichtswasser', 'k-beauty'],
  'Trifft im Toner-Duell auf ein Unentschieden mit Eucerin – beide verzichten auf Parfum und Alcohol denat.',
  'Toner, 180 ml, ohne Parfum, ohne Alcohol denat.',
  ARRAY['Ohne Parfum', 'Ohne Alcohol denat.', 'Auf Feuchtigkeit ausgelegte Rezeptur'],
  ARRAY['Längere INCI-Liste als manche Alternativen (kein Qualitätsurteil)', 'Keine Angaben zu weiteren aktiven Wirkstoffen in den Rohfakten']
),
(
  'eucerin-dermatoclean-klaerendes-gesichtswasser-200ml', 'Eucerin DermatoClean Klärendes Gesichtswasser 200 ml',
  'Klärendes Gesichtswasser, ohne Parfum, ohne Alkohol.',
  E'Das Klärende Gesichtswasser aus der DermatoClean-Reihe von Eucerin ist als klassischer Toner für die Gesichtsreinigung positioniert.\n\nDie Formel kommt ohne Parfum und ohne Alcohol denat. aus.',
  1390, 'EUR', 'https://www.amazon.de/dp/B088RFQ68M?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71-QqPh2WBL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71-QqPh2WBL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'gesichtswasser', 'Drogerie & Körperpflege', 'Eucerin',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'gesichtswasser', 'drogerie-kosmetik'],
  'Steht im Toner-Duell mit Dear Klairs auf Augenhöhe – Unentschieden.',
  'Gesichtswasser, 200 ml, ohne Parfum, ohne Alcohol denat.',
  ARRAY['Ohne Parfum', 'Ohne Alcohol denat.', 'Größere Füllmenge als Klairs'],
  ARRAY['Keine Angaben zu speziellen Feuchtigkeitswirkstoffen in den Rohfakten', 'Keine zusätzlichen Wirkstoffangaben über die Grundrezeptur hinaus vorhanden']
),
(
  'illiyoon-ceramide-ato-concentrate-cream-75ml', 'ILLIYOON Ceramide Ato Concentrate Cream 75 ml',
  'Ceramidcreme für den Alltag – ohne Parfum.',
  E'Die Ceramide Ato Concentrate Cream von ILLIYOON ist eine Feuchtigkeitscreme auf Ceramid-Basis für den täglichen Gebrauch.\n\nDie Rezeptur ist ohne Parfum formuliert.',
  999, 'EUR', 'https://www.amazon.de/dp/B0CLD1T6MB?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/51+8YeFHr1L._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/51+8YeFHr1L._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'feuchtigkeitspflege', 'Drogerie & Körperpflege', 'ILLIYOON',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'feuchtigkeitspflege', 'k-beauty'],
  'Gewinnt das Cremeduell gegen NIVEA durch den Verzicht auf Parfum, bei einer kleinen Unsicherheit zur INCI-Quelle.',
  'Feuchtigkeitscreme, 75 ml, ceramidbasiert, ohne Parfum.',
  ARRAY['Ohne Parfum', 'Ceramidbasierte Rezeptur'],
  ARRAY['Einschränkung: Hersteller-INCI stammt von der 200-ml-Verpackungsvariante, nicht von der gelisteten 75-ml-Größe', 'Kleinere Füllmenge als NIVEA Creme']
),
(
  'nivea-creme-150ml', 'NIVEA Creme 150 ml',
  'Der Klassiker aus dem Blechdöschen – mit Parfum.',
  E'Die NIVEA Creme ist die bekannte Allzweck-Feuchtigkeitscreme im blauen Blechdöschen, seit Jahrzehnten fester Bestandteil vieler Badezimmerschränke.\n\nDie Rezeptur enthält Parfum sowie mehrere deklarierte Duftstoffe.',
  285, 'EUR', 'https://www.amazon.de/dp/B07YQG4M32?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61-Ycy8LcGL._SL1200_.jpg', ARRAY['https://m.media-amazon.com/images/I/61-Ycy8LcGL._SL1200_.jpg'],
  true, false, 'queen', 'beauty', 'feuchtigkeitspflege', 'Drogerie & Körperpflege', 'NIVEA',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'feuchtigkeitspflege', 'drogerie-kosmetik'],
  'Unterliegt im Cremeduell gegen ILLIYOON wegen Parfum und deklarierter Duftstoffe.',
  'Feuchtigkeitscreme, 150 ml, mit Parfum und deklarierten Duftstoffen.',
  ARRAY['Große, bekannte Füllmenge', 'Vielseitig einsetzbare Allzweckcreme'],
  ARRAY['Enthält Parfum', 'Enthält mehrere deklarierte Duftstoffe']
),
(
  'torriden-dive-in-hyaluronic-acid-serum-50ml', 'Torriden DIVE-IN Low Molecular Hyaluronic Acid Serum 50 ml',
  'Niedermolekulare Hyaluronsäure, ohne Parfum.',
  E'Das DIVE-IN Low Molecular Hyaluronic Acid Serum von Torriden setzt auf niedermolekulare Hyaluronsäure für die Feuchtigkeitspflege.\n\nDie Rezeptur ist ohne Parfum formuliert.',
  1695, 'EUR', 'https://www.amazon.de/dp/B07WZ2YTDP?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/51IhsMajjFL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/51IhsMajjFL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'serum', 'Drogerie & Körperpflege', 'Torriden',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'serum', 'k-beauty'],
  'Gewinnt das Serum-Duell gegen lavera durch den Verzicht auf Duftstoffe und Alcohol denat.',
  'Serum, 50 ml, niedermolekulare Hyaluronsäure, ohne Parfum.',
  ARRAY['Ohne Parfum', 'Niedermolekulare Hyaluronsäure als Basis'],
  ARRAY['Keine Angaben zu weiteren Wirkstoffen in den Rohfakten', 'Kleinere Füllmenge als das lavera-Serum']
),
(
  'lavera-hydro-refresh-serum', 'lavera Hydro Refresh Serum',
  'Naturkosmetik-Serum mit Parfum und Alkohol.',
  E'Das Hydro Refresh Serum von lavera ist als Naturkosmetik positioniert und arbeitet mit pflanzlichen Ölen und Auszügen.\n\nDie Rezeptur enthält Parfum, ätherische Öle und deklarierte Duftstoffe, außerdem steht Alcohol denat. weit oben in der INCI-Liste.',
  1195, 'EUR', 'https://www.amazon.de/dp/B085HFJ1LQ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61MON0fyQ0L._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61MON0fyQ0L._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'serum', 'Drogerie & Körperpflege', 'lavera',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'serum', 'drogerie-kosmetik', 'naturkosmetik'],
  'Unterliegt im Serum-Duell gegen Torriden wegen Duftstoffen und Alcohol denat. weit oben in der Liste.',
  'Serum, Naturkosmetik, mit Parfum, ätherischen Ölen und Alcohol denat.',
  ARRAY['Naturkosmetik-Rezeptur mit pflanzlichen Ölen', 'Zertifizierte Naturkosmetik-Positionierung'],
  ARRAY['Enthält Parfum und ätherische Öle', 'Alcohol denat. steht weit oben in der INCI-Liste']
),
(
  'dr-jart-ceramidin-skin-barrier-eye-cream-15ml', 'Dr.Jart+ Ceramidin Skin Barrier Moisturizing Eye Cream 15 ml',
  'Ceramidpflege für die Augenpartie – mit Parfum.',
  E'Die Ceramidin Skin Barrier Moisturizing Eye Cream von Dr.Jart+ ist eine Augencreme auf Ceramid-Basis für die empfindliche Augenpartie.\n\nDie Rezeptur enthält Parfum sowie den Farbstoff CI 19140.',
  2560, 'EUR', 'https://www.amazon.de/dp/B0DKXWDCKF?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61ooweaSbtL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61ooweaSbtL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'augenpflege', 'Drogerie & Körperpflege', 'Dr.Jart+',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'augenpflege', 'k-beauty'],
  'Erzielt im Augenpflege-Duell gegen sebamed ein Unentschieden – beide enthalten Parfum.',
  'Augencreme, 15 ml, mit Parfum und Farbstoff CI 19140.',
  ARRAY['Ceramidbasierte Rezeptur', 'Speziell für die Augenpartie konzipiert'],
  ARRAY['Enthält Parfum', 'Enthält den Farbstoff CI 19140']
),
(
  'sebamed-anti-aging-augencreme-q10-15ml', 'sebamed Anti-Aging Augencreme Q10 15 ml',
  'Q10-Augencreme mit Parfum.',
  E'Die Anti-Aging Augencreme Q10 von sebamed ist für die empfindliche Augenpartie konzipiert und enthält Q10 in der Rezeptur.\n\nDie Formel enthält außerdem Parfum und Benzyl Alcohol.',
  845, 'EUR', 'https://www.amazon.de/dp/B0CX936R3K?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/41WQVI3HmCL._SL1000_.jpg', ARRAY['https://m.media-amazon.com/images/I/41WQVI3HmCL._SL1000_.jpg'],
  true, false, 'queen', 'beauty', 'augenpflege', 'Drogerie & Körperpflege', 'sebamed',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'augenpflege', 'drogerie-kosmetik'],
  'Erzielt im Augenpflege-Duell gegen Dr.Jart+ ein Unentschieden – beide enthalten Parfum.',
  'Augencreme, 15 ml, mit Q10, Parfum und Benzyl Alcohol.',
  ARRAY['Enthält Q10', 'Speziell für die Augenpartie konzipiert'],
  ARRAY['Enthält Parfum', 'Enthält Benzyl Alcohol']
),
(
  'beauty-of-joseon-glow-serum-propolis-niacinamide-30ml', 'Beauty of Joseon Glow Serum Propolis + Niacinamide 30 ml',
  'Propolis-Serum für unreine Haut, wirkstoffbetont.',
  E'Das Glow Serum Propolis + Niacinamide von Beauty of Joseon kombiniert Propolis und Niacinamide mit Betaine Salicylate und Teebaum-Extrakt.\n\nDiese Kombination macht die Rezeptur wirkstoffbetonter als klassische Drogerie-Alternativen für unreine Haut.',
  1025, 'EUR', 'https://www.amazon.de/dp/B086VKZZZY?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/619pJvn1MUL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/619pJvn1MUL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'unreine-haut', 'Drogerie & Körperpflege', 'Beauty of Joseon',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'unreine-haut', 'k-beauty'],
  'Unterliegt im Duell um unreine Haut gegen sebamed wegen des aktiveren Wirkstoffprofils.',
  'Serum, 30 ml, mit Propolis, Niacinamide und Betaine Salicylate.',
  ARRAY['Enthält Niacinamide', 'Wirkstoffbetonte Rezeptur für unreine Haut'],
  ARRAY['Propolis kann bei manchen Menschen ein Kontaktallergen sein', 'Enthält zusätzlich Betaine Salicylate und Teebaum-Extrakt']
),
(
  'sebamed-clear-face-pflege-gel-aloe-vera-50ml', 'sebamed Clear Face Pflege-Gel Aloe vera 50 ml',
  'Reduziertes Pflege-Gel mit Aloe vera.',
  E'Das Clear Face Pflege-Gel von sebamed ist für unreine Haut konzipiert und enthält Aloe vera in der Rezeptur.\n\nDie Formel ist im Vergleich reduzierter aufgebaut.',
  649, 'EUR', 'https://www.amazon.de/dp/B0GWMZBMSY?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61YzFLtqoIL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61YzFLtqoIL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'unreine-haut', 'Drogerie & Körperpflege', 'sebamed',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'unreine-haut', 'drogerie-kosmetik'],
  'Gewinnt das Duell um unreine Haut gegen Beauty of Joseon durch die reduziertere Rezeptur.',
  'Pflege-Gel, 50 ml, mit Aloe vera, reduzierte Rezeptur.',
  ARRAY['Reduzierte Rezeptur', 'Enthält Aloe vera'],
  ARRAY['Keine Angaben zu Wirkstoffen wie Niacinamide in den Rohfakten', 'Weniger aktive Wirkstoffe als das Beauty-of-Joseon-Serum (je nach Hautbedürfnis auch von Vorteil)']
),
(
  'beauty-of-joseon-red-bean-refreshing-pore-mask-140ml', 'Beauty of Joseon Red Bean Refreshing Pore Mask 140 ml',
  'Abwaschbare Maske ohne Exfoliant.',
  E'Die Red Bean Refreshing Pore Mask von Beauty of Joseon ist eine abwaschbare Gesichtsmaske mit kurzer Einwirkzeit.\n\nDie Rezeptur enthält keinen Exfolianten und kommt ohne deklarierte Duftstoffe oder ätherische Öle aus.',
  1250, 'EUR', 'https://www.amazon.de/dp/B0BJPKX14D?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71pgJGEIxsL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71pgJGEIxsL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'gesichtsmaske', 'Drogerie & Körperpflege', 'Beauty of Joseon',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'gesichtsmaske', 'k-beauty'],
  'Gewinnt das Maskenduell gegen colibri knapp, da kein Exfoliant enthalten ist und die Einwirkzeit kürzer ausfällt.',
  'Abwaschbare Maske, 140 ml, ohne Exfoliant, ohne Duftstoffe.',
  ARRAY['Kein Exfoliant enthalten', 'Kürzere Einwirkzeit', 'Ohne Duftstoffe und ätherische Öle'],
  ARRAY['Kein Peeling-Effekt durch Exfolianten (je nach Hautbedürfnis auch Vorteil)', 'Kleinere Füllmenge als die colibri BHA Mask']
),
(
  'colibri-skincare-bha-mask-150ml', 'colibri skincare BHA Mask 150 ml',
  'BHA-Maske mit Salicylsäure als Exfoliant.',
  E'Die BHA Mask von colibri skincare ist eine abwaschbare Gesichtsmaske mit Salicylsäure als Exfolianten.\n\nDie Rezeptur kommt ohne deklarierte Duftstoffe oder ätherische Öle aus.',
  2499, 'EUR', 'https://www.amazon.de/dp/B06XQTTWL9?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71eTnp+mzhL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71eTnp+mzhL._SL1500_.jpg'],
  true, false, 'queen', 'beauty', 'gesichtsmaske', 'Drogerie & Körperpflege', 'colibri skincare',
  ARRAY['queen:beauty', 'k-beauty-vs-deutsche-kosmetik', 'gesichtsmaske', 'drogerie-kosmetik'],
  'Unterliegt im Maskenduell gegen Beauty of Joseon knapp wegen des enthaltenen Exfolianten.',
  'Abwaschbare Maske, 150 ml, mit Salicylsäure, ohne Duftstoffe.',
  ARRAY['Ohne Duftstoffe und ätherische Öle', 'Enthält Salicylsäure als Exfoliant', 'Größere Füllmenge als die Red Bean Mask'],
  ARRAY['Enthält Salicylsäure (Exfoliant) – Einwirkzeit beachten', 'Aktiverer Ansatz als die Red Bean Mask']
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  tagline = EXCLUDED.tagline,
  description = EXCLUDED.description,
  price_cents = EXCLUDED.price_cents,
  currency = EXCLUDED.currency,
  affiliate_url = EXCLUDED.affiliate_url,
  -- Never let a re-run overwrite an existing image with NULL/empty.
  image_url = COALESCE(NULLIF(EXCLUDED.image_url, ''), public.products.image_url),
  image_urls = CASE
    WHEN EXCLUDED.image_urls IS NULL OR cardinality(EXCLUDED.image_urls) = 0
      THEN public.products.image_urls
    ELSE EXCLUDED.image_urls
  END,
  is_published = EXCLUDED.is_published,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  amazon_category = EXCLUDED.amazon_category,
  brand = EXCLUDED.brand,
  shop_tags = EXCLUDED.shop_tags,
  editorial_note = EXCLUDED.editorial_note,
  key_fact = EXCLUDED.key_fact,
  pros = EXCLUDED.pros,
  cons = EXCLUDED.cons;

DO $$
DECLARE
  wanted_slugs CONSTANT text[] := ARRAY[
    'dr-jart-ceramidin-handcreme-100ml', 'eucerin-urearepair-5-urea-handcreme-75ml',
    'cosrx-low-ph-good-morning-gel-cleanser-150ml', 'eucerin-dermatoclean-hyaluron-reinigungsgel-200ml',
    'dear-klairs-supple-preparation-unscented-toner-180ml', 'eucerin-dermatoclean-klaerendes-gesichtswasser-200ml',
    'illiyoon-ceramide-ato-concentrate-cream-75ml', 'nivea-creme-150ml',
    'torriden-dive-in-hyaluronic-acid-serum-50ml', 'lavera-hydro-refresh-serum',
    'dr-jart-ceramidin-skin-barrier-eye-cream-15ml', 'sebamed-anti-aging-augencreme-q10-15ml',
    'beauty-of-joseon-glow-serum-propolis-niacinamide-30ml', 'sebamed-clear-face-pflege-gel-aloe-vera-50ml',
    'beauty-of-joseon-red-bean-refreshing-pore-mask-140ml', 'colibri-skincare-bha-mask-150ml'
  ];
  inserted_count integer;
BEGIN
  SELECT count(*) INTO inserted_count
  FROM public.products
  WHERE slug = ANY(wanted_slugs)
    AND is_published = true
    AND image_url IS NOT NULL AND image_url <> '';

  IF inserted_count <> array_length(wanted_slugs, 1) THEN
    RAISE EXCEPTION 'Postflight failed: expected 16 published products with an image, found %', inserted_count;
  END IF;
END
$$;

COMMIT;

-- All 16 rows are prepared as published because price and image data have been
-- filled in and reviewed. Production execution still requires explicit approval.
SELECT slug, name, price_cents, affiliate_url, image_url, is_published
FROM public.products
WHERE slug IN (
  'dr-jart-ceramidin-handcreme-100ml', 'eucerin-urearepair-5-urea-handcreme-75ml',
  'cosrx-low-ph-good-morning-gel-cleanser-150ml', 'eucerin-dermatoclean-hyaluron-reinigungsgel-200ml',
  'dear-klairs-supple-preparation-unscented-toner-180ml', 'eucerin-dermatoclean-klaerendes-gesichtswasser-200ml',
  'illiyoon-ceramide-ato-concentrate-cream-75ml', 'nivea-creme-150ml',
  'torriden-dive-in-hyaluronic-acid-serum-50ml', 'lavera-hydro-refresh-serum',
  'dr-jart-ceramidin-skin-barrier-eye-cream-15ml', 'sebamed-anti-aging-augencreme-q10-15ml',
  'beauty-of-joseon-glow-serum-propolis-niacinamide-30ml', 'sebamed-clear-face-pflege-gel-aloe-vera-50ml',
  'beauty-of-joseon-red-bean-refreshing-pore-mask-140ml', 'colibri-skincare-bha-mask-150ml'
)
ORDER BY slug;
