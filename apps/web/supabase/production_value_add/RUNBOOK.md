# Value-Add — Production-Runbook

Status: **Die Schritte 1 bis 5b sind am 2026-08-23 auf Production
`ydiihvzcxaaoqhmgoqvu` ausgeführt und auditiert** — Read-only-Preflight,
additive Migration, privater Snapshot, atomarer Backfill, die read-only
Nachprüfung `05_verify_read_only.sql` (16 Zeilen, 14 PASS, 2 INFO, 0 FAIL) und
die read-only Sicherheitsprüfung `05b_verify_payload_security_read_only.sql`
(16 Zeilen, 9 PASS, 7 INFO, 0 FAIL). Schritt 2 und Schritt 3 wurden zusätzlich
jeweils durch einen eigenen unabhängigen read-only Postcheck bestätigt; für
Schritt 4 sind Schritt 5 (Inhalte) und Schritt 5b (Absicherung der Payload)
diese Nachprüfung. **`06` und `07` sind nicht ausgeführt** — sie sind reine
Rollback-Artefakte und brauchen jeweils eine eigene neue Freigabe. Der Postcheck
zu Schritt 3 ist die eigene Datei `03_verify_snapshot_read_only.sql` — sie ist
**nicht** `05_verify_read_only.sql` und hat Schritt 5 nicht ersetzt. Dieses
Runbook erteilt keine Freigabe. **Kein weiterer Production-DB-Schritt ist
freigegeben**; Commit, Merge, Push und Deploy bleiben getrennte
Benutzerentscheidungen und sind ausdrücklich weiterhin gesperrt.

**Geschlossene Prüfungslücke — Stand 2026-08-23.** `05_verify_read_only.sql`
prüft die in Schritt 4 neu erzeugte Audit-Payload
`cbb_private_backup.value_add_payload_v1` ausschließlich **inhaltlich**
(10 Zeilen, 0 Feldabweichungen). Es prüft **weder RLS noch Policies noch die
Rechte** auf dieser Tabelle oder ihrem Schema. Diese Lücke ist inzwischen
geschlossen: `05b_verify_payload_security_read_only.sql` ist nach eigener
ausdrücklicher read-only Freigabe am 2026-08-23 auf Production ausgeführt worden
und hat bestanden — **16 Zeilen, 9 harte PASS, 7 INFO, 0 FAIL**. Damit ist auf
Production gemessen und belegt: RLS aktiv, 0 Policies, Primärschlüssel genau
`PK(slug)`, exakt 10 Spalten mit den 10 erwarteten Namen und **keine Rechte für
PUBLIC, `anon` oder `authenticated`** — weder direkt noch effektiv, weder auf
der Tabelle noch auf dem Schema. Die fünf `service_role`-Zeilen bleiben
ausdrücklich **INFO ohne PASS-Zusage** (siehe 5b). Die bereits bestätigte
Aussage über den **Snapshot** aus Schritt 3 (RLS aktiv, 0 Policies, keine
App-Rechte auf Tabelle und Schema) ist davon unberührt — sie ist durch
`03_verify_snapshot_read_only.sql` auf Production belegt.

> **Überholt (historisch).** Hier stand bis zum Production-Lauf von `05b`:
> „Die Absicherung der Payload ist damit auf Production **nicht gemessen** …
> **weiterhin nicht freigegeben und nicht auf Production ausgeführt** und ist
> der nächste ausdrückliche read-only Freigabepunkt." Das gilt nicht mehr;
> `05b` ist ausgeführt und bestanden.

## Unverrückbare Umgebungsgrenze

- Production: `project/ydiihvzcxaaoqhmgoqvu`
- Pilot: `project/nmzuycveumyfvtxdcnuc`
- PostgreSQL kann die Supabase-Projekt-Ref intern nicht zuverlässig beweisen.
  `current_database()` und `current_user` sind auf Supabase-Projekten nicht
  eindeutig. Deshalb muss vor **jeder schreibenden Datei** die sichtbare
  Dashboard-URL kontrolliert und als Production quittiert werden.
- Die SQL-Guards prüfen zusätzlich, dass keine bekannten Pilot-Artefakte
  existieren und dass Production-only Tabellen sowie mindestens 300 Produkte,
  alle zehn Zielprodukte und alle fünf veröffentlichten Relationsziele
  vorhanden sind. Diese Fingerprints ergänzen die URL-Prüfung, ersetzen sie
  aber nicht.
- Keine Datei aus dem Pilot-Verzeichnis wird auf Production ausgeführt.

## Artefakte

| Datei | Wirkung | Freigabe |
|---|---|---|
| `01_preflight_read_only.sql` | ausschließlich SELECT/Katalogabfragen | 2026-08-23 ausgeführt: PASS; am selben Tag als Postcheck erneut ausgeführt: PASS |
| `02_migrate_value_add.sql` | 8 nullable Spalten + 2 CHECK-Constraints | 2026-08-23 freigegeben und ausgeführt: „Success. No rows returned", read-only bestätigt |
| `03_backup_value_add.sql` | privater 10-Zeilen-Snapshot | 2026-08-23 freigegeben und ausgeführt: `backup_rows = 10`, read-only bestätigt |
| `03_verify_snapshot_read_only.sql` | ausschließlich Nachprüfung von Schritt 3 (genau ein `with … select`) | 2026-08-23 read-only ausgeführt: 17 Zeilen, 2 INFO, 15 PASS, 0 FAIL |
| `04_backfill_value_add.sql` | private Audit-Payload + Updates exakt 10 Produkte | 2026-08-23 freigegeben und ausgeführt: „Success. No rows returned", durch `05` bestätigt |
| `05_verify_read_only.sql` | ausschließlich Nachprüfung der **Inhalte** (nicht der Payload-Rechte) | 2026-08-23 read-only freigegeben und ausgeführt: 16 Zeilen, 14 PASS, 2 INFO, 0 FAIL |
| `05b_verify_payload_security_read_only.sql` | ausschließlich Nachprüfung der **Absicherung** der Audit-Payload: RLS, Policies, PK, Spaltenform, Tabellen- und Schemarechte (genau ein `with … select`) | 2026-08-23 read-only freigegeben und ausgeführt: 16 Zeilen, 9 PASS, 7 INFO, 0 FAIL; vorher lokal positiv und negativ getestet (10/10 Fälle, Bericht Abschnitt 16) |
| `06_restore_value_add.sql` | Restore exakt 10 Produkte | **nicht ausgeführt**; nur bei Bedarf, neue Freigabe |
| `07_down_migration.sql` | droppt 8 Spalten + 2 Constraints | **nicht ausgeführt**; destruktiv, neue Freigabe |

Der neutrale Snapshot heißt
`cbb_private_backup.value_add_pre_backfill_v1`. Er trägt bewusst kein
Ausführungsdatum und wird niemals automatisch gelöscht.

## Reichweite der Zeitgrenzen

In `02`, `03`, `04`, `06` und `07` stehen

```sql
set local lock_timeout = '5s';
set local statement_timeout = '60s';
```

**unmittelbar hinter `begin;`** und damit vor dem ersten `do $$`-Guard-Block.

Das war nicht immer so. Bis zum lokalen PostgreSQL-Test am 2026-08-23 standen
beide Zeilen *hinter* dem Guard-Block. Die Vorprüfung liest aber bereits
`public.products` (`select count(*) …`) und lief deshalb noch mit dem
Session-Default `lock_timeout = 0`, also unbegrenzt. Unter einem parallelen
`AccessExclusiveLock` gab die Datei nicht nach fünf Sekunden auf, sondern
wartete — der lokale Testlauf lief in seinen Client-Timeout von 20 Sekunden
(Exit 124) statt in den erwarteten Lock-Timeout.

Es war kein Datenrisiko: die Transaktion schreibt in dieser Phase nichts und
rollt beim Abbruch vollständig zurück. Es war eine Abweichung zwischen dem
Verhalten der Dateien und der Zusage in diesem Runbook. Die Zeilen wurden
deshalb in allen fünf schreibenden Dateien nach vorn gezogen und die späteren
Duplikate entfernt; der lokale Harness prüft die Position seither zusätzlich
statisch (`case_0_statisch`) und dynamisch unter einer echten Sperre
(`case_j_lock_timeout`).

