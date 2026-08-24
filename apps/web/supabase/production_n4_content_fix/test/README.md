# Lokaler PostgreSQL-Harness — N4-Content-Korrektur

## Ausfuehrungsstatus

**Stand: korrigierter Gesamtlauf erfolgreich — 94 Schritte, 0 Abweichungen,
Exit 0.**

### Lauf 2 (Codex, korrigierter Harness)

Der vollstaendige Wiederholungslauf gegen einen neuen isolierten
PostgreSQL-16-Cluster ist erfolgreich:

* **94 von 94 Schritten PASS**, 0 Abweichungen, Prozess-Exit **0**.
* `case_g_konkurrenz_02` und `case_h_konkurrenz_04` erreichten nachweislich
  den serverseitigen Lock-Wartepunkt. Nach dem Konkurrenz-COMMIT brachen `02`
  bzw. `04` mit Exit 3 und der jeweils erwarteten Recheck-Meldung ab; die
  fremden Aenderungen blieben erhalten.
* `case_f_lock_timeout` brach unter dem echten `AccessExclusiveLock` nach
  rund 5 Sekunden mit `canceling statement due to lock timeout` ab.
* Das Cleanup stoppte PostgreSQL mit `pg_ctl stop` Exit **0** und entfernte
  `PGDATA` sowie das Socketverzeichnis. Es laeuft kein Testcluster mehr.

Damit ist der unten dokumentierte FIFO-/Namenslaengen-Fix praktisch belegt.

### Lauf 1 (Codex, echter lokaler Cluster)

Der Harness wurde erstmals wirklich gegen eine echte PostgreSQL-16-Instanz
gestartet. Ergebnis:

* Alle Faelle **bis einschliesslich `case_e_restore` waren PASS** —
  `case_0_statisch`, Fixture-Aufbau, `case_a` bis `case_e`.
* **`case_g_konkurrenz_02` hing.** Nicht die geprueften SQL-Dateien, sondern
  der **Harness selbst**: ein Deadlock in der FIFO-Steuerung der zweiten
  Session (Diagnose unten).
* Der Lauf wurde daraufhin **gezielt beendet**. Das `trap`-Cleanup lief
  vollstaendig: `pg_ctl stop` mit **Exit 0**, `PGDATA` und Socketverzeichnis
  entfernt. Es laeuft kein Cluster mehr.
* **`case_g`, `case_h` und `case_f` sind damit unbewertet.** Der Lauf ist
  **kein** Gesamt-PASS und wird hier auch nicht als einer ausgegeben.

### Was genau haengen blieb

1. **FIFO-Deadlock.** `exec 8<>"$fifo"` wurde **vor** dem Start des lesenden
   `psql`-Kindprozesses ausgefuehrt. Das Kind erbte fd 8 damit als **eigenes
   Schreibende** der FIFO. Nach `rollback;`, `exec 8>&-` im Parent und `wait`
   bekam `psql` deshalb nie EOF — es hielt den letzten Writer selbst.
   `pg_stat_activity` zeigte den Halter `idle` / `ClientRead` bei
   `query = 'rollback;'`.
2. **Abgeschnittener `application_name`.** Erwartet war der volle
   `${LOCK_APP}_hold_${label}`; sichtbar war nur
   `cbb_n4_lock_holder_cbb-n4test..._hold_g_02_unter_konkurre` — PostgreSQL
   kuerzt `application_name` hart auf `NAMEDATALEN-1` = **63 Byte**. Exakte
   Wartepunkt-Suchen in `pg_stat_activity` sind damit unzuverlaessig.

### Was daraufhin geaendert wurde

