# Lokaler Testbericht — Production-Quality-Fixes 2026-08-30

**Stand:** 2026-08-30, nach Umsetzung der sechs Befunde aus der **dritten**
Opus-Endpruefung und unabhaengigem Codex-Vollauf

**Harness:** `test/run_local_postgres_test.sh`
**Zielprojekt des Changesets:** `project/ydiihvzcxaaoqhmgoqvu` (nicht beruehrt)

## Ergebnis

> [!success] LOKALES GATE FUER DEN AKTUELLEN STAND: **BESTANDEN**
> **166/166 PASS**, **0 Abweichungen**, Records=166, STEP=166,
> Coverage-Assertion PASS, Exit **0**, PostgreSQL **16.15**. Ergebnisdatei:
> `/tmp/cbb-qftest.TBdYphBg/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.TBdYphBg/logs/`.

> [!note] Historie, gilt **nicht** fuer den aktuellen Stand
> Der 164er-Lauf belegt genau Commit `179ef1f`: **164/164 PASS**,
> **0 Abweichungen**, Records=164, STEP=164, Coverage-Assertion PASS, Exit
> **0**, PostgreSQL **16.15**. Ergebnisdatei:
> `/tmp/cbb-qftest.v85MjgLU/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.v85MjgLU/logs/`.

Der wegwerfbare lokale Cluster wurde nach dem aktuellen Lauf sauber gestoppt;
PGDATA und Socketverzeichnis wurden entfernt, die Logs bleiben erhalten. Kein
Paket-SQL lief gegen Production oder Pilot/Staging.

## Was seit dem 164er-Stand (`179ef1f`) hinzugekommen ist

| Aenderung | Wirkung auf den Lauf |
|---|---|
| `01`: die beiden Zaehlungen des Triggervertrags laufen nicht mehr ueber `pg_catalog.regexp_count()` (erst ab PostgreSQL 15), sondern read-only ueber `regexp_matches(…, 'g')` in einem `CROSS JOIN LATERAL` | keine neue Reportzeile; keine undokumentierte Mindestversion mehr, auf PostgreSQL 16.15 unveraendert |
| `01`: die Zuweisungen werden **positionsunabhaengig** gezaehlt — jedes `new.updated_at := / =` im bereinigten Rumpf, egal ob nach `begin`, `then`, `else`, `loop` oder `;`. Ein Vergleich `new.updated_at = …` zaehlt fail-closed mit | keine neue Reportzeile; schaerferer Inhalt der bestehenden Vertragszeile |
| `01`: Zeilenkommentare werden jetzt **vor** Blockkommentaren entfernt, damit `-- … /*` und spaeter `-- … */` keinen echten Code dazwischen verschlucken koennen | keine neue Reportzeile; verhindert ein falsches PASS |
| `01`: die geordnete Regex akzeptiert auch den minimal gueltigen Guard ohne zusaetzliche AND-Bedingung; die Reihenfolge Guard → `THEN` → Zuweisung → `END IF` bleibt hart | keine neue Reportzeile |
| `case_k_triggervertrag`: neuer Negativfall `setup_trigger_zweite_zuweisung_in_schleife.sql` — korrekter Guard, danach zweite bedingungslose Zuweisung in einer `LOOP`; `01` muss FAIL liefern | **+2 Schritte** |
| `case_k_triggervertrag`: der bestehende Sub-Category-Negativfall versteckt seinen gefaehrlichen Code jetzt zwischen `-- … /*` und `-- … */` und ist damit zugleich die Gegenprobe auf die Reihenfolge der Kommentarbereinigung | keine zusaetzlichen Schritte |
| Coverage-Assertion | prueft Records **und** `STEP` hart gegen `ERWARTETE_SCHRITTE=166` |

Damit steigt das Soll von 164 auf **166 Schritte**.

## Laufhistorie