Die Aussage „fünf Sekunden Lock-Timeout" gilt damit für die gesamte
Transaktion, nicht erst ab dem DDL. Das ist lokal gemessen: unter einer echten
parallelen Sperre bricht `02` jetzt mit psql-Exit 3 und
`canceling statement due to lock timeout` nach fünf Sekunden ab, in zwei
unabhängigen Läufen identisch. Details: `LOCAL_POSTGRES_TEST_REPORT.md`,
Abschnitte 6 und 7.

Was damit **nicht** belegt ist: der Lauf auf Supabase unter realer
Production-Nebenläufigkeit. Der lokale Test erzeugt einen künstlichen
Sperrkonflikt, keinen parallelen App-Traffic. Die sichtbare Zielprüfung vor der
Datei und der Abbruch nach fünf Sekunden bleiben deshalb bei jedem echten
Schritt zu beobachten.

Die Production-Läufe von `02`, `03` und `04` am 2026-08-23 liefen jeweils ohne
Sperrkonflikt durch („Success. No rows returned", `backup_rows = 10`, „Success.
No rows returned"). Sie belegen damit, dass die Dateien auf Supabase ausführbar
sind — **nicht**, dass der 5-Sekunden-Lock-Timeout dort unter realer
Nebenläufigkeit greift. Dieser Punkt bleibt für `06` und `07` weiterhin offen
und ist auch für `02`, `03` und `04` nicht positiv belegt, weil kein Lauf auf
eine parallele Sperre getroffen ist.

## Reihenfolge und Gates

### 0. Sichtbare Zielprüfung

1. Supabase-Dashboard öffnen.
2. URL und Projektname müssen eindeutig Production zeigen:
   `project/ydiihvzcxaaoqhmgoqvu`.
3. Bei Pilot-Ref, unbekannter Ref oder unklarer Rolle sofort stoppen.
4. Vor Schritt 1 ausdrückliche Freigabe für den Production-Read-only-Preflight
   einholen.

### 1. Read-only Preflight

Datei: `01_preflight_read_only.sql`

- Writes: keine.
- Erwartet: alle PASS-Zeilen grün; INFO-Zeilen werden dokumentiert.
- Vor der ersten Migration muss der Schema-Zustand `0/8 Spalten + 0/2
  Constraints` und der Snapshot `FEHLT` zeigen.
- Ein bereits vollständig migrierter Zustand `8/8 + 2/2` ist technisch
  konsistent, aber nicht automatisch freigegeben: stoppen und Ursache klären.
- FAIL oder Planungsfehler: nichts korrigieren, keine Migration starten.

Nach Codex-Audit des vollständigen Outputs folgt eine **neue** ausdrückliche
Freigabe für Schritt 2.

Ausgeführt am 2026-08-23 im sichtbar bestätigten Projekt
`project/ydiihvzcxaaoqhmgoqvu`: 16 Ergebniszeilen, alle neun harten Prüfungen
PASS, keine FAIL-Zeile. Bestätigt wurden unter anderem 376 Produkte, 0 bekannte
Pilot-Artefakte, 10/10 veröffentlichte Zielprodukte, 5/5 veröffentlichte
Relationsziele, sauberer Vor-Migrations-Zustand `0/8 + 0/2`, keine befüllten
Value-Add-Felder und kein Production-Snapshot. Die drei erwarteten bestehenden
`editorial_note`-Slugs wurden vollständig gemeldet. Der einzige Unterschied
zwischen lokalem Datei-Hash und Editor-Hash war der beim Einfügen ausgelassene
abschließende LF; die 8448 inhaltlichen Bytes waren identisch.

Dieselbe unveränderte Datei wurde am 2026-08-23 ein zweites Mal ausgeführt — als
read-only Postcheck **nach** Schritt 2. Sie ist damit doppelt verwendet:
einmal als Vor-Prüfung (`0/8 + 0/2`), einmal als Nachweis (`8/8 + 2/2`). Beide
Läufe: 16 Zeilen, 9 harte PASS, 0 FAIL. Ergebnis des zweiten Laufs siehe
„2. Additive Migration → Ausführung am 2026-08-23".

### 2. Additive Migration

Datei: `02_migrate_value_add.sql`

- Writes: ausschließlich acht nullable Spalten ohne Default und zwei
  CHECK-Constraints auf `public.products`.
- Atomar: eine Transaktion, fünf Sekunden Lock-Timeout, 60 Sekunden
  Statement-Timeout — **ab der ersten Anweisung**, also einschließlich der
  Fail-closed-Vorprüfung (siehe „Reichweite der Zeitgrenzen").
- Vorher-/Nachher-Gate: Produktanzahl muss identisch bleiben; Typen und beide
  Constraints müssen vollständig vorhanden sein.
- Teilzustand oder bereits vollständige Migration: harter Abbruch.
- Fehler vor `commit`: die Transaktion rollt vollständig zurück.
- Nach erfolgreichem Commit keine weitere Datei starten. Ergebnis auditieren
  und neue Freigabe für Schritt 3 einholen.

#### Ausführung am 2026-08-23

**Freigabe.** Der Benutzer hat Schritt 2 ausdrücklich und projektbezogen
freigegeben: „Ich gebe Production-Schritt 2 auf `ydiihvzcxaaoqhmgoqvu` frei."

**Ausführungsweg.** Zwei vorherige Claude-Chrome-Versuche scheiterten jeweils
vor dem Browser-Write, mit je **0 Run-Klicks** — es wurde dabei nichts
ausgeführt und nichts geschrieben. Die tatsächliche Ausführung erfolgte danach
**manuell durch den Benutzer** nach Codex-Anleitung, aus der auditierten lokalen
Datei `02_migrate_value_add.sql`. Ein einziger Run.

**Auditierter Dateistand** (lokal gemessen, Repo-Stand nach der
Timeout-Korrektur):

```
MD5     f0a81d658554608d7b3cc3637859a5b0
SHA-256 445c274a6719fb93020362d9982d4448fedf986c111eb3773dccdb74a6e58579
Größe   7043 Bytes, 192 Zeilen
```

**Sichtbarer Zielkontext vor der Ausführung** (Screenshot): Supabase-URL
`project/ydiihvzcxaaoqhmgoqvu`, Projekt „CrazyBaboBazar Project", Branch `main`,
Kennzeichnung `PRODUCTION`.

**Ergebnis des Runs.** Meldung des Benutzers: „Success. No rows returned".

**Grenze der Beleglage — ausdrücklich festgehalten.** Weil der Text manuell in
den SQL-Editor eingefügt und dort ausgeführt wurde, liegt **kein unabhängig
gemessener Editor-Hash des tatsächlich eingefügten Textes** vor. Für Schritt 1
gab es einen solchen Vergleich (Datei-Hash gegen Editor-Hash, Unterschied nur
der ausgelassene abschließende LF); für Schritt 2 gibt es ihn nicht. Der
Editorinhalt ist also **nicht bytegenau gemessen**. Die Belegkette lautet exakt:

1. die lokale Datei ist auditiert (Hashes oben),
2. das Ziel war zum Ausführungszeitpunkt sichtbar als Production bestätigt,
3. der Benutzer meldet den Run als erfolgreich,
4. ein **unabhängiger read-only Postcheck** auf derselben Datenbank zeigt genau
   den Zustand, den diese Datei erzeugen soll.

Punkt 4 trägt die Aussage, nicht Punkt 3.

**Postcheck.** Der Benutzer führte anschließend die **unveränderte**
`01_preflight_read_only.sql` (MD5 `957986f864a73076b1a2a2b18625c6e7`) erneut
read-only auf demselben Production-Projekt aus und lieferte alle 16
Ergebniszeilen: ausführende Rolle `postgres`, Datenbank `postgres`,
`production_tabellen` 4 PASS, 376 Produkte PASS, 0 Pilot-Artefakte PASS,
10 Zielprodukte PASS, 10/10 published PASS, 5/5 Relationsziele PASS,
Schema-Zustand exakt **8/8 Spalten, 8/8 Typen, 2/2 Constraints** PASS,
`value_add_bereits_befuellt` 0 PASS, `production_snapshot` FEHLT PASS. INFO:
weiterhin exakt 3 bestehende `editorial_note` (`n4`, `ninja`, `welpen`), RLS
`true`, 2 Policies, 14 App-Grants, 1 unveränderter Trigger. Insgesamt **9 harte
PASS, 0 FAIL**.

**Was daraus folgt.** Die Migration ist vollständig und rein additiv angekommen:
Produktzahl unverändert bei 376, kein Teilzustand, keine befüllten
Value-Add-Felder, kein Snapshot. Zu diesem Zeitpunkt gab es **keinen Backfill**
und **keinen Snapshot** — Schritt 3 und 4 standen beide noch aus. Beide sind
inzwischen ausgeführt (siehe unten); der Satz beschreibt ausschließlich den
Stand direkt nach Schritt 2.

### 3. Privater Snapshot

Datei: `03_backup_value_add.sql`

- Voraussetzung: Schritt 2 vollständig, alle acht neuen Felder der zehn
  Zielprodukte noch leer. Beides war vor der Ausführung durch den Postcheck zu
  Schritt 2 belegt (`8/8 + 2/2`, `value_add_bereits_befuellt` 0,
  `production_snapshot` FEHLT).
- Writes: privates Schema `cbb_private_backup` und Snapshot-Tabelle v1.
- Snapshot: `id`, `slug`, `editorial_note`, `updated_at` und alle acht neuen
  Felder für exakt zehn Produkte.
- Schutz: App-Rollen erhalten keine Rechte; RLS ist aktiv; PK und Unique-Slug;
  vorhandener Snapshot wird niemals überschrieben.
- Erfolg: abschließendes `backup_rows = 10`.
- Abweichung oder Fehler: Backfill nicht starten. Snapshot nicht löschen oder
  neu erzeugen, bevor der Befund auditiert wurde.

Nach Audit folgt eine **neue** ausdrückliche Freigabe für Schritt 4.

#### Ausführung am 2026-08-23

**Freigabe.** Der Benutzer hat Schritt 3 ausdrücklich und projektbezogen
freigegeben: „Ich gebe Production-Schritt 3 auf `ydiihvzcxaaoqhmgoqvu` frei."

**Ausführungsweg.** **Manuell durch den Benutzer** nach Codex-Anleitung, aus der
auditierten lokalen Datei `03_backup_value_add.sql`. Der Benutzer hat den Text
selbst im Chrome-Browser im Supabase-Dashboard-SQL-Editor eingefügt und dort
ausgeführt. Keine Claude-Chrome-Automatisierung und keine sonstige automatische
Ausführung — der einzige Run-Klick kam vom Benutzer.

**Auditierter Dateistand** (lokal gemessen):

```
MD5     acacd1b3180d1f9a7bad55789f194f8d
SHA-256 61505d7fc0ae24e953395939eec4704ce6ddec881fe9da8129a7724551c6bad0
Größe   8296 Bytes, 232 Zeilen
```

**Sichtbarer Zielkontext vor der Ausführung:** Supabase-URL
`project/ydiihvzcxaaoqhmgoqvu`, Projekt „CrazyBaboBazar Project", Branch `main`,
Kennzeichnung `PRODUCTION`.

**RLS-Warnung des Editors und die Entscheidung dazu.** Supabase warnte statisch,
die Query erstelle eine Tabelle ohne RLS. Codex wies korrekt „Run without RLS"
an: die statische Warnung sieht nur das `create table`, nicht die Fortsetzung
derselben Transaktion. Die auditierte Datei führt selbst
`enable row level security` aus und entzieht anschließend die Rechte. Der
spätere read-only Postcheck bestätigt genau das — `snapshot_rls` = `true`.

**Ergebnis des Runs.** `backup_rows = 10`.

**Grenze der Beleglage — ausdrücklich festgehalten.** Wie bei Schritt 2 wurde der
Text manuell in den SQL-Editor eingefügt; ein **Editor-Hash des tatsächlich
eingefügten Textes wurde auch hier nicht gemessen**. Der Editorinhalt ist also
**nicht bytegenau** belegt. Die Belegkette lautet exakt:

1. die lokale Datei ist auditiert (Hashes oben),
2. das Ziel war zum Ausführungszeitpunkt sichtbar als Production bestätigt,
3. der Benutzer meldet `backup_rows = 10`,
4. ein **unabhängiger read-only Postcheck** auf derselben Datenbank zeigt genau
   den Zustand, den diese Datei erzeugen soll.

Punkt 4 trägt die Aussage über den Datenbankzustand, nicht Punkt 3.

**Postcheck: `03_verify_snapshot_read_only.sql`.** Für Schritt 3 reicht `01`
nicht — sie prüft den Snapshot nur als „vorhanden/FEHLT". Claude hat deshalb
eine eigene read-only Prüfdatei erstellt. Sie ist ein **Postcheck zu Schritt 3**
und **nicht** `05_verify_read_only.sql`; Schritt 5 bleibt unausgeführt und
unverändert.

Codex fand in der ersten Fassung einen **Fail-open-Fehler**: fehlende
`anon`/`authenticated`-Rollen wurden nur als Textinfo ausgegeben und waren nicht
Teil der PASS-Bedingung. Auf einer Datenbank ohne diese Rollen hätten die beiden
Rechte-Prüfungen also PASS gemeldet, ohne etwas zu prüfen. Claude hat das
korrigiert; die Rollenpräsenz (`Rollen 2/2`) ist jetzt Teil beider
PASS-Bedingungen. Finaler auditierter Stand:

```
MD5     f38d182d7611ae8dbace3609208bf95a
SHA-256 3f86eef71c0afdbfcf463450fed0827bf5d5d2787305654111334dbba84ba74e
Größe   16525 Bytes, 410 Zeilen
```

Die Datei enthält genau ein lesendes `with … select … order by`; kein DDL, kein
DML, keine Rechtevergabe, kein `do`-Block, keine Transaktionssteuerung.

Codex hat den **finalen** Postcheck vor dem Production-Einsatz auf einem
isolierten lokalen PostgreSQL 16 nach lokalem `02` → `03` getestet: 17 Zeilen,
2 INFO, 15 PASS, 0 FAIL. Dazu zwei Negativtests: bei fehlender
`authenticated`-Rolle exakt **2** ACL-FAIL (Tabellen- und Schemarechte), bei
einem absichtlich gesetzten `anon`-SELECT-Grant exakt **1** ACL-FAIL. Der
Fail-open-Pfad ist damit nachweislich geschlossen. Temp-Cluster und Prozesse
wurden vollständig entfernt. Details: `LOCAL_POSTGRES_TEST_REPORT.md`,
Abschnitt 12.

**Ergebnis des Postchecks auf Production.** Der Benutzer führte die finale Datei
anschließend read-only auf demselben Production-Projekt aus und lieferte alle
17 Ergebniszeilen — `current_user` `postgres` INFO, `current_database`
`postgres` INFO, dann **15 harte PASS, 0 FAIL**:

| Prüfung | Ist | Status |
|---|---|---|
| `snapshot_zeilen` | 10 | PASS |
| `snapshot_spalten` | 12 gesamt, 12 erwartete Namen | PASS |
| `snapshot_zielmenge` | 0 fehlend, 0 zusätzlich | PASS |
| `snapshot_ids_slugs_eindeutig` | 10/10 | PASS |
| `snapshot_value_add_nicht_null` | 0 | PASS |
| `snapshot_editorial_notes` | 3 Notes, 0 fehlend, 0 unerwartet | PASS |
| `snapshot_gegen_products_drift` | 0 | PASS |
| `products_zeilen` | 376 | PASS |
| `aktuelle_zielprodukte_value_add_nicht_null` | 0 | PASS |
| `snapshot_rls` | true | PASS |
| `snapshot_policies` | 0 | PASS |
| `snapshot_constraints` | PK 1, UNIQUE(slug) 1 | PASS |
| `snapshot_tabellenrechte_app_rollen` | Rollen 2/2; PUBLIC 0, anon 0, authenticated 0 | PASS |
| `snapshot_schemarechte_app_rollen` | Rollen 2/2; PUBLIC 0, anon 0, authenticated 0 | PASS |
| `audit_payload_v1_fehlt` | true | PASS |

**Was daraus folgt.** Der private Snapshot existiert mit exakt zehn Zeilen und
ist inhaltsgleich mit den aktuellen Produktzeilen (Drift 0), RLS ist aktiv, es
gibt keine Policy und keine Rechte für `anon`, `authenticated` oder `PUBLIC` —
weder auf der Tabelle noch auf dem Schema. Die drei bestehenden
`editorial_note`-Texte sind gesichert. Zum **Zeitpunkt dieses Postchecks** gab es
**keinen Backfill**: die Value-Add-Felder der zehn Zielprodukte waren leer, und
die Audit-Payload aus Schritt 4 existierte nicht (`audit_payload_v1_fehlt` =
true).

> **Überholt:** Der letzte Satz beschreibt den Stand vom Postcheck zu Schritt 3.
> Schritt 4 ist inzwischen am selben Tag freigegeben und ausgeführt worden
> (siehe „4. Atomarer Backfill → Ausführung am 2026-08-23"). Die
> `audit_payload_v1`-Tabelle existiert seither, und die zehn Zielprodukte sind
> befüllt. Der Snapshot selbst ist davon unberührt und bleibt der
> Rollback-Stand.

### 4. Atomarer Backfill

Datei: `04_backfill_value_add.sql`

- Voraussetzung: Snapshot v1 mit zehn Zeilen und kein Drift zwischen Snapshot
  und den aktuellen Zielprodukten. Beides war vor der Ausführung durch den
  Postcheck zu Schritt 3 belegt (`snapshot_zeilen` 10,
  `snapshot_gegen_products_drift` 0, `audit_payload_v1_fehlt` true). Die erfüllte
  Voraussetzung war **keine** Freigabe — sie wurde vom Benutzer gesondert für
  Schritt 4 erteilt (siehe „Ausführung am 2026-08-23").
- Die zehn Zeilen werden vor dem Update gesperrt.
- Eine temporäre Payload enthält exakt die im Pilot geprüften Inhalte.
- Dieselbe Payload wird innerhalb der Backfill-Transaktion zusätzlich als
  private Tabelle `cbb_private_backup.value_add_payload_v1` gespeichert, damit
  Schritt 5 die Inhalte nach dem Commit feldgenau prüfen kann. App-Rollen
  erhalten keine Rechte; RLS bleibt ohne öffentliche Policy aktiv.
- Ein einziges `UPDATE ... FROM` muss exakt zehn Zeilen treffen.
- `updated_at = now()` wird für genau diese zehn Seiten explizit gesetzt,
  weil alle zehn sichtbaren neuen Inhalt erhalten. Damit ist die
  Sitemap-lastmod-Erwartung für dieses Changeset eindeutig.
- Vor `commit` müssen gelten: Payload ohne Abweichung, 3 Alternativen,
  2 Ergänzungen, 5 ohne Relation, 0 inkonsistente Relationen,
  0 defekte Relationsziele und 10 geänderte `updated_at`-Werte.
- Jede Abweichung löst eine Exception und damit vollständigen Rollback aus.

Bewusste Überschreibung einer bestehenden `editorial_note`:

- `ninja-staysharp-messerset-6-teilig`
- `n4-nussmilchbereiter-pflanzenmilch`
- `welpen-usb-ladekabel-hunde-design`

Die Liste oben ist der historische Pilotstand. Der Output
`bestehende_editorial_notes` aus Schritt 1 ist für Production autoritativ. Jeder
zusätzliche oder fehlende Slug muss vor dem Backfill geprüft und bewusst
freigegeben werden. Die jeweiligen vorherigen Texte sind im Snapshot gesichert.
Zusätzlich bleiben zwei bekannte Punkte bewusst unverändert:

- `divoom-pixoo-led-panel`: `price_cents` bleibt NULL; kein Preis wird geraten.
- `n4-nussmilchbereiter-pflanzenmilch`: der Widerspruch zwischen Tagline und
  Beschreibung zur Zubereitungszeit wird in diesem Changeset nicht verändert.

Nach dem Commit stoppen und Schritt 5 erst nach der vereinbarten
Production-Read-only-Freigabe ausführen.

#### Ausführung am 2026-08-23

**Freigabe.** Der Benutzer hat Schritt 4 ausdrücklich und projektbezogen
freigegeben: „Ich gebe Production-Schritt 4 auf `ydiihvzcxaaoqhmgoqvu` frei."

**Vorbedingung, unmittelbar davor erneut gemessen.** Der verschärfte lokale
PostgreSQL-Harness wurde vor Schritt 4 noch einmal vollständig auf dem aktuellen
Repo-Stand ausgeführt: **73 von 73 Schritten PASS, 0 Abweichungen, Exit 0**; der
Temp-Cluster wurde danach gestoppt. Das ist ein lokaler Nachweis, keine
Production-Aussage und keine Freigabe. Details:
`LOCAL_POSTGRES_TEST_REPORT.md`, Abschnitt 13.

**Ausführungsweg.** **Manuell durch den Benutzer** im Chrome-Browser im
SQL-Editor des sichtbar bestätigten Production-Projekts, aus der auditierten
lokalen Datei `04_backfill_value_add.sql`. Keine Claude-Chrome-Automatisierung,
kein automatischer Lauf — der einzige Run-Klick kam vom Benutzer.

**Auditierter Dateistand** (lokal gemessen):

```
MD5     a0d6cd3adfca22638f382f28b9c3dbee
SHA-256 3af9c51fe71c7d51391fd93b1d37b1fa7148042e0620203d0c4e4ce460a61001
Größe   19117 Bytes, 409 Zeilen
```

**Sichtbarer Zielkontext vor der Ausführung:** Supabase-Dashboard des bereits
zuvor sichtbar bestätigten Production-Projekts `project/ydiihvzcxaaoqhmgoqvu`.

**RLS-Warnung des Editors und die Entscheidung dazu.** Wie bei Schritt 3 warnte
Supabase statisch vor einer Tabelle ohne RLS. Es wurde wie auditiert
**„Run without RLS"** gewählt: die statische Warnung bewertet nur das
`create table` der Audit-Payload, nicht die Fortsetzung derselben Transaktion.
`04` aktiviert RLS selbst innerhalb dieser Transaktion und entzieht anschließend
die Rechte.

**Korrektur (2026-08-23, nachträglich).** Hier stand vorher, Schritt 5 belege das
— „`audit_payload` PASS, keine App-Rechte". **Das ist falsch.**
`05_verify_read_only.sql` vergleicht die Payload ausschließlich **inhaltlich**
(10 Zeilen, 0 Feldabweichungen) und liest weder `pg_class.relrowsecurity` noch
`pg_policy` noch `relacl`/`nspacl` der Payload. Aus dem PASS von `audit_payload`
folgt **keine** Aussage über RLS, Policies oder Rechte dieser Tabelle. Belegt ist
bisher nur: die Datei `04` **enthält** `enable row level security` und
`revoke all … from public, anon, authenticated`, und der lokale Harness misst
diesen Zustand nach `04` (`assert_after_04.sql`: RLS aktiv, 0 App-Grants).

**Nachtrag (2026-08-23, später am selben Tag).** Der **Production-Zustand** der
Payload-Absicherung war zum Zeitpunkt der obigen Korrektur nicht gemessen.
Inzwischen ist er es: `05b_verify_payload_security_read_only.sql` ist nach
eigener ausdrücklicher read-only Freigabe auf Production ausgeführt worden —
9 harte PASS, 0 FAIL, darunter `payload_rls` = true, `payload_policies` = 0 und
keine direkten oder effektiven Rechte für PUBLIC, `anon` und `authenticated`
(siehe „5b"). Die Aussage stützt sich damit auf eine Messung auf Production,
nicht mehr nur auf den Dateiinhalt von `04` und den lokalen Harness.

**Ergebnis des Runs.** Meldung des Benutzers: **„Success. No rows returned"**.

**Grenze der Beleglage — ausdrücklich festgehalten.** Wie bei Schritt 2 und 3
wurde der Text manuell in den SQL-Editor eingefügt; **der Editorinhalt wurde
nicht bytegenau gehasht**. Ein Editor-Hash des tatsächlich eingefügten Textes
liegt nicht vor. Die Belegkette lautet exakt:

1. die lokale Quelldatei ist auditiert (Hashes oben),
2. das Ziel war zum Ausführungszeitpunkt sichtbar als Production bestätigt,
3. der Benutzer meldet den Run als erfolgreich,
4. die **unabhängige read-only Nachprüfung** `05_verify_read_only.sql` auf
   derselben Datenbank zeigt genau den Zustand, den diese Datei erzeugen soll —
   feldgenau gegen die persistierte Audit-Payload.

Punkt 4 trägt die Aussage über den Datenbankzustand, nicht Punkt 3.

**Was daraus folgt.** Der Backfill ist vollständig und ausschließlich auf den
zehn Zielprodukten angekommen; die Zahlen stehen in „5. Read-only Nachprüfung →
Ausführung am 2026-08-23". Beide bewusst unveränderten Punkte sind bestätigt
geblieben: `divoom-pixoo-led-panel.price_cents` ist weiterhin NULL, und der
Zeitangaben-Widerspruch bei `n4-nussmilchbereiter-pflanzenmilch` ist unverändert
(INFO-Zeile in `05`).

### 5. Read-only Nachprüfung

Datei: `05_verify_read_only.sql`

- Status: **am 2026-08-23 nach Schritt 4 auf Production ausgeführt**, Datei
  unverändert (MD5 `a5c709087d02a0adb6e582e576403834`). Der Snapshot-Postcheck
  `03_verify_snapshot_read_only.sql` gehört zu Schritt 3 und war kein Ersatz
  für diese Datei; `05` lief planmäßig erst nach Schritt 4.
- Writes: keine.
- Erwartet: Snapshot 10, Zielprodukte 10/10 published, vollständig befüllt 10,
  persistente Audit-Payload 10 mit 0 Inhaltsabweichungen, Value-Add global exakt
  10, Verteilung 3/2/5, 0 inkonsistente Relationen, 0 defekte Relationsziele,
  10 geänderte lastmods und Divoom-Preis NULL.
- **Nicht Gegenstand dieser Datei:** RLS, Policies, Primärschlüssel,
  Spaltenform und Rechte der Audit-Payload. `05` liest dafür keinen einzigen
  Katalogwert. Diese Prüfungen stehen in
  `05b_verify_payload_security_read_only.sql` (siehe 5b). Diese Datei ist
  inzwischen **auf Production ausgeführt und bestanden**.
- Jede FAIL-Zeile: kein Commit, Merge oder Deploy; Rollback-Entscheidung mit
  Benutzer abstimmen. Es gab keine FAIL-Zeile.

#### Ausführung am 2026-08-23

**Freigabe.** Der Benutzer hat Schritt 5 ausdrücklich, projektbezogen und
ausdrücklich als read-only freigegeben: „Ich gebe Production-Schritt 5
(read-only) auf `ydiihvzcxaaoqhmgoqvu` frei."

**Statische Vorabprüfung.** Codex hat `05_verify_read_only.sql` unmittelbar vor
dem Lauf noch einmal statisch geprüft: **genau ein lesendes `with … select`**,
kein DDL, kein DML. Die Datei ist unverändert:

```
MD5     a5c709087d02a0adb6e582e576403834
SHA-256 2c01c03703eadea2d989b2ac579272fdd768532e2984346a01c02de222bf56fb
Größe   8172 Bytes, 199 Zeilen
```

**Ausführungsweg.** **Manuell durch den Benutzer**, unverändert, im SQL-Editor
desselben sichtbar bestätigten Production-Projekts
`project/ydiihvzcxaaoqhmgoqvu`.

**Ergebnis: exakt 16 Zeilen, 14 PASS, 2 INFO, 0 FAIL.**

| Prüfung | Ist | Status |
|---|---|---|
| `produkte` | 376 | INFO |
| `pilot_artefakte` | 0 | PASS |
| `schema` | 8/8, 2/2 | PASS |
| `snapshot_zeilen` | 10 | PASS |
| `zielprodukte_published` | 10/10 | PASS |
| `audit_payload` | 10 Zeilen, 0 Abweichungen | PASS |
| `vollstaendig_befuellt` | 10 | PASS |
| `value_add_irgendwo` | 10 | PASS |
| `alternativen` | 3 | PASS |
| `ergaenzungen` | 2 | PASS |
| `ohne_relation` | 5 | PASS |
| `inkonsistente_relationen` | 0 | PASS |
| `defekte_relationsziele` | 0 | PASS |
| `geaenderte_lastmods` | 10 | PASS |
| `divoom_preis_null` | 1 | PASS |
| `n4_zeittext_unveraendert` | bekannter 2-vs-15-Minuten-Widerspruch | INFO |

**Unabhängige Zählung.** Codex hat das vom Benutzer gelieferte Ergebnis
unabhängig nachgezählt: 16 erwartete Prüfungen, 14 PASS, 2 INFO, 0 FAIL — kein
Unterschied zur Meldung.

**Was daraus folgt.** `value_add_irgendwo` = 10 belegt, dass **in der gesamten
Tabelle** genau zehn Zeilen Value-Add-Daten tragen: der Backfill hat die
366 übrigen Produkte nicht angefasst. `audit_payload` mit 10 Zeilen und
0 Abweichungen belegt den Inhalt feldgenau gegen die in derselben Transaktion
persistierte Payload, nicht nur die Anzahl. Die Verteilung 3/2/5 und
0 inkonsistente Relationen bzw. 0 defekte Relationsziele entsprechen exakt der
lokal getesteten Erwartung (`LOCAL_POSTGRES_TEST_REPORT.md`, Abschnitt 5.5).

**Die beiden INFO-Zeilen sind keine Fehler.** `produkte` = 376 ist der
unveränderte Bestand. `n4_zeittext_unveraendert` meldet den **bewusst nicht
angefassten** Widerspruch zwischen Tagline (2 Minuten) und Beschreibung
(15 Minuten) bei `n4-nussmilchbereiter-pflanzenmilch`. Er ist damit weiterhin
offen und gehört in einen eigenen redaktionellen Vorgang, nicht in dieses
Changeset.

**Nicht belegt.** Auch dieser Lauf sagt nichts über den Lock-Timeout unter
realer Nebenläufigkeit (er ist read-only und traf keinen Sperrkonflikt) und
nichts über den byteweisen Editorinhalt von Schritt 4. **Und er sagt nichts über
die Absicherung der Audit-Payload**: RLS, Policies, Primärschlüssel,
Spaltenform sowie Tabellen- und Schemarechte von
`cbb_private_backup.value_add_payload_v1` sind in `05` überhaupt nicht abgefragt
— das PASS bei `audit_payload` ist ein reiner Inhaltsvergleich. Diese Ebene ist
inzwischen durch den **eigenen** Production-Lauf von `05b` gemessen (siehe 5b);
sie folgt weiterhin **nicht** aus diesem Lauf von `05`.

### 5b. Read-only Sicherheitsprüfung der Audit-Payload — auf Production ausgeführt

Datei: `05b_verify_payload_security_read_only.sql`

- Status: **am 2026-08-23 nach eigener ausdrücklicher read-only Freigabe auf
  Production ausgeführt und bestanden** — 16 Zeilen, 9 harte PASS, 7 INFO,
  0 FAIL (siehe „Ausführung am 2026-08-23" unten). Vorher war die Datei bereits
  lokal positiv und negativ getestet und auditiert (siehe „Lokaler Test").
- Warum es sie gibt: `05` prüft die Payload inhaltlich,
  `03_verify_snapshot_read_only.sql` prüft die Absicherung des **Snapshots**.
  Für die in Schritt 4 neu erzeugte **Payload** gab es kein
  Production-Gegenstück. Diese Lücke ist mit dieser Datei **auf Production
  geschlossen**.
- Writes: keine. Genau ein lesendes `with … select`, ein einziges Semikolon am
  Dateiende, kein DDL, kein DML, kein `do $$`.
- Fail-closed: die direkten `::regclass`-Referenzen auf
  `cbb_private_backup.value_add_payload_v1` brechen bei fehlender Tabelle
  bereits die Planung ab.
- Geprüft (hart): Payload vorhanden, exakt 10 Zeilen, RLS aktiv, 0 Policies,
  genau 1 Primärschlüssel und dieser exakt auf `(slug)`, exakt 10 Spalten mit
  exakt den 10 erwarteten Namen, Rollen `anon` und `authenticated` beide
  vorhanden (2/2), keine Tabellenrechte für PUBLIC/`anon`/`authenticated`, keine
  Schemarechte für PUBLIC/`anon`/`authenticated`. Die Rollenpräsenz ist eigene
  harte Zeile **und** Bedingung beider Rechte-Prüfungen — eine fehlende Rolle
  ergibt FAIL, nicht stilles PASS.
- **Beide Rechte-Prüfungen messen zweifach, korrigiert am 2026-08-23.** Neben
  den direkten ACL-Einträgen (`aclexplode`, Grantees PUBLIC/`anon`/
  `authenticated`) werden für `anon` und `authenticated` zusätzlich die
  **effektiven** Privilegien gezählt: Tabelle über `has_table_privilege` für
  `SELECT`/`INSERT`/`UPDATE`/`DELETE`/`TRUNCATE`/`REFERENCES`/`TRIGGER`, Schema
  über `has_schema_privilege` für `USAGE`/`CREATE`. Grund: `aclexplode` sieht
  nur Einträge, deren Grantee **direkt** PUBLIC, `anon` oder `authenticated`
  ist. Erbt eine der beiden Rollen ein Recht über eine **Rollenmitgliedschaft**,
  bleiben die direkten Zähler 0 und die Prüfung meldete vorher fälschlich PASS
  — ein Fail-open-Randfall. Er ist geschlossen: PASS nur bei Rollenpräsenz 2/2
  **und** direkten Zählern 0 **und** effektiven Privilegien 0. Die Ist- und
  Erwartet-Texte weisen beide Messungen getrennt aus
  (`… | direkte ACL: PUBLIC 0, anon 0, authenticated 0 | effektiv: anon 0,
  authenticated 0`). PUBLIC hat keine Rollen-OID und damit keinen eigenen
  `has_*_privilege`-Aufruf; PUBLIC-Rechte sind in der effektiven Messung bereits
  enthalten, weil sie jeder Rolle zugerechnet werden.
- Nur INFO, ausdrücklich **ohne** PASS-Zusage: `current_user`,
  `current_database` und fünf `service_role`-Zeilen (Rollenexistenz inkl.
  `bypassrls`, direkte ACL-Einträge auf Tabelle und Schema, effektive Tabellen-
  und Schemaprivilegien). Grund: `04` revoked `service_role` nicht explizit, und
  die bisherige Policy dieses Changesets definiert als „App-Rollen" genau `anon`
  und `authenticated` — dieselbe Definition, die `03_verify_snapshot_read_only.sql`
  und der lokale `assert_after_04.sql` verwenden. Eine Aussage über
  `service_role` braucht einen eigenen, getrennt freigegebenen Vorgang.
- Erwartete Ausgabe: **16 Zeilen — 9 harte PASS (Sortierung 30 bis 110) und
  7 INFO (10, 20, 200 bis 240)**, deterministisch nach `sortierung` sortiert.
- Auditierter lokaler Dateistand:

```
MD5     e5275a5fe11fb8b38704d4ee28dd68a7
SHA-256 749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e
Größe   21564 Bytes, 483 Zeilen
```

  Der vorherige Stand (MD5 `e6a99f1a1df49e1becfd3caa712c008b`, SHA-256
  `567bb84c890101a46fc2dd3a8b050674aa35e31ae1ea0692690ba2d920c43bc7`, 17174
  Bytes, 400 Zeilen) ist durch die Fail-open-Korrektur oben ersetzt und **nicht
  mehr zu verwenden**. Er war ebenfalls nie freigegeben und nie ausgeführt.

- **Lokaler Test am 2026-08-23 — bestanden.** Codex hat die Datei unabhängig
  gegen einen frischen temporären PostgreSQL-16-Cluster (nur Unix-Socket,
  Production-ähnliche Fixture, lokal `02` → `03` → `04`) ausgeführt: ein
  positiver und neun negative Fälle, alle mit exakt dem erwarteten Ergebnis
  (`ALL_05B_LOCAL_CASES=PASS`). Der positive Fall lieferte gemessen
  **16 Zeilen, 9 PASS, 7 INFO, 0 FAIL, Exit 0**. Die negativen Fälle trafen
  jeweils genau die zuständige Zeile: `rls_disabled` → `payload_rls`,
  `extra_policy` → `payload_policies`, `direct_table_grant` bzw.
  `direct_schema_grant` → die jeweilige Rechtezeile, `extra_column` →
  `payload_spalten`, `missing_primary_key` → `payload_primaerschluessel`.
  `inherited_grants` erzeugte genau 2 FAIL (beide Rechtezeilen) und beweist
  damit die **effektive** Mitgliedschaftsprüfung; `missing_app_role` erzeugte
  genau 3 FAIL; `missing_table` brach fail-closed mit psql-Exit 3 und
  „relation does not exist" **vor** jeder Ausgabe ab. Die Datei blieb dabei
  unverändert (Hashes oben), Cluster-Stop und Temp-Cleanup PASS, kein
  Production- oder Pilot-Kontakt. Details:
  `LOCAL_POSTGRES_TEST_REPORT.md`, Abschnitt 16.
- **Abgrenzung:** Das war ein **eigener lokaler Test**, **nicht** Teil der drei
  Harness-Läufe mit 73/73 PASS. Der bestehende Harness und die Dateien `01` bis
  `07` blieben unverändert.
- **Grenze des lokalen Laufs:** Er belegt das Verhalten der Datei, nicht den
  Zustand von Production. Den Production-Zustand belegt erst der eigene
  Production-Lauf unten.

#### Ausführung am 2026-08-23

**Freigabe.** Der Benutzer hat `05b` ausdrücklich, projektbezogen und
ausdrücklich als read-only freigegeben: „Ich gebe Production-Schritt 5b
(read-only Payload-Sicherheitsprüfung) auf `ydiihvzcxaaoqhmgoqvu` frei."

**Ausführungsweg.** **Manuell durch den Benutzer**, im SQL-Editor desselben
sichtbar bestätigten Production-Projekts `project/ydiihvzcxaaoqhmgoqvu`, aus der
finalen auditierten lokalen Datei. Der Dateistand blieb dabei unverändert und
ist es auch danach:

```
MD5     e5275a5fe11fb8b38704d4ee28dd68a7
SHA-256 749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e
Größe   21564 Bytes, 483 Zeilen
```

Statisch erneut bestätigt: **genau ein read-only `with … select`**, kein DDL,
kein DML.

**Ergebnis: exakt 16 Zeilen, 9 PASS, 7 INFO, 0 FAIL.**

| Prüfung | Ist | Status |
|---|---|---|
| `current_user` | `postgres` | INFO |
| `current_database` | `postgres` | INFO |
| `payload_tabelle_vorhanden` | true | PASS |
| `payload_zeilen` | 10 | PASS |
| `payload_spalten` | 10 gesamt, 10 erwartete Namen | PASS |
| `payload_rls` | true | PASS |
| `payload_policies` | 0 | PASS |
| `payload_primaerschluessel` | PK 1, davon PK(slug) 1 | PASS |
| `app_rollen_vorhanden` | 2/2 | PASS |
| `payload_tabellenrechte_app_rollen` | Rollen 2/2 · direkte ACL: PUBLIC 0, anon 0, authenticated 0 · effektiv: anon 0, authenticated 0 | PASS |
| `payload_schemarechte_app_rollen` | Rollen 2/2 · direkte ACL: PUBLIC 0, anon 0, authenticated 0 · effektiv: anon 0, authenticated 0 | PASS |
| `service_role_vorhanden` | ja · bypassrls true | INFO |
| `service_role_tabellen_acl` | keine | INFO |
| `service_role_schema_acl` | keine | INFO |
| `service_role_tabellenrechte_effektiv` | keine | INFO |
| `service_role_schemarechte_effektiv` | keine | INFO |

Die beiden Rechtezeilen enthalten im Original je zwei Pipe-Zeichen als
Trennzeichen im Ist-Text; sie sind hier als „·" wiedergegeben, damit die
Markdown-Tabelle sie nicht als zusätzliche Spalten liest. Der Schlusswert war in
beiden Fällen eindeutig **PASS**.

**Unabhängige Zählung.** Codex hat die 16 Ergebniszeilen unabhängig
rekonstruiert und gegen die erwartete Matrix abgeglichen: 9 PASS, 7 INFO,
0 FAIL — kein Unterschied zur Meldung und keine fehlende Zeile.

**Was daraus folgt.** Die Absicherung der Audit-Payload
`cbb_private_backup.value_add_payload_v1` ist auf Production **gemessen und
belegt**: die Tabelle existiert mit exakt zehn Zeilen und exakt zehn erwarteten
Spalten, RLS ist aktiv, es gibt keine Policy, der Primärschlüssel ist genau
`PK(slug)`, beide App-Rollen existieren, und weder PUBLIC noch `anon` noch
`authenticated` haben Rechte — weder direkt noch über Rollenmitgliedschaft
geerbt, weder auf der Tabelle noch auf dem Schema. Damit gilt für die Payload
dieselbe belegte Absicherung wie für den Snapshot aus Schritt 3.

**`service_role` bleibt INFO — keine allgemeine Zusage.** Gemessen wurde für
diesen Zustand: `service_role` existiert, ist `bypassrls`, hat **keine** direkten
ACL-Einträge auf Tabelle oder Schema und **keine** effektiven Tabellen- oder
Schemarechte. Das ist ein Ist-Wert, keine PASS-Bedingung dieses Changesets und
keine generelle Sicherheitszusage für diese Rolle — `04` entzieht `service_role`
nichts explizit, und eine Bewertung dieser Rolle braucht weiterhin einen eigenen,
getrennt freigegebenen Vorgang.

**Nicht belegt.** Der Lauf ist read-only und traf keinen Sperrkonflikt; er sagt
nichts über den Lock-Timeout unter realer Nebenläufigkeit und nichts über den
byteweisen Editorinhalt der Schritte 2 bis 4.

**Für jeden künftigen Lauf gilt unverändert:** sichtbares Projekt
`project/ydiihvzcxaaoqhmgoqvu` kontrollieren und eine eigene, ausdrückliche
read-only Freigabe einholen — die Freigabe vom 2026-08-23 war auf diese Datei
beschränkt und ist verbraucht. Bei jeder FAIL-Zeile nichts korrigieren, nichts
nachgranten, nichts löschen — Befund melden.

#### Hinweis: live gesetzte `updated_at`-Werte vs. nicht deployter Code

Die zehn `updated_at`-Werte aus Schritt 4 sind **jetzt in der
Production-Datenbank live**. Sobald die Sitemap revalidiert, können daraus neue
`lastmod`-Signale entstehen — während die zugehörigen Website-Code-Änderungen
dieses Branches **noch nicht deployed** sind.

Das ist **kein Datenfehler**: die Werte sind genau die zehn Seiten, die
sichtbaren neuen Inhalt bekommen haben, und die Felder werden serverseitig
gelesen, sobald sie gerendert werden. Es ist eine reine
Reihenfolge-Beobachtung. Sinnvoll ist deshalb ein **zeitnaher, getrennter
Code-/Deploy-Audit** der Frontend-Seite (Rendering der Value-Add-Felder,
Sitemap-/`lastmod`-Pfad, Revalidation), damit Datenstand und Auslieferung nicht
länger als nötig auseinanderlaufen.

**Merge und Deploy bleiben ausdrücklich gesperrt.** Dieser Hinweis ist eine
Empfehlung für den nächsten Audit-Zyklus, keine Freigabe für Commit, Merge, Push
oder Deploy.

## Rollback

### Daten-Restore

Datei: `06_restore_value_add.sql`

- Nur mit neuer Freigabe.
- Spielt `editorial_note`, `updated_at` und alle acht Value-Add-Felder für exakt
  zehn Produkte aus Snapshot v1 zurück.
- Rowcount muss 10 und Snapshot-Abweichung vor Commit 0 sein.
- Der Snapshot wird nicht gelöscht.
- Die private Audit-Payload wird ebenfalls nicht gelöscht. Nach einem Restore
  bricht ein erneuter Backfill deshalb absichtlich fail-closed ab. Ein Retry
  benötigt einen neuen Audit und eine separate Freigabe für die bewusste
  Bereinigung bzw. Versionierung der alten Payload; dieses Runbook löscht sie
  nicht.
- Falls ein unbekannter Trigger `updated_at` überschreibt, scheitert die
  Null-Diff-Prüfung und die gesamte Restore-Transaktion rollt zurück.

### Schema-Down

Datei: `07_down_migration.sql`

- Destruktiv; separate ausdrückliche Freigabe erforderlich.
- Erst nach erfolgreichem Daten-Restore.
- Prüft vorab, dass alle zehn Produktzeilen exakt dem Snapshot entsprechen.
- Entfernt nur beide Value-Add-Constraints und die acht Value-Add-Spalten.
- `editorial_note`, `updated_at`, Produktzeilen, Snapshot und private
  Audit-Payload bleiben erhalten.

## Bewusst außerhalb dieses Changesets

- `seo_updated_at_trigger.sql`
- `backfill_lastmod_20260704.sql` und `fix_lastmod_timezone_20260704.sql`
- Production-Commit, Merge oder Push nach `main`
- Vercel-Deploy
- Search-Console- oder andere externe Schreibaktionen
- Pilot-Marker-Nachrüstung, Pilot-Reset oder erneute Pilot-SQL-Ausführung

Der 236er Lastmod-Backfill und der Trigger benötigen einen eigenen Audit-Zyklus.
Der lokale Sicherheitsfehler `dry_run := false` im 236er Skript wurde unabhängig
von diesem Runbook wieder auf `true` gestellt; das Skript wird hier trotzdem
nicht ausgeführt. **Seit Schritt 4 stimmen seine hart codierten Erwartungen
nicht mehr**: `n4-nussmilchbereiter-pflanzenmilch`,
`ninja-staysharp-messerset-6-teilig` und
`welpen-usb-ladekabel-hunde-design` besitzen jetzt bereits neue `updated_at`-
Werte. Es bleiben zwar weiterhin 236 Slugs in der historischen Zielmenge,
aber nur noch 233 erfüllen die Bedingung `updated_at < ziel_zeit`. Die aktuelle
einzelne Variable `erwartet` kann diese zwei verschiedenen Werte nicht
abbilden; sie darf insbesondere nicht pauschal auf 233 gesetzt werden. Beide
Lastmod-Dateien bleiben deshalb gesperrt, bis Zielmenge und betroffene Menge
getrennt aus Production neu hergeleitet, im SQL getrennt geprüft, auditiert und
freigegeben wurden.

## Aktueller Haltepunkt

Stand 2026-08-23.

**Erledigt.** Schritt 1 (Read-only-Preflight) ist auf Production ausgeführt und
auditiert. `02`, `03`, `04`, `06` und `07` wurden wegen der Timeout-Reichweite
geändert (siehe „Reichweite der Zeitgrenzen"), ihre Hashes sind dadurch neu; der
lokale Harness wurde im selben Zug verschärft. Der vollständige verschärfte
Harness ist auf genau diesen **geänderten** Dateien **zweimal gelaufen und
bestanden** — je Exit 0, je 73 von 73 Schritten PASS, 0 FAIL — und wurde von
Codex unabhängig ausgeführt und auditiert. Belege: `LOCAL_POSTGRES_TEST_REPORT.md`,
Abschnitt 7. Unmittelbar vor Schritt 4 lief derselbe Harness ein drittes Mal
vollständig durch — 73/73 PASS, 0 Abweichungen, Exit 0 (Abschnitt 13.1). `01`
und `05` sind als Dateien unverändert; `05` ist inzwischen ausgeführt. Die neue
`05b_verify_payload_security_read_only.sql` ist **nicht** Teil dieser
Harness-Läufe: sie ist danach entstanden und wurde in einem **eigenen** lokalen
Test geprüft (10 von 10 Fällen wie erwartet, Bericht Abschnitt 16) und
anschließend auf Production ausgeführt (Bericht Abschnitt 17). Der Harness selbst
blieb dabei unverändert bei 73 Schritten; `05b` ist auch als Datei unverändert.

**Ebenfalls erledigt: Schritt 2.** `02_migrate_value_add.sql` ist am 2026-08-23
nach ausdrücklicher Benutzerfreigabe auf `project/ydiihvzcxaaoqhmgoqvu`
ausgeführt worden — einmalig, manuell durch den Benutzer, mit dem Ergebnis
„Success. No rows returned". Der anschließende unabhängige read-only Postcheck
mit der unveränderten `01` meldet 9 harte PASS, 0 FAIL, Schema `8/8 + 2/2`, 376
Produkte, `value_add_bereits_befuellt` 0 und `production_snapshot` FEHLT. Der
Editorinhalt wurde dabei **nicht** bytegenau gemessen; die vollständige
Belegkette und ihre Grenze stehen in „2. Additive Migration → Ausführung am
2026-08-23".

**Ebenfalls erledigt: Schritt 3.** `03_backup_value_add.sql` (MD5
`acacd1b3180d1f9a7bad55789f194f8d`) ist am 2026-08-23 nach ausdrücklicher
Benutzerfreigabe („Ich gebe Production-Schritt 3 auf `ydiihvzcxaaoqhmgoqvu`
frei.") auf demselben sichtbar bestätigten Production-Projekt ausgeführt worden
— manuell durch den Benutzer, Ergebnis `backup_rows = 10`. Der anschließende
unabhängige read-only Postcheck mit `03_verify_snapshot_read_only.sql` (finaler
Stand MD5 `f38d182d7611ae8dbace3609208bf95a`) liefert 17 Zeilen: 2 INFO,
**15 harte PASS, 0 FAIL**. Auch hier gilt: der manuell eingefügte Editorinhalt
ist **nicht** bytegenau gemessen; den Datenbankzustand belegt der Postcheck.
Details in „3. Privater Snapshot → Ausführung am 2026-08-23".

**Ebenfalls erledigt: Schritt 4.** `04_backfill_value_add.sql` (MD5
`a0d6cd3adfca22638f382f28b9c3dbee`) ist am 2026-08-23 nach ausdrücklicher
Benutzerfreigabe („Ich gebe Production-Schritt 4 auf `ydiihvzcxaaoqhmgoqvu`
frei.") auf demselben, bereits sichtbar bestätigten Production-Projekt
ausgeführt worden — manuell durch den Benutzer im Supabase-Dashboard, Ergebnis
„Success. No rows returned". Bei der statischen RLS-Warnung wurde wie auditiert
„Run without RLS" gewählt, weil `04` RLS selbst innerhalb derselben Transaktion
aktiviert. Unmittelbar vorher lief der verschärfte lokale Harness noch einmal
vollständig: **73/73 PASS, 0 Abweichungen, Exit 0**, Temp-Cluster danach
gestoppt. Auch hier gilt: der manuell eingefügte Editorinhalt ist **nicht**
bytegenau gehasht; den Datenbankzustand belegt Schritt 5. Details in
„4. Atomarer Backfill → Ausführung am 2026-08-23".

**Ebenfalls erledigt: Schritt 5.** `05_verify_read_only.sql` (unverändert, MD5
`a5c709087d02a0adb6e582e576403834`) ist am 2026-08-23 nach ausdrücklicher
read-only Benutzerfreigabe („Ich gebe Production-Schritt 5 (read-only) auf
`ydiihvzcxaaoqhmgoqvu` frei.") ausgeführt worden. Codex hatte die Datei
unmittelbar davor statisch als **ein einziges read-only Statement ohne DDL/DML**
geprüft. Ergebnis: **16 Zeilen, 14 PASS, 2 INFO, 0 FAIL** — von Codex unabhängig
nachgezählt und bestätigt. Vollständige Tabelle in „5. Read-only Nachprüfung →
Ausführung am 2026-08-23".

**Ebenfalls erledigt: Schritt 5b.**
`05b_verify_payload_security_read_only.sql` (unverändert, MD5
`e5275a5fe11fb8b38704d4ee28dd68a7`, SHA-256
`749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e`, 21564 Bytes,
483 Zeilen, genau ein read-only `with … select`) ist am 2026-08-23 nach eigener
ausdrücklicher read-only Benutzerfreigabe („Ich gebe Production-Schritt 5b
(read-only Payload-Sicherheitsprüfung) auf `ydiihvzcxaaoqhmgoqvu` frei.")
manuell durch den Benutzer im sichtbar bestätigten Production-SQL-Editor
ausgeführt worden. Ergebnis: **16 Zeilen, 9 PASS, 7 INFO, 0 FAIL** — von Codex
unabhängig rekonstruiert und gegen die erwartete Matrix abgeglichen.
Vollständige Tabelle in „5b → Ausführung am 2026-08-23".

Stand jetzt: Produktbestand unverändert 376, privater Snapshot v1 mit exakt zehn
Zeilen, RLS aktiv, keine App-Rechte, **Backfill vollständig auf genau zehn
Produkten**, persistente Audit-Payload mit 10 Zeilen und 0 Inhaltsabweichungen,
Value-Add global exakt 10, Verteilung 3/2/5, 0 inkonsistente Relationen,
0 defekte Relationsziele, 10 geänderte `updated_at`-Werte, Divoom-Preis
weiterhin NULL. Zwei INFO-Zeilen in `05`, keine FAIL-Zeile.

Die Angaben „RLS aktiv, keine App-Rechte" im vorigen Absatz gelten auf
Production inzwischen für **beide** privaten Tabellen: für den **Snapshot**
`value_add_pre_backfill_v1` durch `03_verify_snapshot_read_only.sql` und für die
**Audit-Payload** `value_add_payload_v1` durch den Production-Lauf von `05b`
(RLS aktiv, 0 Policies, PK genau auf `slug`, 10/10 erwartete Spalten, keine
direkten und keine effektiven Rechte für PUBLIC, `anon`, `authenticated`). Der
Inhalt der Payload ist zusätzlich durch `05` feldgenau belegt (10 Zeilen,
0 Abweichungen). **Nicht** in dieser Zusage enthalten ist `service_role`: für sie
liegen nur INFO-Werte vor (existiert, `bypassrls` true, keine direkten und keine
effektiven Tabellen-/Schemarechte) — ein dokumentierter Ist-Zustand, keine harte
Zusage.

**Nächster Schritt: keiner ist freigegeben.** Die Schritte 1 bis 5b sind
ausgeführt und inhaltlich auditiert; damit ist der geplante Pfad dieses
Changesets auf der Datenbank vollständig — schreibend wie prüfend. **Kein
weiterer Production-DB-Schritt ist freigegeben.** Die Freigaben für die Schritte
4, 5 und 5b waren jeweils auf ihre Datei beschränkt und sind verbraucht. Dieses
Dokument erteilt keine neue Freigabe.

**Geschlossen: der frühere read-only Freigabepunkt.**
`05b_verify_payload_security_read_only.sql` (Abschnitt 5b) hat die Prüfungslücke
bei der Payload-Absicherung geschlossen — lokal positiv und negativ getestet
(10 von 10 Fällen wie erwartet, Bericht Abschnitt 16) und danach nach eigener
Freigabe auf Production ausgeführt und bestanden.

> **Überholt (historisch).** Hier stand vor dem Production-Lauf: „Offen als
> nächster ausdrücklicher read-only Freigabepunkt … **weiterhin nicht
> freigegeben und nicht auf Production ausgeführt** … diese bleibt ungemessen."
> Das ist erledigt.

**Weiterhin gesperrt.**

- `06_restore_value_add.sql` und `07_down_migration.sql` sind **nicht
  ausgeführt**. Sie sind reine Rollback-Artefakte und brauchen jeweils eine
  eigene, ausdrückliche neue Freigabe nach erneuter sichtbarer Zielprüfung
  `project/ydiihvzcxaaoqhmgoqvu`. `07` zusätzlich erst nach erfolgreichem
  Restore.
- Commit, Merge, Push nach `main` und Vercel-Deploy.
- Die beiden Lastmod-Dateien und der Trigger (siehe „Bewusst außerhalb dieses
  Changesets") — die Erwartungen des 236er-Skripts stimmen seit Schritt 4 nicht
  mehr.

Weder die lokalen Testläufe noch die abgeschlossenen Schritte 1 bis 5b sind eine
Freigabe für irgendeine weitere Aktion.

**Nächster sinnvoller Vorgang — rein lokal, ohne Freigabe.** Ein
**Code-/Deploy-Readiness-Audit** des Frontends: Rendering der Value-Add-Felder,
Sitemap-/`lastmod`-Pfad und Revalidation. Grund ist der Hinweis am Ende von
Abschnitt 5b — die zehn `updated_at`-Werte sind live, die zugehörigen
Code-Änderungen sind es nicht. **Dieser Audit ist ausdrücklich keine Freigabe für
Merge oder Deploy**; beide bleiben gesperrt, und der Audit selbst läuft ohne
Datenbank-, Netzwerk- oder Git-Aktion. Ebenfalls offen bleibt der redaktionelle
2-vs-15-Minuten-Widerspruch bei `n4-nussmilchbereiter-pflanzenmilch`.
