# Lokaler Testbericht — Production-Quality-Fixes 2026-08-30

**Stand:** 2026-08-30, definitiver Codex-Vollauf nach der Erweiterung

**Harness:** `test/run_local_postgres_test.sh`
**Zielprojekt des Changesets:** `project/ydiihvzcxaaoqhmgoqvu` (nicht beruehrt)

## Ergebnis

> [!info] LOKALES GATE VOLLSTAENDIG GRUEN
> PostgreSQL **16.15**, **145/145 PASS**, **0 Abweichungen**, Exit **0**.
> Ergebnisdatei: `/tmp/cbb-qftest.AgI5UJsx/results.tsv`; Einzelprotokolle:
> `/tmp/cbb-qftest.AgI5UJsx/logs/`.

Der Harness startete einen wegwerfbaren lokalen Cluster ausschliesslich ueber
einen Unix-Socket (`listen_addresses=''`). Nach dem Lauf wurde PostgreSQL
sauber gestoppt; PGDATA und Socketverzeichnis wurden entfernt. Production und
Pilot/Staging wurden nicht verbunden oder beschrieben.

## Abgedeckter Stand

- genau sieben Produkt- und drei Listen-Zielzeilen;
- A4-Unterkategorie `basteln -> gadgets`, wobei `updated_at` nachweislich
  unveraendert bleibt;
- neues `updated_at` nur fuer die sechs sichtbar geaenderten Produktseiten;
- harte Vorbedingungen fuer `anon` und `authenticated`;
- direkte und geerbte Backup-Rechte auf Tabellen und Schema;
- `updated_at IS NULL` vor Backup, Apply und Restore;
- dieselben Zeitstempel-Guards in den fruehen No-Op-Pfaden von `02`, `04`
  und `06`;
- falscher Vorzustand, Drift, Mischzustand, fehlende Zeile, manipuliertes,
  leeres oder halbes Backup;
- echte konkurrierende Aenderungen, Lock-Timeout, Idempotenz und exakter
  Restore-Round-Trip.

Die read-only Reports wurden mit exakten Zaehlern geprueft:

| Datei | Erwartung | Ergebnis |
|---|---|---|
| `01_preflight_read_only.sql` | 22 PASS, 0 FAIL | PASS |
| `03_verify_backup_read_only.sql` | 16 PASS, 0 FAIL | PASS |
| `05_verify_read_only.sql` | 23 PASS, 0 FAIL | PASS |

## Laufhistorie

Der fruehere Lauf `/tmp/cbb-qftest.qWvTWbdG` bestand mit **119/119 PASS**,
0 Abweichungen und Exit 0, gilt aber nur fuer den Paketstand vor der
Erweiterung. Der oben dokumentierte Lauf mit 145 Schritten ist der verbindliche
Nachweis fuer den aktuellen lokalen Stand.

## Freigabegrenze

Ein lokaler PASS ist keine Production-Freigabe. Kein Paket-SQL wurde gegen
Production oder Pilot/Staging ausgefuehrt. Jeder Production-Schritt bleibt
einzeln freigabepflichtig; Preis und Bild-URLs sind unmittelbar vor Schritt
`04` erneut read-only zu pruefen.
