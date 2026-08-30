# RUNBOOK — Value-Add Charge 3 (Production)

> **Status: NICHT AUSGEFUEHRT. Production-Hold aktiv.**
> Kein Artefakt dieses Verzeichnisses wurde gegen eine Datenbank ausgefuehrt —
> weder gegen Production noch gegen Pilot/Staging. Die Ausfuehrung ist ohne
> **neue, ausdrueckliche Benutzerfreigabe** untersagt.

**Zielprojekt (vor JEDEM Schritt sichtbar im SQL-Editor gegenpruefen):**
`project/ydiihvzcxaaoqhmgoqvu` — `https://ydiihvzcxaaoqhmgoqvu.supabase.co`

Pilot/Staging (`nmzuycveumyfvtxdcnuc`) ist **kein** Ziel dieses Changesets.

---

## 1 · Was Charge 3 ist

Die dritte Zehnergruppe Produktseiten bekommt die Value-Add-Schicht: „Auf einen
Blick" (`fuer_wen`, `nicht_fuer`, `key_fact`), „Pro & Contra" (`pros`, `cons`),
„Unser Urteil" (`editorial_note`) und in zwei Faellen eine strukturierte
Relation (`alternative_slug`, `alternative_reason`, `alternative_kind`).

| | Batch 1 | Batch 2 | **Batch 3** |
|---|---|---|---|
| Zielprodukte | 10 | 10 | **10** |
| Schema-Migration | ja | nein | **nein** |
| Snapshot | `…_v1` | `…_v2` | **`…_v3`** |
| Audit-Payload | `…_payload_v1` | `…_payload_v2` | **`…_payload_v3`** |
| Value-Add gesamt danach | 10 | 20 | **30** |

Nach Charge 3 waeren **30 von 372** veroeffentlichten Produkt-URLs mit
Value-Add versorgt (rund 8,1 %).

---

## 2 · Die zehn Ziele und warum genau diese

