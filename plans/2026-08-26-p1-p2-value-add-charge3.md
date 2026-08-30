# P1/P2/Value-Add-Charge-3 — lokaler Arbeitsplan

Datum: 2026-08-26
Status: in Arbeit
Production-Hold: aktiv

## Ziel

Die drei priorisierten Blöcke lokal vollständig vorbereiten und testen:

1. P1 — consent-gebundene, datensparsame Klick-out-Messbarkeit
2. P2 — sichtbare und zugängliche Affiliate-CTAs auf Karten und Produktseiten
3. Value-Add-Charge 3 — disjunktes, transaktionales Datenpaket mit Snapshot,
   Payload-Audit, Restore und lokalem PostgreSQL-Harness

## Sicherheitsgrenzen

- keine Production-Datenbankaktion
- kein Deploy, Push oder Merge
- keine Änderung externer Konten
- keine Secrets lesen, anzeigen oder verändern
- Affiliate-Weiterleitung muss auch ohne Consent und bei Logging-Fehlern
  funktionieren
- keine persistenten Identifikatoren ohne ausdrücklichen Consent
- bestehende Batch-1-/Batch-2-Artefakte bleiben byte-identisch

## Abnahme

- vollständiger Diff-Audit durch Codex
- Typecheck, Lint, Tests und Production-Build grün
- P1-Routen-/Consent-/Fail-open-Tests grün
- P2 mobil, Tastatur und Semantik geprüft
- Charge-3-Harness grün; Zielmenge disjunkt und Quellenbindung dokumentiert
- Money Wiki nennt lokalen Stand und Production-Hold korrekt

## Umsetzungsstand 2026-08-26 (Claude-Worker)

Alle drei Blöcke sind lokal geschrieben. **Kein einziges Qualitätsgate konnte
ausgeführt werden** — siehe „Offener Blocker".

### P1 — Klick-out-Messbarkeit

- `lib/affiliate.ts` — Merchant-Allowlist, Pfad-Sanitisierung, Geräteklasse
- `lib/consent-cookie.ts` — der serverseitig prüfbare First-Party-Consent-Cookie
  `cbb_consent_clickout_v2` (`SameSite=Lax`, `Secure` unter HTTPS, `Path=/`)
- `lib/consent.ts` — eine gemeinsame Consent-Store-Instanz über diesem Cookie
- `lib/click-session.ts` — Sitzungskennung, erst nach `accepted` und erst beim
  echten Klick, ausschließlich sessionStorage
- `app/api/click/[slug]/route.ts` — fail-open Redirect, fail-closed Ziel
- `components/ui/affiliate-link.tsx` — der eine CTA der App
- `app/datenschutz/page.tsx` — neuer Abschnitt 6, Abschnitte 7–9 neu nummeriert
- `components/ui/cookie-consent.tsx` — wahrheitsgemäßer Hinweis, Widerruf räumt auf
- `supabase/production_clickouts/` — Tabelle, RLS, Grants, Indizes, private
  Auswertungs-View, Retention-Funktion, Rollback, Runbook, Harness

### P2 — Conversion-UX

- `components/product-grid.tsx` — Hover-CTA entfernt, dauerhafter CTA im Footer,
  keine verschachtelten Links mehr, 44 px Touch-Ziel
- `app/produkt/[slug]/page.tsx` — CTA oberhalb der Beschreibung, mobile
  Sticky-Leiste (z-index 90 unter dem Cookie-Hinweis mit 200)
- `components/ui/sticky-affiliate-bar.tsx` — neue Leiste
- `components/guide-finder.tsx` — auf `AffiliateLink` umgestellt
- `app/design-preview/preview-client.tsx` — bewusst NICHT umgestellt, Begründung
  steht als Kommentar an Ort und Stelle

### Value-Add-Charge 3

- `supabase/production_value_add_batch3/` — 01, 02, 02b, 03, 04, 04b, 05,
  Runbook, Testbericht, vollständiger Harness mit Fixture und Negativfällen
- Zielmenge: die zehn im Runbook §2 begründeten Slugs aus der 30-URL-Kohorte,
  disjunkt zu Batch 1 und Batch 2
- `test/V1_V2_MANIFEST.sha256` — **74/74 Dateien byte-identisch** gegengeprüft

## Offener Blocker

`npm`, `node` und `bash`-Skripte sind in der Worker-Sandbox nicht ausführbar,
PostgreSQL ist nicht installiert. Damit sind **nicht** ausgeführt:

