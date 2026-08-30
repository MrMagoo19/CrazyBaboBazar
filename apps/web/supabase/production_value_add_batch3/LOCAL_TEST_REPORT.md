# Lokaler Testbericht — Value-Add Charge 3

**Stand:** 2026-08-28, nach dem vollstaendigen Stufe-1- und Stufe-2-Lauf von
Codex sowie der anschliessenden Guard-Korrektur und dem vollstaendigen
Wiederholungslauf

**Harness:** `test/run_local_postgres_test.sh`
**Zielprojekt des Changesets:** `project/ydiihvzcxaaoqhmgoqvu` (nicht beruehrt)

---

## 1 · Ergebnis in einem Satz

> [!info] LOKALES GATE 0 IST VOLLSTAENDIG BELEGT GRUEN
> Codex hat den aktuellen Dateistand gegen einen wegwerfbaren PostgreSQL-16-
> Cluster geprueft: **108/108 PASS, 0 Abweichungen, Exit 0**. Darin enthalten
> sind **19/19 statische Pruefungen**, Manifest **74/74 `OK`** und alle
> Datenbank-/Negativfaelle. Der **Production-Hold bleibt trotzdem bestehen**:
> Ein lokaler PASS ist keine Freigabe fuer Production.

---

## 2 · Was wann tatsaechlich lief

| Zeitpunkt | Was | Ergebnis |
|---|---|---|
| 2026-08-28, finaler Wiederholungslauf | Stufe 1 und Stufe 2 gegen PostgreSQL 16, ausgefuehrt von Codex | **108/108 PASS**, 0 Abweichungen, Manifest **74/74 `OK`**, Exit 0. Ergebnisdatei: `/tmp/cbb-pgtest-b3.HnCpYwau/results.tsv`. |
| 2026-08-28, erster vollstaendiger DB-Lauf | Stufe 1 und Stufe 2 | Zwei echte Guard-Reihenfolgefehler gefunden: `b_03_wiederholung` traf den globalen 30-Zeilen-Guard vor dem spezifischen vorhandenen v3-Payload; `m_02_abbruch` traf den globalen 21-Zeilen-Guard vor dem spezifischen Guard fuer vorbefuellte Zielzeilen. |
| 2026-08-28, Korrekturrunde | Claude-Worker, danach unabhaengiger Codex-Audit | Nur die Guard-Reihenfolge wurde korrigiert: spezifische v3-/Zielzustandspruefungen laufen jetzt vor den globalen Mengen-Guards. Der finale Lauf in Zeile 1 belegt beide Korrekturen. |

Die bereits zuvor quellenpraezisierte Payload-Formulierung zur Bartesian-
Cocktailmaschine ist im final geprueften Byte-Stand enthalten. Es gibt damit
keine Aenderung nach dem belegten Lauf.

---

## 3 · Was auch ohne Harness belegt ist

Diese Punkte liessen sich rein lesend pruefen:

| Beleg | Ergebnis |
|---|---|
| Kein Vorgaenger-Artefakt veraendert | Kein Byte unter `production_value_add/` oder `production_value_add_batch2/` wurde angefasst — auch nicht in der Korrekturrunde. `V1_V2_MANIFEST.sha256` (74 Dateien) ist selbst unveraendert; der Stufe-1-Lauf aus Abschnitt 2 hat die 74/74 `OK` bestaetigt. |
| Zielmenge weiterhin genau 10 und disjunkt | `bartesian-cocktailmaschine-mit-kapseln` steht in keiner der zwanzig Vorgaengerlisten. Geprueft wird das im Harness als `disjunkt_b3_gegen_b1_b2` und zusaetzlich als Guard in `01`, `02` und `03`. |
| Kein `vivo` mehr in ausfuehrbaren Mengen | `vivo-hoehenverstellbares-stehpult` kommt in diesem Verzeichnis nur noch in der Finding-Dokumentation des Runbooks (Abschnitt 2.1 und 2 „Bewusst NICHT gewaehlt") vor — in keiner Ziel-, Relations-, Payload-, Fixture- oder Testmenge. |
| Quellenbindung der Payload | Jede Aussage ist auf eine Datei unter `apps/web/supabase/` bzw. `apps/web/lib/guides/` zurueckgefuehrt, siehe `RUNBOOK.md` Abschnitt 4. Die bewusst ausgelassenen Behauptungen stehen in Abschnitt 5. |

---

## 4 · Wie der Test wiederholt wird

```bash
cd apps/web/supabase/production_value_add_batch3/test

# 1) Nur die statische Stufe — braucht keine Datenbank.
CBB_STATIC_ONLY=1 ./run_local_postgres_test.sh

# 2) Vollstaendig, mit systemweit installiertem PostgreSQL.
./run_local_postgres_test.sh

# 3) Vollstaendig, mit PostgreSQL an einem bekannten Ort.
CBB_PG_BIN=/usr/lib/postgresql/16 ./run_local_postgres_test.sh
```

Falls das Skript noch nicht ausfuehrbar ist: `chmod +x run_local_postgres_test.sh`.

Der Harness fasst **keine** Production- und **keine** Pilot-Datenbank an. Er
legt einen eigenen Cluster in einem temporaeren Verzeichnis an, der
ausschliesslich ueber einen Unix-Socket erreichbar ist (`listen_addresses=''`),
und stoppt ihn am Ende wieder.

### Erwartete Ergebnisse

| Stufe | Erwartung |
|---|---|
| CASE 0 (statisch) | 19 Pruefungen, 0 Abweichungen; Manifest 74/74 `OK` |
| `01_preflight_read_only.sql` | 18 PASS, 9 INFO, 0 FAIL |
| `02_backup_value_add_batch3.sql` | Exit 0, `backup_rows = 10` |
| `02b_verify_snapshot_read_only.sql` | 17 PASS, 4 INFO, 0 FAIL |
| `03_backfill_value_add_batch3.sql` | Exit 0, keine Exception |
| `04_verify_read_only.sql` | 17 PASS, 4 INFO, 0 FAIL |
| `04b_verify_payload_security_read_only.sql` | 10 PASS, 7 INFO, 0 FAIL |
| Gesamt | `GESAMT: PASS`, Exit 0 |

Bei fehlendem PostgreSQL: `GESAMT: UMGEBUNG UNVOLLSTAENDIG`, **Exit 2**. Dasselbe
Exit 2 liefert auch der Lauf mit `CBB_STATIC_ONLY=1` — dort ist es die erwartete
Ausgabe fuer „Stufe 1 gruen, Stufe 2 bewusst ausgelassen" und kein Fehlschlag.

---

## 5 · Was der Harness abdeckt

**Stufe 1 — CASE 0, ohne Datenbank (19 Pruefungen)**

1. sha256-Integritaet von Batch 1 und Batch 2 (74 Dateien)
2.–4. `SET LOCAL`-Position und `begin`/`commit`-Paarigkeit in `02`, `03`, `05`
5.–7. Write-Safety in `02`, `03`, `05`: kein `DROP`/`TRUNCATE`/`DELETE`, jede
   v1-/v2-Referenz ausschliesslich innerhalb von `to_regclass()`
8.–11. Read-only-Reinheit von `01`, `02b`, `04`, `04b`
12.–17. Vollstaendigkeit der zehn Zielslugs in jeder der sechs Dateien
18. statische Disjunktheit gegen die zwanzig Vorgaengerslugs
19. Nennung des Production-Ziels in jeder Datei und im Runbook

**Stufe 2 — Datenbankfaelle**

| Fall | Was geprueft wird |
|---|---|
| `case_a_happy_path` | 01 → 02 → 02b → 03 → 04 → 04b in Reihenfolge, dazu die Unversehrtheit von Batch 1 und 2 |
| `case_b_wiederholungen` | verfruehte Verify-Laeufe und Doppelausfuehrung jeder schreibenden Datei |
| `case_n_drift` | Zielzeile aendert sich nach dem Snapshot — 03 bricht ab, 02b meldet genau eine FAIL-Zeile |
| `case_c_rollback` | Abbruch NACH dem Payload-DDL in 03: auch das DDL wird zurueckgerollt |
| `case_d_restore_roundtrip` | 02 → 03 → 05 → 05, inklusive Beweis der zehn zurueckgespielten Originalzeitstempel |
| `case_e_pilot_artefakt` | Pilot-Marker vorhanden |
| `case_f_zu_wenig_produkte` | Bestand unter 300 |
| `case_g_unvollstaendiges_schema` | 7 von 8 Value-Add-Spalten |
| `case_h_relationsziel_offline` | ein Relationsziel unpublished |
| `case_m_fremdbefuellung` | eine Zielzeile traegt bereits Value-Add-Daten |
| `case_k_vorgaenger_artefakt_fehlt` | `value_add_payload_v2` geloescht |
| `case_l_payload_security` | anon bekommt `SELECT` auf die Payload — 04b MUSS zwei FAIL-Zeilen melden |
| `case_o_snapshot_security` | anon bekommt `SELECT` auf den Snapshot — 02b MUSS zwei FAIL-Zeilen melden |
| `case_i_trigger` | `seo_updated_at_trigger` im Zusammenspiel mit 03 und 05 |
| `case_j_lock_timeout` | `02` bricht unter `AccessExclusiveLock` nach ~5 s ab |

---

## 6 · Offene Punkte

1. Das lokale Gate 0 ist belegt. Erst nach **neuer ausdruecklicher
   Benutzerfreigabe**
   darf ueberhaupt ein Schritt gegen Production laufen.
2. Getrennt zu klaeren, **nicht** Teil dieses Changesets: der
   Produktidentitaetskonflikt bei `vivo-hoehenverstellbares-stehpult`
   (RUNBOOK Abschnitt 2.1) und die Preflight-Warnung zu
   `restore_affiliate_urls.sql` (RUNBOOK Abschnitt 7).
3. Der Production-Hold bleibt bis dahin unveraendert bestehen.
