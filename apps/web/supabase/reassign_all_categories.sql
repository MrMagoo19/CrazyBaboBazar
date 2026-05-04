-- =============================================================================
-- reassign_all_categories.sql
-- Komplett-Neuzuweisung aller Produkte zur neuen Taxonomie
--
-- Neue Taxonomie:
--   babo     → gaming | tech | lifestyle | outdoor
--   queen    → kueche | lifestyle | beauty | geschenke
--   miniboss → spielzeug | gaming | spass
--   wellness → fitness | beauty | outdoor
--
-- Spalten: shop_persona, shop_main_category, shop_sub_category
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BABO / GAMING / tabletop
-- Speed Cubes, DnD, Schach, Puzzlematten, Knobelpuzzles, Tabletop-Zubehör
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'tabletop'
WHERE slug IN (
  'gan-356me-speed-cube-3x3-magnetisch',
  'gan-i4-smart-cube-magnetisch-bluetooth',
  'dnd-spielleiterschirm-5e-dungeon-master',
  'krimispiel-escape-room-detektivspiel-erwachsene',
  'digitale-schachuhr-mit-bonus-delay',
  'faltbare-wuerfelbretter-doppelseitig-2er-set',
  'puzzle-board-2000-teile-mit-8-schubladen',
  'huzzle-cast-news-metall-knobelpuzzle',
  'initiative-tracker-acryl-dnd-tabletop',
  'the-army-painter-wet-palette-tabletop',
  'magnetisches-schachspiel-klappbar-reise',
  'shashibo-formwechsel-box-magnetisch',
  'dnd-starter-set-helden-der-grenzlande-deutsch',
  'ki-go-brett-mit-roboterarm-sense-robot',
  'schachroboter-mit-ki-roboterarm-sense-robot',
  'rpg-charakter-journal-charakterbogen-notizbuch',
  'mtg-playmat-mit-wasserdichter-tasche',
  'puzzlematte-fuer-1500-3000-teile-puzzles',
  'sammelkarten-aufbewahrungsbox-fuer-1800-karten',
  'comic-backing-boards-weiss-acid-free',
  'miniaturen-transportkoffer-mit-schloss'
);

-- Fallback LIKE-Matches für tabletop (falls Slug leicht abweicht)
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'tabletop'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%speed-cube%'
    OR slug LIKE '%gan-356%'
    OR slug LIKE '%gan-i4%'
    OR slug LIKE '%dungeon-master%'
    OR slug LIKE '%spielleiterschirm%'
    OR slug LIKE '%schachuhr%'
    OR slug LIKE '%puzzle-board%'
    OR slug LIKE '%huzzle-cast%'
    OR slug LIKE '%knobelpuzzle%'
    OR slug LIKE '%initiative-tracker%'
    OR slug LIKE '%army-painter%'
    OR slug LIKE '%wet-palette%'
    OR slug LIKE '%shashibo%'
    OR slug LIKE '%charakterbogen%'
    OR slug LIKE '%mtg-playmat%'
    OR slug LIKE '%puzzlematte%'
    OR slug LIKE '%sense-robot%'
    OR slug LIKE '%schachroboter%'
    OR slug LIKE '%backing-boards%'
    OR slug LIKE '%transportkoffer%'
  );

-- -----------------------------------------------------------------------------
-- BABO / GAMING / collectibles
-- Funko Pop, LEGO Icons/Star Wars/Technic, Nintendo Spardosen
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'collectibles'
WHERE slug IN (
  'funko-pop-darth-vader-star-wars',
  'lego-icons-star-trek-uss-enterprise',
  'lego-harry-potter-qualitaet-quidditch',
  'lego-technic-ferrari-sf-24-f1-rennauto',
  'lego-fifa-fussball-wm-pokal-editions-set',
  'nintendo-game-boy-spardose',
  'nintendo-classic-mini-snes'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'collectibles'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%funko-pop%'
    OR slug LIKE '%lego-icons-star-trek%'
    OR slug LIKE '%lego-harry-potter-quidditch%'
    OR slug LIKE '%lego-technic-ferrari%'
    OR slug LIKE '%lego-fifa%'
    OR slug LIKE '%game-boy-spardose%'
    OR slug LIKE '%classic-mini-snes%'
    OR slug LIKE '%nintendo-classic-mini%'
  );

