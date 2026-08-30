-- ============================================================================
-- FIXTURE 02 — Production-aehnlicher Datenbestand, Stand NACH Batch 1 und 2
-- ============================================================================
-- Zielbild ist der Zustand, den der Batch-2-Rollout am 2026-08-26 auf
-- project/ydiihvzcxaaoqhmgoqvu hinterlassen hat:
--
--   produkte                     376 gesamt, 372 published
--   Batch-3-Zielprodukte         10/10 published, 0/8 Value-Add-Felder gesetzt
--   Batch-1-Zielprodukte         10/10 published, vollstaendig befuellt
--   Batch-2-Zielprodukte         10/10 published, vollstaendig befuellt
--   Value-Add gesamt             20 Zeilen (Batch 1 plus Batch 2)
--   Value-Add-Schema             8/8 Spalten, 2/2 Constraints
--
-- Alle Texte hier sind Testdaten. Sie stammen nicht aus Production und werden
-- nie dorthin geschrieben — der Harness laeuft ausschliesslich lokal gegen
-- einen eigenen Cluster ohne TCP-Port.
--
-- ALLE ZEHN Batch-3-Zielzeilen tragen bereits eine editorial_note (Praefix
-- ALT-NOTE) und einen eigenen updated_at-Wert. Damit muss
-- 05_restore_value_add_batch3.sql beweisbar zehn verschiedene historische
-- Texte UND zehn verschiedene historische Zeitstempel exakt zurueckspielen.
-- ============================================================================

insert into public.categories (slug, name, description, emoji, sort_order) values
  ('lustige-gadgets',    'Lustige Gadgets',      'Kuriose Produkte',      '😂', 1),
  ('geschenke-maenner',  'Geschenke für Männer', 'Ideen für Männer',      '🎁', 2),
  ('buero-gadgets',      'Büro-Gadgets',         'Helfer am Schreibtisch','💼', 3),
  ('kuechen-gadgets',    'Küchen-Gadgets',       'Küchenhelfer',          '🍳', 4),
  ('geschenke-unter-20', 'Geschenke unter 20 €', 'Kleines Budget',        '💶', 5);

-- ----------------------------------------------------------------------------
-- 1) Die zehn BATCH-3-Zielprodukte — alle published, alle acht Value-Add-Felder
--    NULL, alle mit bestehender editorial_note.
--
--    Die Relationen bilden eine KETTE innerhalb der Zielmenge:
--      dicmky --alternative--> laptop-staender --complement--> tecknet
--    Relationsziele sind also laptop-staender und tecknet. Nur das Ende der
--    Kette, tecknet, bleibt nach 03 selbst relationslos — sonst entstuende ein
--    Kreis. laptop-staender ist Ziel UND Quelle, das ist gewollt.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, brand, editorial_note,
  created_at, updated_at
) values
('bartesian-cocktailmaschine-mit-kapseln', 'Bartesian Cocktailmaschine mit Kapseln',
 'Kapsel rein, Cocktail raus.',
 'Cocktailmaschine mit Kapsel-System. Kapseln enthalten Sirupe und Bitters, Spirituosen kommen aus eigenen Flaschen. Über 40 Cocktail-Varianten.',
 34999, 'https://amzn.to/test-bartesian', '/img/bartesian.jpg',
 true, 'babo', 'lifestyle', 'Bartesian',
 'ALT-NOTE bartesian: Kapselsystem, Sirupe und Bitters in der Kapsel, Spirituosen separat.',
 '2026-03-01 09:00:00+00', '2026-06-01 11:15:00+00'),

('dicmky-hoehenverstellbarer-schreibtisch-aufsatz', 'Dicmky Schreibtisch-Aufsatz',
 'Steh-Setup ohne neuen Tisch.',
 'Höhenverstellbarer Aufsatz mit Gasfeder-Mechanismus, ohne Elektronik, robust bis 15 kg.',
 12900, 'https://amzn.to/test-dicmky', '/img/dicmky.jpg',
 true, 'babo', 'tech', 'Dicmky',
 'ALT-NOTE dicmky: Aus einem flachen Bürotisch wird ein Steh-Sitz-Setup.',
 '2026-03-02 09:00:00+00', '2026-06-02 12:20:00+00'),

