# Lokaler PostgreSQL-Harness — Value-Add Batch 2

Testet die **Originaldateien** `01_preflight_read_only.sql` bis
`05_restore_value_add_batch2.sql` aus dem übergeordneten Verzeichnis gegen eine
echte PostgreSQL-Instanz. Der Harness kopiert und schreibt keine dieser Dateien
um — er führt sie so aus, wie sie später im Supabase-Editor laufen würden.

## Was der Harness nicht tut

- Er verbindet sich **nicht** mit Production (`ydiihvzcxaaoqhmgoqvu`).
- Er verbindet sich **nicht** mit Pilot/Staging (`nmzuycveumyfvtxdcnuc`).
- Er öffnet **keinen** TCP-Port: der Cluster läuft mit `listen_addresses=''`
  und ist ausschließlich über einen Unix-Socket im eigenen Temp-Verzeichnis
  erreichbar.
- Er führt **keine** Datei aus `../../production_value_add/` aus und verändert
  dort nichts. Der Batch-1-Zustand wird von `fixture/03_v1_artifacts.sql`
  nachgebaut.
- Er committet, merged, pusht und deployt nichts.

Der Cluster wird in `mktemp -d` angelegt und am Ende über `pg_ctl -m fast stop`
wieder gestoppt — auch, wenn der Lauf vorzeitig abbricht (`trap … EXIT`).

## Aufruf

```bash
cd apps/web/supabase/production_value_add_batch2/test
bash run_local_postgres_test.sh
```

| Variable | Wirkung |
|---|---|
| `CBB_STATIC_ONLY=1` | nur Stufe 1 (`case_0_statisch`), kein Cluster |
| `CBB_PG_BIN` | Pfad zu den PostgreSQL-Binaries — Prefix mit `bin/` (`/usr/lib/postgresql/16`) oder direkt das bin-Verzeichnis. Ohne die Variable löst der Harness selbst auf: `pg_config --bindir`, sonst das Verzeichnis von `initdb` im `PATH`, sonst `/usr/lib/postgresql/<18…14>/bin`, falls vorhanden. |
| `CBB_KEEP_CLUSTER=1` | Datenverzeichnis nach dem Lauf behalten (Server wird trotzdem gestoppt) |

Exit-Code `0` = alle Erwartungen erfüllt, `1` = mindestens eine Abweichung,
`2` = Umgebungs-/Setup-Problem.

Liegen die Binaries in einem entpackten Paketbaum statt in `/usr`, setzt das
Skript `LD_LIBRARY_PATH` selbst auf das Verzeichnis mit `libpq.so.5` — ohne das
bricht `initdb` mit Exit 127 ab.

### Aufruf auf dieser Maschine

PostgreSQL ist hier **nicht systemweit installiert**. Für die Läufe vom
2026-08-26 lag 16.15 ausschließlich entpackt unter `/tmp`. Der Aufruf folgte
deshalb diesem Muster:

```bash
env LD_LIBRARY_PATH=<entpackter-baum>/root/usr/lib/x86_64-linux-gnu \
    CBB_PG_BIN=<entpackter-baum>/root/usr/lib/postgresql/16/bin \
    bash test/run_local_postgres_test.sh
```

`/tmp` überlebt keinen Neustart — für eine Wiederholung muss der Paketbaum
erneut entpackt und der Pfad angepasst werden.

**Sandbox:** ein Lauf innerhalb einer Sandbox kann schon am Anlegen des
Unix-Sockets scheitern (`EPERM`) und bricht dann **vor** dem ersten
Datenbankfall ab. Das ist ein Infrastrukturproblem, kein SQL-Befund. Der
Harness braucht ein Verzeichnis, in dem er einen Unix-Socket anlegen darf.

## Zweistufiger Aufbau

**Stufe 1 (`case_0_statisch`) braucht keinen Cluster** und läuft immer zuerst.
Fehlt PostgreSQL, gibt der Harness die Stufe-1-Ergebnisse trotzdem vollständig
aus und endet mit Exit `2` und der Meldung
`GESAMT: UMGEBUNG UNVOLLSTAENDIG`. Das ist ausdrücklich **kein** PASS und
**kein** FAIL der Rollout-Dateien — die Datenbankfälle sind dann schlicht nicht
bewertet.

