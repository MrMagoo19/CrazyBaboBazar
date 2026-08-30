# Lokaler Harness — Klick-out-Messung (P1)

Testet die **Originaldateien** aus `../` gegen eine echte PostgreSQL-Instanz.
Es wird nichts kopiert und nichts umgeschrieben.

## Sicherheitsgrenzen

- **Keine** Production- und **keine** Pilot-Datenbank wird angefasst.
- Der Cluster liegt in `$(mktemp -d)`, hoert **nicht** auf TCP
  (`listen_addresses=''`) und wird am Ende gestoppt.
- Keine Datei unter `../` wird veraendert.

## Aufruf

```bash
./run_local_postgres_test.sh                       # alles
CBB_STATIC_ONLY=1 ./run_local_postgres_test.sh     # nur CASE 0
CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh    # Datenverzeichnis behalten
CBB_PG_BIN=/usr/lib/postgresql/16 ./run_local_postgres_test.sh
```

## Exit-Codes

| Code | Bedeutung |
|---|---|
| 0 | alle Erwartungen erfuellt |
| 1 | mindestens eine Abweichung |
| 2 | Umgebungsproblem — **weder PASS noch FAIL** |

## Stufe 1 — statisch, ohne Datenbank

| Pruefung | Was sie belegt |
|---|---|
| `readonly_01`, `readonly_03`, `readonly_04b` | Die drei lesenden Dateien enthalten genau ein Semikolon **ausserhalb von Text-Literalen**, kein schreibendes Schluesselwort und keinen DO-Block. In `04b` traegt ein Literal bewusst ein Semikolon: es ist der exakte Wert von `cron.job.command`, und ein Vergleich gegen eine gekuerzte Fassung waere kein Vergleich. Die Pruefung entfernt Literale, bevor sie zaehlt. |
| `setlocal_02`, `setlocal_04`, `setlocal_04a`, `setlocal_05` | `SET LOCAL lock_timeout` und `statement_timeout` stehen genau einmal, direkt hinter `begin;` und **vor** dem ersten DO-Block. Ohne diese Position wuerde der erste `select count(*) from public.products` mit dem Session-Default `lock_timeout = 0` unbegrenzt warten. |
| `no_forbidden_fields` | In keiner SQL-Datei und in keiner Codezeile des Route-Handlers steht ein Bezeichner fuer IP, User-Agent, Referrer, E-Mail, Querystring oder Geraete-Fingerprint. Kommentare werden vorher entfernt — die ausdrueckliche Erwaehnung „keine IP" in der Dokumentation zaehlt nicht als Treffer. |
| `field_parity` | Die Feldliste, die `app/api/click/[slug]/route.ts` sendet, ist identisch mit der Spaltenliste, die `02_create_clickouts.sql` anlegt. Ein spaeter ergaenztes Feld faellt damit auf. |
| `sequence_hardening` | `02` entzieht `public.click_outs_id_seq` alle Rechte von `PUBLIC`, `anon`, `authenticated` **und** `service_role` und vergibt genau **einen** Sequenz-Grant: `USAGE` an `service_role`. Kein `SELECT`, kein `UPDATE`. Zusaetzlich: `03` prueft die Sequenzrechte selbst (`has_sequence_privilege`). |
| `retention_gate` | Das harte Pre-enable-Gate fuer den 12-Monats-Loeschlauf steht im Runbook (Marker `PRE-ENABLE-GATE`), verknuepft dort `SUPABASE_SERVICE_ROLE_KEY` mit `04_retention.sql`, `04a` und `04b` — **und** die Zeile `GATE-STATUS` widerspricht nicht dem Ausfuehrungsprotokoll: sie darf nicht `ERFUELLT` melden, solange dort noch „Noch nichts ausgefuehrt" steht. Eine Datei, die allein durch ihr Vorhandensein ein Gate erfuellt, waere kein Gate. |
| `retention_schedule` | Jobname (`cbb-click-outs-retention-12m`), Schedule (`15 3 * * *`) und Command stehen **wortgleich** in `04a`, `04b`, `05` und im Runbook. Zusaetzlich: nur `04a` ruft `cron.schedule` auf und genau einmal, nur `05` ruft `cron.unschedule` auf und genau einmal, `04b` ruft keins von beidem auf, `04_retention.sql` plant nicht selbst, und die drei Abbruchtexte (doppelter Jobname, Drift in `04a`, Drift in `05`) sind vorhanden. Ohne diese Pruefung koennte `04b` still einen anderen Job pruefen als `04a` anlegt. |
| `target_named` | Das Production-Ziel `ydiihvzcxaaoqhmgoqvu` steht sichtbar in jeder SQL-Datei und im Runbook. |

