# Lokaler PostgreSQL-Testbericht — Value-Add-Rollout 01 bis 07

Datum: 2026-08-23
Ausführung: vollständig lokal, ohne Netzwerk, ohne Chrome, ohne Supabase.

> ## Lesehinweis: dieser Bericht hat zwei Runden
>
> **Runde 1** (Abschnitte 3 bis 5) ist ein tatsächlich ausgeführter Lauf gegen
> die **damalige** Fassung von `01` bis `07`: 67 Schritte, Harness-Exit 0, ein
> Befund in Schritt 064. Diese Ergebnisse bleiben als Historie stehen — sie
> gelten für die **alten** Dateien.
>
> **Runde 2** (Abschnitte 6 und 7) beschreibt die daraus abgeleitete Korrektur
> an `02`, `03`, `04`, `06`, `07`, die Verschärfung des Harness **und deren
> Messung**. Die Korrektur wurde von Claude implementiert; die Ausführung und
> das Audit des verschärften Harness auf den geänderten Dateien hat **Codex
> unabhängig** vorgenommen: zwei vollständige Läufe, je Harness-Exit 0,
> je 73 Schritte, je 73 PASS und 0 FAIL. Abschnitt 7 dokumentiert beide Läufe
> mit Lock-Beweis und Cleanup-Beweis; es steht dort nichts mehr aus.
>
> Zum Ausführungsstand — **Achtung, dieser Punkt hat sich nach Abfassung der
> Runden 1 und 2 mehrfach geändert.** Beim Stand von Runde 2 galt: keine
> schreibende Datei war jemals auf Production oder Pilot gelaufen. Das gilt
> **nicht mehr**. `02_migrate_value_add.sql`, `03_backup_value_add.sql` und
> `04_backfill_value_add.sql` wurden am 2026-08-23 **nach** beiden lokalen
> Runden auf Production ausgeführt, ebenso die read-only Nachprüfung
> `05_verify_read_only.sql` und die read-only Sicherheitsprüfung
> `05b_verify_payload_security_read_only.sql`. Der maßgebliche Ausführungsstand
> steht in den **Nachträgen Abschnitt 11 (Schritt 2)**, **Abschnitt 12
> (Schritt 3)**, **Abschnitt 13 (Schritt 4, mit erneutem lokalem Harness-Lauf
> davor)**, **Abschnitt 14 (Schritt 5)** und **Abschnitt 17 (Schritt 5b)** sowie
> im RUNBOOK — nicht in den Runden 1 und 2.
>
> Für die Runden 1 und 2 selbst gilt unverändert: alle dort dokumentierten Läufe
> von `02` bis `07` sind **ausschließlich lokale Harness-Läufe** gegen den
> Temp-Cluster (Abschnitt 1), ohne jeden Production- oder Pilot-Kontakt. Ein
> lokaler Lauf von `03` oder `04` in Runde 1 oder 2 ist **kein**
> Production-Lauf; die Production-Läufe stehen ausschließlich in den
> Abschnitten 11 bis 14 und 17. `01_preflight_read_only.sql` wurde am 2026-08-23
> zusätzlich read-only auf Production ausgeführt und auditiert. **`06` und `07`
> sind auf Production oder Pilot nicht ausgeführt worden.** `01` und `05` sind
> in beiden Runden **unverändert** — `05` ist auch durch seinen
> Production-Einsatz unverändert geblieben.
>
> **Abschnitt 12** dokumentiert zusätzlich eine Datei, die es in beiden Runden
> noch nicht gab: `03_verify_snapshot_read_only.sql`, den read-only Postcheck zu
> Schritt 3. Sie ist nicht Teil des Harness und nicht `05_verify_read_only.sql`;
> sie hat Schritt 5 nicht ersetzt (siehe Abschnitt 14).

## 1. Umgebung

| Punkt | Wert |
|---|---|
| PostgreSQL | `postgres (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)` |
| Binaries | `/tmp/cbb-postgres.vYLmod/root/usr/lib/postgresql/16` |
| Cluster | `mktemp -d` unter `/tmp`; Runde 1: `/tmp/cbb-pgtest.WWPr0tdA`; Runde 2 Lauf 1: `/tmp/cbb-pgtest.znxUlhpv`, Lauf 2: `/tmp/cbb-pgtest.O7PhH5yQ` |
| Erreichbarkeit | `listen_addresses=''`, nur lokaler Unix-Socket im Temp-Verzeichnis, kein TCP-Port — auch in Runde 2 kein Production-, Pilot- oder Netzwerk-Kontakt |
| Locale/Meldungen | `--locale=C.UTF-8`, `lc_messages=C` |
| Harness | `apps/web/supabase/production_value_add/test/run_local_postgres_test.sh` |

Weder Production (`ydiihvzcxaaoqhmgoqvu`) noch Pilot (`nmzuycveumyfvtxdcnuc`)
wurden **von diesen Testläufen** kontaktiert. Kein Commit, kein Merge, kein
Push, kein Deploy. Die später erfolgten Production-Läufe von `02`
(Abschnitt 11), `03` (Abschnitt 12), `04` (Abschnitt 13) und `05`
(Abschnitt 14) waren getrennte, jeweils ausdrücklich freigegebene Aktionen
außerhalb dieses Harness.

### 1.1 Hashes — Runde 1 (im Original ausgeführt)

```
957986f864a73076b1a2a2b18625c6e7  01_preflight_read_only.sql
713a57b23cbb2889f17a486d15d18ad0  02_migrate_value_add.sql
f49a08f5d4670a30c1ee105ff90f047b  03_backup_value_add.sql
83313b4d0e0bc0302c709577832a2d68  04_backfill_value_add.sql
a5c709087d02a0adb6e582e576403834  05_verify_read_only.sql
3d62447d7d8740732d8cca2c3edd0957  06_restore_value_add.sql
ab2dada7820ffebac05e553268724009  07_down_migration.sql
```

### 1.2 Hashes — Runde 2 (aktueller Repo-Stand, nach der Korrektur)

```
957986f864a73076b1a2a2b18625c6e7  01_preflight_read_only.sql      (unveraendert)
f0a81d658554608d7b3cc3637859a5b0  02_migrate_value_add.sql        (geaendert)
acacd1b3180d1f9a7bad55789f194f8d  03_backup_value_add.sql         (geaendert)
a0d6cd3adfca22638f382f28b9c3dbee  04_backfill_value_add.sql       (geaendert)
a5c709087d02a0adb6e582e576403834  05_verify_read_only.sql         (unveraendert)
436cd19bf9b59e5ee958c3af5f73a5e4  06_restore_value_add.sql        (geaendert)
d9e8dd0c217358f9cdd8a579de341c6f  07_down_migration.sql           (geaendert)
```

Testinfrastruktur (Runde 2):

```
f49844daa440ce492499451c742910bb  test/run_local_postgres_test.sh                  (verschaerft)
845bd3812163bf9eeadd42d6352d8c61  test/cases/assert_no_value_add_schema.sql        (verschaerft)
293dea62bda186bdc158c7f81f67e62d  test/cases/assert_partial_state_unchanged.sql    (neu)
```

`01_preflight_read_only.sql` trägt weiterhin denselben MD5 wie vor dem
Production-Preflight am 2026-08-23. Zum Zeitpunkt der Runde-2-Läufe hatte keine
der geänderten Dateien `02`, `03`, `04`, `06`, `07` eine Production-Freigabe;
die Änderung betraf ausschließlich noch nicht freigegebene Artefakte.

> **Nachtrag (nach Runde 2):** `02_migrate_value_add.sql`,
> `03_backup_value_add.sql` und `04_backfill_value_add.sql` sind seither auf
> Production ausgeführt worden. Die lokalen Quelldateien, die der Benutzer dabei
> verwendet hat, trugen die hier gelisteten auditierten Stände
> `f0a81d658554608d7b3cc3637859a5b0`, `acacd1b3180d1f9a7bad55789f194f8d` bzw.
> `a0d6cd3adfca22638f382f28b9c3dbee` und sind danach unverändert geblieben. Ein
> Editor-Hash des tatsächlich eingefügten Textes liegt in **keinem** der drei
> Fälle vor; Details in den Abschnitten 11.2, 12.2 und 13.3. Auch
> `05_verify_read_only.sql` (`a5c709087d02a0adb6e582e576403834`, unverändert)
> ist inzwischen read-only auf Production gelaufen — Abschnitt 14. **`06` und
> `07` sind weiterhin nie auf Production oder Pilot gelaufen.** Siehe
> Abschnitte 11 bis 14.

Diese MD5-Werte sind der Stand, gegen den die beiden Runde-2-Läufe (Abschnitt 7)
gelaufen sind, und sind nach dem Audit unverändert gültig. `01` und `05` sind
byte-identisch zu Runde 1.

Zusätzlich wird die echte Repo-Datei `apps/web/supabase/seo_updated_at_trigger.sql`
ausgeführt, damit `products_touch_updated_at()` im Test dieselbe Funktion ist wie
auf Production — kein Nachbau.

## 2. Befehle

```bash
cd /home/batman/CrazyBaboBazar/apps/web/supabase/production_value_add/test
chmod +x run_local_postgres_test.sh
bash -n run_local_postgres_test.sh                      # Syntaxpruefung
./run_local_postgres_test.sh                            # kompletter Lauf
CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh         # Lauf, Datenverzeichnis behalten
```

In Runde 2 wurden `bash -n` (Exit 0) und der volle Lauf **zweimal** ausgeführt
(Abschnitt 7.2), dazu `git diff --check` ohne Ausgabe.

Intern verwendete Befehle (alle mit ihrem Exit-Code protokolliert, seit Runde 2
fail-closed):

```bash
initdb  -D "$PGDATA" -U postgres --auth=trust --encoding=UTF8 --locale=C.UTF-8   # != 0 -> Harness-Exit 2
pg_ctl  -D "$PGDATA" -l "$SERVERLOG" -w \
        -o "-k $SOCKDIR -c listen_addresses='' -c lc_messages=C \
            -c log_min_messages=warning" start                                  # != 0 -> Harness-Exit 2
createdb cbb_fixture                                                            # != 0 -> Harness-Exit 2
createdb -T cbb_fixture <fallname>                     # je Testfall            # != 0 -> Harness-Exit 2
psql -X -q -v ON_ERROR_STOP=1 -d <db> -f <datei>       # je Schritt
pg_ctl  -D "$PGDATA" -m fast stop                                               # im EXIT-Trap
```

Hinweis zur Umgebung: Die Binaries liegen in einem entpackten Paketbaum, nicht in
`/usr`. Ohne `LD_LIBRARY_PATH` auf das Verzeichnis mit `libpq.so.5` bricht
`initdb` mit **Exit 127** (`libpq.so.5: cannot open shared object file`) ab. Der
Harness setzt die Variable selbst; der erste Laufversuch in Runde 1 scheiterte
genau daran und ist damit ebenfalls belegt.

---

# Runde 1 — ausgeführter Lauf gegen die alte Dateifassung

## 3. Fixture

`fixture/03_assert_fixture.sql` erzwingt vor jedem Testfall, dass die
Testdatenbank exakt den Fingerprint trägt, den `01_preflight_read_only.sql` am
2026-08-23 auf Production gemeldet hat:

| Merkmal | Production 2026-08-23 | Lokale Fixture |
|---|---|---|
| Produkte | 376 | 376 |
| Zielprodukte published | 10/10 | 10/10 |
| Relationsziele published | 5/5 | 5/5 |
| Bestehende `editorial_note` in der Zielmenge | 3 | 3 (`n4`, `ninja`, `welpen`) |
| Value-Add-Schema | 0/8 Spalten, 0/2 Constraints | 0/8, 0/2 |
| `value_add_bereits_befuellt` | 0 | 0 |
| `production_snapshot` | FEHLT | FEHLT |
| `products_rls` | true | true |
| `products_policies` | 2 | 2 |
| `app_grants_products` | 14 | 14 |
| `products_user_trigger` | `products_set_updated_at … products_touch_updated_at()` | identisch (echte Repo-Datei) |
| `divoom-pixoo-led-panel.price_cents` | NULL | NULL |

Rollen `anon`, `authenticated` und `service_role` existieren im Cluster — ohne
sie scheitern die `revoke`-Statements in 03, 04 und 06 mit
„role does not exist". Ihre Existenz ist damit eine echte Vorbedingung, keine
Kosmetik.

`fixture/04_baseline.sql` sichert zusätzlich `slug`, `editorial_note`,
`updated_at`, `created_at` und `is_published` **aller 376 Zeilen** in ein
separates Schema `cbb_test_baseline`, das von keinem Guard in 01–07 gesehen wird.
Restore und Down-Migration werden Zeile für Zeile dagegen geprüft.

## 4. Ergebnisübersicht Runde 1

67 Schritte, 0 Abweichungen nach damaliger Bewertung, Harness-Exit-Code **0** —
mit einem als `BEFUND` markierten Schritt, der den Gesamtlauf **nicht** auf FAIL
gesetzt hat. Genau das ist in Runde 2 korrigiert worden.