Schlägt Stufe 1 fehl, bricht der Harness mit Exit `1` ab, bevor er einen
Cluster startet: ein Lock-Test gegen falsch platzierte `set local`-Zeilen wäre
nicht aussagekräftig.

### Stufe 1 im Einzelnen — 17 Prüfungen

| Prüfung | Inhalt |
|---|---|
| `v1_manifest_sha256` | `sha256sum -c V1_MANIFEST.sha256`: alle 34 Dateien unter `production_value_add/` plus `seo_updated_at_trigger.sql` byte-identisch. Der direkte Beweis, dass Batch 1 unangetastet ist. |
| `setlocal_02` / `_03` / `_05` | genau ein `begin;`, genau ein `commit;`, genau eine `lock_timeout`- und eine `statement_timeout`-Zeile (keine Duplikate), `statement_timeout` direkt unter `lock_timeout`, beide hinter `begin;` und vor dem ersten `do $$`, dazwischen nur Leerzeilen und `--`-Kommentare |
| `writesafe_02` / `_03` / `_05` | kein ausführbares `DROP`/`TRUNCATE`/`DELETE` (einzige Ausnahme: die `on commit drop`-Klausel der temporären Payload-Tabelle in `03`), und jede ausführbare Zeile mit `value_add_*_v1` steht innerhalb eines `to_regclass()`-Aufrufs |
| `readonly_01` / `_02b` / `_04` / `_04b` | nach dem Entfernen von Kommentaren **und** Text-Literalen: kein `insert/update/delete/merge/create/alter/drop/truncate/grant/revoke/call/commit/rollback/begin/vacuum/analyze/reindex/copy`, kein `do $$`, und genau **ein** Semikolon |
| `slugs_*` (6×) | alle zehn Batch-2-Slugs kommen in jeder der sechs SQL-Dateien vor |

Die Reihenfolge in `readonly_*` ist bewusst *erst Kommentare, dann Literale*:
kein Literal dieser Dateien enthält `--`, während Kommentare sehr wohl
Apostrophe enthalten können. Umgekehrt wäre die Auswertung fragil. Dass die
Privilegnamen `SELECT`, `INSERT`, … in `02b` und `04b` nur als **Literale** in
`values`-Listen vorkommen, ist damit statisch belegt und nicht bloß behauptet.

## Fixture

`fixture/` baut den Zustand nach, den Production am 2026-08-26 hatte —
also **nach** Batch 1:

| Merkmal | Wert |
|---|---|
| Produkte | 376 gesamt, 372 published |
| Batch-2-Zielprodukte | 10/10 published, 0/8 Value-Add-Felder gesetzt |
| Batch-2-Relationsziele | 2/2 published |
| Batch-1-Zielprodukte | 10/10 published, vollständig befüllt, Verteilung 3/2/5 |
| Value-Add gesamt | exakt 10 Zeilen (nur Batch 1) |
| Value-Add-Schema | 8/8 Spalten, 2/2 Constraints — **von Anfang an**, Batch 2 migriert nicht |
| `products_rls` / Policies | true / 2 |
| App-Grants auf `products` | 14 |
| Trigger | `products_set_updated_at` aus dem echten `seo_updated_at_trigger.sql` |
| Rollen | `anon`, `authenticated`, `service_role` |
| v1-Artefakte | Snapshot (12 Spalten, 10 Zeilen) und Payload (10 Spalten, 10 Zeilen), RLS an, 0 Policies, keine App-Rechte |
| v2-Artefakte | fehlen |

`fixture/01_schema.sql` übernimmt die beiden CHECK-Constraints **wortgleich**
aus `production_value_add/02_migrate_value_add.sql`.

`fixture/03_v1_artifacts.sql` baut die Batch-1-Artefakte nach, ohne die
Batch-1-Dateien auszuführen. Wichtig ist der Zeitstand: der **Snapshot** hält
den Zustand *vor* dem Batch-1-Backfill (acht Felder `NULL`, drei alte
`editorial_note`-Texte, historische `updated_at`), die **Payload** den Zustand
*danach* — sie wird aus `public.products` abgeleitet und stimmt deshalb per
Konstruktion mit dem Bestand überein.

