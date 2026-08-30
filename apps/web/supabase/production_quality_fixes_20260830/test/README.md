# Lokaler PostgreSQL-Harness — Quality-Fixes 2026-08-30

## Status

> [!success] AKTUELLER STAND: **BESTANDEN**
> Der unabhaengige Vollauf bestand am 2026-08-30 gegen PostgreSQL **16.15**
> mit **166/166 PASS**, 0 Abweichungen, Records=166, STEP=166,
> Coverage-Assertion PASS und Exit 0. Ergebnisdatei:
> `/tmp/cbb-qftest.TBdYphBg/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.TBdYphBg/logs/`. Der Cluster wurde danach sauber gestoppt;
> PGDATA und Socketverzeichnis wurden entfernt.
>
> **Historie, gilt nicht fuer den aktuellen Stand:** der 164er-Lauf vom
> 2026-08-30 gegen PostgreSQL **16.15** (**164/164 PASS**, 0 Abweichungen,
> Records=164, STEP=164, Coverage-Assertion PASS, Exit 0) belegt den Stand von
> Commit `179ef1f`. Ergebnisdatei: `/tmp/cbb-qftest.v85MjgLU/results.tsv`;
> Einzelprotokolle: `/tmp/cbb-qftest.v85MjgLU/logs/`. Der Cluster wurde danach
> sauber gestoppt; PGDATA und Socketverzeichnis wurden entfernt.

### Was seit dem 164er-Stand (`179ef1f`) hinzugekommen ist

* **Keine undokumentierte PostgreSQL-15-Abhaengigkeit mehr.** Die beiden
  Zaehlungen im Triggervertrag liefen ueber `pg_catalog.regexp_count()`, das es
  erst ab PostgreSQL 15 gibt — eine Mindestversion, die das Paket nirgends
  belegt. Sie laufen jetzt read-only ueber `regexp_matches(..., 'g')` in einem
  `CROSS JOIN LATERAL`. Das ist seit Jahren vorhanden, funktioniert auf
  PostgreSQL 16.15 unveraendert und setzt keine neue Mindestversion voraus.
* **Positionsunabhaengige Zaehlung der `updated_at`-Zuweisungen.** Frueher
  zaehlte `01` nur Zuweisungen an bestimmten Statementpositionen (`begin`,
  `then`, nach `;`). Eine zweite, bedingungslose Zuweisung in einer `LOOP` fiel
  damit durch das Raster. Gezaehlt wird jetzt **jedes**
  `new.updated_at := / =` im kommentarbereinigten Rumpf; ein Vergleich
  `new.updated_at = …` zaehlt bewusst fail-closed mit.
* **Neuer Negativfall in `case_k_triggervertrag`** (+2 Schritte):
  `setup_trigger_zweite_zuweisung_in_schleife.sql` — korrekter Guard mit
  korrekter Zuweisung, danach eine zweite, bedingungslose
  `new.updated_at = now()` in einer `LOOP`. Geordnete Regex und
  `END IF`-Zaehlung passen weiterhin; nur die positionsunabhaengige Zaehlung
  sieht den zweiten Schreiber. `01` muss FAIL liefern. Die bestehenden Faelle
  bleiben unveraendert daneben stehen.
* **Reihenfolge der Kommentarbereinigung korrigiert.** Zeilenkommentare werden
  jetzt **vor** Blockkommentaren entfernt. Andernfalls koennte ein Rumpf mit
  `-- … /*` und spaeter `-- … */` echten Code zwischen zwei reinen
  Kommentarmarkern verstecken: der Blockausdruck wuerde alles dazwischen
  fressen. Der Negativfall `setup_trigger_bumpt_sub_category.sql` baut genau
  diese Falle nach — bei falscher Reihenfolge meldete `01` faelschlich PASS,
  bei richtiger meldet es weiterhin FAIL. Verschachtelte Blockkommentare
  bleiben bewusst fail-closed.
* **Minimaler gueltiger Guard wird akzeptiert.** Die geordnete Regex verlangte
  zwischen Guard und `THEN` faelschlich mindestens ein Zeichen und wies damit
  `if new.updated_at is not distinct from old.updated_at then
  new.updated_at := now(); end if;` ab. Das Trennzeichen vor `THEN` steht jetzt
  als eigene `[[:space:]]`-Klasse hinter dem `.*`. Die reale Funktion mit
  zusaetzlicher AND-Tupelbedingung bleibt PASS; die Reihenfolge
  Guard → `THEN` → Zuweisung → `END IF` bleibt unveraendert hart.
