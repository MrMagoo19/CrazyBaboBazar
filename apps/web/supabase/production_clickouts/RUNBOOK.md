# RUNBOOK — Production-Klick-out-Messung (P1)

> **Status: NICHT AUSGEFUEHRT. Production-Hold aktiv.**
> Kein Artefakt dieses Verzeichnisses wurde gegen eine Datenbank ausgefuehrt —
> weder gegen Production noch gegen Pilot/Staging. Die Ausfuehrung ist ohne
> **neue, ausdrueckliche Benutzerfreigabe** untersagt.
>
> Das gilt ausdruecklich auch fuer `04a_schedule_retention.sql`: die Datei ist
> **vorbereitet, nicht eingerichtet**. Es existiert kein Datenbank-Job. Das
> Pre-enable-Gate in Abschnitt 7 ist damit **nicht** erfuellt.

**Zielprojekt (vor JEDEM Schritt sichtbar im SQL-Editor gegenpruefen):**
`project/ydiihvzcxaaoqhmgoqvu` — `https://ydiihvzcxaaoqhmgoqvu.supabase.co`

Pilot/Staging (`nmzuycveumyfvtxdcnuc`) ist **kein** Ziel dieses Changesets.

---

## 1 · Was hier gebaut wird — und was ausdruecklich nicht

| Gebaut | Nicht gebaut |
|---|---|
| Eine Zeile pro Klick auf einen Partnerlink, **nur mit Einwilligung** | Keine Personenprofile, keine Wiedererkennung ueber Sitzungen hinweg |
| `product_slug`, `merchant`, `source_path`, `device_class`, `consented_session_id`, `created_at` | Keine IP, kein IP-Hash, kein vollstaendiger User-Agent, kein vollstaendiger Referrer, keine Querystrings, kein Cookie-Inhalt |
| Tagesaggregat als private View | Keine oeffentliche Auswertung, kein Zugriff fuer `anon`/`authenticated` |
| Loeschfunktion mit 12-Monats-Frist | Keine zweite Loeschmoeglichkeit — weder `DELETE` fuer die App noch ein zweiter Job |
| Ein vorbereiteter `pg_cron`-Job, der genau diese Funktion taeglich aufruft | **Keine ausgefuehrte Einrichtung.** Die Datei existiert, der Job auf Production nicht — siehe Abschnitt 7 |

Die Anwendungsseite liegt in:

- `apps/web/lib/affiliate.ts` — Merchant-Allowlist, Pfad-Sanitisierung, Geraeteklasse
- `apps/web/lib/consent-cookie.ts` — der serverseitig pruefbare Consent-Cookie (v2)
- `apps/web/lib/consent.ts` — die eine Consent-Store-Instanz ueber diesem Cookie
- `apps/web/lib/click-session.ts` — Sitzungskennung, erst nach `accepted`
- `apps/web/app/api/click/[slug]/route.ts` — Weiterleitung und Insert
- `apps/web/components/ui/affiliate-link.tsx` — der eine CTA der App

---

## 2 · Das Verhaltensversprechen in einem Satz

**Die Weiterleitung ist fail-open, das Ziel ist fail-closed, das Speichern ist
consent-gebunden.**

1. **Fail-open (Weiterleitung).** Ein Fehler beim Messen darf den Klick nie
   kosten. Der gesamte Logging-Pfad steht in einem `try/catch`, dessen
   Fehlerfall ausdruecklich nichts tut. Fehlt `SUPABASE_SERVICE_ROLE_KEY`,
   wird gar nicht erst gemessen — die Weiterleitung laeuft trotzdem.
2. **Fail-closed (Ziel).** Es gibt keinen Queryparameter, mit dem sich ein Ziel
   setzen liesse. Die Ziel-URL kommt ausschliesslich aus den **veroeffentlichten**
   Produktdaten und muss die Merchant-Allowlist passieren. Unbekannter Slug,
   unsicheres Ziel, fehlende Konfiguration oder nicht erreichbare Datenbank
   enden alle auf `/produkt/<slug>`. Diese Route kann damit kein offener
   Redirect werden.