| Gate | Status |
|---|---|
| `npm test` | nicht ausgeführt |
| `npm run typecheck` | nicht ausgeführt |
| `npm run lint` | nicht ausgeführt |
| `npm run build` | nicht ausgeführt |
| `production_clickouts/test/run_local_postgres_test.sh` | nicht ausgeführt |
| `production_value_add_batch3/test/run_local_postgres_test.sh` | nicht ausgeführt |

Zusätzlich fehlt beiden Harness-Skripten das Ausführungsbit (`chmod +x`), weil
auch `chmod` nicht freigegeben war.

**Vor jeder weiteren Bewertung sind diese sechs Gates nachzuholen.**
Der Production-Hold bleibt unverändert bestehen.

## Korrekturrunde 2026-08-26 — Consent v2 (Codex-Auditbefunde 1–3)

Der Audit hat drei Befunde gegen den P1-Stand erhoben. Alle drei sind
adressiert; der Umbau bleibt strikt auf P1 begrenzt, P2 und Charge 3 sind
unberührt.

**Befund 1 — Consent-Integrität.** Die Route hat jede syntaktisch gültige
`cs`-UUID im Query als Einwilligung behandelt; ein fremd konstruierter Link
hätte ohne Nutzerentscheidung einen Datensatz erzeugt. Die Einwilligung liegt
jetzt in einem First-Party-Cookie, den nur die ausdrückliche Accept-/Decline-
Aktion setzt. `app/api/click/[slug]/route.ts` schreibt nur noch, wenn der
Cookie exakt `accepted` trägt **und** `cs` UUID-Form hat. Query-UUID allein → 0
Inserts.

**Befund 2 — Scope der Einwilligung.** Der alte Schlüssel
`cbb-cookie-consent-v1` (localStorage) deckte den neuen Messzweck nicht ab. Er
wird weder gelesen noch migriert noch gelöscht. Neuer, eigener Name
`cbb_consent_clickout_v2` als Zweckgrenze; wer v1 zugestimmt hatte, entscheidet
neu.

**Befund 3 — ESLint `react-hooks/set-state-in-effect`.** Der Effekt in
`affiliate-link.tsx` ist ersatzlos entfallen — ohne `eslint-disable`. Die
Sitzungskennung entsteht jetzt in den Ereignis-Handlern der tatsächlichen
Aktivierung (`onPointerDown`, `onMouseDown`, `onFocus`, `onClick`), die das
`href` zusätzlich direkt am Element dekorieren. Das erste `href` ist auf Server
und Client identisch und damit hydrierungsstabil; ohne JavaScript und ohne
Consent funktioniert die Weiterleitung unverändert.

**Was der Cookie enthält:** genau `accepted` oder `declined`. Keine Kennung,
keine Nummer, kein Zeitstempel. Die Sitzungskennung bleibt ausschließlich im
`sessionStorage` und kommt nie in einen Cookie.

Geänderte Dateien: `lib/consent-cookie.ts` (neu), `lib/consent.ts`,
`lib/click-session.ts` (nur Kommentar), `app/api/click/[slug]/route.ts`,
`components/ui/affiliate-link.tsx`, `components/ui/cookie-consent.tsx`,
`app/datenschutz/page.tsx`, `supabase/production_clickouts/RUNBOOK.md`.
Tests: `lib/consent-cookie.test.ts` (neu), `lib/consent.test.ts` (neu),
`app/api/click/[slug]/route.test.ts`, `components/ui/affiliate-link.test.tsx`.

**Die sechs Gates oben sind weiterhin nicht ausgeführt** — `npm`, `npx` und die
lokalen Binaries sind auch in dieser Runde nicht freigegeben. Der Stand ist
geschrieben, nicht verifiziert.

## Korrekturrunde 2 · 2026-08-26 — Consent-Widerruf, Sequenzrechte, Charge-3-Ersatz

Zweite, streng begrenzte lokale Korrekturrunde. Kein Commit, kein Push, kein
Deploy, kein Datenbankzugriff (weder lesend noch schreibend), kein Netz, keine
Money-Wiki-Änderung, keine `.env` gelesen oder geändert.

### 1 · P1 — Widerruf und ehrliche Datenschutz-UX

- `components/ui/consent-settings-button.tsx` (neu) — natives `<button>`,
  ruft `consentStore.clearConsent()`. Löscht Entscheidungs-Cookie **und**
  Sitzungskennung; der Banner erscheint ohne Reload wieder, weil Knopf und
  Banner an derselben Store-Instanz hängen.
