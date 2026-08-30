# Lokaler PostgreSQL-Harness — Quality-Fixes 2026-08-30

## Status

**`145/145 PASS, 0 Abweichungen, Exit 0`.**

Codex hat den erweiterten Stand am 2026-08-30 gegen PostgreSQL **16.15**
vollstaendig ausgefuehrt. Ergebnisdatei:
`/tmp/cbb-qftest.AgI5UJsx/results.tsv`; Einzelprotokolle:
`/tmp/cbb-qftest.AgI5UJsx/logs/`. Der Cluster wurde danach sauber gestoppt,
PGDATA und Socketverzeichnis wurden entfernt. Die dauerhafte Zusammenfassung
steht in [`../LOCAL_TEST_REPORT.md`](../LOCAL_TEST_REPORT.md).

Was sich geaendert hat:

* **Siebtes Zielprodukt** `plasmakugel-8-zoll-beruehrungsempfindlich` (A4,
  Kategorie). Die Zielzeilenzaehler sind von `6` auf `7` gestiegen. Die
  lastmod-Zaehler bleiben bewusst bei `6`: A4 aendert nur eine nicht
  gerenderte Unterkategorie und behaelt sein historisches `updated_at`.
* **Zwei neue Diagnosezeilen in `01`** (`a4_kategorie_vorzustand_basteln`,
  `lastmod_zielprodukte_updated_at_nicht_null`) und **eine in `05`**
  (`a4_kategorie_zielzustand_gadgets`). Die exakten PASS-Erwartungen sind
  deshalb jetzt **01 → 22**, **03 → 16**, **05 → 23**.
* **Vier neue Faelle** in sechs neuen Case-Dateien: `case_i_rolle_fehlt`,
  `case_j_updated_at_null`, `case_j2_updated_at_null_vor_04`,
  `case_j3_updated_at_null_vor_06`.
* **`fixture/02_seed.sql`:** die Plasmakugel traegt jetzt den read-only
  belegten Production-Vorzustand `babo / tech / basteln` samt `shop_tags`
  (vorher `babo / diy / basteln` ohne Tags). Damit sieben Zielprodukte sieben
  **verschiedene** historische `updated_at` tragen, wurde ausserdem der reine
  Testwert von `fingerabdruck-vorhaengeschloss-eseesmart` von `2026-07-04` auf
  `2026-07-03` gezogen. `bug-a-salt-…` ist kein Zielprodukt und bleibt bei
  `2026-07-04`; es hat lediglich `shop_tags` bekommen, weil beide A4-Produkte in
  derselben `INSERT`-Spaltenliste stehen.

Fruehere Laufhistorie (gilt fuer den Stand **vor** dieser Erweiterung):

1. Der erste Vollauf fand drei Abweichungen im Fall `case_d5_rechte_geerbt`:
   Das Test-Setup erzeugte wegen `NOINHERIT` kein wirksames geerbtes Recht.
   Korrigiert wurden nur Fixture, Teardown und Testdokumentation; die sechs
   Produktivdateien blieben dabei unveraendert.
2. Der Wiederholungslauf bestand mit **118/118 PASS**.
3. Das unabhaengige Codex-Audit haertete danach `02` zusaetzlich gegen geerbte
   effektive Tabellen- und Schemarechte. `case_d5` wurde um den entsprechenden
   Wiederholungslauf von `02` erweitert. Dieser Lauf bestand mit
   **119/119 PASS**, 0 Abweichungen, Exit 0.

Ergebnisdatei dieses historischen Laufs:
`/tmp/cbb-qftest.qWvTWbdG/results.tsv`; Einzelprotokolle:
`/tmp/cbb-qftest.qWvTWbdG/logs/`. Der lokale Cluster wurde danach sauber
gestoppt; PGDATA und Socketverzeichnis wurden entfernt.

**Diese 119/119 sind kein Nachweis fuer den heutigen Paketstand.** Der
verbindliche Nachweis ist der oben dokumentierte definitive 145er-Vollauf.

## Was er testet

Die sechs Originaldateien aus dem Elternverzeichnis:

```
01_preflight_read_only.sql
02_backup_quality_fixes.sql
03_verify_backup_read_only.sql
04_apply_quality_fixes.sql
05_verify_read_only.sql
06_restore_quality_fixes.sql
```

Der Harness kopiert, patcht oder generiert **keine** SQL des Pakets. Er fuehrt
genau die Dateien aus, die spaeter auf Production laufen wuerden. Zusaetzlich
laedt er den **echten** Trigger `../../seo_updated_at_trigger.sql` in die
Fixture — nicht eine Nachbildung.

## Was er nicht anfasst

Der Harness kennt weder Host noch Projekt-Ref von `ydiihvzcxaaoqhmgoqvu`
(Production) oder `nmzuycveumyfvtxdcnuc` (Pilot). Es gibt keine
Verbindungszeichenkette, kein `PGHOST` ausserhalb des eigenen Sockets, keinen
Netzwerkzugriff.

Er startet einen eigenen PostgreSQL-Cluster in einem `mktemp`-Verzeichnis:

* `initdb` mit `--auth=trust`, Encoding UTF8, Locale `C.UTF-8`,
* Start mit `-k <sockdir> -c listen_addresses=''` — **nur Unix-Socket, kein
  TCP-Port**,
* Stopp per `trap` am Ende (`pg_ctl stop -m fast`), `PGDATA` und
  Socketverzeichnis werden entfernt. Mit `CBB_KEEP_CLUSTER=1` bleibt das
  Datenverzeichnis zur Nachschau stehen.

## Aufruf

```bash
bash run_local_postgres_test.sh
CBB_KEEP_CLUSTER=1 bash run_local_postgres_test.sh
CBB_PG_BIN=/usr/lib/postgresql/16     bash run_local_postgres_test.sh
CBB_PG_BIN=/usr/lib/postgresql/16/bin bash run_local_postgres_test.sh
```

Die Datei wurde ohne Ausfuehrungsbit angelegt. Entweder wie oben ueber `bash`
aufrufen oder einmalig `chmod +x run_local_postgres_test.sh` setzen.

`CBB_PG_BIN` verhaelt sich wie in den bestehenden Harnesses
(`production_value_add/`, `production_n4_content_fix/`): erlaubt ist ein
PostgreSQL-Prefix, das ein `bin/` enthaelt, **oder** direkt das
`bin`-Verzeichnis. Ohne den Override loest der Harness die Binaries selbst auf
(`pg_config`, dann `initdb` im `PATH`, dann `/usr/lib/postgresql/16/bin`, falls
vorhanden). Es gibt bewusst keinen fest verdrahteten `/tmp`-Default — ein
solcher Pfad ist nach einem Reboot tot.

Exit-Codes: `0` alle Erwartungen erfuellt, `1` mindestens eine Abweichung,
`2` Umgebungsproblem (Binaries, `initdb`, Serverstart, `createdb`).

## Ausgangszustand

Die Vorlage-Datenbank `cbb_fixture` bildet den Production-Vorzustand vom
2026-08-30 nach:

| Datei | Inhalt |
|---|---|
| `fixture/00_roles.sql` | `anon`, `authenticated`, `service_role` (letztere mit `BYPASSRLS`) — ohne sie scheitern die `REVOKE`-Statements in `02`, und die Rechte-Guards in `02`/`04`/`06` brechen an ihrer harten Rollen-Vorbedingung ab |
| `fixture/01_schema.sql` | Production-aehnliches Schema inklusive der Spaltendefaults `unknown / sonstiges / ungeordnet`, die den B2-Vorzustand ueberhaupt erklaeren; `products` mit RLS und zwei Policies; App-Rollen mit vollen Rechten auf `public` |
| `fixture/02_seed.sql` | sieben Zielprodukte im belegten Vorzustand, drei Ziellisten mit den exakten Arrays, beide A4-Zielprodukte (eines davon ist zugleich das siebte Zielprodukt), 320 Fuellzeilen (> 300er-Grenze), zwei Nichtziel-Listen |
| `../../seo_updated_at_trigger.sql` | der echte Trigger, unveraendert |
| `fixture/03_baseline.sql` | `md5(to_jsonb(zeile))` jeder Produkt- und Listenzeile im Hilfsschema `cbb_test` |
| `cases/assert_base_state.sql` | Gegenprobe: der Vorzustand stimmt wirklich |