3. **Consent-gebunden (Speichern).** Gespeichert wird nur, wenn **beides**
   zutrifft:
   - der First-Party-Consent-Cookie `cbb_consent_clickout_v2` traegt exakt
     `accepted` (`SameSite=Lax`, `Secure` nur unter HTTPS, `Path=/`), **und**
   - der Queryparameter `cs` hat die UUID-Form.

   Eine gueltige `cs`-UUID **allein** reicht ausdruecklich nicht. Das war der
   Audit-Befund der ersten Fassung: dort galt jede syntaktisch gueltige UUID im
   Query als Einwilligung, ein fremd konstruierter Link haette also ohne jede
   Nutzerentscheidung einen Datensatz erzeugt. Seitdem prueft der Server die
   Einwilligung selbst, statt sie dem Query zu glauben.

   Den Cookie setzt ausschliesslich die ausdrueckliche Accept-/Decline-Aktion im
   Hinweisbanner. Sein Inhalt ist genau `accepted` oder `declined` — kein
   Identifikator, kein Zeitstempel, kein Zaehler. Die Sitzungskennung selbst
   liegt weiterhin nur im `sessionStorage`, kommt nie in einen Cookie und endet
   mit dem Tab.

   **Kein Uebertrag aus Consent v1.** Der alte localStorage-Schluessel
   `cbb-cookie-consent-v1` gehoerte zum blossen Hinweis auf Vercel/Amazon und
   deckte diesen Messzweck nicht ab. Er wird weder gelesen noch migriert; wer
   damals zugestimmt hat, entscheidet neu.

---

## 3 · Warum die Tabelle in `public` liegt

Die Anwendung schreibt ueber PostgREST (`/rest/v1/click_outs`). PostgREST sieht
nur die konfigurierten Schemata; auf Supabase ist das per Default `public`. Eine
Tabelle in einem privaten Schema waere ueber diesen Weg nicht erreichbar und
haette eine Aenderung der Projektkonfiguration erzwungen — eine zusaetzliche,
schwerer auditierbare externe Aktion.

Die Absicherung passiert deshalb ueber **Rechte statt Verstecken**:

| Massnahme | Wirkung |
|---|---|
| `enable row level security` **ohne jede Policy** | `anon` und `authenticated` sehen und schreiben nichts, selbst wenn ihnen jemals wieder ein Grant zugewiesen wuerde |
| `revoke all ... from public, anon, authenticated` | Supabase vergibt bei neuen Tabellen in `public` sonst automatisch alle Rechte |
| `revoke all ... from service_role` + `grant insert` | Der einzige Schreibpfad hat **genau ein** Recht. Kein `SELECT`, kein `UPDATE`, kein `DELETE` |
| `revoke all on sequence public.click_outs_id_seq` + `grant usage` an `service_role` | Die Identity-Sequenz ist ein **eigenes Objekt mit eigener ACL**. Ohne Entzug gaebe `select last_value` die Zahl aller bisher gezaehlten Klick-outs preis, obwohl die Tabelle dicht ist, und `setval` liesse die Nummernfolge verbiegen. `USAGE` erlaubt nur `nextval`/`currval` |
| Auswertung in `cbb_private_analytics` | Ueber PostgREST grundsaetzlich nicht erreichbar, unabhaengig von Grants |

`02` bricht zusaetzlich fail-closed ab, wenn `public.click_outs_id_seq` bereits
existiert. Grund: PostgreSQL leitet den Sequenznamen aus Tabelle und Spalte ab;
bei einer Namenskollision hiesse die neue Sequenz `click_outs_id_seq1`, und der
Rechte-Entzug traefe stillschweigend die falsche.

**Bewusst kein `force row level security`.** FORCE unterwirft auch den
Tabelleneigentuemer der RLS. Da es absichtlich keine Policy gibt, wuerde FORCE
dem Eigentuemer jeden Zugriff nehmen: die Retention-Funktion koennte nichts mehr
loeschen, und `03_verify_read_only.sql` saehe eine kuenstlich leere Tabelle.

