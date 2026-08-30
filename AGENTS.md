# CrazyBaboBazar — Projektweite Supervisor-Regeln

Dieses Dokument ist die dauerhafte Supervisor- und Audit-Policy für das gesamte CrazyBaboBazar-Projekt. Es gilt projektweit und nicht nur für den aktuellen Value-Add-Pilot.

## 0. Engine-Routing — welche Stufe für welche Aufgabe

Ziel: **Kosten nach Aufgabenkomplexität, ohne Qualitätsverlust.** Nicht die Denktiefe
für schwere Aufgaben senken, sondern aufhören, sie für leichte zu bezahlen.

### Codex (Auditor / Supervisor)

Standard ist seit 2026-08-27 `medium` statt `xhigh`. Hochgeschaltet wird per Profil,
nicht durch Ändern des Defaults.

| Aufgabe | Aufruf | Stufe |
|---|---|---|
| Tippfehler, Formatierung, Umbenennen, Datei anzeigen, Existenzprüfung | `codex --profile quick` | low |
| Routine: kleine Edits, klar umrissene Recherche, Statusprüfung, Commit-Nachricht | `codex` | **medium** |
| **Eigentliche Codex-Rolle:** unabhängiges Audit von Claude-Ergebnissen, Code-Review, Architektur, Fehlersuche über mehrere Dateien, Strategie- und Quellenprüfung | `codex --profile deep` | xhigh |
| Eskalation: widersprüchliche Befunde, hartnäckiger Bug, schwer rückabwickelbare Entscheidung | `codex --profile max` | max |

**Regel:** Jede Aufgabe, die unter §7 dieses Dokuments freigabepflichtig ist, wird
mindestens mit `--profile deep` auditiert. Für die Audit-Rolle wird nie
heruntergeschaltet — dort liegt der Wert von Codex.

### Claude Code (Worker)

Claude wählt die Engine über Subagenten in `.claude/agents/`. Das Modell ist in der
Agentendefinition hinterlegt und greift automatisch bei Delegation.

| Agent | Modell | Effort | Wofür |
|---|---|---|---|
| `scout` | haiku | — | Fakten beschaffen: Dateien finden, zählen, SQL, HTTP-Status, Seitengrößen. Read-only. |
| `rechercheur` | sonnet | medium | Externe Recherche **mit Belegstufe** (✅ primär / 🟡 sekundär / 🔴 unverifiziert) |
| `code-auditor` | sonnet | high | Code-Befunde mit `datei.tsx:zeile` und Wirkungsangabe. Read-only. |
| `texter` | sonnet | high | Veröffentlichungstexte nach Voice Bible (Register A/B, Personas, Stoppliste) |
| `pruefer` | opus | high | Gegnerische Endprüfung vor Vorlage beim Benutzer |

Haiku unterstützt keine konfigurierbare Effort-Stufe — daher `—` beim `scout`.
Die Einsparung entsteht dort durch das Modell selbst, nicht durch eine Stufe.

**Regeln für Claude:**

1. **Delegieren, wo delegierbar.** Zählen, Suchen, Statusprüfen gehört an `scout` —
   nicht an die Hauptsitzung. Das ist der größte Einzelhebel auf der Claude-Seite.
2. **Nicht hochstufen ohne Grund.** `pruefer` (opus) läuft am Ende eines Ergebnisses,
   nicht zwischendurch.
3. **Nicht herunterstufen bei Urteilsfragen.** Strategie, Abwägung, Entscheidung und
   Synthese bleiben in der Hauptsitzung. Ein Befund, an dem eine Entscheidung hängt,
   geht nicht an `scout`.
4. **Belegpflicht bleibt unberührt.** Eine günstigere Engine senkt nie den
   Belegstandard. Jeder Agent liefert Quelle, Codestelle oder Abfrage mit.

### Was ausdrücklich nicht heruntergestuft wird

- Unabhängiges Audit durch Codex (Kern der Rolle laut §1)
- Entscheidungen mit Umsatz-, Rechts- oder Rückabwicklungsfolge
- Alles, was unter §7 eine Benutzerfreigabe braucht
- Der letzte Prüfschritt vor Vorlage beim Benutzer

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

## 14. Engine-Auto-Selection & PARA MEMORY COST POLICY

Ziel: Kosten sparen ohne Qualitätsverlust. Agenten (Claude-Worker + lokale
Worker) stellen die Engine / das Profil automatisch je nach Aufgabenkomplexität
ein — dabei gelten die folgenden Regeln und Prüfpfade:

- **Automatische Auswahl:** Worker wählen ein Engine-Profil basierend auf der
  Aufgabenkategorie (siehe `.claude/agents/engine-routing.md`).
- **Minimaler Aufwand zuerst:** Mechanische, gut definierte Aufgaben verwenden
  günstigere/leichte Engines (z. B. `haiku`/`low`) — solange die Belegpflicht
  erfüllt bleibt (Quellen, Dateiangaben, konkrete Outputs).
- **Hochstufung bei Urteilsfragen:** Strategie, Synthese, Entscheidungstexte,
  Architektur und Audit-Aufgaben laufen mindestens auf `medium` oder höher.
- **Audit-Pflicht:** Ergebnisse, die Entscheidungsfolgen haben, werden immer
  von Codex (audit) unabhängig geprüft; Codex darf nicht automatisch
  heruntergestuft werden.

PARA Memory — Kosten-Regeln (strikt):

- Verwende Para Memory nur, wenn vorheriger Projekt-Kontext *wesentlich*
  erforderlich ist.
- Keine Nutzung von Para Memory für:
  - einfache UI-Edits, CSS, component-fixes
  - lint, typecheck, builds, tests
  - lokale Refactors oder offensichtliche Bugfixes
  - Aufgaben, die bereits im aktuellen Chat vollständig beschrieben sind
- Vor Para Memory lookup: 1) `AGENTS.md` prüfen, 2) Repo-Dateien prüfen, 3)
  bereits geladenen Kontext verwenden. Nur wenn dennoch historischer Kontext
  fehlt, Para Memory anfragen.
- Innerhalb einer Aufgabe niemals dieselbe Para Memory-Abfrage wiederholen,
  außer neue Informationen sind notwendig.

Implementierungshinweis:

- Diese Datei ist die Single Source of Truth für Team-Regeln.
  `.claude/agents/engine-routing.md` ist die maschinenlesbare Ableitung davon.

- **Umsetzung im CLAUDE WORKER** (`scripts/claude-worker-terminal.sh`, gemeinsame
  Logik in `scripts/engine-routing-lib.sh`):
  1. Der Worker liest den Agenten aus dem YAML-Frontmatter des Auftrags
     (`agent: <name>`). Der Block darf auch nach einem Vorspann stehen — ein
     Prompt muss nicht mit `---` beginnen.
  2. Er schlägt `recommended_engine` im Block dieses Agenten in
     `.claude/agents/engine-routing.md` nach und übergibt sie als `--model`.
  3. Injiziert wird **ausschließlich** ein Alias, der in der Routingdatei als
     `recommended_engine` steht (aktuell `haiku`, `sonnet`, `opus`). Agentennamen
     und Engine-Aliasse werden gegen ein enges Zeichenmuster geprüft; alles
     andere wird verworfen und auf stderr gemeldet. Es findet keine freie
     Shell-Expansion statt.
  4. Ohne Agent im Frontmatter, bei unbekanntem Agent oder bei ungültigem Wert
     läuft der Auftrag mit der Default-Engine der CLI — nie mit dem Wert eines
     vorherigen Auftrags.
  5. Jede Entscheidung wird nach `engine_log_path` protokolliert
     (`agent=… engine=… injected=yes|no`).

- **Schalter:** `auto_inject_model` in `.claude/worker-config.yaml`, Env-Override
  `CBB_AUTO_INJECT_MODEL`. Policy-konform ist `true`; steht er auf `false`, gibt
  der Worker beim Start einen sichtbaren Hinweis auf diese Abweichung aus.

- **Startprüfung:** Fehlen `AGENTS.md` oder die Routingdatei bzw. fehlen die
  erwarteten Schlüssel, warnt der Worker. Fortgesetzt wird nur nach
  interaktiver Bestätigung — oder wenn `auto_confirm_warnings` (Env:
  `CBB_AUTO_CONFIRM_WARNINGS`) ausdrücklich gesetzt ist. Ohne Terminal und ohne
  diesen Schalter bricht der Worker ab; stillschweigendes Weiterlaufen bei
  Policy-Warnungen gibt es nicht.

- **Test:** `scripts/engine-routing-test.sh` prüft Parsing, Lookup,
  Modellargument-Bildung, Prompt mit Frontmatter und den Reset zwischen Jobs.
  Der Integrationsteil startet den echten Runner mit einem Stub-`claude` und
  einem Wegwerf-State-Verzeichnis — es wird nie das echte Claude aufgerufen.
