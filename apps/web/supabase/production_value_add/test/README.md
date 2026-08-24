# Lokaler PostgreSQL-Harness für den Value-Add-Rollout

Testet die **Originaldateien** `01_preflight_read_only.sql` bis
`07_down_migration.sql` aus dem übergeordneten Verzeichnis gegen eine echte
PostgreSQL-16-Instanz. Der Harness kopiert und schreibt keine dieser Dateien um
— er führt sie so aus, wie sie später im Supabase-Editor laufen würden.

> **Stand 2026-08-23, zweite Runde.** Der erste Lauf hatte einen echten Befund
> gemeldet (`lock_timeout` deckte die Guard-Phase nicht ab, Schritt 064 lief in
> den Client-Timeout). Der Befund ist inzwischen **in den Rollout-Dateien
> korrigiert**: in `02`, `03`, `04`, `06` und `07` stehen beide `set local`-Zeilen
> jetzt unmittelbar hinter `begin;`. Gleichzeitig wurden die Erwartungen dieses
> Harness verschärft (siehe „Wie streng geprüft wird"). Die Rollout-Dateien sind
> damit **nicht mehr byte-identisch** mit dem am 2026-08-23 im Production-Editor
> ausgeführten `01` — `01` und `05` selbst sind unverändert.

## Was der Harness nicht tut

- Er verbindet sich **nicht** mit Production (`ydiihvzcxaaoqhmgoqvu`).
- Er verbindet sich **nicht** mit Pilot/Staging (`nmzuycveumyfvtxdcnuc`).
- Er öffnet **keinen** TCP-Port: der Cluster läuft mit `listen_addresses=''`
  und ist ausschließlich über einen Unix-Socket im eigenen Temp-Verzeichnis
  erreichbar.
- Er committet, merged, pusht und deployt nichts.

Der Cluster wird in `mktemp -d` angelegt und am Ende über `pg_ctl -m fast stop`
wieder gestoppt — auch, wenn der Lauf vorzeitig abbricht (`trap ... EXIT`).

## Aufruf

```bash
cd apps/web/supabase/production_value_add/test
./run_local_postgres_test.sh
```

Optionen über Umgebungsvariablen:

| Variable | Wirkung |
|---|---|
| `CBB_PG_BIN` | Pfad zu den PostgreSQL-16-Binaries — entweder ein Prefix mit `bin/` (`/usr/lib/postgresql/16`) oder direkt das bin-Verzeichnis (`/usr/lib/postgresql/16/bin`). Ohne die Variable löst der Harness selbst auf: `pg_config --bindir`, sonst das Verzeichnis von `initdb` im `PATH`, sonst `/usr/lib/postgresql/16/bin`, falls vorhanden. Findet er nichts, bricht er mit Exit `2` ab. |
| `CBB_KEEP_CLUSTER=1` | Datenverzeichnis nach dem Lauf behalten (Server wird trotzdem gestoppt) |

Exit-Code `0` = alle Erwartungen erfüllt, `1` = mindestens eine Abweichung,
`2` = Umgebungs-/Setup-Problem (Binaries, `initdb`, `pg_ctl start` oder
`createdb`). Setup-Fehler laufen nicht mehr still weiter.

Liegen die Binaries in einem entpackten Paketbaum statt in `/usr`, setzt das
Skript `LD_LIBRARY_PATH` selbst auf das Verzeichnis mit `libpq.so.5` — ohne das
bricht `initdb` mit Exit 127 ab.

## Fixture

`fixture/` baut den Zustand nach, den `01_preflight_read_only.sql` am
2026-08-23 auf Production gemeldet hat:

| Merkmal | Wert |
|---|---|
| Produkte | 376 |
| Zielprodukte published | 10/10 |
| Relationsziele published | 5/5 |
| Bestehende `editorial_note` in der Zielmenge | 3 |
| Value-Add-Schema | 0/8 Spalten, 0/2 Constraints |
| `products_rls` / Policies | true / 2 |
| App-Grants auf `products` (anon + authenticated) | 14 |
| Trigger | `products_set_updated_at` aus dem echten `seo_updated_at_trigger.sql` |
| Rollen | `anon`, `authenticated`, `service_role` |

Der Trigger wird **nicht** nachgebaut: `fixture_real_trigger` führt die echte
Repo-Datei `apps/web/supabase/seo_updated_at_trigger.sql` aus. `03_assert_fixture.sql`
bricht hart ab, wenn die Fixture von diesem Zielbild abweicht — sonst wären alle
späteren PASS-Zeilen wertlos.

`04_baseline.sql` legt zusätzlich eine unveränderliche Kopie von
`slug`/`editorial_note`/`updated_at` **aller 376 Zeilen** in `cbb_test_baseline`
ab. Nach Restore und Down-Migration wird Zeile für Zeile dagegen verglichen —
nicht nur für die zehn Zielprodukte.

Alle Produkttexte in der Fixture sind Testdaten mit `example.invalid`-Links.
Die drei bestehenden Notizen tragen das Präfix `ALT-NOTE`, damit im Report
sichtbar ist, ob wirklich der Originaltext zurückkam.

## Testfälle

| Fall | Inhalt |
|---|---|
| `case_a_happy_path` | 01 → 02 → 03 → 04 → 05 in der vorgesehenen Reihenfolge |
| `case_b_wiederholungen` | jede schreibende Datei zweimal; 05 vor dem Backfill; 07 vor dem Restore |
| `case_c_rollback` | erzwungener Fehler mitten in der 04-Transaktion, Rollback-Beweis |
| `case_d_rollback_pfad` | 04 → 06 → 06 (idempotent) → 07 → 02 erneut, mit Round-Trip-Vergleich |
| `case_e_pilot_artefakt` | `pilot_meta.environment_guard` vorhanden |
| `case_f_zu_wenig_produkte` | Bestand auf 299 gedrückt |
| `case_g_teilzustand` | 3 von 8 Spalten existieren bereits |
| `case_h_relationsziel_offline` | ein Relationsziel unpublished |
| `case_i_trigger` | Trigger hebt lastmod bei sichtbarer Änderung, nicht bei `price_cents`, und respektiert explizit gesetztes `updated_at` |
| `case_j_lock_timeout` | 02 unter `AccessExclusiveLock` auf `public.products` |

`case_0_statisch` braucht keinen Cluster und läuft vor dem `initdb`. Schlägt er
fehl, bricht der Harness sofort mit Exit 1 ab — ein Lock-Test gegen falsch
platzierte `set local`-Zeilen wäre nicht aussagekräftig.

Jeder DB-Fall bekommt über `createdb -T cbb_fixture` eine frische Datenbank,
läuft also unabhängig von den anderen.

## Wie streng geprüft wird

Diese Regeln sind das Ergebnis des Codex-Reviews der ersten Runde. Vorher
konnten mehrere Klassen echter Fehler als PASS durchgehen.

### 1. Erwartete Abbrüche brauchen den *richtigen* Fehler

`step <db> fail <label> <datei> <literal>` verlangt **beides**:

- psql-Exit **exakt 3** (Server-Exception bei `ON_ERROR_STOP=1`), und
- das übergebene Fehler-Literal muss wörtlich im Output stehen (`grep -F`).

Das Literal ist **Pflicht**. Fehlt es, ist der Schritt FAIL („HARNESS-FEHLER").
Ein Abbruch mit einem *anderen* Fehler ist ebenfalls FAIL. Vorher galt jeder
Exit ≠ 0 als PASS — ein Tippfehler im SQL, eine fehlende Rolle oder ein
abgestürzter Server wären als „fail-closed funktioniert" durchgegangen.

Geprüfte Literale:

| Schritt | Erwarteter Serverfehler |
|---|---|
| `b_02_wiederholung` | `Production-Migration abgebrochen: Migration ist bereits vollstaendig vorhanden.` |
| `b_03_wiederholung` | `Production-Backup abgebrochen: Snapshot v1 existiert bereits.` |
| `b_05_vor_backfill` | `relation "cbb_private_backup.value_add_payload_v1" does not exist` |
| `b_04_wiederholung` | `Production-Backfill abgebrochen: 10 Zielzeilen sind seit dem Snapshot gedriftet.` |
| `b_07_vor_restore` | `Production-Down abgebrochen: Restore nicht exakt (10 Abweichungen).` |
| `c_04_bricht_ab` | `CBB-TEST: UPDATE auf products absichtlich blockiert.` |
| `d_04_nach_restore` | `Production-Backfill abgebrochen: Audit-Payload v1 existiert bereits.` |
| `d_07_wiederholung` | `Production-Down abgebrochen: Migration unvollstaendig (0 Spalten, 0 Typen, 0 Constraints).` |
| `e_02_abbruch` | `Production-Migration abgebrochen: Pilot-Artefakt gefunden.` |
| `f_02_abbruch` | `Production-Migration abgebrochen: nur 299 Produkte (< 300).` |
| `g_02_abbruch` | `Production-Migration abgebrochen: Teilzustand (3 Spalten, 3 Typen, 0 Constraints).` |
| `h_02_abbruch` | `Production-Migration abgebrochen: 4/5 Relationsziele published.` |
| `j_02_unter_sperre` | `canceling statement due to lock timeout` |

### 2. `01` und `05`: exakte PASS-Zahl statt „mehr als 0"

Beide sind read-only und melden Probleme **nicht** über den Exit-Code, sondern
als Zeile mit `status = FAIL`. `report_table <db> <label> <datei> <n>` verlangt
deshalb **exakt** `n` PASS-Zeilen und 0 FAIL-Zeilen:

| Datei | Erwartung |
|---|---|
| `01_preflight_read_only.sql` | exakt **9** PASS, 0 FAIL (dazu 7 INFO-Zeilen, 16 Zeilen gesamt) |
| `05_verify_read_only.sql` | exakt **14** PASS, 0 FAIL (dazu 2 INFO-Zeilen, 16 Zeilen gesamt) |

Vorher genügte „> 0 PASS". Eine versehentlich gelöschte Prüfzeile hätte den
Harness nicht gestört.

### 3. Guard-Abbrüche: exakte Spalten- und Constraint-Zahl

- `cases/assert_no_value_add_schema.sql` verlangt jetzt **exakt 0**
  Value-Add-Spalten und **0** Constraints (genutzt in `case_e`, `case_f`,
  `case_h` und zweimal in `case_j`). Vorher wurde jede Spaltenzahl außer 8
  akzeptiert — ein zurückgebliebener Teilzustand mit 5 von 8 Spalten wäre PASS
  gewesen.
- `cases/assert_partial_state_unchanged.sql` (neu) ist für `case_g` zuständig
  und verlangt **exakt die 3** vor `02` angelegten Spalten (`fuer_wen`,
  `nicht_fuer`, `key_fact`, alle `text`) und **0** Constraints — nicht mehr
  (`02` hätte nachgerüstet) und nicht weniger (`02` hätte aufgeräumt).

### 4. Lock-Test: Exit 3, richtige Meldung, richtige Zeit

`case_j_lock_timeout` verlangt nach der SQL-Korrektur:

- psql-Exit **3**,
- die Meldung `canceling statement due to lock timeout`,
- eine Laufzeit im Fenster **3–15 s** (`lock_timeout = '5s'`).

**Exit 124** (Client-Timeout aus `timeout 30`), ein anderer Fehlertext oder ein
erfolgreicher Durchlauf sind jeweils **FAIL**. Das frühere Ergebnis `BEFUND`,
das den Gesamtlauf trotzdem auf PASS ließ, gibt es nicht mehr.

### 5. Lock-Halter wird terminiert, nicht gekillt

Der Lock-Halter läuft mit einem eindeutigen `application_name`
(`cbb_lock_holder_<workdir>`, gesetzt über `PGAPPNAME`). Beendet wird er über

```sql
select pg_terminate_backend(pid) from pg_stat_activity
where application_name = '<eindeutiger name>';
```

Ein `kill` des psql-Clients beendet das Server-Backend nicht zuverlässig; die
Sperre hätte bis zum Ende von `pg_sleep(90)` weiterbestanden und der Nachtest
`j_02_danach` wäre darauf gelaufen. Der Harness wartet danach aktiv, bis kein
`AccessExclusiveLock` auf `products` mehr granted ist (Schritt
`j_locker_terminiert`), und schlägt fehl, wenn `j_02_danach` länger als 30 s
braucht.

### 6. Statische Prüfung der `SET LOCAL`-Position

`case_0_statisch` prüft für `02`, `03`, `04`, `06` und `07` per awk:

- genau **ein** `begin;`,
- genau **eine** `set local lock_timeout = '5s';`-Zeile und genau **eine**
  `set local statement_timeout = '60s';`-Zeile, insgesamt **zwei**
  `set local`-Zeilen (keine späteren Duplikate),
- `statement_timeout` direkt unter `lock_timeout`,
- beide **hinter** `begin;` und **vor** dem ersten `do $$`-Block,
- zwischen `begin;` und `set local` nur Leerzeilen und `--`-Kommentare, keine
  Anweisung.

Damit ist die Korrektur auch dann belegt, wenn der Lock-Test aus
Umgebungsgründen nicht zur Ausführung käme.

### 7. Setup ist fail-closed

`initdb`, `pg_ctl start`, `createdb cbb_fixture` und jedes `createdb -T
cbb_fixture <fall>` beenden den Harness bei Fehler sofort mit **Exit 2**.
Vorher hätte ein fehlgeschlagenes `createdb` nur den Zähler erhöht und alle
folgenden Schritte gegen eine nicht existierende Datenbank laufen lassen.

## Ergebnisse

Der Lauf schreibt `results.tsv` und ein `logs/`-Verzeichnis in sein
Temp-Verzeichnis und gibt den Pfad am Ende aus. Der ausgewertete Lauf ist in
`../LOCAL_POSTGRES_TEST_REPORT.md` dokumentiert.

Schrittzahl nach der Verschärfung: **73** (vorher 67) — 5 statische Prüfungen,
6 Fixture-Schritte, 8 + 12 + 8 + 15 in den Fällen A–D, je 3 in E–H, 1 in I und
6 in J (inklusive des neuen Schrittes `j_locker_terminiert`).

## Aufräumen

`trap cleanup EXIT` beendet zuerst ein eventuell übriggebliebenes
Lock-Halter-Backend, stoppt dann `pg_ctl -m fast` und entfernt `PGDATA`
**und** das Socketverzeichnis. Bleibt eines von beiden liegen, schreibt der
Harness eine WARNUNG. Mit `CBB_KEEP_CLUSTER=1` bleibt das Verzeichnis stehen;
der Server wird trotzdem gestoppt.