('laptop-staender-hoehenverstellbar-360-drehbar', 'Laptop-Ständer 360° drehbar',
 'Bildschirm auf Augenhöhe.',
 'Höhenverstellbarer Aluminium-Laptop-Ständer, 360 Grad drehbar, für Laptops bis 17 Zoll.',
 3490, 'https://amzn.to/test-laptopstaender', '/img/laptopstaender.jpg',
 true, 'babo', 'tech', null,
 'ALT-NOTE laptop: Bildschirm auf Augenhöhe, 360 Grad drehbar.',
 '2026-03-03 09:00:00+00', '2026-06-03 13:25:00+00'),

('tecknet-ergonomische-kabellose-maus-bluetooth', 'TECKNET Vertikale Bluetooth-Maus',
 'Die Hand steht senkrecht.',
 'Vertikale Bluetooth-Maus mit drei DPI-Stufen, geräuscharmem Klicken und USB-C-Ladung.',
 2209, 'https://amzn.to/test-tecknet', '/img/tecknet.jpg',
 true, 'babo', 'tech', 'TECKNET',
 'ALT-NOTE tecknet: Vertikale Handhaltung, drei DPI-Stufen, geräuscharm.',
 '2026-03-04 09:00:00+00', '2026-06-04 14:30:00+00'),

('rocketbook-wiederverwendbares-notizbuch-a4', 'Rocketbook Notizbuch A4',
 'Schreiben, scannen, wischen.',
 'Wiederverwendbares A4-Notizbuch, beschreibbar mit Frixion-Stiften, per App an Cloud-Dienste.',
 3990, 'https://amzn.to/test-rocketbook', '/img/rocketbook.jpg',
 true, 'babo', 'organisation', 'Rocketbook',
 'ALT-NOTE rocketbook: Handschrift per App als PDF, wiederverwendbar.',
 '2026-03-05 09:00:00+00', '2026-07-05 15:35:00+00'),

('ticktime-tk3-wuerfel-timer-countdown', 'Würfel Timer Countdown',
 'Fokus auf Knopfdruck.',
 'Würfel-Timer mit sechs voreingestellten Zeiten von 3 bis 60 Minuten, Vibrations- und Tonalarm.',
 5300, 'https://amzn.to/test-ticktime', '/img/ticktime.jpg',
 true, 'babo', 'organisation', 'Ticktime',
 'ALT-NOTE ticktime: Umdrehen, Countdown läuft, keine App.',
 '2026-03-06 09:00:00+00', '2026-06-06 16:40:00+00'),

('kabeltasche-edc-elektronik-organizer-reise', 'EDC-Kabeltasche',
 'Schluss mit Rucksack-Chaos.',
 'Elektronik-Organizer aus wasserabweisendem Nylon mit mehreren Innenfächern und Netz-Slots.',
 1990, 'https://amzn.to/test-kabeltasche', '/img/kabeltasche.jpg',
 true, 'babo', 'organisation', null,
 'ALT-NOTE kabeltasche: Ladegerät, Kabel, Sticks und Powerbank strukturiert.',
 '2026-03-07 09:00:00+00', '2026-06-07 17:45:00+00'),

('silikon-magnete-airfryer-backpapier-4er-set', 'Silikon-Magnete für Airfryer-Backpapier',
 'Das Papier bleibt liegen.',
 '4er-Set Silikon-Magnete, hitzebeständig bis 240 Grad, wiederverwendbar und spülmaschinenfest.',
 1290, 'https://amzn.to/test-silikonmagnete', '/img/silikonmagnete.jpg',
 true, 'queen', 'kueche', null,
 'ALT-NOTE silikonmagnete: Kein Papier mehr im Ventilator.',
 '2026-03-08 09:00:00+00', '2026-06-08 18:50:00+00'),