---

## 4 · Datenminimierung im Detail

| Feld | Inhalt | Warum es unbedenklich ist |
|---|---|---|
| `product_slug` | z. B. `tre-feuerstahl-xxl` | Oeffentliche URL-Kennung, kein Personenbezug. CHECK erzwingt die Slug-Form |
| `merchant` | `amazon` | CHECK erlaubt nur Werte aus der Allowlist |
| `source_path` | z. B. `/thema/outdoor` | CHECK erzwingt: beginnt mit genau einem Slash, hoechstens 128 Zeichen, **kein** `?`, **kein** `#`, keine Steuerzeichen. Ein Suchbegriff oder eine fremde Domain kann strukturell nicht hineingelangen. `NULL` heisst: keine verwertbare Herkunft, es wurde nichts geraten |
| `device_class` | `mobile` / `tablet` / `desktop` / `unknown` | Vier Werte per CHECK. Der User-Agent selbst wird nie gespeichert |
| `consented_session_id` | zufaellige UUID | Spaltentyp `uuid`: eine frei gewaehlte Kennung (E-Mail, Nutzer-ID, Cookie-Wert) laesst sich gar nicht erst speichern. Entsteht erst nach Einwilligung und erst beim tatsaechlichen Klick, endet mit dem Tab. Der Consent-Cookie selbst wird nur gelesen und nie gespeichert |
| `created_at` | Default `now()` | Der Route-Handler sendet die Spalte nicht mit |

**Bewusst kein Index auf `consented_session_id`.** Ein solcher Index waere
ausschliesslich dafuer nuetzlich, die Klickfolge einer einzelnen Sitzung schnell
zu rekonstruieren — also fuer genau die Profilbildung, die dieses Changeset
nicht will. `03_verify_read_only.sql` prueft sein Fehlen hart (Zeile
`kein_index_auf_sitzungskennung`).

Die View `cbb_private_analytics.click_outs_daily` gibt **nur Aggregate** aus.
`consented_session_id` erscheint nie als Wert, sondern ausschliesslich als
`count(distinct ...)`.

---

## 5 · Voraussetzung: Server-Geheimnis

Der Insert braucht `SUPABASE_SERVICE_ROLE_KEY` — bewusst **ohne**
`NEXT_PUBLIC_`-Praefix, damit die Variable nie in ein Client-Bundle gelangt.
Sie wird ausschliesslich in `app/api/click/[slug]/route.ts` gelesen.

- **Fehlt sie**, ueberspringt der Route-Handler das Logging vollstaendig und
  leitet unveraendert weiter. Das ist der Normalzustand, solange dieses
  Changeset nicht freigegeben ist.
- Das Setzen der Variable in Vercel ist eine **externe Kontoaktion** und
  braucht eine eigene Freigabe. Dieses Repository enthaelt und veraendert keine
  Secrets.

Reihenfolge fuer einen spaeteren Rollout: **erst** Schritte 01–03 gegen die
Datenbank, **dann** 04a und 04b und damit das Retention-Gate aus Abschnitt 7
erfuellen, **erst dann** die Umgebungsvariable setzen. Umgekehrt liefe die Anwendung gegen eine nicht
existierende Tabelle — fail-open faengt das zwar ab, aber es waere unnoetiger
Fehlerlaerm. Und ohne erfuelltes Gate entstuenden Daten ohne Loeschmechanismus.

### PRE-DEPLOY-GATE — Auftragsverarbeitung und Drittlandtransfer

Die Datenschutzerklaerung nennt Supabase jetzt wahrheitsgemaess als
Datenbankdienst/Empfaenger und verweist auf den vom Anbieter dokumentierten
SCC-Mechanismus. Das Repository kann aber **nicht** selbststaendig belegen,
welcher DPA-/SCC-Vertragsstand fuer das konkrete Supabase-Konto tatsaechlich
gilt — dafuer braucht es eine read-only-Pruefung im Supabase-Konto selbst.

