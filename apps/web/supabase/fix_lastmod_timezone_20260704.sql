-- ============================================================
-- Korrektur: Zeitzone des lastmod-Backfills vom 04.07.2026
-- ============================================================
--
-- PROBLEM
--   backfill_lastmod_20260704.sql hat updated_at auf
--       timestamptz '2026-07-04 00:00:00+02'   (Mitternacht Berlin)
--   gesetzt. Das ist derselbe Augenblick wie 2026-07-03 22:00 UTC.
--   sitemap.ts gibt ueber new Date(...).toISOString() UTC aus, die Sitemap
--   zeigt daher
--       <lastmod>2026-07-03T22:00:00.000Z</lastmod>
--   also den 3. Juli. Semantisch derselbe Zeitpunkt, optisch der falsche Tag.
--
-- ZIEL
--   updated_at = timestamptz '2026-07-04 00:00:00+00'
--   rendert als 2026-07-04T00:00:00.000Z
--
-- ZIELMENGE
--   NICHT allein ueber updated_at ausgewaehlt, sondern ID-basiert:
--   die Produkte, deren id in products_updated_at_backup_20260704 steht,
--   deren Sicherungswert AELTER ist als der Backfill-Wert und deren
--   aktueller Wert exakt der Backfill-Wert ist. Das sind genau die Zeilen,
--   die der Backfill angefasst hat.
--   Zusaetzlich wird die so ermittelte ID-Menge gegen die 236 Slugs aus
--   backfill_lastmod_20260704.sql gegengeprueft — zwei unabhaengige Wege
--   muessen dieselbe Menge ergeben, sonst Abbruch.
--
-- SICHERHEIT
--   dry_run steht auf true. So ausgefuehrt aendert die Datei NICHTS.
--   Es wird ausschliesslich updated_at geschrieben, keine andere Spalte.
--   Der Trigger products_set_updated_at greift nicht: updated_at wird
--   ausdruecklich mitgeschrieben, damit ist seine Guard-Bedingung
--   new.updated_at is not distinct from old.updated_at bereits falsch.
--
--   Voraussetzung: die Sicherungstabelle products_updated_at_backup_20260704
--   existiert. Fehlt sie, bricht die Datei ab statt zu raten.
-- ============================================================