* **fd-Reihenfolge umgedreht:** der FIFO-**Leser** (`psql -f fifo`) startet
  jetzt zuerst, **danach** oeffnet der Parent fd 8 mit `exec 8>"$fifo"` als
  reines Schreibende. Das Kind kann fd 8 nicht mehr erben; `exec 8>&-` erzeugt
  echtes EOF und `wait` terminiert. Alle spaeter gestarteten
  Hintergrundprozesse — auch der Ziellauf — starten mit `8>&-`, damit kein
  zweiter Writer das EOF verhindert. Ein Wachhund gibt den Parent wieder frei,
  falls `psql` stirbt, bevor es die FIFO ueberhaupt oeffnet (`psql` oeffnet die
  `-f`-Datei erst nach erfolgreichem Verbindungsaufbau), und ein begrenzter
  Reaper verhindert, dass ein kuenftiger Fehler den Lauf erneut unbegrenzt
  blockiert.
* **`application_name` deterministisch gekuerzt:** der Praefix ist jetzt
  `cbb_n4_<8 Zeichen mktemp-Suffix>` (15 Zeichen) statt
  `cbb_n4_lock_holder_<basename WORKDIR>` (38 Zeichen). Laengster
  zusammengesetzter Name: `cbb_n4_XXXXXXXX_hold_g_02_unter_konkurrenz` =
  **42 Zeichen**, also deutlich unter 63. Der neue statische Schritt
  `static_appname_laenge` rechnet das im Lauf nach und **bricht ab**, wenn
  irgendein Name die Grenze reisst; zusaetzlich prueft `konkurrenz_lauf` jeden
  Namen noch einmal vor der Benutzung.
* **Sachlich falscher Kommentar in `case_h` korrigiert** — siehe
  "Warum gerade `pros` und `nicht_fuer`".

Der anschliessende Lauf 2 hat diese Korrekturen und alle zuvor offenen Faelle
erfolgreich bestaetigt.

### Frueherer Stand (Sitzungen 1 und 2)

Der Harness wurde in den beiden Sitzungen, in denen er entstand bzw. um die
Nebenlaeufigkeits- und Restore-Faelle erweitert wurde, **gar nicht**
ausgefuehrt: beide liefen non-interaktiv mit einer Berechtigungsregel, die das
Starten neuer Prozesse verweigert (`bash …`, `sh …`, `./…`, `chmod +x`,
`postgres --version`, `mktemp -d`, spaeter auch `awk`, `grep` und `bash -n`).
Die statische Kontrolle der SET-LOCAL-Position erfolgte dort durch **Lesen**
der Dateien, und **`bash -n` lief nie** — Lauf 1 war zugleich der erste
Syntaxtest. Auch die hier dokumentierte Korrekturrunde durfte nur `sha256sum`
ausfuehren; `bash -n` wurde erneut abgelehnt.

### Voraussetzung: PostgreSQL 16

`cases/setup_grant_backup_via_hilfsrolle.sql` benutzt
`GRANT <rolle> TO anon WITH INHERIT TRUE` — die per-Mitgliedschaft steuerbare
Vererbung gibt es erst ab PostgreSQL 16. Auf aelteren Servern schlaegt der
Schritt mit einem Syntaxfehler fehl und `case_d4` ist nicht bewertbar.

### Erneut lokal ausfuehren

```bash
cd apps/web
chmod +x supabase/production_n4_content_fix/test/run_local_postgres_test.sh
./supabase/production_n4_content_fix/test/run_local_postgres_test.sh
```

Exit 0 = alle Erwartungen erfuellt. Exit 1 = mindestens eine Abweichung.
Exit 2 = Umgebungsproblem (Binaries, `initdb`, Serverstart, `createdb`).

Der Pfad zu den PostgreSQL-16-Binaries ist ueber `CBB_PG_BIN` ueberschreibbar —
identisch zum Value-Add-Harness. Akzeptiert werden beide Formen: ein Prefix, das
ein `bin/` enthaelt, oder direkt das bin-Verzeichnis. Ohne die Variable loest der
Harness selbst auf: `pg_config --bindir`, sonst das Verzeichnis von `initdb` im
`PATH`, sonst `/usr/lib/postgresql/16/bin`, falls vorhanden. Findet er nichts,
bricht er mit Exit `2` und einem konkreten `CBB_PG_BIN`-Beispiel ab.

