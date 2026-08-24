-- ============================================================================
-- FIXTURE 02 — Realistischer Production-aehnlicher Datenbestand
-- ============================================================================
-- Zielbild ist exakt der Zustand, den 01_preflight_read_only.sql am 2026-08-23
-- auf project/ydiihvzcxaaoqhmgoqvu gemeldet hat:
--
--   produkte                        376   (>= 300)
--   zielprodukte                    10/10 published
--   relationsziele                  5/5   published
--   bestehende_editorial_notes      3     (n4, ninja, welpen)
--   value_add_bereits_befuellt      0
--   divoom-pixoo-led-panel          price_cents IS NULL
--
-- Alle Texte hier sind Testdaten. Sie stammen nicht aus Production und werden
-- nie dorthin geschrieben — der Harness laeuft ausschliesslich lokal.
-- updated_at wird bewusst gestreut, damit 06_restore_value_add.sql beweisbar
-- zehn verschiedene historische Zeitstempel exakt zurueckspielen muss.
-- ============================================================================

insert into public.categories (slug, name, description, emoji, sort_order) values
  ('lustige-gadgets',    'Lustige Gadgets',      'Kuriose Produkte',      '😂', 1),
  ('geschenke-maenner',  'Geschenke für Männer', 'Ideen für Männer',      '🎁', 2),
  ('buero-gadgets',      'Büro-Gadgets',         'Helfer am Schreibtisch','💼', 3),
  ('kuechen-gadgets',    'Küchen-Gadgets',       'Küchenhelfer',          '🍳', 4),
  ('geschenke-unter-20', 'Geschenke unter 20 €', 'Kleines Budget',        '💶', 5);

-- ----------------------------------------------------------------------------
-- 1) Die zehn Zielprodukte des Backfills — alle published.
--    ninja / n4 / welpen tragen bereits eine editorial_note. Genau diese drei
--    Texte werden von 04 bewusst ueberschrieben und muessen von 06 wieder
--    exakt erscheinen.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, brand, editorial_note,
  created_at, updated_at
) values
('pinecil-usbc-loetkolben', 'Pinecil USB-C Lötkolben',
 'Löten, wo du gerade bist.',
 'Kompakter USB-C-Lötkolben mit offener Firmware.',
 5990, 'https://example.invalid/aff/pinecil', '/img/pinecil.jpg',
 true, 'babo', 'tools', 'Pine64', null,
 '2026-01-10 09:00:00+00', '2026-03-01 11:15:00+00'),

('divoom-pixoo-led-panel', 'Divoom Pixoo LED-Panel',
 'Pixel-Art für den Schreibtisch.',
 '16x16-LED-Panel, per App konfigurierbar.',
 null, 'https://example.invalid/aff/pixoo', '/img/pixoo.jpg',
 true, 'babo', 'tech', 'Divoom', null,
 '2026-01-11 09:00:00+00', '2026-03-02 12:20:00+00'),

('sculpfun-s9-laser-engraver', 'Sculpfun S9 Lasergravierer',
 'Gravieren ohne Werkstattbudget.',
 'Graviert Holz, Acryl und Leder.',
 24900, 'https://example.invalid/aff/sculpfun', '/img/sculpfun.jpg',
 true, 'babo', 'tools', 'Sculpfun', null,
 '2026-01-12 09:00:00+00', '2026-03-03 13:25:00+00'),

('arc-reaktor-mk1-schwebend', 'Arc Reaktor MK1 schwebend',
 'Schwebt, dreht sich, leuchtet.',
 'Magnetisch schwebende Replika mit LED.',
 8990, 'https://example.invalid/aff/arc', '/img/arc.jpg',
 true, 'babo', 'deko', null, null,
 '2026-01-13 09:00:00+00', '2026-03-04 14:30:00+00'),

('elektrische-wasserpistole-mit-led', 'Elektrische Wasserpistole mit LED',
 'Kein Pumpen mehr.',
 'Selbstansaugend, elektrischer Abzug, LED.',
 3490, 'https://example.invalid/aff/wapi', '/img/wapi.jpg',
 true, 'babo', 'outdoor', null, null,
 '2026-01-14 09:00:00+00', '2026-03-05 15:35:00+00'),

