# RUNBOOK — Value-Add Charge 4 (Production)

> **Status: CHARGE 4 AUSGEFUEHRT UND VERIFIZIERT.**
> Schritte `01` bis `04b` wurden gegen das freigegebene Production-Projekt
> ausgefuehrt und ohne FAIL verifiziert. Schritt `05` wurde nicht ausgefuehrt;
> er ist ausschliesslich fuer einen separat freizugebenden Rollback gedacht.
> Jede schreibende Datei (`02`, `03`, `05`) braucht weiterhin eine eigene
> ausdrueckliche Benutzerfreigabe.

**Zielprojekt (vor JEDEM Schritt sichtbar im SQL-Editor gegenpruefen):**
`project/ydiihvzcxaaoqhmgoqvu` — `https://ydiihvzcxaaoqhmgoqvu.supabase.co`

Pilot/Staging (`nmzuycveumyfvtxdcnuc`) ist **kein** Ziel dieses Changesets.

---

## 1 · Was Charge 4 ist

Die vierte Gruppe Produktseiten — diesmal **zwoelf** statt zehn — bekommt die
Value-Add-Schicht: „Auf einen Blick" (`fuer_wen`, `nicht_fuer`, `key_fact`),
„Pro & Contra" (`pros`, `cons`) und „Unser Urteil" (`editorial_note`).
Strukturierte Relationen (`alternative_slug`, `alternative_reason`,
`alternative_kind`) legt Charge 4 **keine** an — siehe Abschnitt 3.

| | Batch 1 | Batch 2 | Batch 3 | **Batch 4** |
|---|---|---|---|---|
| Zielprodukte | 10 | 10 | 10 | **12** |
| Schema-Migration | ja | nein | nein | **nein** |
| Snapshot | `…_v1` | `…_v2` | `…_v3` | **`…_v4`** |
| Audit-Payload | `…_payload_v1` | `…_payload_v2` | `…_payload_v3` | **`…_payload_v4`** |
| Relationen | — | — | 2 | **0** |
| Value-Add gesamt davor | 0 | 10 | 20 | **30** |
| Value-Add gesamt danach | 10 | 20 | 30 | **42** |

Nach Charge 4 waeren **42 von 372** veroeffentlichten Produkt-URLs mit
Value-Add versorgt (rund 11,3 %).

Der Inhalt der Payload ist der redaktionell freigegebene Draft
`DRAFT_featured_value_add_batch4.sql` aus demselben Verzeichnis, in `03` Zeile
fuer Zeile **wortgleich** uebernommen. Der Draft und
`SOURCES_featured_value_add_batch4.md` bleiben unveraendert erhalten und sind
der Beleg dafuer, was freigegeben wurde.

---

## 2 · Die zwoelf Ziele

Alle zwoelf sind veroeffentlichte Featured-Produkte. Die Quellenzuordnung je
Ziel steht vollstaendig in `SOURCES_featured_value_add_batch4.md`, hier in
Kurzform:

| # | Slug | Faktenbasis |
|---|---|---|
| 1 | `aarke-wasserkocher-edelstahl-1-2l` | `import_products_batch19.sql`, `expand_descriptions_batch3.sql` — Edelstahl, 1,2 l, Temperaturbereich 40–100 °C, 360°-Sockel |
| 2 | `anker-nano-powerbank-magsafe-5000mah` | **externe Herstellerquelle** (Anker-Produktdatensatz) — 5.000 mAh, Qi2/MagSafe bis 15 W, USB-C bis 20 W, Masse |
| 3 | `dji-osmo-pocket-4-kreativ-combo` | `import_products_batch12.sql` — Einzoll-Sensor, 4K/240 fps, 3-Achsen-Gimbal, 107 GB, Combo-Umfang |
| 4 | `dyson-zone-absolute-kopfhoerer` | `import_products_batch13.sql`, `expand_descriptions_batch5.sql` — ANC, Luftfilter-Visor, PM2.5/Pollen/NO2, bis 50 h |
| 5 | `ferrofluid-sound-visualizer-lampe` | `insert-batch5.sql` (Tagline) — reagiert auf Musik, wechselnde Farben. **Einzige Quelle**, Luecken stehen als `con` |
| 6 | `fontastic-mesu-bluetooth-lautsprecher` | **externe Herstellerquelle** (Fontastic-Support) — 2× 12 W TWS, Bluetooth 5, kabelloses Laden, Masse und Gewicht |
| 7 | `khadas-mind-2-mini-pc` | **externe Herstellerquelle** (Khadas-Produktseite und Support) — 435 g, 2 cm, Thunderbolt 4, Mind Link, RAM onboard |
| 8 | `lego-pokemon-bisaflor-glurak-turtok-72153` | `expand_descriptions_batch6.sql`, `add_editorial_notes_batch6.sql` — Setnummer, drei Starter, Anti-Kipp-Sockel |
| 9 | `plaud-note-pro-ki-diktiergeraet` | `insert-batch5.sql` (Tagline) — KI-Transkription, Zusammenfassung, 50 h. **Einzige Quelle**, Luecken stehen als `con` |
| 10 | `teenage-engineering-tp7-audio-recorder` | `insert-batch5.sql`, `expand_descriptions_batch5.sql` — drei Line-Ins, USB-C, Bluetooth, 128 GB, Sofort-Playback |
| 11 | `vivo-x300-ultra-smartphone` | `import_products_batch14.sql` — ZEISS-Triple-Prime, 4K/120 fps, 16 GB RAM, 1 TB, 6.600 mAh |
| 12 | `xgimi-horizon-ultra-4k-projektor` | `import_products_batch14.sql`, `expand_descriptions_batch5.sql` — 4K, Dolby Vision, 2.300 ISO Lumen, 2× 12 W Harman Kardon |

**Disjunktheit:** Keiner dieser zwoelf Slugs steht in Batch 1, 2 oder 3. Das ist
dreifach abgesichert — literal im Preflight (Zeilen 160, 170 und 180), als
Guard in `02` und `03` und statisch beim lokalen Testlauf.

### 2.1 · Offener Punkt vor der Ausfuehrung: die drei externen Quellen

Fuer `anker-nano-powerbank-magsafe-5000mah`,
`fontastic-mesu-bluetooth-lautsprecher` und `khadas-mind-2-mini-pc` gibt es
**keine** Repo-Quelle. Die Fakten stammen aus offiziellen Herstellerseiten, die
URLs stehen in `SOURCES_featured_value_add_batch4.md`.

**Was das fuer den Rollout bedeutet:** Vor der Freigabe von `03` ist je Produkt
noch einmal zu pruefen, ob der hinterlegte Partnerlink auf **dieselbe Variante**
zeigt, die die Herstellerquelle beschreibt. Genau diese Diskrepanz zwischen Link
und Beschreibung hat in Charge 3 den VIVO-Stehpult-Kandidaten gesperrt. Dieser
Abgleich ist **nicht** Teil der SQL-Artefakte — er ist ein eigener, manueller
Schritt und muss vor `03` erledigt sein.

---

## 3 · Keine Relationen — und warum

Charge 4 setzt fuer alle zwoelf Zeilen `alternative_slug`,
`alternative_reason` und `alternative_kind` ausdruecklich auf `NULL`.

**Begruendung:** Die zwoelf Produkte sind thematisch weit gestreut
(Wasserkocher, Kamera, Kopfhoerer, Lampe, LEGO-Set, Diktiergeraet, Recorder,
Smartphone, Beamer, Mini-PC, Moebel-Lautsprecher, Powerbank). Innerhalb dieser
Menge stuetzt keine Quelle eine Aussage der Form „statt X nimm Y" oder
„X ergaenzt Y" eindeutig. Eine Relation ist auf der Produktseite eine sichtbare
Kaufempfehlung — eine geratene Relation waere genau die Art von Behauptung, die
die Content-Regeln ausschliessen.

Die Guards halten das fest statt es nur zu dokumentieren: `03` bricht ab, wenn
nach dem Backfill nicht **0 Alternativen, 0 Ergaenzungen und 12 relationslose
Zeilen** vorliegen. `04` meldet dieselben drei Zahlen als harte PASS-Zeilen und
gibt die Relationsliste als INFO mit dem erwarteten Wert `KEINE` aus.