do $$
declare
  -- >>> Zum echten Lauf auf false setzen. <<<
  dry_run    boolean     := true;

  alt_wert   timestamptz := timestamptz '2026-07-04 00:00:00+02';  -- 2026-07-03T22:00:00Z
  neu_wert   timestamptz := timestamptz '2026-07-04 00:00:00+00';  -- 2026-07-04T00:00:00Z
  erwartet   integer     := 236;

  slug_liste text[] := array[
      '3d-holzpuzzle-leuchtende-weltkugel',
      '4k-mini-ueberwachungskamera-wlan-nachtsicht',
      '5-in-1-elektrischer-wein-dekanter-smart',
      '6-teiliges-schubladen-ordnungssystem',
      'aarke-wasserkocher-edelstahl-1-2l',
      'adressierbarer-rgb-led-streifen-ws2812b',
      'ai-kopfhoerer-echtzeit-sprachuebersetzter-164-sprachen',
      'ameisenfarm-acryl-set-natursand',
      'aquarium-deko-landschaft-kunststoff',
      'asdirne-pizzaschneider-edelstahl',
      'asien-vegetarisch-kochbuch',
      'baby-groot-blumentopf-figur',
      'baby-mop-strampler-krabbeln-putzen',
      'bartesian-cocktailmaschine-mit-kapseln',
      'batman-fuggler-pluesch',
      'bbq-wuerstchenhalter-maennchen-3er-set',
      'beheizte-wimpernzange-s600',
      'bite-away-two-elektronischer-insektenstichheiler',
      'brubaker-weinflaschenhalter-totenkopf',
      'bug-a-salt-3-0-fliegenjaeger-salzgewehr',
      'bug-beam-insektenfalle-uv-licht',
      'caso-hw660-heisswasserspender',
      'caspor-akupressurmatte-ganzkoerper',
      'cbdywvr-2in1-ladekabel-mit-staender',
      'charmofun-ninja-airfryer-zubehoer-28-stueck',
      'ckb-retro-kaugummi-maschine-suessigkeitenspender',
      'cleanmaxx-pro-automatischer-hemdenbugler',
      'costway-tischkicker-kickertisch',
      'couchbar-snackbox-bambus',
      'cream-noise-machine-baby-tragbar',
      'deadpool-auto-anhaenger-ornament',
      'deadpool-spardose-bueste-marvel',
      'delay-spray-maenner-mega-xxl',
      'derayee-schaumstoff-wasserpistole',
      'dh-fitlife-verstellbare-kurzhantel-18kg',
      'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
      'digitale-schachuhr-mit-bonus-delay',
      'digitaler-messschieber-edelstahl-150mm',
      'divoom-minitoo-retro-pc-lautsprecher-pixel',
      'diycut-taco-staender',
      'dnd-spielleiterschirm-5e-dungeon-master',
      'dnd-starter-set-helden-der-grenzlande-deutsch',
      'drehbare-kosmos-sternkarte-planeten',
      'drehbarer-make-up-organizer-3-ebenen',
      'dusch-wc-aufsatz-warmwasser',
      'dyson-zone-absolute-kopfhoerer',
      'einhell-solarpanel-40w-faltbar-camping',
      'einhorn-jahresvorrat-kondome',
      'einweg-urinbeutel-frauen-unterwegs',
      'eisroller-gesicht-augen-hautpflege',
      'eiswuerfelform-lebensmittelechte',
      'eiswuerfelform-todesstern-star-wars',
      'elektrischer-anspitzer-6-loch-mit-behaelter',
      'elektrisches-nackenmassagegeraet-schultermassage',
      'elgato-stream-deck-xl-32-makrotasten',
      'empation-cocktailshaker-set',
      'esp32-nodemcu-dev-board-wifi-bluetooth',
      'experimentierset-kinder-100-experimente-stem',
      'faelnk-toilettengolf-set',
      'faltbarer-silikon-becher-eisball-2in1',
      'farerkass-pomodoro-timer-cube-countdown',
      'fenree-business-rucksack-wasserdicht-usb',
      'fentec-schwebendes-buecherregal',
      'fifa-world-cup-2026-ballers-minifiguren-2er-pack',
      'filament-aufbewahrungsbox-3d-druck-6er-pack',
      'findchic-edelstahl-drehring',
      'frittierte-regenwuermer-aus-der-dose',
      'funko-pop-darth-vader-star-wars',
      'fusselroller-tierhaare-540-blatt-tragbar',
      'fussmassage-igelball-faszienrolle',
      'gan-356me-speed-cube-3x3-magnetisch',
      'gan-i4-smart-cube-magnetisch-bluetooth',
      'geckoman-elektrische-fliegenklatsche',
      'ghome-smart-wlan-steckdose-4er-pack',
      'gitryin-12-in-1-schnellladestation-desktop',
      'glocusent-leselampe-hals',
      'gluecksgut-anti-stress-wuerfel',
      'gluecksgut-voodoo-puppe',
      'gteller-4in1-edelstahl-dosenhalter-isolator',
      'handventilator-akku-aufladbar-mini',
      'harry-potter-nachtwecker-lcd-sounds',
      'harry-potter-selbstruehrende-tasse-zauberstab',
      'hasbro-twister-klassik',
      'haustier-kamera-360-mit-app',
      'heat-it-insektenstichheiler-smartphone',
      'hitster-musikquiz-partyspiel',
      'huch-what-kartenspiel-deutsche-ausgabe',
      'hurtle-rutschauto-wiggle-drift-car-kinder',
      'huzzle-cast-news-metall-knobelpuzzle',
      'hwwr-karaoke-maschine-2-mikrofone',
      'ifixit-antistatik-matte-faltbar-esd',
      'initiative-tracker-acryl-dnd-tabletop',
      'inner-peace-meditationskissen-yogakissen',
      'interaktives-hundespielzeug-intelligenzspielzeug',
      'ita-bag-kawaii-rucksack-mit-display-fenster',
      'japanische-gelstifte-0-5mm-5er-set',
      'jarlson-trinkflasche-kinder-350ml',
      'jdvootd-programmierbare-led-laufschrift-tafel',
      'joto-wasserdichte-handyhuelle-unterwasser',
      'joyroom-brillenhalter-auto-sonnenblende',
      'kabeltasche-edc-elektronik-organizer-reise',
      'kaffeewaermer-tassenwaermer-elektrisch',
      'katie-cat-suppenkelle-schwarze-katze',
      'katzen-fensterliege-haengematte-weich',
      'katzenschlafsack-fuer-menschen',
      'krimispiel-escape-room-detektivspiel-erwachsene',
      'lamy-safari-harry-potter-gryffindor-fueller',
      'laptop-staender-hoehenverstellbar-360-drehbar',
      'layersmith-schaf-toilettenpapierhalter',
      'led-gesichtsmaske-wireless-4-modi',
      'led-leuchtbrille-aufladbar-party',
      'led-schreibtischlampe-mit-gestensteuerung',
      'lego-botanicals-japanischer-roter-ahorn',
      'lego-botanicals-orchidee-kunstpflanze',
      'lego-cristiano-ronaldo-figur-43016',
      'lego-fifa-fussball-wm-pokal-editions-set',
      'lego-harry-potter-qualitaet-quidditch',
      'lego-icons-star-trek-uss-enterprise',
      'lego-pokemon-bisaflor-glurak-turtok-72153',
      'lego-storage-brick-4-gelb',
      'lego-super-mario-64-fragezeichen-block',
      'lego-technic-ferrari-sf-24-f1-rennauto',
      'lehrergeschenk-baumwollbeutel-klassenarbeit-spruch',
      'leselampe-buch-klemme-augenschonend',
      'lumineo-ultraschall-peelinggeraet',
      'lunchbox-mit-faechern-1300ml-kinder',
      'lymphdrainage-buerste-gesicht-jawline-sculpting',
      'magnetische-bausteine-150-teile-ab-4-jahre',
      'magnetisches-schachspiel-klappbar-reise',
      'makeblock-codey-rocky-programmierbarer-roboter',
      'mammotion-luba-3-awd-maehroboter-lidar',
      'mangoschneider-fruchthalter',
      'masters-of-the-universe-t-shirt-80er-jahre',
      'mayflash-f300-arcade-joystick',
      'mfi-zertifiziert-magsafe-wireless-ladestation-15w',
      'minecraft-fuchs-nachtlicht-offiziell',
      'minecraft-schwein-spardose-19cm',
      'mini-vibrator-lippenstift-10-modi',
      'miniaturen-transportkoffer-mit-schloss',
      'mond-deckenlampe-mit-fernbedienung',
      'mr-bear-family-bartoel-tiki-punch',
      'mtg-playmat-mit-wasserdichter-tasche',
      'musicozy-bluetooth-schlafkopfhoerer',
      'mx2-digitales-mikroskop-kinder-1000x',
      'n4-nussmilchbereiter-pflanzenmilch',
      'nfc-qr-aufsteller-instagram-schild',
      'nifbang-iphone-17-pro-max-huelle-magnetstaender',
      'ninja-creami-scoop-swirl',
      'ninja-staysharp-messerset-6-teilig',
      'nintendo-classic-mini-snes',
      'nintendo-game-boy-spardose',
      'ollny-camping-lichterkette-10m',
      'one-piece-ramen-bowl-keramik',
      'periodensystem-mit-echten-elementen-acryl',
      'personalisierter-kinder-riegel-xxl-30er',
      'personalisiertes-foto-puzzle-1000-teile',
      'personalisiertes-led-nachtlicht-jugendzimmer',
      'personalisiertes-leuchtschild-wanddekoration',
      'personalisiertes-malen-nach-zahlen-eigenes-foto',
      'petkit-futterautomat-mit-kamera-ki-3l',
      'plasmakugel-8-zoll-beruehrungsempfindlich',
      'pop-up-geburtstagskarte-musik-licht-feuerwerk',
      'porseme-ultraschall-luftbefeuchter-farbwechsel',
      'powerball-gyro-handtrainer-original',
      'prisma-brille-lazy-glasses',
      'protoarc-xk01-bluetooth-klappbare-tastatur',
      'prunus-notfall-kurbelradio-j366',
      'puzzlematte-fuer-1500-3000-teile-puzzles',
      'ramen-katze-japan-y2k-kawaii-t-shirt',
      'rechteckige-lupe-mit-licht-und-standfuss-10x',
      'recovry-dermaroller-maenner-haarwachstum',
      'regenbogen-katzenbaelle-24er-set-interaktiv',
      'relaxdays-tierpinata-set',
      'rfid-blocker-karte-neueste-technologie',
      'rgb-gaming-mauspad-led-schreibtischpad',
      'rite-in-the-rain-allwetter-notizbuch-field',
      'rocketbook-wiederverwendbares-notizbuch-a4',
      'rosenstein-soehne-rollbare-warmhalteplatte',
      'sammelkarten-aufbewahrungsbox-fuer-1800-karten',
      'schachroboter-mit-ki-roboterarm-sense-robot',
      'scheisse-quartett-kartenspiel',
      'schildkroete-solarlaternen-metall-haengedeko',
      'schluesselfinder-4-empfaenger-led-30m',
      'shark-turboblade-turmventilator-tf200seu',
      'shashibo-formwechsel-box-magnetisch',
      'shuffleboard-tischset-curling-familienspiel',
      'silikon-magnete-airfryer-backpapier-4er-set',
      'skullcandy-crusher-anc-2-wireless-kopfhoerer',
      'snagger-snackspender-saubere-haende',
      'snoop-dogg-kochbuch-from-crook-to-cook',
      'spider-man-tom-holland-spardose-20cm',
      'sportneer-ultraleichter-campingstuhl',
      'sprossenwand-mit-klimmzugstange-erwachsene',
      'starthilfe-powerbank-7000a-booster',
      'sticker-set-200-stueck-neon-vinyl-wasserfest',
      'stranger-things-lucas-t-shirt-offiziell',
      'street-fighter-arcade-machine',
      'stress-baelle-quetschball-set',
      'suboos-aufladbare-campinglaterne',
      'supcase-magsafe-wallet-iphone',
      'superone-zigarettenanzuender-schnellladegeraet',
      'talking-tables-partyspiel-geburtstag',
      'tecknet-ergonomische-kabellose-maus-bluetooth',
      'teenage-engineering-tp7-audio-recorder',
      'tefal-ixeo-power-allinone-dampfglaetter',
      'tennis-trainer-solo-trainingsgeraet',
      'the-army-painter-wet-palette-tabletop',
      'tipi-zelt-4-6-personen-mit-stehoehe',
      'toilettenbuerste-gag-geschenk-set-lustig',
      'tosy-flying-disc-108-rgb-leds-leuchtfrisbee',
      'tosy-flying-disc-wiederaufladbar',
      'toureal-nachfuellbarer-parfuemzerstaeuber-reise',
      'tradercat-i-teach-muggles-jutebeutel-lehrer',
      'tre-feuerstahl-xxl',
      'trekline-multifunktionsmesser-rostfrei',
      'uag-macbook-air-15-huelle',
      'ubergames-riesenwackelturm-jumbo-jenga',
      'ultraleichter-faltbarer-rucksack-20l',
      'uv-led-nagellampe-gel-naegel-mit-timer',
      'vachichi-boyfriend-kissen-muskuloeser-arm',
      'vicseed-magnet-handyhalterung-auto',
      'vintage-popcorn-maschine-retro-cart',
      'vivo-hoehenverstellbares-stehpult',
      'vogelspielzeug-nymphensittich-wellensittich',
      'wahrheit-oder-pflicht-kartenspiel-paare',
      'wasserdichte-dry-bag-5l-30l',
      'wasserfilter-trinkflasche-edelstahl',
      'weinbeluefter-dekanter-ausgiesser',
      'welpen-usb-ladekabel-hunde-design',
      'white-noise-machine-baby-einschlafhilfe',
      'wolfbox-megaflow-elektrischer-druckluft-reiniger',
      'wurfzelt-3-4-personen-2-sekunden-aufbau',
      'xgimi-horizon-ultra-4k-projektor',
      'yuandian-dodo-duck-led-nachtlicht',
      'yunzii-ql75-retro-schreibmaschinen-tastatur',
      'yusing-gaming-haengevitrine-regal'
  ];

  ziel_ids       uuid[];
  n_ids          integer;
  n_alt_wert     integer;
  n_nur_slug     integer;
  n_nur_id       integer;
  aktualisiert   integer;