('hot-wheels-ultimative-garage-3ft', 'Hot Wheels Ultimative Garage',
 'Drei Etagen für die Autosammlung.',
 'Rund 1 m hoch, mit Aufzug und Waschanlage.',
 19900, 'https://example.invalid/aff/hotwheels', '/img/hotwheels.jpg',
 true, 'miniboss', 'spielzeug', 'Hot Wheels', null,
 '2026-01-15 09:00:00+00', '2026-03-06 16:40:00+00'),

('lego-creator-3in1-retro-kamera-31147', 'LEGO Creator 3in1 Retro-Kamera 31147',
 'Einmal kaufen, dreimal bauen.',
 '261 Teile, drei Baumodelle, ab 8 Jahren.',
 1999, 'https://example.invalid/aff/lego31147', '/img/lego31147.jpg',
 true, 'miniboss', 'spielzeug', 'LEGO', null,
 '2026-01-16 09:00:00+00', '2026-03-07 17:45:00+00'),

('ninja-staysharp-messerset-6-teilig', 'Ninja StaySharp Messerset 6-teilig',
 'Schärft sich beim Reinstecken selbst.',
 '6-teiliges Set mit Schärf-Slots im Block.',
 17900, 'https://example.invalid/aff/ninja', '/img/ninja.jpg',
 true, 'queen', 'kueche', 'Ninja',
 'ALT-NOTE ninja: Messer, die sich im Block selbst schärfen. Klingt nach Gimmick, ist im Alltag aber genau die Sorte Bequemlichkeit, die man nicht mehr hergibt.',
 '2026-01-17 09:00:00+00', '2026-07-04 18:50:00+00'),

('n4-nussmilchbereiter-pflanzenmilch', 'N4 Nussmilchbereiter',
 'Pflanzenmilch in 20 Minuten.',
 'Der Bereiter mixt, kocht und filtert in rund 30 Minuten vollautomatisch.',
 12900, 'https://example.invalid/aff/n4', '/img/n4.jpg',
 true, 'queen', 'kueche', null,
 'ALT-NOTE n4: Frische Hafermilch auf Knopfdruck, Selbstreinigung inklusive. Lohnt sich nur, wenn wirklich täglich getrunken wird.',
 '2026-01-18 09:00:00+00', '2026-07-04 19:55:00+00'),

('welpen-usb-ladekabel-hunde-design', 'Welpen USB-Ladekabel im Hunde-Design',
 'Das langweiligste Alltagsteil, endlich niedlich.',
 '1,5-m-Kabel mit verstärktem Anschluss.',
 1290, 'https://example.invalid/aff/welpen', '/img/welpen.jpg',
 true, 'queen', 'lifestyle', null,
 'ALT-NOTE welpen: Ein Ladekabel mit Hundemotiv und Zugentlastung. Kein Technikwunder, aber ein Alltagsgegenstand mit Charakter.',
 '2026-01-19 09:00:00+00', '2026-07-04 20:00:00+00');

-- ----------------------------------------------------------------------------
-- 2) Die fuenf Relationsziele — alle published, sonst brechen alle Guards ab.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, created_at, updated_at
) values
('ifixit-antistatik-matte-faltbar-esd', 'iFixit Antistatik-Matte faltbar',
 'ESD-Schutz für den Basteltisch.', 'Faltbare ESD-Matte.',
 6990, 'https://example.invalid/aff/ifixit', '/img/ifixit.jpg',
 true, 'babo', 'tools', '2026-02-01 09:00:00+00', '2026-02-01 09:00:00+00'),
('divoom-minitoo-retro-pc-lautsprecher-pixel', 'Divoom Ditoo Mini Retro-Lautsprecher',
 'Pixel-Display mit Sound.', 'Retro-Lautsprecher mit Pixel-Anzeige.',
 8990, 'https://example.invalid/aff/ditoo', '/img/ditoo.jpg',
 true, 'babo', 'tech', '2026-02-02 09:00:00+00', '2026-02-02 09:00:00+00'),