-- -----------------------------------------------------------------------------
-- BABO / GAMING / retro-setup
-- Retro-Konsolen, Arcade Joystick, Controller-Ständer, Vitrine, PS5-Tasche
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'retro-setup'
WHERE slug IN (
  'mad-monkey-retro-spielekonsole',
  'mayflash-f300-arcade-joystick',
  'kytok-controller-staender-4-etagen',
  'yusing-gaming-haengevitrine-regal',
  'ps5-horizontale-tasche-tragetasche'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'retro-setup'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%mad-monkey%'
    OR slug LIKE '%mayflash%'
    OR slug LIKE '%arcade-joystick%'
    OR slug LIKE '%controller-staender%'
    OR slug LIKE '%haengevitrine%'
    OR slug LIKE '%ps5-horizontale%'
    OR slug LIKE '%ps5-tragetasche%'
  );

-- -----------------------------------------------------------------------------
-- BABO / TECH / gadgets
-- Schreibtischlampe, ESP32, LED-Streifen, Messschieber, Kamera, Sternkarte
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'gadgets'
WHERE slug IN (
  'led-schreibtischlampe-mit-gestensteuerung',
  'adressierbarer-rgb-led-streifen-ws2812b',
  'esp32-nodemcu-dev-board-wifi-bluetooth',
  'iFixit-antistatik-matte-faltbar-esd',
  'digitaler-messschieber-edelstahl-150mm',
  'filament-aufbewahrungsbox-3d-druck-6er-pack',
  'rechteckige-lupe-mit-licht-und-standfuss-10x',
  '4k-mini-ueberwachungskamera-wlan-nachtsicht',
  'mammotion-luba-3-awd-maehroboter-lidar',
  'plasmakugel-8-zoll-beruehlungsempfindlich',
  'skullcandy-crusher-anc-2-wireless-kopfhoerer',
  'drehbare-kosmos-sternkarte-planeten',
  'periodensystem-mit-echten-elementen-acryl'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'gadgets'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%gestensteuerung%'
    OR slug LIKE '%ws2812b%'
    OR slug LIKE '%esp32-nodemcu%'
    OR slug LIKE '%antistatik-matte%'
    OR slug LIKE '%messschieber%'
    OR slug LIKE '%filament-aufbewahrung%'
    OR slug LIKE '%lupe-mit-licht%'
    OR slug LIKE '%ueberwachungskamera%'
    OR slug LIKE '%maehroboter-lidar%'
    OR slug LIKE '%plasmakugel%'
    OR slug LIKE '%skullcandy-crusher%'
    OR slug LIKE '%sternkarte-planeten%'
    OR slug LIKE '%periodensystem%'
  );

-- -----------------------------------------------------------------------------
-- BABO / TECH / setup
-- Schreibtischzubehör, Tastaturen, Timer, Kabelmanagement, Notizbücher
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'setup'
WHERE slug IN (
  'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
  'vivo-hoehenverstellbares-stehpult',
  'tecknet-ergonomische-kabellose-maus-bluetooth',
  'jdvootd-programmierbare-led-laufschrift-tafel',
  'protoarc-xk01-bluetooth-klappbare-tastatur',
  'joyroom-kabelmanagement-schreibtisch-selbstklebend',
  'anker-usb-c-adapter-upgraded',
  'mfi-zertifiziert-magsafe-wireless-ladestation-15w',
  'ticktime-tk3-wuerfel-timer-countdown',
  'spiral-tastaturkabel-custom-coiled-usb-c',
  'rocketbook-wiederverwendbares-notizbuch-a4',
  'kabeltasche-edc-elektronik-organizer-reise',
  'nfc-qr-aufsteller-instagram-schild',
  'laptop-staender-hoehenverstellbar-360-drehbar',
  'leselampe-buch-klemme-augenschonend',
  'elektrischer-anspitzer-6-loch-mit-behaelter',
  'rite-in-the-rain-allwetter-notizbuch-field'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'setup'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%schreibtisch-aufsatz%'
    OR slug LIKE '%stehpult%'
    OR slug LIKE '%tecknet%'
    OR slug LIKE '%laufschrift-tafel%'
    OR slug LIKE '%klappbare-tastatur%'
    OR slug LIKE '%kabelmanagement-schreibtisch%'
    OR slug LIKE '%anker-usb-c%'
    OR slug LIKE '%magsafe-wireless%'
    OR slug LIKE '%wuerfel-timer%'
    OR slug LIKE '%coiled-usb-c%'
    OR slug LIKE '%rocketbook%'
    OR slug LIKE '%edc-elektronik%'
    OR slug LIKE '%nfc-qr-aufsteller%'
    OR slug LIKE '%laptop-staender%'
    OR slug LIKE '%buch-klemme%'
    OR slug LIKE '%elektrischer-anspitzer%'
    OR slug LIKE '%rite-in-the-rain%'
    OR slug LIKE '%allwetter-notizbuch%'
  );