* Die Funktionsdefinition wird vor den semantischen Checks von **Block- und
  Zeilenkommentaren** bereinigt (in dieser Reihenfolge: erst Zeilen-, dann
  Blockkommentare). Guard, `THEN`, die einzige Zuweisung und `END IF` muessen
  geordnet zusammenpassen; `:=` und `=` werden gezaehlt.
* Die Coverage-Assertion vergleicht sowohl Records als auch `STEP` mit
  `ERWARTETE_SCHRITTE=166`.

### Was der 160er-Lauf seit dem 145er-Lauf abdeckte

* **Neue Pruefzeile in `01`:** `products_updated_at_triggervertrag`
  (Sortierung 156). Sie liest den **Systemkatalog** (`pg_trigger`, `pg_proc`,
  `pg_get_triggerdef`, `pg_get_functiondef`) und belegt den deployten
  `updated_at`-Vertrag auf `public.products`: genau ein aktiver
  `BEFORE UPDATE FOR EACH ROW` Trigger `products_set_updated_at` auf
  `public.products_touch_updated_at`, kein `shop_sub_category` im
  Funktionsrumpf, ein ausdruecklich gesetztes `NEW.updated_at` bleibt stehen,
  und keine andere aktive Triggerfunktion fasst `updated_at` an. Fehlt der
  Vertrag oder weicht er ab, meldet die Zeile FAIL — und `04` darf nicht
  laufen. Die exakte PASS-Erwartung fuer `01` steigt damit von **22 auf 23**.
* **Neuer Fall `case_k_triggervertrag`** (damals 9 Schritte): bricht den Vertrag
  dreimal unterschiedlich (Bump auf `shop_sub_category`, fehlender
  `updated_at`-Guard, Trigger entfernt) und verlangt jedes Mal die FAIL-Zeile.
  Zwei Kontrollschritte mit dem echten, unveraenderten Trigger davor und
  danach zeigen, dass die FAILs von der Manipulation kommen.
* **Neuer Fall `case_di_backup_identitaet`** (6 Schritte): der
  No-Op-Zweig von `02` prueft die Zeilenidentitaet jetzt ueber **`id` UND
  `slug`** — symmetrisch zum Neuanlage-Pfad und zu `04`/`06`. Der Fall
  manipuliert eine Backup-**id** bei unveraendertem Inhalt.
* **Coverage-Assertion am Ende des Harness:** die damalige Soll-Schrittzahl
  (`ERWARTETE_SCHRITTE` stand zu jenem Zeitpunkt auf 160, heute auf 166) wurde
  gegen die tatsaechlich nach `results.tsv` geschriebenen Records geprueft. Eine
  spaeter entfernte Teststufe kann damit nicht mehr als `GESAMT: PASS`
  durchgehen. Die Assertion legt selbst **keinen** Record an.

### Der vorherige Vollauf (`145/145`, Paketstand davor)

Codex hat diesen Stand am 2026-08-30 gegen PostgreSQL **16.15**
vollstaendig ausgefuehrt. Ergebnisdatei:
`/tmp/cbb-qftest.AgI5UJsx/results.tsv`; Einzelprotokolle:
`/tmp/cbb-qftest.AgI5UJsx/logs/`. Der Cluster wurde danach sauber gestoppt,
PGDATA und Socketverzeichnis wurden entfernt.

Was sich zu diesem Lauf geaendert hatte:

* **Siebtes Zielprodukt** `plasmakugel-8-zoll-beruehrungsempfindlich` (A4,
  Kategorie). Die Zielzeilenzaehler sind von `6` auf `7` gestiegen. Die
  lastmod-Zaehler bleiben bewusst bei `6`: A4 aendert nur eine nicht
  gerenderte Unterkategorie und behaelt sein historisches `updated_at`.