| case | step | label | erwartet | exit | Ergebnis |
|---|---|---|---|---|---|
| fixture | 001 | fixture_roles | ok | 0 | PASS |
| fixture | 002 | fixture_schema | ok | 0 | PASS |
| fixture | 003 | fixture_seed | ok | 0 | PASS |
| fixture | 004 | fixture_real_trigger | ok | 0 | PASS |
| fixture | 005 | fixture_assert | ok | 0 | PASS |
| fixture | 006 | fixture_baseline | ok | 0 | PASS |
| case_a_happy_path | 007 | a_01_preflight_vor_migration | keine FAIL-Zeile | 0 | PASS (9 PASS, 0 FAIL) |
| case_a_happy_path | 008 | a_02_migrate | ok | 0 | PASS |
| case_a_happy_path | 009 | a_02_assert | ok | 0 | PASS |
| case_a_happy_path | 010 | a_03_backup | ok | 0 | PASS |
| case_a_happy_path | 011 | a_03_assert | ok | 0 | PASS |
| case_a_happy_path | 012 | a_04_backfill | ok | 0 | PASS |
| case_a_happy_path | 013 | a_04_assert | ok | 0 | PASS |
| case_a_happy_path | 014 | a_05_verify_nach_backfill | keine FAIL-Zeile | 0 | PASS (14 PASS, 0 FAIL) |
| case_b_wiederholungen | 015 | b_02_migrate | ok | 0 | PASS |
| case_b_wiederholungen | 016 | b_02_wiederholung | fail | 3 | PASS |
| case_b_wiederholungen | 017 | b_02_nach_abbruch | ok | 0 | PASS |
| case_b_wiederholungen | 018 | b_03_backup | ok | 0 | PASS |
| case_b_wiederholungen | 019 | b_03_wiederholung | fail | 3 | PASS |
| case_b_wiederholungen | 020 | b_03_nach_abbruch | ok | 0 | PASS |
| case_b_wiederholungen | 021 | b_05_vor_backfill | fail | 3 | PASS |
| case_b_wiederholungen | 022 | b_04_backfill | ok | 0 | PASS |
| case_b_wiederholungen | 023 | b_04_wiederholung | fail | 3 | PASS |
| case_b_wiederholungen | 024 | b_04_nach_abbruch | ok | 0 | PASS |
| case_b_wiederholungen | 025 | b_07_vor_restore | fail | 3 | PASS |
| case_b_wiederholungen | 026 | b_04_unveraendert | ok | 0 | PASS |
| case_c_rollback | 027 | c_02_migrate | ok | 0 | PASS |
| case_c_rollback | 028 | c_03_backup | ok | 0 | PASS |
| case_c_rollback | 029 | c_block_installieren | ok | 0 | PASS |
| case_c_rollback | 030 | c_04_bricht_ab | fail | 3 | PASS |
| case_c_rollback | 031 | c_rollback_assert | ok | 0 | PASS |
| case_c_rollback | 032 | c_block_entfernen | ok | 0 | PASS |
| case_c_rollback | 033 | c_04_danach_ok | ok | 0 | PASS |
| case_c_rollback | 034 | c_04_assert | ok | 0 | PASS |
| case_d_rollback_pfad | 035 | d_02_migrate | ok | 0 | PASS |
| case_d_rollback_pfad | 036 | d_03_backup | ok | 0 | PASS |
| case_d_rollback_pfad | 037 | d_04_backfill | ok | 0 | PASS |
| case_d_rollback_pfad | 038 | d_06_restore | ok | 0 | PASS |
| case_d_rollback_pfad | 039 | d_06_assert | ok | 0 | PASS |
| case_d_rollback_pfad | 040 | d_06_wiederholung | ok | 0 | PASS |
| case_d_rollback_pfad | 041 | d_06_assert_2 | ok | 0 | PASS |
| case_d_rollback_pfad | 042 | d_04_nach_restore | fail | 3 | PASS |
| case_d_rollback_pfad | 043 | d_06_assert_3 | ok | 0 | PASS |
| case_d_rollback_pfad | 044 | d_07_down | ok | 0 | PASS |
| case_d_rollback_pfad | 045 | d_07_assert | ok | 0 | PASS |
| case_d_rollback_pfad | 046 | d_07_wiederholung | fail | 3 | PASS |
| case_d_rollback_pfad | 047 | d_07_assert_2 | ok | 0 | PASS |
| case_d_rollback_pfad | 048 | d_02_erneut | ok | 0 | PASS |
| case_d_rollback_pfad | 049 | d_02_assert | ok | 0 | PASS |
| case_e_pilot_artefakt | 050 | e_setup | ok | 0 | PASS |
| case_e_pilot_artefakt | 051 | e_02_abbruch | fail | 3 | PASS |
| case_e_pilot_artefakt | 052 | e_kein_schema | ok | 0 | PASS |
| case_f_zu_wenig_produkte | 053 | f_setup | ok | 0 | PASS |
| case_f_zu_wenig_produkte | 054 | f_02_abbruch | fail | 3 | PASS |
| case_f_zu_wenig_produkte | 055 | f_kein_schema | ok | 0 | PASS |
| case_g_teilzustand | 056 | g_setup | ok | 0 | PASS |
| case_g_teilzustand | 057 | g_02_abbruch | fail | 3 | PASS |
| case_g_teilzustand | 058 | g_kein_schema | ok | 0 | PASS |
| case_h_relationsziel_offline | 059 | h_setup | ok | 0 | PASS |
| case_h_relationsziel_offline | 060 | h_02_abbruch | fail | 3 | PASS |
| case_h_relationsziel_offline | 061 | h_kein_schema | ok | 0 | PASS |
| case_i_trigger | 062 | i_trigger | ok | 0 | PASS |
| case_j_lock_timeout | 063 | j_vorbereitung | ok | 0 | PASS |
| case_j_lock_timeout | 064 | **j_02_unter_sperre** | fail | **124** | **BEFUND** (Abschnitt 6) |
| case_j_lock_timeout | 065 | j_kein_schema | ok | 0 | PASS |
| case_j_lock_timeout | 066 | j_02_danach | ok | 0 | PASS |
| case_j_lock_timeout | 067 | j_02_assert | ok | 0 | PASS |

`exit 3` ist der psql-Code für eine Server-Exception bei `ON_ERROR_STOP=1` — also
genau der gewollte Fail-closed-Abbruch. `exit 124` ist der Client-Timeout aus
`timeout 20`.

## 5. Ergebnisse Runde 1 im Detail

### 5.1 Happy Path — `01_preflight_read_only.sql` auf der lokalen Fixture

```
            pruefung             |                                   ist                                    |                erwartet                | status
---------------------------------+--------------------------------------------------------------------------+----------------------------------------+--------
 ausfuehrende_rolle              | postgres                                                                 | INFO                                   | INFO
 datenbank                       | case_a_happy_path                                                        | INFO                                   | INFO
 production_tabellen             | 4                                                                        | 4                                      | PASS
 produkte_mindestens_300         | 376                                                                      | >= 300                                 | PASS
 pilot_artefakte                 | 0                                                                        | 0                                      | PASS
 zielprodukte                    | 10                                                                       | 10                                     | PASS
 veroeffentlichte_zielprodukte   | 10                                                                       | 10                                     | PASS
 veroeffentlichte_relationsziele | 5/5                                                                      | 5/5                                    | PASS
 value_add_schema_zustand        | 0/8 Spalten, 0/8 Typen, 0/2 Constraints                                  | 0/8 + 0/2 … ODER 8/8 + 2/2             | PASS
 value_add_bereits_befuellt      | 0                                                                        | 0                                      | PASS
 production_snapshot             | FEHLT                                                                    | FEHLT vor Backup                       | PASS
 bestehende_editorial_notes      | 3: n4-…, ninja-…, welpen-…                                               | INFO                                   | INFO
 products_rls                    | true                                                                     | INFO                                   | INFO
 products_policies               | 2                                                                        | INFO                                   | INFO
 app_grants_products             | 14                                                                       | INFO                                   | INFO
 products_user_trigger           | 1: CREATE TRIGGER products_set_updated_at BEFORE UPDATE ON public.products … | INFO                               | INFO
(16 rows)
```

Bis auf `datenbank` (lokaler DB-Name statt `postgres`) ist die Ausgabe
zeilengleich mit dem Production-Lauf vom 2026-08-23. Das ist der Beleg, dass der
Harness dieselbe Ausgangslage testet. **9 PASS-Zeilen, 7 INFO-Zeilen, 0 FAIL** —
genau diese 9 verlangt `report_table` seit Runde 2 exakt und hat sie in beiden
Runde-2-Läufen auch exakt gemessen (Abschnitt 7.2).

### 5.2 `02_migrate_value_add.sql`

- Legt 8 nullable Spalten und 2 CHECK-Constraints an, Exit-Code 0.
- `assert_after_02.sql`: 8/8 Spalten, 8/8 Typen, 2/2 Constraints, 376 Produkte,
  **0** befüllte Zeilen und **0 Drift** in `editorial_note`/`updated_at` über alle
  376 Zeilen. Die Migration ist damit nachweislich rein additiv.
- Der In-Transaction-Vergleich über `cbb_value_add_migration_state`
  (`on commit drop`) funktioniert in psql wie vorgesehen.

### 5.3 `03_backup_value_add.sql`

- Exit-Code 0, abschließendes `backup_rows = 10`.
- `assert_after_03.sql`: 10 Zeilen, alle drei bestehenden `editorial_note`
  wortgleich im Snapshot, **0** Abweichung zur Baseline, RLS aktiv,
  **0** Grants für `anon`/`authenticated`/`PUBLIC` — weder auf der Tabelle noch
  auf dem Schema `cbb_private_backup`.

### 5.4 `04_backfill_value_add.sql`

`assert_after_04.sql` prüft mehr, als die Datei selbst prüft:

| Prüfung | Ergebnis |
|---|---|
| Zeilen mit Value-Add-Daten (gesamte Tabelle) | 10 |
| Zielprodukte vollständig befüllt | 10 |
| Audit-Payload `value_add_payload_v1` | 10 Zeilen, 0 Abweichungen |
| Verteilung alternative/complement/ohne | 3 / 2 / 5 |
| Defekte Relationsziele | 0 |
| Zielseiten mit **neuerem** `updated_at` | 10 |
| **Kollateralschaden an den 366 anderen Zeilen** | 0 lastmod, 0 editorial_note |
| Bewusste `editorial_note`-Overwrites | 3 von 3 |
| RLS / App-Grants auf der Audit-Payload | aktiv / 0 |

Der Kollateralschaden-Check ist der SEO-relevante: hätten die 366 nicht
angefassten Produkte ein neues `updated_at` bekommen, würde die Sitemap Google
366 Änderungen melden, die es nie gab.

### 5.5 `05_verify_read_only.sql`

```
         pruefung         |            ist            |         erwartet          | status
--------------------------+---------------------------+---------------------------+--------
 produkte                 | 376                       | INFO                      | INFO
 pilot_artefakte          | 0                         | 0                         | PASS
 schema                   | 8/8, 2/2                  | 8/8, 2/2                  | PASS
 snapshot_zeilen          | 10                        | 10                        | PASS
 zielprodukte_published   | 10/10                     | 10/10                     | PASS
 audit_payload            | 10 Zeilen, 0 Abweichungen | 10 Zeilen, 0 Abweichungen | PASS
 vollstaendig_befuellt    | 10                        | 10                        | PASS
 value_add_irgendwo       | 10                        | 10                        | PASS
 alternativen             | 3                         | 3                         | PASS
 ergaenzungen             | 2                         | 2                         | PASS
 ohne_relation            | 5                         | 5                         | PASS
 inkonsistente_relationen | 0                         | 0                         | PASS
 defekte_relationsziele   | 0                         | 0                         | PASS
 geaenderte_lastmods      | 10                        | 10                        | PASS
 divoom_preis_null        | 1                         | 1                         | PASS
 n4_zeittext_unveraendert | <tagline> | <description> | INFO                      | INFO
(16 rows)
```

14 PASS-Zeilen, 2 INFO-Zeilen, 0 FAIL-Zeilen. Wichtig für den Betrieb: `05`
meldet Probleme **nicht** über den Exit-Code, sondern nur als `status = FAIL` in
der Tabelle. Der Harness wertet das separat aus und verlangt seit Runde 2 exakt
diese 14; in beiden Runde-2-Läufen wurden exakt 14 PASS / 0 FAIL gemessen
(Abschnitt 7.2). Im Dashboard muss ein Mensch die Spalte `status` lesen, ein
„lief durch" reicht nicht.

**Reichweite von `audit_payload` — wichtig.** Diese Zeile ist ein reiner
**Inhaltsvergleich**: 10 Zeilen und 0 Feldabweichungen zwischen
`cbb_private_backup.value_add_payload_v1` und `public.products`. `05` liest für
die Payload **keinen** Katalogwert — weder `pg_class.relrowsecurity` noch
`pg_policy` noch `relacl`/`nspacl`. Aus einem PASS bei `audit_payload` folgt
also **keine** Aussage über RLS, Policies oder Rechte der Payload. Lokal deckt
das der Harness ab (`assert_after_04.sql`, Abschnitt 5.4, letzte Tabellenzeile:
RLS aktiv / 0 App-Grants — geprüft für `anon`, `authenticated` und PUBLIC, nicht
für `service_role`). Auf Production war diese Ebene bis dahin **ungeprüft**;
dafür gibt es seit dem 2026-08-23 die neue read-only Datei
`05b_verify_payload_security_read_only.sql` (Abschnitt 15) — erst **lokal
positiv und negativ getestet** (Abschnitt 16) und danach nach eigener
ausdrücklicher read-only Freigabe **auf Production ausgeführt und bestanden**
(Abschnitt 17: 16 Zeilen, 9 PASS, 7 INFO, 0 FAIL). Die Production-Ebene ist
damit gemessen — aber durch `05b`, nicht durch `05`.

### 5.6 Fail-closed-Wiederholungen