-- -----------------------------------------------------------------------------
-- BABO / TECH / diy
-- 3D Holzpuzzle, Modellbausätze, Ameisenfarm
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'diy'
WHERE slug IN (
  '3d-holzpuzzle-leuchtende-weltkugel',
  'rokr-3d-holzpuzzle-raumfaehre-modellbausatz',
  'ameisenfarm-acryl-set-natursand'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'tech',
  shop_sub_category   = 'diy'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%holzpuzzle%'
    OR slug LIKE '%modellbausatz%'
    OR slug LIKE '%ameisenfarm%'
  );

-- -----------------------------------------------------------------------------
-- BABO / LIFESTYLE / gadgets
-- Bier brauen, Fliegenjäger, Kochbuch, Party-Gadgets, Auto-Gadgets
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'gadgets'
WHERE slug IN (
  'bierbrauset-pils-5-liter-fass',
  'bug-a-salt-3-0-fliegenjager-salzgewehr',
  'bug-beam-insektenfalle-uv-licht',
  'snoop-dogg-kochbuch-from-crook-to-cook',
  'toilettenbuerste-gag-geschenk-set-lustig',
  'stress-baelle-quetschball-set',
  'vintage-popcorn-maschine-retro-cart',
  'brubaker-weinflaschenhalter-totenkopf',
  'empation-cocktailshaker-set',
  'kiayoo-wackelfigur-armaturenbrett-auto',
  'joyroom-brillenhalter-auto-sonnenblende',
  'superone-zigarettenanzuender-schnellladegeraet',
  'led-leuchtbrille-aufladbar-party',
  'tosy-flying-disc-108-rgb-leds-leuchtfrisbee'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'gadgets'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%bierbrauset%'
    OR slug LIKE '%bug-a-salt%'
    OR slug LIKE '%salzgewehr%'
    OR slug LIKE '%bug-beam%'
    OR slug LIKE '%snoop-dogg%'
    OR slug LIKE '%toilettenbuerste-gag%'
    OR slug LIKE '%quetschball%'
    OR slug LIKE '%popcorn-maschine%'
    OR slug LIKE '%weinflaschenhalter-totenkopf%'
    OR slug LIKE '%cocktailshaker%'
    OR slug LIKE '%wackelfigur-armaturenbrett%'
    OR slug LIKE '%brillenhalter-auto%'
    OR slug LIKE '%zigarettenanzuender-schnellladegeraet%'
    OR slug LIKE '%leuchtbrille%'
    OR slug LIKE '%leuchtfrisbee%'
  );

-- -----------------------------------------------------------------------------
-- BABO / LIFESTYLE / fashion
-- T-Shirts
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'fashion'
WHERE slug IN (
  'stranger-things-lucas-t-shirt-offiziell',
  'masters-of-the-universe-t-shirt-80er-jahre'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'fashion'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%stranger-things-lucas%'
    OR slug LIKE '%masters-of-the-universe-t-shirt%'
  );

-- -----------------------------------------------------------------------------
-- BABO / OUTDOOR / survival
-- Paracord, Feuerstahl, Messer, Rucksäcke, Campingstühle, Laternen
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'outdoor',
  shop_sub_category   = 'survival'
WHERE slug IN (
  'azengear-paracord-survival-armband-set',
  'tre-feuerstahl-xxl',
  'trekline-multifunktionsmesser-rostfrei',
  'joto-wasserdichte-handyhuelle-unterwasser',
  'sportneer-ultraleichter-campingstuhl',
  'suboos-aufladbare-campinglaterne',
  'fenree-business-rucksack-wasserdicht-usb',
  'ultraleichter-faltbarer-rucksack-20l'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'outdoor',
  shop_sub_category   = 'survival'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%paracord-survival%'
    OR slug LIKE '%feuerstahl-xxl%'
    OR slug LIKE '%multifunktionsmesser%'
    OR slug LIKE '%handyhuelle-unterwasser%'
    OR slug LIKE '%campingstuhl%'
    OR slug LIKE '%campinglaterne%'
    OR slug LIKE '%fenree%'
    OR slug LIKE '%faltbarer-rucksack-20l%'
  );

