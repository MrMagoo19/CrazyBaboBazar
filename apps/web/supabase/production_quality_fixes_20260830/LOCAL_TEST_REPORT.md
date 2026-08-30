# Lokaler Testbericht — Production-Quality-Fixes 2026-08-30

**Stand:** 2026-08-30, nach der zweiten Opus-Endpruefung und unabhaengigem
Codex-Vollauf

**Harness:** `test/run_local_postgres_test.sh`
**Zielprojekt des Changesets:** `project/ydiihvzcxaaoqhmgoqvu` (nicht beruehrt)

## Ergebnis

> [!success] LOKALES GATE FUER DEN AKTUELLEN STAND: **BESTANDEN**
> **164/164 PASS**, **0 Abweichungen**, Records=164, STEP=164,
> Coverage-Assertion PASS, Exit **0**, PostgreSQL **16.15**. Ergebnisdatei:
> `/tmp/cbb-qftest.Z3T0ySL7/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.Z3T0ySL7/logs/`.

Der wegwerfbare lokale Cluster wurde danach sauber gestoppt; PGDATA und
Socketverzeichnis wurden entfernt, die Logs bleiben erhalten. Kein Paket-SQL
lief gegen Production oder Pilot/Staging.

## Was seit dem 160er-Lauf hinzugekommen ist

| Aenderung | Wirkung auf den Lauf |
|---|---|
| `01`: kommentarbereinigter, geordneter Guard-Zuweisungs-Nachweis; `:=` und `=` werden gezaehlt | keine neue Reportzeile; schaerferer Inhalt der bestehenden Vertragszeile |
| `case_k_triggervertrag`: positiver Kommentarfall und negativer Dummy-Guard mit bedingungsloser `=`-Zuweisung | +4 Schritte |
| Coverage-Assertion | prueft jetzt Records **und** `STEP` hart gegen `ERWARTETE_SCHRITTE=164` |

Damit steigt das Soll von 160 auf **164 Schritte**.

## Laufhistorie

| Lauf | Stand | Ergebnis | Artefakte |
|---|---|---|---|
| aktueller Paketstand | nach zweiter Opus-Endpruefung | **164/164 PASS, 0 Abweichungen, Records=STEP=164, Coverage PASS, Exit 0, PostgreSQL 16.15** | `/tmp/cbb-qftest.Z3T0ySL7/results.tsv`, Logs unter `/tmp/cbb-qftest.Z3T0ySL7/logs/` |
| 160 Schritte | Commit `250ad42` | 160/160 PASS, 0 Abweichungen, Coverage PASS, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.549lsB6T/results.tsv`, Logs unter `/tmp/cbb-qftest.549lsB6T/logs/` |
| 145 Schritte | nach der A4-Erweiterung | 145/145 PASS, 0 Abweichungen, Exit 0, PostgreSQL 16.15 | `/tmp/cbb-qftest.AgI5UJsx/results.tsv`, Logs unter `/tmp/cbb-qftest.AgI5UJsx/logs/` |
| 119 Schritte | vor der A4-Erweiterung | 119/119 PASS, 0 Abweichungen, Exit 0 | `/tmp/cbb-qftest.qWvTWbdG/results.tsv` |

Der 164er-Lauf belegt den aktuellen nachgehaerteten Stand. Die historischen
Laeufe kannten jeweils einen kleineren Test- und Guard-Umfang.

## Abgedeckter Stand (bestandener 164er-Lauf)

- genau sieben Produkt- und drei Listen-Zielzeilen;
- A4-Unterkategorie `basteln -> gadgets`, wobei `updated_at` nachweislich
  unveraendert bleibt;
- neues `updated_at` nur fuer die sechs sichtbar geaenderten Produktseiten;
- der deployte `updated_at`-Triggervertrag auf `public.products`, gemessen im
  Systemkatalog, kommentarbereinigt, mit geordneter Guard-Zuweisungs-Struktur,
  vierfach negativ und mit positivem Kommentarfall gegengeprueft;
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