Jede schreibende Datei wurde ein zweites Mal ausgeführt. Alle Abbrüche kamen
mit dem gewollten Text und ohne jede Nebenwirkung — die anschließende
Zustandsprüfung war jeweils unverändert PASS:

| Schritt | Fehlermeldung des Servers |
|---|---|
| `02` erneut | `Production-Migration abgebrochen: Migration ist bereits vollstaendig vorhanden.` |
| `03` erneut | `Production-Backup abgebrochen: Snapshot v1 existiert bereits.` |
| `04` erneut | `Production-Backfill abgebrochen: 10 Zielzeilen sind seit dem Snapshot gedriftet.` |
| `05` vor `04` | `relation "cbb_private_backup.value_add_payload_v1" does not exist` |
| `07` vor `06` | `Production-Down abgebrochen: Restore nicht exakt (10 Abweichungen).` |
| `07` erneut | `Production-Down abgebrochen: Migration unvollstaendig (0 Spalten, 0 Typen, 0 Constraints).` |
| `04` nach `06` | `Production-Backfill abgebrochen: Audit-Payload v1 existiert bereits.` |

Diese Texte sind seit Runde 2 die im Harness fest hinterlegten Erwartungen —
vorher wurden sie nur protokolliert, nicht geprüft.

Der letzte Punkt bestätigt exakt die Warnung im Runbook: nach einem Restore ist
ein erneuter Backfill gesperrt und braucht eine bewusste Entscheidung über die
alte Audit-Payload.

### 5.7 Transaktions-Rollback (`case_c_rollback`)

`cases/setup_block_updates.sql` installiert einen `before update`-Trigger, der
jedes UPDATE auf `public.products` mit einer Exception beantwortet. Der
Wartepunkt liegt damit **nach** `create table cbb_private_backup.value_add_payload_v1`
und **innerhalb** derselben `begin … commit`-Klammer.

- `04` bricht ab: `ERROR: CBB-TEST: UPDATE auf products absichtlich blockiert.` (exit 3)
- `assert_04_rolled_back.sql` danach: **`value_add_payload_v1` existiert nicht**,
  0 befüllte Zeilen, 0 Drift gegen die Baseline, Snapshot weiterhin 10/10.
- Nach Entfernen des Test-Triggers läuft `04` normal durch — der Abbruch hat
  keinen halben Zustand hinterlassen.

Das ist der eigentliche Atomaritätsbeweis: ein in derselben Transaktion bereits
erzeugtes `CREATE TABLE` verschwindet beim Rollback restlos.

### 5.8 Restore und `updated_at` (`case_d_rollback_pfad`)

`assert_after_06.sql` vergleicht **alle 376 Zeilen** gegen die Baseline:

- 0 Abweichungen in `editorial_note` **und** `updated_at`.
- Die drei Originalnotizen sind wortgleich zurück (Präfix `ALT-NOTE`).
- Die anderen sieben Zielprodukte haben wieder `editorial_note = NULL`.
- 0 Zeilen tragen noch Value-Add-Daten.
- Snapshot und Audit-Payload bestehen weiter — wie im Runbook zugesagt.

Der `updated_at`-Teil ist der heikelste Punkt des ganzen Rollbacks, weil ein
`before update`-Trigger den Snapshot-Zeitstempel überschreiben könnte. Genau das
prüft `case_i_trigger` am echten `products_touch_updated_at()` separat:

1. Sichtbare Änderung (`tagline`) ohne eigenes `updated_at` → Trigger hebt
   `updated_at` auf `now()`. ✔
2. Änderung an `price_cents` → `updated_at` bleibt unverändert stehen. ✔
3. Ausdrücklich mitgeschriebenes `updated_at` (historischer Wert) → Trigger
   respektiert es und überschreibt es **nicht**. ✔

Punkt 3 ist die Voraussetzung dafür, dass `06` überhaupt exakt zurückspielen
kann. Der Runbook-Satz „Falls ein unbekannter Trigger `updated_at` überschreibt,
scheitert die Null-Diff-Prüfung" ist damit lokal geprüft — mit dem bekannten
Trigger scheitert sie nicht.

`06` ist außerdem **idempotent**: ein zweiter Lauf ändert nichts und bleibt bei
0 Abweichungen.

### 5.9 Down-Migration

`assert_after_07.sql` nach `07`:

- 0/8 Value-Add-Spalten, 0/2 Constraints.
- 376 Produkte, 0 Abweichungen gegen die Baseline in `editorial_note`,
  `updated_at`, `is_published` und `created_at`.
- Snapshot und Audit-Payload weiterhin 10/10.
- `products_set_updated_at` weiterhin vorhanden.
- RLS-Policies (2) und App-Grants (14) unverändert.

Anschließend läuft `02` erneut sauber durch — der Vor-Migrations-Zustand ist
vollständig wiederhergestellt und nicht nur „ungefähr" gleich.

### 5.10 Negative Umgebungs-Guards

| Fall | Serverantwort |
|---|---|
| `pilot_meta.environment_guard` vorhanden | `Production-Migration abgebrochen: Pilot-Artefakt gefunden.` |
| 299 Produkte | `Production-Migration abgebrochen: nur 299 Produkte (< 300).` |
| 3 von 8 Spalten vorhanden | `Production-Migration abgebrochen: Teilzustand (3 Spalten, 3 Typen, 0 Constraints).` |
| Relationsziel unpublished | `Production-Migration abgebrochen: 4/5 Relationsziele published.` |

In allen vier Fällen wurde anschließend geprüft, dass **kein** Constraint und
keine zusätzliche Spalte angelegt wurde.

Einschränkung von Runde 1, in Runde 2 behoben: die damalige Prüfdatei
`assert_no_value_add_schema.sql` verlangte nur „nicht 8 Spalten" und „0
Constraints". Ein zurückgebliebener Teilzustand mit 1 bis 7 Spalten wäre
durchgegangen. Die beobachteten Werte waren zwar korrekt (0 bzw. 3 Spalten), die
*Prüfung* war es nicht.

---

# Runde 2 — Korrektur, verschärfter Harness und gemessenes Ergebnis

## 6. Befund aus Runde 1 und seine Behebung

### 6.1 Der Befund

**Fall:** `case_j_lock_timeout`, Schritt 064 der alten Nummerierung.

Aufbau: Eine zweite Sitzung hält `lock table public.products in access exclusive
mode`. Danach wird `02_migrate_value_add.sql` mit einem Client-Timeout von 20 s
gestartet.

Beobachtung aus `pg_stat_activity` während der Blockade:

```
  pid   | state  | wait_event_type | wait_event |          blockiertes_statement
--------+--------+-----------------+------------+------------------------------------------
 345998 | active | Lock            | relation   | do $$ declare product_rows bigint; …
```

Exit-Code des psql-Laufs: **124** (Client-Timeout), nicht der erwartete
Lock-Timeout-Fehler nach 5 Sekunden.

**Ursache:** in `02` — und wortgleich in `03`, `04`, `06` und `07` — standen

```sql
set local lock_timeout = '5s';
set local statement_timeout = '60s';
```

**hinter** dem Fail-closed-`do $$ … $$`-Block. Die Vorprüfung liest aber bereits
`public.products` (`select count(*) …`) und lief deshalb noch mit dem
Session-Default `lock_timeout = 0`, also unbegrenzt.

**Auswirkung:** kein Datenrisiko. Die Transaktion hängt nur; sie schreibt nichts
und rollt beim Abbruch vollständig zurück. Der praktische Effekt war, dass die
Datei bei einer parallelen langen Sperre nicht nach 5 Sekunden aufgibt, sondern
wartet — im Widerspruch zur Runbook-Zusage „fünf Sekunden Lock-Timeout".

### 6.2 Die Korrektur (umgesetzt)

In `02_migrate_value_add.sql`, `03_backup_value_add.sql`,
`04_backfill_value_add.sql`, `06_restore_value_add.sql` und
`07_down_migration.sql` stehen beide Zeilen jetzt **unmittelbar hinter
`begin;`** und damit vor dem ersten Guard-/DO-Block. Die vorher weiter unten
stehenden Duplikate wurden entfernt; jede Datei enthält genau zwei
`set local`-Zeilen.

```sql
begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. …
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$ … $$;   -- Fail-closed-Guard, jetzt ebenfalls zeitlich begrenzt
```

Neue Hashes: Abschnitt 1.2. `01` und `05` sind nicht betroffen.

### 6.3 Die Verschärfungen im Harness (umgesetzt)

Der erste Harness hätte mehrere Klassen echter Fehler als PASS durchgelassen.
Behoben:

| # | Vorher | Jetzt |
|---|---|---|
| 1 | `expect=fail` galt bei **jedem** Exit ≠ 0 als PASS | Exit muss **exakt 3** sein **und** ein pro Schritt hinterlegtes Fehler-Literal muss wörtlich im Output stehen (`grep -F`). Das Literal ist Pflicht; fehlt es, ist der Schritt FAIL. Ein *anderer* Fehler ist FAIL. |
| 2 | `report_table` verlangte „> 0 PASS, 0 FAIL" | `01` exakt **9** PASS / 0 FAIL, `05` exakt **14** PASS / 0 FAIL |
| 3 | `assert_no_value_add_schema.sql` akzeptierte 0–7 Spalten | exakt **0** Spalten und **0** Constraints; für den Teilzustandsfall neue Datei `assert_partial_state_unchanged.sql` mit exakt **3** Spalten (`fuer_wen`, `nicht_fuer`, `key_fact`, alle `text`) und **0** Constraints |
| 4 | Lock-Test konnte `BEFUND` melden und den Gesamtlauf trotzdem auf PASS lassen; Exit 124 war folgenlos | verlangt Exit **3**, die Meldung `canceling statement due to lock timeout` und eine Laufzeit im Fenster **3–15 s**. Exit 124, falscher Text oder Erfolg sind FAIL. `BEFUND` gibt es nicht mehr. |
| 5 | Lock-Halter wurde per `kill` des psql-Clients beendet | eindeutiger `application_name` über `PGAPPNAME`, Beendigung per `pg_terminate_backend`; danach wird aktiv gewartet, bis kein `AccessExclusiveLock` mehr granted ist (neuer Schritt `j_locker_terminiert`). `j_02_danach` wird zusätzlich zeitlich überwacht (> 30 s = FAIL), damit der Nachtest nicht auf das Ende von `pg_sleep(90)` läuft. |
| 6 | Die SET-LOCAL-Position wurde nur indirekt über den Lock-Test berührt | neuer, clusterfreier Fall `case_0_statisch`: awk prüft in allen fünf Dateien genau ein `begin;`, genau eine `lock_timeout`- und eine `statement_timeout`-Zeile (insgesamt zwei `set local`, keine Duplikate), `statement_timeout` direkt unter `lock_timeout`, beide hinter `begin;` und vor dem ersten `do $$`, dazwischen nur Leerzeilen/`--`-Kommentare. Schlägt das fehl, bricht der Harness sofort mit Exit 1 ab. |
| 7 | `initdb`/`createdb`-Fehler liefen still weiter | `initdb`, `pg_ctl start`, `createdb cbb_fixture` und jedes `createdb -T` beenden den Harness bei Fehler mit **Exit 2** |
| 8 | Cleanup entfernte nur `PGDATA` | Cleanup beendet zuerst ein übriggebliebenes Lock-Halter-Backend, stoppt den Server und entfernt `PGDATA` **und** das Socketverzeichnis; bleibt etwas liegen, wird eine WARNUNG protokolliert |

### 6.4 Neue Schrittzahl

**73 Schritte** statt 67:

| Block | Schritte | Nummern |
|---|---|---|
| `case_0_statisch` (neu, ohne Cluster) | 5 | 001–005 |
| `fixture` | 6 | 006–011 |
| `case_a_happy_path` | 8 | 012–019 |
| `case_b_wiederholungen` | 12 | 020–031 |
| `case_c_rollback` | 8 | 032–039 |
| `case_d_rollback_pfad` | 15 | 040–054 |
| `case_e_pilot_artefakt` | 3 | 055–057 |
| `case_f_zu_wenig_produkte` | 3 | 058–060 |
| `case_g_teilzustand` | 3 | 061–063 |
| `case_h_relationsziel_offline` | 3 | 064–066 |
| `case_i_trigger` | 1 | 067 |
| `case_j_lock_timeout` | 6 | 068–073 |

`case_j` enthält jetzt: `j_vorbereitung`, `j_02_unter_sperre`,
`j_locker_terminiert` (neu), `j_exakt_0_spalten`, `j_02_danach`, `j_02_assert`.
Die Labels `e_kein_schema`, `f_kein_schema`, `h_kein_schema` und
`j_kein_schema` heißen jetzt `*_exakt_0_spalten`, `g_kein_schema` heißt
`g_exakt_3_spalten` — die Namen sagen die Erwartung.

## 7. Ergebnisse der Runde 2 — ausgeführt und auditiert

Die Korrektur an den SQL-Dateien und die Verschärfung des Harness stammen aus
der Claude-Implementierung. **Ausgeführt und auditiert hat Codex** — unabhängig
und nachträglich, auf demselben Repo-Stand (Hashes: Abschnitt 1.2). Die
folgenden Zahlen sind gemessen, nicht erwartet.

### 7.1 Statische Vorabprüfungen (Codex)

| Prüfung | Ergebnis |
|---|---|
| `bash -n run_local_postgres_test.sh` | Exit **0** |
| `git diff --check` | **keine Ausgabe** |
| Unabhängige SQL-Lexikprüfung für `01` bis `07` | je **PASS** (7 von 7) |
| `shellcheck` | **nicht durchgeführt** — im System nicht installiert |