Vor dem ersten Production-Write und vor jedem Deploy, der die Klick-Messung
scharf schalten koennte, muss deshalb im Supabase-Konto read-only verifiziert
und in Abschnitt 10 protokolliert werden:

1. aktueller DPA fuer die verwendete Organisation/das verwendete Projekt
   wirksam bzw. angenommen,
2. die dort einbezogenen Standardvertragsklauseln und Unterauftragsverarbeiter
   passen zu der in `app/datenschutz/page.tsx` beschriebenen Verarbeitung,
3. die reale Projektregion ist bekannt; falls sie in der Datenschutzerklaerung
   genannt werden soll, wird sie erst nach dieser Verifikation eingetragen.

**Stand 2026-08-30:** Alle drei Punkte sind read-only verifiziert und in
Abschnitt 10 protokolliert; die Datenschutzerklaerung
(`apps/web/app/datenschutz/page.tsx`, Abschnitt 6) wurde entsprechend
korrigiert — richtige Vertragspartei Supabase Pte. Ltd. (Singapur) statt der
zuvor falschen Delaware-Angabe, Nennung der Region West EU (Ireland)/
eu-west-1 als primaerem Speicherort, Hinweis auf Unterauftragsverarbeiter
(u. a. AWS fuer Hosting, Supabase, Inc. fuer Support) und aktuelle Links zu
DPA und Unterauftragsverarbeiterliste anstelle des veralteten TIA-Links von
Maerz 2025. **Dieses PRE-DEPLOY-GATE ist damit erfuellt.**

Das aendert nichts am Production-Hold insgesamt: Der Rollout bleibt zusaetzlich
durch das Retention-Gate in Abschnitt 7 (weiterhin **NICHT ERFUELLT**) und durch
die generelle Freigabepflicht fuer das Setzen von `SUPABASE_SERVICE_ROLE_KEY`
(Abschnitt 5, externe Kontoaktion mit eigener Freigabe) gesperrt. Diese
Korrektur ist eine lokale Textaenderung im Repository — sie ist weder ein
Production-Write noch eine Rollout-Freigabe.

---

## 6 · Ablauf (jeder Schritt einzeln freizugeben)

| Schritt | Datei | Art | Abbruchkriterium |
|---|---|---|---|
| 01 | `01_preflight_read_only.sql` | read-only | jede FAIL-Zeile blockiert 02 |
| 02 | `02_create_clickouts.sql` | **schreibend (DDL)** | bricht fail-closed ab, wenn die Tabelle existiert |
| 03 | `03_verify_read_only.sql` | read-only | jede FAIL-Zeile ist ein Befund |
| 04a | `04a_schedule_retention.sql` | **schreibend (Planung)** | bricht fail-closed ab bei Drift, doppeltem Jobnamen, fremdem Loeschjob oder fehlendem `pg_cron` |
| 04b | `04b_verify_retention_schedule_read_only.sql` | read-only | jede FAIL-Zeile ist ein Befund |
| 04 | `04_retention.sql` | **schreibend (loeschend)** | der manuelle Loeschlauf. Bleibt neben 04a bestehen, ersetzt ihn nicht |
| 05 | `05_rollback.sql` | **schreibend (destruktiv)** | nur mit eigener Freigabe |

Reihenfolge beim Rollout: **01 → 02 → 03 → 04a → 04b**. `04` ist kein Schritt
dieser Kette, sondern der manuelle Einzellauf; `05` ist der Rueckweg.

**Erwartete Ergebnisse**

- `01` → 11 PASS, 7 INFO, 0 FAIL
- `02` → `click_out_rows = 0`
- `03` → 17 PASS, 6 INFO, 0 FAIL (die 17. Zeile ist `click_outs_sequenzrechte`)
- `04a` → eine Ergebniszeile mit genau dem geplanten Job
- `04b` → 9 PASS, 7 INFO, 0 FAIL

Bei einem FAIL: nichts korrigieren, nichts nachgranten, nichts loeschen, **und
insbesondere 04a nicht "nochmal drueberlaufen lassen"**. Befund melden und
Ursache klaeren.