('tre-feuerstahl-xxl', 'TRE Feuerstahl XXL',
 'Funke statt Feuerzeug.',
 '12 cm langer Feuerstahl aus Magnesium-Legierung mit Schaber, auch bei Nässe nutzbar.',
 1690, 'https://amzn.to/test-feuerstahl', '/img/feuerstahl.jpg',
 true, 'babo', 'outdoor', 'TRE',
 'ALT-NOTE feuerstahl: Robuste Materialien, regentauglich, Kult unter Bushcraftern.',
 '2026-03-09 09:00:00+00', '2026-07-09 19:55:00+00'),

('bbq-wuerstchenhalter-maennchen-3er-set', 'BBQ-Würstchenhalter Männchen 3er-Set',
 'Sechs Würstchen im Stehen.',
 '3er-Set aus Edelstahl im Männchen-Look, spülmaschinenfest und hitzebeständig.',
 1590, 'https://amzn.to/test-bbqhalter', '/img/bbqhalter.jpg',
 true, 'babo', 'outdoor', null,
 'ALT-NOTE bbqhalter: Grillfeste werden zu kleinen Comedy-Auftritten.',
 '2026-03-10 09:00:00+00', '2026-06-10 20:00:00+00');

-- ----------------------------------------------------------------------------
-- 2) Die zehn BATCH-1-Zielprodukte — published und bereits VOLLSTAENDIG
--    befuellt. Verteilung wie auf Production: 3 alternative, 2 complement,
--    5 ohne Relation.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, editorial_note,
  fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind,
  created_at, updated_at
) values
('pinecil-usbc-loetkolben', 'Pinecil USB-C Lötkolben', 'Löten, wo du bist.',
 'Kompakter USB-C-Lötkolben.', 5990, 'https://amzn.to/test-pinecil',
 '/img/pinecil.jpg', true, 'babo', 'tools',
 'B1-NOTE pinecil: Testnotiz aus Batch 1.',
 'B1 fuer_wen pinecil', 'B1 nicht_fuer pinecil', 'B1 key_fact pinecil',
 array['B1 pro pinecil 1', 'B1 pro pinecil 2'],
 array['B1 con pinecil 1'],
 'ifixit-antistatik-matte-faltbar-esd', 'B1 reason pinecil', 'complement',
 '2026-01-10 09:00:00+00', '2026-08-23 20:00:00+00'),

('divoom-pixoo-led-panel', 'Divoom Pixoo LED-Panel', 'Pixel-Art am Schreibtisch.',
 '16x16-LED-Panel.', null, 'https://amzn.to/test-pixoo',
 '/img/pixoo.jpg', true, 'babo', 'tech',
 'B1-NOTE pixoo: Testnotiz aus Batch 1.',
 'B1 fuer_wen pixoo', 'B1 nicht_fuer pixoo', 'B1 key_fact pixoo',
 array['B1 pro pixoo 1', 'B1 pro pixoo 2'],
 array['B1 con pixoo 1'],
 'divoom-minitoo-retro-pc-lautsprecher-pixel', 'B1 reason pixoo', 'alternative',
 '2026-01-11 09:00:00+00', '2026-08-23 20:00:00+00'),

('sculpfun-s9-laser-engraver', 'Sculpfun S9 Lasergravierer', 'Gravieren zu Hause.',
 'Graviert Holz, Acryl und Leder.', 24900, 'https://amzn.to/test-sculpfun',
 '/img/sculpfun.jpg', true, 'babo', 'tools',
 'B1-NOTE sculpfun: Testnotiz aus Batch 1.',
 'B1 fuer_wen sculpfun', 'B1 nicht_fuer sculpfun', 'B1 key_fact sculpfun',
 array['B1 pro sculpfun 1', 'B1 pro sculpfun 2'],
 array['B1 con sculpfun 1'],
 null, null, null,
 '2026-01-12 09:00:00+00', '2026-08-23 20:00:00+00'),

('arc-reaktor-mk1-schwebend', 'Arc Reaktor MK1', 'Schwebt und leuchtet.',
 'Magnetisch schwebende Replika.', 8990, 'https://amzn.to/test-arc',
 '/img/arc.jpg', true, 'babo', 'deko',
 'B1-NOTE arc: Testnotiz aus Batch 1.',
 'B1 fuer_wen arc', 'B1 nicht_fuer arc', 'B1 key_fact arc',
 array['B1 pro arc 1', 'B1 pro arc 2'],
 array['B1 con arc 1'],
 null, null, null,
 '2026-01-13 09:00:00+00', '2026-08-23 20:00:00+00'),