```bash
CBB_PG_BIN=/pfad/zu/postgresql/16 ./run_local_postgres_test.sh
CBB_PG_BIN=/pfad/zu/postgresql/16/bin ./run_local_postgres_test.sh
CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh   # Datenverzeichnis behalten
```

---

## Was der Harness anfasst — und was nicht

* Er startet einen **eigenen** Cluster in einem `mktemp`-Verzeichnis,
  ausschliesslich ueber Unix-Socket erreichbar (`listen_addresses=''`), und
  stoppt ihn per `trap` am Ende — auch bei Abbruch.
* Er fasst **keine** Production- und **keine** Pilot-Datenbank an.
* Er veraendert **keine** Datei in `production_value_add/` und keine der
  Originaldateien `01` bis `06` dieses Pakets. Alle sechs werden unveraendert
  ausgefuehrt.

## Ausgangszustand der Vorlage-Datenbank

`cbb_fixture` bildet den bereits erfolgreich getesteten
Value-Add-Production-Zustand nach und entsteht aus:

| Quelle | Rolle |
|--------|-------|
| `production_value_add/test/fixture/00_roles.sql` | Supabase-aehnliche Rollen |
| `production_value_add/test/fixture/01_schema.sql` | Schema vor der Value-Add-Migration |
| `production_value_add/test/fixture/02_seed.sql` | 376 Produkte |
| `supabase/seo_updated_at_trigger.sql` | der **echte** Trigger, nicht ein Nachbau |
| `production_value_add/test/fixture/03_assert_fixture.sql` | Fixture-Gegenprobe |
| `production_value_add/test/fixture/04_baseline.sql` | Value-Add-Baseline |
| `production_value_add/02_migrate_value_add.sql` | **Originaldatei** |
| `production_value_add/03_backup_value_add.sql` | **Originaldatei** |
| `production_value_add/04_backfill_value_add.sql` | **Originaldatei** |
| `production_value_add/test/cases/assert_after_04.sql` | Gegenprobe des Value-Add-Zustands |
| `cases/setup_n4_production_pre_values.sql` | N4-`tagline`/`description` exakt auf Production-Stand |
| `cases/assert_base_state.sql` | Gegenprobe des Ausgangszustands |
| `cases/baseline_n4.sql` | unveraenderliche Kopie aller 376 Zeilen |

Die Fixture selbst traegt fuer N4 erfundene Testtexte. Erst
`setup_n4_production_pre_values.sql` setzt `tagline` und `description` auf die
Werte aus `import_products_batch13.sql` bzw. `expand_descriptions_batch6.sql`.
Die fuenf Value-Add-/Editorial-Felder stammen unveraendert aus dem Original
`production_value_add/04_backfill_value_add.sql`.

## Schaerfe der Erwartungen

* Ein erwarteter Abbruch gilt **nur** dann als PASS, wenn `psql` mit **Exit 3**
  zurueckkommt **und** die konkrete erwartete Servermeldung im Output steht.
  Ein anderer Fehler ist FAIL, kein PASS. Ein fehlendes Erwartungsliteral im
  Harness ist selbst ein FAIL.
* `report_table` verlangt **exakte** PASS-Zahlen bei 0 FAIL-Zeilen:
  `01` → 18, `03` → 10, `05` → 18. "Mehr als 0 PASS" reicht nicht — eine
  geschrumpfte Pruefliste faellt so auf.
* `report_table_expect_fail` verlangt die Umkehrung: der Bericht muss laufen
  **und** fuer eine benannte Pruefung eine FAIL-Zeile liefern.
* Der Lock-Test verlangt Exit 3, die Meldung
  `canceling statement due to lock timeout` **und** eine Laufzeit von 3–15 s
  (bei `lock_timeout = '5s'`). Exit 124 (Client-Timeout), ein anderer Text oder
  ein Erfolg sind FAIL. Es gibt kein "Befund"-Ergebnis, das trotzdem
  Gesamt-PASS ergibt.
