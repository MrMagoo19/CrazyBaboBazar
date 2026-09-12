# Codex-Audit — American Football Food Stadium

Datum: 2026-09-12

## Einordnung

`draft_american_football_food_stadium_2026.sql` war vor diesem Audit nicht in
Git versioniert. Die Datei bleibt als historischer Entwurf erhalten. Sie ist
schreibend und darf ohne erneute Ziel-, Varianten-, Preis- und
Partnerlinkpruefung nicht ausgefuehrt werden.

Es wurde in diesem Audit keine SQL-Datei ausgefuehrt und kein externer Zustand
veraendert.

## Bestaetigt

- Keine Secrets oder Zugangsdaten im Draft.
- Der Draft umfasst sechs eindeutige Produkt-Slugs und eine Liste mit exakt
  diesen sechs Slugs.
- Der Amazon-Partner-Tag ist in allen sechs Links `geeklist-21`.
- Die offizielle 40YARDS-Seite bestaetigt fuer das Snack Stadium Bambusholz,
  Filz-Spielfeld, zwei Field Goals und etwa 50 x 36 x 10 cm.
- Die offizielle 40YARDS-Seite fuehrt die Zahnstocher als waehlbare Varianten
  mit 30 oder 50 Stueck. Der Produktname im Draft bezeichnet die 30er-Variante;
  der spaeter versionierte Bildpfad traegt dagegen „50-stuck“ im Dateinamen.

## Offene Evidenzluecken

- Der Draft enthaelt kein Backup-/Verify-/Restore-Paket und kein eigenes
  Ausfuehrungsprotokoll. Aus der Datei allein folgt nicht, wann oder wie die
  heute oeffentlich sichtbaren Datensaetze angelegt wurden.
- Der Amazon-Link enthaelt keine im Repo nachvollziehbare Variantenkennung.
  Vor einer Wiederverwendung muss daher geprueft werden, ob Link, Name,
  Stueckzahl und Preis dieselbe 30er-Variante meinen.
- Die Bildabweichung 30/50 ist kein Beleg fuer einen falschen Datensatz, weil
  der Hersteller beide Mengen auf derselben Produktseite anbietet. Sie bleibt
  aber ein visueller Variantenhinweis, der vor einer erneuten Ausfuehrung
  geklaert werden muss.

## Status

**AUDIT PASS MIT HINWEISEN fuer die Archivierung in Git.** Keine Freigabe zur
erneuten SQL-Ausfuehrung.