* **Zwei neue Diagnosezeilen in `01`** (`a4_kategorie_vorzustand_basteln`,
  `lastmod_zielprodukte_updated_at_nicht_null`) und **eine in `05`**
  (`a4_kategorie_zielzustand_gadgets`). Die exakten PASS-Erwartungen waren
  damit **01 → 22**, **03 → 16**, **05 → 23**; seit der Triggervertrags-Zeile
  gilt **01 → 23**.
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

**119/119, 145/145, 160/160 und 164/164 sind historische Nachweise frueherer
Paketstaende** — der 164er-Lauf belegt genau Commit `179ef1f`. Den aktuellen
Stand mit `ERWARTETE_SCHRITTE=166` belegt der bestandene 166er-Vollauf.

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
| `../../seo_updated_at_trigger.sql` | der echte Trigger, unveraendert. Er ist zugleich der Pruefgegenstand der neuen `01`-Zeile `products_updated_at_triggervertrag`: weil hier die Originaldatei geladen wird, prueft der lokale Test denselben Katalogvertrag, der spaeter auf Production stehen muss — keine Nachbildung |
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

Die Triggermanipulationen in `case_k_triggervertrag` sind reines DDL und damit
**datenbanklokal** — sie brauchen kein clusterweites Teardown. Der Fall stellt
den echten Trigger trotzdem am Ende wieder her, weil der Kontrollschritt danach
sonst nichts belegen wuerde.

## Schaerfe der Erwartungen

* Ein erwarteter Abbruch gilt **nur** dann als PASS, wenn `psql` mit **Exit 3**
  zurueckkommt **und** die konkrete erwartete Servermeldung im Output steht.
  „Irgendein Exit ungleich 0“ reicht nie. Ein anderer Fehler als der erwartete
  ist FAIL, nicht PASS.
* `report_table` verlangt **exakte** PASS-Zahlen — `01` → 23, `03` → 16,
  `05` → 23 — bei 0 FAIL-Zeilen. Eine stillschweigend geschrumpfte Pruefliste
  faellt damit auf, statt als PASS durchzugehen.
* Am Ende steht eine **Coverage-Assertion** auf die Soll-Schrittzahl
  `ERWARTETE_SCHRITTE=166`. Sie prueft die bereits nach `results.tsv`
  geschriebenen Records (ohne Kopfzeile) **und** den `STEP`-Zaehler und legt
  selbst keinen Record an. `FAILURES=0` belegt nur, dass die ausgefuehrten
  Stufen bestanden haben — nicht, dass alle Stufen ausgefuehrt wurden. Faellt
  eine Stufe weg, endet der Lauf mit `GESAMT: FAIL`.
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
| `case_k_triggervertrag` | positiver Kommentarfall: `shop_sub_category` nur im Rumpfkommentar bleibt bei 23 PASS. Danach wird der deployte Vertrag **fuenfmal** gebrochen — Bump auf `shop_sub_category` (hinter `-- … /*` und `-- … */` versteckt, also zugleich die Gegenprobe auf die Reihenfolge der Kommentarbereinigung), fehlender Guard, Dummy-Guard mit bedingungsloser `=`-Zuweisung, korrekter Guard **plus zweiter bedingungsloser Zuweisung in einer `LOOP`**, Trigger entfernt. `01` muss jedes Mal `products_updated_at_triggervertrag` als FAIL melden; der echte Trigger am Ende wieder 23 PASS. Geprueft wird der von **Block- und Zeilenkommentaren** bereinigte Systemkatalogtext |
| `case_d_backup_manipuliert` | veraenderter Backup-Inhalt → `04`, `06` **und** ein Wiederholungslauf von `02` brechen ab |
| `case_di_backup_identitaet` | der Backup-**Inhalt** ist korrekt, nur eine Zeilen-**id** ist fremd. `06` schreibt ueber die `id` zurueck, `04` sperrt Zeilenpaare ueber `id` UND `slug` — ein reiner Inhaltsvergleich je `slug` sieht davon nichts. Der No-Op-Zweig von `02` haette den Snapshot frueher durchgewunken; jetzt bricht er mit `Identitaet ueber id und slug: 6/7` ab, `04` mit `6/7 Produkt-Zeilenpaare`, `06` mit `Produkt-Backup passt zu 6/7`. Ergaenzt `case_d_backup_manipuliert`, ersetzt ihn nicht |
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