('elektrische-wasserpistole-mit-led', 'Elektrische Wasserpistole', 'Kein Pumpen.',
 'Selbstansaugend mit LED.', 3490, 'https://amzn.to/test-wapi',
 '/img/wapi.jpg', true, 'babo', 'outdoor',
 'B1-NOTE wapi: Testnotiz aus Batch 1.',
 'B1 fuer_wen wapi', 'B1 nicht_fuer wapi', 'B1 key_fact wapi',
 array['B1 pro wapi 1', 'B1 pro wapi 2'],
 array['B1 con wapi 1'],
 'derayee-schaumstoff-wasserpistole', 'B1 reason wapi', 'alternative',
 '2026-01-14 09:00:00+00', '2026-08-23 20:00:00+00'),

('hot-wheels-ultimative-garage-3ft', 'Hot Wheels Ultimative Garage', 'Drei Etagen.',
 'Rund 1 m hoch.', 19900, 'https://amzn.to/test-hotwheels',
 '/img/hotwheels.jpg', true, 'miniboss', 'spielzeug',
 'B1-NOTE hotwheels: Testnotiz aus Batch 1.',
 'B1 fuer_wen hotwheels', 'B1 nicht_fuer hotwheels', 'B1 key_fact hotwheels',
 array['B1 pro hotwheels 1', 'B1 pro hotwheels 2'],
 array['B1 con hotwheels 1'],
 null, null, null,
 '2026-01-15 09:00:00+00', '2026-08-23 20:00:00+00'),

('lego-creator-3in1-retro-kamera-31147', 'LEGO Creator 3in1 Retro-Kamera',
 'Dreimal bauen.', '261 Teile.', 1999, 'https://amzn.to/test-lego31147',
 '/img/lego31147.jpg', true, 'miniboss', 'spielzeug',
 'B1-NOTE lego: Testnotiz aus Batch 1.',
 'B1 fuer_wen lego', 'B1 nicht_fuer lego', 'B1 key_fact lego',
 array['B1 pro lego 1', 'B1 pro lego 2'],
 array['B1 con lego 1'],
 null, null, null,
 '2026-01-16 09:00:00+00', '2026-08-23 20:00:00+00'),

('ninja-staysharp-messerset-6-teilig', 'Ninja StaySharp Messerset',
 'Schärft sich im Block.', '6-teiliges Set.', 17900,
 'https://amzn.to/test-ninja', '/img/ninja.jpg', true, 'queen', 'kueche',
 'B1-NOTE ninja: Testnotiz aus Batch 1.',
 'B1 fuer_wen ninja', 'B1 nicht_fuer ninja', 'B1 key_fact ninja',
 array['B1 pro ninja 1', 'B1 pro ninja 2'],
 array['B1 con ninja 1'],
 null, null, null,
 '2026-01-17 09:00:00+00', '2026-08-23 20:00:00+00'),

('n4-nussmilchbereiter-pflanzenmilch', 'N4 Nussmilchbereiter',
 'Pflanzenmilch selbst gemacht.', 'Mixt, kocht und filtert.', 12900,
 'https://amzn.to/test-n4', '/img/n4.jpg', true, 'queen', 'kueche',
 'B1-NOTE n4: Testnotiz aus Batch 1.',
 'B1 fuer_wen n4', 'B1 nicht_fuer n4', 'B1 key_fact n4',
 array['B1 pro n4 1', 'B1 pro n4 2'],
 array['B1 con n4 1'],
 'aeropress-go-tragbare-kaffeemaschine', 'B1 reason n4', 'complement',
 '2026-01-18 09:00:00+00', '2026-08-23 20:00:00+00'),