Echt sind ausschliesslich die Werte, auf die die Guards pruefen: die
Vorzustandsfelder der sieben Zielprodukte, die drei Listen-Arrays und die Slugs.
Fuer die siebte Zielzeile sind das `babo / tech / basteln`,
`shop_tags = ['babo:tech','preis:unter50','preis:unter100']`, `is_published` und
`updated_at = 2026-07-04T00:00:00+00` — read-only auf Production verifiziert.
Alle uebrigen Texte sind Testdaten und werden nie nach Production geschrieben.

Jede der sieben Zielzeilen traegt ein **eigenes** historisches `updated_at`.
Damit muss `06` die sechs von `04` geaenderten Zeitstempel beweisbar einzeln
zurueckspielen und kann sich nicht auf einen Einheitswert stuetzen. Fuer die
Plasmakugel beweist der Harness stattdessen, dass `updated_at` sowohl nach
`04` als auch nach `06` unveraendert bleibt. Weil sie den echten
Production-Wert `2026-07-04` behaelt, traegt die reine Testdaten-Zeile
`fingerabdruck-…` bewusst `2026-07-03`.

Keine Zielzeile der Fixture traegt `updated_at IS NULL` —
`cases/assert_base_state.sql` weist das ausdruecklich nach. Sonst waere der
Ausgangszustand nicht vom Negativfall der `updated_at`-Guards zu unterscheiden.

Jeder Fall bekommt eine eigene Datenbank per `createdb -T cbb_fixture`. Faelle
beeinflussen sich also nicht — mit einer Ausnahme: **Rollen und Rollenattribute
sind cluster-weit**. Deshalb haben zwei Faelle ein eigenes Teardown:
`case_d5` entfernt die Hilfsrolle und stellt `anon` wieder auf `NOINHERIT`,
`case_i` benennt `authenticated` zurueck (siehe unten).

## Schaerfe der Erwartungen

* Ein erwarteter Abbruch gilt **nur** dann als PASS, wenn `psql` mit **Exit 3**
  zurueckkommt **und** die konkrete erwartete Servermeldung im Output steht.
  „Irgendein Exit ungleich 0“ reicht nie. Ein anderer Fehler als der erwartete
  ist FAIL, nicht PASS.
* `report_table` verlangt **exakte** PASS-Zahlen — `01` → 22, `03` → 16,
  `05` → 23 — bei 0 FAIL-Zeilen. Eine stillschweigend geschrumpfte Pruefliste
  faellt damit auf, statt als PASS durchzugehen.
* `report_table_expect_fail` verlangt umgekehrt eine **namentlich** benannte
  FAIL-Zeile.
* Der Lock-Test verlangt Exit 3, die Meldung
  `canceling statement due to lock timeout` **und** eine Laufzeit zwischen 3 und
  15 Sekunden. Exit 124 (Client-Timeout) ist FAIL, nicht PASS.
* Die beiden Konkurrenztests sind **echt**: eine zweite Session haelt den
  Row-Lock und aendert ein Feld; dass der Paketlauf wirklich am Lock wartet,
  wird ueber `pg_stat_activity.wait_event_type = 'Lock'` belegt und
  protokolliert. Erst danach commitet die Konkurrenz. Ohne diesen Nachweis ist
  der Fall FAIL. Ein Durchlauf (Exit 0) bedeutet, dass fremde Daten
  ueberschrieben wurden — ebenfalls FAIL.

## Statische Pruefungen (Fall 0, ohne Cluster)

Schlaegt hier etwas fehl, bricht der Lauf sofort ab — ein Lock-Test waere dann
nicht aussagekraeftig.

