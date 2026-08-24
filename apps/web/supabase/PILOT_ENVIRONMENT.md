# Value-Add-Pilotumgebung

Status: Der bestehende Pilot wurde bereits eingerichtet, befüllt und lokal
geprüft. Bootstrap, Seed, Backup und Backfill dürfen dort **nicht erneut**
ausgeführt werden.

Die aktuelle Live-Revalidierung vom 2026-08-23 ist vollständig bestanden.
Der anschließende lokale Runtime- und Screenshot-Audit auf Port 3001 ist
ebenfalls vollständig bestanden.

## Bestätigter Ist-Stand (2026-08-23)

- Pilot/Staging: `nmzuycveumyfvtxdcnuc.supabase.co`
- Production: `ydiihvzcxaaoqhmgoqvu.supabase.co`
- Der frühere Ablauf im Pilot umfasste Bootstrap, Seed, Backup und Backfill.
- Danach wurden 20 Produkte, 4 Kategorien, 7 Listen und 10 vollständig
  befüllte Pilotprodukte bestätigt: 3 Alternativen, 2 Ergänzungen und 5
  Pilotprodukte ohne Relation. Fünf Kontrollprodukte blieben unverändert.
- Die lokale technische und visuelle Produktseitenprüfung wurde anschließend
  als PASS bewertet.
- Ein erneuter Lauf des inzwischen verschärften Bootstrap-Skripts brach am
  2026-08-23 mit drei vorhandenen Zieltabellen ohne neuen privaten Marker ab.
  Der Guard ist das erste Statement nach `begin`; dadurch wurde bei diesem
  Wiederholungsversuch nichts geschrieben.
- Das Dashboard zeigte dabei eindeutig das Pilotprojekt
  `project/nmzuycveumyfvtxdcnuc` ("CrazyBaboBazar Pilot"). Production blieb
  unangetastet.

Der bestehende Pilot stammt aus einem Dateistand vor Einführung von
`pilot_meta.environment_guard`. Dieser fehlende Marker darf nicht ungeprüft
nachgerüstet werden. Löschen, Neuaufsetzen, Überschreiben und Marker-Nachrüstung
sind externe Schreibaktionen und benötigen eine separate Benutzerfreigabe.

## Read-only-Revalidierung

`verify_pilot_staging.sql` wurde am 2026-08-23 read-only im sichtbar
ausgewählten Pilotprojekt ausgeführt. Alle 15 fachlichen Prüfungen bestanden:

| Prüfpunkt | Ist | Status |
|---|---:|---:|
| Produkte / Kategorien / Listen | 20 / 4 / 7 | PASS |
| gefundene Zieltabellen / RLS aktiv | 3 / 3 | PASS |
| SELECT-Policies / Schreib-Policies | 3 / 0 | PASS |
| SELECT-Rechte / Schreibrechte der App-Rollen | 6 / 0 | PASS |
| vollständig befüllte Value-Add-Pilotprodukte | 10 | PASS |
| davon Alternativen / Ergänzungen / ohne Relation | 3 / 2 / 5 | PASS |
| inkonsistente Relationen / defekte Relationsziele | 0 / 0 | PASS |

Die fünf zusätzlichen INFO-Ergebnisse waren ebenfalls erwartungsgemäß:
Ausführung als `postgres`, Datenbank `postgres`, kein neuer Pilot-Marker, kein
neuer Snapshot und vorhandener Legacy-Snapshot
`pilot_value_add_backup_20260823`. Der fehlende neue Marker ist beim
Legacy-Pilot ausdrücklich zulässig. Bei künftigen Änderungen die Prüfung
erneut ausführen; bei einer Abweichung stoppen und nichts korrigieren oder
überschreiben.

## Feste Umgebungsgrenze