('welpen-usb-ladekabel-hunde-design', 'Welpen USB-Ladekabel',
 'Alltagsteil mit Motiv.', '1,5-m-Kabel.', 1290,
 'https://amzn.to/test-welpen', '/img/welpen.jpg', true, 'queen', 'lifestyle',
 'B1-NOTE welpen: Testnotiz aus Batch 1.',
 'B1 fuer_wen welpen', 'B1 nicht_fuer welpen', 'B1 key_fact welpen',
 array['B1 pro welpen 1', 'B1 pro welpen 2'],
 array['B1 con welpen 1'],
 'cbdywvr-2in1-ladekabel-mit-staender', 'B1 reason welpen', 'alternative',
 '2026-01-19 09:00:00+00', '2026-08-23 20:00:00+00');

-- ----------------------------------------------------------------------------
-- 3) Die zehn BATCH-2-Zielprodukte — published und vollstaendig befuellt.
--    Verteilung wie auf Production: 1 alternative, 1 complement, 8 ohne
--    Relation. Beide Relationsziele liegen innerhalb dieser Menge.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, editorial_note,
  fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind,
  created_at, updated_at
) values
('livondo-terracotta-pflanzenbewaesserung', 'Livondo Terracotta-Bewässerung',
 'Gießen ohne Strom.', 'Terracotta-Spikes nach dem Ollas-Prinzip.',
 1490, 'https://amzn.to/test-livondo', '/img/livondo.jpg',
 true, 'queen', 'haushalt', 'B2-NOTE livondo: Testnotiz aus Batch 2.',
 'B2 fuer_wen livondo', 'B2 nicht_fuer livondo', 'B2 key_fact livondo',
 array['B2 pro livondo 1', 'B2 pro livondo 2'], array['B2 con livondo 1'],
 null, null, null,
 '2026-05-01 09:00:00+00', '2026-08-26 09:00:00+00'),

('wixies-wichstuecher-scherzartikel', 'Wixies Servietten',
 'Sieben Servietten, ein Witz.', '7 bedruckte Servietten.',
 590, 'https://amzn.to/test-wixies', '/img/wixies.jpg',
 true, 'babo', 'irrenhaus', 'B2-NOTE wixies: Testnotiz aus Batch 2.',
 'B2 fuer_wen wixies', 'B2 nicht_fuer wixies', 'B2 key_fact wixies',
 array['B2 pro wixies 1', 'B2 pro wixies 2'], array['B2 con wixies 1'],
 null, null, null,
 '2026-05-02 09:00:00+00', '2026-08-26 09:00:00+00'),

('kaffeewaermer-tassenwaermer-elektrisch', 'Elektrischer Kaffeewärmer',
 'Die Tasse bleibt warm.', 'Tassenwärmer für den Schreibtisch.',
 2290, 'https://amzn.to/test-kaffeewaermer', '/img/kaffeewaermer.jpg',
 true, 'babo', 'tech', 'B2-NOTE kaffeewaermer: Testnotiz aus Batch 2.',
 'B2 fuer_wen kaffeewaermer', 'B2 nicht_fuer kaffeewaermer', 'B2 key_fact kaffeewaermer',
 array['B2 pro kaffeewaermer 1', 'B2 pro kaffeewaermer 2'],
 array['B2 con kaffeewaermer 1'],
 'gluecksgut-anti-stress-wuerfel', 'B2 reason kaffeewaermer', 'complement',
 '2026-05-03 09:00:00+00', '2026-08-26 09:00:00+00'),

('gluecksgut-anti-stress-wuerfel', 'Glücksgut Anti-Stress-Würfel',
 'Sechs Seiten für unruhige Hände.', 'Fidget-Würfel mit sechs Bedienseiten.',
 990, 'https://amzn.to/test-gluecksgut', '/img/gluecksgut.jpg',
 true, 'babo', 'organisation', 'B2-NOTE gluecksgut: Testnotiz aus Batch 2.',
 'B2 fuer_wen gluecksgut', 'B2 nicht_fuer gluecksgut', 'B2 key_fact gluecksgut',
 array['B2 pro gluecksgut 1', 'B2 pro gluecksgut 2'],
 array['B2 con gluecksgut 1'],
 'shashibo-formwechsel-box-magnetisch', 'B2 reason gluecksgut', 'alternative',
 '2026-05-04 09:00:00+00', '2026-08-26 09:00:00+00'),