('derayee-schaumstoff-wasserpistole', 'Derayee Schaumstoff-Wasserpistole',
 'Leicht, günstig, nass.', 'Klassische Pumppistole aus Schaumstoff.',
 1490, 'https://example.invalid/aff/derayee', '/img/derayee.jpg',
 true, 'miniboss', 'outdoor', '2026-02-03 09:00:00+00', '2026-02-03 09:00:00+00'),
('aeropress-go-tragbare-kaffeemaschine', 'AeroPress Go',
 'Kaffee, der mitreist.', 'Tragbare Kaffeepresse.',
 3990, 'https://example.invalid/aff/aeropress', '/img/aeropress.jpg',
 true, 'queen', 'kueche', '2026-02-04 09:00:00+00', '2026-02-04 09:00:00+00'),
('cbdywvr-2in1-ladekabel-mit-staender', 'CBDYWVR 2-in-1 Ladekabel mit Ständer',
 'Laden und aufstellen in einem.', 'Ladekabel mit integriertem Ständer.',
 1590, 'https://example.invalid/aff/cbdywvr', '/img/cbdywvr.jpg',
 true, 'queen', 'lifestyle', '2026-02-05 09:00:00+00', '2026-02-05 09:00:00+00');

-- ----------------------------------------------------------------------------
-- 3) 361 weitere Produkte -> insgesamt 376, wie auf Production gezaehlt.
--    Rund ein Drittel unveroeffentlicht und gut die Haelfte mit editorial_note,
--    damit die Guards nicht versehentlich auf einem homogenen Bestand laufen.
--    Diese Notizen liegen ausserhalb der Zielmenge und duerfen von 04 nicht
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
  (g % 3) <> 0,
  (g % 29) = 0,
  (array['babo', 'queen', 'miniboss'])[1 + (g % 3)],
  (array['tech', 'kueche', 'lifestyle', 'outdoor', 'spielzeug',
         'haushalt', 'tools', 'deko'])[1 + (g % 8)],
  array[(array['babo', 'queen', 'miniboss'])[1 + (g % 3)] || ':' ||
        (array['tech', 'kueche', 'lifestyle', 'outdoor', 'spielzeug',
               'haushalt', 'tools', 'deko'])[1 + (g % 8)]],
  case when g % 5 = 0 then 'Testmarke ' || (g % 11) else null end,
  case when g % 2 = 0
       then 'ALT-NOTE fuell-' || g || ': bestehende Notiz ausserhalb der Zielmenge.'
       else null end,
  (select id from public.categories where slug = 'lustige-gadgets'),
  timestamptz '2025-09-01 08:00:00+00' + (g || ' hours')::interval,
  timestamptz '2026-04-01 08:00:00+00' + (g || ' minutes')::interval
from generate_series(1, 361) as g;

-- ----------------------------------------------------------------------------
-- 4) Listen / Nebendaten, damit die DB nicht kuenstlich leer wirkt.
-- ----------------------------------------------------------------------------
insert into public.lists (slug, title, intro, product_slugs, is_published) values
('geschenke-fuer-echte-gamer', 'Geschenke für echte Gamer', 'Testintro.',
 array['divoom-pixoo-led-panel', 'arc-reaktor-mk1-schwebend'], true),
('fuer-den-naechsten-airbnb-aufenthalt', 'Für den nächsten Airbnb-Aufenthalt',
 'Testintro.', array['aeropress-go-tragbare-kaffeemaschine'], true);

insert into public.page_content (page_key, title, intro) values
  ('category:lustige-gadgets', 'Lustige Gadgets', 'Testintro.'),
  ('guide:bestes-buero-gadget', 'Bestes Büro-Gadget', 'Testintro.');

insert into public.discovery_queue (name, source_url, status) values
  ('Testkandidat A', 'https://example.invalid/a', 'pending'),
  ('Testkandidat B', 'https://example.invalid/b', 'approved');

insert into public.swipes (product_slug, direction, session_id) values
  ('pinecil-usbc-loetkolben', 'like', 'test-session-1'),
  ('divoom-pixoo-led-panel', 'skip', 'test-session-1');