| Pruefung | Gegenstand |
|---|---|
| `static_appname_laenge` | kein im Lauf gesetzter `application_name` reisst die Grenze `NAMEDATALEN-1 = 63` Byte. Ein serverseitig gekuerzter Name macht die exakte Wartepunkt-Suche in `pg_stat_activity` unbrauchbar |
| `static_setlocal_*` | in `02`, `04`, `06`: genau ein `begin;`, genau zwei `SET LOCAL`, direkt hinter `begin;` (nur Kommentare dazwischen) und **vor** dem ersten `DO`-Block |
| `static_readonly_*` | `01`, `03`, `05`: erste Anweisung ist ein `WITH`, und keine Zeile beginnt mit einem schreibenden Schluesselwort |
| `static_kein_drop_*` | **keine** der sechs Dateien enthaelt `DROP`, `DELETE` oder `TRUNCATE`. Erlaubt und herausgeschnitten wird nur `on commit drop` — die Lebensdauer einer `TEMPORARY`-Tabelle, die keine Nutzdaten anfasst |

## Faelle

| Fall | Was er belegt |
|---|---|
| `case_a_happy_path` | `01` → `02` → `03` → `04` → `05` in Reihenfolge, alle Zaehler exakt. Danach: `02` ein zweites Mal (No-Op bei identischem Snapshot), `04` ein zweites Mal (No-Op **ohne neues `updated_at`**, gegen einen Fingerabdruck-Snapshot geprueft), und `01` meldet nach der Korrektur nachweislich FAIL statt still PASS |
| `case_b_reihenfolge` | `03` und `05` scheitern ohne Backup bereits an der Planung; `04` und `06` brechen mit `privates Backup fehlt` ab; danach existiert keine Backup-Tabelle und der Vorzustand ist unveraendert |
| `case_c_falscher_vorwert` | ein abweichender Vorwert **vor** `02` → `02` bricht ab, kein Backup entsteht, nichts sickert durch. Verstellt wird `shop_tags` — eine Spalte **ausserhalb** der Triggerliste, `updated_at` bleibt also gleich. Ein reiner Zeitstempelvergleich haette die Aenderung nicht gefunden |
| `case_c2_drift_nach_backup` | derselbe Drift **zwischen** `02` und `04` → `04` bricht mit `gemischter oder gedrifteter Zustand` ab |
| `case_c3_fremdspalte` | `tagline` driftet — eine Spalte, die das Paket gar nicht anfasst und die keine Vorzustandspruefung abdeckt. `04` muss trotzdem abbrechen, weil der vollstaendige `to_jsonb`-Vergleich gegen das Backup zusaetzlich laeuft |
| `case_c4_gemischt` | eine Zeile steht bereits im Zielzustand, neun nicht → `04` bricht ab. Danach weicht **genau eine** Zeile von der Baseline ab: die vom Setup gesetzte |
| `case_c5_fehlende_zeile` | eine Zielzeile ist geloescht → `02` bricht ab (6/7), `04` findet kein Backup |
| `case_d_backup_manipuliert` | veraenderter Backup-Inhalt → `04`, `06` **und** ein Wiederholungslauf von `02` brechen ab |
| `case_d2_backup_leer` | Tabelle existiert, Inhalt weg → `04`, `06` und `02` brechen mit der exakten Zeilenzahl `0/7` ab. Eine Datei, die nur auf Existenz prueft, waere hier durchgelaufen |
| `case_d3_halbes_backup` | nur eine der beiden Backup-Tabellen existiert → `02` ergaenzt sie **nicht** stillschweigend, sondern bricht ab |
| `case_d4_backup_offen` | direkter `GRANT SELECT` an `anon` → `04` und `06` brechen mit `direkt 1, effektiv 1` ab; `03` meldet dieselbe Sache als FAIL-Zeile statt still PASS |
| `case_d5_rechte_geerbt` | **kein** direkter GRANT: das Recht liegt bei einer Hilfsrolle, `anon` ist Mitglied. In den direkten ACLs unsichtbar → `direkt 0, effektiv 1`. Belegt, dass die effektive Rechtepruefung nicht Zierde ist. `02` muss beim Wiederholungslauf ebenso abbrechen wie `04` und `06`; `03` meldet FAIL. Das Setup schaltet `anon` dafuer auf `INHERIT` (siehe unten) und weist beide Zaehler selbst nach; Teardown, weil Rollen cluster-weit sind |
| `case_d6_restore_manipuliert` | nach erfolgreichem `04` wird das Backup manipuliert → `06` schreibt den fremden Inhalt **nicht** nach `public.products` |
| `case_e_restore` | `02` → `04` → `06` mit **exaktem** Round-Trip: jede Zeile traegt wieder ihren Baseline-Fingerabdruck, `updated_at` eingeschlossen. Danach `06` erneut (No-Op) und `04` erneut (der Vorzustand ist wieder da, die Korrektur darf wieder laufen) |
| `case_g_konkurrenz_02` | echte zweite Session aendert `shop_tags`, waehrend `02` am Row-Lock wartet → `02` bricht nach dem Lock ab, die fremde Aenderung ueberlebt, kein Backup entsteht |
| `case_h_konkurrenz_04` | echte zweite Session aendert `product_slugs` einer Zielliste, waehrend `04` am Row-Lock wartet → `04` bricht nach dem Lock ab. `public.lists` hat **kein** `updated_at`; nur der Wertevergleich kann die Aenderung ueberhaupt finden |
| `case_f_lock_timeout` | ein `AccessExclusiveLock` auf `public.products` blockiert `02` → Abbruch nach rund 5 Sekunden mit `canceling statement due to lock timeout`. Danach wird der Halter per `pg_terminate_backend` ueber seinen `application_name` beendet, und `02` laeuft sauber durch |
| `case_i_rolle_fehlt` | `authenticated` ist nicht mehr unter ihrem Namen vorhanden → `02`, `04` und `06` brechen an ihrer harten Rollen-Vorbedingung ab, `03` meldet `app_rollen_vorhanden` als FAIL. Danach Teardown und ein erneuter `02`-Lauf als Beweis, dass der Cluster wieder sauber ist. Details unten |
| `case_j_updated_at_null` | eines der sechs lastmod-Zielprodukte hat `updated_at IS NULL`, **bevor** `02` laeuft → `02` bricht ab, es entsteht kein Snapshot, der als Rollback-Quelle wertlos waere |
| `case_j2_updated_at_null_vor_04` | bei einem lastmod-Zielprodukt ist `updated_at IS NULL` in Quelle **und** Backup → der vollstaendige `to_jsonb`-Vergleich findet nichts, weil beide Seiten denselben NULL-Wert tragen. Nur der eigene Guard faengt es; `04` bricht vor dem ersten UPDATE ab |
| `case_j3_updated_at_null_vor_06` | bei einem lastmod-Zielprodukt ist `updated_at IS NULL` zuerst **nur im Backup**, dann in Zielquelle und Backup. Der Fall belegt die Guards vor allen drei fruehen No-Op-Rueckgaben: `02` akzeptiert keinen wertlosen vorhandenen Snapshot, `04` keinen fachlichen Zielzustand ohne neues lastmod, `06` keine formal gleichen NULL-Zeitstempel |