| Lauf | Stand | Ergebnis | Artefakte |
|---|---|---|---|
| aktueller Paketstand (166 Schritte) | nach Umsetzung der sechs Befunde aus der dritten Opus-Endpruefung | **166/166 PASS, 0 Abweichungen, Records=STEP=166, Coverage PASS, Exit 0, PostgreSQL 16.15** | `/tmp/cbb-qftest.TBdYphBg/results.tsv`, Logs unter `/tmp/cbb-qftest.TBdYphBg/logs/` |
| 164 Schritte | Commit `179ef1f` | 164/164 PASS, 0 Abweichungen, Records=STEP=164, Coverage PASS, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.v85MjgLU/results.tsv`, Logs unter `/tmp/cbb-qftest.v85MjgLU/logs/` |
| 160 Schritte | Commit `250ad42` | 160/160 PASS, 0 Abweichungen, Coverage PASS, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.549lsB6T/results.tsv`, Logs unter `/tmp/cbb-qftest.549lsB6T/logs/` |
| 145 Schritte | nach der A4-Erweiterung | 145/145 PASS, 0 Abweichungen, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.AgI5UJsx/results.tsv`, Logs unter `/tmp/cbb-qftest.AgI5UJsx/logs/` |
| 119 Schritte | vor der A4-Erweiterung | 119/119 PASS, 0 Abweichungen, Exit 0 | `/tmp/cbb-qftest.qWvTWbdG/results.tsv` |

Der 166er-Lauf belegt den aktuellen Stand. Die historischen Laeufe kannten
jeweils einen kleineren Test- und Guard-Umfang.

## Umfang des bestandenen 166er-Laufs

- genau sieben Produkt- und drei Listen-Zielzeilen;
- A4-Unterkategorie `basteln -> gadgets`, wobei `updated_at` nachweislich
  unveraendert bleibt;
- neues `updated_at` nur fuer die sechs sichtbar geaenderten Produktseiten;
- der deployte `updated_at`-Triggervertrag auf `public.products`, gemessen im
  Systemkatalog, von **Block- und Zeilenkommentaren** bereinigt (Zeilen- vor
  Blockkommentaren), mit geordneter Guard-Zuweisungs-Struktur und
  positionsunabhaengiger Zaehlung der Zuweisungen, **fuenffach** negativ und
  mit positivem Kommentarfall gegengeprueft;
- harte Vorbedingungen fuer `anon` und `authenticated`;
- direkte und geerbte Backup-Rechte auf Tabellen und Schema;
- `updated_at IS NULL` vor Backup, Apply und Restore;
- dieselben Zeitstempel-Guards in den fruehen No-Op-Pfaden von `02`, `04`
  und `06`;
- Zeilenidentitaet des Backups ueber `id` UND `slug` in `02`, `04` und `06`;
- falscher Vorzustand, Drift, Mischzustand, fehlende Zeile, manipuliertes,
  leeres oder halbes Backup, Backup mit fremder Zeilen-`id`;
- echte konkurrierende Aenderungen, Lock-Timeout, Idempotenz und exakter
  Restore-Round-Trip;
- die Vollstaendigkeit des Laufs selbst (Coverage-Assertion).

Die read-only Reports sind mit exakten Zaehlern zu pruefen:

| Datei | Erwartung |
|---|---|
| `01_preflight_read_only.sql` | 23 PASS, 0 FAIL |
| `03_verify_backup_read_only.sql` | 16 PASS, 0 FAIL |
| `05_verify_read_only.sql` | 23 PASS, 0 FAIL |

## Sicherheitsrahmen des Harness

Der Harness startet einen wegwerfbaren lokalen Cluster ausschliesslich ueber
einen Unix-Socket (`listen_addresses=''`) und stoppt ihn per `trap`; PGDATA und
Socketverzeichnis werden danach entfernt. Er kennt weder Host noch Projekt-Ref
von Production oder Pilot/Staging.

## Freigabegrenze

Ein lokaler PASS ist keine Production-Freigabe. Kein Paket-SQL wurde gegen
Production oder Pilot/Staging ausgefuehrt. Jeder Production-Schritt bleibt
einzeln freigabepflichtig; Preis und Bild-URLs sind unmittelbar vor Schritt
`04` erneut read-only zu pruefen.