* Die beiden Nebenlaeufigkeitstests (`case_g`, `case_h`) sind **echt**, nicht
  simuliert. Eine zweite Session haelt einen Row-Lock und aendert ein Feld; der
  Paketlauf wird **nachweislich** beim Warten auf diesen Lock beobachtet
  (`pg_stat_activity.wait_event_type = 'Lock'`, Beleg im Log
  `*.wartepunkt.log`); **erst dann** commitet die Konkurrenz. PASS nur bei
  Exit 3 mit der Recheck-Meldung. FAIL bei:
  * Exit 0 — die Datei haette fremde Daten ueberschrieben,
  * `canceling statement due to lock timeout` — zu spaet commitet, der Recheck
    nach dem Lock ist damit nicht bewiesen,
  * fehlendem Wartepunkt-Nachweis — die Datei ist nie in den Lock gelaufen.

## Faelle

| Fall | Inhalt |
|------|--------|
| `case_0_statisch` | `SET LOCAL`-Position in `02`/`04`/`06`; `01`/`03`/`05` enthalten kein schreibendes Statement und beginnen mit `WITH`; jeder im Lauf gesetzte `application_name` bleibt unter 63 Byte |
| `case_a_happy_path` | `01` → `02` → `03` → `04` → `05` in Reihenfolge, danach `assert_after_04`; `01` muss nach der Korrektur FAIL melden |
| `case_b_wiederholungen` | `03`/`05` vor `02`; `04`/`06` ohne Backup; `02` doppelt; `04` doppelt |
| `case_c_falscher_vorwert` | `products` weicht vor `02` ab → `02` bricht ab, kein Backup entsteht |
| `case_c2_drift_nach_backup` | `products` driftet zwischen `02` und `04` → `04` bricht ab |
| `case_d_backup_manipuliert` | Backup-Inhalt veraendert → `04` bricht ab |
| `case_d2_backup_leer` | Backup-Tabelle leer → `04` und `06` brechen ab |
| `case_d3_backup_offen` | `GRANT SELECT … TO anon` → `04` **und** `06` brechen ab, `03` meldet FAIL |
| `case_d4_rechte_geerbt` | Recht liegt bei einer **Hilfsrolle**, `anon` ist nur Mitglied → in den direkten ACLs unsichtbar, `06` bricht ueber die **effektive** Rechtepruefung ab; danach Teardown der clusterweiten Rolle |
| `case_d5_manipuliertes_backup_restore` | `02` → `04` → Backup manipulieren → `06` bricht ab, `products` bleibt exakt im `04`-Stand |
| `case_e_restore` | `02` → `04` → `06` → `06` → `04`, jeweils mit Round-Trip-Beweis |
| `case_g_konkurrenz_02` | zweite Session aendert `pros`, waehrend `02` auf den Row-Lock wartet → `02` bricht nach dem Lock ab, **kein** Backup entsteht, die fremde Aenderung bleibt stehen |
| `case_h_konkurrenz_04` | zweite Session aendert `nicht_fuer`, waehrend `04` auf den Row-Lock wartet → `04` bricht nach dem Lock ab und ueberschreibt die fremde Aenderung **nicht** |
| `case_f_lock_timeout` | `AccessExclusiveLock` auf `public.products` blockiert `02` → echter ~5-s-Lock-Timeout |

### Warum gerade `pros` und `nicht_fuer`

Beide Spalten stehen **nicht** in der Spaltenliste des Triggers
`products_set_updated_at`. Eine konkurrierende Aenderung an ihnen laesst
`updated_at` unveraendert; ein reiner Zeitstempelvergleich reicht deshalb
nicht. In `case_g` muss `02` die geaenderten `pros` durch die erneute,
vollstaendige Pruefung des bekannten Vorzustands nach dem Lock erkennen. In
`case_h` muss `04` die geaenderte Spalte `nicht_fuer` durch den erneuten,
vollstaendigen Driftvergleich gegen das Backup nach dem Lock erkennen. Der
Test belegt jeweils gerade diesen zweiten Check nach erworbener Sperre.

### Wie die Konkurrenz gesteuert wird

