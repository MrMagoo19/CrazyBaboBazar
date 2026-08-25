-- ============================================================================
-- FIXTURE 02 — Production-aehnlicher Datenbestand, Stand NACH Batch 1
-- ============================================================================
-- Zielbild ist der Zustand, den 01_preflight_read_only.sql am 2026-08-26 auf
-- project/ydiihvzcxaaoqhmgoqvu gemeldet hat:
--
--   produkte                     376 gesamt, 372 published
--   Batch-2-Zielprodukte         10/10 published, 0/8 Value-Add-Felder gesetzt
--   Batch-1-Zielprodukte         10/10 published, vollstaendig befuellt
--   Value-Add gesamt             10 Zeilen (ausschliesslich Batch 1)
--   Value-Add-Schema             8/8 Spalten, 2/2 Constraints
--
-- Alle Texte hier sind Testdaten. Sie stammen nicht aus Production und werden
-- nie dorthin geschrieben — der Harness laeuft ausschliesslich lokal gegen
-- einen eigenen Cluster ohne TCP-Port.
--
-- updated_at wird bewusst gestreut, damit 05_restore_value_add_batch2.sql
-- beweisbar zehn verschiedene historische Zeitstempel exakt zurueckspielen muss.
-- ============================================================================

insert into public.categories (slug, name, description, emoji, sort_order) values
  ('lustige-gadgets',    'Lustige Gadgets',      'Kuriose Produkte',      '😂', 1),
  ('geschenke-maenner',  'Geschenke für Männer', 'Ideen für Männer',      '🎁', 2),
  ('buero-gadgets',      'Büro-Gadgets',         'Helfer am Schreibtisch','💼', 3),
  ('kuechen-gadgets',    'Küchen-Gadgets',       'Küchenhelfer',          '🍳', 4),
  ('geschenke-unter-20', 'Geschenke unter 20 €', 'Kleines Budget',        '💶', 5);

-- ----------------------------------------------------------------------------
-- 1) Die zehn BATCH-2-Zielprodukte — alle published, alle acht Value-Add-Felder
--    NULL. Zwei tragen bereits eine editorial_note (Praefix ALT-NOTE): genau
--    diese beiden Texte werden von 03 bewusst ueberschrieben und muessen von
--    05 wortgleich zurueckkommen.
--
--    infactory-boyfriend-kissen traegt im Beschreibungstext den manuellen
--    Querverweis auf vachichi-boyfriend-kissen-muskuloeser-arm. Deshalb setzt
--    03 fuer diese Zeile bewusst KEINE strukturierte Relation.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, brand, editorial_note,
  created_at, updated_at
) values
('livondo-terracotta-pflanzenbewaesserung', 'Livondo Terracotta-Pflanzenbewässerung',
 'Gießen ohne Strom.',
 'Terracotta-Spikes nach dem Ollas-Prinzip. Werden befüllt und in die Erde gesetzt.',
 1490, 'https://example.invalid/aff/livondo', '/img/livondo.jpg',
 true, 'queen', 'haushalt', 'Livondo', null,
 '2026-05-01 09:00:00+00', '2026-06-01 11:15:00+00'),

('wixies-wichstuecher-scherzartikel', 'Wixies Servietten',
 'Sieben Servietten, ein Witz.',
 '7 bedruckte Servietten. Scherzartikel.',
 590, 'https://example.invalid/aff/wixies', '/img/wixies.jpg',
 true, 'babo', 'irrenhaus', null, null,
 '2026-05-02 09:00:00+00', '2026-06-02 12:20:00+00'),

('kaffeewaermer-tassenwaermer-elektrisch', 'Elektrischer Kaffeewärmer',
 'Die Tasse bleibt warm.',
 'Tassenwärmer für den Schreibtisch, Netzbetrieb, Abschaltautomatik.',
 2290, 'https://example.invalid/aff/kaffeewaermer', '/img/kaffeewaermer.jpg',
 true, 'babo', 'tech', null, null,
 '2026-05-03 09:00:00+00', '2026-06-03 13:25:00+00'),

('gluecksgut-anti-stress-wuerfel', 'Glücksgut Anti-Stress-Würfel',
 'Sechs Seiten für unruhige Hände.',
 'Fidget-Würfel mit sechs Bedienseiten.',
 990, 'https://example.invalid/aff/gluecksgut', '/img/gluecksgut.jpg',
 true, 'babo', 'organisation', 'Glücksgut', null,
 '2026-05-04 09:00:00+00', '2026-06-04 14:30:00+00'),