- `app/layout.tsx` — der Knopf steht dauerhaft im Footer unter „Rechtliches".
- `components/ui/cookie-consent.tsx` — „keine Tracking-Cookies" ersetzt durch
  die wahre Aussage: keine Werbe-/Profiling-Cookies, aber ein funktionaler
  Entscheidungs-Cookie mit 182 Tagen Laufzeit und consent-gebundene
  Klickmessung. Widerrufsweg genannt.
- `app/datenschutz/page.tsx` — First-Party-Entscheidungs-Cookie, exakt
  182 Tage / rund sechs Monate, Sitzungs-UUID nur nach Einwilligung im
  `sessionStorage`, Ereignisse **pseudonymisiert/datensparsam** statt „anonym",
  Widerruf über den Footer-Knopf als erster Weg (Browserdaten-Löschen bleibt
  nur eine Alternative).
- `components/ui/consent-settings-button.test.tsx` (neu) — 4 Tests: Semantik
  und Tastaturbedienbarkeit, Widerruf inkl. Session-ID-Löschung und erneutem
  Banner, Widerruf einer Ablehnung, kein Nebeneffekt ohne vorherige
  Entscheidung.

### 2 · P1 — Sequenzrechte und Retention-Gate

- `supabase/production_clickouts/02_create_clickouts.sql` — `revoke all` auf
  `public.click_outs_id_seq` von `PUBLIC`, `anon`, `authenticated`,
  `service_role`; danach **nur** `grant usage` an `service_role`. Neuer
  fail-closed Guard gegen eine bereits existierende gleichnamige Sequenz
  (sonst hieße die neue `…_seq1` und der Entzug träfe die falsche). Die
  Selbstprüfung am Ende der Transaktion prüft Name und effektive Rechte.
- `03_verify_read_only.sql` — neue harte Prüfzeile
  `click_outs_sequenzrechte` (Sortierung 185). Erwartung jetzt
  **17 PASS / 6 INFO**, vorher 16/6.
- `app/api/click/[slug]/route.ts` — HTTP-non-2xx der Insert-Antwort gilt jetzt
  als Fehlerpfad (`res.ok`), bleibt aber fail-open. Ein einziger, datensparsamer
  Log-Kanal: nur Statuscode bzw. Fehlerart, **keine** Ziel-URL, kein
  Cookie-Inhalt, keine Kennung, kein Slug.
- `route.test.ts` — fokussierter 500-Test plus Gegenprobe „201 meldet nichts".
- `test/run_local_postgres_test.sh` — zwei neue statische Prüfungen
  (`sequence_hardening`, `retention_gate`), neuer DB-Fall `case_i_sequenzloch`,
  Erwartungszahlen 16→17 bzw. 15/1→16/1 angepasst.
- `test/cases/assert_after_02.sql` und `assert_rechte_wirken.sql` — Katalog-
  und Wirksamkeitsbeweis für die Sequenzrechte.
- `RUNBOOK.md` — **hartes PRE-ENABLE-GATE**: Der Rollout darf nicht scharf
  geschaltet werden (`SUPABASE_SERVICE_ROLE_KEY` setzen), solange kein
  Scheduler ODER kein verbindlich dokumentierter, überwachter wiederkehrender
  12-Monats-Löschlauf existiert. Kein Scheduler und kein DB-Job wurden angelegt;
  `04_retention.sql` bleibt der freigabepflichtige Löschpfad.

### 3 · P2 — Textkorrektur

- `app/produkt/[slug]/page.tsx` — „Aktueller Preis auf Amazon" →
  „Preisband zur Orientierung". `price_cents` ist ein manuell gepflegter Wert;
  eine Aktualitätszusage wäre durch die Datenquelle nicht gedeckt.
- `app/produkt/[slug]/page.test.tsx` — Test dafür ergänzt.

### 4 · Value-Add-Charge 3 — VIVO gesperrt, Bartesian ersetzt

- `vivo-hoehenverstellbares-stehpult` ist wegen eines belegten
  **Produktidentitätskonflikts** (Merchant-Link → gasgefederter Aufsatz
  `B075JYG2TB`, Beschreibung → teils elektrischer Volltisch) vollständig aus
  allen ausführbaren Mengen entfernt. Es erscheint nur noch als
  `AUSGESCHLOSSEN`-Finding im Runbook (Abschnitt 2.1).