## Stufe 2 — Datenbankfaelle

| Fall | Was geprueft wird |
|---|---|
| `case_a_happy_path` | 01 → 02 → 03, dazu die Wirksamkeit der Rechte, der CHECK-Constraints und der Auswertungs-View |
| `case_b_wiederholung` | verfruehte Laeufe von 03/04/04a/04b/05 und Doppelausfuehrung von 02. `04b` scheitert hier nicht hart (der `cron`-Katalog ist ja da), sondern meldet 1 PASS und 8 FAIL — genau die Zeilen, die belegen, dass nichts geplant ist |
| `case_c_pilot_artefakt` | Pilot-Marker vorhanden |
| `case_d_zu_wenig_produkte` | Bestand unter 300 |
| `case_e_retention` | 12-Monats-Fenster trifft exakt die alten Zeilen, zweiter Lauf ist idempotent |
| `case_f_rollback` | 02 → Daten → 05, danach laesst sich sauber neu anlegen |
| `case_g_rollback_geschuetzt` | fehlt ein Value-Add-Artefakt, verweigert der destruktive Rollback die Arbeit |
| `case_h_rechteloch` | anon bekommt `SELECT` auf `click_outs` — 03 MUSS das als FAIL melden |
| `case_i_sequenzloch` | die Tabelle bleibt dicht, aber anon bekommt `SELECT` auf `click_outs_id_seq` — 03 MUSS das als FAIL in `click_outs_sequenzrechte` melden. Ohne diesen Fall waere ueber `last_value` die Zahl aller Klick-outs lesbar, ohne je eine Zeile zu sehen |
| `case_j_retention_plan` | 04a legt genau einen Job an, 04b bestaetigt ihn (9 PASS), der **zweite** 04a-Lauf ist ein No-op ohne zweiten Job, eine saubere Laufhistorie bleibt gruen, ein fehlgeschlagener Lauf faellt als FAIL in `retention_job_ohne_fehlgeschlagene_laeufe` auf, und `04_retention.sql` bleibt daneben nutzbar |
| `case_k_ohne_cron` | `pg_cron` fehlt vollstaendig: 04a bricht fail-closed ab, 04b scheitert hart (`relation "cron.job" does not exist`) — und 04 sowie 05 laufen **unveraendert** durch. Ohne diesen Fall koennte 04a eine neue harte Abhaengigkeit in den Rollback eingeschleppt haben |
| `case_l_job_drift` | ein gleichnamiger Job mit fremdem Schedule und Command. 04a bricht ab (`Drift`), 05 bricht ab (`Drift`), und der fremde Eintrag steht danach **unveraendert** — genau das, was ein blindes `cron.schedule` vernichtet haette. 04b meldet 6 PASS und 3 FAIL |
| `case_m_doppelter_jobname` | derselbe Jobname unter zwei Nutzern (auf `pg_cron` moeglich, der eindeutige Index liegt auf `(jobname, username)`). 04a und 05 brechen ab, beide Eintraege bleiben stehen, 04b meldet 2 PASS und 7 FAIL |
| `case_n_fremder_purge_job` | ein anders benannter Job ruft denselben Loeschpfad auf. 04a legt keinen zweiten daneben, 05 loescht die Funktion nicht unter ihm weg |
| `case_o_rollback_mit_job` | 02 → 04a → Daten → 05: der Job wird in derselben Transaktion abbestellt, `assert_after_05.sql` belegt, dass kein Eintrag auf die geloeschte Funktion zeigt, und danach laesst sich sauber neu anlegen und neu planen |

