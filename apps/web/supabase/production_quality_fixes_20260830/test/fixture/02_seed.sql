-- ============================================================================
-- FIXTURE 02 — Production-aehnlicher Datenbestand, Stand VOR der Korrektur
-- ============================================================================
-- Zielbild ist der Production-Vorzustand, den Codex am 2026-08-30 read-only
-- verifiziert hat:
--
--   sechs Zielprodukte     alle published, alle im belegten Vorzustand
--   drei Ziellisten        exakt die belegten product_slugs-Arrays
--   zwei A4-Zielprodukte   plasmakugel-...-beruehrungsempfindlich und
--                          bug-a-salt-3-0-fliegenjaeger-salzgewehr, je genau
--                          einmal und published
--   Produkte gesamt        >= 300 (Fingerprint jedes Guards)
--
-- Alle Fuelltexte hier sind Testdaten. Sie stammen nicht aus Production und
-- werden nie dorthin geschrieben — der Harness laeuft ausschliesslich lokal
-- gegen einen eigenen Cluster ohne TCP-Port.
--
-- ECHT sind ausschliesslich die Werte, auf die die Guards prueten: die
-- Vorzustandsfelder der sechs Zielprodukte, die drei Listen-Arrays und die
-- Slugs. Sie stammen aus dem Repo (import_products_batch2.sql,
-- import_lists_batch1.sql, update_list_add_gamer_products.sql,
-- add_shop_fields.sql) und aus dem Codex-Preflight.
--
-- JEDE der sechs Zielzeilen traegt ein EIGENES historisches updated_at. Damit
-- muss 06 beweisbar sechs verschiedene Zeitstempel exakt zurueckspielen und
-- kann sich nicht auf einen Einheitswert stuetzen.
-- ============================================================================

insert into public.categories (slug, name, description, emoji, sort_order) values
  ('lustige-gadgets',    'Lustige Gadgets',      'Kuriose Produkte',       '1', 1),
  ('geschenke-maenner',  'Geschenke für Männer', 'Ideen für Männer',       '2', 2),
  ('geschenke-unter-20', 'Geschenke unter 20 €', 'Kleines Budget',         '3', 3),
  ('tech-gadgets',       'Tech-Gadgets',         'Technik zum Anfassen',   '4', 4);

-- ----------------------------------------------------------------------------
-- 1) B2 — drei Produkte auf den Spaltendefaults, nur Preis-Tags
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  image_urls, is_published, shop_persona, shop_main_category, shop_sub_category,
  shop_tags, brand, editorial_note, created_at, updated_at
) values
('fingerabdruck-vorhaengeschloss-eseesmart',
 'Fingerabdruck Vorhängeschloss Eseesmart',
 'Schloss auf, ohne Schlüssel zu suchen',
 'Biometrisches Vorhängeschloss mit Fingerabdrucksensor. Fixture-Testtext.',
 3899, 'https://amzn.to/fixture-eseesmart',
 'https://m.media-amazon.com/images/I/61hRfgFAKfL._AC_SL1500_.jpg',
 array['https://m.media-amazon.com/images/I/61hRfgFAKfL._AC_SL1500_.jpg'],
 true, 'unknown', 'sonstiges', 'ungeordnet',
 array['preis:unter50','preis:unter100'],
 'Eseesmart', 'Fixture-Redaktionsnotiz Eseesmart.',
 timestamptz '2026-04-20 08:00:00+00', timestamptz '2026-07-04 00:00:00+00'),

('flauschige-handschuhe-weihnachten',
 'Flauschige Handschuhe Weihnachten',
 'Handschuhe die umarmen',
 'Extra flauschige Handschuhe im Weihnachtsdesign. Fixture-Testtext.',
 2999, 'https://amzn.to/fixture-handschuhe',
 'https://m.media-amazon.com/images/I/61dkX-G-OGL._AC_SL1500_.jpg',
 array['https://m.media-amazon.com/images/I/61dkX-G-OGL._AC_SL1500_.jpg'],
 true, 'unknown', 'sonstiges', 'ungeordnet',
 array['preis:unter50','preis:unter100'],
 null, 'Fixture-Redaktionsnotiz Handschuhe.',
 timestamptz '2026-04-21 08:00:00+00', timestamptz '2026-07-05 00:00:00+00'),

