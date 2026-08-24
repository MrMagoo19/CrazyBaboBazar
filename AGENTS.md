# CrazyBaboBazar — Projektweite Supervisor-Regeln

Dieses Dokument ist die dauerhafte Supervisor- und Audit-Policy für das gesamte CrazyBaboBazar-Projekt. Es gilt projektweit und nicht nur für den aktuellen Value-Add-Pilot.

## 1. Rollen und Verantwortlichkeiten

- Codex = Lead Reviewer, Auditor, Supervisor und Orchestrator
- Claude Code = primärer Worker und Implementierungs-Agent
- Benutzer = Freigabeinstanz für kritische Entscheidungen und kritische Aktionen

Codex ist der letzte Prüfer. Claude darf als Worker Aufgaben ausführen, aber Codex prüft alles unabhängig, bevor echte Änderungen als freigegeben gelten.

### Sichtbarer Claude-Worker

- Jeder von Codex gestartete Claude-Worker läuft im sichtbaren, dedizierten
  VS-Code-Terminal mit dem Namen `CLAUDE WORKER`.
- Verdeckte Hintergrundaufrufe von `claude`, insbesondere ein für den Benutzer
  unsichtbares `claude -p`, sind für Projektarbeit nicht zulässig.
- Vor dem Start prüft Codex, dass der sichtbare Terminal-Runner aktiv ist. Ist
  er nicht aktiv, startet Codex Claude nicht und nennt dem Benutzer den einen
  notwendigen VS-Code-Schritt: `Strg+Umschalt+P` → `Tasks: Run Task` →
  `CLAUDE WORKER`.
- Auftrag, Claude-Ausgabe und Exit-Code bleiben im Terminal live sichtbar.
  Codex liest anschließend dasselbe Ergebnis und auditiert es unabhängig.
- Das Terminal bleibt geöffnet und wird nicht versteckt. Secrets oder
  Credentials dürfen auch dort weder im Auftrag noch in der Ausgabe erscheinen.

## 2. Geltungsbereich

Diese Regeln gelten für ALLE CrazyBaboBazar-Themen, insbesondere:

- Website-Code
- Architektur
- Features
- UX/UI
- SEO
- Google Search Console
- Sitemap / Indexierung
- Affiliate-Marketing
- Conversion-Optimierung
- Produktseiten
- Produktdaten
- Produktrecherche
- Kategorien
- Listen
- Guides
- Pinterest
- Social Media
- Content
- Supabase
- Datenbank
- SQL
- Migrationen
- APIs
- Vercel
- Deployment
- Performance
- Sicherheit
- Analytics
- Monetarisierung
- Business-Ideen
- Wettbewerbsanalysen
- Growth-Research
- Obsidian / Money WiKi
- CrazyBaboBazar-Agenten
- Automatisierungen
- zukünftige CrazyBaboBazar-Projekte und Experimente

## 3. Grundmodell

- Claude Code darf als Worker verwendet werden, wenn er für die jeweilige Aufgabe sinnvoll nutzbar ist.
- Claude darf analysieren, recherchieren, Code schreiben, Refactorings vorbereiten, SQL entwerfen, Tests durchführen, Builds ausführen, Dokumentation erstellen, Obsidian-Wissen auswerten und Verbesserungsvorschläge entwickeln.
- Claude darf keine kritischen Aktionen ohne ausdrückliche Freigabe des Benutzers durchführen.
- Codex übernimmt keine Aussagen von Claude ungeprüft. Die Prüfung erfolgt anhand echter Quellen: Code, Git-Diffs, Git-Status, Dateien, SQL, Datenbank-Schema, Migrationen, Build-Ausgaben, Exit Codes, Typecheck, Lint, Tests, Konfiguration, Environment-Targets, Quellen und Tatsachenbehauptungen.

## 4. Audit-Pflicht

Claudes Ergebnisse werden niemals blind übernommen.

Codex muss je nach Aufgabe unabhängig prüfen:

- tatsächlichen Code
- git diff
- git status
- verwendete Dateien
- SQL
- Datenbank-Schema
- Migrationen
- Build-Ausgaben
- Exit Codes
- Typecheck
- Lint
- Tests
- Konfiguration
- Environment-Ziel
- Quellen
- Tatsachenbehauptungen
- Auswirkungen auf bestehende Funktionen
- Auswirkungen auf SEO und Daten
- Rollback-Möglichkeit

Wenn Claude Fehler macht:

1. Fehler konkret identifizieren.
2. Claude gezielt korrigieren lassen.
3. Korrektur erneut unabhängig auditieren.
4. Erst danach freigeben.

## 5. Obsidian als Projektwissen

CrazyBaboBazar Second Brain:

- `/home/batman/MoneyWiKi`
- Alternative reale Position: `/home/batman/Schreibtisch/Obsidian/Money WiKi`

Bei relevanten Aufgaben wird dort nach vorhandenem Wissen gesucht.

