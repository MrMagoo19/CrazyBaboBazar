-- =============================================================================
-- DESCRIPTION EXPANSIONS — Batch 1 (25 Produkte)
-- Ziel: dünne ~150-200 Zeichen Descriptions auf 280-380 Zeichen erweitern.
-- Voice-Bible-konform: konkret, mit "für wen/wann" Kontext, natürliches Deutsch.
-- Für Produkte auf der "Gecrawlt – zurzeit nicht indexiert" GSC-Liste.
-- =============================================================================

-- ── BABO / tech ──────────────────────────────────────────────────────────────

UPDATE products SET description = 'LED-Schreibtischlampe mit berührungsloser Gestensteuerung und Fernbedienung. 24 W, 80 cm breit, Tageslichttechnologie mit mehreren Farbtemperaturen und Dimmstufen. Ohne Klicks zwischen Fokus-Modus, Video-Call-Licht und Ambient wechseln — auch mit fettigen Fingern vom Pizza-Abend beim Coding.'
WHERE slug = 'led-schreibtischlampe-mit-gestensteuerung';

UPDATE products SET description = 'WS2812B LED-Streifen mit 300 individuell adressierbaren LEDs auf 5 Metern. Kompatibel mit Arduino, Raspberry Pi, WLED und allen gängigen Controllern. Rohmaterial für Ambilight, Bett-Beleuchtung, Kunstprojekte und Gaming-Setups — für alle, die ihre Beleuchtung selbst schreiben statt IKEA-Sets zu kaufen.'
WHERE slug = 'adressierbarer-rgb-led-streifen-ws2812b';

UPDATE products SET description = 'AZDelivery ESP32 Dev Kit C V4 mit integriertem WLAN und Bluetooth — Arduino-kompatibel, breadboard-tauglich, inklusive gratis eBook zum Einstieg. Für Smart-Home-Sensoren, IoT-Projekte, Home-Automatisierung ohne Cloud-Zwang. Der Board-Standard, den auch Home-Assistant und ESPHome nativ unterstützen.'
WHERE slug = 'esp32-nodemcu-dev-board-wifi-bluetooth';

UPDATE products SET description = '6er-Pack hermetisch verschließbare Filament-Boxen mit integriertem Trockenmittel und Feuchtigkeits-Indikator. Verhindert dass PLA, PETG oder Nylon nach zwei Wochen offener Lagerung anfangen zu bröseln oder Druck-Artefakte zu produzieren. Setup, das jeder 3D-Drucker früher oder später braucht.'
WHERE slug = 'filament-aufbewahrungsbox-3d-druck-6er-pack';

UPDATE products SET description = 'Digitaler Messschieber aus Edelstahl mit LCD-Display, automatischer Abschaltung und Inch/mm-Umschaltung. Präzision bis 0,01 mm, 150 mm Messbereich. Für Bastler, 3D-Drucker-Kalibrierung, Werkstätten und alle, die auch beim IKEA-Möbelaufbau auf die letzte Nachkommastelle achten wollen.'
WHERE slug = 'digitaler-messschieber-edelstahl-150mm';

UPDATE products SET description = 'Faltbare ESD-Antistatik-Arbeitsmatte mit Erdungsband und magnetischem Schraubenfach. Schützt Motherboards, Grafikkarten und Handy-Innereien vor statischer Entladung beim Basteln. Für alle, die Elektronik selbst reparieren wollen — ohne dass der Teppich das nächste Bauteil kostet.'
WHERE slug = 'ifixit-antistatik-matte-faltbar-esd';

UPDATE products SET description = 'Augenschonende Buchklemm-Leselampe mit 3 Helligkeitsstufen und 3 Farbtemperaturen (warmweiß, neutral, tageslichtweiß). USB-C aufladbar, flexibler Schwanenhals, klemmt an Bücher, Kindle oder Notenständer. Für Bettleser, die neben schlafenden Partnern lesen wollen ohne Diskussion.'
WHERE slug = 'leselampe-buch-klemme-augenschonend';