`shellcheck` gilt damit ausdrücklich **nicht** als bestanden; es liegt kein
Ergebnis vor. Die Aussagekraft der Shell-Prüfung beschränkt sich auf `bash -n`.

### 7.2 Die beiden Läufe

| Punkt | Lauf 1 | Lauf 2 |
|---|---|---|
| Workdir | `/tmp/cbb-pgtest.znxUlhpv` | `/tmp/cbb-pgtest.O7PhH5yQ` |
| Harness-Exit | **0** | **0** |
| Schritte | 73 | 73 |
| PASS | **73** | **73** |
| FAIL / Abweichungen | **0** | **0** |
| `01` unter `report_table` | 9 PASS / 0 FAIL | 9 PASS / 0 FAIL |
| `05` unter `report_table` | 14 PASS / 0 FAIL | 14 PASS / 0 FAIL |
| `j_02_danach` Laufzeit | 0 s | 1 s |

`results.tsv` beider Läufe enthält je **73 Zeilen, 73 PASS, 0 FAIL**. Nach
Normalisierung der Temp-Pfade sind die beiden Dateien inhaltlich gleich — der
einzige verbleibende Unterschied ist der pro Lauf eindeutige
`application_name` des Lock-Halters, der genau so gewollt ist. Damit ist der
Lauf reproduzierbar und nicht von einem einmaligen Zufall abhängig.

Die in Abschnitt 6.3 beschriebenen Verschärfungen waren dabei aktiv: exakte
Fehler-Literale bei jedem `expect=fail`-Schritt, exakt 9 bzw. 14 PASS-Zeilen bei
`01`/`05`, exakte Spalten- und Constraint-Zahlen bei den Guard-Abbrüchen sowie
`case_0_statisch` vor dem `initdb`.

### 7.3 Lock-Beweis (`case_j_lock_timeout`)

Der Befund aus Runde 1 (Exit 124, Client-Timeout) tritt nicht mehr auf. In
**beiden** Läufen identisch:

| Schritt | Lauf 1 | Lauf 2 |
|---|---|---|
| `j_02_unter_sperre` | Exit **3**, `canceling statement due to lock timeout`, nach **5 s** | Exit **3**, dieselbe Meldung, nach **5 s** |
| `j_locker_terminiert` | **1** Backend terminiert, Sperre nach **0 s** frei | **1** Backend terminiert, Sperre nach **0 s** frei |
| `j_02_danach` | **0 s** | **1 s** |

Das ist der direkte Gegenbeweis zum Runde-1-Befund: `lock_timeout = '5s'` greift
jetzt bereits in der Guard-Phase, die Datei gibt nach fünf Sekunden auf statt zu
warten. Die Runbook-Zusage „fünf Sekunden Lock-Timeout" ist damit lokal
gemessen, nicht nur behauptet.

### 7.4 Cleanup-Beweis

Für **beide** Läufe gilt:

- `pg_ctl stop`: Exit **0**
- `PGDATA` entfernt
- Socketverzeichnis entfernt
- danach **kein** zugehöriger `postgres`-Prozess mehr vorhanden

Der `trap cleanup EXIT` des verschärften Harness hat also getan, was Abschnitt
6.3 Punkt 8 beschreibt — inklusive des Lock-Halter-Backends.

### 7.5 Beleglage der Datei-Änderung

- Die Änderung an `02`, `03`, `04`, `06`, `07` ist im Repo umgesetzt; jede
  Datei enthält genau zwei `set local`-Zeilen, direkt hinter `begin;` und vor
  dem ersten `do $$`. Nachgewiesen über
  `grep -n '^set local ' 0*.sql` — genau 10 Treffer, zwei je Datei:

  | Datei | `begin;` | `set local` | erster `do $$` |
  |---|---|---|---|
  | `02_migrate_value_add.sql` | Z8 | Z14 + Z15 | Z18 |
  | `03_backup_value_add.sql` | Z10 | Z16 + Z17 | Z19 |
  | `04_backfill_value_add.sql` | Z16 | Z22 + Z23 | Z25 |
  | `06_restore_value_add.sql` | Z9 | Z15 + Z16 | Z18 |
  | `07_down_migration.sql` | Z11 | Z17 + Z18 | Z20 |

  Dazwischen steht in jeder Datei nur der erklärende `--`-Kommentarblock.
  Ergänzend die neuen Hashes in Abschnitt 1.2.
- Die Harness-Verschärfungen und die beiden Assert-Dateien sind geschrieben;
  Hashes in Abschnitt 1.2. Sie waren in beiden Läufen aus 7.2 aktiv.
- `01` und `05` sind byte-identisch zur Runde 1 und zum Production-Preflight.

### 7.6 Grenzen der Runde-2-Belege

Auch nach zwei bestandenen Läufen bleibt offen, was ein lokaler PostgreSQL nicht
zeigen kann. Abschnitt 8 gilt unverändert. Zusätzlich gilt für die
Vorabprüfungen der Runde 2:

- `shellcheck` liegt **nicht** vor (nicht installiert). Über Stilfehler oder
  Quoting-Probleme jenseits der reinen Syntax ist damit nichts belegt.
- Die SQL-Lexikprüfung für `01` bis `07` war eine unabhängige Prüfung von Codex,
  kein Repo-Skript. Ein wiederholbares npm-/Shell-Target dafür gibt es hier
  nicht; wer sie nachvollziehen will, prüft ergänzend:

  ```bash
  grep -rn "^set local " apps/web/supabase/production_value_add/0*.sql
  # genau 2 Treffer je Datei in 02, 03, 04, 06, 07; keine in 01 und 05
  ```

## 8. Was dieser Test **nicht** abdeckt

- **Die Supabase-Projekt-Ref.** PostgreSQL kennt sie nicht. Die sichtbare
  Dashboard-URL-Prüfung vor jeder schreibenden Datei bleibt unersetzlich.
- **Reale Production-Inhalte.** Die Fixture bildet Struktur, Mengen und
  Fingerprint nach, nicht die echten Produkttexte. Ob der Payload-Text inhaltlich
  zu den echten Produkten passt, ist eine redaktionelle Frage.
- **Nebenläufige Schreiber aus der App.** Getestet wird ein künstlicher
  Sperrkonflikt, nicht paralleler Traffic.
- **PostgREST, RLS-Wirkung aus Sicht von `anon`, Sitemap-Rendering.** Der Test
  prüft die DB-Ebene, nicht den Auslieferungspfad.
- **Die tatsächliche Production-Rolle.** Lokal läuft alles als Superuser
  `postgres`; auf Supabase ist die Dashboard-Rolle eingeschränkter. `create
  schema` und `revoke` auf App-Rollen sind die Stellen, die dort erstmals real
  belegt werden.
- **Der Lock-Timeout im echten Supabase-Lauf.** Lokal ist belegt, dass
  `set local lock_timeout = '5s'` ab der ersten Anweisung greift und `02` unter
  einer echten parallelen Sperre nach fünf Sekunden mit psql-Exit 3 abbricht
  (Abschnitt 7.3). Nicht getestet ist der Lauf auf Supabase unter realer
  Production-Nebenläufigkeit. Die sichtbare Zielprüfung vor der Datei und der
  5-Sekunden-Abbruch bleiben beim echten Schritt zu beobachten.
- **Die drei bestehenden `editorial_note`-Texte auf Production.** Der Test
  beweist, dass `06` zurückspielt, was `03` gesichert hat — nicht, dass die
  Production-Texte identisch zu den hier verwendeten Testtexten sind.

## 9. Aufräumen

Runde 1:

```
pg_ctl -D <PGDATA> -m fast stop      # exit 0
pgrep -af postgres                   # keine Treffer
```

Runde 2, beide Läufe (Details in Abschnitt 7.4):

```
pg_ctl stop                          # exit 0
PGDATA                               # entfernt
Socketverzeichnis                    # entfernt
zugehoeriger postgres-Prozess        # danach keiner mehr vorhanden
```

Der `trap cleanup EXIT` des verschärften Harness beendet zuerst ein eventuell
übriggebliebenes Lock-Halter-Backend, stoppt den Server und entfernt `PGDATA`
und das Socketverzeichnis. Dieses Verhalten ist damit gemessen, nicht nur
zugesagt. Es blieb in keinem der beiden Läufe etwas liegen.

In beiden Runden: keine Verbindung zu Production oder Pilot, kein Commit, kein
Merge, kein Push, kein Deploy.

## 10. Fazit

Runde 1 hat gezeigt: `01` bis `07` verhielten sich auf echtem PostgreSQL 16 so,
wie das RUNBOOK sie beschreibt — additiv, atomar, fail-closed, mit exaktem
Restore-Pfad inklusive `updated_at`, ohne Kollateralschaden an den 366 nicht
adressierten Produkten und mit vollständig rückbaubarem Schema. Der einzige
inhaltliche Befund war die Reichweite von `lock_timeout` in der Vorprüfungsphase.

Runde 2 hat diesen Befund in den Dateien behoben und den Harness so verschärft,
dass er ihn als FAIL melden würde statt als folgenlosen Hinweis — und beides ist
inzwischen **gemessen**: Codex hat den verschärften Harness unabhängig zweimal
auf den geänderten Dateien ausgeführt, beide Male Exit 0, je 73 von 73 Schritten
PASS, 0 FAIL. Der Lock-Test liefert jetzt Exit 3 mit
`canceling statement due to lock timeout` nach 5 Sekunden statt Exit 124 nach
20. Beide Läufe räumten vollständig auf. Damit ist die Wirkung der Korrektur
belegt und reproduzierbar, nicht mehr nur erwartet.

Nicht belegt bleibt alles aus Abschnitt 8 sowie `shellcheck` (nicht
installiert). Ein lokaler PostgreSQL kann die Supabase-Projekt-Ref, die
Production-Rolle und die echten Produktinhalte nicht ersetzen.

Der Haltepunkt änderte sich dadurch nur an einer Stelle: die lokale
Testvoraussetzung für Schritt 2 war erfüllt. Zum Zeitpunkt dieses Fazits hatten
`02` bis `07` **keine** Production-Freigabe, und der nächste Schritt war eine
ausdrückliche Benutzerfreigabe ausschließlich für Production-Schritt 2.

**Dieser Absatz ist inzwischen überholt.** Die Freigaben für die Schritte 2, 3,
4 und 5 wurden einzeln erteilt; `02`, `03`, `04` und `05` sind auf Production
ausgeführt. Der aktuelle Haltepunkt steht in **Abschnitt 14.5** und im RUNBOOK
unter „Aktueller Haltepunkt".

---

# Nachtrag — Production-Ausführung von `02`, nach Abschluss beider Runden

## 11. Production-Schritt 2 am 2026-08-23

Dieser Abschnitt gehört **nicht** zu den lokalen Testläufen. Er wurde nach
Runde 1 und Runde 2 ergänzt und ändert an deren Ergebnissen nichts: die
Abschnitte 3 bis 10 bleiben die Dokumentation zweier rein lokaler Testrunden
gegen den Temp-Cluster aus Abschnitt 1.

### 11.1 Was passiert ist

Der Benutzer hat Schritt 2 ausdrücklich freigegeben: „Ich gebe
Production-Schritt 2 auf `ydiihvzcxaaoqhmgoqvu` frei."

Zwei vorherige Claude-Chrome-Versuche scheiterten **vor** dem Browser-Write, mit
je **0 Run-Klicks**; sie haben nichts ausgeführt. Die tatsächliche Ausführung
erfolgte danach **manuell durch den Benutzer** nach Codex-Anleitung, aus der
auditierten lokalen Datei `02_migrate_value_add.sql`. Ein einziger Run.

Sichtbarer Zielkontext auf dem Screenshot vor der Ausführung: Supabase-URL
`project/ydiihvzcxaaoqhmgoqvu`, Projekt „CrazyBaboBazar Project", `main`,
`PRODUCTION`.

Rückmeldung des Runs: **„Success. No rows returned"**.

### 11.2 Beleglage — und ihre Grenze

Weil der Text manuell in den SQL-Editor eingefügt wurde, liegt **kein unabhängig
gemessener Editor-Hash des tatsächlich eingefügten Textes** vor. Anders als beim
Preflight (Abschnitt 1.2 / RUNBOOK Schritt 1, wo Datei-Hash und Editor-Hash bis
auf den fehlenden abschließenden LF verglichen wurden) ist der Editorinhalt bei
Schritt 2 **nicht bytegenau gemessen worden**. Das wird hier festgehalten, nicht
weggelassen.

Die Belegkette lautet damit exakt:

| Glied | Beleg |
|---|---|
| Quelle | lokale Datei auditiert: MD5 `f0a81d658554608d7b3cc3637859a5b0`, SHA-256 `445c274a6719fb93020362d9982d4448fedf986c111eb3773dccdb74a6e58579`, 7043 Bytes, 192 Zeilen |
| Ziel | sichtbar bestätigt: `project/ydiihvzcxaaoqhmgoqvu`, „CrazyBaboBazar Project", `main`, `PRODUCTION` |
| Run | Erfolgsmeldung des Benutzers: „Success. No rows returned" |
| Wirkung | unabhängiger read-only Postcheck mit der unveränderten `01` (Abschnitt 11.3) |

Das vierte Glied trägt die Aussage über den Datenbankzustand; das dritte allein
täte es nicht.

### 11.3 Read-only Postcheck

Der Benutzer führte die **unveränderte** `01_preflight_read_only.sql`
(MD5 `957986f864a73076b1a2a2b18625c6e7`, byte-identisch zu beiden Runden) erneut
read-only auf demselben Production-Projekt aus und lieferte alle 16
Ergebniszeilen:

| Prüfung | Ist | Status |
|---|---|---|
| `ausfuehrende_rolle` | `postgres` | INFO |
| `datenbank` | `postgres` | INFO |
| `production_tabellen` | 4 | PASS |
| `produkte_mindestens_300` | 376 | PASS |
| `pilot_artefakte` | 0 | PASS |
| `zielprodukte` | 10 | PASS |
| `veroeffentlichte_zielprodukte` | 10 | PASS |
| `veroeffentlichte_relationsziele` | 5/5 | PASS |
| `value_add_schema_zustand` | **8/8 Spalten, 8/8 Typen, 2/2 Constraints** | PASS |
| `value_add_bereits_befuellt` | 0 | PASS |
| `production_snapshot` | FEHLT | PASS |
| `bestehende_editorial_notes` | weiterhin exakt 3: `n4`, `ninja`, `welpen` | INFO |
| `products_rls` | true | INFO |
| `products_policies` | 2 | INFO |
| `app_grants_products` | 14 | INFO |
| `products_user_trigger` | 1, unverändert | INFO |

**9 harte PASS, 0 FAIL.**

Das ist inhaltlich derselbe Zustand, den `assert_after_02.sql` lokal nach `02`
gemessen hat (Abschnitt 5.2): Schema vollständig, Produktzahl unverändert, keine
befüllten Value-Add-Zeilen. Der Postcheck ersetzt den lokalen Assert nicht — er
bestätigt ihn auf Production auf der Ebene, die `01` abdeckt.

### 11.4 Was daraus folgt — und was nicht

**Belegt:** Production-Schritt 2 ist ausgeführt und unabhängig read-only
bestätigt. Die Migration ist rein additiv angekommen, der Produktbestand ist mit
376 unverändert, es gab zu diesem Zeitpunkt **keinen Backfill** und **keinen
Snapshot**. (Beides hat sich seither geändert: der Snapshot entstand durch
Schritt 3 — Abschnitt 12 —, der Backfill durch Schritt 4 — Abschnitt 13. Der
Satz oben beschreibt ausschließlich den Stand direkt nach Schritt 2.)

**Nicht belegt:** dass der eingefügte Editortext byteweise der lokalen Datei
entsprach (siehe 11.2). Ebenso wenig belegt der erfolgreiche Lauf, dass der
5-Sekunden-Lock-Timeout auf Supabase unter realer Nebenläufigkeit greift — der
Lauf traf keinen Sperrkonflikt. Abschnitt 8 gilt im Übrigen unverändert weiter.

### 11.5 Haltepunkt nach Schritt 2 — **überholt**

> Dieser Unterabschnitt beschreibt den Stand unmittelbar nach Schritt 2 und ist
> inzwischen überholt: die dort geforderte Freigabe wurde erteilt und `03` ist
> ausgeführt, ebenso danach `04` und `05`. Der aktuelle Haltepunkt steht in
> **Abschnitt 14.5**. Der Text bleibt als Historie stehen.

Stand nach Schritt 2: `03_backup_value_add.sql` wurde **nicht** ausgeführt. Der
nächste Schritt war eine **ausdrückliche Benutzerfreigabe ausschließlich für
Production-Schritt 3**, Datei `03_backup_value_add.sql`, nach erneuter
sichtbarer Zielprüfung `project/ydiihvzcxaaoqhmgoqvu`. Die Freigabe für
Schritt 2 war auf `02` beschränkt und verbraucht; dieses Dokument erteilte keine
neue.

`04`, `05`, `06`, `07`, Commit, Merge, Push nach `main` und Vercel-Deploy
blieben nach Runbook gesperrt.

---

# Nachtrag — Production-Ausführung von `03` und ihr read-only Postcheck

## 12. Production-Schritt 3 am 2026-08-23

Auch dieser Abschnitt gehört **nicht** zu den lokalen Testrunden. Er wurde nach
Runde 1, Runde 2 und dem Nachtrag zu Schritt 2 ergänzt und ändert an deren
Ergebnissen nichts: die Abschnitte 3 bis 10 bleiben die Dokumentation zweier
rein lokaler Testrunden gegen den Temp-Cluster aus Abschnitt 1, Abschnitt 11
bleibt der Nachtrag zu Schritt 2.

### 12.1 Was passiert ist

Der Benutzer hat Schritt 3 ausdrücklich freigegeben: „Ich gebe
Production-Schritt 3 auf `ydiihvzcxaaoqhmgoqvu` frei."

Die Ausführung erfolgte **manuell durch den Benutzer** nach Codex-Anleitung, aus
der auditierten lokalen Datei `03_backup_value_add.sql`. Der Benutzer hat den
Text selbst im Chrome-Browser im Supabase-Dashboard-SQL-Editor eingefügt und
dort ausgeführt. Keine Claude-Chrome-Automatisierung und keine sonstige
automatische Ausführung — der einzige Run-Klick kam vom Benutzer.

Sichtbar bestätigter Zielkontext vor der Ausführung: Supabase-URL
`project/ydiihvzcxaaoqhmgoqvu`, Projekt „CrazyBaboBazar Project", `main`,
`PRODUCTION`.

Rückmeldung des Runs: **`backup_rows = 10`**.

**Zur RLS-Warnung des Editors.** Supabase warnte statisch, die Query erstelle
eine Tabelle ohne RLS. Codex wies korrekt „Run without RLS" an: die statische
Warnung bewertet nur das `create table`, nicht den Rest derselben Transaktion.
Die auditierte Datei führt selbst `enable row level security` aus und entzieht
anschließend die Rechte. Bestätigt wird das nicht durch diese Begründung,
sondern durch den späteren read-only Postcheck: `snapshot_rls` = `true`,
`snapshot_policies` = 0, keine Rechte für `anon`, `authenticated` oder `PUBLIC`.

### 12.2 Beleglage — und ihre Grenze

Wie bei Schritt 2 wurde der Text manuell in den SQL-Editor eingefügt. Ein
**Editor-Hash des tatsächlich eingefügten Textes wurde auch hier nicht
gemessen**; der Editorinhalt ist damit **nicht bytegenau** belegt. Das wird
festgehalten, nicht weggelassen.

| Glied | Beleg |
|---|---|
| Quelle | lokale Datei auditiert: MD5 `acacd1b3180d1f9a7bad55789f194f8d`, SHA-256 `61505d7fc0ae24e953395939eec4704ce6ddec881fe9da8129a7724551c6bad0`, 8296 Bytes, 232 Zeilen |
| Ziel | sichtbar bestätigt: `project/ydiihvzcxaaoqhmgoqvu`, „CrazyBaboBazar Project", `main`, `PRODUCTION` |
| Run | Rückmeldung des Benutzers: `backup_rows = 10` |
| Wirkung | unabhängiger read-only Postcheck `03_verify_snapshot_read_only.sql` (Abschnitte 12.3 und 12.4) |

Das vierte Glied trägt die Aussage über den Datenbankzustand; das dritte allein
täte es nicht.

### 12.3 Der Postcheck `03_verify_snapshot_read_only.sql`

`01_preflight_read_only.sql` prüft den Snapshot nur als „vorhanden/FEHLT" und
reicht für Schritt 3 nicht. Claude hat deshalb eine eigene read-only Prüfdatei
`03_verify_snapshot_read_only.sql` erstellt. Sie gehört **nicht** zum lokalen
Harness aus Abschnitt 1 und ist **nicht** `05_verify_read_only.sql`. Schritt 5
war zu diesem Zeitpunkt noch nicht ausgeführt; er lief planmäßig erst nach
Schritt 4 (Abschnitt 14). Die Datei `05` ist dabei unverändert geblieben.

**Befund von Codex an der ersten Fassung — Fail open.** Die Prüfungen der
Tabellen- und Schemarechte gaben die Präsenz der Rollen `anon` und
`authenticated` nur als Textinfo aus; sie war nicht Teil der PASS-Bedingung. Auf
einer Datenbank, auf der diese Rollen fehlen, hätten beide Prüfungen also PASS
gemeldet, ohne etwas geprüft zu haben — genau die Klasse Fehler, die ein
Sicherheitscheck nicht haben darf. Claude hat korrigiert: die Rollenpräsenz
(`Rollen 2/2`) ist jetzt Bestandteil beider `case`-Bedingungen.

Finaler auditierter Stand:

```
MD5     f38d182d7611ae8dbace3609208bf95a
SHA-256 3f86eef71c0afdbfcf463450fed0827bf5d5d2787305654111334dbba84ba74e
Größe   16525 Bytes, 410 Zeilen
```

Form: genau ein lesendes `with … select … order by`, abgeschlossen durch das
einzige statement-trennende Semikolon am Dateiende. Kein DDL, kein DML, keine
Rechtevergabe, kein `do`-Block, keine Transaktionssteuerung.

**Lokaler Test des finalen Postchecks durch Codex** — isolierter PostgreSQL 16,
lokal aufgebauter Zustand nach `02` → `03`, kein Production- oder Pilot-Kontakt:

| Lauf | Ergebnis |
|---|---|
| Normalfall nach lokalem `02` → `03` | 17 Zeilen, 2 INFO, **15 PASS, 0 FAIL** |
| Negativtest: Rolle `authenticated` fehlt | exakt **2** ACL-FAIL (Tabellen- und Schemarechte) |
| Negativtest: absichtlicher `anon`-SELECT-Grant | exakt **1** ACL-FAIL |
| Cleanup | Temp-Cluster und Prozesse vollständig entfernt |

Die beiden Negativtests sind der Beleg, dass der Fail-open-Pfad geschlossen ist:
die Prüfung schlägt jetzt sowohl bei fehlender Rolle als auch bei einem echten
App-Recht an.

### 12.4 Ergebnis des Postchecks auf Production

Der Benutzer führte die finale Datei anschließend read-only auf demselben
Production-Projekt aus und lieferte alle 17 Ergebniszeilen:

| Prüfung | Ist | Status |
|---|---|---|
| `current_user` | `postgres` | INFO |
| `current_database` | `postgres` | INFO |
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

**15 harte PASS, 0 FAIL.**

Das ist inhaltlich derselbe Zustand, den `assert_after_03.sql` lokal nach `03`
gemessen hat (Abschnitt 5.3) — hier zusätzlich mit Spaltenform, Zielmengen-
Abgleich, Drift gegen `public.products` und dem Nachweis, dass die Audit-Payload
aus Schritt 4 fehlt. Der Production-Postcheck ersetzt den lokalen Assert nicht;
er belegt den Production-Zustand.

**Belegt:** Production-Schritt 3 ist ausgeführt und unabhängig read-only
bestätigt. Der private Snapshot enthält exakt zehn Zeilen, ist inhaltsgleich mit
den aktuellen Produktzeilen, RLS ist aktiv, es gibt keine Policy und keine
Rechte für App-Rollen — weder auf der Tabelle noch auf dem Schema. Zum
**Zeitpunkt dieses Postchecks** gab es **keinen Backfill** und **keine
Audit-Payload** aus Schritt 4.

> **Zum letzten Satz — überholt.** Schritt 4 ist am selben Tag freigegeben und
> ausgeführt worden (Abschnitt 13); die Audit-Payload
> `cbb_private_backup.value_add_payload_v1` existiert seither mit zehn Zeilen
> und 0 Inhaltsabweichungen (Abschnitt 14). Der Snapshot selbst ist unverändert
> und bleibt der Rollback-Stand — `06` wurde nicht ausgeführt. Der Drift-Wert
> `snapshot_gegen_products_drift` = 0 aus dieser Tabelle gilt naturgemäß nur für
> den Zeitpunkt **vor** dem Backfill; nach Schritt 4 unterscheiden sich Snapshot
> und Produktzeilen absichtlich in genau den befüllten Feldern.

**Nicht belegt:** dass der eingefügte Editortext byteweise der lokalen Datei
entsprach (12.2). Ebenso wenig belegt der erfolgreiche Lauf, dass der
5-Sekunden-Lock-Timeout auf Supabase unter realer Nebenläufigkeit greift — auch
dieser Lauf traf keinen Sperrkonflikt. Abschnitt 8 gilt im Übrigen unverändert
weiter.

### 12.5 Haltepunkt nach Schritt 3 — **überholt**

> Dieser Unterabschnitt beschreibt den Stand unmittelbar nach Schritt 3 und ist
> inzwischen überholt: die dort geforderte Freigabe für Schritt 4 wurde erteilt,
> `04` ist ausgeführt (Abschnitt 13) und die read-only Nachprüfung `05` ebenfalls
> (Abschnitt 14). Der aktuelle Haltepunkt steht in **Abschnitt 14.5**. Der Text
> bleibt als Historie stehen.

Stand nach Schritt 3: `04_backfill_value_add.sql` wurde **nicht** ausgeführt.
Der nächste Schritt war eine **ausdrückliche Benutzerfreigabe ausschließlich für
Production-Schritt 4**, Datei `04_backfill_value_add.sql`, nach erneuter
sichtbarer Zielprüfung `project/ydiihvzcxaaoqhmgoqvu`. Die Freigabe für Schritt 3
war auf `03` beschränkt und verbraucht; dieses Dokument erteilte keine neue.

`05` war zu diesem Zeitpunkt ebenfalls nicht ausgeführt —
`03_verify_snapshot_read_only.sql` ist der Postcheck zu Schritt 3 und hat
Schritt 5 nicht vorweggenommen. `04`, `05`, `06`, `07`, Commit, Merge, Push nach
`main` und Vercel-Deploy blieben nach Runbook gesperrt.

---