-- -----------------------------------------------------------------------------
-- BABO / OUTDOOR / camping
-- Zelte, Solar, Dry Bags
-- (Hinweis: Zelte + Solar + Dry Bags werden hier BABO zugewiesen.
--  wellness/outdoor bekommt eigene Zuweisung weiter unten.)
-- Entscheidung: Produkte werden EINMAL zugewiesen. Hier → BABO.
-- wellness/outdoor-Camp-Produkte werden mit eigenen wellness-Slugs behandelt.
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'outdoor',
  shop_sub_category   = 'camping'
WHERE slug IN (
  'wurfzelt-3-4-personen-2-sekunden-aufbau',
  'tipi-zelt-4-6-personen-mit-stehoehe',
  'einhell-solarpanel-40w-faltbar-camping',
  'wasserdichte-dry-bag-5l-30l'
);

UPDATE products SET
  shop_persona        = 'babo',
  shop_main_category  = 'outdoor',
  shop_sub_category   = 'camping'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%wurfzelt%'
    OR slug LIKE '%tipi-zelt%'
    OR slug LIKE '%solarpanel%'
    OR slug LIKE '%dry-bag%'
  );

-- =============================================================================
-- QUEEN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUEEN / KUECHE / gadgets
-- Küchenwerkzeuge, Kaffeemaschinen, Wein-Gadgets, Spezial-Geschirr
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'kueche',
  shop_sub_category   = 'gadgets'
