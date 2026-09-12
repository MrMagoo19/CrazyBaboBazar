-- ============================================================================
-- DRAFT — FEATURED VALUE-ADD BATCH 4 — CONTENT NUR, NICHT ZUR AUSFUEHRUNG
-- ============================================================================
-- STATUS: DRAFT. Diese Datei ist KEIN Produktions-Artefakt. Sie enthaelt
-- ausschliesslich vorformulierten Value-Add-Content zur redaktionellen
-- Freigabe. Es gibt bewusst KEIN begin/commit, KEINE Guard-Bloecke, KEINE
-- Backup-/Backfill-/Restore-Logik und KEINEN Bezug zu einer Supabase-Umgebung.
-- Diese Datei darf nicht gegen Production oder irgendeine andere Datenbank
-- ausgefuehrt werden. Ein produktionsreifes Vier-Schritte-Paket (Preflight,
-- Backup, Backfill, Restore) nach dem Muster von production_value_add_batch3
-- entsteht erst NACH redaktioneller Freigabe dieses Drafts, in eigenen Dateien.
--
-- QUELLENBINDUNG: siehe SOURCES_featured_value_add_batch4.md im selben
-- Verzeichnis fuer die Zuordnung jeder Aussage zu ihrer Repo-Quelldatei.
--
-- UMFANG: 12 von 12 angefragten Slugs. Die drei ursprünglich fehlenden
-- Produktquellen wurden nachträglich über offizielle Herstellerseiten ergänzt;
-- die URLs und belegten Fakten stehen im SOURCES-Dokument.
--
-- KEINE EXAKTEN PREISE: dem Voice-Bible-Regelwerk folgend enthaelt keine
-- Zeile einen Preis oder ein Preisband.
--
-- RELATIONEN: keine. Fuer keines der zwoelf Zielprodukte liegt eine Repo-Quelle
-- vor, die eine alternative_slug/alternative_reason/alternative_kind-Relation
-- zu einem anderen veroeffentlichten Produkt eindeutig stuetzt. Alle neun
-- Zeilen tragen deshalb alternative_slug, alternative_reason und
-- alternative_kind als NULL.
-- ============================================================================

-- Struktur zur Orientierung fuer die spaetere Produktions-Payload-Tabelle.
-- Nicht ausfuehren — kein CREATE, kein Zielschema, keine Transaktion.
--
-- spalten: slug, fuer_wen, nicht_fuer, key_fact, pros (2-4), cons (>=1), editorial_note