Die **bestehenden** Relationen aus Charge 3 werden davon nicht beruehrt. `01`
prueft in Zeile 220 trotzdem, dass keine von ihnen ins Leere zeigt — eine
zwischenzeitlich offline genommene Zielseite waere ein Befund, der vor einer
weiteren Charge zu klaeren ist.

---

## 4 · Quellenbindung

Jede Aussage der Payload stammt aus einer dokumentierten Quelle. Keine Aussage
ist erfunden, keine ist aus dem Produktnamen abgeleitet. Die vollstaendige
Zuordnung Aussage -> Quelldatei bzw. Aussage -> Hersteller-URL steht in
`SOURCES_featured_value_add_batch4.md` im selben Verzeichnis. Diese Datei
gehoert zum Changeset und ist bei jeder Pruefung mitzulesen.

**Keine Preise.** Keine Zeile der Payload nennt einen Preis, ein Preisband,
einen Rabatt, eine Verfuegbarkeit, eine Bewertung oder eine
Testsieger-Aussage. Preise erscheinen auf der Seite ausschliesslich als
Preisband aus `price_cents` zur Laufzeit.

---

## 5 · Bewusst ausgelassene Behauptungen

| Ausgelassen | Grund |
|---|---|
| `ferrofluid-sound-visualizer-lampe`: Masse, Stromversorgung, Lautstaerke-Empfindlichkeit | Es gibt dazu **keine** Quelle. Statt zu raten, benennt ein `con` die Luecke ausdruecklich und verweist auf die aktuelle Produktseite. |
| `plaud-note-pro-ki-diktiergeraet`: Akkulaufzeit, Sprachenumfang, Umgang der KI mit personenbezogenen Aufnahmen | Ebenfalls unbelegt. Der Datenschutzaspekt ist bei einem Aufnahmegeraet mit KI-Auswertung zu heikel fuer eine Vermutung — er steht als offene Frage im `con`. |
| `lego-pokemon-bisaflor-glurak-turtok-72153`: Teilezahl, exakte Masse | In keiner Quelle beziffert. Als `con` benannt statt geschaetzt. |
| `vivo-x300-ultra-smartphone`: Gewicht, Abmessungen | In der Produktquelle nicht enthalten. Als `con` benannt. |
| `dji-osmo-pocket-4-kreativ-combo`: Speichererweiterung | Die Quelle nennt 107 GB intern und **keine** Erweiterungsmoeglichkeit. Der `con` sagt genau das — und behauptet nicht, dass eine Erweiterung ausgeschlossen sei. |
| `dyson-zone-absolute-kopfhoerer`: gesundheitliche Wirkung der Luftfilterung | Uebernommen ist ausschliesslich die technische Funktion (filtert PM2.5, Pollen, Bakterien, NO2). Eine Wirkungsaussage auf die Gesundheit waere eine medizinische Behauptung ohne zitierfaehige Quelle. |
| `khadas-mind-2-mini-pc`, `fontastic-mesu-bluetooth-lautsprecher`, `anker-nano-powerbank-magsafe-5000mah`: alles ueber die Herstellerangabe hinaus | Bei den drei extern belegten Produkten ist jede Zahl mit „laut Hersteller" attribuiert, wo sie aus der Herstellerseite stammt. Es gibt keinen eigenen Test. |
| Alle Ziele: Preise, Rabatte, Verfuegbarkeiten, Testsieger-Aussagen, Bewertungen, Garantien | Grundsatzregel des Projekts. |

---

## 6 · Robustheit der Preflight-Pruefung und ihre Grenze

`01_preflight_read_only.sql` prueft die Artefakte von Batch 1, 2 und 3
**ausschliesslich ueber den Systemkatalog** (`to_regclass`, `pg_class`,
`pg_attribute`, `pg_policy`, `pg_constraint`). Es gibt keine direkte Referenz
auf diese Tabellen.

**Warum:** Eine direkte Referenz wuerde bei fehlender Tabelle schon die
*Planung* abbrechen. Es gaebe dann ueberhaupt keinen Report, sondern nur
„relation does not exist". Gewollt ist das Gegenteil: ein kontrollierter
FAIL-Report, der zeigt, **was** fehlt.