- Alle Pilot-SQL-Dateien dürfen ausschließlich im Pilotprojekt laufen.
- `.env.local` bleibt unverändert auf Production.
- Für lokale Pilotläufe sind ausschließlich `pilot:check`, `dev:pilot`,
  `build:pilot` und `start:pilot` vorgesehen.
- Normales `npm run dev`, `npm run build` und `npm run start` sind keine
  Pilotbefehle.

## Lokale Vorschau

Die Pilot-URL liegt in der ignorierten `.env.pilot.local`. Der Publishable-Key
soll bevorzugt nur im aktuellen Terminal als
`NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` exportiert werden; er muss nicht in der
Datei gespeichert werden. Bereits gesetzte Prozessvariablen haben Vorrang vor
dem leeren Dateiwert.

1. Den Publishable-/Anon-Key des Pilotprojekts im selben Terminal exportieren,
   aus dem die App gestartet wird. Den Key nicht in Chat, Logs oder Befehle im
   Shell-Verlauf kopieren. Secret- und Service-Role-Keys sind verboten.
2. `npm run pilot:check` prüft Zielprojekt und Key-Typ, ohne Next.js oder eine
   Datenbankverbindung zu starten.
3. `npm run dev:pilot` startet Next.js nur, wenn URL und Key den Pilot-Guard
   bestehen. `npm run build:pilot` und `npm run start:pilot` verwenden denselben
   Guard und das getrennte Build-Verzeichnis `.next-pilot`.

`.env.pilot.local` und `.next-pilot` sind durch `.gitignore` ausgeschlossen.
Der Guard zeigt den Key weder an noch schreibt er ihn in eine Datei.

## SQL-Dateien: historischer Ablauf und heutige Verwendung

Der historische Pilotablauf war:

1. `pilot_staging_bootstrap.sql`
2. `pilot_staging_seed.sql`
3. `backup_pilot_value_add.sql`
4. `backfill_pilot_value_add.sql`

Dieser Ablauf ist für den bestehenden Pilot **abgeschlossen**. Die vier Dateien
nicht erneut ausführen. Ihre aktuellen Guards und Snapshot-Namen können von dem
Dateistand abweichen, der damals tatsächlich im Dashboard lief.

Für ein künftig neu genehmigtes, leeres Wegwerfprojekt gilt weiterhin:

- Vor dem Bootstrap müssen `categories`, `products` und `lists` fehlen.
- Der aktuelle Bootstrap legt den privaten Marker, das Minimalschema,
  SELECT-Grants und RLS-Policies an.
- Die Value-Add-Spalten sind bereits enthalten;
  `add_value_add_fields.sql` wird dort nicht zusätzlich ausgeführt.
- Seed, Backup und Backfill prüfen den privaten Marker erneut.

## Bewusste Grenzen der Vorschau

- `swipes` ist nicht enthalten; `/entdecken` und `/entdecken/likes` gehören
  nicht zum Produktseiten-Pilot.
- Der `updated_at`-/Sitemap-Trigger ist nicht enthalten. Die Staging-Vorschau
  prüft Darstellung und Datenzugriff, nicht den Production-lastmod-Pfad.
- Kein Deployment, kein Merge, keine Search-Console-Aktion und kein
  Production-Schreibzugriff gehört zu diesem Ablauf.

## Aktueller lokaler Runtime-Audit (2026-08-23)

- `pilot:check` bestand mit der festen Pilot-URL und einem ausschließlich in
  der Terminal-Sitzung gesetzten Publishable-/Anon-Key.
- `dev:pilot` startete anschließend lokal auf `http://localhost:3001`.
- Die fünf repräsentativen Produktseiten `pinecil-usbc-loetkolben`,
  `divoom-pixoo-led-panel`, `sculpfun-s9-laser-engraver`,
  `seek-thermal-compact-usbc` und `mangoschneider-fruchthalter` lieferten
  jeweils HTTP 200.