WHERE slug IN (
  'asdirne-pizzaschneider-edelstahl',
  'peleg-design-pastail-walfoermiges-nudelsieb',
  'diycut-taco-staender',
  'katie-cat-suppenkelle-schwarze-katze',
  'one-piece-ramen-bowl-keramik',
  'aeropress-go-tragbare-kaffeemaschine',
  'weinbeluefter-dekanter-ausgiesser',
  '5-in-1-elektrischer-wein-dekanter-smart',
  'snagger-snackspender-saubere-haende',
  'bialetti-moka-express-stranger-things-edition',
  'harry-potter-selbstruerhrende-tasse-zauberstab',
  'lunchbox-mit-faechern-1300ml-kinder'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'kueche',
  shop_sub_category   = 'gadgets'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%pizzaschneider%'
    OR slug LIKE '%nudelsieb%'
    OR slug LIKE '%taco-staender%'
    OR slug LIKE '%suppenkelle%'
    OR slug LIKE '%ramen-bowl%'
    OR slug LIKE '%aeropress%'
    OR slug LIKE '%weinbeluefter%'
    OR slug LIKE '%wein-dekanter%'
    OR slug LIKE '%snackspender%'
    OR slug LIKE '%bialetti-moka%'
    OR slug LIKE '%selbstruerhrende-tasse%'
    OR slug LIKE '%lunchbox%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / LIFESTYLE / deko
-- Schwebendes Regal, Groot, Aquarium, Gartenzwerg, LEGO Botanicals, Haustier
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'deko'
WHERE slug IN (
  'fentec-schwebendes-buecherregal',
  'baby-groot-blumentopf-figur',
  'aquarium-deko-landschaft-kunststoff',
  'yoga-gartenzwerg-buddha-meditation-20cm',
  'lego-botanicals-japanischer-roter-ahorn',
  'lego-botanicals-orchidee-kunstpflanze',
  'haustier-kamera-360-mit-app',
  'petkit-futterautomat-mit-kamera-ki-3l',
  'welpen-usb-ladekabel-hunde-design',
  'sticker-set-200-stueck-neon-vinyl-wasserfest',
  'ramen-katze-japan-y2k-kawaii-t-shirt',
  'astronaut-sternenhimmel-projektor-galaxy'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'deko'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%schwebendes-buecherregal%'
    OR slug LIKE '%groot-blumentopf%'
    OR slug LIKE '%aquarium-deko%'
    OR slug LIKE '%gartenzwerg-buddha%'
    OR slug LIKE '%lego-botanicals%'
    OR slug LIKE '%haustier-kamera%'
    OR slug LIKE '%futterautomat-kamera%'
    OR slug LIKE '%welpen-usb-ladekabel%'
    OR slug LIKE '%sticker-set-neon%'
    OR slug LIKE '%ramen-katze%'
    OR slug LIKE '%sternenhimmel-projektor%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / LIFESTYLE / harry-potter
-- Harry Potter Fandom Produkte (außer Tasse → kueche)
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'harry-potter'
WHERE slug IN (
  'lamy-safari-harry-potter-gryffindor-fueller',
  'harry-potter-nachtwecker-lcd-sounds'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'harry-potter'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%gryffindor-fueller%'
    OR slug LIKE '%harry-potter-nachtwecker%'
    OR slug LIKE '%harry-potter-wecker%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / LIFESTYLE / mode
-- Windbreaker, Ringe, Parfümzerstäuber, Ita Bag, Buchumschläge
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'mode'
WHERE slug IN (
  'newl-reflektierende-holographic-windbreaker',
  'findchic-edelstahl-drehring',
  'toureal-nachfuellbarer-parfuemzerstaeuber-reise',
  'ita-bag-kawaii-rucksack-mit-display-fenster',
  'retro-buchumschlaege-blumen-buchhuell-taschenbu'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'lifestyle',
  shop_sub_category   = 'mode'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%holographic-windbreaker%'
    OR slug LIKE '%findchic%'
    OR slug LIKE '%parfuemzerstaeuber%'
    OR slug LIKE '%ita-bag-kawaii%'
    OR slug LIKE '%buchumschlaege%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / BEAUTY / pflege
-- Kosmetik, Haarpflege, Nagelpflege, Gelstifte
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'beauty',
  shop_sub_category   = 'pflege'
WHERE slug IN (
  'cosrx-pdrn-exosome-skinplaning-glaze-mask',
  'ninabella-haarbuerste-ohne-ziepen',
  'uv-led-nagellampe-gel-naegel-mit-timer',
  'japanische-gelstifte-0-5mm-5er-set'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'beauty',
  shop_sub_category   = 'pflege'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%cosrx%'
    OR slug LIKE '%haarbuerste-ohne-ziepen%'
    OR slug LIKE '%nagellampe%'
    OR slug LIKE '%gelstifte%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / GESCHENKE / lehrer
-- Lehrergeschenke, Jutebeutel
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'geschenke',
  shop_sub_category   = 'lehrer'
WHERE slug IN (
  'lehrergeschenk-stofftasche-abschiedsgeschenk',
  'lehrergeschenk-baumwollbeutel-klassenarbeit-spruch',
  'i-teach-muggles-jutebeutel'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'geschenke',
  shop_sub_category   = 'lehrer'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%lehrergeschenk%'
    OR slug LIKE '%i-teach-muggles%'
    OR slug LIKE '%klassenarbeit-spruch%'
  );

-- -----------------------------------------------------------------------------
-- QUEEN / GESCHENKE / personalisiert
-- Malen nach Zahlen, Foto-Puzzle
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'geschenke',
  shop_sub_category   = 'personalisiert'
WHERE slug IN (
  'personalisiertes-malen-nach-zahlen-eigenes-foto',
  'personalisiertes-foto-puzzle-1000-teile'
);

UPDATE products SET
  shop_persona        = 'queen',
  shop_main_category  = 'geschenke',
  shop_sub_category   = 'personalisiert'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%malen-nach-zahlen-eigenes-foto%'
    OR slug LIKE '%foto-puzzle-1000%'
  );

-- =============================================================================
-- MINIBOSS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- MINIBOSS / SPIELZEUG / lernen
-- STEM, Mikroskope, Roboter, Bitzee
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spielzeug',
  shop_sub_category   = 'lernen'
WHERE slug IN (
  'experimentierset-kinder-100-experimente-stem',
  'magnetische-bausteine-150-teile-ab-4-jahre',
  'digitales-mikroskop-kinder-1000-fach',
  'mx2-digitales-mikroskop-kinder-1000x',
  'makeblock-codey-rocky-programmierbarer-roboter',
  'bitzee-disney-interaktives-digital-haustier'
);

UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spielzeug',
  shop_sub_category   = 'lernen'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%experimentierset-kinder%'
    OR slug LIKE '%magnetische-bausteine%'
    OR slug LIKE '%mikroskop-kinder%'
    OR slug LIKE '%codey-rocky%'
    OR slug LIKE '%bitzee%'
  );

-- -----------------------------------------------------------------------------
-- MINIBOSS / SPIELZEUG / tiere
-- Interaktives Tierspielzeug
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spielzeug',
  shop_sub_category   = 'tiere'
WHERE slug IN (
  'interaktives-hundespielzeug-intelligenzspielzeug',
  'regenbogen-katzenballe-24er-set-interaktiv',
  'vogelspielzeug-nymphensittich-wellensittich'
);

UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spielzeug',
  shop_sub_category   = 'tiere'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%hundespielzeug-intelligenz%'
    OR slug LIKE '%katzenballe-24er%'
    OR slug LIKE '%vogelspielzeug%'
  );

-- -----------------------------------------------------------------------------
-- MINIBOSS / GAMING / collectibles
-- Spardosen, Nachtlichter, FIFA Minifiguren, Brettspiele
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'collectibles'
WHERE slug IN (
  'deadpool-spardose-bueste-marvel',
  'spider-man-tom-holland-spardose-20cm',
  'minecraft-schwein-spardose-19cm',
  'personalisierte-holz-spardose-kinder',
  'elektronische-atm-spardose-kinder',
  'minecraft-fuchs-nachtlicht-offiziell',
  'yuandian-dodo-duck-led-nachtlicht',
  'nelux-3er-pack-planet-wolke-nachtlicht',
  'fifa-world-cup-2026-ballers-minifiguren-2er-pack',
  'wer-ist-es-marvel-edition-brettspiel'
);

UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'gaming',
  shop_sub_category   = 'collectibles'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%deadpool-spardose%'
    OR slug LIKE '%spider-man-spardose%'
    OR slug LIKE '%minecraft-schwein-spardose%'
    OR slug LIKE '%holz-spardose-kinder%'
    OR slug LIKE '%atm-spardose%'
    OR slug LIKE '%minecraft-fuchs-nachtlicht%'
    OR slug LIKE '%dodo-duck%'
    OR slug LIKE '%planet-wolke-nachtlicht%'
    OR slug LIKE '%fifa-world-cup-2026%'
    OR slug LIKE '%wer-ist-es-marvel%'
  );

-- -----------------------------------------------------------------------------
-- MINIBOSS / SPASS / party
-- Kartenspiele, Partyspiele, Tischkicker, Wasserpistolen, Kaugummi-Automat
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spass',
  shop_sub_category   = 'party'
WHERE slug IN (
  'huch-what-kartenspiel-deutsche-ausgabe',
  'talking-tables-partyspiel-geburtstag',
  'hitster-musikquiz-partyspiel',
  'ubergames-riesenwackelturm-jumbo-jenga',
  'costway-tischkicker-kickertisch',
  'derayee-schaumstoff-wasserpistole',
  'ckb-retro-kaugummi-maschine-suessigkeitenspender'
);

UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spass',
  shop_sub_category   = 'party'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%what-kartenspiel%'
    OR slug LIKE '%talking-tables%'
    OR slug LIKE '%hitster%'
    OR slug LIKE '%riesenwackelturm%'
    OR slug LIKE '%tischkicker%'
    OR slug LIKE '%schaumstoff-wasserpistole%'
    OR slug LIKE '%kaugummi-maschine%'
    OR slug LIKE '%suessigkeitenspender%'
  );