**Der Preis:** Die exakte Zeilenzahl der v1-/v2-/v3-Tabellen kann `01` nicht
lesen. Zeile 290 gibt nur die Katalogschaetzung `reltuples` aus — als INFO,
ohne Zusage. Der harte Beleg, dass alle drei Vorgaenger intakt sind, kommt aus
`public.products` (Zeile 190: 30 befuellte Zeilen, davon Batch 1, 2 und 3
jeweils vollstaendig 10).

`public.products` dagegen wird direkt gelesen: fehlt diese Tabelle, bricht die
Planung fail-closed ab. Das ist gewollt — ohne `products` ist der ganze Vorgang
gegenstandslos.

---

## 7 · Ablauf (jeder Schritt einzeln freizugeben)

| Schritt | Datei | Art | Erwartetes Ergebnis |
|---|---|---|---|
| 01 | `01_preflight_read_only.sql` | read-only | **20 PASS, 9 INFO, 0 FAIL** |
| 02 | `02_backup_value_add_batch4.sql` | **schreibend** | `backup_rows = 12` |
| 02b | `02b_verify_snapshot_read_only.sql` | read-only | **17 PASS, 4 INFO, 0 FAIL** |
| 03 | `03_backfill_value_add_batch4.sql` | **schreibend** | leere Ergebnismenge, keine Exception |
| 04 | `04_verify_read_only.sql` | read-only | **16 PASS, 4 INFO, 0 FAIL** |
| 04b | `04b_verify_payload_security_read_only.sql` | read-only | **10 PASS, 7 INFO, 0 FAIL** |
| 05 | `05_restore_value_add_batch4.sql` | **schreibend** | nur im Rollback-Fall |

Bei **irgendeinem FAIL**: nichts korrigieren, nichts nachtragen, nichts
loeschen. Befund melden und Ursache klaeren.

### Production-Preflight-Warnung: `restore_affiliate_urls.sql` nicht ausfuehren