('infactory-boyfriend-kissen', 'infactory Boyfriend-Kissen',
 'Ein Arm zum Anlehnen.',
 'Kissen in Form eines Pyjama-Oberteils, ca. 54 x 50 cm, bei 30 Grad waschbar. Wer lieber einen muskulösen Arm mag, findet ihn beim vachichi-boyfriend-kissen-muskuloeser-arm.',
 2490, 'https://example.invalid/aff/infactory', '/img/infactory.jpg',
 true, 'queen', 'lifestyle', 'infactory',
 'ALT-NOTE infactory: Ein Kissen mit Arm. Klingt albern, funktioniert auf dem Sofa aber überraschend gut.',
 '2026-05-05 09:00:00+00', '2026-07-05 15:35:00+00'),

('scheisse-quartett-kartenspiel', 'Scheisse-Quartett',
 'Quartett mit 32 Figuren.',
 'Klassisches Quartett im Reiseformat.',
 890, 'https://example.invalid/aff/quartett', '/img/quartett.jpg',
 true, 'babo', 'irrenhaus', null, null,
 '2026-05-06 09:00:00+00', '2026-06-06 16:40:00+00'),

('riesige-aufblasbare-ente-pool', 'Riesige aufblasbare Pool-Ente',
 '1,2 Meter Ente.',
 'Aufblasbare Ente aus PVC mit Schnellventil.',
 3490, 'https://example.invalid/aff/ente', '/img/ente.jpg',
 true, 'miniboss', 'outdoor', null, null,
 '2026-05-07 09:00:00+00', '2026-06-07 17:45:00+00'),

('shashibo-formwechsel-box-magnetisch', 'Shashibo Formwechsel-Box',
 'Über 70 Formen aus einem Würfel.',
 'Magnetische Formwechsel-Box, ohne Batterie, ab 6 Jahren.',
 2790, 'https://example.invalid/aff/shashibo', '/img/shashibo.jpg',
 true, 'miniboss', 'puzzle', 'Shashibo', null,
 '2026-05-08 09:00:00+00', '2026-06-08 18:50:00+00'),

('eiswuerfelform-todesstern-star-wars', 'Todesstern-Eiswürfelform',
 'Drei Kugeln pro Durchgang.',
 'Eiswürfelform aus lebensmittelechtem Silikon für drei Star-Wars-Eiskugeln.',
 1290, 'https://example.invalid/aff/todesstern', '/img/todesstern.jpg',
 true, 'babo', 'kueche', null,
 'ALT-NOTE todesstern: Silikonform für drei Eiskugeln. Für Fans, nicht für große Runden.',
 '2026-05-09 09:00:00+00', '2026-07-09 19:55:00+00'),

('katzenschlafsack-fuer-menschen', 'Katzenschlafsack für Menschen',
 'Einpacken, Hände bleiben frei.',
 'Schlafsack mit Katzenohren-Kapuze, Armlöchern und Reißverschluss, Größen S bis XL.',
 4490, 'https://example.invalid/aff/katzenschlafsack', '/img/katzenschlafsack.jpg',
 true, 'queen', 'lifestyle', null, null,
 '2026-05-10 09:00:00+00', '2026-06-10 20:00:00+00');

-- ----------------------------------------------------------------------------
-- 2) Das Produkt, auf das infactory im Beschreibungstext manuell verweist.
--    Es ist bewusst KEIN Batch-2-Ziel und bekommt keine strukturierte Relation.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, created_at, updated_at
) values
('vachichi-boyfriend-kissen-muskuloeser-arm', 'vachichi Boyfriend-Kissen',
 'Variante mit muskulösem Arm.', 'Kissen mit Arm, andere Ausführung.',
 2990, 'https://example.invalid/aff/vachichi', '/img/vachichi.jpg',
 true, 'queen', 'lifestyle',
 '2026-04-20 09:00:00+00', '2026-04-20 09:00:00+00');

