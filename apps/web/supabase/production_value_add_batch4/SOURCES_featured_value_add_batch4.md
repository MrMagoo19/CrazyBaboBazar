# Quellen — Featured Value-Add Batch 4 (DRAFT)

Alle Pfade relativ zu `apps/web/supabase/`. Diese Datei ordnet jede Aussage in
`DRAFT_featured_value_add_batch4.sql` einer Repo-Quelle zu. Kein Zugriff auf
Supabase, keine SQL-Ausführung — reine Repo-Recherche.

Angefragt waren 12 Slugs. Für alle 12 liegen jetzt ausreichende Belege vor.
Die drei zunächst fehlenden Produktquellen wurden über offizielle
Herstellerseiten ergänzt und sind unten mit URL dokumentiert.

---

## aarke-wasserkocher-edelstahl-1-2l

- Name, Grundbeschreibung, Edelstahl, mehrere Temperatureinstellungen,
  360°-Sockel, leiser Kochvorgang, tropffreier Ausgießer, 1,2 Liter, Marke
  Aarke (schwedisches Designlabel, baut auch den Carbonator):
  `import_products_batch19.sql` Z. 40–50.
- Konkrete Temperaturwerte (präzise Temperaturkontrolle von 40–100 °C; 70 °C Grüntee, 94 °C Kaffee,
  37 °C Babymilch), "preisgekröntes skandinavisches Design", vier Farben:
  `expand_descriptions_batch3.sql` Z. 31–32.