- Zwei absichtlich nicht geseedete Production-Slugs (`flipper-zero` und
  `hoverair-x1-pro-drohne`) lieferten jeweils HTTP 404. Damit war die lokale
  Vorschau nachweislich an den begrenzten Pilotdatenbestand gebunden.
- Serverseitiger Text- und unabhängiger Headless-Chrome-Screenshot-Audit:
  Value-Add-Blöcke, Alternative, „Passt dazu“, relationloser Zustand und beide
  Kontrollzustände renderten erwartungsgemäß. Es gab keinen sichtbaren
  Layoutbruch.
- Claudes direkter Chrome-Zugriff blieb trotz Site-Freigabe an der
  Session-Berechtigung blockiert. Claude lieferte die Testmatrix; Codex führte
  HTTP-, DOM-/Text- und Screenshot-Audit unabhängig aus.

## Historischer Zwischenstand (2026-08-23, überholt)

> Dieser Absatz beschreibt den Stand **vor** dem lokalen PostgreSQL-Test und
> **vor** den Production-Schritten 2 bis 5b. Er ist als Historie festgehalten und
> gilt nicht mehr als aktuelle Lagebeschreibung.
>
> „Das getrennte Production-Paket unter `supabase/production_value_add/` ist
> lokal erstellt und statisch auditiert, aber noch nicht mit seinen schreibenden
> Dateien gegen PostgreSQL probegelaufen. Der Production-Read-only-Preflight
> wurde am 2026-08-23 im sichtbar bestätigten Projekt `ydiihvzcxaaoqhmgoqvu`
> ausgeführt und unabhängig auditiert: alle neun harten Prüfungen PASS, keine
> FAIL-Zeile, sauberer Zustand `0/8 + 0/2`, zehn veröffentlichte Zielprodukte
> und fünf veröffentlichte Relationsziele. Vor einer späteren
> Production-Migration ist ein Probelauf der schreibenden Dateien auf einem
> isolierten Production-Klon/Branch bzw. echtem PostgreSQL Pflicht."

Die damals geforderte Bedingung ist inzwischen erfüllt: der Probelauf gegen
echtes PostgreSQL hat stattgefunden (siehe unten).

## Aktueller Stand des Production-Pakets (2026-08-23)

Die Pilot-Datenbank und die lokale Pilot-App sind für diesen Pilotstand
vollständig revalidiert. Für das getrennte Production-Paket unter
`supabase/production_value_add/` gilt jetzt:

- **Lokaler Test.** Der verschärfte Harness ist auf dem aktuellen Dateistand
  **dreimal** vollständig gelaufen — jeweils **73 von 73 Schritten PASS,
  0 Abweichungen, Exit 0**, gegen einen isolierten temporären PostgreSQL-Cluster
  ohne Production- oder Pilot-Kontakt. Belege:
  `production_value_add/LOCAL_POSTGRES_TEST_REPORT.md`, Abschnitte 7.2 und 13.1.
- **Production-Schritte 1 bis 5b sind ausgeführt und auditiert** —
  Read-only-Preflight, additive Migration, privater Snapshot, atomarer Backfill,
  die read-only Nachprüfung `05_verify_read_only.sql` (16 Zeilen, 14 PASS,
  2 INFO, 0 FAIL) und die read-only Sicherheitsprüfung
  `05b_verify_payload_security_read_only.sql` (16 Zeilen, 9 PASS, 7 INFO,
  0 FAIL). Jeder Schritt lief nach einer eigenen ausdrücklichen
  Benutzerfreigabe, manuell durch den Benutzer, im sichtbar bestätigten Projekt
  `ydiihvzcxaaoqhmgoqvu`.
- **Die Absicherung des privaten Snapshots** `value_add_pre_backfill_v1` ist auf
  Production belegt: RLS aktiv, 0 Policies, keine Rechte für PUBLIC, `anon` oder
  `authenticated` — weder auf der Tabelle noch auf dem Schema
  (`03_verify_snapshot_read_only.sql`, 15 harte PASS, 0 FAIL).