-- DRAFT PAYLOAD BATCH 4 (12 Zeilen)
values
(
  'aarke-wasserkocher-edelstahl-1-2l',
  'Alle, die einen Wasserkocher wollen, der auf der Küchenzeile auch gut aussieht und bei Tee, Kaffee oder Babymilch die passende Temperatur trifft.',
  'Wer nur schnell Wasser heiß machen will, ohne Temperaturwahl — dafür reicht ein einfacher Wasserkocher.',
  'Edelstahl-Wasserkocher mit mehreren Temperatureinstellungen im Bereich von 40 bis 100 °C, 1,2 Liter, vom schwedischen Designlabel Aarke.',
  array[
    'Temperaturwahl passend für Grüntee (70 °C), Kaffee (94 °C) und Babymilch (37 °C)',
    '360°-Sockel, tropffreier Ausgießer, leiser Kochvorgang',
    'Preisgekröntes skandinavisches Design, in vier Farben erhältlich',
    'Von Aarke — demselben Label wie der bekannte Carbonator'
  ],
  array[
    'Die 1,2-Liter-Größe setzt bei mehreren Tassen hintereinander eine klare Grenze',
    'Mehrere Temperatureinstellungen sind für Nutzer ohne Tee- oder Kaffee-Routine möglicherweise unnötig'
  ],
  null, null, null,
  'Der Aarke-Wasserkocher aus Edelstahl, der Küchen sofort premium aussehen lässt: 1,2 Liter, Temperaturwahl von 40 bis 100 °C, preisgekröntes skandinavisches Design. Für Menschen, deren Küche auch ein Statement ist.'
),
(
  'dji-osmo-pocket-4-kreativ-combo',
  'Alle, die regelmäßig filmen — Reisen, Sport, Content, Familie — und genug von verwackelten Handy-Videos haben.',
  'Wer nur gelegentlich ein Foto macht — dafür reicht das Smartphone.',
  'Kompakt-Kamera mit Einzoll-Sensor, 4K-Video bis 240 Bilder pro Sekunde und 3-Achsen-Gimbal-Stabilisierung; die Kreativ-Combo bringt zusätzlich ein Mic-3-Sender-Empfänger-Set und ein Fülllicht mit.',
  array[
    'Einzoll-Sensor und 4K bei bis zu 240 Bildern pro Sekunde',
    '3-Achsen-Gimbal gleicht Wackler mechanisch aus',
    '107 GB interner Speicher, kein SD-Karten-Zwang',
    'Kreativ-Combo liefert Mikrofon-Set und Fülllicht gleich mit'
  ],
  array[
    '107 GB interner Speicher sind angegeben; eine Erweiterung wird in der Quelle nicht genannt',
    'Zusatzteile der Kreativ-Combo brauchen beim Transport eigenen Stauraum'
  ],
  null, null, null,
  'Die kleinste Profi-Kamera aus dem DJI-Programm, in der Kreativ-Combo direkt mit Mikrofon-Set und Fülllicht. Einzoll-Sensor und 240fps passen locker in die Hosentasche. Für alle, die regelmäßig filmen und verwackelte Handy-Videos hinter sich lassen wollen.'
),
(
  'dyson-zone-absolute-kopfhoerer',
  'Alle, die viel in der Stadt oder im Transit unterwegs sind und schlechte Luft nicht mehr als normal hinnehmen wollen.',
  'Wer schlichte, kompakte Kopfhörer sucht — mit aufgesetztem Luftfilter-Visor ist das Gerät deutlich sperriger als normale Over-Ears.',
  'Over-Ear-Kopfhörer mit aktivem Noise-Cancelling und optionalem Luftfilter-Visor, der PM2.5-Partikel, Pollen, Bakterien und NO2-Gase direkt vor dem Gesicht filtert.',
  array[
    'Filtert PM2.5, Pollen, Bakterien und NO2-Gase in Echtzeit',
    'Aktives Noise-Cancelling auf Flaggschiff-Niveau, 11-Treiber-Audiosystem',
    'Bis zu 50 Stunden Akkulaufzeit',
    'Gereinigte Luft kommt ohne Schlauch oder Maske direkt aus dem Bügel'
  ],
  array[
    'Mit aufgesetztem Visor deutlich sperriger als normale Kopfhörer',
    'Wer nur ANC-Kopfhörer braucht, nutzt die zusätzliche Luftfilter-Funktion möglicherweise nicht'
  ],
  null, null, null,
  'Kopfhörer und Luftreiniger in einem Gehäuse — klingt nach Marketing-Gag, filtert aber tatsächlich PM2.5, Pollen und NO2 direkt vor dem Gesicht. Bis zu 50 Stunden Akku, ANC auf Flaggschiff-Niveau. Absurdes Gerät, aber auf die einzig richtige Art absurd.'
),
(
  'ferrofluid-sound-visualizer-lampe',
  'Alle, die eine Lampe wollen, die nicht einfach nur leuchtet, sondern sichtbar auf Musik reagiert.',
  'Wer eine schlichte, unauffällige Lichtquelle sucht — das Ding ist bewusst ein Blickfang.',
  'Ferrofluid-Lampe, die sich im Takt der Musik bewegt und dabei in bunten Farben leuchtet.',
  array[
    'Reagiert auf Musik und leuchtet dabei in bunten Farben',
    'Ferrofluid formt sich zu tanzenden Mustern im Licht'
  ],
  array[
    'Zu Lautstärke-Empfindlichkeit, Stromversorgung und Maßen liegen uns keine verifizierten Herstellerangaben vor — vor dem Kauf auf der aktuellen Produktseite prüfen'
  ],
  null, null, null,
  'Eine Lampe, die tanzt statt nur zu leuchten — Ferrofluid formt sich im Takt der Musik, dazu wechselnde Farben. Zu technischen Details wie Lautstärke-Empfindlichkeit oder Stromversorgung liegt uns keine verifizierte Herstellerangabe vor.'
),
(
  'lego-pokemon-bisaflor-glurak-turtok-72153',
  '90er-Kinder, die Pokémon erst spielten und dann sammelten — und alle, die die drei Starter der ersten Generation als Deko im Regal wollen.',
  'Wer ein schnelles Bauset für kleine Kinder sucht — das ist ein aufwendiges Set mit vielen Details.',
  'LEGO-Set 72153 mit den drei Starter-Pokémon der ersten Generation — Bisaflor, Glurak und Turtok — als detaillierte Modelle mit Anti-Kipp-Sockeln.',
  array[
    'Alle drei Starter der ersten Pokémon-Generation in einem Set',
    'Detailliert und aufwendig gebaut',
    'Anti-Kipp-Sockel für stabilen Stand im Regal'
  ],
  array[
    'Der Bauaufwand macht es eher etwas für geübte oder ältere LEGO-Bauer als für ganz kleine Kinder',
    'Zu Teilezahl und exakten Maßen liegen uns keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  'Die drei Starter der ersten Pokémon-Generation, als LEGO-Modelle mit Anti-Kipp-Sockel fürs Regal. Aufwendig gebaut, für 90er-Kinder, die Pokémon erst spielten und heute sammeln.'
),
(
  'plaud-note-pro-ki-diktiergeraet',
  'Alle, die viel aufnehmen — Meetings, Interviews, Ideen unterwegs — und die Nachbearbeitung nicht mehr selbst tippen wollen.',
  'Wer nur gelegentlich eine Sprachmemo braucht — dafür reicht die Aufnahme-App im Smartphone.',
  'KI-Diktiergerät mit automatischer Transkription, automatischer Zusammenfassung und einer Aufnahmekapazität von 50 Stunden.',
  array[
    'Transkribiert Aufnahmen automatisch per KI',
    'Erstellt zusätzlich automatische Zusammenfassungen',
    'Bis zu 50 Stunden Aufnahmekapazität'
  ],
  array[
    'Zu Akkulaufzeit, Sprachenumfang und Umgang der KI-Funktionen mit personenbezogenen Aufnahmen liegen uns keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  'Aufnehmen, und die KI macht den Rest: Transkript und Zusammenfassung entstehen automatisch, bis zu 50 Stunden Kapazität. Für alle, die Meetings und Interviews nicht mehr von Hand nachtippen wollen.'
),
(
  'teenage-engineering-tp7-audio-recorder',
  'Sounddesigner, Podcaster und Field-Recording-Enthusiasten, die einen tragbaren Profi-Recorder wollen, der auch als Objekt überzeugt.',
  'Wer nur gelegentlich eine Sprachnotiz aufnehmen will — dafür ist das deutlich zu viel Gerät.',
  'Portabler Profi-Audiorecorder mit drei Line-Ins, USB-C, Bluetooth, Mikrofon und 128 GB internem Speicher, dazu Sofort-Playback direkt am Gerät.',
  array[
    'Drei Line-Ins für professionelle Aufnahmesituationen',
    '128 GB integrierter Speicher laut Produktbeschreibung',
    'Bluetooth und Mikrofon zusätzlich zu den Line-Ins integriert',
    'Sofort-Playback direkt am Gerät ohne Umweg über einen Rechner'
  ],
  array[
    'Für gelegentliche Sprachnotizen ist der Funktionsumfang klar überdimensioniert',
    'Drei Line-Ins und Sofort-Playback richten sich an Nutzer mit konkreten Audio-Workflows'
  ],
  null, null, null,
  'Der Field-Recorder für Sounddesigner, Podcaster und alle, die Aufnahmequalität ernst nehmen. Drei Line-Ins, USB-C, 128 GB Speicher, Sofort-Playback direkt am Gerät. Teenage Engineering baut Geräte, die auch als Objekt überzeugen — TP-7 ist eins davon.'
),
(
  'vivo-x300-ultra-smartphone',
  'Alle, die beim Smartphone-Kauf nicht nach dem Mittelfeld schauen, sondern nach dem technisch maximal Ausgestatteten — vor allem bei der Kamera.',
  'Wer ein kompaktes oder günstiges Smartphone sucht — hier stehen Kamera-Ausstattung und Speicher im Vordergrund, nicht der Preis.',
  'Smartphone mit ZEISS-Triple-Prime-Objektiven, 4K-Video bei bis zu 120 fps, 16 GB RAM, 1 TB Speicher, 2K-ZEISS-Master-Color-Display und 6.600-mAh-Akku.',
  array[
    'ZEISS-Triple-Prime-Objektive für 4K-Video bei bis zu 120 fps',
    '1 TB interner Speicher, 16 GB RAM',
    '2K-ZEISS-Master-Color-Display und 6.600-mAh-Akku',
    'Foto-Kit im Lieferumfang enthalten'
  ],
  array[
    'Der große Speicher und das Foto-Kit richten sich an Nutzer, die den Ausstattungsumfang tatsächlich ausschöpfen',
    'Zu Gewicht und Abmessungen liegen in der Produktquelle keine Angaben vor'
  ],
  null, null, null,
  'Kein Kompromiss-Smartphone, sondern das Maximum: ZEISS-Triple-Kamera, 4K bei 120fps, 1 TB Speicher, 6.600-mAh-Akku. Für alle, die aufgehört haben zu vergleichen und einfach das technisch Beste wollen.'
),
(
  'xgimi-horizon-ultra-4k-projektor',
  'Alle, die ein Heimkino wollen, aber keinen Fernseher — oder einen riesigen Zweitbildschirm fürs Wohnzimmer.',
  'Wer einen klassischen Fernseher ohne Projektor-Aufstellung sucht — Abstand zur Projektionsfläche gehört hier zum Setup.',
  '4K-Projektor mit Dolby Vision, 2.300 ISO Lumen und zwei integrierten 12-Watt-Harman-Kardon-Lautsprechern, Bilddiagonale bis 200 Zoll.',
  array[
    '4K mit Dolby Vision und 2.300 ISO Lumen',
    'Zwei Harman-Kardon-Lautsprecher mit je 12 Watt — kein Soundbar-Zwang',
    'Android TV 11 mit integriertem Netflix, YouTube und Prime Video',
    'Automatischer Fokus und automatische Trapezkorrektur'
  ],
  array[
    'Bis zu 200 Zoll Bilddiagonale brauchen entsprechend Abstand und einen abdunkelbaren Raum',
    'Bei bis zu 200 Zoll Bilddiagonale müssen Abstand und Projektionsfläche zum Raum passen'
  ],
  null, null, null,
  'Ein 4K-Beamer mit Dolby Vision und eingebautem Harman-Kardon-Sound, der ohne Soundbar auskommt. Autofokus, Auto-Trapezkorrektur, bis 200 Zoll Bilddiagonale. Für alle, die ein Heimkino wollen, aber keinen Fernseher.'
),
(
  'khadas-mind-2-mini-pc',
  'Menschen, die einen sehr kompakten Rechner für unterwegs wollen und ihr Setup bei Bedarf über Mind-Family-Module erweitern möchten.',
  'Wer Arbeitsspeicher selbst austauschen oder einen klassischen Desktop mit frei wählbaren Komponenten bauen will.',
  'Khadas Mind 2 als portable Workstation: laut Hersteller 435 g leicht, 2 cm dünn, mit Thunderbolt 4, USB4, HDMI 2.1 und Mind-Link-Schnittstelle für Erweiterungsmodule.',
  array[
    '435 g Gewicht und 2 cm Bauhöhe laut Hersteller',
    'Thunderbolt 4, USB4, HDMI 2.1 und zwei USB-A-3.2-Anschlüsse',
    'Magnetische Abdeckung für den M.2-2230-SSD-Steckplatz',
    'Mind Link verbindet den Rechner mit optionalen Erweiterungsmodulen'
  ],
  array[
    'Der Arbeitsspeicher ist laut Hersteller onboard und nicht austauschbar',
    'Erweiterungen setzen auf separate Mind-Family-Module'
  ],
  null, null, null,
  'Ein Mini-PC, der eher wie ein Baustein für ein modulares Setup gedacht ist: 435 Gramm, zwei Zentimeter dünn, Thunderbolt 4 und Mind Link für Dock, Grafikmodul und weitere Erweiterungen. Für Menschen, die ihren Rechner zwischen Tasche und Schreibtisch bewegen.'
),
(
  'fontastic-mesu-bluetooth-lautsprecher',
  'Alle, die Lautsprecher, Beistelltisch und kabelloses Laden in einem Möbelstück verbinden wollen.',
  'Wer einen kleinen Bluetooth-Lautsprecher für unterwegs sucht — der Mesu ist ein 5,9 kg schwerer Tisch mit 61,5 cm Höhe.',
  'Multifunktionstisch mit TWS-Stereo aus zwei 12-Watt-Lautsprechern, Bluetooth 5, AUX, USB-Wiedergabe, Freisprechfunktion und kabelloser Ladefläche.',
  array[
    'Zwei 12-Watt-Lautsprecher mit TWS-Stereo',
    'Bluetooth 5, AUX-In, USB-Wiedergabe und USB-Ladeanschluss',
    'Kabelloses Laden direkt auf der Tischplatte',
    'Integrierter Akku mit laut Hersteller bis zu 6 Stunden Wiedergabe bei 50 Prozent Lautstärke'
  ],
  array[
    'Mit 61,5 × 39,5 × 38,5 cm und 5,9 kg kein mobiles Lautsprecherformat',
    'Die angegebene Wiedergabezeit von 6 Stunden gilt bei 50 Prozent Lautstärke'
  ],
  null, null, null,
  'Der Mesu ist kein Lautsprecher, den man in den Rucksack steckt, sondern ein Tisch, der Musik, Ladefläche und Ablage zusammenzieht. Zwei 12-Watt-Treiber, TWS und kabelloses Laden — ein Möbelstück für Sofa, Schlafzimmer oder Lounge.'
),
(
  'anker-nano-powerbank-magsafe-5000mah',
  'iPhone-Nutzer mit Qi2- oder MagSafe-kompatiblem Case, die unterwegs ohne Kabel nachladen wollen.',
  'Wer ein nicht-magnetisches oder sehr dickes Case nutzt — dafür ist die magnetische Ausrichtung nicht zuverlässig.',
  'Schlanke magnetische Anker-Powerbank mit 5.000 mAh, Qi2-/MagSafe-kompatibler Wireless-Leistung bis 15 W und USB-C-Ausgang bis 20 W.',
  array[
    '5.000 mAh Kapazität bei etwa 8,6 mm Bauhöhe',
    'Bis zu 15 W kabelloses Laden für kompatible Geräte',
    'USB-C-Ausgang mit bis zu 20 W',
    'Laut Hersteller etwa 102 × 70,6 × 8,6 mm und rund 122 g'
  ],
  array[
    'Magnetische Ausrichtung setzt ein kompatibles Gerät oder Case voraus',
    'Die tatsächliche Ladeleistung hängt laut Hersteller vom Gerät und der Nutzung ab'
  ],
  null, null, null,
  'Die Powerbank für den Moment, in dem das iPhone leer wird, aber das Kabel zu Hause liegt: 5.000 mAh, magnetische Qi2-/MagSafe-Ladung bis 15 Watt und USB-C als Ausweichroute. Schlank genug für die Jackentasche — sofern das Case mitspielt.'
);

-- Ende DRAFT. Kein weiterer Inhalt, keine Transaktion, keine Ausfuehrung.