begin
  -- 0. Sicherungstabelle vorhanden?
  if to_regclass('public.products_updated_at_backup_20260704') is null then
    raise exception
      'Abbruch: Sicherungstabelle products_updated_at_backup_20260704 fehlt. '
      'Ohne sie laesst sich die Zielmenge nicht ID-basiert bestimmen.';
  end if;

  -- 1. Zielmenge ID-basiert aus der Sicherung ableiten.
  select array_agg(p.id)
    into ziel_ids
  from products p
  join products_updated_at_backup_20260704 b on b.id = p.id
  where p.updated_at = alt_wert          -- heutiger Backfill-Wert
    and b.updated_at < alt_wert;         -- Sicherung ist aelter, wurde also veraendert

  n_ids := coalesce(array_length(ziel_ids, 1), 0);

  -- 2. Wie viele Zeilen tragen den Backfill-Wert insgesamt?
  select count(*) into n_alt_wert from products where updated_at = alt_wert;

  -- 3. Gegenprobe gegen die Slug-Liste aus backfill_lastmod_20260704.sql.
  select count(*) into n_nur_slug
  from products
  where slug = any(slug_liste)
    and not (id = any(ziel_ids));

  select count(*) into n_nur_id
  from products
  where id = any(ziel_ids)
    and not (slug = any(slug_liste));

  raise notice 'Zielmenge ueber Sicherung (IDs) : %', n_ids;
  raise notice 'Zeilen mit Backfill-Wert gesamt : %', n_alt_wert;
  raise notice 'nur in Slug-Liste, nicht in IDs : %', n_nur_slug;
  raise notice 'nur in IDs, nicht in Slug-Liste : %', n_nur_id;

  if n_ids <> erwartet then
    raise exception 'Abbruch: Zielmenge % statt % IDs.', n_ids, erwartet;
  end if;

  if n_alt_wert <> erwartet then
    raise exception
      'Abbruch: % Zeilen tragen den Backfill-Wert, erwartet %. '
      'Es wurden seit dem Backfill weitere Zeilen auf diesen Wert gesetzt.',
      n_alt_wert, erwartet;
  end if;

  if n_nur_slug <> 0 or n_nur_id <> 0 then
    raise exception
      'Abbruch: ID-Menge und Slug-Liste stimmen nicht ueberein (% / %).',
      n_nur_slug, n_nur_id;
  end if;

  if dry_run then
    raise notice 'DRY RUN — es wurde nichts geaendert. Fuer den echten Lauf dry_run := false setzen.';
    return;
  end if;

  -- 4. Nur updated_at, nur diese IDs.
  update products
  set    updated_at = neu_wert
  where  id = any(ziel_ids)
    and  updated_at = alt_wert;

  get diagnostics aktualisiert = row_count;

  if aktualisiert <> erwartet then
    raise exception 'Abbruch und Rollback: % statt % Zeilen aktualisiert.', aktualisiert, erwartet;
  end if;

  raise notice 'OK — % Zeilen auf % gesetzt.', aktualisiert, neu_wert;
