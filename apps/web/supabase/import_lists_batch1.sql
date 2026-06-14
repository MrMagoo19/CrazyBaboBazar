-- =============================================================================
-- import_lists_batch1.sql
-- 6 kuratierte Listen — Sommer 2026
-- Erstellt: 2026-06-14
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Camping Gadgets Sommer 2026
-- Target: "Camping Gadgets", "Outdoor Gadgets Sommer", "Camping Zubehör"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'camping-gadgets-sommer',
  'Camping Gadgets Sommer 2026',
  E'Das Gear, das aus einem normalen Camping-Trip ein echtes Abenteuer macht. Handverlesen für alle, die den Sommer draußen verbringen wollen — mit direktem Amazon-Link.',
  E'Camping ist 2026 nicht mehr Schlafsack und Dosenessen. Die richtige Ausrüstung macht den Unterschied zwischen einem frustrierenden Wochenende und einem Trip, über den man noch Jahre später redet.\n\nDiese Liste zeigt das beste Outdoor-Gear das gerade auf Amazon erhältlich ist — vom Wurfzelt das in 2 Sekunden steht, über das faltbare Solarpanel für netzunabhängige Energie, bis zur selbstfliegenden Drohne die deinen Camping-Moment in 4K festhält.\n\nJedes Produkt hier wurde danach ausgewählt ob es den Trip wirklich verbessert — kein überflüssiges Zubehör, kein Plastik das nach einem Sommer aufgibt.',
  ARRAY[
    'wurfzelt-3-4-personen-2-sekunden-aufbau',
    'tipi-zelt-4-6-personen-mit-stehoehe',
    'suboos-aufladbare-campinglaterne',
    'sportneer-ultraleichter-campingstuhl',
    'einhell-solarpanel-40w-faltbar-camping',
    'wasserdichte-dry-bag-5l-30l',
    'azengear-paracord-survival-armband-set',
    'tre-feuerstahl-xxl',
    'joto-wasserdichte-handyhuelle-unterwasser',
    'ultraleichter-faltbarer-rucksack-20l',
    'ollny-camping-lichterkette-10m',
    'hoverair-x1-pro-drohne',
    'tosy-flying-disc-108-rgb-leds-leuchtfrisbee',
    'elektrische-wasserpistole-mit-led',
    'bite-away-two-elektronischer-insektenstichheiler',
    'vonmaehlen-evergreen-go-powerbank'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;

-- -----------------------------------------------------------------------------
-- 2. Verrückte Amazon Gadgets
-- Target: "Verrückte Amazon Gadgets", "Verrückte Gadgets kaufen"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'verrueckte-amazon-gadgets',
  'Verrückte Amazon Gadgets',
  E'Keine Fakes, keine Photoshops. Diese Gadgets gibt es wirklich auf Amazon — und sie sind noch verrückter als sie aussehen.',
  E'Amazon hat Millionen Produkte. Die meisten davon sind langweilig. Aber wenn man weiß wo man sucht, findet man Dinge die man kaum glauben kann — ein Flipper Zero der Funksignale analysiert, eine Wärmebildkamera für den Smartphone-Port, ein Arc Reaktor der wirklich schwebt.\n\nDiese Liste ist das Ergebnis dieser Suche. 16 Gadgets, jedes mit einem echten Wow-Faktor — entweder technisch beeindruckend, wissenschaftlich faszinierend oder einfach so absurd nützlich dass man sofort kaufen will.\n\nJedes Produkt ist direkt auf Amazon.de verfügbar. Kein Aliexpress, kein monatelanger Versand.',
  ARRAY[
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
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;

-- -----------------------------------------------------------------------------
-- 3. Amazon Fundstücke
-- Target: "Amazon Fundstücke", "Amazon Geheimtipps"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'amazon-fundstuecke',
  'Amazon Fundstücke',
  E'Nicht viral, nicht in jeder Empfehlungsliste — aber genau deshalb hier. Das sind die Amazon-Produkte, die du selbst nie gefunden hättest.',
  E'Es gibt Produkte auf Amazon, die seit Jahren existieren — und fast niemand kennt sie. Keine Bestseller, keine Influencer-Deals, kein gesponserte Werbung. Einfach gute Produkte, die auf Seite 8 der Suchergebnisse verschwinden.\n\nDiese Liste ist ein Gegengewicht zu den üblichen "Top 10"-Listen. Hier findest du ein Notizbuch das auch im Regen funktioniert, eine Leselampe die du um den Hals trägst, ein Ladekabel das gleichzeitig als Ständer dient — kleine Dinge, die den Alltag auf eine Art verbessern, die man vorher nicht vermisst hat.\n\nAlle Produkte direkt auf Amazon.de. Kein Tracking, kein Account nötig.',
  ARRAY[
    'bug-beam-insektenfalle-uv-licht',
    'welpen-usb-ladekabel-hunde-design',
    'cbdywvr-2in1-ladekabel-mit-staender',
    'glocusent-leselampe-hals',
    'nfc-qr-aufsteller-instagram-schild',
    'couchbar-snackbox-bambus',
    'ticktime-tk3-wuerfel-timer-countdown',
    'spiral-tastaturkabel-custom-coiled-usb-c',
    'rite-in-the-rain-allwetter-notizbuch-field',
    'powerball-gyro-handtrainer-original',
    'handventilator-akku-aufladbar-mini',
    'porseme-ultraschall-luftbefeuchter-farbwechsel',
    'fusselroller-tierhaare-540-blatt-tragbar',
    'prisma-brille-lazy-glasses',
    'kabeltasche-edc-elektronik-organizer-reise',
    'tosy-flying-disc-108-rgb-leds-leuchtfrisbee'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;

-- -----------------------------------------------------------------------------
-- 4. Witzige Geschenke für Männer
-- Target: "Witzige Geschenke für Männer", "Lustige Männer Geschenke"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'witzige-geschenke-maenner',
  'Witzige Geschenke für Männer',
  E'Kein Parfüm. Kein Werkzeug-Set. Keine Socken. Diese Liste zeigt Geschenke für Männer, die beim Auspacken für echte Reaktionen sorgen.',
  E'Es gibt eine stille Vereinbarung beim Männer-Beschenken: Entweder macht man das sichere, langweilige Ding — oder man wählt etwas das er sich nie selbst kaufen würde und genau deswegen liebt.\n\nDas Salzgewehr gegen Fliegen. Das Toilettengolf-Set fürs Büro. Die Wackelfigur fürs Armaturenbrett. Diese Produkte sind nicht nur witzig — sie sind Gesprächsstarter, Büro-Legenden und Schreibtisch-Highlights.\n\nFür Geburtstag, Vatertag, Weihnachten oder einfach weil man ihm etwas kaufen muss und diesmal nicht mit einem Gutschein aufgeben will.',
  ARRAY[
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
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;

-- -----------------------------------------------------------------------------
-- 5. Schreibtisch Setup Gadgets
-- Target: "Schreibtisch Setup Gadgets", "Home Office Gadgets", "Desk Setup"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'schreibtisch-setup-gadgets',
  'Schreibtisch Setup Gadgets',
  E'Der Schreibtisch ist das neue Wohnzimmer. Diese Gadgets machen ihn produktiver, effizienter — und ehrlich gesagt viel cooler.',
  E'Remote Work ist keine Phase. Wer 8 Stunden am Tag am Schreibtisch verbringt, sollte diesen Schreibtisch ernst nehmen — mit Equipment das wirklich funktioniert statt aussieht als ob.\n\nVom Stehpult-Aufsatz der den Rücken rettet, über das HHKB Professional Hybrid das nach zehn Jahren noch das beste Tipp-Erlebnis liefert, bis zur programmierbaren LED-Laufschrift-Tafel die Meetings revolutioniert: Diese Liste zeigt was ein echter Schreibtisch-Setup in 2026 kann.\n\nJedes Produkt wurde danach ausgewählt ob es echten Nutzwert im Alltag bringt — kein Deko-Setup, keine "guter Look für YouTube"-Auswahl. Direkter Amazon-Link bei jedem Produkt.',
  ARRAY[
    'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
    'vivo-hoehenverstellbares-stehpult',
    'tecknet-ergonomische-kabellose-maus-bluetooth',
    'jdvootd-programmierbare-led-laufschrift-tafel',
    'protoarc-xk01-bluetooth-klappbare-tastatur',
    'joyroom-kabelmanagement-schreibtisch-selbstklebend',
    'mfi-zertifiziert-magsafe-wireless-ladestation-15w',
    'ticktime-tk3-wuerfel-timer-countdown',
    'spiral-tastaturkabel-custom-coiled-usb-c',
    'rocketbook-wiederverwendbares-notizbuch-a4',
    'nfc-qr-aufsteller-instagram-schild',
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'leselampe-buch-klemme-augenschonend',
    'hhkb-professional-hybrid',
    'divoom-pixoo-led-panel',
    'oikkei-ki-maus',
    'kabeltasche-edc-elektronik-organizer-reise'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;

-- -----------------------------------------------------------------------------
-- 6. Partyspiele für Erwachsene
-- Target: "Partyspiele Erwachsene", "Spieleabend Ideen", "Kartenspiele Erwachsene"
-- -----------------------------------------------------------------------------
INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'spieleabend-partyspiele-erwachsene',
  'Partyspiele für Erwachsene',
  E'Nicht Uno. Nicht Monopoly. Diese Spiele bringen echte Momente — und enden selten vor Mitternacht.',
  E'Spieleabende können langweilig sein. Müssen sie aber nicht. Der Unterschied liegt im Spiel.\n\nHitster bringt Musiknostalgie und Konkurrenzgeist an einen Tisch. Jumbo Jenga macht aus dem Wohnzimmer ein Kasino. DnD Starter Set verwandelt einen normalen Freitagabend in drei Stunden episches Abenteuer. Und der Tischkicker — der braucht keine Erklärung.\n\nDiese Liste ist für alle, die den nächsten Spieleabend unvergesslich machen wollen. Für Grillabende, Gartenpartys, WG-Abende und alle Situationen in denen "sollen wir Netflix schauen?" die falsche Antwort ist.',
  ARRAY[
    'hitster-musikquiz-partyspiel',
    'huch-what-kartenspiel-deutsche-ausgabe',
    'talking-tables-partyspiel-geburtstag',
    'ubergames-riesenwackelturm-jumbo-jenga',
    'costway-tischkicker-kickertisch',
    'dnd-starter-set-helden-der-grenzlande-deutsch',
    'krimispiel-escape-room-detektivspiel-erwachsene',
    'wer-ist-es-marvel-edition-brettspiel',
    'huzzle-cast-news-metall-knobelpuzzle',
    'empation-cocktailshaker-set',
    'vintage-popcorn-maschine-retro-cart'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title         = EXCLUDED.title,
  intro         = EXCLUDED.intro,
  body          = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published  = EXCLUDED.is_published;
