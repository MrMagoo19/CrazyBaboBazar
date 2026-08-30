# Lokaler Harness — Value-Add Charge 3

Testet die **Originaldateien** aus `../` gegen eine echte PostgreSQL-Instanz.
Es wird nichts kopiert und nichts umgeschrieben: der Harness fuehrt exakt die
Dateien aus, die spaeter im SQL-Editor laufen wuerden.

## Sicherheitsgrenzen

- **Keine** Production- und **keine** Pilot-Datenbank wird angefasst.
- Der Cluster liegt in `$(mktemp -d)`, hoert **nicht** auf TCP
  (`listen_addresses=''`) und wird am Ende gestoppt.
- Keine Datei unter `../` wird veraendert.
- Keine Datei unter `../../production_value_add/` oder
  `../../production_value_add_batch2/` wird veraendert oder ausgefuehrt. Der
  Zustand beider Vorgaengerchargen wird von `fixture/03_v1_v2_artifacts.sql`
  nachgebaut; `V1_V2_MANIFEST.sha256` belegt die Unversehrtheit byteweise.

## Aufruf

```bash
./run_local_postgres_test.sh                       # alles
CBB_STATIC_ONLY=1 ./run_local_postgres_test.sh     # nur CASE 0
CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh    # Datenverzeichnis behalten
CBB_PG_BIN=/usr/lib/postgresql/16 ./run_local_postgres_test.sh
```

## Exit-Codes

| Code | Bedeutung |
|---|---|
| 0 | alle Erwartungen erfuellt |
| 1 | mindestens eine Abweichung |
| 2 | Umgebungsproblem (Binaries, `initdb`, Serverstart, `createdb`) — **weder PASS noch FAIL** |

## Aufbau

```
fixture/
  00_roles.sql            anon, authenticated, service_role
  01_schema.sql           Production-aehnliches Schema, Stand nach Batch 1 und 2
  02_seed.sql             376 Produkte, 372 published, 20 mit Value-Add
  03_v1_v2_artifacts.sql  die vier privaten v1-/v2-Tabellen
  04_assert_fixture.sql   Selbstpruefung der Fixture
  05_baseline.sql         Baseline aller 376 Zeilen plus der vier Vorgaengertabellen
cases/
  assert_*.sql            Nachpruefungen
  setup_*.sql             Negativfaelle
  teardown_*.sql          Aufraeumen
V1_V2_MANIFEST.sha256     74 Dateien: Batch 1, Batch 2 und der gemeinsame Trigger
```

## Warum die Baseline so breit ist

`fixture/05_baseline.sql` sichert **jede** der 376 Produktzeilen, nicht nur die
zehn Ziele. Nur so kann `assert_after_03.sql` die scharfe Frage beantworten:
*hat sich ausserhalb der Zielmenge irgendetwas bewegt?* Ein Backfill, der
versehentlich 11 statt 10 Zeilen trifft, faellt damit auf — ein Test, der nur
die eigenen zehn Zeilen prueft, wuerde ihn durchwinken.

## Warum jeder Negativfall ein Fehler-Literal verlangt

`step ... fail` akzeptiert nicht „irgendein Exit ungleich 0". Verlangt werden
**Exit 3** (Server-Exception bei `ON_ERROR_STOP=1`) **und** das exakte
Fehlerliteral im Output. Ein Abbruch aus dem falschen Grund waere sonst ein
stilles PASS.

## Warum die lesenden Dateien anders geprueft werden

`01`, `02b`, `04` und `04b` melden Probleme **nicht** ueber den Exit-Code,
sondern als Ergebniszeile mit `status = FAIL`. `report_table` verlangt deshalb
die **exakte** Zahl an PASS-Zeilen und 0 FAIL-Zeilen. Eine nachtraeglich
geschrumpfte Pruefliste faellt damit auf, statt als PASS durchzugehen.

Fuer die beiden Sicherheitsfaelle dreht `report_table_expect_fail` die
Erwartung um: dort **muss** die Datei FAIL melden, in exakt der erwarteten Zahl
und mit dem genannten Pruefnamen. Ein PASS waere dort der eigentliche Befund.