-- ----------------------------------------------------------------------------
-- 3) Die zehn BATCH-1-Zielprodukte — published und bereits VOLLSTAENDIG
--    befuellt. Verteilung wie auf Production: 3 alternative, 2 complement,
--    5 ohne Relation. Diese zehn Zeilen darf Batch 2 unter keinen Umstaenden
--    anfassen — genau das prueft der Harness spaeter Zeile fuer Zeile.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, editorial_note,
  fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind,
  created_at, updated_at
) values
('pinecil-usbc-loetkolben', 'Pinecil USB-C Lötkolben', 'Löten, wo du bist.',
 'Kompakter USB-C-Lötkolben.', 5990, 'https://example.invalid/aff/pinecil',
 '/img/pinecil.jpg', true, 'babo', 'tools',
 'B1-NOTE pinecil: Testnotiz aus Batch 1.',
 'B1 fuer_wen pinecil', 'B1 nicht_fuer pinecil', 'B1 key_fact pinecil',
 array['B1 pro pinecil 1', 'B1 pro pinecil 2'],
 array['B1 con pinecil 1'],
 'ifixit-antistatik-matte-faltbar-esd', 'B1 reason pinecil', 'complement',
 '2026-01-10 09:00:00+00', '2026-08-23 20:00:00+00'),

('divoom-pixoo-led-panel', 'Divoom Pixoo LED-Panel', 'Pixel-Art am Schreibtisch.',
 '16x16-LED-Panel.', null, 'https://example.invalid/aff/pixoo',
 '/img/pixoo.jpg', true, 'babo', 'tech',
 'B1-NOTE pixoo: Testnotiz aus Batch 1.',
 'B1 fuer_wen pixoo', 'B1 nicht_fuer pixoo', 'B1 key_fact pixoo',
 array['B1 pro pixoo 1', 'B1 pro pixoo 2'],
 array['B1 con pixoo 1'],
 'divoom-minitoo-retro-pc-lautsprecher-pixel', 'B1 reason pixoo', 'alternative',
 '2026-01-11 09:00:00+00', '2026-08-23 20:00:00+00'),

('sculpfun-s9-laser-engraver', 'Sculpfun S9 Lasergravierer', 'Gravieren zu Hause.',
 'Graviert Holz, Acryl und Leder.', 24900, 'https://example.invalid/aff/sculpfun',
 '/img/sculpfun.jpg', true, 'babo', 'tools',
 'B1-NOTE sculpfun: Testnotiz aus Batch 1.',
 'B1 fuer_wen sculpfun', 'B1 nicht_fuer sculpfun', 'B1 key_fact sculpfun',
 array['B1 pro sculpfun 1', 'B1 pro sculpfun 2'],
 array['B1 con sculpfun 1'],
 null, null, null,
 '2026-01-12 09:00:00+00', '2026-08-23 20:00:00+00'),

('arc-reaktor-mk1-schwebend', 'Arc Reaktor MK1', 'Schwebt und leuchtet.',
 'Magnetisch schwebende Replika.', 8990, 'https://example.invalid/aff/arc',
 '/img/arc.jpg', true, 'babo', 'deko',
 'B1-NOTE arc: Testnotiz aus Batch 1.',
 'B1 fuer_wen arc', 'B1 nicht_fuer arc', 'B1 key_fact arc',
 array['B1 pro arc 1', 'B1 pro arc 2'],
 array['B1 con arc 1'],
 null, null, null,
 '2026-01-13 09:00:00+00', '2026-08-23 20:00:00+00'),

('elektrische-wasserpistole-mit-led', 'Elektrische Wasserpistole', 'Kein Pumpen.',
 'Selbstansaugend mit LED.', 3490, 'https://example.invalid/aff/wapi',
 '/img/wapi.jpg', true, 'babo', 'outdoor',
 'B1-NOTE wapi: Testnotiz aus Batch 1.',
 'B1 fuer_wen wapi', 'B1 nicht_fuer wapi', 'B1 key_fact wapi',
 array['B1 pro wapi 1', 'B1 pro wapi 2'],
 array['B1 con wapi 1'],
 'derayee-schaumstoff-wasserpistole', 'B1 reason wapi', 'alternative',
 '2026-01-14 09:00:00+00', '2026-08-23 20:00:00+00'),

('hot-wheels-ultimative-garage-3ft', 'Hot Wheels Ultimative Garage', 'Drei Etagen.',
 'Rund 1 m hoch.', 19900, 'https://example.invalid/aff/hotwheels',
 '/img/hotwheels.jpg', true, 'miniboss', 'spielzeug',
 'B1-NOTE hotwheels: Testnotiz aus Batch 1.',
 'B1 fuer_wen hotwheels', 'B1 nicht_fuer hotwheels', 'B1 key_fact hotwheels',
 array['B1 pro hotwheels 1', 'B1 pro hotwheels 2'],
 array['B1 con hotwheels 1'],
 null, null, null,
 '2026-01-15 09:00:00+00', '2026-08-23 20:00:00+00'),