('infactory-boyfriend-kissen', 'infactory Boyfriend-Kissen',
 'Ein Arm zum Anlehnen.', 'Kissen in Form eines Pyjama-Oberteils.',
 2490, 'https://amzn.to/test-infactory', '/img/infactory.jpg',
 true, 'queen', 'lifestyle', 'B2-NOTE infactory: Testnotiz aus Batch 2.',
 'B2 fuer_wen infactory', 'B2 nicht_fuer infactory', 'B2 key_fact infactory',
 array['B2 pro infactory 1', 'B2 pro infactory 2'],
 array['B2 con infactory 1'],
 null, null, null,
 '2026-05-05 09:00:00+00', '2026-08-26 09:00:00+00'),

('scheisse-quartett-kartenspiel', 'Scheisse-Quartett',
 'Quartett mit 32 Figuren.', 'Klassisches Quartett im Reiseformat.',
 890, 'https://amzn.to/test-quartett', '/img/quartett.jpg',
 true, 'babo', 'irrenhaus', 'B2-NOTE quartett: Testnotiz aus Batch 2.',
 'B2 fuer_wen quartett', 'B2 nicht_fuer quartett', 'B2 key_fact quartett',
 array['B2 pro quartett 1', 'B2 pro quartett 2'],
 array['B2 con quartett 1'],
 null, null, null,
 '2026-05-06 09:00:00+00', '2026-08-26 09:00:00+00'),

('riesige-aufblasbare-ente-pool', 'Riesige aufblasbare Pool-Ente',
 '1,2 Meter Ente.', 'Aufblasbare Ente aus PVC mit Schnellventil.',
 3490, 'https://amzn.to/test-ente', '/img/ente.jpg',
 true, 'miniboss', 'outdoor', 'B2-NOTE ente: Testnotiz aus Batch 2.',
 'B2 fuer_wen ente', 'B2 nicht_fuer ente', 'B2 key_fact ente',
 array['B2 pro ente 1', 'B2 pro ente 2'], array['B2 con ente 1'],
 null, null, null,
 '2026-05-07 09:00:00+00', '2026-08-26 09:00:00+00'),

('shashibo-formwechsel-box-magnetisch', 'Shashibo Formwechsel-Box',
 'Über 70 Formen aus einem Würfel.', 'Magnetische Formwechsel-Box.',
 2790, 'https://amzn.to/test-shashibo', '/img/shashibo.jpg',
 true, 'miniboss', 'puzzle', 'B2-NOTE shashibo: Testnotiz aus Batch 2.',
 'B2 fuer_wen shashibo', 'B2 nicht_fuer shashibo', 'B2 key_fact shashibo',
 array['B2 pro shashibo 1', 'B2 pro shashibo 2'],
 array['B2 con shashibo 1'],
 null, null, null,
 '2026-05-08 09:00:00+00', '2026-08-26 09:00:00+00'),

('eiswuerfelform-todesstern-star-wars', 'Todesstern-Eiswürfelform',
 'Drei Kugeln pro Durchgang.', 'Eiswürfelform aus lebensmittelechtem Silikon.',
 1290, 'https://amzn.to/test-todesstern', '/img/todesstern.jpg',
 true, 'babo', 'kueche', 'B2-NOTE todesstern: Testnotiz aus Batch 2.',
 'B2 fuer_wen todesstern', 'B2 nicht_fuer todesstern', 'B2 key_fact todesstern',
 array['B2 pro todesstern 1', 'B2 pro todesstern 2'],
 array['B2 con todesstern 1'],
 null, null, null,
 '2026-05-09 09:00:00+00', '2026-08-26 09:00:00+00'),