end
$$;


-- ============================================================
-- PRUEFQUERIES (nach dem echten Lauf einzeln ausfuehren)
-- ============================================================

-- 1. Genau 236 Produkte auf dem Zielwert?
-- select count(*) as auf_zielwert
-- from   products
-- where  updated_at = timestamptz '2026-07-04 00:00:00+00';
-- erwartet: 236

-- 2. Keine Zeile traegt mehr den alten Wert?
-- select count(*) as noch_alter_wert
-- from   products
-- where  updated_at = timestamptz '2026-07-04 00:00:00+02';
-- erwartet: 0

-- 3. Stichprobe — muss 2026-07-04T00:00:00+00:00 zeigen.
-- select slug, updated_at
-- from   products
-- where  slug in ('3d-holzpuzzle-leuchtende-weltkugel',
--                 '4k-mini-ueberwachungskamera-wlan-nachtsicht',
--                 '5-in-1-elektrischer-wein-dekanter-smart')
-- order  by slug;

-- 4. Gegenprobe — nicht betroffene Produkte unveraendert gegenueber der Sicherung.
-- select count(*) as unveraendert
-- from   products p
-- join   products_updated_at_backup_20260704 b on b.id = p.id
-- where  p.updated_at = b.updated_at;
-- erwartet: 136 Produkte plus alle nicht veroeffentlichten Zeilen

-- 5. Wurde ausser updated_at etwas angefasst? Sicherung enthaelt nur
--    id, slug und updated_at — Spaltenvergleich daher ueber die Zeilenzahl:
-- select count(*) as produkte_gesamt from products;
-- erwartet: unveraendert gegenueber vor dem Lauf


-- ============================================================
-- ROLLBACK
-- ============================================================

-- A) Nur diese Korrektur zurueck (zurueck auf den Backfill-Wert +02):
-- update products
-- set    updated_at = timestamptz '2026-07-04 00:00:00+02'
-- where  updated_at = timestamptz '2026-07-04 00:00:00+00';
-- erwartet: 236 Zeilen

-- B) Vollstaendig zurueck auf den Stand VOR dem Backfill:
-- update products p
-- set    updated_at = b.updated_at
-- from   products_updated_at_backup_20260704 b
-- where  p.id = b.id
--   and  p.updated_at is distinct from b.updated_at;
-- erwartet: 236 Zeilen

-- Die Sicherungstabelle erst loeschen, wenn beide Varianten nicht mehr
-- gebraucht werden:
-- drop table products_updated_at_backup_20260704;