('pizza-socks-box-pepperoni',
 'Pizza Socks Box Pepperoni',
 'Socken die nach Pizza schmecken könnten',
 'Lustige Pizza-Socken in einer Pizzakarton-Box. Fixture-Testtext.',
 1998, 'https://amzn.to/fixture-pizzasocks',
 'https://m.media-amazon.com/images/I/71R6ZbqWO1L._AC_SL1500_.jpg',
 array['https://m.media-amazon.com/images/I/71R6ZbqWO1L._AC_SL1500_.jpg'],
 true, 'unknown', 'sonstiges', 'ungeordnet',
 array['preis:unter20','preis:unter50','preis:unter100'],
 null, 'Fixture-Redaktionsnotiz Pizza Socks.',
 timestamptz '2026-04-22 08:00:00+00', timestamptz '2026-07-06 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 2) B5a — Preis fehlt vollstaendig (price_cents IS NULL)
--    Affiliate-Link und Amazon-Bilder existieren und bleiben unveraendert.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  image_urls, is_published, shop_persona, shop_main_category, shop_sub_category,
  shop_tags, brand, editorial_note, created_at, updated_at
) values
('divoom-pixoo-led-panel',
 'Divoom Pixoo LED-Panel',
 'Pixel-Art-Display für den Schreibtisch',
 '16x16 Pixel, konfigurierbar per App. Fixture-Testtext.',
 null, 'https://www.amazon.de/dp/B07HHXWN3C?tag=geeklist-21',
 'https://m.media-amazon.com/images/I/61fixturePixooL._AC_SL1500_.jpg',
 array['https://m.media-amazon.com/images/I/61fixturePixooL._AC_SL1500_.jpg'],
 true, 'babo', 'tech', 'gadgets',
 array['babo:tech','preis:unter50','preis:unter100'],
 'Divoom', 'Fixture-Redaktionsnotiz Pixoo.',
 timestamptz '2026-04-23 08:00:00+00', timestamptz '2026-07-07 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 3) B5b — ein einzelnes Nicht-Amazon-Bild in image_url UND image_urls
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  image_urls, is_published, shop_persona, shop_main_category, shop_sub_category,
  shop_tags, brand, editorial_note, created_at, updated_at
) values
('divoom-minitoo-retro-pc-lautsprecher-pixel',
 'Divoom MiniToo Retro PC-Lautsprecher',
 'Sieht aus wie ein Rechner von 1985. Klingt wie 2026.',
 'Bluetooth-Lautsprecher im Retro-PC-Design mit Pixel-Display. Fixture-Testtext.',
 8999, 'https://www.amazon.de/dp/B0FRF3XGQ4?tag=geeklist-21',
 'https://divoom.com/cdn/shop/files/minitoo-1.jpg',
 array['https://divoom.com/cdn/shop/files/minitoo-1.jpg'],
 true, 'babo', 'tech', 'gadgets',
 array['babo:tech','preis:unter100','preis:unter200'],
 'Divoom', 'Fixture-Redaktionsnotiz MiniToo.',
 timestamptz '2026-04-24 08:00:00+00', timestamptz '2026-07-08 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 4) D6 — "Cream Noise Machine" in name, description und editorial_note.
--    Diese drei Texte sind die ECHTEN Production-Vorwerte.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  image_urls, is_published, shop_persona, shop_main_category, shop_sub_category,
  shop_tags, brand, editorial_note, created_at, updated_at
) values
('cream-noise-machine-baby-tragbar',
 'Cream Noise Machine Baby Tragbar',
 'Tiefschlaf für dein Baby.',
 'Tragbare Cream Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.',
 3099, 'https://www.amazon.de/dp/B0D4PMN2MD?tag=geeklist-21',
 'https://m.media-amazon.com/images/I/41G+hNn7oXL._AC_.jpg',
 array['https://m.media-amazon.com/images/I/61FOkqiX9XL._AC_SL1500_.jpg'],
 true, 'miniboss', 'spass', 'nachtlicht',
 array['miniboss:spass','preis:unter50','preis:unter100'],
 null,
 'Die tragbare Cream-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.',
 timestamptz '2026-04-25 08:00:00+00', timestamptz '2026-07-09 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 5) Die beiden A4-Zielprodukte. Auf sie zeigen die korrigierten
--    Listeneintraege. Beide muessen genau einmal existieren und published sein
--    — 01, 04 und 05 pruefen das hart.
--    Die fehlerhaften Slugs (...beruehlungs..., ...fliegenjager...) gibt es
--    bewusst NICHT: genau deshalb sind die Listeneintraege tot.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, shop_sub_category,
  created_at, updated_at
) values
('plasmakugel-8-zoll-beruehrungsempfindlich',
 'Plasmakugel 8 Zoll Berührungsempfindlich',
 'Blitze in deiner Hand.',
 'Magische 8-Zoll-Plasmakugel. Fixture-Testtext.',
 3799, 'https://www.amazon.de/dp/B081HXZCRL?tag=geeklist-21',
 'https://m.media-amazon.com/images/I/41yolsOXR+L._AC_.jpg',
 true, 'babo', 'diy', 'basteln',
 timestamptz '2026-04-10 08:00:00+00', timestamptz '2026-07-04 00:00:00+00'),