`03_verify_read_only.sql` liefert im gesunden Zustand **17 PASS** und
**6 INFO**. In den beiden Loch-Faellen sind es 16 PASS und genau 1 FAIL.
`04b_verify_retention_schedule_read_only.sql` liefert im gesunden Zustand
**9 PASS** und **7 INFO**.

### `fixture/02b_cron_stub.sql` — und was ein gruener Lauf NICHT belegt

`pg_cron` ist eine kompilierte Erweiterung mit Hintergrundprozess und laesst
sich in einem wegwerfbaren Cluster nicht anlegen. Die Fixture bildet deshalb
genau den benutzten Teil nach: `cron.job` (inklusive Spaltentypen und dem
eindeutigen Index auf `(jobname, username)`), `cron.job_run_details`,
`cron.schedule(text, text, text)` und `cron.unschedule(bigint)` — samt dem
**Ueberschreib-Verhalten** bei gleichem Jobnamen, denn genau davor schuetzen die
Guards in `04a` und `05`.

Nicht nachgebildet ist die **Ausfuehrung**. Im Harness laeuft nichts zu
irgendeiner Zeit; Laufhistorie entsteht ausschliesslich ueber
`cases/setup_seed_job_runs.sql` und `cases/setup_seed_job_run_failed.sql`. Ein
gruener Harness belegt damit die Planung und ihre Guards — **nicht**, dass auf
Production tatsaechlich geloescht wird. Das belegt allein die protokollierte
Kontrolle der echten Job-History (RUNBOOK Abschnitt 7, Gate-Punkt 3).

Ebenfalls nicht nachbildbar ist der Eintrag in `pg_extension`. `04b` meldet ihn
darum als INFO-Zeile `pg_cron_extension`: lokal steht dort `0`, auf Production
muss dort `1` stehen. Steht dort auf Production `0`, existiert zwar ein Job,
aber niemand fuehrt ihn aus — dann ist das Gate nicht erfuellt.

### `assert_rechte_wirken.sql` — der eigentliche Sicherheitsbeweis

`assert_after_02.sql` liest den **Katalog**. Dieser Fall greift wirklich zu:

- `anon` darf weder lesen noch schreiben (erwartet `insufficient_privilege`)
- `service_role` **darf** schreiben — trotz aktiver RLS ohne Policy, weil sie
  `BYPASSRLS` traegt
- `service_role` darf **nicht** lesen und **nicht** loeschen. Ohne `SELECT`
  kann ein kompromittierter Server-Schluessel die bereits erfassten Ereignisse
  nicht abziehen; ohne `DELETE` ist die Retention-Funktion der einzige
  Loeschpfad.
- Weder `anon` noch `service_role` kommen an den **Zaehlerstand der
  Identity-Sequenz** (`select last_value`), und `service_role` kann kein
  `setval` ausfuehren. Der Zaehlerstand waere sonst die Zahl aller bisher
  gezaehlten Klick-outs — lesbar, ohne je eine Zeile zu sehen.

Der Rollenwechsel laeuft ueber `set_config('role', ..., true)` statt ueber
`SET LOCAL ROLE`: `set_config` ist ein gewoehnlicher Funktionsaufruf und damit
in PL/pgSQL uneingeschraenkt verfuegbar.

### `assert_constraints_greifen.sql`

Zehn Negativfaelle (Querystring, Fragment, protokollrelative und absolute
Herkunft, Ueberlaenge, Steuerzeichen, unbekannter Merchant, freie
Geraeteklasse, Slug mit Pfadwechsel, Slug in Grossbuchstaben) muessen alle mit
`check_violation` scheitern — und drei zulaessige Datensaetze muessen
durchgehen. Ohne die Gegenprobe waeren zu strenge Constraints unentdeckt und
die Messung waere still tot.