`fixture/04_assert_fixture.sql` bricht hart ab, wenn die Fixture von diesem
Zielbild abweicht — sonst wären alle späteren PASS-Zeilen wertlos.

`fixture/05_baseline.sql` legt drei unveränderliche Kopien an: alle 376
Produktzeilen (mit `editorial_note`, `updated_at` und den acht
Value-Add-Feldern), den v1-Snapshot und die v1-Payload. Gegen diese Kopien wird
später Zeile für Zeile verglichen.

Alle Produkttexte der Fixture sind Testdaten mit `example.invalid`-Links. Die
bestehenden Notizen tragen die Präfixe `ALT-NOTE` (Batch 2), `B1-NOTE`
(Batch 1, aktueller Stand) und `B1-ALT-NOTE` (Batch 1, Snapshot-Stand), damit
im Report sichtbar ist, welcher Text zurückkam.

## Testfälle (Stufe 2)

| Fall | Inhalt |
|---|---|
| `case_a_happy_path` | 01 → 02 → 02b → 03 → 04 → 04b in der vorgesehenen Reihenfolge |
| `case_b_wiederholungen` | 02b/03/05 **vor** dem Backup; 04/04b **vor** dem Backfill; jede schreibende Datei zweimal |
| `case_n_drift` | eine Zielzeile ändert sich zwischen 02 und 03 → Drift-Guard, und 02b meldet den Drift als FAIL-Zeile |
| `case_c_rollback` | erzwungener Fehler mitten in der 03-Transaktion, Rollback-Beweis inklusive des bereits erzeugten Payload-DDL |
| `case_d_restore_roundtrip` | 02 → 03 → 05 → 05 (idempotent), Round-Trip über alle 376 Zeilen |
| `case_e_pilot_artefakt` | `pilot_meta.environment_guard` vorhanden |
| `case_f_zu_wenig_produkte` | Bestand auf 299 gedrückt |
| `case_g_unvollstaendiges_schema` | `key_fact` entfernt → 7/8 Spalten |
| `case_h_relationsziel_offline` | `shashibo` unpublished |
| `case_m_fremdbefuellung` | eine Zielzeile trägt bereits `key_fact` |
| `case_k_batch1_artefakt_fehlt` | `value_add_payload_v1` gelöscht |
| `case_l_payload_security` | `anon` bekommt `SELECT` auf die Payload → 04b **muss** FAIL melden |
| `case_o_snapshot_security` | `anon` bekommt `SELECT` auf den Snapshot → 02b **muss** FAIL melden |
| `case_i_trigger` | Trigger hebt lastmod bei sichtbarer Änderung, nicht bei `price_cents` und nicht bei den acht Value-Add-Spalten, und respektiert explizit gesetztes `updated_at` |
| `case_j_lock_timeout` | 02 unter `AccessExclusiveLock` auf `public.products` |

Jeder Fall bekommt über `createdb -T cbb_fixture` eine frische Datenbank, läuft
also unabhängig von den anderen.

Nach fast jedem Fall läuft zusätzlich `cases/assert_v1_untouched.sql`. Zwei
Ausnahmen, beide begründet:

- `case_g_unvollstaendiges_schema` — die Datei liest `products.key_fact`, die
  dieser Fall absichtlich entfernt hat. Zuständig ist
  `cases/assert_schema_teilzustand.sql`.
- `case_k_batch1_artefakt_fehlt` — die Datei verlangt ein vollständiges
  Batch 1, das dieser Fall absichtlich zerstört. Zuständig ist
  `cases/assert_v1_payload_missing.sql`.

## Wie streng geprüft wird

### 1. Erwartete Abbrüche brauchen den *richtigen* Fehler

