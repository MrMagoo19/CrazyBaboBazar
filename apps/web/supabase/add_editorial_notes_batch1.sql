-- =============================================================================
-- EDITORIAL NOTES — Batch 1 (20 Produkte)
-- Ziel: eindeutig-unique Content pro Produktseite ("Unser Urteil"-Kasten),
-- damit Google die Seiten indexiert. Voice-Bible-konform: kurz, pointiert,
-- Nutzen/Gefühl statt Spec-Liste.
--
-- Fokus: die zuletzt gecrawlten "Gecrawlt – zurzeit nicht indexiert" URLs
-- aus der GSC-Analyse vom 2026-06-25 bis 2026-06-04.
-- =============================================================================

-- ── BABO / tech ──────────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Eine Station, alle Geräte, kein Kabelchaos mehr. Handy, Tablet, Watch, AirPods und Powerbank gleichzeitig — ohne dass der Schreibtisch aussieht wie nach einem Umzug. Setup-Hygiene für Menschen mit mehr Geräten als Steckdosen.'
WHERE slug = 'gitryin-12-in-1-schnellladestation-desktop';

UPDATE products SET editorial_note = 'Der Rolls-Royce der Makro-Boards. 32 programmierbare Tasten mit LCD-Icons — nicht nur für Streamer, sondern für alle die Photoshop, DAWs oder OBS wie ein Cockpit bedienen. Einmal eingerichtet, willst du keine Maus mehr anfassen.'
WHERE slug = 'elgato-stream-deck-xl-32-makrotasten';

UPDATE products SET editorial_note = 'Militärstandard-Schutz für Menschen, die ihr MacBook täglich zwischen Rucksack, Café und Meeting-Room hin- und herschieben. Fühlt sich an wie eine Panzerhülle, sieht aber aus wie was du beim Genius Bar mitbringen darfst.'
WHERE slug = 'uag-macbook-air-15-huelle';

UPDATE products SET editorial_note = 'Der Grund, warum dein Nacken abends nicht mehr schmerzt. Bildschirm auf Augenhöhe, 360° drehbar für Video-Calls und Screen-Sharing. Klingt trivial, ändert deinen Arbeitstag.'
WHERE slug = 'laptop-staender-hoehenverstellbar-360-drehbar';

-- ── BABO / outdoor & tools ───────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Camping- und Grillmeister-Zubehör für alle, die ihr Bier auch beim vierten warm nicht mögen. Vier Funktionen in einem Ding, ohne dass eine davon halbherzig wirkt.'
WHERE slug = 'gteller-4in1-edelstahl-dosenhalter-isolator';

-- ── BABO / fitness ───────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Ein Ding statt zwölf. 18 Kilo, verstellbar in Sekunden, ohne dass du dein Wohnzimmer in einen Kraftraum verwandelst. Für alle, die Home-Workouts ernst nehmen, aber keinen Platz für ein komplettes Rack haben.'
WHERE slug = 'dh-fitlife-verstellbare-kurzhantel-18kg';

-- ── QUEEN / beauty ───────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Das kleine Ding, das entscheidet, ob dein Handgepäck cool riecht oder nach TSA. Nachfüllen aus jeder Flasche, keine Extra-Reisegröße mehr kaufen, keine 100-ml-Regel-Probleme. Simpel, macht Reisen um ein Detail besser.'
WHERE slug = 'toureal-nachfuellbarer-parfuemzerstaeuber-reise';

UPDATE products SET editorial_note = 'Die Beauty-Routine, die dich abends aussehen lässt, als hättest du sie ernst genommen. Vier Modi, wireless, aufs Sofa mitnehmbar. Kein Salon, aber auch keine Ausrede mehr.'
WHERE slug = 'led-gesichtsmaske-wireless-4-modi';

UPDATE products SET editorial_note = 'Der Schminktisch, der endlich funktioniert. Drei Ebenen, dreht sich, alles auf Sicht. Kein Wühlen mehr im Kulturbeutel um den einen Eyeliner. Ordnung, die aussieht wie Deko.'
WHERE slug = 'drehbarer-make-up-organizer-3-ebenen';

UPDATE products SET editorial_note = 'Der 20-Sekunden-Reset für verquollene Augen und lange Nächte. In den Kühlschrank, morgens rausholen, drüberrollen. Kein Wellness-Studio, keine Extra-Skincare-Runde — einfach schneller wach aussehen.'
WHERE slug = 'eisroller-gesicht-augen-hautpflege';

-- ── QUEEN / küche & lifestyle ────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Die Kelle, die aus einer Küchenaktivität ein kleines Bühnenstück macht. Reine Deko-Nerdigkeit, aber der Kater klammert sich charmant am Topfrand fest. Für Menschen, die auch beim Kochen Charakter zeigen wollen.'
WHERE slug = 'katie-cat-suppenkelle-schwarze-katze';