Die zweite Session wird ueber eine **FIFO** gefuettert, nicht ueber eine
temporaere SQL-Datei mit festem `pg_sleep`. Der Leser (`psql -f fifo`) startet
zuerst; erst danach oeffnet der Parent mit `exec 8>fifo` ein reines
Schreibende. So erbt das Kind keinen eigenen Writer und erhaelt nach dem
Schliessen im Parent sicher EOF. Nur so liegt der COMMIT-Zeitpunkt exakt
zwischen "Paketlauf wartet nachweislich" und "Paketlauf bekommt den Lock".
Ein festes `pg_sleep` waere Zeitraten, kein Beweis — und wuerde je nach
Maschine mal den Lock-Timeout und mal den Recheck messen.

Zwei Regeln haengen daran und stehen auch so im Skript:

* **Jeder** spaeter gestartete Hintergrundprozess — auch der Ziellauf — startet
  mit `8>&-`. Ein einziger geerbter Writer genuegt, um das EOF zu verhindern.
* `exec 8>fifo` blockiert, bis ein Leser die FIFO geoeffnet hat, und `psql`
  oeffnet die `-f`-Datei erst **nach** erfolgreichem Verbindungsaufbau. Stirbt
  es vorher, gaebe es nie einen Leser. Dafuer gibt es einen Wachhund, der die
  Leseseite notfalls selbst kurz oeffnet und den Parent freigibt; der meldet
  den toten Leser dann als FAIL, statt zu haengen. Ein begrenzter Reaper um das
  abschliessende `wait` ist die zweite Notbremse.

Das Warten auf den Wartepunkt laeuft **serverseitig** in einer einzigen
Verbindung (`do $$ … perform pg_sleep(0.05) … $$`). Ein Polling aus der Shell
heraus waere zu langsam: jede `psql`-Runde kostet Verbindungsaufbau, und
parallel laeuft der `lock_timeout = '5s'` des Ziellaufs.

### `application_name` und die 63-Byte-Grenze

Der Wartepunkt wird ueber `pg_stat_activity.application_name` **exakt** gesucht.
PostgreSQL kuerzt diesen Wert aber hart auf `NAMEDATALEN-1` = 63 Byte — in
Lauf 1 war der Name genau deshalb abgeschnitten und die Suche unzuverlaessig.
Der Praefix ist jetzt kurz und deterministisch:

| Wert | Aufbau | Laenge |
|------|--------|--------|
| `LOCK_APP` | `cbb_n4_` + 8-stelliges `mktemp`-Suffix | 15 |
| Halter-Session | `${LOCK_APP}_hold_g_02_unter_konkurrenz` | 42 |
| Ziel-Session | `${LOCK_APP}_ziel_h_04_unter_konkurrenz` | 42 |

Die Labels der beiden Konkurrenzfaelle stehen dafuer zentral als `LABEL_G` /
`LABEL_H` im Skript. Der statische Schritt `static_appname_laenge` (Teil von
`case_0_statisch`) rechnet die Laengen vor dem Clusterstart nach und laesst den
Lauf abbrechen, wenn ein Name die Grenze reisst; `konkurrenz_lauf` prueft
zusaetzlich jeden Namen direkt vor der Benutzung. Alle Bestandteile sind ASCII,
Zeichen- und Bytelaenge sind damit identisch.

## Was der Harness beweisen soll

1. **Positiver Pfad** — `01`/`03`/`05` melden exakt 18/10/18 PASS und 0 FAIL,
   `02` und `04` laufen durch.
2. **375 Nichtzielzeilen ohne Drift** — `cases/assert_after_04.sql` vergleicht
   alle 376 Zeilen gegen `cbb_test_n4_baseline.products_before`. Genau eine
   Zeile darf abweichen; die anderen 375 muessen Bit fuer Bit identisch sein,
   `updated_at` eingeschlossen.
3. **`updated_at`-Verhalten** — nach `04` ist `updated_at` der N4-Zeile
   **neuer** als vorher, alle anderen unveraendert. Nach `06` ist es **exakt**
   der historische Wert.
4. **Exakter Restore** — `cases/assert_after_06.sql` verlangt 376 von 376
   Zeilen identisch zur Baseline und dass kein Rest des Zieltexts uebrig ist.