- Ersatz: `bartesian-cocktailmaschine-mit-kapseln`, mit vorsichtiger, aus
  `import_products_batch19.sql`, `expand_descriptions_batch3.sql`,
  `add_editorial_notes_batch5.sql` und
  `lib/guides/beste-kuechen-gadgets-2026.ts` belegter Payload. Keine
  Alkohol-/Gesundheitsaussage, „Barqualität" ausdrücklich **nicht** übernommen;
  Folgekosten (Kapseln, Spirituosen), Stellflächenbedarf und die nötige
  Händlerprüfung stehen als `cons`.
- Relation neu: `dicmky --alternative--> laptop-staender`, dazu weiterhin
  `laptop-staender --complement--> tecknet`. Das ist eine **Kette**, kein Kreis;
  nur das Kettenende `tecknet` bleibt relationslos. Prüfname und Erwartung
  entsprechend `kettenende_bleibt_relationslos = 1` (vorher
  `relationsziele_bleiben_relationslos = 2`).
- DICMKY nennt **keine** Traglast mehr — weder 10 kg noch 15 kg, auch nicht als
  „widersprüchliche Repo-Angabe". Der Quellenkonflikt ist im Runbook
  dokumentiert, nicht auf der Produktseite.
- Zielmenge weiterhin genau **10 disjunkte** Slugs; Batch 1 und Batch 2 sind
  byte-identisch unberührt.
- Neue Preflight-Warnung im Charge-3-Runbook zu
  `apps/web/supabase/restore_affiliate_urls.sql` (kann falsche/stale
  Zuordnungen wiederherstellen, u. a. VIVO/DICMKY). Die Datei selbst wurde in
  dieser Runde **nicht** geändert.
- `LOCAL_TEST_REPORT.md` wahrheitsgemäß aktualisiert: Stufe 1 lief vor dieser
  Runde mit **19/19 PASS** (Codex), Stufe 2 lief mangels
  `psql`/`initdb`/`pg_ctl`/Docker/Podman nie. Durch die Änderungen dieser Runde
  ist das Stufe-1-Ergebnis **stale** und muss neu laufen.

### Gates in dieser Runde

Unverändert blockiert. In dieser Worker-Sitzung sind `npm`, `npx`, `bash` und
`node <skript>` nicht freigegeben; jeder Aufruf endete mit
„This command requires approval", bevor irgendetwas startete. **Nichts wurde
umgangen.** Es gilt weiterhin:

| Gate | Status |
|---|---|
| `npm test` | nicht ausgeführt (Terminalberechtigung) |
| `npm run typecheck` | nicht ausgeführt (Terminalberechtigung) |
| `npm run lint` | nicht ausgeführt (Terminalberechtigung) |
| `npm run build` | nicht ausgeführt (Terminalberechtigung) |
| `CBB_STATIC_ONLY=1 …/production_clickouts/test/run_local_postgres_test.sh` | nicht ausgeführt (Terminalberechtigung) |
| `CBB_STATIC_ONLY=1 …/production_value_add_batch3/test/run_local_postgres_test.sh` | nicht ausgeführt (Terminalberechtigung) |

Lesend geprüft und sauber: `git diff --check` (keine Ausgabe) und
`git status --short`. Der Production-Hold bleibt unverändert bestehen.

## Ergebnisstand 2026-08-27 — Gates von Codex ausgeführt

Die lokale Implementierung der drei Blöcke ist fertig. Die oben als blockiert
geführten Gates hat inzwischen **Codex** ausgeführt:

| Gate | Ergebnis |
|---|---|
| `npm test` | 17 Testdateien, 279 Tests grün |
| `npm run typecheck` | Exit 0 |
| `npm run lint` | Exit 0 |
| `npm run build` | 441/441 Seiten erzeugt |
| `production_clickouts` — Stufe 1 (statisch) | 10/10 PASS |
| `production_value_add_batch3` — Stufe 1 (statisch) | 19/19 PASS, Manifest 74/74 `OK` |
| **Beide DB-Stufen (Stufe 2)** | **nicht bewertet** — `psql`/`initdb`/`pg_ctl` fehlen, weder Docker noch Podman vorhanden |

**Keinerlei Production-Aktion:** kein Commit, kein Push, kein Merge, kein Deploy,
kein Datenbankzugriff. Der Production-Hold bleibt bestehen; ein Rollout braucht
grüne Stufe 2 **und** eine neue ausdrückliche Benutzerfreigabe.

### Dritte lokale Korrekturrunde 2026-08-27

