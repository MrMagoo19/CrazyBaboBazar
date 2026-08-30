# RUNBOOK — Production-Quality-Fixes 2026-08-30

## Status

**`lokal vollstaendig getestet, nichts auf Production ausgefuehrt`**

Keine Datei dieses Verzeichnisses wurde gegen `project/ydiihvzcxaaoqhmgoqvu`
(Production) oder `project/nmzuycveumyfvtxdcnuc` (Pilot) ausgefuehrt. Es gab
keinen Production-Write, keinen Pilot-Write, keinen Push und kein Deploy.
Codex hat den Production-Vorzustand der Zielzeilen per read-only REST-GET
geprueft und Preis, ASINs sowie Bild-Erreichbarkeit extern read-only
gegengeprueft.

Der definitive Codex-Vollauf gegen PostgreSQL **16.15** bestand mit
**145/145 PASS**, **0 Abweichungen** und Exit **0**. Ergebnisdatei:
`/tmp/cbb-qftest.AgI5UJsx/results.tsv`; dauerhafte Zusammenfassung:
[`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md). Der fruehere Lauf mit 119/119
PASS bleibt als Historie fuer den Paketstand vor der Erweiterung dokumentiert.

Jeder spaetere Schritt ist **einzeln** freigabepflichtig. Es gibt keine
Sammelfreigabe fuer dieses Paket. Die Freigabetabelle steht in
[Abschnitt 3](#3-reihenfolge-und-freigabegrenzen); die offenen Gates stehen in
[Abschnitt 8](#8-noch-nicht-ausgefuehrte-gates).

---

## 1. Worum es geht

Das Paket korrigiert fuenf belegte Produktionsbefunde und **nichts sonst**.
Betroffen sind genau **sieben Zeilen in `public.products`** und **drei Zeilen in
`public.lists`**.

| Befund | Was ist falsch | Beleg im Repo |
|---|---|---|
| **A4** (Listen) | Zwei Listen verweisen auf einen Produkt-Slug mit Schreibfehler. Die korrekten Produkte existieren, die Listeneintraege zeigen ins Leere. | `import_lists_batch1.sql` Z. 58 und Z. 130 gegen `import_products_batch2.sql` Z. 30 und Z. 48 |
| **A4** (Kategorie) | Derselbe Tippfehler hat eine Produktzeile stehen lassen: `reassign_all_categories.sql` Z. 144-162 stellt einen Block ausdruecklich auf `babo / tech / gadgets`, fuehrt in seiner Slug-Liste (Z. 158) aber `plasmakugel-8-zoll-beruehlungsempfindlich`. Das echte Produkt `plasmakugel-8-zoll-beruehrungsempfindlich` wurde davon nie getroffen und steht bis heute auf `shop_sub_category = 'basteln'`. | `reassign_all_categories.sql` Z. 144-162, Tippfehler-Slug in Z. 158 |
| **A5** | `geschenke-fuer-gamer` traegt 16 statt 13 Eintraege — die letzten drei sind exakte Wiederholungen der Positionen 11 bis 13. | `update_list_add_gamer_products.sql` haengt genau diese drei Slugs an und ist zweimal gelaufen |
| **B2** | Drei Produkte stehen noch auf den Spaltendefaults `unknown / sonstiges / ungeordnet` und tragen nur Preis-Tags, also keinen Persona-Tag. | Defaults aus `add_shop_fields.sql`; Tag-Konvention aus `pilot_staging_seed.sql` |
| **B5** | `divoom-pixoo-led-panel` hat keinen Preis. `divoom-minitoo-…` hat ein einzelnes Nicht-Amazon-Bild. | `backfill_pilot_value_add.sql` Z. 25 haelt den fehlenden Preis ausdruecklich fest |
| **D6** | `cream-noise-machine-baby-tragbar` heisst in Name, Beschreibung und Redaktionsnotiz „Cream Noise Machine“ statt „White Noise Machine“. | `import_products_batch2.sql` Z. 23, `expand_descriptions_batch3.sql`, `add_editorial_notes_batch3.sql` |

**D7 ist ausdruecklich NICHT Teil dieses Pakets.** Siehe
[Abschnitt 6](#6-d7--warum-hier-nichts-passiert).

Der Production-Vorzustand aller zehn Zeilen wurde am **2026-08-30 von Codex
read-only verifiziert**. Genau dieser Vorzustand steht als Literal in allen
sechs SQL-Dateien und ist harte Abbruchbedingung.

---

## 2. Was genau geaendert wird

### 2.1 `public.products` — sieben Zeilen

| Gruppe | Slug | Geaenderte Spalten | vorher | nachher |
|---|---|---|---|---|
| B2 | `fingerabdruck-vorhaengeschloss-eseesmart` | `shop_persona`, `shop_main_category`, `shop_sub_category`, `shop_tags`, `updated_at` | `unknown / sonstiges / ungeordnet`, Tags `['preis:unter50','preis:unter100']` | `babo / tech / gadgets`, Tags `['babo:tech','preis:unter50','preis:unter100']` |
| B2 | `flauschige-handschuhe-weihnachten` | dieselben | `unknown / sonstiges / ungeordnet`, Tags `['preis:unter50','preis:unter100']` | `queen / lifestyle / mode`, Tags `['queen:lifestyle','preis:unter50','preis:unter100']` |
| B2 | `pizza-socks-box-pepperoni` | dieselben | `unknown / sonstiges / ungeordnet`, Tags `['preis:unter20','preis:unter50','preis:unter100']` | `queen / lifestyle / mode`, Tags `['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100']` |
| B5a | `divoom-pixoo-led-panel` | `price_cents`, `updated_at` | `NULL` | `4249` |
| B5b | `divoom-minitoo-retro-pc-lautsprecher-pixel` | `image_url`, `image_urls`, `updated_at` | ein Divoom-Shop-Bild | erstes von neun Amazon-Bildern; `image_urls` = alle neun |
| D6 | `cream-noise-machine-baby-tragbar` | `name`, `description`, `editorial_note`, `updated_at` | „Cream Noise Machine“ | „White Noise Machine“ |
| A4 | `plasmakugel-8-zoll-beruehrungsempfindlich` | nur `shop_sub_category` | `babo / tech / basteln`, Tags `['babo:tech','preis:unter50','preis:unter100']` | `babo / tech / gadgets` — **Persona, Hauptkategorie, Tags und `updated_at` bleiben identisch** |

**A4 aendert genau eine Spalte.** `shop_persona`, `shop_main_category`,
`shop_tags` und `updated_at` stehen in `04` nicht im `SET`, sondern
ausschliesslich in der Vorzustands- beziehungsweise Vollzeilenpruefung. Ein zu
breites UPDATE liesse die Transaktion scheitern.

Belege fuer die A4-Zeile:

* **Production, read-only am 2026-08-30 (Codex):** `babo / tech / basteln`,
  `shop_tags = ['babo:tech','preis:unter50','preis:unter100']`,
  `is_published = true`, `updated_at = 2026-07-04T00:00:00+00`.
* **Repo:** `reassign_all_categories.sql` Z. 144-162 — der Block setzt
  ausdruecklich `babo / tech / gadgets`, seine Slug-Liste enthaelt in Z. 158
  jedoch den Tippfehler-Slug `plasmakugel-8-zoll-beruehlungsempfindlich`. Das
  Zielprodukt wurde deshalb nie getroffen.

Die beabsichtigte Unterkategorie steht damit im Repo; das Paket vollzieht nur
nach, was `reassign_all_categories.sql` erreichen wollte.

**Kein Preis-Tag wird erfunden.** Die Persona-Tags werden den bereits
vorhandenen Preis-Tags nur vorangestellt; die Preisbaender bleiben, wie sie
sind.

**Der Slug `cream-noise-machine-baby-tragbar` bleibt absichtlich stehen.** Die
URL ist indexiert. Eine Slug-Aenderung waere ein SEO-Eingriff mit Redirect-Bedarf
und kein Textfix — sie ist nicht Teil dieses Pakets. Geaendert werden
ausschliesslich die drei sichtbaren Texte.

**B5 aendert nur Preis und Bilder.** Affiliate-Link und ASIN beider
Divoom-Produkte bleiben unberuehrt.

**Beruehrungspunkt zum Value-Add-Rollout:** `divoom-pixoo-led-panel` und
`divoom-minitoo-retro-pc-lautsprecher-pixel` gehoeren zu den zehn Produkten des
Value-Add-Pilots (`backfill_pilot_value_add.sql`,
`supabase/production_value_add/`). Dieses Paket fasst **keine** der acht
Value-Add-Spalten an (`fuer_wen`, `nicht_fuer`, `key_fact`, `pros`, `cons`,
`alternative_slug`, `alternative_reason`, `alternative_kind`). Der Nachweis ist
nicht nur eine Absichtserklaerung: `04` und `05` vergleichen die vollstaendige
Zeile gegen den Snapshot abzueglich genau der erlaubten Spalten — eine
Value-Add-Spalte, die sich mitveraendert haette, liesse die Transaktion
scheitern. Das Paket setzt die Value-Add-Artefakte umgekehrt auch nicht voraus:
sein Fingerprint besteht aus `products`, `lists`, `page_content`,
`discovery_queue` und `swipes`.

### 2.2 `public.lists` — drei Zeilen, jeweils nur `product_slugs`

| Slug | Aenderung |
|---|---|
| `verrueckte-amazon-gadgets` | Position 4: `plasmakugel-8-zoll-beruehlungsempfindlich` → `plasmakugel-8-zoll-beruehrungsempfindlich`. Die uebrigen 15 Eintraege und die Reihenfolge bleiben identisch. |
| `witzige-geschenke-maenner` | Position 2: `bug-a-salt-3-0-fliegenjager-salzgewehr` → `bug-a-salt-3-0-fliegenjaeger-salzgewehr`. Die uebrigen 11 Eintraege und die Reihenfolge bleiben identisch. |
| `geschenke-fuer-gamer` | 16 → 13 Eintraege: exakt die ersten 13. Erste Vorkommen und Reihenfolge bleiben erhalten. |

`public.lists` hat **keine** Spalte `updated_at`. Dort wird kein Zeitstempel
geschrieben.

> **Beleggrenze dieser Aussage.** Sie stuetzt sich auf zwei Quellen mit
> unterschiedlichem Gewicht:
>
> 1. **Production-REST-Schemaprobe, 2026-08-30, read-only.** Eine
>    PostgREST-Abfrage auf `updated_at` in `public.lists` antwortete mit
>    PostgreSQL-Fehlercode **`42703`** (`undefined_column`). Das ist ein
>    direkter Beleg am laufenden Production-Schema — nicht am Repo.
> 2. **Statische Repo-Pruefung.** Die einzige explizite Nicht-Test-Definition
>    von `public.lists` im Repo steht in `pilot_staging_bootstrap.sql` und
>    gehoert zum Pilot/Staging-Aufbau; sie fuehrt keine Spalte `updated_at`.
>    Das ist fuer Production nur eine Heuristik.
>
> Punkt 2 allein ist eine **Heuristik**, kein Beweis: eine ausserhalb des Repos
> von Hand ausgefuehrte Migration waere darin unsichtbar. Verbindlich ist
> deshalb Punkt 1. Die Repo-Dateien wurden fuer diese Aussage zusaetzlich
> vollstaendig von Codex und vom Pruefer gelesen, nicht nur gegrept.
>
> Praktisch abgesichert ist die Aussage ohnehin doppelt: schriebe `04` einen
> Zeitstempel in `public.lists`, gaebe es die Spalte nicht und die Anweisung
> scheiterte; gaebe es sie doch, faenge der `to_jsonb`-Vergleich gegen das
> Backup jede unbeabsichtigte Aenderung ab.

**Es werden keine anderen Dubletten bereinigt.** Die Deduplizierung gilt
ausschliesslich fuer `geschenke-fuer-gamer` und nur fuer die drei belegten
Wiederholungen. Andere Listen bleiben unberuehrt — auch dann, wenn sie
zufaellig denselben fehlerhaften Slug enthalten.

### 2.3 `updated_at`

Die sechs sichtbaren Produktaenderungen setzen `updated_at = now()`
**ausdruecklich**.
Der Trigger `products_set_updated_at` (`supabase/seo_updated_at_trigger.sql`)
ueberschreibt einen ausdruecklich mitgeschriebenen Wert nicht.

Begruendung je Gruppe:

* **B2** — `shop_persona` und `shop_main_category` bauen Breadcrumb-Link und
  -Label sowie den Block „aehnliche Produkte“. Beides sind sichtbare
  Seiteninhalte und interne Links.
* **B5a** — sichtbar ist das Preisband, nicht der exakte Preis
  (`lib/db-types.ts`, `getPriceBand`). Hier wechselt die Seite von
  „kein Preis“ auf ein Band; das ist eine echte sichtbare Aenderung. Genau fuer
  diesen Fall laesst der Trigger-Kommentar ein ausdruecklich mitgeschriebenes
  `updated_at` zu.
* **B5b** — `image_url` ist das primaere Produktbild und JSON-LD-Fallback.
* **D6** — `name`, `description` und `editorial_note` sind H1, Fliesstext,
  Meta-Description und der „Unser Urteil“-Block.
* **A4** — **hier liegt der Fall anders.**
  `shop_sub_category` erscheint im Rendering der Produktseite nicht: die
  einzige Verwendung im Anwendungscode ist `lib/db-types.ts` als Typfeld, und
  der Trigger-Kommentar in `supabase/seo_updated_at_trigger.sql` fuehrt die
  Spalte ausdruecklich unter „Bewusst NICHT aufgenommen“ mit der Begruendung
  „Kommt im gesamten Rendering nicht vor“. Aus demselben Grund wuerde der
  Trigger hier **nicht** feuern. Das Paket folgt diesem Aufnahmekriterium:
  `updated_at` bleibt bei A4 exakt historisch, und `04`, `05` sowie der
  Harness pruefen diese Nichtaenderung ausdruecklich.

`06` stellt die **historischen** `updated_at`-Werte der sechs
lastmod-Zielprodukte aus dem Snapshot wieder her, nicht `now()`. Bei A4 war der
historische Wert auch im Zielzustand unveraendert.

### 2.4 `updated_at IS NULL` ist eine harte Abbruchbedingung

`schema.sql` definiert `updated_at` nur als `DEFAULT now()`, **nicht** als
`NOT NULL`. Ein NULL-Zeitstempel an einer Zielzeile wuerde jeden Beweis dieses
Pakets still aushebeln:

* `p.updated_at > b.updated_at` ergibt mit NULL wieder NULL — die Zeile zaehlt
  weder als „neu“ noch als „nicht neu“.
* `06` haette keinen historischen Wert zurueckzuspielen; der Round-Trip waere
  ein Datenverlust statt einer Wiederherstellung.

Deshalb bricht **jede schreibende Datei vor ihrem Schreibvorgang** ab, wenn
eines der sechs lastmod-Zielprodukte `updated_at IS NULL` traegt:

| Datei | Geprueft wird | Meldung beginnt mit |
|---|---|---|
| `02` | die sechs lastmod-Zielzeilen in `public.products`, nach dem Row-Lock | `QF-Backup abgebrochen: … updated_at IS NULL` |
| `04` | die sechs lastmod-Zielzeilen in `public.products`, vor dem ersten UPDATE | `QF-Korrektur abgebrochen: … updated_at IS NULL` |
| `06` | die sechs lastmod-Zielzeilen **und** ihre sechs Backup-Zeilen | `QF-Restore abgebrochen: updated_at IS NULL bei …` |

`01` meldet denselben Sachverhalt read-only als Pruefzeile
`lastmod_zielprodukte_updated_at_nicht_null` (erwartet 6). Der Harness weist alle drei
Guards mit eigenen Negativfaellen nach
(`case_j_updated_at_null`, `case_j2_updated_at_null_vor_04`,
`case_j3_updated_at_null_vor_06`).

---

## 3. Reihenfolge und Freigabegrenzen

| Schritt | Datei | Art | Freigabe | Stand Production |
|---|---|---|---|---|
| 1 | `01_preflight_read_only.sql` | read-only | **eigene Freigabe #1 — erforderlich** | nicht ausgefuehrt |
| 2 | `02_backup_quality_fixes.sql` | **schreibend** | **eigene Freigabe #2 — erforderlich** | nicht ausgefuehrt |
| 3 | `03_verify_backup_read_only.sql` | read-only | **eigene Freigabe #3 — erforderlich** | nicht ausgefuehrt |
| 4 | `04_apply_quality_fixes.sql` | **schreibend** | **eigene Freigabe #4 — erforderlich** | nicht ausgefuehrt |
| 5 | `05_verify_read_only.sql` | read-only | **eigene Freigabe #5 — erforderlich** | nicht ausgefuehrt |
| (R) | `06_restore_quality_fixes.sql` | **schreibend** | **eigene Freigabe #6 — erforderlich** | nicht ausgefuehrt — reiner Rollbackpfad |

Regeln:

* Jede Zeile ist eine eigene Freigabe. Eine erteilte Freigabe gilt fuer genau
  einen Lauf einer genau benannten Datei gegen ein genau benanntes Projekt.
* Vor jedem Schritt ist das Zielprojekt **ausserhalb von SQL sichtbar** zu
  pruefen: `project/ydiihvzcxaaoqhmgoqvu`.
* Meldet `01` auch nur eine `FAIL`-Zeile, ist Schritt 2 **nicht** freigegeben.
  Dasselbe gilt fuer `03` vor Schritt 4 und `05` als Abschluss.
* `06` wird nur ausgefuehrt, wenn ein Rollback ausdruecklich gewuenscht ist und
  dafuer eine eigene Freigabe erteilt wurde.

Erwartete Ergebnisformen:

| Datei | Zeilen | davon PASS | davon INFO | FAIL |
|---|---|---|---|---|
| `01` | 28 | 22 | 6 | 0 |
| `03` | 23 | 16 | 7 | 0 |
| `05` | 28 | 23 | 5 | 0 |

Gegenueber dem Stand vor der Erweiterung sind das in `01` zwei zusaetzliche
PASS-Zeilen (`a4_kategorie_vorzustand_basteln`,
  `lastmod_zielprodukte_updated_at_nicht_null`) und in `05` eine
(`a4_kategorie_zielzustand_gadgets`). `03` bleibt bei 16 PASS-Zeilen; dort
aendern sich nur die erwarteten Zahlen von 6 auf 7.

`02` gibt nach dem Commit `7` und `3` zurueck. `04` und `06` geben nichts
zurueck; ein erfolgreicher Lauf ist ein Lauf ohne Exception.

---

## 4. Vor der Ausfuehrung zwingend zu pruefen

### 4.1 Zielumgebung

Production ist `ydiihvzcxaaoqhmgoqvu.supabase.co`, Pilot ist
`nmzuycveumyfvtxdcnuc.supabase.co`. Das Ziel wird sichtbar geprueft, nicht
angenommen (`AGENTS.md` §6).

### 4.2 Der Preis in B5a ist tagesaktuell — Pflicht-Nachpruefung

`price_cents = 4249` stammt von der Amazon.de-Produktseite zu ASIN
`B07HHXWN3C`, angezeigter Preis **42,49 EUR, abgelesen am 2026-08-30**.

**Vor einer spaeteren Production-Ausfuehrung von `04` ist dieser Preis
unmittelbar erneut zu pruefen.** Weicht er ab:

1. Das Paket **nicht** ausfuehren.
2. Den Befund neu auditieren und den Zielwert in **allen** Dateien anpassen, in
   denen er steht (`01`, `02`, `04`, `05`, `06`).
3. Den lokalen Harness erneut laufen lassen.
4. Neue Freigabe einholen.

Ein Preis im Shop, den es auf Amazon nicht gibt, ist ein Verstoss gegen die
Amazon-Programmrichtlinien und gegen die Content-Regeln in `CLAUDE.md`. Er ist
schaedlicher als gar kein Preis — und „gar kein Preis“ ist der aktuelle Zustand.

### 4.3 Die neun Bild-URLs in B5b

Alle neun URLs wurden am 2026-08-30 mit `GET` geprueft: HTTP 200,
`Content-Type: image/jpeg`. Quelle ist Amazon.de, ASIN `B0FRF3XGQ4`. Sie sind
stabiler als die aktuelle Divoom-Shop-URL, weil sie auf derselben CDN liegen wie
alle uebrigen Produktbilder des Shops.

### 4.4 Lokaler Harness — Gate erfuellt

**Stand: `145/145 PASS, 0 Abweichungen, Exit 0`.**

`test/run_local_postgres_test.sh` lief am 2026-08-30 gegen PostgreSQL **16.15**
mit **145/145 PASS**, **0 Abweichungen** und Exit **0**. Darin enthalten sind
die siebte Zielproduktzeile, die zusaetzlichen Diagnosezeilen, der Rollen-Guard
in `02`, die drei `updated_at`-Guards sowie vier neue Negativfaelle. Der
lokale Cluster wurde danach sauber gestoppt; PGDATA und Socketverzeichnis wurden
entfernt. Details stehen in [`LOCAL_TEST_REPORT.md`](LOCAL_TEST_REPORT.md) und
[`test/README.md`](test/README.md).

---

## 5. Sicherheitsmerkmale der sechs Dateien

### 5.1 Form

* `01`, `03` und `05` sind je **genau ein lesendes `WITH … SELECT`**. Kein DDL,
  kein DML, kein `DO`-Block, keine Transaktionssteuerung. Der Harness prueft das
  statisch.
* `02`, `04` und `06` sind je **eine** Transaktion. Direkt hinter `begin;`
  stehen `lock_timeout = '5s'` und `statement_timeout = '60s'` — vor der ersten
  Anweisung, die `public.products` anfasst. Ohne diese Reihenfolge wuerde die
  Guard-Phase mit dem Session-Default `lock_timeout = 0` unbegrenzt auf einen
  konkurrierenden `AccessExclusiveLock` warten. Auch das prueft der Harness
  statisch.
* **Keine der sechs Dateien enthaelt ein `DROP`, `DELETE` oder `TRUNCATE`.**
  Statisch geprueft. Das Backup bleibt nach einem Restore als Audit-Artefakt
  bestehen; keine Datei dieses Pakets loescht es.

### 5.2 Production-Fingerprint

Jede schreibende Datei bricht ab, wenn

* eines der bekannten Pilot-Artefakte vorhanden ist
  (`pilot_meta.environment_guard`, `pilot_backup.value_add_pre_backfill`,
  `public.pilot_value_add_backup_20260823`),
* eine der fuenf Tabellen `products`, `lists`, `page_content`,
  `discovery_queue`, `swipes` fehlt,
* `public.products` weniger als 300 Zeilen hat.

### 5.3 Harter Vor- und Zielzustand, Row-Locks, Recheck nach dem Lock

Die sperrfreie Vorpruefung ist nur ein billiger Vorfilter. Verbindlich ist
immer die Pruefung **nach** dem Row-Lock:

1. Alle zehn Zielzeilen werden gemeinsam mit ihren Backup-Zeilen gesperrt
   (`FOR UPDATE OF p, b` bzw. `FOR UPDATE OF l, b`). Die erwartete Zeilenzahl
   wird per `GET DIAGNOSTICS` geprueft: 7 und 3.
2. Danach wird der Zustand **vollstaendig** neu klassifiziert, plus:
   * Backup entspricht exakt dem bekannten Vorzustand (Manipulationsschutz),
   * Backup und Quelle sind im Vorzustandsfall **ueber alle Spalten** driftfrei
     (`to_jsonb`-Vergleich, `updated_at` eingeschlossen),
   * kein Zielprodukt traegt `updated_at IS NULL` (siehe Abschnitt 2.4).
3. Erst danach wird geschrieben. Jedes UPDATE prueft seine Trefferzahl exakt
   (3, 1, 1, 1, 1 fuer Produkte; 3 fuer Listen).

Eine konkurrierende Aenderung, die zwischen Vorpruefung und Lock committet, wird
dadurch erkannt und **nicht** ueberschrieben. Der Harness weist beides mit echten
zweiten Sessions nach, nicht simuliert.

### 5.4 „Keine andere Zeile“ ist gemessen, nicht behauptet

`04` und `06` nehmen vor dem Schreibvorgang einen `md5(to_jsonb(zeile))`-
Fingerabdruck **jeder Nichtzielzeile** in `products` und `lists` auf und
vergleichen ihn danach. Weicht auch nur eine Zeile ab, bricht die Transaktion
ab.

Zusaetzlich wird pro Zielzeile geprueft, dass ausserhalb der fuer sie erlaubten
Spalten nichts abweicht — `to_jsonb(zeile) - erlaubte_spalten` gegen dieselbe
Operation auf der Backup-Zeile.

> **Betriebshinweis:** Weil diese Messung in `READ COMMITTED` laeuft, wuerde ein
> gleichzeitiger fremder Schreibvorgang an einer beliebigen anderen Produkt-
> oder Listenzeile zum Abbruch fuehren. Das ist beabsichtigt fail-closed. In der
> Praxis schreibt auf `products` und `lists` nur ein Admin-Skript; die App
> schreibt ausschliesslich nach `swipes`.

### 5.5 Snapshot

`02` legt zwei Tabellen im privaten Schema `cbb_private_backup` an:

| Tabelle | Inhalt |
|---|---|
| `quality_fixes_20260830_products_v1` | 7 vollstaendige Zeilen aus `public.products` (`SELECT *`) |
| `quality_fixes_20260830_lists_v1` | 3 vollstaendige Zeilen aus `public.lists` (`SELECT *`) |

„Vollstaendig“ ist Absicht: der Rollback ist damit nicht auf die heute bekannte
Spaltenauswahl angewiesen. Beide Tabellen bekommen `PRIMARY KEY (id)`,
`UNIQUE (slug)` und `ROW LEVEL SECURITY`; sie haben **0 Policies** und **keine
Rechte** fuer `PUBLIC`, `anon`, `authenticated` oder `service_role`. Geprueft
wird zweifach — direkte ACL-Eintraege ueber `aclexplode` **und** effektive
Rechte ueber `has_table_privilege`/`has_schema_privilege`, die
Rollenmitgliedschaft und geerbte `PUBLIC`-Rechte mit aufloesen. Eine Pruefung,
die nur die direkten ACLs liest, waere fail-open, sobald ein Recht nur geerbt
ist.

`service_role` ist in `04` und `06` eine **harte** Abbruchbedingung. In `03` und
`05` erscheint sie nur als `INFO`: dort wird berichtet, hier wird geschrieben.
Auf Supabase traegt `service_role` typischerweise `BYPASSRLS`; RLS allein ist
gegen sie kein Schutz.

**Rollen-Guard — alle drei schreibenden Dateien.** Saemtliche Rechte-Zaehler
laufen ueber `pg_roles … where rolname in ('anon','authenticated',
'service_role')`. Fehlt eine der beiden App-Rollen, faellt sie aus dem Join und
der Zaehler meldet still `0` — kein Beleg fuer „keine Rechte“, nur einer fuer
„keine Rolle“. `04` und `06` brachen dafuer schon vorher hart ab; **`02` tut es
jetzt ebenfalls**, und zwar in Guard 1, also **vor jeder Verzweigung**. Damit
kann auch der No-Op-Zweig (Backup existiert bereits) keine Backup-Tabelle mehr
als „sicher“ durchwinken, deren Rechtelage gar nicht gemessen wurde. Die
Meldung lautet einheitlich
`… abgebrochen: %/2 App-Rollen (anon, authenticated) vorhanden — Rechtepruefung nicht aussagekraeftig.`

`service_role` bleibt aus dieser Vorbedingung bewusst draussen: `02` revoked sie
nur, wenn es sie gibt, und ein Cluster ohne `service_role` ist kein Fehlerfall.
`anon` und `authenticated` dagegen existieren auf Supabase immer.

Der Harness weist das mit `case_i_rolle_fehlt` nach. Dort wird `authenticated`
**umbenannt statt geloescht**: ACL-Eintraege haengen an der Rollen-OID, ein
`DROP ROLE` scheiterte an den Rechten in allen bereits angelegten
Fall-Datenbanken. Aus Sicht der Guards ist die Rolle danach genauso weg wie nach
einem `DROP`. Weil Rollen und Rollenattribute **clusterweit** sind, hat der Fall
ein eigenes Teardown, das zurueckbenennt und danach nachweist, dass Name,
`NOINHERIT`, die Rechte auf `public` und die Dichtheit des privaten Backups
unveraendert sind; ein abschliessender `02`-Lauf belegt, dass der Cluster
wirklich wieder sauber ist.

> **Vor Freigabe #4 lesen:** Melden die vier `service_role`-INFO-Zeilen von `03`
> etwas anderes als `keine`, wird `04` abbrechen. Das ist beabsichtigt und dann
> ein eigener Befund — kein Grund, den Guard zu entschaerfen. Erwartet wird
> `keine` in allen vier Zeilen, weil `02` `service_role` ausdruecklich revoked
> und `service_role` auf Supabase kein Mitglied der besitzenden Rolle ist
> (umgekehrt ist `postgres` Mitglied von `service_role`, was die effektiven
> Rechte von `service_role` nicht erhoeht).

### 5.6 Wiederholbarkeit

| Datei | Bei erneutem Lauf im erreichten Zustand | Bei gemischtem oder gedriftetem Zustand |
|---|---|---|
| `02` | No-Op, wenn beide Backup-Tabellen existieren, exakt den bekannten Vorzustand enthalten und die sechs lastmod-Zeitstempel nicht NULL sind | Abbruch — auch bei nur einer der beiden Tabellen, falscher Zeilenzahl, veraendertem Inhalt, NULL-Zeitstempel oder geoeffneten Rechten |
| `04` | No-Op, wenn alle zehn Zeilen exakt im Zielzustand stehen und alle sechs lastmod-Zeitstempel nach dem Backup liegen — **kein UPDATE, kein neues `updated_at`** | Abbruch |
| `06` | No-Op, wenn alle zehn Zeilen exakt dem Backup entsprechen und weder Quelle noch Backup einen NULL-lastmod-Zeitstempel tragen | Abbruch |

---

## 6. D7 — warum hier nichts passiert

Der Audit-Befund D7 betraf zwei Produktzeilen, die auf den ersten Blick wie
Dubletten aussehen:

| Slug | ASIN / Link | Preis | aktuelles Bild | Klassifizierung |
|---|---|---|---|---|
| `tosy-flying-disc-108-rgb-leds-leuchtfrisbee` | `B0B1YMNGS2`, **direkt im Repo** (`import_products_batch8.sql` Z. 49) | 3599 (`import_products_batch8.sql` Z. 46) | `51QWMABiNIL` (`fix_batch8_images.sql` Z. 5) | `babo / lifestyle / gadgets` (`reassign_all_categories.sql` Z. 286) |
| `tosy-flying-disc-wiederaufladbar` | eigener Kurzlink `amzn.to/3QtubCJ` (`manual_affiliate_fix.sql` Z. 44) — die ASIN steht **nicht** im Repo | 2999 (`products_update.sql` Z. 63) | `81vsAxy1YLL` (`products_update.sql` Z. 63) | `miniboss / spass / outdoor` (`reassign_all_categories.sql` Z. 754) |

#### Was das Repo belegt — und was nicht

**Aus dem Repo direkt belegt:**

* zwei **getrennte Slugs** mit getrennten Datensaetzen,
* zwei **verschiedene Preise**: 3599 und 2999,
* zwei **verschiedene aktuelle Bilder**: `51QWMABiNIL` und `81vsAxy1YLL`,
* zwei **verschiedene redaktionelle Klassifizierungen**, dazu der ausdrueckliche
  Kommentar `Flying Disc (wiederaufladbar — Miniboss-Version)` in
  `reassign_all_categories.sql` Z. 752,
* **eine** ASIN im Klartext: `B0B1YMNGS2` fuer die 108-RGB-Variante.

**NICHT aus dem Repo belegt:** die zweite ASIN `B0C3ZTKRGX`. Der Datensatz
`tosy-flying-disc-wiederaufladbar` traegt im Repo nur einen Amazon-Kurzlink.
`B0C3ZTKRGX` stammt aus dem **externen read-only Redirect-Abgleich des aktuellen
Production-Kurzlinks am 2026-08-30** — einer Ausserquelle mit eigenem
Zeitbezug, nicht aus dem Repository. Ein Kurzlink kann umgehaengt werden; die
Aussage gilt fuer den Stand vom 2026-08-30.

> **Korrektur gegenueber der frueheren Fassung dieses Runbooks.** Dort stand
> `51+3VUFiE8L` als aktuelles Bild mit Quelle `fix_batch8_images.sql`. Beides
> zusammen war falsch: `51+3VUFiE8L` ist der **Import**-Wert aus
> `import_products_batch8.sql` Z. 48 und wurde von `fix_batch8_images.sql` Z. 5
> ueberschrieben. Der aktuelle Wert ist `51QWMABiNIL`. Ebenso stand dort, das
> Repo belege „zwei verschiedene ASINs“ — es belegt eine.

Die Trennung bleibt damit belegt: sie steht auf getrennten Slugs, getrennten
Preisen, getrennten Bildern und einem ausdruecklichen Redaktionskommentar. Sie
haengt **nicht** an der zweiten ASIN. Das ist kein Datenfehler, sondern eine
**beabsichtigte redaktionelle Trennung** zweier Artikel. Der Befund wird damit
geschlossen. **Es gibt keine SQL-Aenderung fuer D7, und dieses Paket fasst die
beiden Zeilen nicht an.** `01` und `05` fuehren den Punkt nur als `INFO`-Zeile.

---

## 7. Ausfuehrung — Schritt fuer Schritt

Jeder Schritt setzt seine eigene, frisch erteilte Freigabe voraus. Das lokale
Harness-Gate aus Abschnitt 4.4 ist erfuellt; offen bleiben die
Production-Freigaben und die unmittelbar vor `04` zu wiederholenden
Preis-/Bildpruefungen.

1. **Freigabe #1 einholen.** Zielprojekt sichtbar pruefen.
   `01_preflight_read_only.sql` ausfuehren. Erwartet: 28 Zeilen, 22 PASS,
   6 INFO, **0 FAIL**. Jede FAIL-Zeile beendet den Vorgang hier.
2. **Preis nachpruefen** (Abschnitt 4.2). Bei Abweichung: Stopp und
   Neu-Audit.
3. **Freigabe #2 einholen.** `02_backup_quality_fixes.sql` ausfuehren.
   Erwartet: `backup_produkt_zeilen = 7`, `backup_listen_zeilen = 3`.
4. **Freigabe #3 einholen.** `03_verify_backup_read_only.sql` ausfuehren.
   Erwartet: 23 Zeilen, 16 PASS, 7 INFO, **0 FAIL**.
5. **Freigabe #4 einholen.** `04_apply_quality_fixes.sql` ausfuehren.
   Erwartet: kein Fehler, keine Ausgabe.
6. **Freigabe #5 einholen.** `05_verify_read_only.sql` ausfuehren.
   Erwartet: 28 Zeilen, 23 PASS, 5 INFO, **0 FAIL**.
7. **Nachlauf ohne Datenbankbezug** (getrennt zu bewerten, nicht Teil dieses
   Pakets): Die sechs sichtbar geaenderten Produktseiten tragen ein neues
   `lastmod`; die A4-Produktzeile behaelt ihren historischen Zeitstempel. Ob und
   wann eine Sitemap-Einreichung erfolgt, ist eine eigene Entscheidung mit
   eigener Freigabe (`AGENTS.md` §7, Search-Console-Schreibaktionen).

Rollback: **Freigabe #6 einholen**, dann `06_restore_quality_fixes.sql`. Danach
`05` erneut ausfuehren — es muss dann FAIL-Zeilen melden, denn der Zielzustand
ist wieder aufgehoben. Das ist der korrekte Ausgang, kein Fehler.

---

## 8. Noch nicht ausgefuehrte Gates

| Gate | Wer | Stand |
|---|---|---|
| Lokaler PostgreSQL-Harness `test/run_local_postgres_test.sh` | Codex | **145/145 PASS**, 0 Abweichungen, Exit 0 (PostgreSQL 16.15, 2026-08-30) |
| Historie: Harness-Lauf vor der Erweiterung | Codex | 119/119 PASS, 0 Abweichungen, Exit 0 (2026-08-30) — gilt **nicht** fuer den aktuellen Stand |
| Unabhaengiges Codex-Audit der sechs SQL-Dateien (`--profile deep`) | Codex | **abgeschlossen**; A4-lastmod getrennt, drei No-Op-Zeitstempelpfade nachgehaertet, Harness-Gate gruen |
| Erneute Preispruefung ASIN `B07HHXWN3C` unmittelbar vor `04` | Codex/Benutzer | **offen** |
| Erneute Erreichbarkeitspruefung der neun Bild-URLs unmittelbar vor `04` | Codex/Benutzer | **offen** |
| Freigabe #1 bis #5 (Production) | Benutzer | **offen** |
| Freigabe #6 (Rollback) | Benutzer | **offen, nur bei Bedarf** |
| Sitemap-/Search-Console-Nachlauf | Benutzer | **offen, eigener Vorgang** |

Keine Production-Checkbox fuer **A4, A5, B2, B5 oder D6** ist abgehakt. **D7**
bleibt als sachlich geklaert markiert — er braucht keine Datenaenderung und
damit auch keine Production-Ausfuehrung.

---

## 9. Dateien

```
production_quality_fixes_20260830/
├── 01_preflight_read_only.sql        read-only, ein WITH … SELECT, 28 Zeilen
├── 02_backup_quality_fixes.sql       schreibend, legt den Snapshot an
├── 03_verify_backup_read_only.sql    read-only, prueft den Snapshot, 23 Zeilen
├── 04_apply_quality_fixes.sql        schreibend, die eigentliche Korrektur
├── 05_verify_read_only.sql           read-only, Abschlusspruefung, 28 Zeilen
├── 06_restore_quality_fixes.sql      schreibend, Rollback aus dem Snapshot
├── RUNBOOK.md                        diese Datei
└── test/
    ├── README.md                     Aufbau und Aussagekraft des Harness
    ├── run_local_postgres_test.sh    Harness gegen echtes PostgreSQL 16
    ├── fixture/                       Rollen, Schema, Seed, Baseline
    └── cases/                         Setups, Teardowns und Assertions
```
