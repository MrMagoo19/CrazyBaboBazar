# RUNBOOK — Production-N4-Content-Korrektur

## Status

**Schritt 1 (read-only Preflight), Schritt 2 (Backup), Schritt 3 (read-only
Backup-Pruefung), Schritt 4 (schreibende N4-Inhaltskorrektur) und Schritt 5
(read-only Abschlusspruefung) sind auf Production ausgefuehrt. `06` ist
unausgefuehrt und ist nicht erforderlich, solange kein Rollback gewuenscht oder
angezeigt ist; es bleibt in jedem Fall separat freigabepflichtig.**

Ausgefuehrt wurden ausschliesslich `01_preflight_read_only.sql` (read-only, ohne
DDL und ohne DML), `02_backup_n4_content.sql` (schreibend, legt die
Backup-Tabelle an), `03_verify_backup_read_only.sql` (**read-only**, ohne DDL
und ohne DML), `04_correct_n4_content.sql` (**schreibend**, korrigiert den
N4-Inhalt) und `05_verify_read_only.sql` (**read-only**, ohne DDL und ohne DML)
auf `project/ydiihvzcxaaoqhmgoqvu`. Details siehe
[Abschnitt 3.1](#31-ausfuehrungsstand-production). An `public.products` wurde
durch Schritt 4 genau die N4-Zeile korrigiert — keine weitere Zeile. Die
unabhaengige Nachpruefung dieses Zielzustands auf Production ist mit Schritt 5
**erfolgreich abgeschlossen** (26 Zeilen, 18 PASS, 8 INFO, 0 FAIL); die
N4-Korrektur ist damit verifiziert. `06` (Restore) ist **nicht** auszufuehren,
ausser es wird spaeter ausdruecklich ein Rollback gewuenscht und dafuer eine
eigene Freigabe erteilt. Auf Git-Seite geschah nichts:
kein Git-Commit, kein Merge, kein Push, kein Deploy. (Die SQL-Transaktionen von
Schritt 2 und Schritt 4 enthalten selbstverstaendlich je ein `COMMIT` — gemeint
ist hier ausschliesslich Git.) Die uebrigen Dateien in diesem Verzeichnis warten weiterhin
auf eine ausdrueckliche Benutzerfreigabe — jede einzeln.

Der Stand des lokalen PostgreSQL-Tests ist in
[`test/README.md`](test/README.md) dokumentiert. Nach einem ersten, wegen eines
FIFO-Fehlers im Harness gezielt abgebrochenen Lauf wurde die Steuerung
korrigiert und unabhaengig erneut ausgefuehrt: **94 Schritte, 0 Abweichungen,
Exit 0**. Das umfasst die echten Nebenlaeufigkeitsfaelle, den 5-Sekunden-
Lock-Timeout und den exakten Restore aller 376 Fixture-Zeilen. Der temporaere
PostgreSQL-16-Cluster wurde danach mit `pg_ctl stop` Exit 0 gestoppt; `PGDATA`
und Socketverzeichnis wurden entfernt.

---

## 1. Worum es geht

Die Produktseite `n4-nussmilchbereiter-pflanzenmilch` (ASIN `B0FKMBPLBF`)
widerspricht sich in Production selbst:

| Feld          | Aussage in Production                        | Quelle im Repo                          |
|---------------|----------------------------------------------|-----------------------------------------|
| `tagline`     | "Hafermilch in unter 2 Minuten"              | `supabase/import_products_batch13.sql`  |
| `description` | "in 15 Minuten"                              | `supabase/expand_descriptions_batch6.sql` |
| `description` | "Amortisiert sich nach 2 Monaten"            | `supabase/expand_descriptions_batch6.sql` |

"unter 2 Minuten" und "15 Minuten" koennen nicht beide stimmen. Die
Amortisationsaussage ist unbelegt. Der Value-Add-Rollout
(`supabase/production_value_add/`) hat diesen Widerspruch bewusst nicht
angefasst — siehe dortiger Kopfkommentar in `04_backfill_value_add.sql` und
die INFO-Zeile `n4_zeittext_unveraendert` in `05_verify_read_only.sql`.
Dieses Paket loest ihn auf, und zwar **nur** ihn.

### Quellen fuer den korrigierten Text

1. **F.A.Z. Kaufkompass, unabhaengiger Test** —
   <https://www.faz.net/kaufkompass/?p=354062>
   Beschreibt die Programme *Grains / Nuts / Beans*, misst beim Haferprogramm
   **32 Minuten**, Erhitzen bis **100 °C**, und stellt fest, dass das
   Reinigungsprogramm **unterstuetzt, aber nicht vollstaendig reinigt**.
2. **Produktlisting-Mirror** —
   <https://www.ubuy.com.gh/productde/R37DPNOFE-ariceck-n4-professional-nut-milk-maker-with-self-cleaning-function-ideal-for-almond-milk-soy-milk-and-smoothies-800w-high-power-motor-recipe>
   Bestaetigt **Ariceck N4**, **1,5 Liter**, **800 W** sowie
   **Mandel / Soja / Hafer** und eine **Reinigungsfunktion**.

### Bewusste Zurueckhaltung im Zieltext

Der Zieltext nennt **keine neue konkrete Laufzeit** und **keine Amortisation**.
Die 32 Minuten aus dem F.A.Z.-Test gelten fuer ein Programm auf einem
Testgeraet — daraus wird hier keine allgemeine Zusage gemacht. Stattdessen:
"Die Laufzeit haengt vom gewaehlten Programm ab". Aus "unterstuetzt, aber
reinigt nicht vollstaendig" wird "ein Reinigungsprogramm unterstuetzt
anschliessend beim Saubermachen, ersetzt die manuelle Nachreinigung aber nicht
immer" — und nicht mehr "Selbstreinigung".

---

## 2. Was genau geaendert wird

Genau **eine** Zeile: `public.products` mit
`slug = 'n4-nussmilchbereiter-pflanzenmilch'`.

An ihr genau **acht** Spalten:

| Spalte           | vorher (gekuerzt)                                   | nachher (gekuerzt)                                        |
|------------------|-----------------------------------------------------|-----------------------------------------------------------|
| `tagline`        | 800W … Hafermilch in unter 2 Minuten                | 1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor …         |
| `description`    | … in 15 Minuten … Amortisiert sich nach 2 Monaten   | … Programme fuer Getreide, Nuesse und Bohnen …            |
| `nicht_fuer`     | … die Anschaffung amortisiert sich dann kaum        | … keinerlei manuelle Nachreinigung erwartet               |
| `key_fact`       | 800-W-Bereiter mit Selbstreinigung …                | 1,5-Liter-Behaelter, 800-W-Motor … unterstuetzt …         |
| `pros`           | u. a. "Selbstreinigung", "Fuenf Milchsorten"        | Programme, 1,5 Liter, 800-W-Motor, Reinigungsprogramm     |
| `cons`           | "Lohnt sich nur bei regelmaessigem Konsum" …        | Laufzeit programmabhaengig, manuelle Nachreinigung        |
| `editorial_note` | "… auf Knopfdruck und reinigt sich selbst"          | "… unterstuetzt danach mit einem Reinigungsprogramm"      |
| `updated_at`     | historischer Wert                                    | `now()`                                                   |

`updated_at = now()` ist Absicht: `tagline`, `description` und
`editorial_note` sind sichtbarer Seiteninhalt, die Korrektur ist also ein
echtes neues `lastmod` fuer die Sitemap. Der Trigger
`products_set_updated_at` (siehe `supabase/seo_updated_at_trigger.sql`)
ueberschreibt einen ausdruecklich mitgeschriebenen Wert nicht.

**Nicht** geaendert werden `fuer_wen`, `alternative_slug`,
`alternative_reason`, `alternative_kind` — und keine andere Zeile der Tabelle.

---

## 3. Reihenfolge und Freigabegrenzen

| Schritt | Datei                                | Art        | Freigabe                    | Stand Production |
|---------|--------------------------------------|------------|-----------------------------|------------------|
| 1       | `01_preflight_read_only.sql`         | read-only  | **eigene Freigabe #1 — erteilt und verbraucht** | **ausgefuehrt, 0 FAIL** (3.1) |
| 2       | `02_backup_n4_content.sql`           | **schreibend** | **eigene Freigabe #2 — erteilt und verbraucht** | **ausgefuehrt, `n4_backup_rows=1`** (3.1) |
| 3       | `03_verify_backup_read_only.sql`     | read-only  | **eigene Freigabe #3 — erteilt und verbraucht** | **ausgefuehrt, 17 Zeilen, 10 PASS, 7 INFO, 0 FAIL** (3.1) |
| 4       | `04_correct_n4_content.sql`          | **schreibend** | **eigene Freigabe #4 — erteilt und verbraucht** | **ausgefuehrt, rohe Rueckgabe `[]`** (3.1) |
| 5       | `05_verify_read_only.sql`            | read-only  | **eigene Freigabe #5 — erteilt und verbraucht** | **ausgefuehrt, 26 Zeilen, 18 PASS, 8 INFO, 0 FAIL** (3.1) |
| (R)     | `06_restore_n4_content.sql`          | **schreibend** | **eigene Freigabe #6 — erforderlich** | nicht ausgefuehrt — reiner Rollbackpfad |

Vor **jedem** Schritt, der die Production-Datenbank beruehrt, gilt ohne
Ausnahme: es braucht eine eigene, ausdrueckliche Benutzerfreigabe fuer genau
diese eine Datei. Das schliesst die read-only Schritte `01`, `03` und `05`
ausdruecklich ein — auch ein `SELECT` ist ein Zugriff auf Production und ist
nicht freigabefrei. Freigaben gelten nicht weiter: eine Freigabe fuer `02`
erlaubt `03` nicht, eine Freigabe fuer `03` erlaubt `04` nicht, und so fort bis
`06`. Die Freigabe fuer Schritt 1 ist mit dessen Ausfuehrung verbraucht und
deckt keinen weiteren Schritt. Ohne die jeweils eigene Freigabe wird die Datei
nicht ausgefuehrt.

Zusaetzlich gilt vor **jedem** schreibenden Schritt (`02`, `04`, `06`):

1. Im Supabase-SQL-Editor sichtbar pruefen, dass das Projekt
   **`project/ydiihvzcxaaoqhmgoqvu`** ausgewaehlt ist. PostgreSQL kennt die
   Supabase-Projekt-Ref nicht; die Tabellen-Fingerprints in den Guards sind nur
   ein zusaetzlicher Fail-closed-Beleg, kein Ersatz fuer den Blick.
2. Der vorhergehende read-only Schritt muss **0 FAIL-Zeilen** gemeldet haben.
3. Es wird **genau eine Datei** freigegeben, nicht "der Rest des Runbooks".
4. Bei irgendeinem FAIL: nichts korrigieren, nichts nachgranten, nichts
   loeschen. Befund melden und Ursache klaeren.

### Erwartete Ergebnisse der read-only Schritte

| Datei | Zeilen | davon PASS | davon INFO | INFO-Sortierungen        |
|-------|--------|-----------|------------|--------------------------|
| `01`  | 21     | 18        | 3          | 10, 20, 210              |
| `03`  | 17     | 10        | 7          | 10, 20, 200–240          |
| `05`  | 26     | 18        | 8          | 10, 20, 210–260          |

`service_role` erscheint in `03` und `05` ausschliesslich als INFO, nie als
PASS. Die Rolle ist auf Supabase typischerweise `BYPASSRLS`; RLS allein ist
gegen sie kein Schutz. Wer eine Zusage ueber `service_role` braucht, braucht
dafuer einen eigenen, getrennt freigegebenen Vorgang. Dasselbe Muster wie in
`production_value_add/05b_verify_payload_security_read_only.sql`.

**Ausnahme `06`:** dort ist `service_role` keine INFO, sondern eine harte
Abbruchbedingung — siehe Abschnitt 6.2. `06` schreibt Backup-Inhalt nach
`public.products`; eine Rolle, die das Backup veraendern koennte, macht diesen
Schritt unsicher. Meldet `03` fuer `service_role` etwas anderes als "keine",
wird `06` deshalb abbrechen.

### 3.1 Ausfuehrungsstand Production

Bisher sind genau **fuenf** Schritte dieses Runbooks auf Production ausgefuehrt
worden: Schritt 1, der read-only Preflight, Schritt 2, das Backup, Schritt 3,
die read-only Backup-Pruefung, Schritt 4, die schreibende N4-Inhaltskorrektur,
und Schritt 5, die read-only Abschlusspruefung. `06` ist unausgefuehrt, ist
nicht erforderlich, solange kein Rollback gewuenscht oder angezeigt ist, und
braucht in jedem Fall eine eigene, ausdrueckliche Freigabe.

#### Schritt 1 — `01_preflight_read_only.sql` (read-only, ausgefuehrt)

**Freigabe.** Der Benutzer gab wortwoertlich frei:
"Ich gebe Production-N4-Schritt 1 (read-only Preflight) auf
ydiihvzcxaaoqhmgoqvu frei." Diese Freigabe deckt ausschliesslich Schritt 1 ab.

**Identitaet der ausgefuehrten Datei.** SHA-256 der lokalen Datei und des in
den Editor eingefuegten Inhalts waren identisch:

```
148b6772ce69904fd52474d41d21da9da005a2492b5fb733ca808574b1f6813e
```

**Ziel, sichtbar geprueft.** CrazyBaboBazar Project, `project/ydiihvzcxaaoqhmgoqvu`,
Branch `main` / `PRODUCTION`, Rolle `postgres`.

**Art des Laufs.** Genau einmal ausgefuehrt. Genau ein read-only
`WITH … SELECT`. Kein DDL, kein DML, keine Transaktion mit Schreibanteil.

**Ergebnis: 21 Zeilen, 18 PASS, 3 INFO, 0 FAIL** — exakt die in der Tabelle
"Erwartete Ergebnisse der read-only Schritte" fuer `01` hinterlegte Struktur.
Alle 18 harten Checks bestanden:

* 4 Production-Tabellen vorhanden (Fingerprint vollstaendig),
* 376 Produkte,
* 0 Pilot-Artefakte,
* N4 genau 1x und `is_published = true`,
* Value-Add-Schema vollstaendig: 8/8 Spalten, 8/8 Typen, 2/2 Constraints,
* `value_add_pre_backfill_v1` = 10 Zeilen, `value_add_payload_v1` = 10 Zeilen,
  N4-Payload-Zeile befuellt (1),
* `cbb_private_backup.n4_content_pre_fix_v1` fehlt — wie vor Schritt 2 gefordert,
* alle sieben N4-Vorwerte jeweils 1 und der Gesamtvorzustand 1.

**Die 3 INFO-Zeilen.** `current_user` = `postgres`, `current_database` =
`postgres`, sowie der bereits bekannte Zeitwiderspruch im N4-Text — der wird
planmaessig erst durch Schritt 04 aufgeloest und ist hier korrekt nur eine
Feststellung, kein FAIL.

**UI-Automatik, keine bewusste Aktion.** Beim Einfuegen legte der Supabase-
Autosave automatisch die Snippet-ID `/sql/350a7584-35d5-4541-aea1-e6a0c12eabed`
an. Es wurde nie auf "Save" geklickt; beim Lauf stand im Editor
"Unsaved edits". Das ist Verhalten der Oberflaeche, kein Vorgang des Runbooks.

**Abbruch der Tabverbindung.** Nach dem Auslesen des Ergebnisses brach die
MCP-Tabgruppe weg. Eine zweite Ausfuehrung fand dadurch **nicht** statt — der
Lauf blieb bei genau einer Ausfuehrung.

**Unabhaengige Nachkontrolle (lokal, kein DB-Zugriff).** Codex bestaetigte
anschliessend lokal erneut den SHA-256, genau ein Semikolon in der Datei,
0 schreibende Top-Level-Statements sowie die logische Vollstaendigkeit der
18 PASS aus der festen 21-Zeilen-Struktur.

**Grenze.** Die Freigabe fuer Schritt 1 ist mit dessen Ausfuehrung verbraucht
und deckte keinen weiteren Schritt. Schritt 2 wurde erst spaeter und getrennt
freigegeben — siehe unten.

#### Schritt 2 — `02_backup_n4_content.sql` (schreibend, ausgefuehrt)

**Freigabe.** Der Benutzer gab Production-N4-Schritt 2 auf
`ydiihvzcxaaoqhmgoqvu` frei. Diese Freigabe deckt ausschliesslich Schritt 2 ab.

**Identitaet der ausgefuehrten Datei.** SHA-256 von
`apps/web/supabase/production_n4_content_fix/02_backup_n4_content.sql`:

```
88b5649c19286c03922f2c8513fef3c3adf240334d79b71f50fef5de5352b900
```

**Ziel, vor der Ausfuehrung geprueft.** `get_project_url` lieferte exakt
`https://ydiihvzcxaaoqhmgoqvu.supabase.co`.

> **Hinweis zur Abweichung von Abschnitt 3, Punkt 1.** Abschnitt 3 verlangt vor
> jedem schreibenden Schritt den sichtbaren Blick in den Supabase-SQL-Editor.
> Bei diesem Lauf fand **kein visueller SQL-Editor-Sichtcheck** statt: Schritt 2
> wurde auf ausdruecklichen Wunsch des Benutzers stattdessen ueber den direkt
> verbundenen Supabase-MCP ausgefuehrt. Als Zielnachweis diente dort
> `get_project_url` unmittelbar vor `execute_sql`, das exakt
> `https://ydiihvzcxaaoqhmgoqvu.supabase.co` lieferte. Das ist eine
> dokumentierte Abweichung fuer genau diesen Lauf — die allgemeine Regel in
> Abschnitt 3 gilt unveraendert weiter.

**Art des Laufs.** Genau ein `execute_sql`-Aufruf. Kein Chrome, kein
`apply_migration`. Auf Git-Seite geschah nichts: kein Git-Commit, kein Merge,
kein Push, kein Deploy. Die SQL-Transaktion der Datei selbst enthaelt
korrekterweise ein `COMMIT`; das ist davon unberuehrt.

**Ergebnis.** Exakt:

```
[{"n4_backup_rows":1}]
```

**Folgenloser erster Anlauf.** Ein erster Worker-Anlauf endete vorher mit
`Claude API Error 529 Overloaded`, ohne Agenten- und ohne MCP-Ausgabe; er hat
Supabase nicht aufgerufen. Danach fand genau **ein** erfolgreicher SQL-Lauf
statt.

**Unabhaengige Nachkontrolle (lokal, kein DB-Zugriff).** Codex pruefte
anschliessend unabhaengig den lokalen SQL-Hash, den Worker-Modus
`supabase_write`, Exit-Code 0, den Auftrag, das Log und den SQL-Inhalt.

**Offen.** Eine unabhaengige Pruefung des Production-Inhalts ist bewusst noch
nicht erfolgt — sie entspricht Schritt 3.

**Grenze.** Schritt 3 und alle weiteren Schritte wurden nicht ausgefuehrt und
bleiben einzeln freigabepflichtig. Vor Schritt 03 gelten unveraendert die
Regeln aus Abschnitt 3.

*(Stand bei Abschluss von Schritt 2. Schritt 3 wurde spaeter und getrennt
freigegeben — siehe unten; damit ist auch der Punkt "Offen" erledigt.)*

#### Schritt 3 — `03_verify_backup_read_only.sql` (read-only, ausgefuehrt)

**Freigabe.** Der Benutzer gab wortwoertlich frei: "Ich gebe
Production-N4-Schritt 3 (read-only Backup-Pruefung) auf ydiihvzcxaaoqhmgoqvu
frei." Diese Freigabe deckt ausschliesslich Schritt 3 ab.

**Identitaet der ausgefuehrten Datei.** SHA-256 von
`apps/web/supabase/production_n4_content_fix/03_verify_backup_read_only.sql`:

```
1c3a4b9e1c08d43b72ca55ff1636b30d98c64b8a88782687b04f5a5494319bae
```

Vorab statisch von Codex geprueft: genau ein lesendes `WITH … SELECT`, kein
DDL, kein DML, keine Transaktionssteuerung.

**Ziel, vor der Ausfuehrung geprueft.** `get_project_url` lieferte exakt
`https://ydiihvzcxaaoqhmgoqvu.supabase.co`.

> **Hinweis zur Abweichung vom Zielcheck aus Abschnitt 3.** Wie schon Schritt 2
> lief auch Schritt 3 auf ausdruecklichen Wunsch des Benutzers direkt ueber den
> verbundenen Supabase-MCP — **ohne visuellen SQL-Editor-Sichtcheck**. Als
> Zielnachweis diente `get_project_url` unmittelbar vor `execute_sql`. Das ist
> eine dokumentierte Abweichung fuer genau diesen Lauf; die allgemeine Regel in
> Abschnitt 3 gilt unveraendert und unabgeschwaecht weiter.

**Art des Laufs.** Genau ein `execute_sql`-Aufruf mit unveraendertem
Dateiinhalt. Kein DDL, kein DML, keine DB-Aenderung.

**Ergebnis: 17 Zeilen, 10 PASS, 7 INFO, 0 FAIL** — exakt die in der Tabelle
"Erwartete Ergebnisse der read-only Schritte" fuer `03` hinterlegte Struktur.
Die harten Befunde:

* Backup vorhanden mit genau 1 Zeile und exakt N4,
* 10/10 erwartete Spalten,
* Drift gegen `public.products` = 0,
* RLS `true`, 0 Policies,
* `PRIMARY KEY (id)` = 1, `UNIQUE (slug)` = 1,
* `anon` und `authenticated` vorhanden,
* direkte **und** effektive Tabellen- sowie Schemarechte fuer `PUBLIC`, `anon`,
  `authenticated` jeweils 0.

**Die 7 INFO-Zeilen.** `current_user` = `postgres`, `current_database` =
`postgres`, sowie `service_role`: vorhanden, `bypassrls = true`, direkte und
effektive Tabellen- und Schemarechte jeweils keine. Damit ist die harte
Abbruchbedingung aus Abschnitt 6.2 fuer `06` nicht ausgeloest.

**Unabhaengige Nachkontrolle (lokal, kein DB-Zugriff).** Codex pruefte
anschliessend den lokalen Hash (unveraendert), den Worker-Exit-Code 0, den
Auftrag, das Log und den Tool-Scope und zaehlte die Logzeilen unabhaengig als
10 PASS, 7 INFO, 0 FAIL nach.

**Grenze (Stand bei Abschluss von Schritt 3, historisch).** An der Datenbank
wurde durch Schritt 3 nichts geaendert. Schritt 4 und alle weiteren Schritte
waren **zu diesem Zeitpunkt** nicht ausgefuehrt und blieben einzeln
freigabepflichtig. Vor Schritt 04 galten unveraendert die Regeln aus
Abschnitt 3, einschliesslich des sichtbaren Zielchecks vor schreibenden
Schritten.

*(Diese Grenze ist ueberholt: Schritt 4 wurde spaeter und getrennt freigegeben
und ausgefuehrt — siehe die unmittelbar folgende Untersektion
"Schritt 4 — `04_correct_n4_content.sql`".)*

#### Schritt 4 — `04_correct_n4_content.sql` (schreibend, ausgefuehrt)

**Freigabe.** Der Benutzer gab wortwoertlich frei: "Ich gebe
Production-N4-Schritt 4 (schreibende N4-Inhaltskorrektur) auf
ydiihvzcxaaoqhmgoqvu frei." Diese Freigabe deckt ausschliesslich Schritt 4 ab.

**Identitaet der ausgefuehrten Datei.** SHA-256 von
`apps/web/supabase/production_n4_content_fix/04_correct_n4_content.sql`:

```
e518fed7bcce6edb750612d4fba5b9ae6897ece0d3c153ea779971198af7d3e3
```

**Ziel, vor der Ausfuehrung geprueft.** `get_project_url` lieferte exakt
`https://ydiihvzcxaaoqhmgoqvu.supabase.co`.

> **Hinweis zur Abweichung vom Zielcheck aus Abschnitt 3.** Wie schon die
> Schritte 2 und 3 lief auch Schritt 4 auf ausdruecklichen Wunsch des Benutzers
> direkt ueber den verbundenen Supabase-MCP — **ohne visuellen
> SQL-Editor-Sichtcheck**. Als Zielnachweis diente `get_project_url`
> unmittelbar vor `execute_sql`. Das ist eine dokumentierte Abweichung fuer
> genau diesen Lauf; die allgemeine Regel in Abschnitt 3 gilt unveraendert und
> unabgeschwaecht weiter.

**Art des Laufs.** Genau ein `execute_sql`-Aufruf mit unveraendertem
Dateiinhalt. Kein SQL- und kein Toolfehler. Kein Chrome, kein
`apply_migration`, keine Datei-, Git-, Branch-, Storage- oder Secret-Aktion
waehrend des SQL-Laufs.

**Ergebnis.** Rohe Rueckgabe exakt:

```
[]
```

**Was der erfolgreiche Abschluss belegt.** Die Datei ist eine atomare
Transaktion und aktualisiert genau die N4-Zeile in `public.products`, dort
genau die sieben Inhaltsfelder plus `updated_at`. Sie enthaelt
Fail-closed-Vorbedingungen, Row-Locks, die Wiederholungspruefungen nach dem
Lock (Abschnitt 6.1) und Nachbedingungen vor `COMMIT`. Jeder Guard- oder
Nachbedingungsfehler haette die Transaktion abgebrochen; der erfolgreiche
Abschluss bedeutet daher, dass die in der Datei enthaltenen Nachbedingungen
bestanden haben.

**Lokaler Testbeleg.** Das unveraenderte Artefakt war Bestandteil des oben
dokumentierten PostgreSQL-Testlaufs mit 94/94 Schritten, 0 Abweichungen,
Exit 0.

**Unabhaengige Nachkontrolle (lokal, kein DB-Zugriff).** Codex pruefte
anschliessend den lokalen Hash (unveraendert), den Worker-Modus, den
Exit-Code 0, den Auftrag, das Log, den Tool-Scope und die SQL-Nachbedingungen.

**Grenze (Stand bei Abschluss von Schritt 4, historisch).** Schritt 5 und alle
weiteren Schritte waren **zu diesem Zeitpunkt** nicht ausgefuehrt und blieben
einzeln freigabepflichtig. Die unabhaengige Production-Nachpruefung des
Zielzustands war ausdruecklich **nicht** Teil dieses Laufs — sie blieb
Schritt 5. Vor Schritt 05 galten unveraendert die Regeln aus Abschnitt 3.

*(Diese Grenze ist ueberholt: Schritt 5 wurde spaeter und getrennt freigegeben
und ausgefuehrt — siehe die unmittelbar folgende Untersektion
"Schritt 5 — `05_verify_read_only.sql`". Damit ist die dort als offen
bezeichnete Nachpruefung erledigt.)*

#### Schritt 5 — `05_verify_read_only.sql` (read-only, ausgefuehrt)

**Freigabe.** Der Benutzer gab wortwoertlich frei: "Ich gebe
Production-N4-Schritt 5 (read-only Abschlusspruefung) auf ydiihvzcxaaoqhmgoqvu
frei." Diese Freigabe deckt ausschliesslich Schritt 5 ab.

**Identitaet der ausgefuehrten Datei.** SHA-256 von
`apps/web/supabase/production_n4_content_fix/05_verify_read_only.sql`:

```
be7db519aeb8b2bda722418790c553941b5aa9ed22b9bd94e24517f1b527c1cb
```

Vorab statisch von Codex geprueft: genau ein lesendes `WITH … SELECT`, kein
DDL, kein DML, keine Transaktionssteuerung.

**Ziel, vor der Ausfuehrung geprueft.** `get_project_url` lieferte exakt
`https://ydiihvzcxaaoqhmgoqvu.supabase.co`.

> **Hinweis zur Abweichung vom Zielcheck aus Abschnitt 3.** Wie schon die
> Schritte 2 bis 4 lief auch Schritt 5 auf ausdruecklichen Wunsch des Benutzers
> direkt ueber den verbundenen Supabase-MCP — **ohne visuellen
> SQL-Editor-Sichtcheck**. Als Zielnachweis diente `get_project_url`
> unmittelbar vor `execute_sql`. Das ist eine dokumentierte Abweichung fuer
> genau diesen Lauf; die allgemeine Regel in Abschnitt 3 gilt unveraendert und
> unabgeschwaecht weiter.

**Art des Laufs.** Genau ein `execute_sql`-Aufruf mit unveraendertem
Dateiinhalt. Kein DDL, kein DML, keine DB-Aenderung.

**Ergebnis: 26 Zeilen, 18 PASS, 8 INFO, 0 FAIL** — exakt die in der Tabelle
"Erwartete Ergebnisse der read-only Schritte" fuer `05` hinterlegte Struktur.
Die harten Befunde:

* N4 genau 1x und `is_published = true`,
* alle sieben Zieltextfelder jeweils 1 und der Gesamtzieltext 1,
* Backup weiterhin 1 Zeile und exakt der unveraenderte Vorzustand,
* die vier bewusst nicht geaenderten N4-Value-Add-Felder gegen den Payload 1,
* neun uebrige Pilotzeilen und 0 Abweichungen,
* Backup RLS `true`, 0 Policies,
* App-Rollen 2/2 (`anon`, `authenticated`),
* direkte **und** effektive Tabellen- sowie Schemarechte fuer `PUBLIC`, `anon`,
  `authenticated` jeweils 0,
* `updated_at` neuer als im Backup = 1.

**Die 8 INFO-Zeilen.** `current_user` = `postgres`, `current_database` =
`postgres`, der aktuelle N4-Text ohne konkrete Laufzeit- und ohne
Amortisationszusage, sowie `service_role`: vorhanden, `bypassrls = true`,
direkte und effektive Tabellen- und Schemarechte jeweils keine.

**Unabhaengige Nachkontrolle (lokal, kein DB-Zugriff).** Codex zaehlte die
Logzeilen unabhaengig als 18 PASS, 8 INFO, 0 FAIL nach und pruefte den lokalen
Hash, den Worker-Exit-Code 0, den Auftrag, das Log, den Tool-Scope und die
unveraenderten Artefakte.

**Abschlussstatus.** An der Datenbank wurde durch Schritt 5 nichts geaendert.
Die N4-Korrektur aus Schritt 4 ist damit auf Production **unabhaengig
verifiziert**; die in den Schritten 2 bis 4 als offen gefuehrte Nachpruefung ist
erledigt. `06` (Restore) wurde nicht ausgefuehrt und ist bei 0 FAIL auch nicht
angezeigt: Es ist **nicht** auszufuehren, ausser es wird spaeter ausdruecklich
ein Rollback gewuenscht und dafuer eine eigene Freigabe erteilt. `06` bleibt
ausschliesslich ein separat freigabepflichtiger Notfall- und Rollbackpfad; die
Regeln aus Abschnitt 3 gelten dafuer unveraendert.

---

## 4. Erwartete Tabellen

### Vorausgesetzt (muessen existieren)

| Tabelle | Erwartung |
|---------|-----------|
| `public.products` | >= 300 Zeilen, N4 genau 1x und `is_published = true` |
| `public.page_content` | existiert (Production-Fingerprint) |
| `public.discovery_queue` | existiert (Production-Fingerprint) |
| `public.swipes` | existiert (Production-Fingerprint) |
| `cbb_private_backup.value_add_pre_backfill_v1` | genau 10 Zeilen |
| `cbb_private_backup.value_add_payload_v1` | genau 10 Zeilen, N4-Zeile befuellt |
| 8 Value-Add-Spalten + 2 CHECK-Constraints auf `public.products` | vollstaendig |

### Muessen fehlen

| Objekt | Grund |
|--------|-------|
| `pilot_meta.environment_guard` | Pilot-Marker — Abbruch, falls vorhanden |
| `pilot_backup.value_add_pre_backfill` | Pilot-Marker — Abbruch, falls vorhanden |
| `public.pilot_value_add_backup_20260823` | Pilot-Marker — Abbruch, falls vorhanden |
| `cbb_private_backup.n4_content_pre_fix_v1` | darf vor Schritt 2 nicht existieren |

### Neu angelegt (Schritt 2)

`cbb_private_backup.n4_content_pre_fix_v1` — genau **1 Zeile**, genau
**10 Spalten**:

```
id, slug, updated_at,
tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
```

Absicherung: `PRIMARY KEY (id)`, `UNIQUE (slug)`, RLS aktiv, 0 Policies,
`REVOKE ALL` auf Schema und Tabelle fuer `PUBLIC`, `anon`, `authenticated` —
und fuer `service_role`, falls die Rolle existiert.

> **Bekannte Nebenwirkung, bewusst so gewaehlt:** das `REVOKE ALL ON SCHEMA
> cbb_private_backup FROM service_role` wirkt auf das ganze private
> Backup-Schema, also auch auf die beiden Value-Add-Artefakte darin. Fuer den
> Betrieb ist das folgenlos — die App liest ausschliesslich mit `anon` bzw.
> `authenticated`, und alle Runbook-Schritte laufen im SQL-Editor als
> `postgres`, nicht als `service_role`. Wer die Value-Add-Snapshots
> ausdruecklich als `service_role` lesen koennen muss, braucht dafuer einen
> eigenen, getrennt freigegebenen Grant-Vorgang.

Das Backup wird von **keiner** Datei dieses Pakets automatisch geloescht, auch
nicht nach einem Restore. Es bleibt Audit-Artefakt bis zum Ende des
Beobachtungsfensters und wird erst danach in einem eigenen, getrennt
freigegebenen Vorgang entfernt.

---

## 5. Rollback

`06_restore_n4_content.sql` spielt exakt die gesicherten Felder zurueck —
**einschliesslich des historischen `updated_at`**. Nach dem Restore ist der
Stand vor der Korrektur wiederhergestellt, inklusive des alten `lastmod`-Werts
fuer die Sitemap.

Eigenschaften:

* wiederholbar — ein zweiter Lauf aendert nichts mehr und bricht nicht ab,
* fail closed bei fehlendem, leerem, **inhaltlich abweichendem** oder
  unsicherem Backup (Details in Abschnitt 6.2),
* laesst das Backup stehen — auch ein manipuliertes wird weder ueberschrieben
  noch "repariert", sondern nur zum Abbruch gemeldet,
* prueft Backup-Inhalt und Identitaet **nach** dem Row-Lock erneut,
* danach ist der erwartete Vorzustand wieder gegeben, `04` darf also erneut
  laufen (mit neuer Freigabe).

`products` wird von `06` bewusst **nicht** gegen den Vorzustand geprueft — der
Restore soll ja gerade aus dem korrigierten Stand zurueckfuehren. Geprueft wird
die Datenquelle des Schreibvorgangs, also das Backup.

Fehler **waehrend** eines schreibenden Schritts brauchen keinen Rollback: `02`,
`04` und `06` laufen jeweils in genau einer Transaktion. Bricht ein Guard oder
eine Nachbedingung ab, ist nichts geschrieben worden.

`04` legt kein DDL an und aendert kein Schema — es gibt daher keine
Down-Migration in diesem Paket. Der Schema-Rollback des Value-Add-Rollouts
(`production_value_add/07_down_migration.sql`) bleibt davon unberuehrt, setzt
aber voraus, dass zuvor **beide** Restores gelaufen sind: erst
`production_n4_content_fix/06`, dann `production_value_add/06`.

---

## 6. Fail-closed-Verhalten im Ueberblick

| Situation | Reaktion |
|-----------|----------|
| Pilot-Artefakt gefunden | Abbruch in `02`, `04`, `06` |
| Production-Fingerprint unvollstaendig | Abbruch in `02`, `04`, `06` |
| < 300 Produkte | Abbruch in `02`, `04`, `06` |
| N4 nicht genau 1x published | Abbruch in `02`, `04` |
| Value-Add-Schema nicht 8/8 + 2/2 | Abbruch in `02`, `04` |
| Value-Add-Marker fehlen oder ungleich 10 Zeilen | Abbruch in `02`, `04` |
| N4-Vorzustand weicht ab | Abbruch in `02`, `04` |
| Backup existiert bereits | Abbruch in `02` |
| Backup fehlt / leer / manipuliert / unsicher | Abbruch in `04`, `06` |
| Backup-Inhalt ist nicht der bekannte Vorzustand | Abbruch in `04`, `06` — auch **vor** dem Restore, siehe unten |
| `anon`/`authenticated` haben Rechte am Backup — direkt **oder** geerbt | Abbruch in `06` |
| `service_role` hat Rechte am Backup — direkt **oder** geerbt | Abbruch in `06` |
| `anon` oder `authenticated` existiert gar nicht | Abbruch in `06` (Rechtepruefung waere nicht aussagekraeftig) |
| Zielzeile driftet zwischen Vorpruefung und Schreiben | Abbruch nach dem Row-Lock, siehe unten |
| Backup driftet zwischen Vorpruefung und Schreiben | Abbruch nach dem Row-Lock in `04` und `06` |
| Konkurrierender `AccessExclusiveLock` | Abbruch nach `lock_timeout = '5s'` |
| Statement laeuft > 60 s | Abbruch durch `statement_timeout = '60s'` |
| `03` oder `05` ohne vorhandenes Backup | Planungsabbruch, `relation … does not exist` |

Die beiden `set local`-Zeilen stehen in `02`, `04` und `06` **direkt hinter
`begin;`** und **vor dem ersten DO-Block**. Sonst wuerde der erste
`select count(*) from public.products` im Guard mit dem Session-Default
`lock_timeout = 0` unbegrenzt auf eine konkurrierende Sperre warten. Der
Harness prueft diese Position statisch.

### 6.1 Der Row-Lock ist die Grenze, nicht die Vorpruefung

Alle Guards, die **vor** dem Row-Lock laufen, lesen ohne Sperre. Zwischen so
einer Vorpruefung und dem Schreiben darf eine konkurrierende Transaktion
jederzeit committen. Vorpruefungen sind deshalb nur ein billiger Vorfilter;
verbindlich ist ausschliesslich, was **nach** dem erfolgreichen Lock erneut
geprueft wird.

| Datei | sperrt | prueft danach erneut |
|-------|--------|----------------------|
| `02` | die N4-Produktzeile | **alle sieben** Inhaltsfelder, `id`, `slug`, `is_published` — erst danach entsteht die Backup-Tabelle |
| `04` | die N4-Produktzeile **und** die Backup-Zeile | (a) alle sieben Product-Vorwerte, (b) Backup = bekannter Vorzustand, (c) Driftfreiheit `products` ↔ Backup inkl. `id`, `slug`, `updated_at` — erst danach das `UPDATE` |
| `06` | die N4-Produktzeile **und** die Backup-Zeile | Backup = bekannter Vorzustand, Identitaet `products` ↔ Backup — erst danach das `UPDATE` |

Vorher war das in `02` unvollstaendig (nach dem Lock wurden nur `tagline` und
`description` erneut geprueft, nicht `nicht_fuer`, `key_fact`, `pros`, `cons`,
`editorial_note`) und in `04` gar nicht vorhanden. Beides ist behoben.

Warum das nicht theoretisch ist: `pros`, `cons`, `nicht_fuer` und `key_fact`
stehen **nicht** in der Spaltenliste des Triggers `products_set_updated_at`.
Eine konkurrierende Aenderung an ihnen laesst `updated_at` unveraendert — ein
reiner Zeitstempelvergleich haette sie also nicht bemerkt. Die vollstaendigen
Inhalts- und Driftvergleiche nach erworbenem Lock erfassen sie dagegen; genau
das belegen die Konkurrenzfaelle des lokalen Harnesses fuer `pros` (`02`) und
`nicht_fuer` (`04`).

### 6.2 `06` glaubt dem Backup nicht

`06` ist der einzige Schritt, der Backup-Inhalt **nach** `public.products`
schreibt. Ein manipuliertes Backup waere damit unmittelbar Seiteninhalt.
Deshalb prueft `06` vor jedem Schreibvorgang:

1. **Inhalt** — das Backup muss exakt den bekannten Vorzustand tragen
   (dieselben sieben Literale wie in `02` und `04`). Weicht ein Feld ab, wird
   nichts geschrieben.
2. **Privatheit** — RLS aktiv, 0 Policies, und fuer `PUBLIC`, `anon`,
   `authenticated` **null** Rechte auf Tabelle *und* Schema, gemessen
   **doppelt**: direkte ACL-Eintraege (`aclexplode`) *und* effektive Rechte
   (`has_table_privilege` / `has_schema_privilege`). Die zweite Messung ist die
   wichtige — ein Recht, das nur ueber eine Rollenmitgliedschaft geerbt ist,
   taucht in den direkten ACLs gar nicht auf. Existiert `service_role`, gilt
   dieselbe Null-Forderung fuer sie. Fehlt `anon` oder `authenticated`, bricht
   `06` ab, statt aus "keine Rolle" ein "keine Rechte" zu machen.
3. **Nach dem Lock noch einmal** — Inhalt und Identitaet werden nach dem
   erfolgreichen Row-Lock wiederholt geprueft.

`service_role` ist damit in `06` eine **harte** Abbruchbedingung, waehrend sie
in `03` und `05` nur als INFO-Zeile erscheint. Der Unterschied ist Absicht:
`03` und `05` berichten, `06` schreibt. Praktische Folge: wenn `03` fuer
`service_role` etwas anderes als "keine" meldet, wird `06` fail closed
abbrechen. Das ist gewollt — es ist dann ein eigener, getrennt freizugebender
Grant-Vorgang noetig, kein stiller Restore ueber ein Backup, das eine
BYPASSRLS-Rolle vorher haette veraendern koennen.

---

## 7. Zusaetzlich im selben Vorgang: die statische Guide-Kopie

`lib/guides/beste-kuechen-gadgets-2026.ts` enthielt denselben Fehler als
statischen Text ("in 15 Minuten … Amortisiert sich nach 2 Monaten"). Der
N4-Absatz wurde auf denselben Sachstand korrigiert. Das ist eine reine
Code-Aenderung im Repo, kein Datenbankvorgang, und braucht keine
Datenbankfreigabe — wohl aber ein Review vor jedem Deploy.

Es wurde ausschliesslich dieser eine Absatz geaendert. Kein weiterer Text,
keine `productSlugs`, keine andere Datei.

---

## 8. Ausserhalb des Umfangs

* Keine Aenderung an `supabase/production_value_add/01` bis `07` und nicht an
  deren Test-Harness.
* Keine Aenderung an anderen Produktzeilen, auch nicht an den uebrigen neun
  Value-Add-Pilotprodukten.
* Kein `price_cents`, kein `image_url`, kein `affiliate_url`.
* Kein Loeschen von Backup- oder Audit-Artefakten.
* Keine Veroeffentlichung, kein Deploy, kein Git-Commit.