`step <db> fail <label> <datei> <literal>` verlangt **beides**: psql-Exit
**exakt 3** und das Literal wörtlich im Output (`grep -F`). Das Literal ist
Pflicht; fehlt es, ist der Schritt FAIL („HARNESS-FEHLER"). Ein Abbruch mit
einem *anderen* Fehler ist ebenfalls FAIL.

| Schritt | Erwarteter Serverfehler |
|---|---|
| `b_02b_vor_backup` | `relation "cbb_private_backup.value_add_pre_backfill_v2" does not exist` |
| `b_03_vor_backup` | `Batch-2-Backfill abgebrochen: privater Snapshot v2 fehlt.` |
| `b_05_vor_backup` | `Batch-2-Restore abgebrochen: privater Snapshot v2 fehlt.` |
| `b_02_wiederholung` | `Batch-2-Backup abgebrochen: Snapshot v2 existiert bereits.` |
| `b_04_vor_backfill` | `relation "cbb_private_backup.value_add_payload_v2" does not exist` |
| `b_04b_vor_backfill` | `relation "cbb_private_backup.value_add_payload_v2" does not exist` |
| `b_03_wiederholung` | `Batch-2-Backfill abgebrochen: Audit-Payload v2 existiert bereits.` |
| `n_03_abbruch` | `Batch-2-Backfill abgebrochen: 1 Zielzeilen sind seit dem Snapshot gedriftet.` |
| `c_03_bricht_ab` | `CBB-TEST: UPDATE auf products absichtlich blockiert.` |
| `d_03_nach_restore` | `Batch-2-Backfill abgebrochen: Audit-Payload v2 existiert bereits.` |
| `e_02_abbruch` | `Batch-2-Backup abgebrochen: Pilot-Artefakt gefunden.` |
| `f_02_abbruch` | `Batch-2-Backup abgebrochen: nur 299 Produkte (< 300).` |
| `g_02_abbruch` | `Batch-2-Backup abgebrochen: Value-Add-Schema unvollstaendig (7 Spalten, 7 Typen, 2 Constraints).` |
| `h_02_abbruch` | `Batch-2-Backup abgebrochen: 9/10 Zielprodukte published.` |
| `m_02_abbruch` | `Batch-2-Backup abgebrochen: 1 Zielprodukte enthalten bereits Value-Add-Daten.` |
| `k_02_abbruch` | `Batch-2-Backup abgebrochen: Batch-1-Payload v1 fehlt.` |
| `j_02_unter_sperre` | `canceling statement due to lock timeout` |

Zu `b_03_wiederholung`: nach einem erfolgreichen `03` schlägt der
**Payload-Guard** zu, nicht der Drift-Guard — die Existenzprüfung von
`value_add_payload_v2` steht bewusst im ersten Guard-Block und damit vor dem
Zeilen-Lock. Der Drift-Guard bekommt mit `case_n_drift` einen eigenen Fall.

Zu `h_02_abbruch`: beide Relationsziele von Batch 2 liegen **innerhalb** der
Zielmenge. Ein unpublished Relationsziel löst deshalb zuerst den
Published-Guard aus. Das ist die strengere Bedingung.

### 2. Die vier lesenden Dateien: exakte PASS-Zahl

| Datei | Erwartung |
|---|---|
| `01_preflight_read_only.sql` | exakt **16** PASS, 0 FAIL (dazu 9 INFO, 25 Zeilen) |
| `02b_verify_snapshot_read_only.sql` | exakt **17** PASS, 0 FAIL (dazu 4 INFO, 21 Zeilen) |
| `04_verify_read_only.sql` | exakt **17** PASS, 0 FAIL (dazu 4 INFO, 21 Zeilen) |
| `04b_verify_payload_security_read_only.sql` | exakt **10** PASS, 0 FAIL (dazu 7 INFO, 17 Zeilen) |

„Mehr als 0 PASS" reicht nicht — eine versehentlich gelöschte Prüfzeile fällt
so auf.

### 3. Sicherheitsprüfungen müssen auch *greifen*

Zwei Fälle reißen absichtlich ein Loch (`grant usage on schema` +
`grant select`) und verlangen über `report_table_expect_fail`, dass die
zuständige Prüfdatei es meldet:

- `case_l_payload_security`: nach dem Grant auf die **Payload** liefert `04b`
  genau **8 PASS und 2 FAIL** — die Tabellenrechte
  (`payload_v2_tabellenrechte_app_rollen`) und die Schemarechte
  (`payload_v2_schemarechte_app_rollen`).
- `case_o_snapshot_security`: nach dem Grant auf den **Snapshot** liefert `02b`
  genau **15 PASS und 2 FAIL** — `snapshot_v2_tabellenrechte_app_rollen` und
  `snapshot_v2_schemarechte_app_rollen`.

Beide sind bewusst getrennte Fälle: `02b` verlangt zusätzlich, dass
`value_add_payload_v2` noch **nicht** existiert. Liefe es nach einem Backfill,
wäre diese Zeile ebenfalls FAIL und die Zählung nicht mehr eindeutig dem
Rechte-Loch zuzuordnen.

Ein PASS wäre hier jeweils der eigentliche Befund. Ohne diese Fälle wäre ein
grünes `04b` nur die Aussage „die Prüfung läuft", nicht „die Prüfung greift".

### 4. Lock-Test: Exit 3, richtige Meldung, richtige Zeit

`case_j_lock_timeout` verlangt psql-Exit **3**, die Meldung
`canceling statement due to lock timeout` und eine Laufzeit im Fenster
**3–15 s** (`lock_timeout = '5s'`). Exit 124 (Client-Timeout), ein anderer
Fehlertext oder ein erfolgreicher Durchlauf sind jeweils FAIL.

Der Lock-Halter läuft mit einem eindeutigen `application_name` und wird über
`pg_terminate_backend` beendet, nicht per `kill` des psql-Clients. Der Harness
wartet danach aktiv, bis kein `AccessExclusiveLock` mehr granted ist, und
schlägt fehl, wenn der Nachtest länger als 30 s braucht.

### 5. Setup ist fail-closed

`initdb`, `pg_ctl start`, `createdb cbb_fixture` und jedes
`createdb -T cbb_fixture <fall>` beenden den Harness bei Fehler sofort mit
Exit `2`.

## Ergebnisse

Der Lauf schreibt `results.tsv` und ein `logs/`-Verzeichnis in sein
Temp-Verzeichnis und gibt den Pfad am Ende aus. Der ausgewertete Lauf ist in
[`../LOCAL_TEST_REPORT.md`](../LOCAL_TEST_REPORT.md) dokumentiert.

### Letzter ausgeführter Lauf

Ausgeführt und auditiert von **Codex** am 2026-08-26 auf dem **aktuellen**,
textentschärften Stand der Rollout-Dateien — Workdir
`/tmp/cbb-pgtest-b2.CvjYPVa5`:

| | Wert |
|---|---|
| PostgreSQL | **16.15** |
| Exit-Code | **0** |
| Schritte | **106** |
| Abweichungen | **0** |
| Gesamturteil | **GESAMT PASS** |
| `v1_manifest_sha256` | **34/34 identisch** |
| Cluster | sauber gestoppt |

Bestanden sind damit Stufe 1 vollständig sowie alle Fälle der Stufe 2: Happy
Path, Wiederholungen, Drift, Transaktionsrollback, doppelter
Restore-Roundtrip, die Pilot-, Bestands-, Schema-, Published-,
Fremdbefüllungs- und v1-Guards, die Payload- und Snapshot-ACL-Negativtests,
das Trigger-Verhalten und das Lock-Timeout bei `lock_timeout = '5s'`.

Das ist der Gate-0-Beleg in `../RUNBOOK.md` §5.

### Historie: der Lauf davor

Vor der Textnachschärfung in `../03_backfill_value_add_batch2.sql` (siehe
`../RUNBOOK.md` §4, „Quellenbindung der Texte") lief derselbe Harness bereits
einmal vollständig durch — Workdir `/tmp/cbb-pgtest-b2.6t9bQFUe`, ebenfalls
Exit 0, 106 Schritte, 0 Abweichungen, GESAMT PASS, v1-Manifest 34/34.
Geändert wurden zwischen beiden Läufen ausschließlich Fließtexte;
SQL-Struktur, Slugs, Relationen, Feld- und Array-Anzahl sowie alle Guards
blieben unverändert, die Erwartungswerte dieses Harness waren davon nicht
betroffen — was der Lauf oben bestätigt.