# Nachtrag — erneuter Harness-Lauf und Production-Ausführung von `04`

## 13. Production-Schritt 4 am 2026-08-23

Auch dieser Abschnitt gehört **nicht** zu den lokalen Testrunden 1 und 2. Er
wurde nach den Nachträgen zu Schritt 2 und Schritt 3 ergänzt und ändert an deren
Ergebnissen nichts. Die Abschnitte 3 bis 10 bleiben die Dokumentation zweier
rein lokaler Testrunden gegen den Temp-Cluster aus Abschnitt 1.

### 13.1 Erneuter lokaler Harness-Lauf unmittelbar vor Schritt 4

Vor der Production-Ausführung von `04` wurde der aktuelle verschärfte
PostgreSQL-Harness noch einmal vollständig auf dem aktuellen Repo-Stand
ausgeführt:

| Punkt | Ergebnis |
|---|---|
| Schritte | **73** |
| PASS | **73** |
| FAIL / Abweichungen | **0** |
| Harness-Exit | **0** |
| Temp-Cluster danach | gestoppt |

Das ist ein dritter vollständiger Lauf desselben Harness (nach den beiden Läufen
aus Abschnitt 7.2) und reproduziert deren Ergebnis. Er ist ein **lokaler**
Nachweis gegen den Temp-Cluster aus Abschnitt 1 — kein Production-Kontakt, keine
Aussage über Supabase und **keine Freigabe**. Die Grenzen aus Abschnitt 8 gelten
unverändert.

### 13.2 Was passiert ist

Der Benutzer hat Schritt 4 ausdrücklich freigegeben: „Ich gebe
Production-Schritt 4 auf `ydiihvzcxaaoqhmgoqvu` frei."

Die Ausführung erfolgte **manuell durch den Benutzer** im Chrome-Browser im
SQL-Editor des Supabase-Dashboards, aus der auditierten lokalen Datei
`04_backfill_value_add.sql`. Keine Claude-Chrome-Automatisierung und keine
sonstige automatische Ausführung — der einzige Run-Klick kam vom Benutzer. Ziel
war das bereits zuvor sichtbar als Production bestätigte Projekt
`project/ydiihvzcxaaoqhmgoqvu`.

Rückmeldung des Runs: **„Success. No rows returned"**.

**Zur RLS-Warnung des Editors.** Wie bei Schritt 3 warnte Supabase statisch, die
Query erstelle eine Tabelle ohne RLS. Es wurde wie auditiert **„Run without
RLS"** gewählt: die statische Warnung bewertet nur das `create table` der
Audit-Payload, nicht den Rest derselben Transaktion. `04` aktiviert RLS selbst
innerhalb dieser Transaktion und entzieht anschließend die Rechte.

**Korrektur (2026-08-23, nachträglich).** Hier stand vorher, bestätigt werde das
durch die read-only Nachprüfung in Abschnitt 14 (`audit_payload` 10 Zeilen,
0 Abweichungen). **Das trägt die Aussage nicht.** `audit_payload` ist ein reiner
Inhaltsvergleich; `05` fragt RLS, Policies und Rechte der Payload gar nicht ab
(Abschnitt 5.5). Was tatsächlich belegt ist: die Datei `04` **enthält**
`enable row level security` und
`revoke all … from public, anon, authenticated`, und der lokale Harness misst
diesen Zustand nach `04` (`assert_after_04.sql`, Abschnitt 5.4). Der
**Production-Zustand** der Payload-Absicherung war damit zum Zeitpunkt dieser
Korrektur **nicht gemessen**.

**Nachtrag (2026-08-23, später am selben Tag).** Er ist es inzwischen:
`05b_verify_payload_security_read_only.sql` (Abschnitt 15) wurde nach dem
lokalen Test (Abschnitt 16) und nach eigener ausdrücklicher read-only Freigabe
auf Production ausgeführt und hat bestanden — 9 harte PASS, 0 FAIL, darunter
`payload_rls` = true, `payload_policies` = 0 und keine direkten wie effektiven
Rechte für PUBLIC, `anon` und `authenticated` auf Tabelle und Schema
(Abschnitt 17).

### 13.3 Beleglage — und ihre Grenze

Wie bei Schritt 2 und Schritt 3 wurde der Text manuell in den SQL-Editor
eingefügt. **Der manuell eingefügte Editorinhalt wurde nicht bytegenau
gehasht**; ein Editor-Hash des tatsächlich eingefügten Textes liegt nicht vor.
Das wird festgehalten, nicht weggelassen.

| Glied | Beleg |
|---|---|
| Quelle | lokale Datei auditiert: MD5 `a0d6cd3adfca22638f382f28b9c3dbee`, SHA-256 `3af9c51fe71c7d51391fd93b1d37b1fa7148042e0620203d0c4e4ce460a61001`, 19117 Bytes, 409 Zeilen |
| Lokale Vorprüfung | verschärfter Harness unmittelbar davor: 73/73 PASS, 0 Abweichungen, Exit 0 (13.1) |
| Ziel | bereits sichtbar bestätigtes Production-Projekt `project/ydiihvzcxaaoqhmgoqvu` |
| Run | Rückmeldung des Benutzers: „Success. No rows returned" |
| Wirkung | unabhängige read-only Nachprüfung `05_verify_read_only.sql` (Abschnitt 14) |

Das letzte Glied trägt die Aussage über den Datenbankzustand; die Rückmeldung
allein täte es nicht. Für Schritt 4 ist diese Nachprüfung besonders aussagekräftig,
weil sie den Inhalt **feldgenau** gegen die in derselben Transaktion
persistierte Audit-Payload vergleicht und nicht nur Zeilen zählt.

---

# Nachtrag — Production-Ausführung der read-only Nachprüfung `05`

## 14. Production-Schritt 5 am 2026-08-23

### 14.1 Freigabe und statische Vorabprüfung

Der Benutzer hat Schritt 5 ausdrücklich, projektbezogen und ausdrücklich als
read-only freigegeben: „Ich gebe Production-Schritt 5 (read-only) auf
`ydiihvzcxaaoqhmgoqvu` frei."

Codex hat `05_verify_read_only.sql` **unmittelbar vor dem Lauf** noch einmal
statisch geprüft: **genau ein lesendes `with … select`**, kein DDL, kein DML. Die
Datei ist gegenüber Runde 1 und Runde 2 unverändert:

```
MD5     a5c709087d02a0adb6e582e576403834
SHA-256 2c01c03703eadea2d989b2ac579272fdd768532e2984346a01c02de222bf56fb
Größe   8172 Bytes, 199 Zeilen
```

Ausführung: **manuell durch den Benutzer**, unverändert, im SQL-Editor desselben
Production-Projekts.

### 14.2 Ergebnis auf Production

**Exakt 16 Zeilen: 14 PASS, 2 INFO, 0 FAIL.**

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

### 14.3 Abgleich mit dem lokalen Lauf

Das Production-Ergebnis stimmt in Zeilenzahl, Prüfungsnamen, Status und allen
harten Werten mit dem lokalen Lauf von `05` aus Abschnitt 5.5 überein — dort
16 Zeilen, 14 PASS, 2 INFO, 0 FAIL nach lokalem `02` → `03` → `04` gegen die
Fixture, hier dieselben 16 Zeilen mit denselben 14 PASS. Dass auch die
Produktzahl beidseitig 376 lautet, liegt daran, dass die Fixture genau auf den
Production-Fingerprint gebaut ist (Abschnitt 3). Inhaltlich unterscheiden sich
nur die INFO-Texte, die echten Text ausgeben: `n4_zeittext_unveraendert` zeigt
lokal die Fixture-Texte und auf Production die echten Produkttexte. Dass die
Payload-Inhalte redaktionell zu den echten Produkten passen, bleibt eine
inhaltliche Frage außerhalb dieses Tests (Abschnitt 8).

Damit gilt für Schritt 4 dieselbe Erwartungsmenge, die der Harness seit Runde 2
**exakt** verlangt (Abschnitt 6.3, Punkt 2: `05` exakt 14 PASS / 0 FAIL) — und
sie ist auf Production erfüllt. Der Kollateralschaden-Check aus Abschnitt 5.4
hat auf Production sein Gegenstück in `value_add_irgendwo` = 10: in der gesamten
Tabelle tragen genau zehn Zeilen Value-Add-Daten, die 366 übrigen Produkte sind
nicht angefasst worden.

### 14.4 Was belegt ist — und was nicht

**Belegt:** Production-Schritt 4 ist ausgeführt und durch eine unabhängige
read-only Nachprüfung bestätigt — vollständig, auf genau zehn Produkten,
feldgenau gegen die persistierte Audit-Payload, mit der erwarteten Verteilung
3/2/5, ohne inkonsistente Relationen und ohne defekte Relationsziele. Die zehn
`updated_at`-Werte sind gesetzt. Beide bewusst unveränderten Punkte sind
bestätigt: `divoom-pixoo-led-panel.price_cents` bleibt NULL, und der
Zeitangaben-Widerspruch bei `n4-nussmilchbereiter-pflanzenmilch` ist unverändert
(INFO-Zeile, kein Fehler, offener redaktioneller Vorgang außerhalb dieses
Changesets).

**Nicht belegt:** dass der bei Schritt 4 eingefügte Editortext byteweise der
lokalen Datei entsprach (13.3). Ebenso wenig belegen die Läufe, dass der
5-Sekunden-Lock-Timeout auf Supabase unter realer Nebenläufigkeit greift — weder
`04` noch der read-only Lauf von `05` trafen einen Sperrkonflikt.

**Ebenfalls nicht belegt — durch diesen Lauf — die Absicherung der
Audit-Payload.** `05` prüft die Payload ausschließlich inhaltlich. RLS,
Policies, Primärschlüssel, Spaltenform sowie Tabellen- und Schemarechte von
`cbb_private_backup.value_add_payload_v1` kommen in `05` überhaupt nicht vor;
aus diesem Lauf folgt dazu nichts. Diese Ebene ist inzwischen **separat**
gemessen: lokal durch `assert_after_04.sql` (Abschnitt 5.4) und den `05b`-Test
(Abschnitt 16) und **auf Production durch den eigenen Lauf von `05b`**
(Abschnitt 17). Für den **Snapshot** gilt sie unverändert durch Abschnitt 12.4
(`snapshot_rls`/`snapshot_policies`/`snapshot_*rechte_app_rollen`).

> **Überholt (historisch).** Hier stand vor dem Production-Lauf von `05b`:
> „… sind auf Production **ungemessen** … auf Production ist sie weiterhin nicht
> ausgeführt." Das gilt seit Abschnitt 17 nicht mehr.

Abschnitt 8 gilt im Übrigen unverändert weiter.

### 14.5 Haltepunkt nach Schritt 5 — **überholt**

> Dieser Unterabschnitt beschreibt den Stand direkt nach Schritt 5 und **vor**
> dem Production-Lauf von `05b`. Der maßgebliche Haltepunkt steht in
> **Abschnitt 17.6**.

**Die Schritte 1 bis 5 sind auf Production ausgeführt und inhaltlich
auditiert.** Damit ist der schreibende Vorwärtspfad dieses Changesets auf der
Datenbank vollständig.

- **Offen war zu diesem Zeitpunkt: die Absicherung der Audit-Payload auf
  Production.** `05` belegt Inhalte, nicht RLS/Policies/Rechte der Payload
  (Abschnitte 5.5, 13.2, 14.4). `05b_verify_payload_security_read_only.sql`
  (Abschnitt 15) schließt diese Lücke; sie war damals **lokal positiv und negativ
  getestet und auditiert** (Abschnitt 16), aber noch nicht für Production
  freigegeben und dort nicht ausgeführt, und damit der nächste ausdrückliche
  read-only Freigabepunkt. **Inzwischen erledigt:** `05b` ist nach eigener
  Freigabe auf Production ausgeführt und bestanden (Abschnitt 17).

- `06_restore_value_add.sql` und `07_down_migration.sql` sind **nicht
  ausgeführt**. Sie sind reine Rollback-Artefakte und brauchen jeweils eine
  eigene, ausdrückliche neue Freigabe nach erneuter sichtbarer Zielprüfung
  `project/ydiihvzcxaaoqhmgoqvu`; `07` zusätzlich erst nach erfolgreichem
  Restore.
- **Kein weiterer Production-DB-Schritt ist automatisch freigegeben.** Die
  Freigaben für Schritt 4 und Schritt 5 waren jeweils auf ihre Datei beschränkt
  und sind verbraucht. Dieses Dokument erteilt keine neue.
- Commit, Merge, Push nach `main` und Vercel-Deploy bleiben gesperrt.
- Weder die lokalen Harness-Läufe (Abschnitte 7.2 und 13.1) noch die
  abgeschlossenen Schritte 1 bis 5 sind eine Freigabe für irgendeine weitere
  Aktion.

### 14.6 Hinweis: live gesetzte `updated_at`-Werte vs. nicht deployter Code

Die zehn `updated_at`-Werte aus Schritt 4 sind **jetzt in der
Production-Datenbank live** (`geaenderte_lastmods` = 10, Abschnitt 14.2). Sobald
die Sitemap revalidiert, können daraus neue `lastmod`-Signale entstehen —
während die zugehörigen Website-Code-Änderungen dieses Branches **noch nicht
deployed** sind.

Das ist **kein Datenfehler**. Es ist eine Reihenfolge-Beobachtung: Datenstand
und Auslieferung laufen bis zum Deploy auseinander. Ein **zeitnaher, getrennter
Code-/Deploy-Audit** ist deshalb sinnvoll — Rendering der Value-Add-Felder,
Sitemap-/`lastmod`-Pfad und Revalidation. Dieser Bericht deckt ausschließlich
die DB-Ebene ab; der Auslieferungspfad ist ausdrücklich nicht getestet
(Abschnitt 8).