-- -----------------------------------------------------------------------------
-- MINIBOSS / SPASS / outdoor
-- Flying Disc (wiederaufladbar — Miniboss-Version)
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spass',
  shop_sub_category   = 'outdoor'
WHERE slug IN (
  'tosy-flying-disc-wiederaufladbar'
);

UPDATE products SET
  shop_persona        = 'miniboss',
  shop_main_category  = 'spass',
  shop_sub_category   = 'outdoor'
WHERE shop_sub_category IS NULL
  AND slug LIKE '%tosy-flying-disc-wiederaufladbar%';

-- =============================================================================
-- WELLNESS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- WELLNESS / FITNESS / sport
-- Sprossenwand, Power Tower, Tennis-Trainer, Powerball, Massagepistole,
-- Akupressurmatte, Saunadecke, Schlafkopfhörer
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'wellness',
  shop_main_category  = 'fitness',
  shop_sub_category   = 'sport'
WHERE slug IN (
  'sprossenwand-mit-klimmzugstange-erwachsene',
  'power-tower-klimmzugstange-faltbar',
  'tennis-trainer-solo-trainingsgeraet',
  'powerball-gyro-handtrainer-original',
  'hyako-massagepistole-triggerpunkt',
  'caspor-akupressurmatte-ganzkoerper',
  'lifepro-infrarot-saunadecke',
  'musicozy-bluetooth-schlafkopfhoerer'
);