('bug-a-salt-3-0-fliegenjaeger-salzgewehr',
 'Bug-A-Salt 3.0 Fliegenjäger Salzgewehr',
 'Fliegen jagen war nie so lustig.',
 'Das Original Salzgewehr gegen Fliegen. Fixture-Testtext.',
 5573, 'https://www.amazon.de/dp/B089CDCCR1?tag=geeklist-21',
 'https://m.media-amazon.com/images/I/31S68XoTJoL._AC_.jpg',
 true, 'babo', 'lifestyle', 'gadgets',
 timestamptz '2026-04-11 08:00:00+00', timestamptz '2026-07-04 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 6) Fuellzeilen bis ueber die 300er-Grenze des Fingerprints.
--    Sie sind gleichzeitig die Nichtzielmenge, deren Unveraendertheit 04 und 06
--    ueber md5(to_jsonb(zeile)) messen.
-- ----------------------------------------------------------------------------
insert into public.products (
  slug, name, tagline, description, price_cents, affiliate_url, image_url,
  is_published, shop_persona, shop_main_category, shop_sub_category, shop_tags,
  editorial_note, created_at, updated_at
)
select
  'fixture-fuellprodukt-' || lpad(g::text, 3, '0'),
  'Fixture Fuellprodukt ' || g,
  'Fixture-Tagline ' || g,
  'Fixture-Beschreibung ' || g,
  1000 + g,
  'https://amzn.to/fixture-' || g,
  'https://m.media-amazon.com/images/I/fixture' || g || '._AC_.jpg',
  true,
  case when g % 3 = 0 then 'babo' when g % 3 = 1 then 'queen' else 'miniboss' end,
  'lifestyle', 'gadgets',
  array['preis:unter50','preis:unter100'],
  'Fixture-Redaktionsnotiz ' || g,
  timestamptz '2026-03-01 08:00:00+00' + (g || ' minutes')::interval,
  timestamptz '2026-06-01 08:00:00+00' + (g || ' minutes')::interval
from generate_series(1, 320) as g;

-- ----------------------------------------------------------------------------
-- 7) Die drei Ziellisten im belegten Vorzustand.
--    A4: je ein Eintrag mit Schreibfehler (Position 4 bzw. 2).
--    A5: 16 Eintraege, die letzten drei sind Wiederholungen von 11 bis 13.
-- ----------------------------------------------------------------------------
insert into public.lists (slug, title, intro, body, product_slugs, is_published)
values
('verrueckte-amazon-gadgets',
 'Verrückte Amazon Gadgets',
 'Fixture-Intro.',
 'Fixture-Body.',
 array[
   'flipper-zero',
   'seek-thermal-compact-usbc',
   'arc-reaktor-mk1-schwebend',
   'plasmakugel-8-zoll-beruehlungsempfindlich',
   'ameisenfarm-acryl-set-natursand',
   'periodensystem-mit-echten-elementen-acryl',
   'hoverair-x1-pro-drohne',
   'prisma-brille-lazy-glasses',
   'bite-away-two-elektronischer-insektenstichheiler',
   'bitzee-disney-interaktives-digital-haustier',
   'schachroboter-mit-ki-roboterarm-sense-robot',
   'drehbare-kosmos-sternkarte-planeten',
   'led-leuchtbrille-aufladbar-party',
   'shashibo-formwechsel-box-magnetisch',
   'phonesoap-3-uv-desinfektion',
   'dji-osmo-pocket-4-kreativ-combo'
 ],
 true),

