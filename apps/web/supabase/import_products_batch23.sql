-- =============================================================================
-- import_products_batch23.sql
-- 11 virale Produkte für dünne Kategorien: Frauen, Abitur, Fußball
-- Erstellt: 2026-06-14
-- HINWEIS: image_url leer lassen — Bilder manuell via Amazon-Produktseite ergänzen
-- =============================================================================

-- -----------------------------------------------------------------------------
-- GESCHENKE FÜR FRAUEN (3 neue Produkte)
-- -----------------------------------------------------------------------------

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'renpho-led-gesichtsmaske-rotlicht',
  'RENPHO Artemis LED Gesichtsmaske',
  '324 LEDs, 3 Lichtmodi — Rotlichtherapie für zuhause wie beim Dermatologen',
  E'Rotlichtherapie ist seit Jahren Standard in Hautarzt-Praxen. Die RENPHO Artemis bringt dieselbe Technologie nach Hause — kompakt, kabellos und FDA-zugelassen.\n\n324 LED-Chips in drei Wellenlängen: Rot (630nm) für Kollagenproduktion und Faltenreduktion, Nahinfrarot (850nm) das tiefer ins Gewebe eindringt, Blau (415nm) gegen Akne-Bakterien. Drei voreingestellte Modi je nach Hautziel. Die flexible Silikonmaske passt sich jedem Gesicht an, die abnehmbaren Augenmuscheln erleichtern die Reinigung.\n\n20 Minuten täglich. USB-C aufladbar. Für Zuhause und auf Reisen.',
  12900,
  'EUR',
  'https://www.amazon.de/dp/B0FJS8ZQWS?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'queen',
  'beauty',
  'gesichtspflege',
  ARRAY['beauty', 'beauty-tech', 'hautpflege', 'anti-aging', 'rotlicht', 'led-maske', 'gesichtspflege', 'geschenke-frauen', 'tiktok-viral', 'wellness']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'ems-gua-sha-gesichtsmassagegeraet-elektrisch',
  'EMS Gua Sha Gesichtsmassagegerät elektrisch',
  'Microstrom trifft Rotlicht — Face Lifting ohne Arztbesuch',
  E'Gua Sha kennt jede, die TikTok aufmacht. Aber das hier ist die elektrische Evolutionsstufe: EMS-Microstrom stimuliert die Gesichtsmuskulatur wie ein Mini-Training, während Rotlicht die Durchblutung anregt und Wärme (45°C) die Spannung aus den Muskeln löst.\n\n4 Lichtmodi (Rot, Blau, Violett, Grün) für verschiedene Hautziele — von Anti-Aging bis Porenfeuchtigkeit. 3 Intensitätsstufen, sanfte Vibration für die Lymphdrainage. Passt auf Schläfen, Wangen, Kinn und Hals.\n\nErgebnis nach 4 Wochen laut Kundenbewertungen: definierter Jawline, weniger Schwellungen, strahlendere Haut.',
  3499,
  'EUR',
  'https://www.amazon.de/dp/B0DPQ6NDTJ?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'queen',
  'beauty',
  'gesichtspflege',
  ARRAY['beauty', 'beauty-tech', 'gua-sha', 'ems', 'gesichtsmassage', 'hautpflege', 'anti-aging', 'rotlicht', 'geschenke-frauen', 'tiktok-viral']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'bedsure-satin-kissenbezug-doppelpack',
  'Bedsure Satin Kissenbezug 2er-Set',
  'Weniger Haarbruch, weniger Schlaffalten — der Kissenbezug den Friseure empfehlen',
  E'Wer einmal auf Satin geschlafen hat, versteht den Hype. Baumwolle zieht an Haaren und Haut — Satin gleitet. Das reduziert Haarbruch, verhindert Frizz und lässt das Gesicht morgens weniger zerknautscht aussehen.\n\nDas Bedsure 2er-Set aus hochwertigem Satin (ähnlich Seide) ist der Bestseller auf Amazon für genau diesen Zweck. 40x80cm, Umschlagverschluss für einfaches Aufziehen, maschinenwaschbar bei 30°C. Verfügbar in 10+ Farben.\n\nKleineres Investment, sichtbarer Effekt. Besonders geeignet für lockige oder gefärbte Haare — und für alle, die morgens gut aussehen wollen.',
  1899,
  'EUR',
  'https://www.amazon.de/dp/B07QQQVN1X?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'queen',
  'beauty',
  'schlaf',
  ARRAY['beauty', 'haarpflege', 'hautpflege', 'schlaf', 'satin', 'kissenbezug', 'wellness', 'geschenke-frauen', 'tiktok-viral', 'lifestyle']
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