- Bestehende redaktionelle Einordnung ("Küchen sofort premium aussehen
  lässt", Design-Statement-Charakter) als Ton-Referenz, nicht wörtlich
  übernommen: `add_editorial_notes_batch5.sql` Z. 48–49.

## dji-osmo-pocket-4-kreativ-combo

- Name, Einzoll-Sensor, 4K bis 240 fps, 3-Achsen-Gimbal, 107 GB interner
  Speicher, Kreativ-Combo enthält Mic-3-Sender-Empfänger-Set und Fülllicht,
  Zielgruppe (Reisen/Sport/Content/Familie, Ersatz für verwackelte
  Handy-Videos): `import_products_batch12.sql` Z. 32–44.
- Listenzugehörigkeit als Zusatzkontext (nicht Teil der Payload):
  `production_quality_fixes_20260830/04_apply_quality_fixes.sql` Z. 349, 367
  (Listen `verrueckte-amazon-gadgets`, `witzige-geschenke-maenner`).

## dyson-zone-absolute-kopfhoerer

- Name, Kombigerät Kopfhörer + Luftreiniger, filtert PM2.5/Pollen/Bakterien/
  NO2, kein Schlauch/Clip/Maske, Luft kommt aus dem Bügel, ANC auf
  "Flaggschiff-Niveau", bis 50 Stunden Akku, 11-Treiber-Audiosystem:
  `import_products_batch13.sql` Z. 4–14.
- "Optionaler Luftfilter-Visor fürs Gesicht" als präzisere Formulierung der
  Filter-Mechanik: `expand_descriptions_batch5.sql` Z. 17–18.
- Ton-Referenz "absurdes Gerät, aber auf die einzig richtige Art absurd" aus
  Quelle direkt für editorial_note übernommen: `import_products_batch13.sql`
  Z. 8 (Originaltext), gespiegelt in `add_editorial_notes_batch5.sql` Z. 28.

## ferrofluid-sound-visualizer-lampe

- Name, Kernfakt (reagiert auf Musik, wechselt Farben, "tanzende"
  Ferrofluid-Bewegung): `insert-batch5.sql` Z. 51–59 (Tagline-Spalte).
- Das ist die einzige verfügbare Faktenquelle für dieses Produkt — kein
  Preis, keine Maße, keine Stromversorgung, keine Lautstärke-Empfindlichkeit
  irgendwo im Repo belegt. Das cons-Feld benennt diese Lücke deshalb explizit
  statt eine Angabe zu erfinden.

## lego-pokemon-bisaflor-glurak-turtok-72153

- Setnummer 72153, enthaltene Modelle (Bisaflor, Glurak, Turtok als Starter
  der ersten Generation), "detailliert, aufwendig gebaut", Anti-Kipp-Sockel,
  Zielgruppe 90er-Kinder: `expand_descriptions_batch6.sql` Z. 85–86.
- Redaktionelle Einordnung als Deko-Statement fürs Regal:
  `add_editorial_notes_batch6.sql` Z. 85–86.
- Teilezahl und exakte Maße sind in keiner Quelle beziffert — cons benennt
  das statt zu schätzen.

## plaud-note-pro-ki-diktiergeraet

- Name, Kernfakt (KI-Aufnahmegerät, automatische Transkription, automatische
  Zusammenfassung, 50 Stunden Kapazität): `insert-batch5.sql` Z. 61–69
  (Tagline-Spalte).
- Wie beim Ferrofluid-Produkt ist dies die einzige Faktenquelle im Repo —
  keine Angaben zu Akkulaufzeit, Sprachumfang oder Preis vorhanden. cons
  benennt das explizit.

## teenage-engineering-tp7-audio-recorder

- Name, Kernspezifikation (portabler Profi-Recorder, USB-C-Audio, Bluetooth,
  Mikrofon, 128 GB Speicher): `insert-batch5.sql` Z. 71–79 (Tagline-Spalte).
- Drei Line-Ins, "analog-inspiriertes Design, digitale Aufnahmequalität",
  integrierter Speicher, Sofort-Playback, Zielgruppe (Sounddesigner,
  Podcaster, Field-Recording-Enthusiasten): `expand_descriptions_batch5.sql`
  Z. 8–9.
- Ton-Referenz "Geräte, die auch als Objekt überzeugen":
  `add_editorial_notes_batch5.sql` Z. 10–11.

## vivo-x300-ultra-smartphone

- Name, ZEISS-Triple-Prime-Objektive, 4K-Video bei 120 fps, 16 GB RAM, 1 TB
  Speicher, 2K-ZEISS-Master-Color-Display, 6.600-mAh-Akku, Foto-Kit im
  Lieferumfang, Zielgruppe (maximale Ausstattung statt Mittelfeld):
  `import_products_batch14.sql` Z. 122–132.

## xgimi-horizon-ultra-4k-projektor

- Name, 4K, Dolby Vision, 2.300 ISO Lumen, zwei Harman-Kardon-Lautsprecher
  je 12 W, Android TV 11, optischer Zoom, automatische Trapezkorrektur, kein
  separater Soundbar nötig, Zielgruppe (Heimkino ohne Fernseher):
  `import_products_batch14.sql` Z. 70–80.
- "Integriertes Netflix, YouTube, Prime Video via Android TV", "bis zu 200
  Zoll Bilddiagonale": `expand_descriptions_batch5.sql` Z. 14–15.

---

## khadas-mind-2-mini-pc

- Hersteller-Highlights: 435 g Gewicht, 2 cm Bauhöhe, Thunderbolt 4,
  Mind-Link-Schnittstelle und modulare Erweiterungen:
  [Khadas Mind 2/2s Produktseite](https://www.khadas.com/product-page/mind-2).
- Anschlüsse (Thunderbolt 4, USB4, HDMI 2.1, zwei USB-A 3.2) und magnetische
  SSD-Abdeckung: [Khadas Mind 2/2s Produktseite](https://www.khadas.com/product-page/mind-2).
- Onboard-RAM nicht austauschbar; M.2-2230-Erweiterungsslots:
  [Khadas Support — Mind](https://www.khadas.com/support-mind).

## fontastic-mesu-bluetooth-lautsprecher

- Multifunktionstisch mit TWS-Stereo aus zwei 12-Watt-Lautsprechern,
  Bluetooth 5, AUX, USB, Freisprechfunktion und kabellosem Laden:
  [Fontastic Mesu — Hersteller-Support](https://support.fontastic.eu/multimedia/tisch-lautsprecher-mesu-in-grau).
- Integrierter Akku (2 × 2.500 mAh), bis zu 6 Stunden Wiedergabe bei 50 %,
  Maße 61,5 × 39,5 × 38,5 cm und 5,9 kg:
  [Fontastic Mesu — Hersteller-Support](https://support.fontastic.eu/multimedia/tisch-lautsprecher-mesu-in-grau).

## anker-nano-powerbank-magsafe-5000mah

- 5.000 mAh, Qi2-/MagSafe-kompatible magnetische Wireless-Ladung bis 15 W,
  USB-C bis 20 W, 8,6 mm Bauhöhe und ca. 102 × 70,6 × 8,6 mm:
  [Anker Nano Power Bank 5K — offizieller Anker-Produktdatensatz](https://www.anker.com/ca/products/a1665).
- Kompatibilität mit magnetischen bzw. Qi2-fähigen Geräten und Hinweis, dass
  Ladeleistung vom Gerät abhängt: [Anker Nano Power Bank 5K — offizieller
  Anker-Produktdatensatz](https://www.anker.com/ca/products/a1665).

## Quellenstatus

Alle 12 Zielprodukte haben damit eine dokumentierte Faktenquelle. Für die drei
extern ergänzten Quellen gilt: Die URLs müssen vor einer Production-Ausführung
nochmals auf die konkrete Variante und Lieferbarkeit geprüft werden. Preise
wurden bewusst nicht in den Draft übernommen.

## BLOCKED — Audit-Marker (leer)

Keine aktuellen Blocker. Der Abschnitt bleibt als Audit-Marker erhalten, falls
eine Quelle vor der Production-Ausführung nicht mehr erreichbar ist.