- **Ebenfalls belegt: die Absicherung der Audit-Payload**
  `value_add_payload_v1` aus Schritt 4. `05` prüft diese Tabelle nur
  **inhaltlich** (10 Zeilen, 0 Abweichungen) und liest für sie keinen
  Katalogwert; diese Lücke schließt `05b`. Die Datei war zuerst **lokal positiv
  und negativ getestet und auditiert** (ein positiver und neun negative Fälle,
  alle exakt wie erwartet; Beleg:
  `production_value_add/LOCAL_POSTGRES_TEST_REPORT.md`, Abschnitt 16) und wurde
  danach nach eigener ausdrücklicher read-only Freigabe („Ich gebe
  Production-Schritt 5b (read-only Payload-Sicherheitsprüfung) auf
  `ydiihvzcxaaoqhmgoqvu` frei.") auf Production ausgeführt — Dateistand
  unverändert, 9 harte PASS, 0 FAIL. Auf Production gemessen sind damit:
  Tabelle vorhanden, 10 Zeilen, 10/10 erwartete Spalten, RLS aktiv, 0 Policies,
  Primärschlüssel genau `PK(slug)`, App-Rollen 2/2 und **keine Rechte für
  PUBLIC, `anon` oder `authenticated`** — weder direkte ACL-Einträge noch
  effektive, über Rollenmitgliedschaft geerbte Privilegien, weder auf der
  Tabelle noch auf dem Schema. Beleg: Abschnitt 17 desselben Berichts. Der
  lokale Test war ein **eigener** Lauf und **nicht** Teil der drei
  73/73-Harness-Läufe; der Harness selbst blieb unverändert.
- **`service_role` bleibt INFO, ohne PASS-Zusage.** `05b` gibt für sie nur
  Ist-Werte aus; gemessen ist für diesen Zustand: Rolle vorhanden,
  `bypassrls` true, keine direkten ACL-Einträge und keine effektiven Tabellen-
  oder Schemarechte. Das ist ein dokumentierter Ist-Zustand, keine allgemeine
  Sicherheitszusage — eine Bewertung dieser Rolle braucht einen eigenen,
  getrennt freigegebenen Vorgang.

> **Überholt (historisch).** Hier stand bis zum Production-Lauf von `05b`:
> „**Offen: die Absicherung der Audit-Payload** … auf Production **nicht
> gemessen** … **weiterhin nicht für Production freigegeben und dort nicht
> ausgeführt** … Sie ist der **nächste ausdrückliche read-only Freigabepunkt**."
> Das gilt nicht mehr.

**Nächster sinnvoller Vorgang — rein lokal, ohne Freigabe.** Ein
**Code-/Deploy-Readiness-Audit** des Frontends (Rendering der Value-Add-Felder,
Sitemap-/`lastmod`-Pfad, Revalidation). Die zehn `updated_at`-Werte aus Schritt 4
sind live, die zugehörigen Code-Änderungen dieses Branches nicht. Dieser Audit
ist **ausdrücklich keine Freigabe für Merge oder Deploy**.

## Weiterhin gesperrt

- `06_restore_value_add.sql` und `07_down_migration.sql` sind **nicht
  ausgeführt**; sie sind reine Rollback-Artefakte und brauchen jeweils eine
  eigene neue Freigabe, `07` zusätzlich erst nach erfolgreichem Restore.
- Commit, Merge, Push nach `main` und Vercel-Deploy.
- Eine Marker-Nachrüstung, ein Reset oder jede andere Schreibaktion im Pilot.
- Jede weitere Production-Aktion, schreibend wie lesend. Die Freigaben für die
  Schritte 2 bis 5b waren jeweils auf ihre Datei beschränkt und sind verbraucht;
  **kein weiterer Production-DB-Schritt ist freigegeben**, und dieses Dokument
  erteilt keine neue Freigabe.