('lego-creator-3in1-retro-kamera-31147', 'LEGO Creator 3in1 Retro-Kamera',
 'Dreimal bauen.', '261 Teile.', 1999, 'https://example.invalid/aff/lego31147',
 '/img/lego31147.jpg', true, 'miniboss', 'spielzeug',
 'B1-NOTE lego: Testnotiz aus Batch 1.',
 'B1 fuer_wen lego', 'B1 nicht_fuer lego', 'B1 key_fact lego',
 array['B1 pro lego 1', 'B1 pro lego 2'],
 array['B1 con lego 1'],
 null, null, null,
 '2026-01-16 09:00:00+00', '2026-08-23 20:00:00+00'),

('ninja-staysharp-messerset-6-teilig', 'Ninja StaySharp Messerset',
 'Schärft sich im Block.', '6-teiliges Set.', 17900,
 'https://example.invalid/aff/ninja', '/img/ninja.jpg', true, 'queen', 'kueche',
 'B1-NOTE ninja: Testnotiz aus Batch 1.',
 'B1 fuer_wen ninja', 'B1 nicht_fuer ninja', 'B1 key_fact ninja',
 array['B1 pro ninja 1', 'B1 pro ninja 2'],
 array['B1 con ninja 1'],
 null, null, null,
 '2026-01-17 09:00:00+00', '2026-08-23 20:00:00+00'),

('n4-nussmilchbereiter-pflanzenmilch', 'N4 Nussmilchbereiter',
 'Pflanzenmilch selbst gemacht.', 'Mixt, kocht und filtert.', 12900,
 'https://example.invalid/aff/n4', '/img/n4.jpg', true, 'queen', 'kueche',
 'B1-NOTE n4: Testnotiz aus Batch 1.',
 'B1 fuer_wen n4', 'B1 nicht_fuer n4', 'B1 key_fact n4',
 array['B1 pro n4 1', 'B1 pro n4 2'],
 array['B1 con n4 1'],
 'aeropress-go-tragbare-kaffeemaschine', 'B1 reason n4', 'complement',
 '2026-01-18 09:00:00+00', '2026-08-23 20:00:00+00'),

('welpen-usb-ladekabel-hunde-design', 'Welpen USB-Ladekabel',
 'Alltagsteil mit Motiv.', '1,5-m-Kabel.', 1290,
 'https://example.invalid/aff/welpen', '/img/welpen.jpg', true, 'queen', 'lifestyle',
 'B1-NOTE welpen: Testnotiz aus Batch 1.',
 'B1 fuer_wen welpen', 'B1 nicht_fuer welpen', 'B1 key_fact welpen',
 array['B1 pro welpen 1', 'B1 pro welpen 2'],
 array['B1 con welpen 1'],
 'cbdywvr-2in1-ladekabel-mit-staender', 'B1 reason welpen', 'alternative',
 '2026-01-19 09:00:00+00', '2026-08-23 20:00:00+00');

-- ----------------------------------------------------------------------------
-- 4) Die fuenf BATCH-1-Relationsziele — published, aber ohne Value-Add-Daten.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, created_at, updated_at
) values
('ifixit-antistatik-matte-faltbar-esd', 'iFixit Antistatik-Matte',
 'ESD-Schutz für den Basteltisch.', 'Faltbare ESD-Matte.',
 6990, 'https://example.invalid/aff/ifixit', '/img/ifixit.jpg',
 true, 'babo', 'tools', '2026-02-01 09:00:00+00', '2026-02-01 09:00:00+00'),
('divoom-minitoo-retro-pc-lautsprecher-pixel', 'Divoom Ditoo Mini',
 'Pixel-Display mit Sound.', 'Retro-Lautsprecher mit Pixel-Anzeige.',
 8990, 'https://example.invalid/aff/ditoo', '/img/ditoo.jpg',
 true, 'babo', 'tech', '2026-02-02 09:00:00+00', '2026-02-02 09:00:00+00'),
('derayee-schaumstoff-wasserpistole', 'Derayee Schaumstoff-Wasserpistole',
 'Leicht und nass.', 'Klassische Pumppistole.',
 1490, 'https://example.invalid/aff/derayee', '/img/derayee.jpg',
 true, 'miniboss', 'outdoor', '2026-02-03 09:00:00+00', '2026-02-03 09:00:00+00'),
