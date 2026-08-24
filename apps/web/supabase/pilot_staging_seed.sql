-- ============================================================
-- PILOT-/STAGING-SEED — Produktseiten-Pilotvorschau
-- ============================================================
-- STATUS: ENTWURF — NICHT AUSGEFÜHRT.
-- Ziel: ausschließlich das Pilot-/Staging-Projekt. NIEMALS Production.
--
-- Voraussetzung: pilot_staging_bootstrap.sql wurde vorher angewendet.
--
-- Inhalt (20 Produkte, 4 Kategorien, 7 Listen):
--   • 10 Pilotprodukte (bekommen später die Value-Add-Felder)
--   • 5 Referenzziele für alternative_slug (Alternative / Passt dazu)
--   • 5 Kontrollprodukte ohne Value-Add — Vergleichsseiten im alten Zustand
--   • 4 Kategorien: nur die, die von den obigen Produkten referenziert werden
--   • 7 Listen: nur die, die mindestens eines der Produkte enthalten
--     (nötig für den "Enthalten in Listen & Guides"-Block auf der Produktseite)
--
-- Herkunft: 1:1 read-only aus der Produktions-DB gelesen. Keine erfundenen
-- Fakten, keine geänderten Texte, keine geänderten Preise. IDs und Zeitstempel
-- werden übernommen, damit der Seed reproduzierbar ist.
--
-- Die Value-Add-Spalten (fuer_wen, nicht_fuer, key_fact, pros, cons,
-- alternative_*) bleiben hier bewusst NULL. Sie werden erst durch
-- backfill_pilot_value_add.sql gesetzt — so testet der Pilot exakt den
-- Pfad, der später auf Production laufen soll:
--     1) pilot_staging_bootstrap.sql
--     2) pilot_staging_seed.sql        (diese Datei)
--     3) backup_pilot_value_add.sql
--     4) backfill_pilot_value_add.sql
--
-- Basisdaten sind idempotent: on conflict (slug) do update. Bei den 10
-- Pilotprodukten überschreibt ein Wiederholungslauf bewusst weder die neuen
-- Value-Add-Felder noch editorial_note, damit nach einem Backfill kein
-- inkonsistenter Mischzustand entsteht. Soll der komplette Vorher-Zustand
-- wiederhergestellt werden, den dokumentierten Rollback verwenden.
-- ============================================================

begin;

-- Nie ohne den vom Bootstrap angelegten Pilot-Marker schreiben.
do $$
begin
  if to_regclass('pilot_meta.environment_guard') is null then
    raise exception 'Pilot-Seed abgebrochen: Umgebungsmarker fehlt.';
  end if;

  perform 1
  from pilot_meta.environment_guard
  where project_ref = 'nmzuycveumyfvtxdcnuc';

  if not found then
    raise exception 'Pilot-Seed abgebrochen: falscher Umgebungsmarker.';
  end if;
end $$;

-- ── KATEGORIEN ──────────────────────────────────────────────
insert into public.categories (id, slug, name, description, emoji, sort_order, created_at) values
  ('33ad2afa-0517-4e22-ada5-7499d1e89f32', 'lustige-gadgets', 'Lustige Gadgets', 'Kuriose und witzige Produkte für jeden Anlass', '😂', 1, '2026-04-25T18:19:19.446478+00:00'),
  ('a35c1804-e8e8-4ef2-a4b4-2ef95a2d25c2', 'geschenke-maenner', 'Geschenke für Männer', 'Coole Geschenkideen für Männer jeden Alters', '🎁', 2, '2026-04-25T18:19:19.446478+00:00'),
  ('6afb7f96-51ac-4d1a-8f60-66142f742789', 'kuechen-gadgets', 'Küchen-Gadgets', 'Praktische und verrückte Küchenhelfer', '🍳', 4, '2026-04-25T18:19:19.446478+00:00'),
  ('95b7774b-63b8-4fc0-ad83-7af93630dca7', 'geschenke-unter-20', 'Geschenke unter 20 €', 'Die besten Geschenke für kleines Budget', '💶', 5, '2026-04-25T18:19:19.446478+00:00')
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  emoji = excluded.emoji,
  sort_order = excluded.sort_order;