---

## 7 · Retention

`cbb_private_analytics.purge_click_outs(retention_months integer default 12)`
ist der **einzige** Loeschpfad der Tabelle — `service_role` hat bewusst kein
`DELETE`. Die Funktion ist `security definer` mit fest verdrahtetem
`search_path` und akzeptiert nur 1 bis 24 Monate.

Die 12 Monate sind **keine freie Wahl**: genau diese Frist steht in der
Datenschutzerklaerung (`apps/web/app/datenschutz/page.tsx`, Abschnitt 6). Eine
Aenderung hier erzwingt eine Aenderung dort im selben Schritt.

### Der geplante Lauf — `04a_schedule_retention.sql`

| | |
|---|---|
| Jobname | `cbb-click-outs-retention-12m` |
| Schedule | `15 3 * * *` — taeglich 03:15 UTC |
| Command | `select cbb_private_analytics.purge_click_outs(12);` |
| Mechanismus | `pg_cron` (`cron.schedule`), Job liegt in `cron.job`, Laeufe in `cron.job_run_details` |

**Warum taeglich und nicht monatlich.** Der Job loescht ausschliesslich Zeilen
jenseits der 12-Monats-Grenze. Taeglich heisst deshalb nicht „mehr Loeschung",
sondern: die zugesagte Frist ist hoechstens **einen Tag** ueberschritten statt
hoechstens einen Monat. Ein ausgefallener Lauf holt sich am naechsten Tag von
selbst nach, ohne dass jemand eingreift.

**Warum es vor `cron.schedule` einen Guard gibt.** `cron.schedule(jobname, …)`
legt bei einem bereits vorhandenen gleichnamigen Job **keinen zweiten Job an,
sondern ueberschreibt den vorhandenen** — so steht es im Supabase-Cron-
Quickstart. Ein blindes `cron.schedule` waere damit kein idempotenter Rollout,
sondern ein stiller Ueberschreiber. `04a` entscheidet deshalb **vor** dem
Schreiben:

| Vorzustand | Verhalten von `04a` |
|---|---|
| kein Job dieses Namens | legt **genau einen** Job an |
| Job vorhanden, exakt identisch (Schedule, Command, Datenbank, aktiv) | **No-op** mit NOTICE, kein Schreibvorgang |
| Job vorhanden, weicht ab | **Abbruch (Drift)** — nichts wird geaendert |
| Name kommt mehrfach vor (auf `pg_cron` moeglich: der eindeutige Index liegt auf `(jobname, username)`) | **Abbruch** — nichts wird geaendert |
| ein anders benannter Job ruft `purge_click_outs` auf | **Abbruch** — zwei Planungen fuer eine Frist sind nicht gewollt |
| `pg_cron` nicht nutzbar | **Abbruch** |

Jeder Abbruch rollt die Transaktion vollstaendig zurueck. Es bleibt in keinem
Fall ein halb eingerichteter Zustand zurueck. Die Kontrolle nach dem Anlegen
laeuft ebenfalls **innerhalb** derselben Transaktion.

**Voraussetzung, die nicht in diesem Repository liegt:** `pg_cron` muss im
Supabase-Projekt aktiviert sein (Dashboard → Database → Extensions, oder
`create extension pg_cron`). Das ist eine externe Kontoaktion mit eigener
Freigabe. `01` meldet als INFO, ob die Extension installiert und verfuegbar
ist; ist sie es nicht, bricht `04a` fail-closed ab, statt in einen Katalog zu
schreiben, den niemand ausliest.

`05_rollback.sql` bestellt einen vorhandenen, exakt benannten Retention-Job in
derselben Transaktion **vor** dem Drop der Funktion wieder ab (`cron.unschedule`
ueber die `jobid`) und prueft danach, dass keiner mehr eingetragen ist. Ohne das
bliebe ein Job zurueck, der ab dann jede Nacht scheitert. Bei einem
gleichnamigen Job mit fremdem Inhalt bricht auch der Rollback fail-closed ab —
ein fremder Job wird nicht stillschweigend abbestellt, und die Funktion faellt
dann ebenfalls nicht.

