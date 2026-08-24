-- ============================================================
-- Einmalige Nachtragung: lastmod fuer den Textausbau vom 04.07.2026
-- ============================================================
--
-- Am 04.07.2026 haben 236 Produkte eine editorial_note und/oder eine
-- verlaengerte description erhalten (19 SQL-Dateien: add_editorial_notes_
-- batch1-8, expand_descriptions_batch1-9, fix_descriptions_voicebible,
-- fix_wellness_persona). Keine dieser Dateien hat updated_at mitgeschrieben.
-- Die Sitemap meldet fuer diese URLs daher weiterhin lastmod-Werte zwischen
-- dem 25.04. und dem 19.06.2026.
--
-- HERKUNFT DES DATUMS — bitte lesen, bevor die Datei laeuft:
--   2026-07-04 ist ABGELEITET, nicht gemessen. Es gibt keinen Ausfuehrungs-Log.
--   Genau deshalb ist der Wert noetig: updated_at wurde damals nicht gepflegt,
--   die Spalte kann ihren eigenen Aenderungszeitpunkt also nicht bezeugen.
--   Ein SELECT auf created_at/updated_at beweist hier nichts.
--
--   Was belegt ist:
--     * Untergrenze: die 19 Batch-Dateien wurden am 2026-07-04 zwischen
--       15:12 und 16:39 (+0200) committet (Author- = Committer-Datum).
--       Frueher kann der Inhalt nicht in der Datenbank gewesen sein.
--     * Fuer 2 der 19 Dateien — fix_descriptions_voicebible.sql und
--       fix_wellness_persona.sql — sagt der Commit-Body von f732ae1
--       ausdruecklich "SQL that was already applied to prod", also am
--       04.07. bereits eingespielt.
--     * Obergrenze: die Inhalte sind heute live (per HTTP verifiziert,
--       "Unser Urteil"-Block wird ausgeliefert).
--   Was NICHT belegt ist:
--     * der exakte Ausfuehrungszeitpunkt der uebrigen 17 Dateien. Er liegt
--       irgendwo zwischen dem 04.07.2026 und heute.
--
--   Deshalb wird bewusst die UNTERGRENZE auf Tagesgenauigkeit gesetzt:
--   Mitternacht des 04.07.2026. Ein Fehler in diese Richtung laesst die
--   Seite aelter erscheinen als sie ist — das ist harmlos. Ein zu spaetes
--   Datum waere eine Frische-Behauptung ohne Beleg.
--   Die Uhrzeit 00:00 ist kein Messwert, sondern die uebliche
--   Repraesentation eines nur tagesgenau bekannten Datums.
--
-- Diese Datei traegt dieses Datum nach.
--   KEIN now()  — kein erfundener Uhrzeitwert.
--   KEINE Heuristik — die Slug-Liste ist aus den 19 Batch-Dateien generiert.
--   KEIN Rundumschlag — die uebrigen 136 Produktseiten bleiben unberuehrt.
--
-- SICHERHEIT: dry_run steht auf true. So ausgefuehrt aendert die Datei NICHTS
-- und meldet nur, wie viele Zeilen betroffen waeren. Erst  dry_run := false
-- fuehrt das UPDATE aus.
--
-- Reihenfolge: diese Datei VOR seo_updated_at_trigger.sql ausfuehren.
-- Rollback: siehe Block am Dateiende.
-- ============================================================

do $$
declare
  -- >>> Zum echten Lauf auf false setzen. <<<
  dry_run    boolean     := true;

  -- Tagesgenau, nicht uhrzeitgenau. Siehe Kopfkommentar "HERKUNFT DES DATUMS".
  ziel_zeit  timestamptz := timestamptz '2026-07-04 00:00:00+02';
  erwartet   integer     := 236;
  ziel       text[]      := array[
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
  gefunden       integer;
  betroffen      integer;
  aktualisiert   integer;
begin
  -- 1. Existieren alle Slugs ueberhaupt noch?
  select count(*) into gefunden
  from products
  where slug = any(ziel);

  -- 2. Wie viele davon haetten ein zu altes updated_at?
  select count(*) into betroffen
  from products
  where slug = any(ziel)
    and updated_at < ziel_zeit;

  raise notice 'Slugs in der Liste      : %', array_length(ziel, 1);
  raise notice 'davon in der Datenbank  : %', gefunden;
  raise notice 'davon updated_at < Ziel : %', betroffen;

  if gefunden <> erwartet then
    raise exception
      'Abbruch: % von % Slugs in der Datenbank gefunden. Liste und DB stehen nicht im Einklang.',
      gefunden, erwartet;
  end if;

  if betroffen <> erwartet then
    raise exception
      'Abbruch: % statt % Zeilen wuerden aktualisiert. Erwartete Zielmenge nicht getroffen.',
      betroffen, erwartet;
  end if;

  if dry_run then
    raise notice 'DRY RUN — es wurde nichts geaendert. Fuer den echten Lauf dry_run := false setzen.';
    return;
  end if;

  update products
  set    updated_at = ziel_zeit
  where  slug = any(ziel)
    and  updated_at < ziel_zeit;

  get diagnostics aktualisiert = row_count;

  if aktualisiert <> erwartet then
    raise exception 'Abbruch und Rollback: % statt % Zeilen aktualisiert.', aktualisiert, erwartet;
  end if;

  raise notice 'OK — % Zeilen auf % gesetzt.', aktualisiert, ziel_zeit;
end
$$;

-- ------------------------------------------------------------
-- Kontrolle NACH dem echten Lauf (ohne Slug-Liste, unabhaengig pruefbar)
-- Erwartet: 236
-- ------------------------------------------------------------
-- select count(*) as auf_ziel_zeit
-- from   products
-- where  updated_at = timestamptz '2026-07-04 00:00:00+02';

-- ------------------------------------------------------------
-- Rollback
-- ------------------------------------------------------------
-- Es gibt keinen automatischen Rueckweg zu den alten Einzelwerten — die
-- vorherigen updated_at-Zeitstempel sind nach dem UPDATE verloren.
-- Deshalb VOR dem echten Lauf sichern:
--
--   create table products_updated_at_backup_20260704 as
--   select id, slug, updated_at from products;
--
-- Zuruecksetzen:
--
--   update products p
--   set    updated_at = b.updated_at
--   from   products_updated_at_backup_20260704 b
--   where  p.id = b.id
--     and  p.updated_at is distinct from b.updated_at;
-- ------------------------------------------------------------