('katzenschlafsack-fuer-menschen', 'Katzenschlafsack für Menschen',
 'Einpacken, Hände bleiben frei.', 'Schlafsack mit Katzenohren-Kapuze.',
 4490, 'https://amzn.to/test-katzenschlafsack', '/img/katzenschlafsack.jpg',
 true, 'queen', 'lifestyle', 'B2-NOTE katzenschlafsack: Testnotiz aus Batch 2.',
 'B2 fuer_wen katzenschlafsack', 'B2 nicht_fuer katzenschlafsack',
 'B2 key_fact katzenschlafsack',
 array['B2 pro katzenschlafsack 1', 'B2 pro katzenschlafsack 2'],
 array['B2 con katzenschlafsack 1'],
 null, null, null,
 '2026-05-10 09:00:00+00', '2026-08-26 09:00:00+00');

-- ----------------------------------------------------------------------------
-- 4) Die fuenf BATCH-1-Relationsziele plus das in einer Batch-2-Beschreibung
--    manuell verlinkte Produkt — published, aber ohne Value-Add-Daten.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, created_at, updated_at
) values
('ifixit-antistatik-matte-faltbar-esd', 'iFixit Antistatik-Matte',
 'ESD-Schutz für den Basteltisch.', 'Faltbare ESD-Matte.',
 6990, 'https://amzn.to/test-ifixit', '/img/ifixit.jpg',
 true, 'babo', 'tools', '2026-02-01 09:00:00+00', '2026-02-01 09:00:00+00'),
('divoom-minitoo-retro-pc-lautsprecher-pixel', 'Divoom Ditoo Mini',
 'Pixel-Display mit Sound.', 'Retro-Lautsprecher mit Pixel-Anzeige.',
 8990, 'https://amzn.to/test-ditoo', '/img/ditoo.jpg',
 true, 'babo', 'tech', '2026-02-02 09:00:00+00', '2026-02-02 09:00:00+00'),
('derayee-schaumstoff-wasserpistole', 'Derayee Schaumstoff-Wasserpistole',
 'Leicht und nass.', 'Klassische Pumppistole.',
 1490, 'https://amzn.to/test-derayee', '/img/derayee.jpg',
 true, 'miniboss', 'outdoor', '2026-02-03 09:00:00+00', '2026-02-03 09:00:00+00'),
('aeropress-go-tragbare-kaffeemaschine', 'AeroPress Go',
 'Kaffee, der mitreist.', 'Tragbare Kaffeepresse.',
 3990, 'https://amzn.to/test-aeropress', '/img/aeropress.jpg',
 true, 'queen', 'kueche', '2026-02-04 09:00:00+00', '2026-02-04 09:00:00+00'),
('cbdywvr-2in1-ladekabel-mit-staender', 'CBDYWVR 2-in-1 Ladekabel',
 'Laden und aufstellen.', 'Ladekabel mit Ständer.',
 1590, 'https://amzn.to/test-cbdywvr', '/img/cbdywvr.jpg',
 true, 'queen', 'lifestyle', '2026-02-05 09:00:00+00', '2026-02-05 09:00:00+00'),
('vachichi-boyfriend-kissen-muskuloeser-arm', 'vachichi Boyfriend-Kissen',
 'Variante mit muskulösem Arm.', 'Kissen mit Arm, andere Ausführung.',
 2990, 'https://amzn.to/test-vachichi', '/img/vachichi.jpg',
 true, 'queen', 'lifestyle', '2026-04-20 09:00:00+00', '2026-04-20 09:00:00+00');

-- ----------------------------------------------------------------------------
-- 5) 340 weitere Produkte -> insgesamt 376, davon 372 published.
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
  'https://amzn.to/test-fuell-' || g,
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
from generate_series(1, 340) as g;

-- ----------------------------------------------------------------------------
-- 6) Listen / Nebendaten, damit die DB nicht kuenstlich leer wirkt.
-- ----------------------------------------------------------------------------
insert into public.lists (slug, title, intro, product_slugs, is_published) values
('fuer-den-schreibtisch', 'Für den Schreibtisch', 'Testintro.',
 array['ticktime-tk3-wuerfel-timer-countdown', 'rocketbook-wiederverwendbares-notizbuch-a4'],
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
  ('ticktime-tk3-wuerfel-timer-countdown', 'like', 'test-session-1'),
  ('tre-feuerstahl-xxl', 'skip', 'test-session-1');