### PRE-ENABLE-GATE — Retention (hart, nicht verhandelbar)

> **Die Messung darf NICHT scharf geschaltet werden, solange kein automatischer
> Scheduler ODER ein verbindlich dokumentierter, ueberwachter wiederkehrender
> 12-Monats-Loeschlauf eingerichtet ist.**

„Scharf schalten" heisst hier genau eine Handlung: das Setzen von
`SUPABASE_SERVICE_ROLE_KEY` in der Vercel-Umgebung. Vorher schreibt der
Route-Handler nichts, egal ob die Tabelle existiert — es entstehen also auch
keine Daten, fuer die eine Frist laufen muesste.

**Warum das ein Gate ist und keine Empfehlung:** Die Datenschutzerklaerung
(`apps/web/app/datenschutz/page.tsx`, Abschnitt 6) sagt zu, dass die
Zaehl-Datensaetze *spaetestens nach 12 Monaten geloescht* werden. Eine Zusage
ohne Mechanismus ist keine Zusage. `purge_click_outs` ist der einzige
Loeschpfad — aber eine Funktion, die niemand aufruft, loescht nichts, und eine
Datei, die niemand ausfuehrt, ruft sie nicht auf.

Erfuellt ist das Gate durch **eines** von beidem, schriftlich festgehalten in
Abschnitt 10 dieses Runbooks:

1. **Automatisch:** ein auf Production **eingerichteter** `pg_cron`-Job, der
   `cbb_private_analytics.purge_click_outs(12)` wiederkehrend ausfuehrt.
2. **Manuell, aber verbindlich:** ein dokumentierter wiederkehrender Lauf mit
   festem Intervall (hoechstens monatlich), benannter verantwortlicher Person,
   Kalendereintrag oder Ticket-Serie und einer Ueberwachung, die einen
   ausgefallenen Lauf sichtbar macht. „Wir denken dran" erfuellt das Gate nicht.

#### Vorbereitet ist nicht eingerichtet

`04a_schedule_retention.sql` liegt seit diesem Changeset im Repository. **Das
allein erfuellt Variante 1 nicht.** Eine Datei, die niemand ausgefuehrt hat,
legt keinen Job an — genauso wenig wie `04_retention.sql` etwas loescht,
solange niemand sie startet. Variante 1 ist erst erfuellt, wenn **alle drei**
Punkte abgehakt und in Abschnitt 10 protokolliert sind:

1. **`04a` auf Production ausgefuehrt** (`project/ydiihvzcxaaoqhmgoqvu`), mit
   Datum, ausfuehrender Person und der zurueckgegebenen `jobid`.
2. **`04b_verify_retention_schedule_read_only.sql` dort FAIL-frei** — 9 PASS,
   7 INFO, 0 FAIL. Dabei ist die INFO-Zeile `pg_cron_extension` mitzulesen:
   steht dort **nicht 1**, existiert zwar ein Eintrag in `cron.job`, aber
   niemand fuehrt ihn aus — dann ist das Gate **nicht** erfuellt.
3. **Job-History nachweislich kontrolliert.** Direkt nach dem Einrichten ist
   `cron.job_run_details` erwartungsgemaess leer; ein gruenes `04b` am
   Einrichtungstag belegt deshalb nur die Planung, nicht den Vollzug. Es
   braucht einen spaeteren, in Abschnitt 10 protokollierten Lauf von `04b`,
   dessen INFO-Zeile `laufhistorie` echte Laeufe zeigt und dessen Zeile
   `retention_job_ohne_fehlgeschlagene_laeufe` PASS meldet.

Solange keine der beiden Varianten in Abschnitt 10 eingetragen ist, bleibt der
Server-Schluessel ungesetzt und die Messung inaktiv. `04_retention.sql` bleibt
in jedem Fall der freigabepflichtige manuelle Loeschpfad — jeder einzelne Lauf
braucht eine eigene Freigabe.

