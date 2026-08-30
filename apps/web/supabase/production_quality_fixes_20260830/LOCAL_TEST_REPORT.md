# Lokaler Testbericht — Production-Quality-Fixes 2026-08-30

**Stand:** 2026-08-30, nach den Korrekturen aus der Opus-Endpruefung und
unabhaengigem Codex-Vollauf

**Harness:** `test/run_local_postgres_test.sh`
**Zielprojekt des Changesets:** `project/ydiihvzcxaaoqhmgoqvu` (nicht beruehrt)

## Ergebnis

> [!success] LOKALES GATE FUER DEN AKTUELLEN STAND: **BESTANDEN**
> **160/160 PASS**, **0 Abweichungen**, Coverage-Assertion PASS, Exit **0**,
> PostgreSQL **16.15**. Ergebnisdatei:
> `/tmp/cbb-qftest.549lsB6T/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.549lsB6T/logs/`.

Der wegwerfbare lokale Cluster wurde danach sauber gestoppt; PGDATA und
Socketverzeichnis wurden entfernt, die Logs bleiben erhalten. Kein Paket-SQL
lief gegen Production oder Pilot/Staging.

## Was seit dem letzten ausgefuehrten Lauf hinzugekommen ist

| Aenderung | Wirkung auf den Lauf |
|---|---|
| `01`: Katalogpruefung `products_updated_at_triggervertrag` (Sortierung 156) | `01` erwartet jetzt **23** statt 22 PASS-Zeilen, 29 statt 28 Zeilen |
| `case_k_triggervertrag` — Vertrag dreimal gebrochen, zweimal Kontrolle | +9 Schritte |
| `02`: Zeilenidentitaet (`id` UND `slug`) im No-Op-Zweig, fail-closed | keine neue Erwartung in bestehenden Faellen |
| `case_di_backup_identitaet` — Backup mit fremder Zeilen-`id` | +6 Schritte |
| Coverage-Assertion `ERWARTETE_SCHRITTE=160` am Ende des Harness | kein eigener `results.tsv`-Record; prueft die Gesamtzahl der geschriebenen Records |

Damit steigt das Soll von 145 auf **160 Schritte**.

## Laufhistorie

| Lauf | Stand | Ergebnis | Artefakte |
|---|---|---|---|
| aktueller Paketstand | nach Opus-Korrekturen | **160/160 PASS, 0 Abweichungen, Coverage PASS, Exit 0, PostgreSQL 16.15** | `/tmp/cbb-qftest.549lsB6T/results.tsv`, Logs unter `/tmp/cbb-qftest.549lsB6T/logs/` |
| 145 Schritte | nach der A4-Erweiterung | 145/145 PASS, 0 Abweichungen, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.AgI5UJsx/results.tsv`, Logs unter `/tmp/cbb-qftest.AgI5UJsx/logs/` |
| 119 Schritte | vor der A4-Erweiterung | 119/119 PASS, 0 Abweichungen, Exit 0 | `/tmp/cbb-qftest.qWvTWbdG/results.tsv` |

Der 160er-Lauf belegt den heutigen Stand. Die beiden historischen Laeufe
kannten weder die Triggervertrags-Pruefzeile noch die Identitaetspruefung im
No-Op-Zweig von `02` noch die Coverage-Assertion.

## Abgedeckter Stand (bestandener 160er-Lauf)

- genau sieben Produkt- und drei Listen-Zielzeilen;
- A4-Unterkategorie `basteln -> gadgets`, wobei `updated_at` nachweislich
  unveraendert bleibt;
- neues `updated_at` nur fuer die sechs sichtbar geaenderten Produktseiten;
- der deployte `updated_at`-Triggervertrag auf `public.products`, gemessen im
  Systemkatalog und dreifach negativ gegengeprueft;
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