UPDATE products SET
  shop_persona        = 'wellness',
  shop_main_category  = 'fitness',
  shop_sub_category   = 'sport'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%sprossenwand%'
    OR slug LIKE '%power-tower-klimmzug%'
    OR slug LIKE '%tennis-trainer%'
    OR slug LIKE '%powerball-gyro%'
    OR slug LIKE '%massagepistole-triggerpunkt%'
    OR slug LIKE '%akupressurmatte%'
    OR slug LIKE '%infrarot-saunadecke%'
    OR slug LIKE '%schlafkopfhoerer%'
  );

-- -----------------------------------------------------------------------------
-- WELLNESS / BEAUTY / pflege
-- Luftbefeuchter, Bartöl, Fusselroller, Handventilator, Noise Machines
-- (UV-Nagellampe & Haarbürste & COSRX → queen/beauty, daher hier ausgelassen)
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona        = 'wellness',
  shop_main_category  = 'beauty',
  shop_sub_category   = 'pflege'
WHERE slug IN (
  'porseme-ultraschall-luftbefeuchter-farbwechsel',
  'mr-bear-family-bartoeel-tiki-punch',
  'fusselroller-tierhaare-540-blatt-tragbar',
  'handventilator-akku-aufladbar-mini',
  'white-noise-machine-baby-einschlafhilfe',
  'cream-noise-machine-baby-tragbar'
);

-- Slug-Variante für ninabella slug-Produkt (ASIN b0bxdpjmqk als Slug)
UPDATE products SET
  shop_persona        = 'wellness',
  shop_main_category  = 'beauty',
  shop_sub_category   = 'pflege'
WHERE slug = 'b0bxdpjmqk';

UPDATE products SET
  shop_persona        = 'wellness',
  shop_main_category  = 'beauty',
  shop_sub_category   = 'pflege'
WHERE shop_sub_category IS NULL
  AND (
    slug LIKE '%luftbefeuchter-farbwechsel%'
    OR slug LIKE '%bartoeel-tiki%'
    OR slug LIKE '%fusselroller%'
    OR slug LIKE '%handventilator-akku%'
    OR slug LIKE '%noise-machine-baby%'
    OR slug LIKE '%einschlafhilfe-baby%'
  );

-- -----------------------------------------------------------------------------
-- WELLNESS / OUTDOOR / camping
-- Zelte, Solar, Dry Bags, Rucksack (wellness-Variante)
-- Hinweis: Diese Produkte haben denselben Slug wie babo/outdoor/camping oben.
-- Da die Produkte in der DB nur EINMAL existieren, werden sie oben BABO zugewiesen.
-- Falls du eigene wellness-Outdoor-Produkte mit eigenen Slugs anlegen willst,
-- füge sie hier ein. Aktuell keine doppelten Zuweisungen.
--
-- Falls gewünscht: Kommentiere die babo-Camping-Statements oben aus und
-- aktiviere die folgenden:
-- -----------------------------------------------------------------------------
-- UPDATE products SET
--   shop_persona        = 'wellness',
--   shop_main_category  = 'outdoor',
--   shop_sub_category   = 'camping'
-- WHERE slug IN (
--   'wurfzelt-3-4-personen-2-sekunden-aufbau',
--   'tipi-zelt-4-6-personen-mit-stehoehe',
--   'einhell-solarpanel-40w-faltbar-camping',
--   'wasserdichte-dry-bag-5l-30l',
--   'ultraleichter-faltbarer-rucksack-20l'
-- );

-- =============================================================================
-- KONTROLLE: Zeige alle Produkte ohne Persona-Zuweisung
-- (Zum Prüfen nach dem Ausführen; auskommentiert für Produktionslauf)
-- =============================================================================
-- SELECT slug, name
-- FROM products
-- WHERE is_published = true
--   AND shop_persona IS NULL
-- ORDER BY slug;