-- -----------------------------------------------------------------------------
-- ABITUR & REISE (4 neue Produkte)
-- -----------------------------------------------------------------------------

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'fujifilm-instax-mini-12-sofortbildkamera',
  'Fujifilm Instax Mini 12 Sofortbildkamera',
  'Drücken. Warten. Foto in der Hand — Erinnerungen zum Anfassen',
  E'In einer Welt voller Screenshots und Cloud-Alben ist ein Foto das du in der Hand halten kannst etwas Besonderes. Die Fujifilm Instax Mini 12 druckt es in Sekunden.\n\nKein WLAN-Setup, keine App, kein Display das ablenkt. Einfach einlegen, drücken, fertig — ein 54x86mm Kreditkarten-Format-Foto das sofort entwickelt. Die Mini 12 hat automatische Belichtung, ein Selbstporträt-Spiegel für Selfies und einen Nahaufnahmemodus für Gruppenfotos.\n\nIdeal für Abiturbälle, Festivals, Reisen und alle Momente die nicht nur in der Cloud, sondern auf der Pinnwand landen sollen. Verfügbar in 5 Pastellfarben.',
  8999,
  'EUR',
  'https://www.amazon.de/dp/B0BV37WZJL?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'queen',
  'lifestyle',
  'fotografie',
  ARRAY['lifestyle', 'fotografie', 'sofortbildkamera', 'instax', 'geschenk', 'abitur', 'geschenke-frauen', 'reise', 'festival', 'kawaii']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'envami-rubbelkarte-weltkarte',
  'envami Rubbelkarte Weltkarte',
  'Jedes besuchte Land freirubbeln — deine Reisekarte als Wanddeko',
  E'Die Idee ist einfach und geil: Eine Weltkarte mit einer Goldfolie bedeckt. Für jedes Land das du bereist hast, rubbelt du die Folie ab — und darunter kommt eine detaillierte Farbkarte zum Vorschein.\n\nDie envami Rubbelweltkarte ist das Original Made in Germany: 68x43cm auf hochwertigem Kunstdruckpapier, hochglänzend beschichtet, mit deutschen Beschriftungen und allen Hauptstädten. Inklusive Rubbelstift und Rahmenhalterungen.\n\nDas perfekte Geschenk für alle die reisen, planen zu reisen oder einfach eine coole Wanddeko wollen. Für Abitur, Geburtstag oder als Inspiration für das nächste große Abenteuer.',
  2499,
  'EUR',
  'https://www.amazon.de/dp/B089NRZR43?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'lifestyle',
  'reise',
  ARRAY['lifestyle', 'reise', 'wanddeko', 'rubbelkarte', 'weltkarte', 'geschenk', 'abitur', 'geschenke-frauen', 'geschenke-maenner', 'travel']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'tessan-universal-reiseadapter-weltweit',
  'TESSAN Universal Reiseadapter',
  '224+ Länder, 2 USB-A + 2 USB-C — ein Stecker für die ganze Welt',
  E'Wer zum ersten Mal in ein fremdes Land reist, hat dieses Problem garantiert: falsche Stecker. Der TESSAN Universal Reiseadapter löst das ein für alle Mal.\n\n224+ Länder abgedeckt, inklusive USA, UK, Japan, Australien, Thailand und ganz Europa. Integriert sind 2 USB-A Ports und 2 USB-C Ports — gleichzeitiges Laden von bis zu 4 Geräten plus ein weiteres Gerät über die AC-Steckdose. Kompaktes Format, Schiebemechanismus für den jeweiligen Steckertyp.\n\nDas kleine Ding das im Rucksack landet und immer dann entscheidet ob man Strom hat oder nicht. Ideales Abiturgeschenk für alle die ein Gap Year, ein Auslandssemester oder eine Weltreise planen.',
  2199,
  'EUR',
  'https://www.amazon.de/dp/B0B2DRC76L?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'tech',
  'reise',
  ARRAY['tech', 'reise', 'reiseadapter', 'laden', 'travel', 'gadget', 'abitur', 'geschenk', 'auslandsstudium', 'gap-year']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'kindle-paperwhite-16gb-2024',
  'Amazon Kindle Paperwhite 16 GB (2024)',
  '7 Zoll, 25% schnellere Seitenumblätterei — der beste E-Reader den Amazon je gebaut hat',
  E'Wer viel liest, liest auf einem Kindle. Wer noch nicht auf einem Kindle gelesen hat, weiß noch nicht was er verpasst.\n\nDer Kindle Paperwhite 2024 ist die 12. Generation — mit dem bisher größten 7-Zoll-Display ohne Spiegelung, 300 PPI Schärfe und 25% schnelleren Seitenumblätterungen. Bis zu 12 Wochen Akku, IPX8 wasserdicht (30 Minuten in 2m Tiefe), warm-/kaltweißes Hintergrundlicht. 16 GB für tausende Bücher in der Tasche.\n\nDas Geschenk für alle die lesen wollen aber nie Zeit dafür haben — Bücher in der Hosentasche machen den Unterschied. Für Abitur, Studium, Weltreise.',
  13999,
  'EUR',
  'https://www.amazon.de/dp/B0CFP6F89F?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'tech',
  'ereader',
  ARRAY['tech', 'ereader', 'kindle', 'lesen', 'bücher', 'abitur', 'geschenk', 'studium', 'reise', 'premium']
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