| Gate | Zustand |
|---|---|
| `04a` auf Production ausgefuehrt | **nein** |
| `04b` auf Production FAIL-frei | **nein** |
| Job-History kontrolliert und protokolliert | **nein** |
| Scheduler damit eingerichtet | **nein — nur vorbereitet** |
| Verbindlicher, ueberwachter manueller Loeschlauf dokumentiert | **nein** |
| **Folge** | **`SUPABASE_SERVICE_ROLE_KEY` darf nicht gesetzt werden. Rollout bleibt gesperrt.** |

**GATE-STATUS: NICHT ERFUELLT**

Diese Zeile ist der maschinell gelesene Stand: der lokale Harness
(`static_retention_gate`) prueft, dass sie existiert und dass sie nicht
`ERFUELLT` meldet, solange Abschnitt 10 noch leer ist.

---

## 8 · Rollback

`05_rollback.sql` bestellt zuerst den geplanten Retention-Job ab und entfernt
dann Funktion, View, Tabelle und Schema — **ohne Kopie**.
Das ist Absicht: ein Rollback der Klick-out-Messung soll die Daten beseitigen
und nicht in ein Schattenarchiv verschieben, sonst waere er datenschutzrechtlich
kein Rollback.

Vorher: `SUPABASE_SERVICE_ROLE_KEY` aus der Vercel-Umgebung entfernen und den
Deploy abwarten. Der Route-Handler ueberspringt das Logging dann und leitet
unveraendert weiter — es entstehen keine Fehler, nur keine Daten mehr.

Wer Zahlen retten will, exportiert **vorher** bewusst die Aggregate aus
`cbb_private_analytics.click_outs_daily`. Ein Export der Rohereignisse ist
ausdruecklich nicht vorgesehen.

---

## 9 · Lokaler Test

`test/run_local_postgres_test.sh` prueft in **Stufe 1** ohne Datenbank:

- Read-only-Reinheit der beiden lesenden Dateien (genau ein Semikolon, keine
  schreibenden Schluesselwoerter, kein DO-Block)
- `SET LOCAL`-Position und `begin`/`commit`-Paarigkeit der drei schreibenden
  Dateien
- dass die Datenminimierung nicht still aufgeweicht wurde: die Spaltenliste der
  Tabelle stimmt mit der Feldliste des Route-Handlers ueberein, und in keiner
  SQL-Datei taucht ein verbotener Feldname auf (`ip`, `user_agent`, `referrer`,
  `email`, `query`)
- `sequence_hardening`: `02` entzieht der Identity-Sequenz alle Rechte und
  vergibt **genau einen** Grant (`USAGE` an `service_role`), und `03` prueft die
  Sequenzrechte selbst ueber `has_sequence_privilege`
- `retention_gate`: das harte Pre-enable-Gate aus Abschnitt 7 steht im Runbook,
  verweist auf `04a`/`04b` — und die Zeile `GATE-STATUS` widerspricht nicht dem
  Ausfuehrungsprotokoll in Abschnitt 10
- `retention_schedule`: Jobname, Schedule und Command stehen wortgleich in
  `04a`, `04b`, `05` und im Runbook; nur `04a` ruft `cron.schedule` auf (genau
  einmal), nur `05` ruft `cron.unschedule` auf (genau einmal), und die
  Drift-Guards sind vorhanden

**Stufe 2** braucht einen PostgreSQL-Cluster und faehrt den Ablauf
01 → 02 → 03 → 04a → 04b plus Negativfaelle gegen eine wegwerfbare lokale
Instanz. Fehlen die Binaries, meldet der Harness das klar, gibt Stufe 1
vollstaendig aus und endet mit **Exit 2** — das ist ausdruecklich weder PASS
noch FAIL der Rollout-Dateien.