UPDATE products SET description = 'Beleuchtete Lupe mit 10-facher Vergrößerung, flexiblem Schwanenhals-Ständer und dimmbarer LED-Beleuchtung. Standfest genug für beide Hände frei, für Löten, Kreuzstickerei, Modellbau, Uhrenreparaturen und Kleingedrucktes. Ehrliches Werkzeug, das auch für Senior-Alltagsprobleme funktioniert.'
WHERE slug = 'rechteckige-lupe-mit-licht-und-standfuss-10x';

-- ── BABO / gaming, tabletop, DnD ─────────────────────────────────────────────

UPDATE products SET description = 'Aluminium-gerahmter Transportkoffer für Tabletop-Miniaturen mit 5 verstellbaren Schaumstoff-Lagen. Zahlenschloss, robuster Griff, Kanten-Verstärkung. Für Warhammer-, Frostgrave- oder DnD-Miniaturen auf Turnier-Reisen — damit die Space-Marines nicht am Bahnsteig ihre Waffenarme verlieren.'
WHERE slug = 'miniaturen-transportkoffer-mit-schloss';

UPDATE products SET description = 'Professionelle Spielmatte für Magic: The Gathering, Yu-Gi-Oh oder andere TCG-Spiele. Genähte Kanten, rutschfeste Unterseite, verstärkter Untergrund. Kommt mit wasserdichter Rolltasche für den Transport — für alle, die 400 Euro Deck ernst nehmen und keine Kaffeeflecken drauf haben wollen.'
WHERE slug = 'mtg-playmat-mit-wasserdichter-tasche';

UPDATE products SET description = 'Rollbare Puzzleunterlage aus Filz für Puzzles bis 3000 Teile. Einrollbar mit Klettverschluss, Tabbi-Verpackung, lässt begonnene Puzzles über Wochen sicher zwischenlagern. Für Puzzle-Menschen, deren Wohnzimmertisch nicht dauerhaft blockiert werden darf — oder Familien mit Katzen.'
WHERE slug = 'puzzlematte-fuer-1500-3000-teile-puzzles';

UPDATE products SET description = 'Magnetische Deckbox aus robustem Karton mit Trennwänden — passt für über 1800 Sammelkarten in Standard-Sleeves (MTG, Pokémon, Yu-Gi-Oh, Digimon). Magnetverschluss verhindert versehentliches Öffnen im Rucksack. Für Sammler, deren Bestand nach 3 Jahren die IKEA-Schuhbox sprengt.'
WHERE slug = 'sammelkarten-aufbewahrungsbox-fuer-1800-karten';

UPDATE products SET description = 'Stabiler DM-Screen für Dungeons & Dragons 5e aus Kunstleder und Acryl-Einschüben. Referenztabellen für Rüstungsklasse, Zustände und häufige DCs, dazu Stauraum für Würfel und Karten. Für Dungeon Master, die endlich weniger im Handbuch blättern und mehr Story erzählen wollen.'
WHERE slug = 'dnd-spielleiterschirm-5e-dungeon-master';

UPDATE products SET description = 'Lasergeschnittener Acryl-Initiative-Tracker im Schwert-Design für D&D, Pathfinder oder andere d20-Systeme. Mit 12 farbigen Initiative-Marken und löschbarem HP-Feld pro Kämpfer. Kein Post-it-Chaos mehr am Spieltisch, keine doppelten Züge — sichtbar für alle Spieler, magnetisch stabil.'
WHERE slug = 'initiative-tracker-acryl-dnd-tabletop';

UPDATE products SET description = 'Premium-Krimispiel im Escape-Room-Stil für 1–5 Spieler, ca. 3 Stunden pro Fall. Tatortakte, Spurensuche, Verhörprotokolle, Karten und Fotos — alles physisch, kein Handy nötig. Klimaneutral produziert. Für Freundeskreise, die Netflix-Roulette satt sind und einen echten Whodunit-Abend wollen.'
WHERE slug = 'krimispiel-escape-room-detektivspiel-erwachsene';