- `components/ui/affiliate-link.tsx` — neue optionale Prop
  `measurementEnabled` (Default `true`). Bei `false` bleibt das `href` die
  interne `/api/click/<slug>`-Route, es entsteht aber selbst bei erteiltem
  Consent nie eine Kennung — kein `cs`, kein `sessionStorage`-Schreibvorgang.
- `app/design-preview/preview-client.tsx` — der letzte direkte
  `href={product.affiliate_url}` der App ist ersetzt durch `AffiliateLink`
  mit `measurementEnabled={false}`. Styling, Merchant-Label, `rel` und `target`
  unverändert; der Kommentar nennt jetzt den wahren Grund. Damit findet `rg`
  in `app/` und `components/` keinen direkten Partnerlink mehr.
- `components/ui/affiliate-link.test.tsx` — Tests für den Messungs-Aus-Fall und
  ein statischer Regressionsschutz gegen den Design-Preview-Direktlink.
- `components/ui/cookie-banner.tsx` — war unbenutzter Altcode mit eigenem
  localStorage-Consent; jetzt ein reiner Re-Export von `CookieConsent`. Kein
  zweites Consent-System mehr im Repo, kein öffentlicher Name entfernt.
- `supabase/production_value_add_batch3/03_backfill_value_add_batch3.sql` —
  eine Zeichenkette quellenpräziser: „Der Hersteller nennt …" → „Die vorhandene
  Produktbeschreibung nennt … über 40 Cocktail-Varianten". Sonst keine
  Payload-Änderung.
- `supabase/production_value_add_batch3/LOCAL_TEST_REPORT.md` — auf den belegten
  Stand gebracht (Stufe 1 grün, Stufe 2 nie gelaufen, Production-Hold aktiv).

Die Testzahl oben (279) stammt aus Codex' Lauf **vor** dieser Runde; diese Runde
hat Tests ergänzt. Die endgültige Zahl trägt Codex nach dem nächsten Lauf nach.

## Gate-Lauf 2026-08-30 — Claude, nach der dritten Korrekturrunde

Der Codex-Lauf vom 2026-08-27 lag **vor** der dritten Korrekturrunde und war damit
veraltet. Alle Gates wurden neu ausgeführt. Umgebung: Node v20.20.2, npm 10.8.2,
Arbeitsverzeichnis `apps/web`.

| Gate | Ergebnis | Vorher (Codex 27.08.) |
|---|---|---|
| `npm run typecheck` | **Exit 0** | Exit 0 |
| `npm run lint` | **Exit 0** | Exit 0 |
| `npm test` | **19 Dateien, 304 Tests grün** | 17 Dateien, 279 Tests |
| `npm run build` | **Exit 0, 441 Seiten** | 441/441 Seiten |
| `production_clickouts` Stufe 1 | **13/13 PASS** | 10/10 PASS |
| `production_value_add_batch3` Stufe 1 | **19/19 PASS**, Manifest 74/74 `OK` | 19/19 PASS |

Die dritte Korrekturrunde hat **25 Tests** und **3 statische Prüfschritte** ergänzt;
alle sind grün. Die im Plan offen gelassene Testzahl ist damit nachgetragen.

### Stufe 2 weiterhin nicht bewertet