('witzige-geschenke-maenner',
 'Witzige Geschenke für Männer',
 'Fixture-Intro.',
 'Fixture-Body.',
 array[
   'faelnk-toilettengolf-set',
   'bug-a-salt-3-0-fliegenjager-salzgewehr',
   'toilettenbuerste-gag-geschenk-set-lustig',
   'kiayoo-wackelfigur-armaturenbrett-auto',
   'bbq-wuerstchenhalter-maennchen-3er-set',
   'brubaker-weinflaschenhalter-totenkopf',
   'snoop-dogg-kochbuch-from-crook-to-cook',
   'prisma-brille-lazy-glasses',
   'deadpool-auto-anhaenger-ornament',
   'stress-baelle-quetschball-set',
   'bierbrauset-pils-5-liter-fass',
   'bartesian-cocktailmaschine-mit-kapseln'
 ],
 true),

('geschenke-fuer-gamer',
 'Geschenke für echte Gamer',
 'Fixture-Intro.',
 'Fixture-Body.',
 array[
   'street-fighter-arcade-machine',
   'dnd-starter-set-helden-der-grenzlande-deutsch',
   'mayflash-f300-arcade-joystick',
   'nintendo-classic-mini-snes',
   'mad-monkey-retro-spielekonsole',
   'gan-356me-speed-cube-3x3-magnetisch',
   'krimispiel-escape-room-detektivspiel-erwachsene',
   'ps5-horizontale-tasche-tragetasche',
   'kytok-controller-staender-4-etagen',
   'shashibo-formwechsel-box-magnetisch',
   'weiminli-switch-skull-case',
   'giiker-super-slide-puzzle',
   'dealkit-3d-labyrinth-wuerfel',
   'weiminli-switch-skull-case',
   'giiker-super-slide-puzzle',
   'dealkit-3d-labyrinth-wuerfel'
 ],
 true);

-- ----------------------------------------------------------------------------
-- 8) Nichtziel-Listen. Ihre Unveraendertheit misst 04 und 06 ueber
--    md5(to_jsonb(zeile)). Die zweite enthaelt bewusst denselben fehlerhaften
--    Slug wie eine Zielliste: 04 darf ihn dort NICHT anfassen, weil sie keine
--    Zielzeile ist.
-- ----------------------------------------------------------------------------
insert into public.lists (slug, title, intro, body, product_slugs, is_published)
values
('camping-gadgets-sommer',
 'Camping Gadgets Sommer 2026',
 'Fixture-Intro.',
 'Fixture-Body.',
 array['hoverair-x1-pro-drohne', 'bite-away-two-elektronischer-insektenstichheiler'],
 true),

('fixture-fremdliste-mit-fehlerslug',
 'Fixture-Fremdliste',
 'Fixture-Intro.',
 'Fixture-Body.',
 array['plasmakugel-8-zoll-beruehlungsempfindlich', 'flipper-zero'],
 true);

-- ----------------------------------------------------------------------------
-- 9) Die uebrigen Fingerprint-Tabellen, damit sie nicht leer sind.
-- ----------------------------------------------------------------------------
insert into public.page_content (page_key, title, intro)
values ('startseite', 'Crazy Babo Bazar', 'Fixture-Intro.');

insert into public.discovery_queue (name, source_url, status)
values ('Fixture-Kandidat', 'https://example.invalid/fixture', 'pending');

insert into public.swipes (product_slug, direction, session_id)
values ('flipper-zero', 'like', 'fixture-session');