-- -----------------------------------------------------------------------------
-- FUßBALL & WM 2026 (4 neue Produkte)
-- -----------------------------------------------------------------------------

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'panini-wm-2026-sticker-album-xxl-set',
  'Panini WM 2026 Sticker Album XXL Fan-Starterset',
  'Das offizielle Panini Album + 70 Sticker — Sammelfieber zur WM 2026',
  E'Es gibt Dinge die jede WM begleiten. Panini ist eines davon. Das offizielle FIFA World Cup 2026 Sticker-Album ist für alle 48 Nationalmannschaften ausgelegt — 980 verschiedene Sticker, 18 Spieler pro Team, Teamfoto und Verbandslogo als Sondersticker.\n\nDas XXL Fan-Starterset enthält das Album plus 10 Tüten (70 Sticker) zum direkten Loslegen — kein Leerbuch kaufen und dann noch Packs suchen müssen. Zusätzlich dabei: einen WM-Spielplan als Poster und eine Deutschland-Blumenkette.\n\nFür alle die WM-Fieber haben, tauschen wollen und früher auch Panini-Alben voll geklebt haben. Oder für die die es dieses Jahr zum ersten Mal erleben.',
  1999,
  'EUR',
  'https://www.amazon.de/dp/B0GWW3XHVZ?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'lifestyle',
  'fussball',
  ARRAY['lifestyle', 'fussball', 'wm-2026', 'panini', 'sticker', 'sammeln', 'wm-fieber', 'geschenke-maenner', 'kinder', 'sport']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'fussball-rebounder-trainingswand-faltbar',
  'Fußball Rebounder Trainingswand faltbar',
  'Pass-, Schuss- und Reaktionstraining alleine — rund um die Uhr',
  E'Das Problem mit Fußballtraining: Man braucht immer jemanden der zurückspielt. Diese Trainingswand löst das Problem.\n\nDer Fußball Rebounder prallt den Ball präzise zurück — für Passübungen, Schusstraining, Reaktionsübungen und Torschüsse auf Zielpunkte. Zwei einstellbare Winkel für flache Pässe oder Halbhochbälle. 100cm breit, faltbar für einfachen Transport, geeignet für Rasen und Kunstrasenboden.\n\nIdeal für alle die ernsthaft trainieren wollen — ohne Trainingspartner und ohne feste Trainingszeiten. Für Kinder ab 8 Jahren und Erwachsene. Inspiriert von der WM: Jetzt ist die beste Zeit um Fußball zu spielen.',
  4499,
  'EUR',
  'https://www.amazon.de/dp/B0DTTZZ6MY?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'miniboss',
  'sport',
  'fussball',
  ARRAY['sport', 'fussball', 'training', 'rebounder', 'trainingswand', 'outdoor', 'kinder', 'wm-2026', 'fitness']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'wm-2026-tippspiel-buch-ganze-familie',
  'WM 2026 — Das Tippspiel für die ganze Familie',
  'Tippen, Jubeln, Streiten — das WM-Erlebnis als Brettspiel für Zuhause',
  E'Kicktipp ist schön. Aber nichts schlägt ein Tippspiel das auf dem Tisch liegt wenn das Spiel läuft.\n\nDieses offizielle WM 2026 Tippspiel von Marc Fischer (KOSMOS) verwandelt jeden Spielabend in ein Erlebnis: Tipp-Bögen für alle Gruppenspiele und KO-Runden, Wissens-Duelle zwischen den Spielen, Challenge-Karten für Halbzeitpausen, Punktetabelle und Siegerpokal-Abschluss.\n\nFür 2-8 Spieler, ab 10 Jahren. Das Buch das beim Finale auf jedem WM-Tisch liegen sollte — für Familien, WGs, Arbeitskollegen und alle die WM-Abende unvergesslich machen wollen.',
  1099,
  'EUR',
  'https://www.amazon.de/dp/3690331129?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'babo',
  'lifestyle',
  'fussball',
  ARRAY['lifestyle', 'fussball', 'wm-2026', 'tippspiel', 'spieleabend', 'familie', 'geschenke-maenner', 'sport', 'party']
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