**Belegter lokaler Stand (zuletzt wiederholt 2026-08-30, Codex-Audit):** Der vollstaendige Harness
lief gegen einen wegwerfbaren PostgreSQL-16-Cluster mit **118/118 PASS**, **0
Abweichungen** und Exit 0. Darin enthalten sind 13 statische Pruefungen sowie
die Datenbankfaelle A bis O, einschliesslich Drift, doppeltem Jobnamen,
fehlendem `pg_cron`, fehlgeschlagener Laufhistorie und Rollback mit aktivem
Job. Letzte Ergebnisdatei: `/tmp/cbb-pgtest-clicks.LydWhvbd/results.tsv`.

Dieser lokale PASS belegt die SQL-Logik und ihre Guards, **nicht** die
Einrichtung oder Ausfuehrung auf Production. Das Retention-Gate in Abschnitt 7
und der Production-Hold bleiben deshalb unveraendert.

`pg_cron` selbst laesst sich in einem wegwerfbaren Cluster nicht installieren.
Die Fixture `test/fixture/02b_cron_stub.sql` bildet deshalb `cron.job`,
`cron.job_run_details`, `cron.schedule` und `cron.unschedule` nach —
einschliesslich des **Ueberschreib-Verhaltens** bei gleichem Jobnamen, denn
genau davor schuetzen die Guards. Nicht nachgebildet ist die Ausfuehrung: im
Harness laeuft nichts zu irgendeiner Zeit, die Laufhistorie wird von Hand
gesetzt. Ein gruener Harness belegt damit die Planung und ihre Guards, **nicht**
dass auf Production tatsaechlich geloescht wird. Das belegt allein Punkt 3 des
Gates.

---

## 10 · Ausfuehrungsprotokoll

| Datum | Schritt | Ziel | Ergebnis |
|---|---|---|---|
| — | — | — | **Noch keine Production-SQL-Ausfuehrung.** Production-Hold aktiv. Retention-Gate (Abschnitt 7) bleibt **NICHT ERFUELLT**. |
| 2026-08-30 | PRE-DEPLOY-GATE (Abschnitt 5), read-only | Organisation "CrazyBaboBazar" (Ref `jjkoafzwtawtzcmrxexj`), Projekt "CrazyBaboBazar Project" (Ref `ydiihvzcxaaoqhmgoqvu`) | Dashboard Settings > General: Project region **West EU (Ireland)**, `eu-west-1` (primaerer Speicherort). Supabase Terms of Service **Version 3 — 1. August 2026** (Agreement gilt durch Zugriff/Nutzung, DPA ausdruecklich einbezogen). Supabase-DPA **Version 1 — 1. August 2026**; Auftragsverarbeiter/Datenimporteur ist **Supabase Pte. Ltd.**, 65 Chulia Street #38-02/03, OCBC Centre, Singapore 049513; DPA gilt ab Effective Date des Agreements; Annahme des Agreements wirkt wie Unterzeichnung der SCCs; fuer Controller→Processor gilt **Modul 2**. Offizielle Unterauftragsverarbeiterliste, **Stand 1. Juni 2026**: Amazon Web Services, Inc. = Hosting, Supabase, Inc. = Support (weitere Dienstleister gelistet); kein Hinweis, dass Supabase, Inc. der vertragliche Auftragsverarbeiter waere. Ergebnis: die drei Punkte des PRE-DEPLOY-GATE sind erfuellt; `apps/web/app/datenschutz/page.tsx` (Abschnitt 6) entsprechend korrigiert (Vertragspartei, Region, Unterauftragsverarbeiter-Hinweis, DPA-/Subprocessor-Links, veralteten TIA-Link entfernt). **Keine Production-Ausfuehrung, kein Rollout, keine Freigabe** — Retention-Gate (Abschnitt 7) bleibt **NICHT ERFUELLT**. |

Zusaetzlich offen: Retention-Gate (Abschnitt 7) — `04a`/`04b` auf Production
ausfuehren und Job-History kontrollieren — sowie die generelle Freigabe zum
Setzen von `SUPABASE_SERVICE_ROLE_KEY` (Abschnitt 5). Das PRE-DEPLOY-GATE
selbst (DPA/SCC-Kontostand, reale Projektregion) ist seit 2026-08-30 erfuellt
und oben protokolliert.