`psql`, `initdb`, `pg_ctl`, `docker` und `podman` sind auf diesem Rechner **nicht
installiert**. Beide Harnesse enden korrekt mit Exit 2 („UMGEBUNG UNVOLLSTAENDIG") —
das ist ausdrücklich **kein** FAIL der Rollout-Dateien, sondern eine nicht bewertete
Prüfebene.

Zwei mögliche Wege, beide freigabepflichtig:

1. **PostgreSQL lokal installieren** (`sudo apt install postgresql`) — Systemänderung.
2. **Supabase-Dev-Branch** anlegen und die Harnesse dagegen laufen lassen — externe
   Systemänderung, möglicherweise kostenpflichtig, aber näher am echten Zielsystem.

### Zusätzlicher Befund aus dem Harness-Lauf

`production_clickouts` Schritt 011 meldet: **`GATE-STATUS: NICHT ERFUELLT`**.
Das harte Pre-Enable-Gate aus dem Runbook ist korrekt verankert, aber die Bedingung
(Scheduler **oder** verbindlich dokumentierter, überwachter 12-Monats-Löschlauf) ist
nicht erfüllt. Solange das so bleibt, darf die Klick-out-Messung in Production nicht
scharf geschaltet werden — unabhängig von Stufe 2.

**Production-Hold bleibt unverändert bestehen.** Kein Commit, kein Push, kein Deploy,
kein Datenbankzugriff in diesem Lauf.

## Finaler lokaler Abschluss 2026-08-30 — Codex-Audit

Die oben als „Stufe 2 weiterhin nicht bewertet" dokumentierte Aussage ist
historisch und wird durch diesen Abschnitt ersetzt. Codex hat beide Harnesse mit
einem portablen PostgreSQL 16.15 vollständig gegen wegwerfbare lokale Cluster
ausgeführt. Production und Pilot/Staging wurden dabei nicht berührt.

### Abgeschlossene Arbeitsblöcke

- **Engine-Routing:** Der sichtbare Claude-Runner liest `agent:` aus dem
  Prompt-Frontmatter, mappt ausschließlich die in
  `.claude/agents/engine-routing.md` erlaubten Aliasse und beendet die
  Optionsauswertung vor einem mit `---` beginnenden Prompt. Jobzustand und
  Modellargumente werden zwischen Aufträgen zurückgesetzt.
- **Affiliate-CTA/Disclosure:** `Anzeige · Affiliate-Link` bleibt an allen
  direkten CTAs sichtbar und Teil des zugänglichen Namens. Preisfilter haben
  echte Labels, Auswahlbuttons melden ihren Zustand, das Design-Preview-Overlay
  wird auch bei Tastaturfokus sichtbar, dekorative Icons sind ausgeblendet und
  Affiliate-Links verwenden `touch-action: manipulation`.
- **F1 Datenschutz:** Supabase ist als Datenbankdienst/Empfänger der
  consent-gebundenen Klick-Messung einschließlich Anbieteranschrift,
  Datenumfang, möglicher Drittlandverarbeitung, SCC-Mechanismus und
  Anbieterquellen dokumentiert. Es wird keine unbelegte Projektregion genannt.
- **Lokale Quick Wins:** A1 (drei statt vier Personas), A2 (read-only
  Bestandszählung), A3 (bereits geladene Produktmenge statt Festzahl) und C6
  (kanonisches sichtbares Label `Tech`) sind im Repo erledigt.

### Finale lokale Gates

| Gate | Ergebnis |
|---|---|
| `npm test` | **21 Dateien, 325 Tests grün** |
| `npm run typecheck` | **Exit 0** |
| `npm run lint` | **Exit 0** |
| `npm run build` | **Exit 0, 441/441 Seiten** |
| Engine-Routing-Harness | **41/41 PASS**, echter Runner mit Stub-`claude`, kein versteckter Claude-Aufruf |
| `production_clickouts` PostgreSQL-Harness | **118/118 PASS**, 0 Abweichungen, Exit 0; `/tmp/cbb-pgtest-clicks.LydWhvbd/results.tsv` |
| `production_value_add_batch3` PostgreSQL-Harness | **108/108 PASS**, 0 Abweichungen, Exit 0; `/tmp/cbb-pgtest-b3.rKRQhnbA/results.tsv` |
| `git diff --check` | **Exit 0**, keine Ausgabe |

Nach dem vollständigen Web-Gate wurde nur noch der zustandswirksame Klick des
Design-Preview-Filters und eine echte Hover-Rückmeldung am Preisfilter ergänzt;
die sieben betroffenen Testdateien liefen danach erneut mit **82/82 PASS**. Der
abschließende Voll-Gate-Lauf wird im Commit-/Audit-Protokoll als finale
Evidenz geführt.

### Verbleibende Grenzen und nächste Prioritäten

1. **Production-Hold bleibt aktiv.** Kein Production-DB-Write, kein Deploy,
   kein `main`-Push/-Merge und keine externe Schreibaktion fand statt.
2. Das Retention-Pre-enable-Gate ist weiterhin **NICHT ERFÜLLT**. Der
   `SUPABASE_SERVICE_ROLE_KEY` darf für Klick-Messung nicht gesetzt werden.
3. Der konkrete Supabase-DPA/SCC-Kontostand und die reale Projektregion sind
   im Repo nicht belegbar. Beides ist vor dem ersten Production-Write
   read-only zu verifizieren und im Click-out-Runbook zu protokollieren.
4. A4, A5, B2, B5, D6 und D7 sind konkrete Production-Datenkorrekturen. Ihre
   Fundorte sind read-only belegt; die Ausführung braucht ausdrückliche
   Benutzerfreigabe.
5. W4 der Search-Console-Wirkungsmessung bleibt **2026-09-23**. Vorher gibt es
   keine belastbare Nachher-Aussage.