**Quelle der Auswahl:** die feste 30-URL-Kohorte „Produkte mit hohem
strategischem Wert" aus
`raw/seo/search-console/2026-08-26/indexation-diagnostic.md`, Abschnitt 5 (Money
Wiki). Diese Kohorte ist read-only URL-genau geprueft
(`cohort-30-monitoring.md`, 30/30 „Gecrawlt – zurzeit nicht indexiert").

Von den 30 Kohorten-URLs sind **13 bereits versorgt** (4 aus Batch 1, 9 aus
Batch 2). Es bleiben **17 Kandidaten**. Aus ihnen sind diese zehn gewaehlt:

| # | Slug | Warum |
|---|---|---|
| 1 | `bartesian-cocktailmaschine-mit-kapseln` | Sehr konkrete, in mehreren Repo-Quellen uebereinstimmende Funktionsbeschreibung (Kapselsystem, Sirupe und Bitters in der Kapsel, Spirituosen separat). Ersetzt den gesperrten VIVO-Kandidaten, siehe Abschnitt 2.1. Kein Relationsziel. |
| 2 | `dicmky-hoehenverstellbarer-schreibtisch-aufsatz` | Nachruestloesung fuer den vorhandenen Tisch, gut belegt. Quelle der **alternative** auf 3. Die widerspruechlichen Traglastwerte 10/15 kg werden nicht als Kaufbehauptung uebernommen — die Payload nennt gar keinen Wert. |
| 3 | `laptop-staender-hoehenverstellbar-360-drehbar` | Klare Spezifikationen (Aluminium, 360 Grad, bis 17 Zoll). Ziel der **alternative** von 2 und gleichzeitig Quelle des **complement** auf 4. |
| 4 | `tecknet-ergonomische-kabellose-maus-bluetooth` | Drei belegte DPI-Stufen, USB-C, Multi-Device. Relationsziel. |
| 5 | `rocketbook-wiederverwendbares-notizbuch-a4` | Sehr konkrete, ueberpruefbare Funktionsbeschreibung inklusive Ziel-Dienste. |
| 6 | `ticktime-tk3-wuerfel-timer-countdown` | Sechs feste Zeiten 3–60 Minuten, Vibration und Ton — praezise Fakten, starker Haken. |
| 7 | `kabeltasche-edc-elektronik-organizer-reise` | Vollstaendige Fachliste im Repo belegt. |
| 8 | `silikon-magnete-airfryer-backpapier-4er-set` | Loest ein scharf umrissenes Problem, 240 °C und 4er-Set belegt. |
| 9 | `tre-feuerstahl-xxl` | 12 cm, Magnesium-Legierung, Herstellerangabe zu Zuendungen — sauber attribuierbar. |
| 10 | `bbq-wuerstchenhalter-maennchen-3er-set` | Edelstahl, spuelmaschinenfest, sechs Wuerstchen — belegt, und ein Gag mit klarer Grenze. |

**Disjunktheit:** Keiner dieser zehn Slugs steht in Batch 1 oder Batch 2. Das
ist dreifach abgesichert — statisch im Harness (`disjunkt_b3_gegen_b1_b2`),
literal im Preflight (Zeilen 150 und 160) und als Guard in `02` und `03`.

### Bewusst NICHT gewaehlt — und warum

| Kandidat | Grund |
|---|---|
| `bite-away-two-elektronischer-insektenstichheiler` | Die vorhandene Repo-Beschreibung stuetzt sich auf eine Wirkungsaussage („wissenschaftlich belegte Wirkung gegen Juckreiz"). Eine gesundheitsbezogene Behauptung ohne eigene, zitierfaehige Quelle verstoesst gegen die Content-Regeln. Ohne diese Aussage bliebe zu wenig Substanz. |
| `powerball-gyro-handtrainer-original` | Die tragende Nutzenaussage der Repo-Quelle ist eine Reha-Behauptung („Reha nach Handgelenks-Verletzung", „verspannte Sehnen mobilisieren"). Ohne sie bliebe zu wenig Substanz, mit ihr waere es eine gesundheitsbezogene Aussage ohne zitierfaehige Quelle. |
| `huzzle-cast-news-metall-knobelpuzzle` | Widerspruch im Schwierigkeitsgrad: `expand_descriptions_batch1.sql` nennt **4/6**, `add_editorial_notes_batch6.sql` **Level 6**. Ohne Klaerung waere jede der beiden Zahlen geraten. |
| `vivo-hoehenverstellbares-stehpult` | **AUSGESCHLOSSEN — Produktidentitaetskonflikt, siehe Abschnitt 2.1.** War in der ersten Fassung dieses Changesets Ziel Nr. 1 und Relationsziel. Steht seitdem in **keiner** ausfuehrbaren Ziel- oder Relationsmenge dieses Verzeichnisses mehr. |
| `faelnk-toilettengolf-set`, `prisma-brille-lazy-glasses`, `cbdywvr-2in1-ladekabel-mit-staender` | Fachlich unproblematisch und belegt, aber geringere Faktendichte oder kein tragfaehiger Relationspartner innerhalb dieser Zehnergruppe. Bleiben Kandidaten fuer Charge 4. |

### 2.1 · Finding: `vivo-hoehenverstellbares-stehpult` ist gesperrt

**Befund (unabhaengig gegen Production `ydiihvzcxaaoqhmgoqvu` belegt):** Der
aktuell hinterlegte Merchant-Link fuehrt auf einen **gasgefederten
VIVO-Schreibtischaufsatz** (ASIN `B075JYG2TB`). Die Beschreibung in Datenbank
und Repo beschreibt jedoch teilweise einen **elektrischen Volltisch** mit
Memory-Positionen und 60 kg Traglast. Das sind zwei verschiedene Produkte.

**Warum das ein Ausschluss ist und keine Payload-Frage:** Eine Value-Add-Schicht
beschreibt „fuer wen", „nicht fuer" und „Pro & Contra" eines Produkts. Wenn
unklar ist, **welches** Produkt am Ende des Partnerlinks steht, ist jede dieser
Aussagen ein Ratespiel — auch eine bewusst vage. Die urspruengliche Fassung hat
versucht, das mit einer „belegten Schnittmenge" zu loesen; das war der falsche
Weg, weil es den Identitaetskonflikt kaschiert statt ihn zu melden.

**Konsequenz fuer dieses Changeset:** `vivo-hoehenverstellbares-stehpult` ist
vollstaendig entfernt — aus Zielmenge, Relationen, Payload, Snapshot, Restore,
Fixtures und Testfaellen. Es kommt nur noch in dieser Finding-Dokumentation vor.
Ersatz ist `bartesian-cocktailmaschine-mit-kapseln` (Ziel Nr. 1). Die Zielmenge
bleibt bei genau **10 disjunkten** Slugs, Batch 1 und Batch 2 sind unberuehrt.

**Offen und NICHT Teil dieses Changesets:** Ob Link oder Beschreibung falsch
ist, muss getrennt geklaert und korrigiert werden. Bis dahin ist auch die
bestehende Produktseite betroffen — dieses Changeset macht sie weder besser
noch schlechter, es fuegt ihr nur nichts hinzu.

---

## 3 · Die zwei Relationen

```
dicmky-hoehenverstellbarer-schreibtisch-aufsatz
    --> laptop-staender-hoehenverstellbar-360-drehbar  kind = alternative

laptop-staender-hoehenverstellbar-360-drehbar
    --> tecknet-ergonomische-kabellose-maus-bluetooth  kind = complement
```

Beide **Ziele** liegen innerhalb der Batch-3-Zielmenge. Damit ist die Relation
vollstaendig aus derselben, bereits bestaetigten Menge guardbar — es kann keine
Relation auf ein Produkt zeigen, dessen Zustand dieses Changeset nicht prueft.

**Sachliche Begruendung der `alternative`:** Der DICMKY-Aufsatz hebt den
**gesamten Arbeitsplatz** auf Stehhoehe und belegt dafuer dauerhaft
Tischflaeche. Der Laptop-Staender hebt **nur den Bildschirm** und ist kompakt.
Wer wenig Platz hat oder ohnehin nur am Laptop arbeitet, ist mit dem Staender
besser bedient — das ist die klassische Alternative, nicht die Ergaenzung.

**Es ist eine Kette, kein Kreis:**

```
dicmky --alternative--> laptop-staender --complement--> tecknet
```

`laptop-staender` ist gleichzeitig **Ziel und Quelle**. Das ist zulaessig: Die
Produktseite folgt der Relation genau einen Schritt weit. Ein Kreis entstuende
erst, wenn das **Ende** der Kette zurueckzeigte — deshalb bleibt
`tecknet-ergonomische-kabellose-maus-bluetooth` bewusst relationslos. `03` und
`04` pruefen genau das (`ziele_relationslos = 1`, Zeile
`kettenende_bleibt_relationslos`).

Die uebrigen acht Zeilen bekommen `alternative_slug`, `alternative_reason` und
`alternative_kind` ausdruecklich `NULL`.

---

## 4 · Quellenbindung

Jede Aussage der Payload stammt aus vorhandenen Repo-Quellen. Keine Aussage ist
erfunden, keine ist aus dem Produktnamen abgeleitet.

| Ziel | Quelldateien unter `apps/web/supabase/` | Uebernommene Fakten |
|---|---|---|
| `bartesian-cocktailmaschine-mit-kapseln` | `import_products_batch19.sql`, `expand_descriptions_batch3.sql`, `add_editorial_notes_batch5.sql`, `lib/guides/beste-kuechen-gadgets-2026.ts` | Kapselsystem nach Vorbild einer Kaffeemaschine, Kapseln enthalten Sirupe und Bitters, Spirituosen kommen aus eigenen Flaschen, genannte Cocktails Old Fashioned, Espresso Martini, Margarita, ueber 40 Varianten, vorportionierte Kapseln |
| `dicmky-hoehenverstellbarer-schreibtisch-aufsatz` | `products_seo_descriptions.sql`, `products_update.sql`, `expand_descriptions_batch8.sql`, `add_editorial_notes_batch5.sql` | belastbare Schnittmenge: hoehenverstellbarer Aufsatz fuer Monitor oder Laptop, vorhandener Tisch bleibt; **gar keine** Traglastangabe wegen des 10/15-kg-Konflikts |
| `laptop-staender-hoehenverstellbar-360-drehbar` | `expand_descriptions_batch5.sql`, `add_editorial_notes_batch1.sql` | hoehenverstellbar, 360 Grad drehbar fuer Video-Calls und Screen-Sharing, Aluminium, bis 17 Zoll |
| `tecknet-ergonomische-kabellose-maus-bluetooth` | `expand_descriptions_batch4.sql`, `add_editorial_notes_batch8.sql`, `products_update.sql` | vertikale Handhaltung, DPI-Stufen 800/1200/1600, geraeuscharmes Klicken, USB-C-Ladung, mehrere Geraete |
| `rocketbook-wiederverwendbares-notizbuch-a4` | `expand_descriptions_batch4.sql`, `add_editorial_notes_batch6.sql` | A4, Frixion-Stifte, mit feuchtem Tuch loeschbar, per App an Google Drive, Dropbox, Evernote oder Slack |
| `ticktime-tk3-wuerfel-timer-countdown` | `products_seo_descriptions.sql`, `products_update.sql` | sechs Seiten mit voreingestellten Zeiten von 3 bis 60 Minuten, Countdown startet automatisch, Vibrations- und Tonalarm, keine App |
| `kabeltasche-edc-elektronik-organizer-reise` | `expand_descriptions_batch9.sql`, `add_editorial_notes_batch8.sql` | Faecher fuer Ladegeraet, Kabel, USB-Sticks, SD-Karten, Powerbank und Adapter, Nylon, wasserabweisend, Netz-Slots |
| `silikon-magnete-airfryer-backpapier-4er-set` | `expand_descriptions_batch8.sql`, `add_editorial_notes_batch5.sql` | 4er-Set, haelt das Papier am Rand fest, hitzebestaendig bis 240 °C, wiederverwendbar, spuelmaschinenfest |
| `tre-feuerstahl-xxl` | `expand_descriptions_batch2.sql`, `add_editorial_notes_batch3.sql` | 12 cm Laenge, Magnesium-Legierung mit Schaber, funktioniert bei Regen, Kaelte und nasser Kleidung, laut Hersteller ueber 10.000 Zuendungen |
| `bbq-wuerstchenhalter-maennchen-3er-set` | `expand_descriptions_batch7.sql`, `add_editorial_notes_batch7.sql` | 3er-Set aus Edelstahl, sechs Wuerstchen stehend, spuelmaschinenfest, hitzebestaendig |

---

## 5 · Bewusst ausgelassene Behauptungen

Diese Aussagen stehen zwar in Repo-Quellen, sind aber **nicht** in die Payload
uebernommen worden:

| Ausgelassen | Grund |
|---|---|
| `dicmky`: konkrete Traglast | **Quellenkonflikt:** `products_seo_descriptions.sql` nennt **10 kg**, `expand_descriptions_batch8.sql` nennt **15 kg**. Die Payload nennt **keinen** der beiden Werte — auch nicht als „widerspruechliche Repo-Angabe". `nicht_fuer`, `cons` und `editorial_note` sagen statt dessen ausdruecklich, dass uns keine gesicherte Angabe vorliegt und die aktuelle Herstellerangabe vor dem Kauf zu pruefen ist. Der Konflikt selbst gehoert hierher ins Runbook, nicht auf die Produktseite. |
| `bartesian`: „Barqualitaet ohne Barkeeper" | Steht als Tagline in `import_products_batch19.sql` und sinngemaess in `add_editorial_notes_batch5.sql`. Das ist eine Qualitaetsbehauptung ohne Beleg und ohne Pruefmoeglichkeit — sie wird nicht in die Payload uebernommen. |
| `bartesian`: „vier Staerkeoptionen", „vier Spirituosen gleichzeitig befuellbar" | Steht ausschliesslich in der **alten** Beschreibung aus `import_products_batch19.sql`, die spaeter durch `expand_descriptions_batch3.sql` ersetzt wurde. Der aktuelle Produktionsstand enthaelt diese Angaben nicht — sie werden deshalb nicht uebernommen. |
| `bartesian`: alles zu Alkoholwirkung, Genuss, Geselligkeit oder „echtem Cocktail" als Qualitaetsurteil | Weder belegbar noch angemessen. Die Payload beschreibt ausschliesslich die Funktionsweise und die Folgekosten. |
| `tecknet`: „reduziert Belastung auf Handgelenk und Unterarm", „fuer Menschen mit Karpaltunnel-Symptomen" | Gesundheitsbezogene Wirkungsaussage ohne zitierfaehige Quelle. Uebernommen wurde nur die neutrale Bauform „vertikale Handhaltung". |
| `laptop-staender`: „hitzeleitend (Kuehlung)" | Der Kuehleffekt ist eine Wirkungsbehauptung ohne Messwert. Uebernommen wurde nur das Material „Aluminium". |
| `laptop-staender`: „kein Nackenschmerz mehr", „dein Nacken schmerzt abends nicht mehr" | Gesundheitsversprechen. In der `editorial_note` steht stattdessen die neutrale Formulierung „der Nacken bleibt gerade" als Beschreibung der Koerperhaltung, nicht als Heilversprechen. |
| `tre-feuerstahl`: „ueber 10.000 Zuendungen" **ohne** Attribution | Uebernommen ausschliesslich mit dem Zusatz „laut Hersteller" — in `key_fact`, in einem `pro` und in der `editorial_note`. Zusaetzlich steht die fehlende eigene Pruefung ausdruecklich als `con`. |
| `kabeltasche`: konkrete Masse | Es gibt keine. Statt zu raten, steht die Luecke ausdruecklich als `con` („keine verifizierten Herstellerangaben"). |
| Alle Ziele: Preise, Rabatte, Verfuegbarkeiten, Testsieger-Aussagen, Bewertungen, Garantien | Grundsatzregel des Projekts. Preise erscheinen ausschliesslich als Preisband, und zwar aus `price_cents` zur Laufzeit, nie in dieser Payload. |

---

## 6 · Robustheit der Preflight-Pruefung und ihre Grenze

`01_preflight_read_only.sql` prueft die Artefakte von Batch 1 und Batch 2
**ausschliesslich ueber den Systemkatalog** (`to_regclass`, `pg_class`,
`pg_attribute`, `pg_policy`, `pg_constraint`). Es gibt keine direkte Referenz
auf diese Tabellen.

**Warum:** Eine direkte Referenz wuerde bei fehlender Tabelle schon die
*Planung* abbrechen. Es gaebe dann ueberhaupt keinen Report, sondern nur
„relation does not exist". Gewollt ist das Gegenteil: ein kontrollierter
FAIL-Report, der zeigt, **was** fehlt.

**Der Preis:** Die exakte Zeilenzahl der v1-/v2-Tabellen kann `01` nicht lesen.
Zeile 270 gibt nur die Katalogschaetzung `reltuples` aus — als INFO, ohne
Zusage. Der harte Beleg, dass beide Vorgaenger intakt sind, kommt aus
`public.products` (Zeile 170: 20 befuellte Zeilen, davon Batch 1 vollstaendig
10 und Batch 2 vollstaendig 10).

`public.products` dagegen wird direkt gelesen: fehlt diese Tabelle, bricht die
Planung fail-closed ab. Das ist gewollt — ohne `products` ist der ganze Vorgang
gegenstandslos.

---

## 7 · Ablauf (jeder Schritt einzeln freizugeben)

| Schritt | Datei | Art | Erwartetes Ergebnis |
|---|---|---|---|
| 01 | `01_preflight_read_only.sql` | read-only | **18 PASS, 9 INFO, 0 FAIL** |
| 02 | `02_backup_value_add_batch3.sql` | **schreibend** | `backup_rows = 10` |
| 02b | `02b_verify_snapshot_read_only.sql` | read-only | **17 PASS, 4 INFO, 0 FAIL** |
| 03 | `03_backfill_value_add_batch3.sql` | **schreibend** | leere Ergebnismenge, keine Exception |
| 04 | `04_verify_read_only.sql` | read-only | **17 PASS, 4 INFO, 0 FAIL** |
| 04b | `04b_verify_payload_security_read_only.sql` | read-only | **10 PASS, 7 INFO, 0 FAIL** |
| 05 | `05_restore_value_add_batch3.sql` | **schreibend** | nur im Rollback-Fall |

Bei **irgendeinem FAIL**: nichts korrigieren, nichts nachtragen, nichts
loeschen. Befund melden und Ursache klaeren.

### Production-Preflight-Warnung: `restore_affiliate_urls.sql` nicht ausfuehren

`apps/web/supabase/restore_affiliate_urls.sql` setzt **alle** `affiliate_url`
pauschal auf einen alten Seed-Stand zurueck („VOLLSTAENDIGES RESET"). Die Datei
enthaelt unter anderem feste Ziele fuer
`vivo-hoehenverstellbares-stehpult` (Zeile 76) und
`dicmky-hoehenverstellbarer-schreibtisch-aufsatz` (Zeile 74).

**Risiko:** Ein Lauf dieser Datei kann falsche oder veraltete Zuordnungen
wiederherstellen — genau die Art von Link-Beschreibungs-Diskrepanz, die den
VIVO-Kandidaten gesperrt hat (Abschnitt 2.1). Ein Klick-out zeigte dann auf ein
anderes Produkt als die Seite beschreibt.

**Regel fuer Charge 3:** Diese Datei wird im Rahmen dieses Changesets **nicht**
ausgefuehrt und **nicht** veraendert. Wer sie jemals wieder anfassen will,
klaert vorher Zeile fuer Zeile, ob das Ziel noch zum beschriebenen Produkt
passt. Das ist ein eigener, getrennt freizugebender Vorgang.

### Fail-closed-Guards im Ueberblick

| Guard | Wirkung |
|---|---|
| Production-Fingerprint | `products`, `page_content`, `discovery_queue`, `swipes` muessen alle existieren |
| Keine Pilot-Artefakte | `pilot_meta.environment_guard`, `pilot_backup.value_add_pre_backfill`, `public.pilot_value_add_backup_20260823` muessen fehlen |
| Bestand | mindestens 300 Produkte |
| Zielmenge | exakt 10, alle `is_published` |
| Relationsziele | beide published, beide innerhalb der Zielmenge |
| Disjunktheit | 0 Ueberschneidungen mit Batch 1 **und** Batch 2 |
| Schema | 8/8 Spalten, 8/8 Typen, 2/2 Constraints — **keine** Migration |
| Vorgaenger | alle vier v1-/v2-Artefakte vorhanden, 20 befuellte Zeilen, je 10 vollstaendig |
| Ziel-Value-Add | vorab leer (0 von 10) |
| Drift | Zielzeilen duerfen sich zwischen 02 und 03 nicht veraendert haben |
| Wiederholung | 02 bricht bei vorhandenem v3-Snapshot ab, 03 bei vorhandener v3-Payload |
| Zeitgrenzen | `lock_timeout = 5s` und `statement_timeout = 60s` **vor** dem ersten Tabellenzugriff |
| Private Artefakte | RLS an, 0 Policies, keine Rechte fuer `PUBLIC`, `anon`, `authenticated` |

---

## 8 · Rollback und seine bewusste Grenze

`05_restore_value_add_batch3.sql` spielt exakt die zehn Zeilen aus dem Snapshot
zurueck — `editorial_note`, `updated_at` und die acht Value-Add-Felder. Danach
sieht Batch 3 aus wie vor Schritt 03.

**Was 05 nicht tut:** Snapshot und Payload werden **nicht** geloescht. Beide
bleiben fuer das Beobachtungsfenster erhalten und sind Voraussetzung fuer einen
nachvollziehbaren Befund. Batch 1 und Batch 2 werden nicht angefasst. Es gibt
bewusst **keine** Down-Migration — die acht Spalten und die zwei Constraints
tragen die beiden Vorgaengerchargen.

**Die bewusste Grenze:** Der Rollback prueft ausschliesslich seine eigenen zehn
Zeilen. Er zaehlt **nicht**, wie viele Produkte insgesamt Value-Add tragen.
Grund: eine spaetere Charge 4 wuerde diese Zahl veraendern und damit einen
dringend noetigen Rollback von Batch 3 blockieren. Ein Rollback darf nie an
einem Zustand scheitern, den er gar nicht anfasst.

Aus demselben Grund verlangt der Guard die v1-/v2-Artefakte nur als **Existenz**
und prueft ihren Inhalt nicht.

`05` ist idempotent: ein zweiter Lauf aendert nach dem ersten erfolgreichen
Durchgang nichts mehr. Der Trigger `products_set_updated_at` ueberschreibt ein
ausdruecklich mitgeschriebenes `updated_at` nicht — genau darauf stuetzt sich
das Zurueckspielen der historischen Zeitstempel.

---

## 9 · Lokaler Test

`test/run_local_postgres_test.sh`, zweistufig:

**Stufe 1 (CASE 0, ohne Datenbank)**

- `sha256sum -c V1_V2_MANIFEST.sha256` — **74 Dateien** byte-identisch: alle 73
  Dateien der Changesets von Batch 1 und Batch 2 plus der gemeinsam genutzte
  `seo_updated_at_trigger.sql`. Damit ist belegt, dass Charge 3 kein einziges
  Vorgaenger-Artefakt im Repository angefasst hat.
- `SET LOCAL`-Position und `begin`/`commit`-Paarigkeit der drei schreibenden
  Dateien
- Read-only-Reinheit der vier lesenden Dateien (genau ein Semikolon, keine
  schreibenden Schluesselwoerter, kein DO-Block)
- Write-Safety der drei schreibenden Dateien: kein `DROP`, `TRUNCATE` oder
  `DELETE`, und jede v1-/v2-Referenz ausschliesslich innerhalb von
  `to_regclass()`
- Vollstaendigkeit der zehn Zielslugs in jeder Datei
- statische Disjunktheit gegen die zwanzig Vorgaengerslugs
- Nennung des Production-Ziels in jeder Datei und im Runbook

**Stufe 2 (Datenbankfaelle)** faehrt gegen einen eigenen, wegwerfbaren Cluster
ohne TCP-Port: Happy Path, Doppelausfuehrung, Drift, Transaktions-Rollback
mitten in 03, Restore-Roundtrip, Pilot-Marker, Bestand unter 300,
unvollstaendiges Schema, offline genommenes Relationsziel, fremdbefuellte
Zielzeile, fehlendes Vorgaenger-Artefakt, zwei Rechte-Loecher (Snapshot und
Payload) und das Lock-Timeout-Verhalten.

Fehlen die PostgreSQL-Binaries, meldet der Harness das klar, gibt Stufe 1
vollstaendig aus und endet mit **Exit 2** — ausdruecklich weder PASS noch FAIL
der Rollout-Dateien.

Der aktuelle Testbericht steht in `LOCAL_TEST_REPORT.md`.

---

## 10 · Ausfuehrungsprotokoll

| Datum | Schritt | Ziel | Ergebnis |
|---|---|---|---|
| — | — | — | **Noch nichts gegen eine Datenbank ausgefuehrt.** Production-Hold aktiv. |
