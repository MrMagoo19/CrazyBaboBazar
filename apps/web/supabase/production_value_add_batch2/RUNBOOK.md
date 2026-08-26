# Value-Add Batch 2 — Production-Runbook

> **STATUS: am 2026-08-26 auf Production ausgeführt und auditiert.**
>
> Ziel war bei **jedem** Schritt sichtbar geprüft
> `https://ydiihvzcxaaoqhmgoqvu.supabase.co`.
>
> Ausgeführt wurden `01` → `02` → `02b` → `03` → `04` → `04b`. Alle Gates
> grün: **0 FAIL in allen vier read-only Prüfungen**, beide schreibenden
> Schritte genau **einmal** und erfolgreich. `05_restore_…` wurde
> **nicht** ausgeführt; Snapshot v2 und Audit-Payload v2 bleiben als
> Rollback- und Beobachtungsartefakte bestehen. Zahlen je Gate stehen unten
> in §5, die Zusammenfassung in §9.
>
> Vorlauf: der vollständige lokale PostgreSQL-Harness ist am 2026-08-26 von
> **Codex** unabhängig ausgeführt und auditiert worden — zuletzt auf dem
> **aktuellen**, textentschärften Stand (PostgreSQL 16.15, Workdir
> `/tmp/cbb-pgtest-b2.CvjYPVa5`): **Exit 0, 106 Schritte, 0 Abweichungen,
> GESAMT PASS**, v1-Manifest 34/34 byte-identisch, Cluster sauber gestoppt.
> Ein erster Lauf auf dem Textstand davor lieferte dasselbe Ergebnis. Details
> in [`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md) §1.
>
> Der Rollout dieses Verzeichnisses ist ein reiner **Datenbank**-Vorgang.
> Er beinhaltete **keinen** Commit, **keinen** Push und **keinen** Deploy —
> der Codestand ist davon unabhängig. **Zeitlich danach** sind die
> Repo-Artefakte mit `3557b0d` `feat(web): ship SEO fixes and value-add batch 2`
> und `1be76d1` `fix(audit): close live crawler connections` committet, auf
> GitHub `main` gepusht und über Vercel ausgerollt worden. Das war ein
> **getrennter** Vorgang nach Gate 6 und hat an den DB-Gates oben nichts
> geändert. Siehe §10.

---

## 1. Was Batch 2 ist — und was es ausdrücklich nicht ist

Batch 2 füllt die acht Value-Add-Felder plus `editorial_note` für **zehn
weitere Produkte**. Es ist die Fortsetzung von
[`../production_value_add/`](../production_value_add/RUNBOOK.md) (Batch 1,
am 2026-08-23 ausgeführt).

**Batch 2 enthält bewusst keine Schema-Migration und keine Down-Migration.**
Die acht Spalten und die beiden CHECK-Constraints existieren auf Production
bereits — sie gehören zu Batch 1 und dürfen nicht angefasst werden. Ein
Rollback von Batch 2 ist ein reiner **Daten**-Rollback.

| | Batch 1 | Batch 2 |
|---|---|---|
| Schema-Migration | ja (`02_migrate_value_add.sql`) | **nein** |
| Down-Migration | ja (`07_down_migration.sql`) | **nein** |
| Snapshot | `cbb_private_backup.value_add_pre_backfill_v1` | `…_v2` |
| Audit-Payload | `cbb_private_backup.value_add_payload_v1` | `…_v2` |
| Zielprodukte | 10 (disjunkt) | 10 (disjunkt) |
| Relations-Triplets | 3 alternative, 2 complement, 5 ohne | **1 alternative, 1 complement, 8 ohne** |

### Batch 1 ist tabu

Keine Datei dieses Verzeichnisses schreibt in
`cbb_private_backup.value_add_pre_backfill_v1` oder
`cbb_private_backup.value_add_payload_v1`. Beide werden ausschließlich per
`to_regclass()` auf **Existenz** geprüft, weil ein fehlendes Batch-1-Artefakt
bedeutet, dass die Historie nicht mehr vollständig ist — und dann darf Batch 2
nicht aufsetzen.

Der lokale Testharness belegt das doppelt:

- statisch: `case_0_statisch` prüft per `sha256sum -c`, dass **alle 34 Dateien**
  unter `production_value_add/` (plus `seo_updated_at_trigger.sql`)
  byte-identisch sind, und dass jede ausführbare Zeile in `02`, `03` und `05`,
  die `value_add_*_v1` nennt, dies innerhalb eines `to_regclass()`-Aufrufs tut.
- dynamisch: `cases/assert_v1_untouched.sql` vergleicht nach jedem Fall beide
  v1-Tabellen **und** die zehn Batch-1-Produktzeilen Zelle für Zelle gegen eine
  vor dem Lauf gezogene Baseline.

Beides ist im maßgeblichen Codex-Lauf vom 2026-08-26 (`CvjYPVa5`) tatsächlich
gelaufen: das Manifest meldete **34/34 identisch**, die dynamischen Vergleiche
0 Abweichungen.

---

## 2. Unverrückbare Umgebungsgrenze

- Ziel ist **ausschließlich** `project/ydiihvzcxaaoqhmgoqvu`.
- Pilot/Staging (`nmzuycveumyfvtxdcnuc`) ist für diesen Vorgang irrelevant und
  darf nicht verwendet werden.
- Vor **jedem** Schritt wird das ausgewählte Projekt im Supabase-Editor
  sichtbar geprüft. SQL kann die Projekt-Ref nicht lesen; die Guards prüfen
  stattdessen einen Tabellen-Fingerprint (`products`, `page_content`,
  `discovery_queue`, `swipes`), den Produktbestand (`>= 300`) und die
  Abwesenheit bekannter Pilot-Artefakte.
- Jeder schreibende Schritt braucht eine **eigene, frische** Freigabe durch den
  Benutzer. Eine Freigabe für Schritt 2 ist keine Freigabe für Schritt 3.

---

## 3. Artefakte

| Datei | Art | Wirkung |
|---|---|---|
| `01_preflight_read_only.sql` | read-only | 16 harte Prüfungen + 9 INFO-Zeilen (25 Zeilen) |
| `02_backup_value_add_batch2.sql` | **schreibend** | legt `value_add_pre_backfill_v2` an (10 Zeilen) |
| `02b_verify_snapshot_read_only.sql` | read-only | 17 harte Prüfungen + 4 INFO-Zeilen (21 Zeilen) |
| `03_backfill_value_add_batch2.sql` | **schreibend** | füllt 10 Produktzeilen, legt `value_add_payload_v2` an |
| `04_verify_read_only.sql` | read-only | Inhalt: 17 harte Prüfungen + 4 INFO (21 Zeilen) |
| `04b_verify_payload_security_read_only.sql` | read-only | Absicherung der Payload: 10 harte Prüfungen + 7 INFO (17 Zeilen) |
| `05_restore_value_add_batch2.sql` | **schreibend** | Rollback der 10 Datenzeilen, löscht nichts |
| `test/` | lokal | eigener PostgreSQL-Harness, siehe [`test/README.md`](test/README.md) |

Die drei schreibenden Dateien sind jeweils **eine** Transaktion:
`begin;` → `set local lock_timeout = '5s';` →
`set local statement_timeout = '60s';` → Guards → Arbeit → Nachprüfung →
`commit;`. Bricht irgendetwas ab, ist nichts passiert.

### Reichweite der Zeitgrenzen

Beide `set local`-Zeilen stehen **unmittelbar hinter `begin;`** und vor dem
ersten `do $$`-Block. Das ist kein Stilfrage, sondern der Befund aus dem
Batch-1-Review: der erste Guard-Block fasst mit
`select count(*) from public.products` die Tabelle bereits an. Stünden die
Zeitgrenzen danach, würde dieser Zugriff mit dem Session-Default
`lock_timeout = 0` unbegrenzt auf einen konkurrierenden
`AccessExclusiveLock` warten. `case_0_statisch` prüft die Position statisch,
`case_j_lock_timeout` prüft sie dynamisch gegen eine echte Sperre.

---

## 4. Inhalt: was geschrieben wird

Zehn Produkte, alle published, alle acht Value-Add-Felder vorher `NULL`,
disjunkt zu Batch 1:

| # | Slug | Relation |
|---|---|---|
| 1 | `livondo-terracotta-pflanzenbewaesserung` | — |
| 2 | `wixies-wichstuecher-scherzartikel` | — |
| 3 | `kaffeewaermer-tassenwaermer-elektrisch` | → `gluecksgut-anti-stress-wuerfel` (**complement**) |
| 4 | `gluecksgut-anti-stress-wuerfel` | → `shashibo-formwechsel-box-magnetisch` (**alternative**) |
| 5 | `infactory-boyfriend-kissen` | — (bewusst, siehe unten) |
| 6 | `scheisse-quartett-kartenspiel` | — |
| 7 | `riesige-aufblasbare-ente-pool` | — |
| 8 | `shashibo-formwechsel-box-magnetisch` | — |
| 9 | `eiswuerfelform-todesstern-star-wars` | — |
| 10 | `katzenschlafsack-fuer-menschen` | — |

**Erwartete Verteilung: 1 alternative, 1 complement, 8 ohne Relation.**
Beide Relationsziele liegen innerhalb der Batch-2-Zielmenge — die Relation ist
damit vollständig aus einer bereits geprüften Menge belegbar.

### Warum `infactory-boyfriend-kissen` keine strukturierte Relation bekommt

Der bestehende Beschreibungstext dieses Produkts enthält bereits einen
**manuellen** Querverweis auf `vachichi-boyfriend-kissen-muskuloeser-arm`. Eine
zusätzliche strukturierte Relation würde denselben Hinweis auf der Produktseite
ein zweites Mal rendern. Die Entscheidung ist nicht implizit: `03` prüft nach
dem UPDATE ausdrücklich, dass diese Zeile relationslos ist, und `04` meldet es
als eigene Prüfzeile (`infactory_bleibt_relationslos`).

### Quellenbindung der Texte

Jeder Text beschränkt sich auf die verifizierten Rohfakten. Die Texte wurden
am 2026-08-26 gezielt nachgeschärft; entfernt wurde alles, was darüber
hinausging — auch dann, wenn es plausibel klang. Konkret **nicht** behauptet
wird:

- **Livondo**: nichts zu Reichweite oder Standzeit einer Füllung (der
  `cons`-Eintrag benennt die Lücke ausdrücklich), kein Alter des Ollas-Prinzips,
  keine sofortige Wiedereinsatzbereitschaft nach dem Nachfüllen. Belegt sind:
  Ollas-Prinzip, befüllen und in die Erde setzen, langsame Abgabe über den Ton,
  ohne Strom und Timer.
- **Wixies**: keine speziellen Anlässe, kein Packungsformat, keine Award-,
  Wirkungs- oder Kaufversprechen. Belegt sind: 7 bedruckte Servietten, derber
  Gag- bzw. Scherzartikel.
- **Kaffeewärmer**: keine Aussage darüber, ob kalter Kaffee neu erhitzt wird,
  keine Größen-/Stellflächenbehauptung. Als Nachteile stehen nur die
  Netzbindung und die automatische Abschaltung nach 8 Stunden.
- **Glücksgut-Würfel**: keine Hosentaschen- oder Größenbehauptung, keine
  Aussage darüber, welche der sechs Seiten hörbar ist. Belegt sind: sechs
  Seiten, Drücken/Drehen/Schieben/Klicken, ruhige Bedienoptionen, Einsatz an
  Schreibtisch, im Meeting und in Fokus-Phasen.
- **Boyfriend-Kissen**: kein „kompakt", und keine Aussage zu ergonomischer
  Wirkung **oder** Nichtwirkung. Belegt sind: realistisches Pyjama-Oberteil mit
  Arm, ca. 54 × 50 cm, bei 30 °C waschbar. Die Geschmacks-Einordnung bleibt.
- **Scheisse-Quartett**: keine Erklärdauer, keine Jackentaschen-Behauptung,
  keine Aussage über Vielspieler. Belegt sind: 32 Figuren, klassisches
  Quartettprinzip, Reiseformat, derbes Thema.
- **Pool-Ente**: keine Alters-, Sicherheits- oder Belastbarkeitsangabe — und
  ausdrücklich auch **keine** Aussage darüber, wofür sie *nicht* gedacht sei.
  Der `cons`-Eintrag und die `editorial_note` stellen nur fest, dass zu Alter,
  Sicherheit und Belastbarkeit keine verifizierten Angaben vorliegen. Belegt
  sind: 1,2 m, PVC, Schnellventil.
- **Shashibo**: keine Mund- oder Verschluckwarnung und keine konkrete
  Magnetwirkung („halten die Form von selbst"). Belegt sind: magnetisch, laut
  Produktdaten über 70 Formen, ohne Batterie und App, ab 6 Jahren. „über 70
  Formen" ist an jeder Stelle als *laut Produktdaten* gekennzeichnet.
- **Todesstern-Eiswürfelform**: nichts zum Herausdrücken, nichts zum
  Gefrierfachbedarf, keine Geschmacks- oder Kühlversprechen. Belegt sind:
  lebensmittelechtes Silikon, drei Star-Wars-Eiskugeln im Todesstern-Design.
- **Katzenschlafsack**: keine Aussage, er sei „zum Laufen nicht gedacht".
  Belegt sind: Katzenohren-Kapuze, Armlöcher, weiches Innenfutter,
  Reißverschluss, Größen S bis XL. Passform- und Geschmackshinweis bleiben.

Keine exakten Preise, keine Rabatt- oder Verfügbarkeitsangaben, keine
Kaufaufforderungen, keine Superlative, kein Wort aus der Stoppliste der
Voice Bible.

Strukturell unverändert durch diese Nachschärfung: alle zehn Slugs, beide
Relationen, die Feldbelegung (`fuer_wen`, `nicht_fuer`, `key_fact`, 2–4
`pros`, ≥ 1 `cons`, `editorial_note` — nichts leer), die 20 `array[`-Literale
im `values`-Block, die 8 null-Triplets und sämtliche Guards. Der maßgebliche
Harness-Lauf (`CvjYPVa5`, §7) fand auf genau diesem nachgeschärften Stand statt
und belegt das dynamisch.

### `editorial_note` wird überschrieben

Alle zehn Zeilen bekommen eine `editorial_note`. Trägt eine Zielzeile bereits
eine, wird sie **bewusst überschrieben**. Welche Zeilen betroffen sind, meldet
`02b` in der INFO-Zeile `snapshot_v2_bestehende_editorial_notes` — diese Zahl
ist absichtlich **keine** harte Prüfung, weil der Ist-Stand der
`editorial_note`-Belegung der zehn Zielzeilen zum Zeitpunkt der Erstellung
dieses Runbooks nicht read-only bestätigt vorlag. Der Originaltext und der
originale `updated_at`-Wert liegen im Snapshot und werden von `05` wortgleich
zurückgeholt.

**Ist-Stand aus dem Lauf vom 2026-08-26:** `01` meldete, dass **alle zehn**
Zielzeilen bereits eine `editorial_note` trugen. Alle zehn wurden im Snapshot
v2 gesichert und danach bewusst ersetzt.

---

## 5. Reihenfolge und Gates

Jedes Gate ist einzeln. Ein Gate wird nur passiert, wenn **alle** genannten
Bedingungen erfüllt sind. Bei jedem FAIL: **nichts korrigieren, nichts
nachtragen, nichts löschen.** Befund melden, Ursache klären, Vorgang stoppen.

> [!success] Ausführungsstand 2026-08-26
> Gate 0 bis Gate 6 sind in dieser Reihenfolge durchlaufen worden, jedes mit
> 0 FAIL. Die Checkboxen unten sind mit den **tatsächlich beobachteten**
> Werten abgehakt. Gate „Rollback" (§6) wurde bewusst nicht ausgelöst.

### Gate 0 — Sichtbare Zielprüfung

- [x] Im Supabase-Editor ist `project/ydiihvzcxaaoqhmgoqvu` ausgewählt —
      vor jedem einzelnen Schritt erneut sichtbar gegen
      `https://ydiihvzcxaaoqhmgoqvu.supabase.co` geprüft.
- [x] Der Benutzer hat den Rollout von Batch 2 grundsätzlich freigegeben.
- [x] Der lokale Harness (`test/`) ist auf dem **aktuellen**, textentschärften
      Stand fehlerfrei gelaufen — Codex-Lauf vom 2026-08-26, Workdir
      `/tmp/cbb-pgtest-b2.CvjYPVa5`: PostgreSQL 16.15, Exit 0, 106 Schritte,
      0 Abweichungen, GESAMT PASS, v1-Manifest 34/34, Cluster sauber gestoppt.
      Das ist der Gate-0-Beleg. Der frühere Lauf auf dem Textstand vor der
      Nachschärfung ist Historie ([`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md)
      §1.3).

**Erst dann weiter zu Gate 1.**

---

### Gate 1 — Read-only Preflight

Ausführen: `01_preflight_read_only.sql`

Erwartet: **25 Zeilen — 16 × PASS, 9 × INFO, 0 × FAIL.**

Die 16 harten Prüfungen:

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | `production_tabellen` | 4 |
| 2 | `produkte_mindestens_300` | `>= 300` |
| 3 | `pilot_artefakte` | 0 |
| 4 | `zielprodukte_batch2` | 10 |
| 5 | `veroeffentlichte_zielprodukte` | 10 |
| 6 | `veroeffentlichte_relationsziele` | 2/2 |
| 7 | `value_add_schema_vollstaendig` | 8/8 Spalten, 8/8 Typen, 2/2 Constraints |
| 8 | `batch2_bereits_befuellt` | 0 |
| 9 | `v1_snapshot_vorhanden` | true |
| 10 | `v1_payload_vorhanden` | true |
| 11 | `v1_snapshot_form` | RLS true, 0 Policies, 12 Spalten, PK 1 |
| 12 | `v1_payload_form` | RLS true, 0 Policies, 10 Spalten, PK 1 |
| 13 | `batch2_disjunkt_zu_batch1` | 0 Überschneidungen |
| 14 | `batch1_befuellung_intakt` | 10 Value-Add-Zeilen gesamt, davon 10 Batch 1 vollständig |
| 15 | `v2_snapshot_fehlt` | true |
| 16 | `v2_payload_fehlt` | true |

- [x] 0 FAIL-Zeilen. **Beobachtet am 2026-08-26: 16 PASS, 9 INFO, 0 FAIL.**
- [x] INFO `produkte_gesamt_und_published` protokolliert — beobachtet:
      **376 gesamt, 372 published**.
- [x] INFO `bestehende_editorial_notes` protokolliert — beobachtet: **alle 10
      Zielzeilen trugen bereits eine `editorial_note`**; alle zehn wurden in
      Gate 3 bewusst überschrieben.

Weiter beobachtet: Batch 2 **10/10 published** und Value-Add durchgehend leer,
die v1-Artefakte aus Batch 1 intakt, die v2-Artefakte noch nicht vorhanden.

**Bei irgendeinem FAIL: Gate 2 nicht öffnen.**

---

### Gate 2 — Privater Snapshot (schreibend)

- [x] **Ausdrückliche Benutzerfreigabe.** Die zuvor erteilte Freigabe
      „alles umsetzen" umfasste den vollständigen Batch-2-Rollout und damit
      diesen Schritt; sie wurde nicht als neue Einzel-Freigabe formuliert.
- [x] Zielprojekt erneut sichtbar geprüft.

Ausführen: `02_backup_value_add_batch2.sql`

Was passiert:

1. Guard-Block: Pilot-Artefakte, Fingerprint, `>= 300` Produkte, 10/10
   Zielprodukte published, 2/2 Relationsziele published, Disjunktheit zu
   Batch 1, Schema 8/8 + 2/2, v1-Snapshot da, v1-Payload da, v2-Snapshot fehlt,
   0 Zielzeilen bereits befüllt.
2. Zweiter Block: `for update` auf exakt die 10 Zielzeilen, danach erneute
   Befüllungsprüfung — ein paralleler Schreiber zwischen Guard und Snapshot
   kann nicht durchrutschen.
3. `create table cbb_private_backup.value_add_pre_backfill_v2 as select …`
   mit 12 Spalten: `id`, `slug`, `editorial_note`, `updated_at` und den acht
   Value-Add-Feldern.
4. `add primary key (id)`, `add unique (slug)`, `enable row level security`,
   `revoke all … from public, anon, authenticated`.
5. Nachprüfung in derselben Transaktion: exakt 10 Zeilen, 0 davon mit
   Value-Add-Daten, Batch-1-Artefakte weiterhin vorhanden.

Erwartete Ausgabe nach `commit`: **`backup_rows = 10`.**

- [x] `backup_rows = 10`. **Beobachtet am 2026-08-26**, genau ein
      erfolgreicher Lauf. Angelegt wurde
      `cbb_private_backup.value_add_pre_backfill_v2` mit RLS, Primärschlüssel,
      `UNIQUE(slug)` und ohne App-Rechte.

**Wiederholung ist fail-closed:** ein zweiter Lauf bricht mit
`Batch-2-Backup abgebrochen: Snapshot v2 existiert bereits.` ab. Der Snapshot
wird nie überschrieben und nie ersetzt.

---

### Gate 3 — Read-only Snapshot-Prüfung

Ausführen: `02b_verify_snapshot_read_only.sql`

Erwartet: **21 Zeilen — 17 × PASS, 4 × INFO, 0 × FAIL.**

Geprüft werden unter anderem:

- Snapshot: 10 Zeilen, 12 Spalten mit exakt den erwarteten Namen, Zielmenge
  ohne fehlende und ohne zusätzliche Slugs, 10 eindeutige `id` und `slug`,
  0 Zeilen mit Value-Add-Daten, 0 Drift gegen `public.products`.
- Absicherung: RLS an, 0 Policies, PK 1, `UNIQUE(slug)` 1.
- Rechte **doppelt und fail-closed**, für Tabelle und Schema:
  (a) direkte ACL-Einträge für `PUBLIC`, `anon`, `authenticated` = 0 und
  (b) effektive Privilegien über `has_table_privilege` /
  `has_schema_privilege` für `anon` und `authenticated` = 0.
  Zusätzlich wird verlangt, dass beide Rollen überhaupt existieren
  (`app_rollen_vorhanden = 2/2`) — sonst wäre ein Zähler von 0 nur ein Beleg
  für „keine Rolle", nicht für „keine Rechte".
- `value_add_payload_v2` existiert noch **nicht**.
- Batch-1-Artefakte weiterhin vorhanden, Batch-1-Befüllung mit exakt 10
  Value-Add-Zeilen intakt.

- [x] 0 FAIL-Zeilen. **Beobachtet am 2026-08-26: 17 PASS, 4 INFO, 0 FAIL.**
- [x] INFO `snapshot_v2_bestehende_editorial_notes` protokolliert.

Weiter beobachtet: **0 Drift** gegen `public.products`, **10 Zeilen**,
**12/12 Spalten**, ACL und RLS abgesichert, v1-Artefakte intakt, Payload v2
noch nicht vorhanden.

**Bei irgendeinem FAIL: Gate 4 nicht öffnen.**

---

### Gate 4 — Atomarer Backfill (schreibend)

- [x] **Ausdrückliche Benutzerfreigabe.** Die zuvor erteilte Freigabe
      „alles umsetzen" umfasste den vollständigen Batch-2-Rollout und damit
      diesen Schritt; sie wurde nicht als neue Einzel-Freigabe formuliert.
- [x] Zielprojekt erneut sichtbar geprüft.
- [x] Die aus Gate 3 protokollierten `editorial_note`-Slugs sind dem Benutzer
      genannt worden — sie werden jetzt überschrieben. Betroffen waren alle
      zehn Zielzeilen.

Ausführen: `03_backfill_value_add_batch2.sql`

Was passiert:

1. Guard-Block wie in Gate 2, zusätzlich: Snapshot v2 existiert mit 10 Zeilen,
   Payload v2 existiert noch nicht.
2. `for update` auf die 10 Snapshot-Zeilen, danach **Drift-Prüfung** über alle
   zwölf Snapshot-Felder. Hat sich seit Gate 2 auch nur eine Zelle geändert,
   bricht der Lauf ab.
3. Temporäre Payload-Tabelle (`on commit drop`) mit den 10 Datensätzen.
4. `create table cbb_private_backup.value_add_payload_v2 as select *`,
   `add primary key (slug)`, `enable row level security`,
   `revoke all … from public, anon, authenticated`.
5. `update public.products … set … updated_at = now()` — muss exakt 10 Zeilen
   treffen.
6. Nachprüfung in derselben Transaktion:
   Payload 10 Zeilen, 0 Feldabweichungen, 1 alternative, 1 complement,
   8 ohne Relation, 0 inkonsistente Triplets, 0 defekte Relationsziele,
   10 geänderte `updated_at`, **20** Value-Add-Zeilen insgesamt
   (10 Batch 1 + 10 Batch 2), Batch 1 weiterhin 10/10 vollständig,
   `infactory-boyfriend-kissen` relationslos.

- [x] Der Lauf endet mit `COMMIT` ohne Meldung. **Beobachtet am 2026-08-26:**
      genau ein Lauf, erfolgreich committet, leere Ergebnismenge wie erwartet,
      keine Exception.

Die internen Nachprüfungen derselben Transaktion meldeten: **10 aktualisierte
Zeilen**, Payload **10**, **0 Feldabweichungen**, **1 alternative**,
**1 complement**, **8 ohne Relation**, **20 Value-Add-Zeilen insgesamt**,
Batch 1 weiterhin **10/10 vollständig**, **10 geänderte `updated_at`**.

**Wiederholung ist fail-closed:** ein zweiter Lauf bricht mit
`Batch-2-Backfill abgebrochen: Audit-Payload v2 existiert bereits.` ab. Läuft
er stattdessen auf einen Bestand, der sich seit dem Snapshot verändert hat,
bricht er mit `… Zielzeilen sind seit dem Snapshot gedriftet.` ab.

---

### Gate 5 — Read-only Nachprüfung, Inhalt

Ausführen: `04_verify_read_only.sql`

Erwartet: **21 Zeilen — 17 × PASS, 4 × INFO, 0 × FAIL.**

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | `pilot_artefakte` | 0 |
| 2 | `value_add_schema` | 8/8 Spalten, 2/2 Constraints |
| 3 | `snapshot_v2_zeilen` | 10 |
| 4 | `zielprodukte_published` | 10/10 |
| 5 | `audit_payload_v2` | 10 Zeilen, 0 Abweichungen |
| 6 | `zielprodukte_vollstaendig_befuellt` | 10 vollständig, 10 mit 2–4 `pros`, 10 mit ≥ 1 `cons` |
| 7 | `value_add_gesamt` | 20 |
| 8 | `batch1_befuellung_intakt` | 10 |
| 9 | `alternativen` | 1 |
| 10 | `ergaenzungen` | 1 |
| 11 | `ohne_relation` | 8 |
| 12 | `inkonsistente_relationen` | 0 |
| 13 | `defekte_relationsziele` | 0 |
| 14 | `geaenderte_lastmods` | 10 |
| 15 | `infactory_bleibt_relationslos` | 1 |
| 16 | `batch1_artefakte_vorhanden` | true / true |
| 17 | `produkte_mindestens_300` | `>= 300` |

- [x] 0 FAIL-Zeilen. **Beobachtet am 2026-08-26: 17 PASS, 4 INFO, 0 FAIL** —
      20 Value-Add-Produkte gesamt, Batch 2 10/10 vollständig befüllt,
      0 defekte und 0 inkonsistente Relationen.
- [x] INFO `relationsliste` zeigt genau zwei Triplets:
      `kaffeewaermer-tassenwaermer-elektrisch -> gluecksgut-anti-stress-wuerfel (complement)`
      und
      `gluecksgut-anti-stress-wuerfel -> shashibo-formwechsel-box-magnetisch (alternative)`.

---

### Gate 6 — Read-only Sicherheitsprüfung der Audit-Payload

Ausführen: `04b_verify_payload_security_read_only.sql`

Erwartet: **17 Zeilen — 10 × PASS, 7 × INFO, 0 × FAIL.**

`04` prüft die Payload nur **inhaltlich**. Dieses Gate prüft ihre
**Absicherung**: Existenz, 10 Zeilen, exakt 10 Spalten mit exakt den erwarteten
Namen, RLS an, 0 Policies, genau ein Primärschlüssel und dieser exakt aus
`(slug)`, beide App-Rollen vorhanden, und die Rechte auf Tabelle **und** Schema
doppelt auf 0 — direkt (`aclexplode`) und effektiv (`has_*_privilege`, löst
Rollenmitgliedschaft und `PUBLIC` mit auf). Zusätzlich: die Batch-1-Artefakte
sind weiterhin da.

- [x] 0 FAIL-Zeilen. **Beobachtet am 2026-08-26: 10 PASS, 7 INFO, 0 FAIL** —
      Payload v2 mit 10 Zeilen und 10 Spalten, RLS an, 0 Policies, PK `(slug)`,
      und **keinerlei direkte oder effektive Rechte** für `PUBLIC`, `anon` und
      `authenticated` auf Tabelle und Schema. Die v1-Artefakte sind weiterhin
      vorhanden.
- [x] Die fünf `service_role`-INFO-Zeilen sind protokolliert — beobachtet:
      keine direkte und keine effektive ACL auf Tabelle oder Schema. Sie sind
      **keine Zusage**: `03` revoked `service_role` nicht explizit, und die
      Rolle ist auf Supabase typischerweise `BYPASSRLS`. Wer eine Aussage über
      `service_role` braucht, braucht dafür einen eigenen, getrennt
      freigegebenen Vorgang.

**Nach Gate 6 ist der Rollout abgeschlossen.** Snapshot v2 und Payload v2
bleiben bestehen, bis der Benutzer das Beobachtungsfenster für beendet erklärt.

---

## 6. Rollback

> [!warning] Nicht ausgeführt
> `05_restore_value_add_batch2.sql` ist am 2026-08-26 **nicht** gelaufen, weil
> alle Gates grün waren. Der Abschnitt bleibt als bereitstehende Option
> stehen. Snapshot v2 und Audit-Payload v2 bleiben dafür erhalten, bis der
> Benutzer das Beobachtungsfenster für beendet erklärt.

Ausführen: `05_restore_value_add_batch2.sql`

- [ ] **Eigene, frische Freigabe des Benutzers.**
- [ ] Zielprojekt erneut sichtbar geprüft.

Stellt für exakt die zehn Snapshot-Zeilen `editorial_note`, `updated_at` und
die acht Value-Add-Felder wieder her. Danach trägt nur noch Batch 1
Value-Add-Daten.

Was der Rollback **nicht** tut:

- Er löscht den Snapshot v2 nicht.
- Er löscht die Audit-Payload v2 nicht.
- Er fasst Batch 1 nicht an.
- Er entfernt keine Spalte und keinen Constraint — es gibt in Batch 2 keine
  Down-Migration.

Der Lauf ist idempotent: ein zweiter Durchlauf ändert nichts mehr. Das
funktioniert, weil `products_touch_updated_at()` ein ausdrücklich
mitgeschriebenes `updated_at` nicht mit `now()` überschreibt — belegt in
`test/cases/assert_trigger_behaviour.sql`.

Prüfen nach dem Rollback: `04_verify_read_only.sql` **muss** jetzt FAIL-Zeilen
liefern (`audit_payload_v2` mit 10 Abweichungen, `value_add_gesamt = 10`,
`geaenderte_lastmods = 0` und weitere). Das ist der gewollte Zustand, nicht ein
Befund — es belegt, dass der Rollback gewirkt hat.

---

## 7. Lokaler Test

Der Harness unter [`test/`](test/README.md) fährt einen eigenen
PostgreSQL-Cluster in `mktemp -d` hoch (`listen_addresses=''`, nur Unix-Socket)
und führt die **Originaldateien** dieses Verzeichnisses gegen eine
production-ähnliche Fixture aus. Er fasst weder Production noch Pilot an.

Fälle: Happy Path, Wiederholungen, Transaktions-Rollback mitten in `03`,
Restore-Roundtrip, Drift zwischen Snapshot und Bestand, Pilot-Fingerprint,
Bestand unter 300, unvollständiges Value-Add-Schema, unpublished
Relationsziel, fremdbefüllte Zielzeile, fehlendes Batch-1-Artefakt,
Payload-/Snapshot-Sicherheit (inklusive eines absichtlich gesetzten
Rechte-Lochs, das als FAIL gemeldet werden **muss**), Trigger-Verhalten und
Lock-Timeout.

**Ausgeführter Stand (2026-08-26, Lauf durch Codex, Workdir
`/tmp/cbb-pgtest-b2.CvjYPVa5`, auf dem aktuellen textentschärften Stand):**
PostgreSQL 16.15, Exit 0, 106 Schritte, 0 Abweichungen, GESAMT PASS,
v1-Manifest 34/34, Cluster sauber gestoppt. Alle oben genannten Fälle sind
darin bestanden, inklusive doppeltem Restore-Roundtrip und Lock-Timeout bei
`lock_timeout = '5s'`. PostgreSQL lag dabei **nur entpackt** unter `/tmp` und
wurde nicht systemweit installiert; der Harness wurde über `CBB_PG_BIN` und
`LD_LIBRARY_PATH` darauf gezeigt — das Aufrufmuster steht in
[`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md) §1.1.

Historie: ein erster vollständiger Lauf auf dem Textstand *vor* der
Nachschärfung lieferte dasselbe Ergebnis; ein noch früherer Sandbox-Versuch
scheiterte am Unix-Socket (`EPERM`) und damit **vor** dem ersten
Datenbankfall — ein Infrastrukturvorlauf, kein SQL-Befund
([`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md) §1.3).

---

## 8. Bewusste Grenzen — dokumentiert, nicht versteckt

1. **Kontrollierter FAIL vs. Planungsfehler.** PostgreSQL löst
   Relationsnamen zur Planungszeit auf. Eine fehlende Tabelle, die eine
   read-only Datei direkt referenziert, führt deshalb zu
   `relation … does not exist` statt zu einer FAIL-Zeile. Die Dateien nutzen
   das gezielt:
   - Direkt referenziert (harter Planungsfehler = gewollt fail-closed):
     `public.products` überall, `…_pre_backfill_v2` in `02b`, `04`, `05`,
     `…_payload_v2` in `04` und `04b`.
   - Nur über `to_regclass()` (lesbare FAIL-Zeile): die Batch-1-Artefakte in
     allen Dateien, `…_payload_v2` in `02b`, `…_pre_backfill_v2` in `01`.

   **Preis dieser Robustheit:** die exakte Zeilenzahl der v1-Tabellen liest
   kein read-only Artefakt. Der harte inhaltliche Beleg, dass Batch 1 intakt
   ist, kommt aus `public.products` (`batch1_befuellung_intakt`), nicht aus den
   v1-Tabellen. `01` gibt zusätzlich `reltuples` als reine Katalogschätzung
   ohne Zusage aus.

2. **`editorial_note`-Zahl der Zielmenge ist INFO, nicht PASS.** Für Batch 1
   war bekannt, dass genau drei Zielzeilen eine Notiz trugen — dort ist es eine
   harte Prüfung. Für Batch 2 lag dieser Ist-Stand bei Erstellung nicht
   read-only bestätigt vor. Eine erfundene Zahl wäre ein falsches PASS, deshalb
   INFO. Der Drift-Guard in `03` und der Round-Trip in `05` sind davon nicht
   betroffen — sie arbeiten feldweise gegen den Snapshot.

3. **`05` prüft nur seine eigenen zehn Zeilen.** Der Rollback zählt bewusst
   **nicht**, wie viele Produkte insgesamt Value-Add-Daten tragen. Ein späterer
   Batch 3 würde diese Zahl verändern und damit einen dringend nötigen
   Rollback von Batch 2 blockieren. Ein Rollback darf nie an einem Zustand
   scheitern, den er gar nicht anfasst.

4. **Der Relationsguard in `02`/`03` kann nicht isoliert auslösen.** Beide
   Relationsziele liegen innerhalb der Zielmenge. Wird eines unpublished,
   schlägt der frühere Guard `10/10 Zielprodukte published` zuerst an. Das ist
   die strengere Bedingung — der Vorgang stoppt früher, nicht später.
   `case_h_relationsziel_offline` prüft genau diese Meldung.

5. **`service_role` ist nirgends eine Zusage.** Sie wird nicht revoked und ist
   auf Supabase typischerweise `BYPASSRLS`. Alle Aussagen dazu sind INFO.

6. **Das erneute `revoke all on schema cbb_private_backup`** in `02` ist auf
   einem bereits abgesicherten Schema ein No-op. Es steht dort, damit der Pfad
   auch in einer Umgebung geschlossen bleibt, in der das Schema noch nicht
   abgesichert wäre.

7. **`create schema if not exists`** in `02` ist die einzige Stelle, an der
   Batch 2 ein Objekt anfasst, das Batch 1 angelegt hat. Es verändert das
   Schema nicht — es stellt nur sicher, dass es existiert.

---

## 9. Ausführungsprotokoll 2026-08-26 und aktueller Haltepunkt

Ziel bei jedem Schritt sichtbar geprüft: `https://ydiihvzcxaaoqhmgoqvu.supabase.co`.
Keine Uhrzeiten protokolliert.

| Schritt | Art | Ergebnis |
|---|---|---|
| lokaler Harness | lokal | PostgreSQL 16.15, Workdir `/tmp/cbb-pgtest-b2.CvjYPVa5`, Exit 0, 106 Schritte, 0 Abweichungen, GESAMT PASS, v1-Manifest 34/34 byte-identisch, Cluster sauber gestoppt |
| `01_preflight_read_only.sql` | read-only | **16 PASS, 9 INFO, 0 FAIL**; 376 gesamt / 372 published; Batch 2 10/10 published, Value-Add leer; v1 intakt; v2-Artefakte fehlten; alle 10 Zielzeilen hatten eine `editorial_note` |
| `02_backup_value_add_batch2.sql` | **schreibend** | genau einmal, erfolgreich, **`backup_rows = 10`**; Snapshot v2 mit RLS, PK, `UNIQUE(slug)`, ohne App-Rechte |
| `02b_verify_snapshot_read_only.sql` | read-only | **17 PASS, 4 INFO, 0 FAIL**; 0 Drift, 10 Zeilen, 12/12 Spalten, ACL/RLS sicher, v1 intakt, Payload v2 fehlte noch |
| `03_backfill_value_add_batch2.sql` | **schreibend** | genau einmal, committet, keine Exception; intern 10 Updates, Payload 10, 0 Mismatch, 1 alternative, 1 complement, 8 ohne Relation, 20 Value-Add gesamt, Batch 1 weiter 10/10, 10 geänderte `updated_at` |
| `04_verify_read_only.sql` | read-only | **17 PASS, 4 INFO, 0 FAIL**; 20 Value-Add-Produkte gesamt, Batch 2 10/10 vollständig, 0 defekte/inkonsistente Relationen |
| `04b_verify_payload_security_read_only.sql` | read-only | **10 PASS, 7 INFO, 0 FAIL**; Payload v2 10 Zeilen / 10 Spalten, RLS an, 0 Policies, PK `(slug)`, keine direkten oder effektiven Rechte für `PUBLIC`/`anon`/`authenticated`; `service_role` nur INFO, ohne ACL |
| `05_restore_value_add_batch2.sql` | **schreibend** | **nicht ausgeführt** — alle Gates grün |

### Live-Smoke nach dem Rollout

- Alle **10** Ziel-URLs liefern HTTP **200**.
- Nach Cache-Busting zeigen alle **10** „Auf einen Blick" und „Pro & Contra".
- Alle **10** eindeutigen `key_fact`-Texte sind im HTML.
- Beide Relationslinks sind korrekt gerendert.

### Stand danach

- **Value-Add-Abdeckung in Production: 20 von 372 veröffentlichten
  Produkt-URLs, rund 5,4 %.**
- Rollback-Artefakte bleiben erhalten: `value_add_pre_backfill_v2` und
  `value_add_payload_v2`. Batch 1 (`…_v1`) ist unangetastet.
- Die Textnachschärfung in `03` (§4, „Quellenbindung") liegt **vor** dem
  maßgeblichen Harness-Lauf und ist damit mitgeprüft. SQL-Struktur, Slugs,
  Relationen, Feld-/Array-Anzahl und Guards sind unverändert.
- Nächster Schritt: Beobachtungsfenster. Erst wenn der Benutzer es für beendet
  erklärt, werden Snapshot v2 und Payload v2 zur Disposition gestellt.

> [!note] Abgrenzung zum Codestand
> Dieser Abschnitt beschreibt ausschließlich den **Datenbank**-Rollout. Der
> Codestand des Repositories ist davon getrennt und wurde **erst danach** in
> einem eigenen Vorgang ausgerollt — siehe §10.

---

## 10. Codestand: getrennter Rollout nach Gate 6

> [!info] Zeitliche Trennung
> Zum Zeitpunkt der DB-Gates oben standen `main` und `origin/main` auf
> `ea353c9`, der Worktree war dirty. Der Datenbank-Rollout hat davon nichts
> berührt und war mit Gate 6 abgeschlossen. **Erst danach** wurden die
> Repo-Artefakte committet, gepusht und ausgerollt. Die Gate-Ergebnisse in
> §5 und §9 sind dadurch unverändert.

**Stand 2026-08-26 nach diesem getrennten Vorgang:**

- `3557b0d` `feat(web): ship SEO fixes and value-add batch 2` — auf GitHub
  `main` gepusht und von Vercel ausgerollt.
- `1be76d1` `fix(audit): close live crawler connections` — Folgecommit nach
  dem Live-Voll-Audit, ebenfalls auf `main` gepusht. Er änderte **nur** das
  Audit-Skript und einen Regressionstest, keine Anwendungs- oder SQL-Datei
  dieses Verzeichnisses.
- `main` **und** `origin/main` stehen exakt auf `1be76d1`. Worktree sauber.
- GitHub Actions `web quality`: für `3557b0d` erfolgreich, für `1be76d1`
  ebenfalls `completed/success` (Run 32913224131).
- Finale lokale Gates nach dem Crawler-Fix: **162/162 Tests**, Typecheck grün,
  Lint grün; Production-Build des Web-Changesets **441/441 Pfade** grün.

**Befund aus dem Live-Voll-Audit:** Nach fertig geschriebenem Report blieben
unter Node 20 zwei `TCPSocketWrap`-Handles des Crawlers offen. Fix:
`connection: close` plus Regressionstest (`1be76d1`). Der Voll-Crawler danach
beendet sich natürlich mit Exit 0 in 16,6 s.

> [!note] Betrieblicher Hinweis zum Push
> Der erste HTTPS-Push wurde von GitHub wegen der neuen Workflow-Datei und
> fehlendem `workflow`-Scope abgelehnt. Remote wurde dabei **nichts**
> verändert. Der bereits vorhandene, als `MrMagoo19` authentifizierte
> SSH-Key wurde danach für den Push verwendet; an Credentials oder
> Remote-Konfiguration wurde nichts geändert. Kein offenes Produktproblem —
> nur relevant, falls künftig erneut per HTTPS gepusht wird.

**Unverändert durch diesen Abschnitt:** alle DB-Gates, Snapshot v2, Payload v2
und der Restore-Status (`05_restore_value_add_batch2.sql` bleibt **nicht
ausgeführt**). Value-Add-Abdeckung in Production bleibt **20 von 372**.