INSERT INTO products (slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'monodeal-mini-fussball-2in1-tor-torwand',
  'MONODEAL 2in1 Mini Fußballtor & Torwand',
  'Pop-Up in Sekunden — Garten-Fußball wenn das Spiel läuft',
  E'Wenn die WM läuft, will jeder draußen kicken. Dieses 2in1 Pop-Up Set von MONODEAL macht es möglich — in 30 Sekunden aufgebaut, kein Werkzeug nötig.\n\nEnthalten: ein vollwertiges Mini-Tor (Netz inkl.) und eine Torwand mit zwei Schusslöchern für gezielte Schussübungen. Wetterfest, für Rasen, Beton und Kunstrasen geeignet. Faltbar für Transport und Lagerung im Rucksack.\n\nPerfekt für Grillen mit Fußball, WM-Fanabende im Garten, Schulpausen oder als Trainingsgerät für Kinder. Wenn auf dem Bildschirm Tore fallen, will man welche schießen — dieses Set macht es möglich.',
  4499,
  'EUR',
  'https://www.amazon.de/dp/B0C2VHGR7M?tag=geeklist-21',
  '',
  ARRAY[]::text[],
  true,
  false,
  'miniboss',
  'sport',
  'fussball',
  ARRAY['sport', 'fussball', 'tor', 'garten', 'outdoor', 'kinder', 'wm-2026', 'training', 'spielen']
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
