# Quellen & Audit — Wichtelguide-Refresh (2026-09-14)

Recherchezeitpunkt: 2026-09-14, im Rahmen der Überarbeitung von
`apps/web/lib/guides/wichtelgeschenke-unter-20-euro.ts` auf 16 Produkte.

## Wichtiger Hinweis zur Belegstufe

**Externe Verifikation wurde durchgeführt — gestuft nach Quelle.**

Der `claude-chrome`-Recherchelauf vom 2026-09-14 hat alle vier
Amazon-Produktseiten der neuen Produkte live geprüft und dabei für jede
Seite ASIN, eine Preis-Momentaufnahme, Marke, Bild-URL sowie die dort
sichtbaren Bewertungsdaten geliefert. Das ist die primäre Verifikationsquelle
für die vier neuen Produkte.

Im Anschluss hat Codex alle vier Amazon-Produkt-URLs sowie alle vier
Bild-URLs per HTTP geprüft: 8/8 Anfragen antworteten mit HTTP 200. Das belegt
Erreichbarkeit der Seiten und Bilder — nicht dauerhaft Preis oder Qualität.

Für die 12 bestehenden Produkte im Guide hat Codex ebenfalls eine
Erreichbarkeitsprüfung durchgeführt: 12/12 Amazon-Produktseiten antworteten
mit HTTP 200. Preise wurden dabei nicht erneut ausgelesen; die im Guide
verwendeten Preisangaben zu den 12 bestehenden Produkten stammen unverändert
aus der bisherigen Guide-Version.

**Offenes Risiko:** Preis, Verfügbarkeit und Bewertungsbasis sind
Momentaufnahmen vom Recherchezeitpunkt (2026-09-14), keine dauerhafte
Garantie. Bei nennenswertem Zeitabstand zur Veröffentlichung empfiehlt sich
ein erneuter Preis-Stichprobencheck.

## Produkt 1 — DEBUG DUCK – die Problemlöser-Ente

- ASIN: B088646PWY
- Quelle: https://www.amazon.de/dp/B088646PWY (live geprüft per claude-chrome, 2026-09-14; Erreichbarkeit zusätzlich per HTTP von Codex bestätigt, 200 OK)
- Preis-Momentaufnahme: 14,99 €
- Marke: neonquelle
- Bestätigt: ASIN, Preis-Momentaufnahme, Marke und Bild-URL wurden beim Live-Check bestätigt.
- Unsicher/nicht übernommen: "Naturkautschuk" / "handgemacht" — laut Auftrag
  nur verwenden, wenn recherchebelegt; da keine Recherche möglich war, wurde
  die Angabe **nicht** in Guide-Text oder SQL übernommen.
- Übernommen: allgemeines Funktionsprinzip "Rubber-Duck-Debugging" — das ist
  ein bekanntes, produktunabhängiges Konzept aus der Softwareentwicklung, keine
  produktspezifische Tatsachenbehauptung.
- Bewertungsbasis: im Text als "noch überschaubar" / "wenige Bewertungen"
  formuliert, ohne erfundene konkrete Zahl.

## Produkt 2 — snagger Snackspender, schwarz-rot

- ASIN: B097YRJ27K
- Quelle: https://www.amazon.de/dp/B097YRJ27K (live geprüft per claude-chrome, 2026-09-14; Erreichbarkeit zusätzlich per HTTP von Codex bestätigt, 200 OK)
- Preis-Momentaufnahme: 19,90 €
- Marke: snagger
- Im Auftrag genannt, aber NICHT übernommen: "Made in Germany", "4,6 Sterne /
  3729 Bewertungen" — beide Angaben wurden vom Live-Check nicht bestätigt und
  daher bewusst weder in den Guide-Text noch in die SQL-Datei aufgenommen
  (Regel: fehlende Bestätigung → weglassen statt behaupten).
- Übernommen: nur die aus dem Produktnamen ableitbare Grundfunktion
  ("Snackspender" = Behälter für kleine Snacks).

## Produkt 3 — getDigital Retro-Kochlöffel im Arcade-Design, 2er-Set

- ASIN: B01N9FCJHA
- Quelle: https://www.amazon.de/dp/B01N9FCJHA (live geprüft per claude-chrome, 2026-09-14; Erreichbarkeit zusätzlich per HTTP von Codex bestätigt, 200 OK)
- Preis-Momentaufnahme: 16,90 €
- Marke: getDigital
- Material Buchenholz: als Vorgabe aus dem Auftrag übernommen (dort explizit
  als Fakt benannt), beim Live-Check nicht gesondert gegengeprüft.
- Spülmaschinenfestigkeit: bewusst NICHT behauptet, wie im Auftrag verlangt.
  In den `cons` stattdessen als offene Frage formuliert ("besser von Hand
  spülen").

## Produkt 4 — Magische Rätselbox aus Holz mit zwei Geheimfächern

- ASIN: B07V9BGBGY
- Quelle: https://www.amazon.de/dp/B07V9BGBGY (live geprüft per claude-chrome, 2026-09-14; Erreichbarkeit zusätzlich per HTTP von Codex bestätigt, 200 OK)
- Preis-Momentaufnahme: 15,99 €
- Marke: HD-Store
- Übernommen: Funktionsbeschreibung "zwei Geheimfächer" und die vom Auftrag
  vorgegebene Einordnung als raffinierte Geschenkverpackung mit kleinem
  Zusatzinhalt (Geldschein/Gutschein/Süßigkeit als Beispiel, nicht als feste
  Behauptung über Lieferumfang).

## Teilweise durchgeführt: Gegenprüfung der 12 bestehenden Produkte

Ein lesender Abgleich der 12 im Guide beibehaltenen Produkte gegen
`public.products` (Name, Preis, Persona, Kategorie) wurde nicht durchgeführt.
Codex hat stattdessen die öffentlichen Amazon-Produktseiten der 12
bestehenden Produkte per HTTP geprüft: 12/12 antworteten mit HTTP 200. Das
belegt nur Erreichbarkeit, nicht den aktuellen Preis- oder DB-Zustand —
Preise wurden dabei nicht erneut ausgelesen. Die im Guide verwendeten
Produktdaten stammen daher unverändert aus der bisherigen Guide-Version
(Stand vor diesem Refresh) und wurden nicht gegen den aktuellen DB-Zustand
verifiziert.