**Merge und Deploy bleiben ausdrücklich gesperrt.** Dieser Hinweis ist eine
Empfehlung für den nächsten Audit-Zyklus, keine Freigabe.

---

# Nachtrag — neue read-only Sicherheitsprüfung `05b` (Datei, Prüfumfang und Grenzen)

## 15. `05b_verify_payload_security_read_only.sql`

### 15.1 Der belegte Befund, der zu dieser Datei geführt hat

`05_verify_read_only.sql` prüft die in Schritt 4 neu erzeugte Tabelle
`cbb_private_backup.value_add_payload_v1` ausschließlich **inhaltlich**: 10 Zeilen
und 0 Feldabweichungen gegen `public.products`. Es liest für diese Tabelle
**keinen** Katalogwert — kein `pg_class.relrowsecurity`, kein `pg_policy`, kein
`relacl`, kein `nspacl`. Für den **Snapshot** aus Schritt 3 leistet
`03_verify_snapshot_read_only.sql` genau diese Prüfungen (Nummern 10 bis 14) und
hat sie auf Production auch bestanden (Abschnitt 12.4). Für die **Payload** gab
es kein Production-Gegenstück.

Zwei Textstellen behaupteten trotzdem, Schritt 5 belege „keine App-Rechte" bzw.
bestätige die RLS-Aktivierung aus `04`. Beide sind oben korrigiert
(Abschnitt 13.2 hier, `RUNBOOK.md` Abschnitt „4. Atomarer Backfill →
RLS-Warnung").

### 15.2 Was die neue Datei prüft

Genau ein lesendes `with … select`, ein einziges Semikolon am Dateiende, kein
DDL, kein DML, kein `do $$`, keine Transaktionssteuerung. Fail-closed über
direkte `::regclass`-Referenzen: fehlt die Payload-Tabelle, bricht bereits die
Planung mit „relation does not exist" ab.

**Harte Prüfungen (9, Sortierung 30 bis 110):**

| # | Prüfung | Sollwert |
|---:|---|---|
| 1 | `payload_tabelle_vorhanden` | `true` |
| 2 | `payload_zeilen` | `10` |
| 3 | `payload_spalten` | `10 gesamt, 10 erwartete Namen` |
| 4 | `payload_rls` | `true` |
| 5 | `payload_policies` | `0` |
| 6 | `payload_primaerschluessel` | `PK 1, davon PK(slug) 1` |
| 7 | `app_rollen_vorhanden` | `2/2` |
| 8 | `payload_tabellenrechte_app_rollen` | `Rollen 2/2 \| direkte ACL: PUBLIC 0, anon 0, authenticated 0 \| effektiv: anon 0, authenticated 0` |
| 9 | `payload_schemarechte_app_rollen` | `Rollen 2/2 \| direkte ACL: PUBLIC 0, anon 0, authenticated 0 \| effektiv: anon 0, authenticated 0` |

Die zehn erwarteten Spaltennamen sind die Payload-Definition aus `04`: `slug`,
`fuer_wen`, `nicht_fuer`, `key_fact`, `pros`, `cons`, `alternative_slug`,
`alternative_reason`, `alternative_kind`, `editorial_note`. Zusammen mit
`spalten_gesamt = 10` schließt das eine fehlende wie eine zusätzliche Spalte aus.

Die **direkten** Rechte werden wie in `03_verify_snapshot_read_only.sql` über
`aclexplode(coalesce(acl, acldefault(…)))` auf `pg_class` bzw. `pg_namespace`
gezählt, nicht über `information_schema` — dort fehlen Default-ACLs und
PUBLIC-Einträge.

**Zwei Fail-open-Pfade sind geschlossen:**

1. *Fehlende Rolle.* Existiert `anon` oder `authenticated` nicht, würde der
   Grantee-Join die Zähler still auf 0 drücken. Deshalb ist `role_presence` eine
   eigene harte Zeile **und** zusätzliche Bedingung der Prüfungen 8 und 9.
2. *Geerbte Rechte (korrigiert am 2026-08-23).* `aclexplode` zählt nur Einträge,
   deren Grantee **direkt** PUBLIC, `anon` oder `authenticated` ist. Erbt `anon`
   oder `authenticated` ein Recht über eine **Rollenmitgliedschaft**
   (`grant <rolle> to anon`), taucht dieser Grantee in der ACL der Payload gar
   nicht auf — die direkten Zähler blieben 0 und beide Rechte-Prüfungen meldeten
   fälschlich PASS. Die Datei berechnete effektive Rechte bis dahin nur für
   `service_role` (INFO). Jetzt gilt dieselbe Methode fail-closed auch für die
   zwei harten Rollen: `has_table_privilege` für `SELECT`, `INSERT`, `UPDATE`,
   `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER` und `has_schema_privilege` für
   `USAGE`, `CREATE`, jeweils für `anon` und `authenticated`, gezählt in den CTEs
   `table_privileges_effective` und `schema_privileges_effective`.

Beide harten Rechtezeilen sind seitdem nur PASS, wenn **alle drei** Bedingungen
gelten: Rollenpräsenz `2/2`, direkte/PUBLIC-ACL-Zähler `0` **und** effektive
Privilegien `0`. Ist- und Erwartet-Text weisen die beiden Messungen getrennt aus.
PUBLIC hat keine Rollen-OID und deshalb keinen eigenen `has_*_privilege`-Aufruf;
PUBLIC-Rechte sind in der effektiven Messung bereits enthalten, weil
`has_*_privilege` sie jeder Rolle zurechnet.

Die Zeilenzahl der Ausgabe ändert sich durch die Korrektur nicht — es kommen
keine Zeilen hinzu, die vorhandenen Zeilen 100 und 110 werden strenger und ihr
Text ausführlicher.

**INFO-Zeilen (7):** `current_user` und `current_database` (10/20) sowie fünf
`service_role`-Zeilen (200 bis 240): Rollenexistenz inklusive `bypassrls`,
direkte ACL-Einträge auf Tabelle und Schema, effektive Tabellen- und
Schemaprivilegien über `has_table_privilege`/`has_schema_privilege`.

### 15.3 Warum `service_role` nur INFO ist

Ausdrücklich **keine** PASS-Zusage. Gründe:

1. `04` revoked nur `public, anon, authenticated` — `service_role` ist dort
   **nicht** explizit entzogen.
2. Die bisherige Policy dieses Changesets definiert „App-Rollen" als genau
   `anon` und `authenticated`. Dieselbe Definition verwenden
   `03_verify_snapshot_read_only.sql` und der lokale `assert_after_04.sql`;
   `service_role` ist dort bewusst nicht Teil der Messung.
3. `service_role` ist auf Supabase typischerweise `BYPASSRLS` (in der lokalen
   Fixture explizit: `test/fixture/00_roles.sql`). RLS allein ist gegen sie kein
   Schutz.

Die INFO-Zeilen dokumentieren den Ist-Zustand, damit er sichtbar ist. Eine
Bewertung dieser Rolle braucht einen eigenen, getrennt freigegebenen Vorgang.

Die Fail-open-Korrektur vom 2026-08-23 ändert daran nichts: sie übernimmt die
Methode (`has_table_privilege`/`has_schema_privilege`) für `anon` und
`authenticated` in die **harte** Bewertung, lässt `service_role` aber
unverändert bei **INFO**. Der Geltungsbereich der geprüften App-Rollen wird
durch die Korrektur nicht erweitert.

### 15.4 Dateistand und Prüfungsgrenze

Stand nach der Fail-open-Korrektur vom 2026-08-23:

```
MD5     e5275a5fe11fb8b38704d4ee28dd68a7
SHA-256 749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e
Größe   21564 Bytes, 483 Zeilen
```

Der vorherige Stand — MD5 `e6a99f1a1df49e1becfd3caa712c008b`, SHA-256
`567bb84c890101a46fc2dd3a8b050674aa35e31ae1ea0692690ba2d920c43bc7`, 17174 Bytes,
400 Zeilen — ist damit **ersetzt und nicht mehr zu verwenden**. Auch er war nie
freigegeben und nie ausgeführt, weder lokal noch auf Production.

Erwartete Ausgabe **unverändert**: **16 Zeilen — 9 PASS, 7 INFO, 0 FAIL**,
deterministisch nach `sortierung` sortiert. Die Korrektur fügt keine Zeile hinzu;
sie verschärft die Bedingungen der Zeilen 100 und 110 und erweitert deren Ist-/
Erwartet-Text.

**Bisher geprüft (statisch):** genau ein Semikolon in der gesamten Datei, am
Dateiende (Zeile 483 von 483); keine DDL-/DML-/Rechte-Schlüsselwörter außerhalb
von Textliteralen (die Treffer `SELECT`/`INSERT`/`UPDATE`/`DELETE`/`TRUNCATE`/
`CREATE` stehen ausschließlich als Privilegnamen in `values`-Listen für
`has_table_privilege`/`has_schema_privilege`); Hashes oben.

> **Überholt (2026-08-23).** Hier stand: „**Nicht geprüft:** ein Lauf gegen
> echtes PostgreSQL. Ein lokaler Testlauf war in der Sitzung, in der die Datei
> entstand, nicht ohne Berechtigungsdialog möglich und wurde deshalb **nicht**
> ausgeführt; für die Korrektur vom 2026-08-23 wurde ebenfalls **kein** Lauf
> durchgeführt — auch keine reine Syntaxprüfung gegen einen Server. Es liegt
> **kein gemessenes Ergebnis** vor — weder lokal noch auf Production. Die obige
> Erwartung ist eine Erwartung, kein Messwert." Der lokale Teil dieser Aussage
> ist durch Abschnitt 16 überholt.

**Inzwischen auch dynamisch geprüft — lokal.** Codex hat `05b` am 2026-08-23
unabhängig gegen einen frischen temporären PostgreSQL-16-Cluster ausgeführt:
ein positiver und neun negative Fälle, alle mit exakt der erwarteten Ausgabe
(`ALL_05B_LOCAL_CASES=PASS`). Die oben genannte erwartete Ausgabe — 16 Zeilen,
9 PASS, 7 INFO, 0 FAIL — ist damit **lokal ein Messwert**. Details, Fallliste und
Grenzen in **Abschnitt 16**.

> **Überholt (2026-08-23).** Hier stand außerdem: „**Weiterhin nicht geprüft:**
> der **Production-Zustand**. Auf `ydiihvzcxaaoqhmgoqvu` ist `05b` **nicht
> ausgeführt**; für Production liegt **kein gemessenes Ergebnis** vor." Auch das
> gilt nicht mehr — siehe Abschnitt 17.

**Inzwischen auch auf Production gemessen.** `05b` ist am 2026-08-23 nach eigener
ausdrücklicher read-only Freigabe auf `ydiihvzcxaaoqhmgoqvu` ausgeführt worden:
16 Zeilen, 9 PASS, 7 INFO, 0 FAIL, Dateistand unverändert. Details, vollständige
Ergebnistabelle und Grenzen in **Abschnitt 17**.

Der bestehende Test-Harness und die Dateien `01` bis `07` sind unverändert;
`05b` ist **nicht** Teil der drei Harness-Läufe mit 73/73 PASS — der Lauf aus
Abschnitt 16 ist ein eigener, separater Test.

### 15.5 Status

> **Überholt (2026-08-23).** Hier stand zuerst: „**Neu, lokal, nicht
> freigegeben, nicht ausgeführt.**", danach: „**Lokal positiv und negativ
> getestet, für Production weiterhin nicht freigegeben und dort nicht
> ausgeführt.**" Beides gilt nicht mehr — siehe Abschnitte 16 und 17.

**Lokal positiv und negativ getestet (Abschnitt 16) und danach nach eigener
ausdrücklicher read-only Freigabe auf Production ausgeführt und bestanden
(Abschnitt 17).** Die Freigabe war auf diese Datei beschränkt und ist
verbraucht; ein erneuter Lauf braucht eine neue ausdrückliche read-only Freigabe
nach sichtbarer Zielprüfung `project/ydiihvzcxaaoqhmgoqvu`. Bei jeder FAIL-Zeile
gilt unverändert: nichts korrigieren, nichts nachgranten, nichts löschen —
Befund melden. Commit, Merge, Push und Deploy bleiben unverändert gesperrt.

---

# Nachtrag — lokaler PostgreSQL-Test von `05b` (eigener Lauf, nicht Teil des Harness)

## 16. Lokaler Test von `05b_verify_payload_security_read_only.sql` am 2026-08-23

Dieser Abschnitt schließt die in Abschnitt 15.4 festgehaltene Lücke „kein Lauf
gegen echtes PostgreSQL". Er sagt **nichts** über den Production-Zustand.

### 16.1 Abgrenzung — was dieser Lauf ist und was nicht

- Es ist ein **eigener, separater lokaler Test** nur für `05b`.
- Er ist **nicht** Teil der drei Harness-Läufe mit 73/73 PASS (Abschnitte 7.2
  und 13.1). Diese Läufe bleiben unverändert gültig und unverändert bei 73
  Schritten.
- Der bestehende Test-Harness wurde **nicht** geändert und **nicht** erweitert.
  `05b` ist weiterhin kein Harness-Schritt.
- Die Dateien `01` bis `07` wurden **nicht** angefasst.
- Es gab **keinen** Kontakt zu Production und **keinen** zum Pilotprojekt:
  ein frischer, eigener temporärer PostgreSQL-16-Cluster, ausschließlich über
  einen Unix-Socket erreichbar, ohne TCP-Listener.
- Ausgeführt hat den Lauf **Codex, unabhängig**.

### 16.2 Dateistand während des Tests — unverändert

`05b_verify_payload_security_read_only.sql` blieb über den gesamten Test
unverändert; es ist derselbe Stand wie in Abschnitt 15.4:

```
MD5     e5275a5fe11fb8b38704d4ee28dd68a7
SHA-256 749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e
Größe   21564 Bytes, 483 Zeilen
```

Die statische Eigenschaft wurde dabei erneut bestätigt: **genau ein read-only
`with … select` und genau ein Semikolon** in der gesamten Datei.

### 16.3 Aufbau

1. Frischer lokaler PostgreSQL-16-Cluster, nur Unix-Socket.
2. Aufbau der **Production-ähnlichen Fixture**.
3. Lokaler Lauf von `02` → `03` → `04`, damit die Audit-Payload
   `cbb_private_backup.value_add_payload_v1` in genau dem Zustand vorliegt, den
   `05b` bewerten soll.
4. Danach die zehn `05b`-Fälle aus 16.4 — ein positiver und neun negative.

### 16.4 Die zehn Fälle und ihr gemessenes Ergebnis

| # | Fall | Erwartung | Gemessen | Status |
|---:|---|---|---|---|
| 1 | positiv | rc 0, 16 Zeilen, 9 PASS, 7 INFO, 0 FAIL | exakt so | PASS |
| 2 | `rls_disabled` | genau ein FAIL: `payload_rls` | exakt so | PASS |
| 3 | `extra_policy` | genau ein FAIL: `payload_policies` | exakt so | PASS |
| 4 | `direct_table_grant` | genau ein FAIL: `payload_tabellenrechte_app_rollen` | exakt so | PASS |
| 5 | `direct_schema_grant` | genau ein FAIL: `payload_schemarechte_app_rollen` | exakt so | PASS |
| 6 | `inherited_grants` | genau 2 FAIL, beide Rechtezeilen | exakt so | PASS |
| 7 | `missing_app_role` | genau 3 FAIL: `app_rollen_vorhanden` + beide Rechtezeilen | exakt so | PASS |
| 8 | `extra_column` | genau ein FAIL: `payload_spalten` | exakt so | PASS |
| 9 | `missing_primary_key` | genau ein FAIL: `payload_primaerschluessel` | exakt so | PASS |
| 10 | `missing_table` | psql Exit 3, „relation does not exist", fail-closed vor Ausgabe | exakt so | PASS |

**Alle erwarteten Resultate trafen exakt zu: `ALL_05B_LOCAL_CASES=PASS`.**

Cluster-Stop: PASS. Temp-Cleanup: PASS.

### 16.5 Was die einzelnen Fälle belegen

- **Fall 1** bestätigt die bisher nur erwartete Ausgabeform als **Messwert**:
  16 Zeilen, 9 harte PASS, 7 INFO, 0 FAIL, Exit 0. Abschnitt 15.4 sagte dazu
  „eine Erwartung, kein Messwert" — das gilt lokal nicht mehr.
- **Fälle 2, 3, 8, 9** treffen jeweils **genau** die zuständige harte Zeile und
  keine andere. Die Prüfungen sind also trennscharf, nicht pauschal.
- **Fall 6 (`inherited_grants`)** ist der wichtigste: er beweist, dass die am
  2026-08-23 eingebaute **effektive** Rechteprüfung
  (`has_table_privilege`/`has_schema_privilege`) tatsächlich greift. Ein über
  **Rollenmitgliedschaft geerbtes** Recht erzeugt zwei FAIL — der in Abschnitt
  15.2 beschriebene Fail-open-Pfad ist damit nicht nur behauptet, sondern
  gemessen geschlossen.
- **Fall 7 (`missing_app_role`)** beweist den zweiten Fail-open-Pfad: eine
  fehlende App-Rolle ergibt drei FAIL statt eines stillen PASS.
- **Fall 10 (`missing_table`)** beweist das Fail-closed-Verhalten: bei fehlender
  Payload-Tabelle bricht `psql` mit Exit 3 ab, **bevor** irgendeine
  Ergebniszeile entsteht. Es gibt kein „PASS auf einer Tabelle, die es nicht
  gibt".

### 16.6 Was dieser Lauf **nicht** belegt

- **Keine Aussage über Production.** Gemessen wurde eine lokale Fixture, nicht
  `ydiihvzcxaaoqhmgoqvu`. Was auf Production gilt, belegt ausschließlich der
  **eigene Production-Lauf** in Abschnitt 17 — dieser Abschnitt hat ihn
  ausdrücklich **nicht** vorweggenommen.
- **Keine Freigabe.** Der Lauf hat am Freigabestand nichts geändert. Die
  Production-Ausführung erfolgte erst danach, auf eine eigene ausdrückliche
  read-only Freigabe hin (Abschnitt 17.1).
- Der Lauf sagt nichts über `service_role` — die fünf `service_role`-Zeilen
  bleiben INFO ohne PASS-Zusage (Abschnitt 15.3).

### 16.7 Status nach diesem Lauf

> **Überholt (2026-08-23).** Hier stand: „`05b` ist **lokal positiv und negativ
> getestet und auditiert**, bleibt aber der **nächste ausdrückliche read-only
> Freigabepunkt** dieses Changesets." Der Freigabepunkt ist inzwischen
> wahrgenommen und abgeschlossen — siehe Abschnitt 17.

Zum Zeitpunkt dieses Laufs war `05b` **lokal positiv und negativ getestet und
auditiert** und der nächste ausdrückliche read-only Freigabepunkt. Der
Production-Lauf folgte am selben Tag nach eigener Freigabe (Abschnitt 17).
Unverändert gilt für jeden künftigen Lauf: sichtbares Projekt
`project/ydiihvzcxaaoqhmgoqvu` kontrollieren, eigene ausdrückliche read-only
Freigabe einholen, bei jeder FAIL-Zeile nichts korrigieren, nichts nachgranten,
nichts löschen — Befund melden. Commit, Merge, Push und Deploy bleiben
gesperrt.

---

# Nachtrag — Production-Ausführung der read-only Sicherheitsprüfung `05b`

## 17. Production-Schritt 5b am 2026-08-23

Dieser Abschnitt schließt die in den Abschnitten 5.5, 13.2, 14.4 und 15.4
festgehaltene Lücke „Absicherung der Audit-Payload auf Production ungemessen".

### 17.1 Freigabe und statische Vorabprüfung

Der Benutzer hat `05b` ausdrücklich, projektbezogen und ausdrücklich als
read-only freigegeben:

> „Ich gebe Production-Schritt 5b (read-only Payload-Sicherheitsprüfung) auf
> ydiihvzcxaaoqhmgoqvu frei."

Die Datei war zum Zeitpunkt der Freigabe bereits statisch und dynamisch geprüft
(Abschnitte 15.4 und 16). Der Dateistand blieb unverändert und ist es auch nach
dem Lauf:

```
MD5     e5275a5fe11fb8b38704d4ee28dd68a7
SHA-256 749edde6a95379327c63419c813b03fa4732021073aa00f680cf7e9ae518f81e
Größe   21564 Bytes, 483 Zeilen
```

Statische Eigenschaft erneut bestätigt: **genau ein read-only `with … select`**,
kein DDL, kein DML, kein `do $$`, keine Transaktionssteuerung.

### 17.2 Ausführungsweg

**Manuell durch den Benutzer**, aus der finalen auditierten lokalen Datei, im
SQL-Editor des **sichtbar bestätigten** Production-Projekts
`ydiihvzcxaaoqhmgoqvu`. Keine Automatisierung, kein Chrome-Zugriff durch Claude,
kein Harness-Lauf. Die Datei schreibt nichts.

### 17.3 Ergebnis auf Production

**Exakt 16 Zeilen: 9 PASS, 7 INFO, 0 FAIL.**

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

**Zur Darstellung.** Die beiden Rechtezeilen und `service_role_vorhanden`
enthalten im Original Pipe-Zeichen als Trennzeichen innerhalb des Ist-Textes
(`… | direkte ACL: … | effektiv: …` bzw. `ja | bypassrls true`). In der
Rohmeldung wurden diese Pipes von Markdown als zusätzliche Spaltentrenner
gelesen; die Zeilen sind hier deshalb mit „·" wiedergegeben. Der jeweilige
Schlusswert war eindeutig **PASS** bzw. **INFO** — an den Werten ändert die
Wiedergabe nichts.

**Unabhängige Zählung.** Codex hat die 16 Ergebniszeilen unabhängig
rekonstruiert und gegen die erwartete Matrix aus Abschnitt 15.2 abgeglichen:
9 PASS, 7 INFO, 0 FAIL, keine fehlende und keine zusätzliche Zeile.

### 17.4 Abgleich mit dem lokalen Lauf

Das Production-Ergebnis stimmt in Zeilenzahl, Prüfungsnamen, Status und allen
harten Werten mit dem positiven lokalen Fall aus Abschnitt 16.4 überein: dort
16 Zeilen, 9 PASS, 7 INFO, 0 FAIL gegen die Fixture, hier dieselben 16 Zeilen mit
denselben 9 PASS gegen Production. Die in Abschnitt 15.4 als „Erwartung, kein
Messwert" bezeichnete Ausgabeform ist damit auch auf Production ein Messwert.

### 17.5 Was belegt ist — und was nicht

**Belegt (Production, gemessen).** Die Audit-Payload
`cbb_private_backup.value_add_payload_v1` existiert, hat exakt 10 Zeilen und
exakt 10 Spalten mit den 10 erwarteten Namen, RLS ist aktiv, es gibt **0
Policies**, der Primärschlüssel ist genau einer und genau `PK(slug)`, beide
App-Rollen `anon` und `authenticated` existieren (2/2), und es gibt für PUBLIC,
`anon` und `authenticated` **keine Rechte** — weder als direkte ACL-Einträge noch
als **effektive** Privilegien über Rollenmitgliedschaft, weder auf der Tabelle
noch auf dem Schema. Beide Fail-open-Pfade aus Abschnitt 15.2 waren in diesem
Lauf aktiv abgesichert: die Rollenpräsenz ist eigene harte Zeile **und**
Bedingung beider Rechtezeilen.

Damit ist die Payload auf Production auf derselben Ebene belegt wie der Snapshot
aus Schritt 3 (Abschnitt 12.4).

**`service_role`: Ist-Werte, ausdrücklich nur INFO.** Gemessen wurde für diesen
Zustand: `service_role` existiert, ist `bypassrls`, hat **keine** direkten
ACL-Einträge auf Tabelle oder Schema und **keine** effektiven Tabellen- oder
Schemarechte. Das ist ein dokumentierter Ist-Zustand und **keine** PASS-Zusage
und **keine** allgemeine Sicherheitsaussage über diese Rolle. Die Gründe stehen
unverändert in Abschnitt 15.3: `04` entzieht `service_role` nichts explizit, die
Changeset-Definition von „App-Rollen" umfasst genau `anon` und `authenticated`,
und `BYPASSRLS` macht RLS gegen diese Rolle wirkungslos. Eine Bewertung von
`service_role` braucht weiterhin einen eigenen, getrennt freigegebenen Vorgang.

**Nicht belegt.** Der Lauf ist read-only und traf keinen Sperrkonflikt — er sagt
nichts über den Lock-Timeout unter realer Nebenläufigkeit. Er sagt ebenso nichts
über den byteweisen Editorinhalt der Schritte 2 bis 4 (Abschnitte 11.2, 12.2,
13.3) und nichts über den Auslieferungspfad der Website (Abschnitt 8).

### 17.6 Aktueller Haltepunkt

**Die Schritte 1 bis 5b sind auf Production ausgeführt und auditiert.** Der
geplante Pfad dieses Changesets auf der Datenbank ist damit vollständig —
schreibend (`02`, `03`, `04`) wie prüfend (`01`, `03`-Postcheck, `05`, `05b`).

- **Kein weiterer Production-DB-Schritt ist freigegeben.** Die Freigaben für die
  Schritte 4, 5 und 5b waren jeweils auf ihre Datei beschränkt und sind
  verbraucht. Dieses Dokument erteilt keine neue Freigabe.
- `06_restore_value_add.sql` und `07_down_migration.sql` sind **nicht
  ausgeführt**. Sie sind reine Rollback-Artefakte und brauchen jeweils eine
  eigene, ausdrückliche neue Freigabe nach erneuter sichtbarer Zielprüfung
  `project/ydiihvzcxaaoqhmgoqvu`; `07` zusätzlich erst nach erfolgreichem
  Restore.
- Commit, Merge, Push nach `main` und Vercel-Deploy bleiben gesperrt.
- Weder die lokalen Läufe (Abschnitte 7.2, 13.1, 16) noch die abgeschlossenen
  Schritte 1 bis 5b sind eine Freigabe für irgendeine weitere Aktion.

**Nächster sinnvoller Vorgang — rein lokal, ohne Freigabe.** Ein
**Code-/Deploy-Readiness-Audit** des Frontends: Rendering der Value-Add-Felder,
Sitemap-/`lastmod`-Pfad und Revalidation (Hintergrund: Abschnitt 14.6 — die zehn
`updated_at`-Werte sind live, der zugehörige Code ist nicht deployed). Dieser
Audit ist **ausdrücklich keine Freigabe für Merge oder Deploy** und braucht weder
Datenbank- noch Netzwerk- noch Git-Aktionen.