-- ── LIFESTYLE / wellness ─────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Der Grund, warum deine Meditation länger als drei Minuten dauert. Erhöht das Becken, entlastet den Rücken, macht "einfach still sitzen" endlich physisch machbar. Auch als Sitzkissen fürs Sofa unterschätzt.'
WHERE slug = 'inner-peace-meditationskissen-yogakissen';

-- ── PARTY / GESCHENKE ────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Die Grundlage jedes Abends, der "nur ein Bierchen" heißen sollte. Zwei Mikros = keine Ausreden. Bluetooth, Bass, tragbar. Nichts eskaliert Partys schneller.'
WHERE slug = 'hwwr-karaoke-maschine-2-mikrofone';

UPDATE products SET editorial_note = 'Die Karte, die andere Karten wie Belege aussehen lässt. Öffnet sich wie ein Feuerwerk, spielt Musik, leuchtet — und der Beschenkte merkt, dass da jemand mehr als 4,50 Euro investiert hat.'
WHERE slug = 'pop-up-geburtstagskarte-musik-licht-feuerwerk';

-- ── GAMING / SPIELE ──────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Für alle, die Escape Room mögen, aber keine Lust auf 39 Euro pro Person plus Anfahrt haben. Wohnzimmer-Version, funktioniert mit 2–6 Leuten, ein Fall pro Abend. Optimal, wenn Netflix-Roulette wieder mal zu nichts führt.'
WHERE slug = 'krimispiel-escape-room-detektivspiel-erwachsene';

UPDATE products SET editorial_note = 'Das Schachbrett, das jedes Auto, jeden Flug und jeden Wartesaal in eine Partie verwandelt. Magnete halten alles fest, Klappmechanismus verstaut die Figuren im Brett. Für Menschen, die auf "echt spielen" statt Handy-App stehen.'
WHERE slug = 'magnetisches-schachspiel-klappbar-reise';

-- ── MINIBOSS / spielzeug ─────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Der schnellste Weg, ein Kind zu einer Stunde stiller Konzentration zu bekommen. 1000-fache Vergrößerung, USB an Laptop oder Handy — und plötzlich sind Krümel, Blätter und Fingerabdrücke Wissenschaft.'
WHERE slug = 'mx2-digitales-mikroskop-kinder-1000x';

-- ── IRRENHAUS / lifestyle ────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Das ideale Mitbringsel für Menschen, die auf Insta-Storys hoffen. Ob du sie tatsächlich isst oder als Deko im Bücherregal aufstellst — Reaktion garantiert.'
WHERE slug = 'frittierte-regenwuermer-aus-der-dose';

-- ── FASHION ──────────────────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Für alle, deren Alltagsuniform zwischen Anime, Streetwear und Instagram tanzt. Weiche Baumwolle, laute Motive, dezenter Schnitt. Kommt öfter im Kleiderschrank vor, als es sein sollte.'
WHERE slug = 'ramen-katze-japan-y2k-kawaii-t-shirt';

-- ── SMART HOME / HAUSTIER ────────────────────────────────────────────────────

UPDATE products SET editorial_note = 'Für alle, die sich fragen "hat die Katze schon gefressen?" und dann bis Feierabend nicht weiterarbeiten können. App, Live-Kamera, Portionierung. Katzen-Nannying für Berufstätige.'
WHERE slug = 'petkit-futterautomat-mit-kamera-ki-3l';

-- =============================================================================
-- PRÜFEN
-- =============================================================================

SELECT slug, LEFT(editorial_note, 80) AS urteil_preview
FROM products
WHERE editorial_note IS NOT NULL
  AND slug IN (
    'gitryin-12-in-1-schnellladestation-desktop',
    'gteller-4in1-edelstahl-dosenhalter-isolator',
    'elgato-stream-deck-xl-32-makrotasten',
    'toureal-nachfuellbarer-parfuemzerstaeuber-reise',
    'frittierte-regenwuermer-aus-der-dose',
    'dh-fitlife-verstellbare-kurzhantel-18kg',
    'uag-macbook-air-15-huelle',
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'katie-cat-suppenkelle-schwarze-katze',
    'hwwr-karaoke-maschine-2-mikrofone',
    'pop-up-geburtstagskarte-musik-licht-feuerwerk',
    'krimispiel-escape-room-detektivspiel-erwachsene',
    'magnetisches-schachspiel-klappbar-reise',
    'mx2-digitales-mikroskop-kinder-1000x',
    'ramen-katze-japan-y2k-kawaii-t-shirt',
    'led-gesichtsmaske-wireless-4-modi',
    'drehbarer-make-up-organizer-3-ebenen',
    'eisroller-gesicht-augen-hautpflege',
    'inner-peace-meditationskissen-yogakissen',
    'petkit-futterautomat-mit-kamera-ki-3l'
  )
ORDER BY slug;