### Warum `case_d5` `anon` kurzzeitig auf `INHERIT` stellt

`fixture/00_roles.sql` legt `anon` als **`NOINHERIT`** an — so ist es auch auf
Supabase. Eine `NOINHERIT`-Rolle bekommt ueber blosse Mitgliedschaft aber
**kein** effektives Recht: `has_table_privilege` folgt nur vererbenden
Mitgliedschaften. Ein Setup, das nur `GRANT hilfsrolle TO anon` macht, erzeugt
also gar keinen geerbten Rechtetreffer — der Fall waere ein stiller
Blindgaenger statt eines Negativtests.

Deshalb setzt `cases/setup_grant_backup_via_hilfsrolle.sql` `anon` fuer die
Dauer dieses einen Falls auf `INHERIT`. Drei Punkte dazu:

* **Reihenfolge ist Pflicht: `ALTER` vor `GRANT`.** Ab PostgreSQL 16 haelt jede
  Mitgliedschaft ihre eigene `INHERIT`-Option fest; deren Default wird beim
  `GRANT` aus `rolinherit` des Mitglieds uebernommen. Ein `GRANT` vor dem
  `ALTER` bliebe dauerhaft nicht-vererbend.
* **Der gepruefte Zustand ist kein Fantasiezustand.** `direkte ACL 0,
  effektiv 1` ist auch mit Supabase-Defaults erreichbar — ab PostgreSQL 16
  genuegt dafuer ein `GRANT <rolle> TO anon WITH INHERIT TRUE`, ohne `anon`
  anzufassen. Der `ALTER`-Weg steht hier nur deshalb, weil er auf jeder
  PostgreSQL-Version dasselbe bedeutet.