5. **Echte Fail-closed-Faelle** — falscher Vorwert (vor `02` und zwischen `02`
   und `04`), bestehendes Backup, manipuliertes Backup, leeres Backup, fuer
   `anon` geoeffnetes Backup, nur ueber eine Rollenmitgliedschaft geerbtes
   Recht, fehlendes Backup, falsche Reihenfolge — jeweils mit exakter
   Servermeldung und Exit 3.
6. **Lock-Timeout** — `02` bricht unter einem konkurrierenden
   `AccessExclusiveLock` nach rund 5 s mit der erwarteten Servermeldung ab,
   hinterlaesst kein Backup-Artefakt, und laeuft nach Freigabe der Sperre
   normal durch.
7. **Kein Verlust fremder Aenderungen** — `02` und `04` warten nachweislich auf
   den Row-Lock, sehen nach dem Lock den neuen Stand und brechen ab. Die
   konkurrierende Aenderung steht danach unveraendert in `products`; `02`
   hinterlaesst kein Backup, `04` keinen Zieltext.
8. **Kein Restore aus manipuliertem Backup** — `06` prueft den Backup-Inhalt
   gegen den bekannten Vorzustand und schreibt fremden Text nicht nach
   `public.products`. `products` bleibt exakt im `04`-Stand, die Manipulation
   bleibt im Backup stehen und wird auch nicht "repariert".

## Statisch belegt

Ohne laufende Datenbank wurde geprueft — in den Korrekturrunden durch Lesen der
Dateien, weil `awk`, `grep` und `bash -n` nicht gestartet werden durften:

* `begin;` kommt in `02`, `04` und `06` genau einmal am Zeilenanfang vor
  (Z25 / Z34 / Z45).
* `set local lock_timeout = '5s';` und `set local statement_timeout = '60s';`
  stehen jeweils direkt aufeinanderfolgend und nur einmal (Z31+32 / Z40+41 /
  Z51+52), zwischen `begin;` und ihnen stehen nur Kommentarzeilen.
* Der erste `do $$`-Block folgt erst danach (Z42 / Z46 / Z57).
* `01`, `03` und `05` sind unveraendert geblieben und enthalten weiterhin
  **kein** schreibendes Statement.
* Der laengste zusammengesetzte `application_name` ist 42 Zeichen lang und
  bleibt damit unter der 63-Byte-Grenze (Rechnung siehe oben).

Diese Pruefungen decken `case_0_statisch` ab; im Lauf rechnet der Harness sie
selbst nach. Alles Uebrige braucht den Cluster.

**Nicht statisch belegt:** die FIFO-Korrektur in `konkurrenz_lauf` selbst. Sie
ist eine Laufzeit-Eigenschaft (fd-Vererbung und EOF) und laesst sich nur durch
einen echten Lauf von `case_g` und `case_h` nachweisen. Die Korrekturrunde
durfte auch `bash -n` nicht ausfuehren — nur `sha256sum` war erlaubt.

## Neue Dateien dieser Korrekturrunde

| Datei | Rolle |
|-------|-------|
| `cases/assert_konkurrenz_pros.sql` | nach `case_g`: fremde `pros`-Aenderung steht noch, kein Backup, kein Zieltext |
| `cases/assert_konkurrenz_nicht_fuer.sql` | nach `case_h`: fremde `nicht_fuer`-Aenderung steht noch, kein Zieltext, Backup intakt |
| `cases/setup_grant_backup_via_hilfsrolle.sql` | Hilfsrolle mit Tabellen-GRANT + Mitgliedschaft `anon` (`WITH INHERIT TRUE`); weist selbst nach, dass `anon` 0 direkte, aber effektive Rechte hat |
| `cases/teardown_hilfsrolle.sql` | entfernt Mitgliedschaft und Rolle wieder — Rollen sind clusterweit |
| `cases/assert_products_ziel_unveraendert.sql` | nach `case_d5`: `products` exakt im `04`-Stand, Manipulation nur im Backup |