UPDATE products SET description = 'Digitale Schachuhr mit Bonus-, Delay- und Fischer-Modus sowie 5+ voreingestellten Turnier-Zeitkontrollen. Klar ablesbares LCD, robust, laut genug für die letzte Sekunde. Für Schach-Clubs, Blitz-Sessions am Küchentisch oder Freundeskreise, die endlich fair auf Zeit spielen wollen.'
WHERE slug = 'digitale-schachuhr-mit-bonus-delay';

UPDATE products SET description = 'Hochwertiges Metall-Knobelpuzzle von Huzzle (früher Hanayama) im Cast News Design, Schwierigkeit 4/6. Auseinandernehmen und wieder zusammensetzen — kann Wochen dauern. Kein Batterie, kein App-Zwang. Für Geduldsspiel-Nerds und alle, die eine Kaffeepausen-Beschäftigung fürs Büro brauchen.'
WHERE slug = 'huzzle-cast-news-metall-knobelpuzzle';

-- ── QUEEN / küche, deko, lifestyle ───────────────────────────────────────────

UPDATE products SET description = 'OTOTO Suppenkelle in Form einer schwarzen Katze, die sich beim Ablegen am Topfrand festklammert. Aus lebensmittelechtem Nylon, spülmaschinen- und hitzebeständig bis 200 °C. Für Küchen mit Charakter — und alle, die auch beim Kochen ein bisschen Deko brauchen können.'
WHERE slug = 'katie-cat-suppenkelle-schwarze-katze';

UPDATE products SET description = 'Auslaufsichere Bento-Lunchbox mit 5 Fächern und 1300 ml Fassungsvermögen. Lebensmittelechte Materialien, BPA-frei, spülmaschinen- und mikrowellenfest. Für Kita- und Schul-Mittag ohne Kohlrabi-neben-Nudeln-Chaos, oder als Meal-Prep-Container für Erwachsene mit Portionsdenken.'
WHERE slug = 'lunchbox-mit-faechern-1300ml-kinder';

UPDATE products SET description = 'Ita-Bag Rucksack mit großem transparentem Acryl-Fenster für Pins, Buttons und Fanmerch. Mit Laptop-Fach bis 15 Zoll, wasserabweisend, verstärkte Träger. Für Anime-Conventions, MangaCon und alle, deren Rucksack gleichzeitig Vitrine und Statement sein soll.'
WHERE slug = 'ita-bag-kawaii-rucksack-mit-display-fenster';

UPDATE products SET description = 'Dekorativer Pflanzentopf in Form von Baby Groot aus Guardians of the Galaxy. Mit Ablaufloch und Abdeckung, aus robustem Kunstharz, ca. 15 cm hoch. Für Sukkulenten, Kakteen oder Kräuter — Fandom-Deko, die weniger Regalplatz frisst als eine ausgewachsene Figur und trotzdem sofort erkennbar ist.'
WHERE slug = 'baby-groot-blumentopf-figur';

UPDATE products SET description = 'Detailreiche Aquarium-Dekoration aus ungiftigem Kunststoff. Verschiedene Designs — Ananashaus (SpongeBob-Verweis, ja), Unterwasser-Landschaften, versunkene Schiffe. Sicher für Süß- und Salzwasser, alle Fischarten. Für Aquarianer, die Karton-Kies-Wasser-Optik hinter sich lassen wollen.'
WHERE slug = 'aquarium-deko-landschaft-kunststoff';

-- ── HAUSTIER ─────────────────────────────────────────────────────────────────

UPDATE products SET description = 'Nina Ottosson Intelligenzspielzeug für Hunde, Schwierigkeitsgrad Level 2 (mittel). Leckerlis in Schiebefächern verstecken — Hund muss durch Schieben, Drehen und Anheben lösen. Fördert mentale Auslastung, ideal für Regen-Nachmittage, Herbst-Wochenenden und Hunde, die zu klug sind für Standard-Spielzeug.'
WHERE slug = 'interaktives-hundespielzeug-intelligenzspielzeug';

UPDATE products SET description = 'Weiche Katzen-Hängematte für Fensterscheiben mit vier robusten Saugnäpfen und abnehmbarem, wendbarem Bezug. Hält bis zu 20 kg, einfach zu montieren, Bezug waschbar. Für Katzen, die auf Sonnenlicht und Aussicht bestehen — und Menschen, deren Fensterbank sonst dauerhaft belegt wäre.'
WHERE slug = 'katzen-fensterliege-haengematte-weich';