('aeropress-go-tragbare-kaffeemaschine', 'AeroPress Go',
 'Kaffee, der mitreist.', 'Tragbare Kaffeepresse.',
 3990, 'https://example.invalid/aff/aeropress', '/img/aeropress.jpg',
 true, 'queen', 'kueche', '2026-02-04 09:00:00+00', '2026-02-04 09:00:00+00'),
('cbdywvr-2in1-ladekabel-mit-staender', 'CBDYWVR 2-in-1 Ladekabel',
 'Laden und aufstellen.', 'Ladekabel mit Ständer.',
 1590, 'https://example.invalid/aff/cbdywvr', '/img/cbdywvr.jpg',
 true, 'queen', 'lifestyle', '2026-02-05 09:00:00+00', '2026-02-05 09:00:00+00');

-- ----------------------------------------------------------------------------
-- 5) 350 weitere Produkte -> insgesamt 376, davon 372 published.
--    g = 1 bis 4 bleiben unpublished, das ergibt 372 published wie auf
--    Production am 2026-08-26. Gut die Haelfte traegt eine editorial_note.
--    Diese Notizen liegen ausserhalb jeder Zielmenge und duerfen von 03 nicht
--    angefasst werden — genau das prueft der Harness spaeter.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, is_featured, shop_persona, shop_main_category, shop_tags,
  brand, editorial_note, category_id, created_at, updated_at
)
select
  'fuellprodukt-' || to_char(g, 'FM000'),
  'Füllprodukt ' || g,
  'Testtagline ' || g || '.',
  'Testbeschreibung für Füllprodukt ' || g || '.',
  case when g % 17 = 0 then null else 500 + (g * 37) % 24500 end,
  'https://example.invalid/aff/fuell-' || g,
  '/img/fuell-' || g || '.jpg',
  g > 4,
  (g % 29) = 0,
  (array['babo', 'queen', 'miniboss'])[1 + (g % 3)],
  (array['tech', 'kueche', 'lifestyle', 'outdoor', 'spielzeug',
         'haushalt', 'tools', 'deko'])[1 + (g % 8)],
  array[(array['babo', 'queen', 'miniboss'])[1 + (g % 3)] || ':' ||
        (array['tech', 'kueche', 'lifestyle', 'outdoor', 'spielzeug',
               'haushalt', 'tools', 'deko'])[1 + (g % 8)]],
  case when g % 5 = 0 then 'Testmarke ' || (g % 11) else null end,
  case when g % 2 = 0
       then 'ALT-NOTE fuell-' || g || ': bestehende Notiz ausserhalb jeder Zielmenge.'
       else null end,
  (select id from public.categories where slug = 'lustige-gadgets'),
  timestamptz '2025-09-01 08:00:00+00' + (g || ' hours')::interval,
  timestamptz '2026-04-01 08:00:00+00' + (g || ' minutes')::interval
from generate_series(1, 350) as g;

-- ----------------------------------------------------------------------------
-- 6) Listen / Nebendaten, damit die DB nicht kuenstlich leer wirkt.
-- ----------------------------------------------------------------------------
insert into public.lists (slug, title, intro, product_slugs, is_published) values
('fuer-den-schreibtisch', 'Für den Schreibtisch', 'Testintro.',
 array['kaffeewaermer-tassenwaermer-elektrisch', 'gluecksgut-anti-stress-wuerfel'],
 true),
('geschenke-fuer-echte-gamer', 'Geschenke für echte Gamer', 'Testintro.',
 array['divoom-pixoo-led-panel', 'arc-reaktor-mk1-schwebend'], true);

insert into public.page_content (page_key, title, intro) values
  ('category:lustige-gadgets', 'Lustige Gadgets', 'Testintro.'),
  ('guide:bestes-buero-gadget', 'Bestes Büro-Gadget', 'Testintro.');

insert into public.discovery_queue (name, source_url, status) values
  ('Testkandidat A', 'https://example.invalid/a', 'pending'),
  ('Testkandidat B', 'https://example.invalid/b', 'approved');

insert into public.swipes (product_slug, direction, session_id) values
  ('gluecksgut-anti-stress-wuerfel', 'like', 'test-session-1'),
  ('shashibo-formwechsel-box-magnetisch', 'skip', 'test-session-1');