`apps/web/supabase/restore_affiliate_urls.sql` setzt **alle** `affiliate_url`
pauschal auf einen alten Seed-Stand zurueck („VOLLSTAENDIGES RESET").

**Risiko:** Ein Lauf dieser Datei kann falsche oder veraltete Zuordnungen
wiederherstellen — genau die Art von Link-Beschreibungs-Diskrepanz, die in
Charge 3 den VIVO-Stehpult-Kandidaten gesperrt hat. Ein Klick-out zeigte dann
auf ein anderes Produkt als die Seite beschreibt. Fuer die drei extern belegten
Ziele aus Abschnitt 2.1 waere das besonders folgenreich.

**Regel fuer Charge 4:** Diese Datei wird im Rahmen dieses Changesets **nicht**
ausgefuehrt und **nicht** veraendert.

### Fail-closed-Guards im Ueberblick

| Guard | Wirkung |
|---|---|
| Production-Fingerprint | `products`, `page_content`, `discovery_queue`, `swipes` muessen alle existieren |
| Keine Pilot-Artefakte | `pilot_meta.environment_guard`, `pilot_backup.value_add_pre_backfill`, `public.pilot_value_add_backup_20260823` muessen fehlen |
| Bestand | mindestens 300 Produkte |
| Zielmenge | exakt 12, alle `is_published` |
| Relationen | 0 Alternativen, 0 Ergaenzungen, 12 relationslose Zeilen nach dem Backfill |
| Disjunktheit | 0 Ueberschneidungen mit Batch 1, Batch 2 **und** Batch 3 |
| Schema | 8/8 Spalten, 8/8 Typen, 2/2 Constraints — **keine** Migration |
| Vorgaenger | alle sechs v1-/v2-/v3-Artefakte vorhanden, 30 befuellte Zeilen, je 10 vollstaendig |
| Ziel-Value-Add | vorab leer (0 von 12) |
| Bestandszahl | vor dem Backfill exakt **30**, nach dem Backfill exakt **42** |
| Drift | Zielzeilen duerfen sich zwischen 02 und 03 nicht veraendert haben |
| Wiederholung | 02 bricht bei vorhandenem v4-Snapshot ab, 03 bei vorhandener v4-Payload, 05 bei bereits zurueckgespieltem Zustand |
| Zeitgrenzen | `lock_timeout = 5s` und `statement_timeout = 60s` **vor** dem ersten Tabellenzugriff |
| Private Artefakte | RLS an, 0 Policies, keine Rechte fuer `PUBLIC`, `anon`, `authenticated` |
| Inhaltsform | jede der 12 Zeilen 2–4 `pros` und mindestens 1 `con`, `editorial_note` gesetzt |

---

## 8 · Rollback: rein, fail-closed und bewusst NICHT idempotent

`05_restore_value_add_batch4.sql` spielt exakt die zwoelf Zeilen aus dem
Snapshot zurueck — `editorial_note`, `updated_at` und die acht
Value-Add-Felder. Danach sieht Batch 4 aus wie vor Schritt 03.

**Die zwei harten Voraussetzungen.** `05` schreibt nur, wenn beides gilt:

1. `cbb_private_backup.value_add_payload_v4` existiert und traegt zwoelf
   Zeilen. Ohne die Payload gibt es keinen belegten Nachzustand — dann bricht
   `05` ab, statt zu raten.
2. Alle zwoelf Zielzeilen stehen feldgleich zur Payload v4, also exakt im
   Zustand nach `03`.

Trifft eines von beidem nicht zu, wird **nichts geschrieben**. Damit ist
ausgeschlossen, dass `05` einen anderen als den von `03` erzeugten Zustand
ueberschreibt — etwa eine spaetere redaktionelle Ueberarbeitung derselben
Zeilen.

**Unterschied zu Batch 3:** Dort war `05` idempotent, ein zweiter Lauf war
folgenlos. Hier bricht der zweite Lauf ab, weil die Zeilen nach dem ersten
Rollback im Snapshot- und nicht mehr im Payload-Zustand stehen. Dieser Fall
bekommt eine eigene, eindeutige Meldung („bereits zurueckgespielt — alle 12
Zielzeilen stehen schon im Snapshot-Zustand"), damit er nicht mit einem
Fremdzugriff verwechselt wird. Auch dieser Ausgang schreibt nichts.

`updated_at` ist bewusst **nicht** Teil des Payload-Vergleichs: `03` setzt dort
`now()`, der Wert ist nicht vorhersagbar. Der historische Zeitstempel kommt
beim Zurueckspielen aus dem Snapshot. Der Trigger `products_set_updated_at`
ueberschreibt ein ausdruecklich mitgeschriebenes `updated_at` nicht — genau
darauf stuetzt sich das Zurueckspielen.

**Was 05 nicht tut:** Snapshot und Payload werden **nicht** geloescht. Beide
bleiben fuer das Beobachtungsfenster erhalten und sind Voraussetzung fuer einen
nachvollziehbaren Befund. Batch 1, 2 und 3 werden nicht angefasst. Es gibt
bewusst **keine** Down-Migration — die acht Spalten und die zwei Constraints
tragen die drei Vorgaengerchargen.

**Die bewusste Grenze:** Der Rollback prueft ausschliesslich seine eigenen
zwoelf Zeilen. Er zaehlt **nicht**, wie viele Produkte insgesamt Value-Add
tragen. Grund: eine spaetere Charge 5 wuerde diese Zahl veraendern und damit
einen dringend noetigen Rollback von Batch 4 blockieren. Ein Rollback darf nie
an einem Zustand scheitern, den er gar nicht anfasst. Aus demselben Grund
verlangt der Guard die v1-/v2-/v3-Artefakte nur als **Existenz** und prueft
ihren Inhalt nicht.

---

## 9 · Lokaler Test

Dieses Verzeichnis bringt **keinen** eigenen PostgreSQL-Harness mit. Codex hat
die sieben SQL-Dateien grundlegend statisch geprüft (Zielzählungen, Quote-
Parität, Produktionsziel, v4-Namen, 30→42-Guards und Read-only-/Write-Hinweise).
Der vollständige Harness aus
`../production_value_add_batch3/test/run_local_postgres_test.sh` wurde für
Batch 4 **nicht** ausgeführt. Die folgenden Punkte sind deshalb die noch
abzugleichende Checkliste für einen separaten lokalen Harness-Lauf:

- `SET LOCAL`-Position und `begin`/`commit`-Paarigkeit der drei schreibenden
  Dateien (`02`, `03`, `05`)
- Write-Safety der drei schreibenden Dateien: kein `DROP`, `TRUNCATE` oder
  `DELETE` ausserhalb von Kommentaren — einzige Ausnahme ist das
  `on commit drop` der temporaeren Payload-Tabelle in `03` — und jede
  v1-/v2-/v3-Referenz ausschliesslich innerhalb von `to_regclass()`
- Read-only-Reinheit der vier lesenden Dateien (`01`, `02b`, `04`, `04b`):
  genau ein Semikolon, keine schreibenden Schluesselwoerter, kein DO-Block
- Vollstaendigkeit der zwoelf Zielslugs in den sechs zielbezogenen Dateien
  (`01`, `02`, `02b`, `03`, `04`, `05`). `04b` prueft ausschliesslich die
  Sicherheit der privaten Payload-Tabelle und fuehrt die Zielslugs deshalb
  bewusst nicht literal auf.
- statische Disjunktheit gegen die dreissig Vorgaengerslugs
- Nennung des Production-Ziels in jeder Datei und in diesem Runbook
- wortgleiche Uebernahme der zwoelf Payload-Zeilen aus
  `DRAFT_featured_value_add_batch4.sql` nach `03`

**Nicht geprueft und ausdruecklich offen:** Es gab **keinen** Lauf gegen einen
PostgreSQL-Cluster. Happy Path, Doppelausfuehrung, Drift, Transaktions-Rollback
mitten in `03`, Restore-Verhalten, Rechte-Loecher und das Lock-Timeout-Verhalten
sind fuer Charge 4 **nicht** dynamisch nachgewiesen. Wer diesen Nachweis
braucht, baut den Harness aus `../production_value_add_batch3/test/` fuer die
v4-Artefakte und die zwoelf Zielslugs nach. Das ist ein eigener, getrennt
freizugebender Vorgang und war nicht Teil dieses Auftrags.

---

## 10 · Ausfuehrungsprotokoll

| Datum | Schritt | Ziel | Ergebnis |
|---|---|---|---|
| 2026-08-31 | 01 | Production `ydiihvzcxaaoqhmgoqvu` | **20 PASS, 9 INFO, 0 FAIL** |
| 2026-08-31 | 02 | Production `ydiihvzcxaaoqhmgoqvu` | Snapshot v4 angelegt; durch 02b mit **12 Zeilen** verifiziert |
| 2026-08-31 | 02b | Production `ydiihvzcxaaoqhmgoqvu` | **17 PASS, 4 INFO, 0 FAIL** |
| 2026-08-31 | 03 | Production `ydiihvzcxaaoqhmgoqvu` | Backfill erfolgreich; durch 04 mit **42 Value-Add-Einträgen** verifiziert |
| 2026-08-31 | 04 | Production `ydiihvzcxaaoqhmgoqvu` | **16 PASS, 4 INFO, 0 FAIL** |
| 2026-08-31 | 04b | Production `ydiihvzcxaaoqhmgoqvu` | **10 PASS, 7 INFO, 0 FAIL** |

## 11 · Nachaudit 2026-09-12

Der lokale Codex-Nachaudit hat die zehn Dateien vor ihrer ersten
Git-Versionierung erneut statisch geprueft. Ergebnis und Grenzen stehen in
`AUDIT-2026-09-12.md`.

Dabei wurde die Checkliste in Abschnitt 9 praezisiert: `04b` ist eine reine
ACL-/RLS-Pruefung der privaten Payload-Tabelle und enthaelt daher keine
Zielslug-Liste. Die uebrigen sechs zielbezogenen SQL-Dateien enthalten alle
zwoelf Slugs. Diese Dokumentationskorrektur veraendert keine SQL-Datei und
keinen Production-Zustand.