UPDATE products SET description = '24-teiliges Set aus bunten interaktiven Bällen für Katzen — leicht, leise (kein plötzliches Nacht-Krach), mit Klingel oder Federn. Fördert Jagdinstinkt, hält Katzen an Regentagen aktiv. Vorratsgröße reicht für Monate, weil Katzen die Hälfte unters Sofa katapultieren.'
WHERE slug = 'regenbogen-katzenbaelle-24er-set-interaktiv';

-- ── BABO / SPARE (retro, camping) ────────────────────────────────────────────

UPDATE products SET description = 'Originalgetreue Replik des klassischen Nintendo Game Boy als Spardose. Aus hochwertigem Kunststoff mit realistischem Detail, Münzschlitz oben. Nostalgisches Sammlerstück und praktischer Sparstrumpf — Geschenk zur ersten Wohnung, für 90er-Kinder, die ihr Kleingeld ehrenhaft parken wollen.'
WHERE slug = 'nintendo-game-boy-spardose';

UPDATE products SET description = 'Robuste Dry Bag aus 500D PVC — kratzfest, wasserdicht (IPX8), staubdicht. In 5 Größen von 5 bis 30 Liter, jeweils mit Schulterriemen. Für Kajak-Touren, Wanderungen im Regen, Angel-Ausflüge und alle Outdoor-Aktivitäten, bei denen Handy und Klamotten trocken bleiben müssen.'
WHERE slug = 'wasserdichte-dry-bag-5l-30l';

UPDATE products SET description = 'Das originale Powerball Basic — gyroskopischer Handtrainer für Handgelenke, Unterarme und Finger. Kein Aufziehmechanismus nötig, arbeitet mit Fliehkräften, geräuscharm, langlebig. Für Kletterer, Musiker, Reha nach Handgelenks-Verletzung und alle, die verspannte Sehnen wieder mobilisieren wollen.'
WHERE slug = 'powerball-gyro-handtrainer-original';

-- =============================================================================
-- PRÜFEN
-- =============================================================================

SELECT slug, LENGTH(description) AS desc_length, LEFT(description, 60) AS preview
FROM products
WHERE slug IN (
  'led-schreibtischlampe-mit-gestensteuerung',
  'adressierbarer-rgb-led-streifen-ws2812b',
  'esp32-nodemcu-dev-board-wifi-bluetooth',
  'filament-aufbewahrungsbox-3d-druck-6er-pack',
  'digitaler-messschieber-edelstahl-150mm',
  'ifixit-antistatik-matte-faltbar-esd',
  'leselampe-buch-klemme-augenschonend',
  'rechteckige-lupe-mit-licht-und-standfuss-10x',
  'miniaturen-transportkoffer-mit-schloss',
  'mtg-playmat-mit-wasserdichter-tasche',
  'puzzlematte-fuer-1500-3000-teile-puzzles',
  'sammelkarten-aufbewahrungsbox-fuer-1800-karten',
  'dnd-spielleiterschirm-5e-dungeon-master',
  'initiative-tracker-acryl-dnd-tabletop',
  'krimispiel-escape-room-detektivspiel-erwachsene',
  'digitale-schachuhr-mit-bonus-delay',
  'huzzle-cast-news-metall-knobelpuzzle',
  'katie-cat-suppenkelle-schwarze-katze',
  'lunchbox-mit-faechern-1300ml-kinder',
  'ita-bag-kawaii-rucksack-mit-display-fenster',
  'baby-groot-blumentopf-figur',
  'aquarium-deko-landschaft-kunststoff',
  'interaktives-hundespielzeug-intelligenzspielzeug',
  'katzen-fensterliege-haengematte-weich',
  'regenbogen-katzenbaelle-24er-set-interaktiv',
  'nintendo-game-boy-spardose',
  'wasserdichte-dry-bag-5l-30l',
  'powerball-gyro-handtrainer-original'
)
ORDER BY desc_length ASC;