-- ── PRODUKTE: 10 PILOTSEITEN ────────────────────────────────
insert into public.products (id, category_id, slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, created_at, updated_at, shop_persona, shop_main_category, shop_sub_category, amazon_category, brand, shop_tags, editorial_note) values
  ('67376fa8-6d63-4b5d-b07b-dde5c67fcb9f', null, 'pinecil-usbc-loetkolben', 'PINECIL USB-C Lötkolben', 'Der smarteste Lötkolben der Welt – in 6 Sekunden heiß', '30 Gramm, USB-C betrieben, in 6 Sekunden auf Temperatur. Der PINECIL ist Open-Source, per Firmware erweiterbar und läuft mit jedem USB-C-Netzteil oder Powerbank.

Temperaturgenauigkeit auf 1°C, automatischer Schlafmodus, präzises Spitzensystem. Für Maker, Reparatur-Enthusiasten und alle, die nie wieder einen alten Kolben anfassen wollen.', 6326, 'EUR', 'https://www.amazon.de/dp/B096X6SG13?tag=geeklist-21&linkCode=ogi&th=1', 'https://m.media-amazon.com/images/I/61IX8eET+dL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/61IX8eET+dL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61x4Y3VEHZL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/51g--Z2xTRL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61CSh+xhtzL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/41Z8NiOnxML._AC_SL1000_.jpg'], true, false, '2026-06-10T20:29:13.882329+00:00', '2026-06-10T20:29:13.882329+00:00', 'babo', 'tech', 'maker', null, null, array['tech','geeklist'], null),
  ('fab76166-ee3a-44a5-a36b-8023de20d42f', null, 'divoom-pixoo-led-panel', 'Divoom Pixoo LED-Panel', 'Pixel-Art-Display für den Schreibtisch', '16×16 Pixel, unendliche Möglichkeiten. Zeigt Spotify-Visualizer, Krypto-Kurse, eigene Pixel-Art, GIFs, Uhrzeit oder Social-Media-Benachrichtigungen – alles konfigurierbar per App.

Der Divoom Pixoo ist das perfekte Desk-Accessoire für alle, die ihren Workspace ein bisschen mehr nach Arcade-Halle aussehen lassen wollen.', null, 'EUR', 'https://www.amazon.de/dp/B07HHXWN3C?tag=geeklist-21&linkCode=ogi&th=1', 'https://m.media-amazon.com/images/I/61YCcPzXvGL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/61YCcPzXvGL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71EpB2y5MRL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71KSji1QLnL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71G0HBXGi0L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71E5oVo5XbL._AC_SL1500_.jpg'], true, false, '2026-06-10T20:29:13.882329+00:00', '2026-06-10T20:29:13.882329+00:00', 'babo', 'tech', 'setup', null, null, array['tech','gaming','geeklist'], null),
  ('942a64d1-7fca-4632-8f65-302d9de3afb9', null, 'sculpfun-s9-laser-engraver', 'SCULPFUN S9 Laser-Graviermaschine', 'Graviert Holz, Acryl & Metall – Maker-Einstieg ohne Riesenetat', 'Holz, Acryl, Leder, anodisiertes Aluminium – der SCULPFUN S9 graviert alles mit 90W-Laserleistung (Spitzenleistung). Open-Source-Software (LaserGRBL, LightBurn), einfacher Aufbau in 20 Minuten.

Perfekt für alle die eigene Schilder, Schmuck, Geschenke oder einfach coole Sachen mit Laser brennen wollen – ohne 5-stelliges Budget.', 21500, 'EUR', 'https://www.amazon.de/dp/B09MFQQ9VC?tag=geeklist-21&linkCode=ogi&th=1', 'https://m.media-amazon.com/images/I/71kUSK2oZUL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71kUSK2oZUL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71r3RjF+yKL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71lbQQ2jChL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71l8k40wa4L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71T3ukGpyeL._AC_SL1500_.jpg'], true, false, '2026-06-10T20:29:13.882329+00:00', '2026-06-10T20:29:13.882329+00:00', 'babo', 'tech', 'maker', null, null, array['tech','geeklist'], null),
  ('b870b36b-6bc6-4e33-b900-2f7bb2d4391d', null, 'arc-reaktor-mk1-schwebend', 'Arc Reaktor MK1 – Schwebend & Rotierend', 'Tony Starks Herzstück – 1:1 Replika die wirklich schwebt', 'Kein Poster, kein 3D-Druck – sondern ein magnetisch schwebender, rotierender Arc Reactor in originalgetreuer 1:1-Größe. Die LED-Beleuchtung ist exakt wie im Film, das Schwebefeld stabil genug für den Dauerbetrieb.

Das ultimative Desk-Objekt für jeden Marvel-Fan und Iron-Man-Enthusiasten. Sieht aus als hätte Stark Industries geliefert.', 12900, 'EUR', 'https://www.amazon.de/dp/B0D2HLTT4Y?tag=geeklist-21&linkCode=ogi&th=1', 'https://m.media-amazon.com/images/I/71KnOHrLGbL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71KnOHrLGbL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71yLY03uzbL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81waVzEtDkL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61n66XQcW4L._AC_SL1000_.jpg','https://m.media-amazon.com/images/I/61t38hKybtL._AC_SL1000_.jpg','https://m.media-amazon.com/images/I/61VrTwzOzdL._AC_SL1000_.jpg'], true, false, '2026-06-10T20:32:28.134883+00:00', '2026-06-10T20:32:28.134883+00:00', 'babo', 'tech', 'setup', null, null, array['tech','gaming','geeklist'], null),
  ('38b8cfba-b1f1-4cd2-ae6a-407ec8e8e244', null, 'elektrische-wasserpistole-mit-led', 'Elektrische Wasserpistole mit LED', 'Selbstansaugende Elektro-Wasserpistole mit LED — große Reichweite, kein Pumpen nötig', 'Automatische Wasserpistole mit LED-Lichtern, selbstansaugend, große Kapazität, ultralange Reichweite. Kein manuelles Pumpen — einmal ins Wasser tauchen, Abzug halten, fertig.

Für alle, die Wasserkämpfe endlich auf ernstzunehmendem Niveau führen wollen. Funktioniert für Erwachsene und Kinder — und ist ehrlich gesagt für Erwachsene lustiger.', 2519, 'EUR', 'https://www.amazon.de/dp/B0DL5S57FD?coliid=IDVAEA91AI2ZI&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=003b7afc03f5cebed126ff84c85eeb32&ref_=as_li_ss_tl', 'https://m.media-amazon.com/images/I/71n9jOdcgoL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71n9jOdcgoL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71yKiKJRoVL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81AvwjlJRlL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71JxW6S--mL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71ZsMertKRL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71Y2BSI-IXL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81LziM1l8WL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71VY-u2bT+L._AC_SL1500_.jpg'], true, false, '2026-05-31T22:13:33.119348+00:00', '2026-05-31T22:13:33.119348+00:00', 'babo', 'outdoor', 'gadgets', null, null, '{}'::text[], null),
  ('54c3f6ad-f972-45f2-b533-3c4dd1b7325e', null, 'hot-wheels-ultimative-garage-3ft', 'Hot Wheels Ultimative Garage 3ft', 'Hot Wheels Parkhaus 3-stöckig mit Aufzug — fast 1 Meter hoch, 2 Autos inklusive', 'Drei Stockwerke, Aufzug, Waschanlage, Tankstelle — und das alles fast einen Meter hoch. Die ultimative Hot-Wheels-Garage kommt mit zwei Die-Cast-Autos direkt im Paket.

Für alle die zu viele Hot-Wheels-Autos haben und keinen Ort mehr wissen wohin damit. Das hier ist der Ort.', 9499, 'EUR', 'https://www.amazon.de/dp/B0BN15NTGG?linkCode=ll1&tag=geeklist-21', 'https://m.media-amazon.com/images/I/81O2mq9kWUL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/81O2mq9kWUL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/91WWe7-TS1L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81I3ha284DL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81nHHuOoRZL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81eeDzLav0L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/91-iwDLoNYL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81JG++B6+CL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81O2mq9kWUL._AC_SL1500_.jpg'], true, false, '2026-06-07T20:59:50.365903+00:00', '2026-06-07T20:59:50.365903+00:00', 'miniboss', 'spielzeug', 'fahrzeuge', null, null, '{}'::text[], null),
  ('c837a558-2287-42c7-83e6-02045eccbd7f', null, 'lego-creator-3in1-retro-kamera-31147', 'LEGO Creator 3-in-1 Retro-Kamera (31147)', 'LEGO Creator 3-in-1 — Retro-Kamera, Videokamera oder TV-Set aus einem Baukasten', 'Einmal bauen, dreimal spielen: Aus demselben Set entsteht entweder eine Retro-Fotokamera, eine Videokamera oder ein Retro-Fernseher. 261 Teile, drei verschiedene Bauerlebnisse.

Für Kinder ab 8 Jahren die kreativ bauen wollen — und für alle die irgendwie sowohl Lego- als auch Nostalgietick haben.', 1499, 'EUR', 'https://www.amazon.de/dp/B0CGY3FHDR?linkCode=ll1&tag=geeklist-21', 'https://m.media-amazon.com/images/I/81JbY4q5ZKL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/81JbY4q5ZKL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/816hYWUUbnL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71uF20S18fL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71Vnb3942gL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81jUU6RnmUL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71Hvm7tqQvL._AC_SL1500_.jpg'], true, false, '2026-06-07T20:59:50.365903+00:00', '2026-06-07T20:59:50.365903+00:00', 'miniboss', 'spielzeug', 'lego', null, null, '{}'::text[], null),
  ('2dfdc970-004c-40dc-805e-772ab6c1cc3b', null, 'ninja-staysharp-messerset-6-teilig', 'Ninja StaySharp Messerset 6-teilig', '6 Messer mit eingebautem Schärfer im Block — scharf halten ohne extra Aufwand', 'Ninja StaySharp Messerset mit 6 Teilen inklusive integrierten Schleif-Slots im Messerblock. Deutsche Stahl-Qualität, 15-Grad-Klingenwinkel, alle Standard-Messer für Küchen (Koch, Brot, Santoku, Fleisch, Zubereitung, Schere). Für Küchen, in denen ehrlich gekocht wird und Messer nicht nach 6 Monaten stumpf werden sollen.', 16490, 'EUR', 'https://www.amazon.de/dp/B0CLP63P3G?coliid=I2DHPQSEUSHM7D&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=9450c9fd00103b8c65801863c441608e&ref_=as_li_ss_tl', 'https://m.media-amazon.com/images/I/711eOYNO9vL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/711eOYNO9vL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/617oOFAzohL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71H+xCwQ2BL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71UTZuYzFEL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/814S7N7QQZL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/716mJiiXhjL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/818rbNA3aHL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61FGSQMSfzL._AC_SL1500_.jpg'], true, false, '2026-05-28T21:09:19.977526+00:00', '2026-07-04T00:00:00+00:00', 'queen', 'kueche', 'gadgets', null, null, '{}'::text[], 'Das Ninja StaySharp Messerset, das mit eingebauten Schärfsystem endlich aufhört, nach sechs Monaten stumpf zu werden. 6-teilig, mit Block. Für Küchen, in denen echt gekocht wird.'),
  ('58886923-acf9-40da-b51e-67c104c4188f', null, 'n4-nussmilchbereiter-pflanzenmilch', 'N4 Nussmilchbereiter Pflanzenmilch', '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten', 'N4 Nussmilchbereiter für frische Pflanzenmilch. Hafer-, Mandel-, Soja-, Reis- oder Cashew-Milch in 15 Minuten. Mixt, kocht, filtert automatisch. Für Menschen, die Bio-Milch-Preise satt haben und ihre Zutaten selbst kontrollieren wollen. Amortisiert sich nach 2 Monaten täglichem Frühstück.', 11999, 'EUR', 'https://www.amazon.de/dp/B0FKMBPLBF?linkCode=ll2&tag=geeklist-21&ref_=as_li_ss_tl', 'https://m.media-amazon.com/images/I/41bCLL0vUjL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71aVa+zbu-L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81YpLJ3r59L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/815izVLlIWL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71-SmYG5wML._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/816rkdDj1QL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81i+kGGToYL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81v54Gq9NLL._AC_SL1500_.jpg'], true, false, '2026-05-27T10:06:31.354641+00:00', '2026-07-04T00:00:00+00:00', 'queen', 'kueche', 'gadgets', null, null, '{}'::text[], 'Der N4 Nussmilchbereiter für Pflanzenmilch, aus dem in 15 Minuten frische Hafer-, Mandel- oder Sojamilch entsteht. Für Menschen, die Milch-Alternativen ernst nehmen und den Preis im Bio-Laden satt haben.'),
  ('d7ecdf55-b91d-4ee5-baa7-a04619f35543', null, 'welpen-usb-ladekabel-hunde-design', 'Welpen USB-Ladekabel Hunde-Design', 'Aufladen mit Wow-Faktor.', 'Welpen-USB-Ladekabel im Hunde-Design. Verstärkter Anschluss (USB-C oder Lightning), robuste Ummantelung mit süßem Welpen-Motiv, Zugentlastung integriert. 1,5 m Länge. Für Hunde-Fans und alle, deren Standard-Kabel nach 3 Wochen an der Buchse brechen — mit Charakter.', 1519, 'EUR', 'https://www.amazon.de/dp/B0F28L9Z2K?tag=geeklist-21', 'https://m.media-amazon.com/images/I/314s6Yjhk1L._AC_.jpg', array['https://m.media-amazon.com/images/I/51EH3JpvkmL._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/51Ys1oqY0RL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/6190X+VKtUL._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/61uDldj1HIL._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/71jzqeN93bL._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/61hgTBnYGML._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/61+0nTxL3-L._AC_SL1280_.jpg','https://m.media-amazon.com/images/I/61Vcl8qGraL._AC_SL1280_.jpg'], true, false, '2026-05-04T21:10:37.172097+00:00', '2026-07-04T00:00:00+00:00', 'queen', 'lifestyle', 'deko', null, null, array['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100'], 'Das Welpen-USB-Ladekabel im Hunde-Design, aus dem Handy-Laden ein kleines Deko-Statement wird. Verstärkter Anschluss, Meterware. Für Hunde-Fans und alle, deren Standard-Kabel nach 3 Wochen brechen.')
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  affiliate_url = excluded.affiliate_url,
  image_url = excluded.image_url,
  image_urls = excluded.image_urls,
  is_published = excluded.is_published,
  is_featured = excluded.is_featured,
  created_at = excluded.created_at,
  updated_at = excluded.updated_at,
  shop_persona = excluded.shop_persona,
  shop_main_category = excluded.shop_main_category,
  shop_sub_category = excluded.shop_sub_category,
  amazon_category = excluded.amazon_category,
  brand = excluded.brand,
  shop_tags = excluded.shop_tags;

-- ── PRODUKTE: 5 REFERENZZIELE (alternative_slug) ────────────
-- Ohne diese Zeilen bliebe der Alternative-/Passt-dazu-Block leer, weil das
-- Template nur rendert, wenn das Zielprodukt existiert UND is_published ist.
insert into public.products (id, category_id, slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, created_at, updated_at, shop_persona, shop_main_category, shop_sub_category, amazon_category, brand, shop_tags, editorial_note) values
  ('d8094ff2-3dc5-41e3-a9b9-f5d58b458236', null, 'ifixit-antistatik-matte-faltbar-esd', 'iFixit Antistatik-Matte faltbar ESD', 'Reparieren ohne statische Entladung.', 'iFixit ESD-Antistatik-Arbeitsmatte, faltbar, mit Erdungsband und magnetischem Schraubenfach. Schützt Handys, Motherboards, Grafikkarten und Kameras beim Basteln vor statischer Entladung. Rutschfeste Unterseite, hitzebeständig für Löt-Arbeiten. Für alle, die Elektronik reparieren statt wegwerfen.', 2795, 'EUR', 'https://www.amazon.de/dp/B01BLPBOS4?tag=geeklist-21', 'https://m.media-amazon.com/images/I/41V6wR9fwpL._AC_.jpg', array['https://m.media-amazon.com/images/I/41V6wR9fwpL._AC_.jpg'], true, false, '2026-04-29T07:26:13.129917+00:00', '2026-07-04T00:00:00+00:00', 'babo', 'tech', 'gadgets', null, null, array['babo:tech','preis:unter50','preis:unter100'], 'Für alle die Elektronik reparieren oder modifizieren — die antistatische Matte ist kein Luxus sondern Schutz. iFixit ist die Referenz in diesem Bereich, das merkt man an der Qualität.'),
  ('25b76e4d-7582-4f15-8d76-1446eebce022', null, 'divoom-minitoo-retro-pc-lautsprecher-pixel', 'Divoom MiniToo Retro PC-Lautsprecher', 'Sieht aus wie ein Rechner von 1985. Klingt wie 2026.', 'Divoom hat einen Bluetooth-Lautsprecher gebaut der aussieht wie ein Retro-PC der 80er — komplett mit Pixel-Display auf dem du eigene Animationen, Uhren, Wetter oder Nachrichten anzeigen kannst.

Bluetooth und USB-Audio, Wecker mit weißem Rauschen, DIY Pixelmotive via App. Das Display ist programmierbar — perfekt für Schreibtisch-Setups die auffallen sollen. Beige-Gehäuse im klassischen Computer-Look, ca. 11 cm groß.

4,4 Sterne bei 168 Bewertungen. Für Gaming-Setups, Homeoffice-Tische und alle die Nostalgie mit moderner Technik verbinden wollen. Eines der besten Schreibtisch-Gadgets wenn man nicht einfach nur einen Lautsprecher will — sondern eine Persönlichkeit.', 6999, 'EUR', 'https://www.amazon.de/dp/B0FRF3XGQ4?tag=geeklist-21', 'https://divoom.com/cdn/shop/files/minitoo-1.jpg', array['https://divoom.com/cdn/shop/files/minitoo-1.jpg'], true, false, '2026-06-19T22:13:10.498053+00:00', '2026-07-04T00:00:00+00:00', 'babo', 'tech', 'schreibtisch-setup', null, null, array['tech','schreibtisch-setup','lautsprecher','bluetooth','retro','pixel','divoom','gaming','homeoffice','setup','geschenk'], null),
  ('03045600-c96a-4fe9-a36a-997de3a16594', '33ad2afa-0517-4e22-ada5-7499d1e89f32', 'derayee-schaumstoff-wasserpistole', 'Schaumstoff Wasserpistole', 'Wasserschlacht die Spaß macht', 'Derayee Schaumstoff-Wasserpistole — großer Wasser-Tank, hohe Reichweite, robust genug für ganze Sommer-Kriege. Ergonomischer Griff für Kinder- und Erwachsenenhände. Nachfüllen unter jedem Wasserhahn. Familien-Wochenend-Klassik, die von Balkon-Schlacht bis Bade-See-Ausflug funktioniert.', 899, 'EUR', 'https://amzn.to/4vRPfTB', 'https://m.media-amazon.com/images/I/81jlQuZsNjL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/81jlQuZsNjL._AC_SL1500_.jpg'], true, false, '2026-04-25T18:22:34.160392+00:00', '2026-07-04T00:00:00+00:00', 'miniboss', 'spass', 'party', null, null, array['miniboss:spass','preis:unter20','preis:unter50','preis:unter100'], 'Die Derayee Schaumstoff-Wasserpistole, mit der Sommer-Rache endlich strategisch wird. Reichweite ordentlich, Nachfüllen simpel, Kids und Erwachsene gleich Waffen-fähig. Familien-Wochenend-Klassik.'),
  ('2a6cfb21-cefc-4361-be6f-7df1785f8abe', null, 'aeropress-go-tragbare-kaffeemaschine', 'AeroPress Go Tragbare Kaffeemaschine', 'Barista-Kaffee überall.', 'Du kennst das: Überall hinfahren, aber nirgends einen anständigen Kaffee bekommen. Entweder schmeckt er wie Spülwasser oder kostet so viel wie ein kleines Auto. Die AeroPress Go ist dein stiller Held gegen dieses Dilemma.

Das Ding ist kompakt wie ein Radiergummi auf Stereoiden – passt in jeden Rucksack, jeden Koffer, sogar in deine Seele (metaphorisch). Und trotz Mini-Format braut sie dir in unter einer Minute einen Kaffee, der ehrlich gesagt oft besser ist als das teuer Zeug von der Ecke. Vollmundig, sauber, keine Bitterkeit – nur pure Kaffee-Zufriedenheit.

Zur Basis gehören ein isolierter Trinkbecher (weil dein Kaffee auch noch warm sein soll, wenn du ihn trinkst) und eine praktische Tasche zum Mitnehmen. Ob Campingtrip, Büro-Flucht oder die nächste Dienstreise – mit der AeroPress Go wirst du zum Barista deiner Träume. Nur eben überall.

Dein mobiles Kaffeeparadies wartet. Zugreifen? Gute Idee.', 4400, 'EUR', 'https://www.amazon.de/dp/B07YVL8SF3?tag=geeklist-21', 'https://m.media-amazon.com/images/I/31PI2nCKkBL._AC_.jpg', array['https://m.media-amazon.com/images/I/512XTywyANL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71nQaCP0DVL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61vR-QqjP8L._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61LLw37IyDL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61jGPsiYeQL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71o-PR2VfYL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/51ecbiHk7kL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/51sS83mCmGL._AC_SL1500_.jpg'], true, false, '2026-04-29T07:26:13.129917+00:00', '2026-04-29T07:26:13.129917+00:00', 'queen', 'kueche', 'gadgets', null, null, array['queen:kueche','preis:unter50','preis:unter100'], 'Die AeroPress ist unter Kaffeeliebhabern seit Jahren Kult — und das Go ist die Reiseversion die wirklich mitkommt. Wer guten Kaffee auch unterwegs will und keine Kapselmaschine nehmen will.'),
  ('73c9ecdc-8235-49e9-854b-4b61b066d51d', null, 'cbdywvr-2in1-ladekabel-mit-staender', 'CBDYWVR 2-in-1 Ladekabel mit Ständer', '240W Schnellladekabel mit eingebautem Ständer — Typ-C, 1,5m, für Handy, Tablet und Laptop', 'CBDYWVR 2-in-1 Ladekabel mit eingebautem Ständer. USB-C, 240 Watt Schnellladung, 1,5 Meter Länge, mehrfach verstellbar — das Kabel steht aufgestellt, das Telefon liegt nicht mehr flach beim Laden. Auch für Tablets und Laptops. Multitool-Denken fürs Ladekabel, aufgeräumte Nachttische.', 1289, 'EUR', 'https://www.amazon.de/dp/B0G63HGHGV?coliid=I1VH5FPO3FLKX8&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=ff250a4b2272fd1d3ed2bfaf580ea438&ref_=as_li_ss_tl', 'https://m.media-amazon.com/images/I/61P467fTrrL._SL1500_.jpg', array['https://m.media-amazon.com/images/I/61P467fTrrL._SL1500_.jpg','https://m.media-amazon.com/images/I/71eebImPv6L._SL1500_.jpg','https://m.media-amazon.com/images/I/71bkqgrnMhL._SL1500_.jpg','https://m.media-amazon.com/images/I/71ny5Ak6LxL._SL1500_.jpg','https://m.media-amazon.com/images/I/719L3aKn22L._SL1500_.jpg','https://m.media-amazon.com/images/I/71vbNFYfEDL._SL1500_.jpg','https://m.media-amazon.com/images/I/71Nv3qZOTlL._SL1500_.jpg','https://m.media-amazon.com/images/I/71aDLo2xcnL._SL1500_.jpg'], true, false, '2026-05-31T22:17:06.445278+00:00', '2026-07-04T00:00:00+00:00', 'babo', 'tech', 'setup', null, null, '{}'::text[], 'Das CBDYWVR 2-in-1 Ladekabel mit eingebautem Ständer, 240 W Schnellladung, USB-C. Kein Kabel-Salat auf dem Nachttisch mehr, das Telefon steht beim Laden aufrecht. Multitool-Denken fürs Ladekabel.')
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  affiliate_url = excluded.affiliate_url,
  image_url = excluded.image_url,
  image_urls = excluded.image_urls,
  is_published = excluded.is_published,
  is_featured = excluded.is_featured,
  created_at = excluded.created_at,
  updated_at = excluded.updated_at,
  shop_persona = excluded.shop_persona,
  shop_main_category = excluded.shop_main_category,
  shop_sub_category = excluded.shop_sub_category,
  amazon_category = excluded.amazon_category,
  brand = excluded.brand,
  shop_tags = excluded.shop_tags,
  editorial_note = excluded.editorial_note;

-- ── PRODUKTE: 5 KONTROLLSEITEN (ohne Value-Add) ─────────────
-- Je eine passende persona/shop_main_category-Kombination zu den Pilotseiten:
-- dienen als Vergleichsseite und füllen zugleich den "Könnte dich auch
-- interessieren"-Block (getRelatedProducts matcht auf persona + main_category).
insert into public.products (id, category_id, slug, name, tagline, description, price_cents, currency, affiliate_url, image_url, image_urls, is_published, is_featured, created_at, updated_at, shop_persona, shop_main_category, shop_sub_category, amazon_category, brand, shop_tags, editorial_note) values
  ('bc421ece-a1cf-4247-a2fa-a5f2b7323c49', null, 'experimentierset-kinder-100-experimente-stem', 'Experimentierset Kinder 100+ Experimente STEM', 'Wissenschaft zum Anfassen.', 'Experimentier-Set für Kinder mit 100 STEM-Versuchen — Chemie, Physik, Optik, Wasser-Experimente, Vulkane. Echte Materialien, kein Bildschirm, kein Abo. Ab 8 Jahren, mit ausführlichem Anleitungsbuch. Für regnerische Sonntage, Ferien oder Kinder, die Wissenschaft als Spaß erleben sollen.', 2999, 'EUR', 'https://www.amazon.de/dp/B0C7Q183MT?tag=geeklist-21', 'https://m.media-amazon.com/images/I/51c3jagm+ZL._AC_.jpg', array['https://m.media-amazon.com/images/I/810LpyAuTvL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81gqA-IiLaL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81HLCdBIksL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71V+LoxRRkL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/91BirHJsxML._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/81a4YevR1aL._AC_SL1500_.jpg'], true, false, '2026-05-03T20:26:18.161278+00:00', '2026-07-04T00:00:00+00:00', 'miniboss', 'spielzeug', 'lernen', null, null, array['miniboss:spielzeug','preis:unter50','preis:unter100'], '100 Experimente klingen nach viel — und das sind sie. Für Kinder die Fragen stellen und Antworten selbst herausfinden wollen ist das besser als jeder Bildschirm.'),
  ('9dd61391-478e-411a-b7c2-97963207a6e4', '6afb7f96-51ac-4d1a-8f60-66142f742789', 'mangoschneider-fruchthalter', 'Mangoschneider Fruchthalter', 'Mango schneiden ohne Drama', 'Mango-Schneider aus Edelstahl mit Fruchthalter-Griff. Kern raus, zwei Hälften in Sekunden, ohne Sauerei am Brett. Rutschfester Griff, spülmaschinenfest. Für alle, die Mango lieben, aber die Vorbereitung hassen — und für Menschen, die Obst häufiger essen würden, wenn es weniger fummelig wäre.', 1475, 'EUR', 'https://amzn.to/48oo3St', 'https://m.media-amazon.com/images/I/71TMNoUDynL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71TMNoUDynL._AC_SL1500_.jpg'], true, false, '2026-04-25T18:22:34.160392+00:00', '2026-07-04T00:00:00+00:00', 'queen', 'kueche', 'werkzeug', null, null, array['preis:unter20','preis:unter50','preis:unter100'], 'Mango schneiden ohne so ein Gerät ist eine klebrige Angelegenheit. Mit dem Schneider geht es in Sekunden und die Stücke sehen ordentlich aus. Für Mangofans kein Luxus sondern Pflicht.'),
  ('9ac9ce5c-4749-4836-9c26-3bcb64589d6b', null, 'seek-thermal-compact-usbc', 'Seek Thermal Compact USB-C', 'Dein Smartphone wird zur Wärmebildkamera', 'Steck es in den USB-C-Port – und plötzlich siehst du Wärme. Wärmeverluste in Wänden aufspüren, überhitzte Elektronik erkennen, Tiere in der Nacht beobachten oder einfach Menschen wie Predator aussehen lassen.

Die Seek Thermal Compact hat 206×156 Pixel Auflösung und funktioniert ohne App-Kauf direkt mit Android. Für alle, die einen echten Geek-Superhero-Moment wollen.', 28900, 'EUR', 'https://www.amazon.de/dp/B07RQ3J27Y?tag=geeklist-21&linkCode=ogi&th=1', 'https://m.media-amazon.com/images/I/71NC0C51nUL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/71NC0C51nUL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71m3nE2cnOL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71e3kM7+zXL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/61+Y-5sqDKL._AC_SL1500_.jpg','https://m.media-amazon.com/images/I/71lvwv3OIEL._AC_SL1500_.jpg'], true, false, '2026-06-10T20:29:13.882329+00:00', '2026-06-10T20:29:13.882329+00:00', 'babo', 'tech', 'gadget', null, null, array['tech','outdoor','geeklist'], null),
  ('73a0f763-bfab-424d-a9d3-6b1344e5045d', 'a35c1804-e8e8-4ef2-a4b4-2ef95a2d25c2', 'suboos-aufladbare-campinglaterne', 'Aufladbare Campinglaterne', 'Licht wenn man es braucht', 'Suboos aufladbare Camping-Laterne mit 4400 mAh Akku, USB-C-Ladeanschluss und integrierter Powerbank. Vier Helligkeitsstufen bis 200 Lumen, wasserdicht (IPX4), Karabinerhaken. Bis zu 200 Stunden Laufzeit im Sparmodus. Für Zelt, Terrasse, Stromausfall oder als Basis für Zusatzhelligkeit.', 2597, 'EUR', 'https://amzn.to/4cvV9Cf', 'https://m.media-amazon.com/images/I/616TtM4BHqL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/616TtM4BHqL._AC_SL1500_.jpg'], true, false, '2026-04-25T18:22:34.160392+00:00', '2026-07-04T00:00:00+00:00', 'babo', 'outdoor', 'survival', null, null, array['babo:outdoor','preis:unter50','preis:unter100'], 'Die aufladbare Camping-Laterne, die zwei Rollen spielt: Zelt-Licht und Powerbank fürs Handy. 200+ Stunden Laufzeit im Sparmodus. Das Ding, das immer im Kofferraum ist und nie wirklich weg kann.'),
  ('563f5ec8-cf7b-469d-baa7-6c1c9046b188', '95b7774b-63b8-4fc0-ad83-7af93630dca7', 'toureal-nachfuellbarer-parfuemzerstaeuber-reise', 'Nachfüllbarer Parfümzerstäuber', 'Lieblingsduft immer dabei', 'Dein Lieblingsduft verdient es, immer dabei zu sein – aber ehrlich, eine ganze 100-ml-Flasche in der Handtasche? Das ist dann doch etwas oversized. Hier kommt der Toureal Parfümzerstäuber ins Spiel: 5 ml pures Aroma-Glück, die du überall hin mitnehmen kannst, ohne dabei wie ein mobiles Parfümerie-Lager auszusehen.

Das Ding ist aus stabilem Aluminium gefertigt, sieht dabei noch gut aus und wiegt so wenig, dass du ihn wahrscheinlich vergisst, dass er überhaupt in deiner Tasche ist. Und das Beste? Nachfüllen ist absurd einfach: Düse abschrauben, befüllen, fertig. Keine komplizierte Technik, keine Fummelei, keine Frustration. Eine Hand reicht völlig.

Ob für die Arbeit, unterwegs, im Urlaub oder einfach zwischendurch – mit diesem kompakten Begleiter kannst du deinem Duft treu bleiben, ohne Kompromisse einzugehen. Praktisch, zuverlässig und so smart designt, dass du dich fragen wirst, wie du je ohne ihn leben konntest.', 999, 'EUR', 'https://amzn.to/4mNxCA2', 'https://m.media-amazon.com/images/I/51Th7tnHTpL._AC_SL1500_.jpg', array['https://m.media-amazon.com/images/I/51Th7tnHTpL._AC_SL1500_.jpg'], true, false, '2026-04-25T18:22:34.160392+00:00', '2026-07-04T00:00:00+00:00', 'queen', 'lifestyle', 'mode', null, null, array['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100'], 'Das kleine Ding, das entscheidet, ob dein Handgepäck cool riecht oder nach TSA. Nachfüllen aus jeder Flasche, keine Extra-Reisegröße mehr kaufen, keine 100-ml-Regel-Probleme. Simpel, macht Reisen um ein Detail besser.')
on conflict (slug) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  affiliate_url = excluded.affiliate_url,
  image_url = excluded.image_url,
  image_urls = excluded.image_urls,
  is_published = excluded.is_published,
  is_featured = excluded.is_featured,
  created_at = excluded.created_at,
  updated_at = excluded.updated_at,
  shop_persona = excluded.shop_persona,
  shop_main_category = excluded.shop_main_category,
  shop_sub_category = excluded.shop_sub_category,
  amazon_category = excluded.amazon_category,
  brand = excluded.brand,
  shop_tags = excluded.shop_tags,
  editorial_note = excluded.editorial_note;

-- ── LISTEN ──────────────────────────────────────────────────
-- product_slugs bleibt original: getListsForProduct fragt per contains() ab.
-- Slugs, die nicht mit geseedet sind, stören dabei nicht.
insert into public.lists (id, slug, title, intro, body, product_slugs, is_published, created_at) values
  ('c1413002-db48-441e-9bd1-8ac7712eb684', 'miniboss-starter-kit', 'Miniboss Starter Kit', 'Produkte für kleine Menschen mit großen Ansprüchen. Kein Spielzeug von der Stange — sondern Sachen die wirklich begeistern, fordern und Spaß machen. Für Kinder die schon wissen was sie wollen.', null, array['tonies-toniebox-2-bundle-bauernhof','nerf-elite-2-0-commander-rc-6','hot-wheels-ultimative-garage-3ft','lego-creator-3in1-retro-kamera-31147','osmo-genius-starter-set-ipad','hasbro-twister-klassik','lunchbox-mit-faechern-1300ml-kinder'], true, '2026-06-07T21:03:59.149903+00:00'),
  ('b42473cf-4313-4047-b79e-b861f3f531de', 'iphone-setup-2026', 'iPhone-Setup 2026', 'MagSafe hat das iPhone-Zubehör neu erfunden — aber nur wenn man die richtigen Teile kauft. Kein generisches Amazon-Zeug, keine Kompromisse. Dieses Setup macht das iPhone zum System.', null, array['anker-nano-powerbank-magsafe-5000mah','supcase-magsafe-wallet-iphone','nifbang-iphone-17-pro-max-huelle-magnetstaender','cbdywvr-2in1-ladekabel-mit-staender'], true, '2026-06-07T19:13:50.517972+00:00'),
  ('5ebe63a5-8b87-4949-9d83-585cf0ea5be8', 'geeklist', 'Geeklist', 'Für alle, die Technik nicht nur benutzen – sondern verstehen, aufmachen und besser machen wollen.', 'Kein Amazon-Bestseller-Einheitsbrei. Diese Liste ist für echte Geeks: Tools die Türen öffnen, Gadgets die zum Tüfteln einladen und Gear das Legenden-Status hat.

Jedes Produkt hier hat eine Geschichte – und du wirst sie jedem erzählen wollen der es sieht.', array['flipper-zero','hoverair-x1-pro-drohne','anbernic-rg35xx-h','hhkb-professional-hybrid','ragnok-ergostrike7-gaming-maus','arc-reaktor-mk1-schwebend','divoom-pixoo-led-panel','sculpfun-s9-laser-engraver','seek-thermal-compact-usbc','phonesoap-3-uv-desinfektion','pinecil-usbc-loetkolben'], true, '2026-06-10T20:29:13.882329+00:00'),
  ('73be7b51-193b-4609-82d0-c469b770e96c', 'camping-gadgets-sommer', 'Camping Gadgets Sommer 2026', 'Das Gear, das aus einem normalen Camping-Trip ein echtes Abenteuer macht. Handverlesen für alle, die den Sommer draußen verbringen wollen — mit direktem Amazon-Link.', 'Camping ist 2026 nicht mehr Schlafsack und Dosenessen. Die richtige Ausrüstung macht den Unterschied zwischen einem frustrierenden Wochenende und einem Trip, über den man noch Jahre später redet.

Diese Liste zeigt das beste Outdoor-Gear das gerade auf Amazon erhältlich ist — vom Wurfzelt das in 2 Sekunden steht, über das faltbare Solarpanel für netzunabhängige Energie, bis zur selbstfliegenden Drohne die deinen Camping-Moment in 4K festhält.

Jedes Produkt hier wurde danach ausgewählt ob es den Trip wirklich verbessert — kein überflüssiges Zubehör, kein Plastik das nach einem Sommer aufgibt.', array['wurfzelt-3-4-personen-2-sekunden-aufbau','tipi-zelt-4-6-personen-mit-stehoehe','suboos-aufladbare-campinglaterne','sportneer-ultraleichter-campingstuhl','einhell-solarpanel-40w-faltbar-camping','wasserdichte-dry-bag-5l-30l','azengear-paracord-survival-armband-set','tre-feuerstahl-xxl','joto-wasserdichte-handyhuelle-unterwasser','ultraleichter-faltbarer-rucksack-20l','ollny-camping-lichterkette-10m','hoverair-x1-pro-drohne','tosy-flying-disc-108-rgb-leds-leuchtfrisbee','elektrische-wasserpistole-mit-led','bite-away-two-elektronischer-insektenstichheiler','vonmaehlen-evergreen-go-powerbank'], true, '2026-06-14T12:20:33.419776+00:00'),
  ('da372e43-80e1-4ac8-8436-f382e8e7b7cd', 'verrueckte-amazon-gadgets', 'Verrückte Amazon Gadgets', 'Keine Fakes, keine Photoshops. Diese Gadgets gibt es wirklich auf Amazon — und sie sind noch verrückter als sie aussehen.', 'Amazon hat Millionen Produkte. Die meisten davon sind langweilig. Aber wenn man weiß wo man sucht, findet man Dinge die man kaum glauben kann — ein Flipper Zero der Funksignale analysiert, eine Wärmebildkamera für den Smartphone-Port, ein Arc Reaktor der wirklich schwebt.

Diese Liste ist das Ergebnis dieser Suche. 16 Gadgets, jedes mit einem echten Wow-Faktor — entweder technisch beeindruckend, wissenschaftlich faszinierend oder einfach so absurd nützlich dass man sofort kaufen will.

Jedes Produkt ist direkt auf Amazon.de verfügbar. Kein Aliexpress, kein monatelanger Versand.', array['flipper-zero','seek-thermal-compact-usbc','arc-reaktor-mk1-schwebend','plasmakugel-8-zoll-beruehlungsempfindlich','ameisenfarm-acryl-set-natursand','periodensystem-mit-echten-elementen-acryl','hoverair-x1-pro-drohne','prisma-brille-lazy-glasses','bite-away-two-elektronischer-insektenstichheiler','bitzee-disney-interaktives-digital-haustier','schachroboter-mit-ki-roboterarm-sense-robot','drehbare-kosmos-sternkarte-planeten','led-leuchtbrille-aufladbar-party','shashibo-formwechsel-box-magnetisch','phonesoap-3-uv-desinfektion','dji-osmo-pocket-4-kreativ-combo'], true, '2026-06-14T12:20:33.419776+00:00'),
  ('0c4ed275-25e8-4c54-a9ab-7888c73d12e1', 'amazon-fundstuecke', 'Amazon Fundstücke', 'Nicht viral, nicht in jeder Empfehlungsliste — aber genau deshalb hier. Das sind die Amazon-Produkte, die du selbst nie gefunden hättest.', 'Es gibt Produkte auf Amazon, die seit Jahren existieren — und fast niemand kennt sie. Keine Bestseller, keine Influencer-Deals, kein gesponserte Werbung. Einfach gute Produkte, die auf Seite 8 der Suchergebnisse verschwinden.

Diese Liste ist ein Gegengewicht zu den üblichen "Top 10"-Listen. Hier findest du ein Notizbuch das auch im Regen funktioniert, eine Leselampe die du um den Hals trägst, ein Ladekabel das gleichzeitig als Ständer dient — kleine Dinge, die den Alltag auf eine Art verbessern, die man vorher nicht vermisst hat.

Alle Produkte direkt auf Amazon.de. Kein Tracking, kein Account nötig.', array['bug-beam-insektenfalle-uv-licht','welpen-usb-ladekabel-hunde-design','cbdywvr-2in1-ladekabel-mit-staender','glocusent-leselampe-hals','nfc-qr-aufsteller-instagram-schild','couchbar-snackbox-bambus','ticktime-tk3-wuerfel-timer-countdown','spiral-tastaturkabel-custom-coiled-usb-c','rite-in-the-rain-allwetter-notizbuch-field','powerball-gyro-handtrainer-original','handventilator-akku-aufladbar-mini','porseme-ultraschall-luftbefeuchter-farbwechsel','fusselroller-tierhaare-540-blatt-tragbar','prisma-brille-lazy-glasses','kabeltasche-edc-elektronik-organizer-reise','tosy-flying-disc-108-rgb-leds-leuchtfrisbee'], true, '2026-06-14T12:20:33.419776+00:00'),
  ('c4f1e1a9-1424-4481-beaf-167920c08554', 'schreibtisch-setup-gadgets', 'Schreibtisch Setup Gadgets', 'Der Schreibtisch ist das neue Wohnzimmer. Diese Gadgets machen ihn produktiver, effizienter — und ehrlich gesagt viel cooler.', 'Remote Work ist keine Phase. Wer 8 Stunden am Tag am Schreibtisch verbringt, sollte diesen Schreibtisch ernst nehmen — mit Equipment das wirklich funktioniert statt aussieht als ob.

Vom Stehpult-Aufsatz der den Rücken rettet, über das HHKB Professional Hybrid das nach zehn Jahren noch das beste Tipp-Erlebnis liefert, bis zur programmierbaren LED-Laufschrift-Tafel die Meetings revolutioniert: Diese Liste zeigt was ein echter Schreibtisch-Setup in 2026 kann.

Jedes Produkt wurde danach ausgewählt ob es echten Nutzwert im Alltag bringt — kein Deko-Setup, keine "guter Look für YouTube"-Auswahl. Direkter Amazon-Link bei jedem Produkt.', array['dicmky-hoehenverstellbarer-schreibtisch-aufsatz','vivo-hoehenverstellbares-stehpult','tecknet-ergonomische-kabellose-maus-bluetooth','jdvootd-programmierbare-led-laufschrift-tafel','protoarc-xk01-bluetooth-klappbare-tastatur','joyroom-kabelmanagement-schreibtisch-selbstklebend','mfi-zertifiziert-magsafe-wireless-ladestation-15w','ticktime-tk3-wuerfel-timer-countdown','spiral-tastaturkabel-custom-coiled-usb-c','rocketbook-wiederverwendbares-notizbuch-a4','nfc-qr-aufsteller-instagram-schild','laptop-staender-hoehenverstellbar-360-drehbar','leselampe-buch-klemme-augenschonend','hhkb-professional-hybrid','divoom-pixoo-led-panel','oikkei-ki-maus','kabeltasche-edc-elektronik-organizer-reise'], true, '2026-06-14T12:20:33.419776+00:00')
on conflict (slug) do update set
  title = excluded.title,
  intro = excluded.intro,
  body = excluded.body,
  product_slugs = excluded.product_slugs,
  is_published = excluded.is_published;

commit;

-- ============================================================
-- VERIFIKATION (read-only, nach dem Seed ausführen)
-- ============================================================
-- (a) Zählstand. Erwartet: 20 Produkte, 4 Kategorien, 7 Listen.
-- select
--   (select count(*) from public.products)   as produkte,
--   (select count(*) from public.categories) as kategorien,
--   (select count(*) from public.lists)      as listen;
--
-- (b) Alle 10 Pilot-Slugs vorhanden und veröffentlicht? Erwartet: 10 Zeilen.
-- select slug, is_published, shop_persona, shop_main_category
-- from public.products
-- where slug in (
--   'pinecil-usbc-loetkolben',
--   'divoom-pixoo-led-panel',
--   'sculpfun-s9-laser-engraver',
--   'arc-reaktor-mk1-schwebend',
--   'elektrische-wasserpistole-mit-led',
--   'hot-wheels-ultimative-garage-3ft',
--   'lego-creator-3in1-retro-kamera-31147',
--   'ninja-staysharp-messerset-6-teilig',
--   'n4-nussmilchbereiter-pflanzenmilch',
--   'welpen-usb-ladekabel-hunde-design'
-- ) order by slug;
--
-- (c) Alle 5 Referenzziele vorhanden und veröffentlicht? Erwartet: 5 Zeilen.
-- select slug, is_published from public.products
-- where slug in (
--   'ifixit-antistatik-matte-faltbar-esd',
--   'divoom-minitoo-retro-pc-lautsprecher-pixel',
--   'derayee-schaumstoff-wasserpistole',
--   'aeropress-go-tragbare-kaffeemaschine',
--   'cbdywvr-2in1-ladekabel-mit-staender'
-- ) order by slug;
--
-- (d) Kategorie-Referenzen intakt? Erwartet: 0 Zeilen.
-- select p.slug from public.products p
-- left join public.categories c on c.id = p.category_id
-- where p.category_id is not null and c.id is null;
--
-- (e) Value-Add noch leer (kommt erst per Backfill)? Erwartet: 0 Zeilen.
-- select slug from public.products
-- where fuer_wen is not null or pros is not null or alternative_slug is not null;