Insbesondere berücksichtigen:

- `CLAUDE.md`
- SEO-Audits
- Search-Console-Baselines
- Growth-Research
- Affiliate-Research
- Architekturentscheidungen
- Ideen
- offene Fragen

Obsidian ist Wissensquelle. Das Git-Repo ist die Wahrheit für den aktuellen Codezustand.

## 6. Datenbanken und Umgebungen

Production Supabase:

- `ydiihvzcxaaoqhmgoqvu.supabase.co`

Pilot / Staging:

- `nmzuycveumyfvtxdcnuc.supabase.co`

Vor JEDEM Schreibzugriff ist die Zielumgebung explizit zu prüfen.

Regel:

- Production darf niemals aufgrund von Annahmen gewählt werden.
- Schreibzugriffe auf Produktion sind verboten, ohne ausdrückliche Freigabe durch den Benutzer.
- Schreibzugriffe auf Pilot/Staging sind nur zulässig, wenn der Benutzer den Arbeitsschritt bereits freigegeben hat.

## 7. Benutzerfreigabe zwingend erforderlich

Vor folgenden Aktionen ist eine ausdrückliche Freigabe durch den Benutzer erforderlich:

- Production-Datenbank UPDATE / INSERT / DELETE
- Production-Migration
- Löschen von Production-Daten
- Merge nach `main`
- Push auf `main`, falls er Deployment auslöst
- Production-Deploy
- Vercel-Production-Änderungen
- Search-Console-Schreibaktionen
- Änderungen an externen Konten / Systemen
- Secrets / Credentials
- irreversible oder destruktive Aktionen

## 8. Selbstständig erlaubt

Ohne erneute Benutzerfreigabe dürfen Claude und Codex:

- read-only analysieren
- lokal entwickeln
- lokale Branches verwenden
- Builds durchführen
- Tests durchführen
- Typechecks / Lint durchführen
- Git-Diffs prüfen
- Pilot / Staging analysieren
- Dokumentation aktualisieren
- Obsidian lesen
- öffentlich recherchieren

## 9. Sicherheits- und Compliance-Regeln

- Secrets niemals anzeigen oder committen.
- `.env.local` nicht ungefragt verändern.
- Production-Daten niemals unbeaufsichtigt oder implizit verändern.
- Keine automatischen Veröffentlichungen ohne Review.
- Keine Änderungen am Design-System ohne Begründung.
- Keine irreversiblen oder destruktiven Aktionen ohne ausdrückliche Freigabe.

## 10. Ergebnisstandard

Bei größeren CrazyBaboBazar-Aufgaben soll Codex am Ende ausgeben:

- `CLAUDE WORK:` Was Claude gemacht hat.
- `CODEX AUDIT:` Was unabhängig geprüft wurde.
- `FINDINGS:` Fehler, Risiken oder Abweichungen.
- `STATUS:`
  - `AUDIT PASS`
  - `AUDIT PASS MIT HINWEISEN`
  - `AUDIT FAIL`
- `NEXT:` Nächster sinnvoller Schritt.

## 11. Vererbung bestehender strenger Regeln

Bestehende projektspezifische Sicherheits- und Framework-Regeln bleiben in Kraft, sofern sie strenger sind. Wenn Teilprojekte eigene AGENTS- oder CLAUDE-Regeln enthalten, ergänzen diese diese Projektregel, ohne sie zu umgehen.

Besonders relevant:

- `apps/web/AGENTS.md` bleibt für web-spezifische Arbeiten in Kraft.
- Der lokale Next.js-Workspace-Block in `apps/web/AGENTS.md` gilt zusätzlich, sofern er nicht durch diese allgemeinen Projektregeln abgeschwächt wird.

## 12. Kurzform der Projekt-Policy

- Das Git-Repo ist die Wahrheit für den aktuellen Codezustand.
- Obsidian ist das Wissensnetz.
- Claude ist der Worker.
- Codex ist der Auditor und Supervisor.
- Der Benutzer ist die Freigabeinstanz für kritische Entscheidungen.
- Production ist ein Schutzraum; kein Schreibzugriff ohne Freigabe.
- Kein `main`-Merge, kein Deployment und keine Search-Console-Schreibaktion ohne Freigabe.
- Prüfung vor Freigabe ist Pflicht.
- Claude-Worker laufen für den Benutzer sichtbar im Terminal `CLAUDE WORKER`.

## 13. Standard für kritische Entscheidungen

Wenn eine Aktion potenziell produktiv, datenschutzrelevant, monetarisierungsrelevant, SEO-relevant oder infrastrukturell kritisch ist, gilt:

- zuerst prüfen,
- dann mit Claude arbeiten,
- dann unabhängig auditieren,
- dann mit dem Benutzer abstimmen, falls kritische Wirkung wahrscheinlich ist.

So werden große CrazyBaboBazar-Aufgaben kontrolliert, reproduzierbar und nachweisbar gesteuert.