* **Der Schalter beruehrt die sechs Originaldateien nicht.** Die Rechte-Guards
  in `02`, `04` und `06` sehen lediglich einen
  Zustand, den es ohne den Schalter nicht gaebe. Das Setup weist selbst nach,
  dass danach **direkte ACL = 0** und **effektives Recht = 1** gilt — mit
  denselben Rollen und derselben Privilegienliste, die auch die Guards
  verwenden. Stimmt eine der beiden Zahlen nicht, bricht schon das Setup ab.

`cases/teardown_hilfsrolle.sql` stellt danach `NOINHERIT` wieder her und
prueft den Fixture-Ausgangszustand nach: Hilfsrolle weg, kein `SELECT` fuer
`anon`, `rolinherit = false`, **0** Rollenmitgliedschaften.

### Warum `case_i` die Rolle umbenennt statt sie zu loeschen

Alle Rechte-Zaehler in `02`, `04` und `06` laufen ueber
`pg_roles … where rolname in ('anon','authenticated','service_role')`. Fehlt
eine der beiden App-Rollen, faellt sie aus dem Join und der Zaehler meldet still
`0` — kein Beleg fuer „keine Rechte“, nur einer fuer „keine Rolle“. `04` und
`06` brachen dafuer schon vorher hart ab; `02` tut es seit dieser Erweiterung
ebenfalls, und zwar in Guard 1 vor jeder Verzweigung. Damit kann auch der
No-Op-Zweig von `02` keine Backup-Tabelle mehr als „sicher“ durchwinken, deren
Rechtelage gar nicht gemessen wurde.

`DROP ROLE authenticated` ist im Harness **nicht** moeglich: ACL-Eintraege
haengen an der Rollen-OID, und `anon`/`authenticated` haben in **jeder** bereits
angelegten Fall-Datenbank Rechte auf die `public`-Tabellen (so bildet
`fixture/01_schema.sql` den Supabase-Default nach). PostgreSQL verweigert den
DROP dann wegen genau dieser Abhaengigkeiten — auch wegen derer in anderen
Datenbanken desselben Clusters.

`ALTER ROLE … RENAME` loest das sauber: die ACLs bleiben unangetastet, weil sie
die OID referenzieren. Aus Sicht der Guards ist der **Name** `authenticated`
danach exakt so weg wie nach einem DROP. Die Rolle ist `NOLOGIN` und hat kein
Passwort, ein Rename kann hier also auch keine MD5-Passworthuelle entwerten.

`cases/teardown_rolle_authenticated.sql` benennt zurueck und weist danach nach:
die geparkte Rolle existiert nicht mehr, beide App-Rollen sind wieder da,
`authenticated` hat weiterhin `SELECT` auf `public.products` und `USAGE` auf
`schema public`, steht auf `NOINHERIT` — und hat **kein** Recht auf das private
Backup. Der abschliessende `02`-Lauf des Falls belegt zusaetzlich, dass der
Cluster fuer alle spaeteren Faelle wieder in seinem Ausgangszustand ist.

## Ergebnisdatei

Der Lauf schreibt eine TSV mit einer Zeile je Schritt
(`case`, `step`, `label`, `file`, `expect`, `exit`, `verdict`, `detail`) und
gibt sie am Ende als Tabelle aus. Alle `psql`-Ausgaben liegen einzeln im
Logverzeichnis unter dem `mktemp`-Pfad, der zu Beginn ausgegeben wird.
