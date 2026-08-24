-- ============================================================
-- PILOT-BACKFILL — Value-Add-Felder für 10 Produktseiten
-- ============================================================
-- STATUS: ENTWURF — NICHT AUSGEFÜHRT. Erst gegen eine NICHT-Produktions-DB
-- (Staging / Supabase-Branch) und nach Freigabe laufen lassen.
-- Vollständige Voraussetzung im Pilot (siehe PILOT_ENVIRONMENT.md):
--   1) pilot_staging_bootstrap.sql
--   2) pilot_staging_seed.sql
--   3) backup_pilot_value_add.sql (Sicherung muss erfolgreich sein)
--
-- Regeln (eingehalten):
--   • Nur die 10 Pilotprodukte werden per slug angefasst (WHERE slug = ...).
--   • Inhalte ausschließlich aus vorhandenen Fakten (tagline + description).
--     Keine erfundene Erfahrung. key_fact = Herstellerangabe (Kennzeichnung im UI).
--   • Relation (B): alternative_kind unterscheidet
--       'alternative' = echtes Ersatzprodukt (gleicher Zweck), ODER
--       'complement'  = "Passt dazu" (nur ergänzend).
--     Wo KEIN echtes Ersatz-/Ergänzungsprodukt im Katalog existiert, bleiben
--     alle drei alternative_*-Felder NULL — KEINE Fake-Alternative.
--   • Idempotent & atomar (BEGIN/COMMIT). Bei Fehler ROLLBACK.
--
-- ============================================================
-- ⛔ BLOCKED — GETRENNT ZU KLÄREN, HIER BEWUSST NICHT ANGEFASST
-- ============================================================
--  (1) divoom-pixoo-led-panel: price_cents IS NULL. Preis NICHT geraten/gesetzt.
--      Value-Add-Felder sind preis-unabhängig und werden befüllt.
--  (2) n4-nussmilchbereiter-pflanzenmilch: Zubereitungszeit widersprüchlich
--      (tagline "unter 2 Minuten" vs. description "15 Minuten"). tagline/description
--      werden NICHT verändert; die neuen Felder enthalten KEINE Zeitangabe.
-- ============================================================

begin;

-- Nie ohne den vom Bootstrap angelegten Pilot-Marker schreiben.
do $$
begin
  if to_regclass('pilot_meta.environment_guard') is null then
    raise exception 'Pilot-Backfill abgebrochen: Umgebungsmarker fehlt.';
  end if;

  perform 1
  from pilot_meta.environment_guard
  where project_ref = 'nmzuycveumyfvtxdcnuc';

  if not found then
    raise exception 'Pilot-Backfill abgebrochen: falscher Umgebungsmarker.';
  end if;
end $$;

-- 1) PINECIL USB-C Lötkolben (babo/tech) — Relation: PASST DAZU (complement)
update public.products set
  fuer_wen           = 'Maker, Reparatur-Fans und alle, die unterwegs an der Powerbank löten wollen.',
  nicht_fuer         = 'Wer nur einmal im Jahr ein Kabel flickt — dafür ist das Feature-Set zu viel.',
  key_fact           = '30 g, USB-C-betrieben, in 6 Sekunden auf Temperatur, Genauigkeit 1 °C.',
  pros               = array['In 6 Sekunden heiß','Läuft an jeder USB-C-Quelle oder Powerbank','Open-Source-Firmware, erweiterbar','Automatischer Schlafmodus'],
  cons               = array['Eigene USB-C-Stromquelle nötig','Volles Potenzial erst nach Firmware-Setup'],
  alternative_slug   = 'ifixit-antistatik-matte-faltbar-esd',
  alternative_kind   = 'complement',
  alternative_reason = 'Beim Löten und Reparieren schützt die faltbare ESD-Matte Bauteile und Tisch vor statischer Entladung — der natürliche Begleiter.',
  editorial_note     = 'In die Hosentasche und trotzdem ernst zu nehmen: USB-C rein, sechs Sekunden warten, löten. Open-Source heißt, er wird eher besser als schlechter. Für alle, die reparieren statt wegwerfen.'
where slug = 'pinecil-usbc-loetkolben';

-- 2) Divoom Pixoo LED-Panel (babo/tech) — Relation: ALTERNATIVE — price_cents BLOCKED
update public.products set
  fuer_wen           = 'Wer Schreibtisch oder Stream mit Pixel-Art, Uhr oder Spotify-Visualizer aufwerten will.',
  nicht_fuer         = 'Wer ein hochauflösendes Info-Display erwartet — 16×16 ist bewusst grob.',
  key_fact           = '16×16-Pixel-LED-Panel, komplett per App konfigurierbar.',
  pros               = array['Zeigt Pixel-Art, GIFs, Uhr, Spotify-Visualizer und Benachrichtigungen','Alles per App steuerbar','Starker Retro- und Arcade-Look'],
  cons               = array['Nur 16×16 Pixel — für Text oder Details ungeeignet','Funktion hängt an der Hersteller-App'],
  alternative_slug   = 'divoom-minitoo-retro-pc-lautsprecher-pixel',
  alternative_kind   = 'alternative',
  alternative_reason = 'Ebenfalls ein konfigurierbares Pixel-Display fürs Desk-Setup, zusätzlich mit Lautsprecher — wenn du Pixel-Anzeige und Sound kombinieren willst.',
  editorial_note     = 'Reines Deko-mit-Funktion: ein Pixel-Display, das den Schreibtisch nach Arcade aussehen lässt und nebenbei die Uhrzeit oder den Spotify-Track zeigt. Kein Tool, ein Stimmungsmacher.'
where slug = 'divoom-pixoo-led-panel';

-- 3) SCULPFUN S9 Laser-Graviermaschine (babo/tech) — Relation: KEINE (kein echtes Ersatz-/Ergänzungsprodukt im Katalog)
update public.products set
  fuer_wen           = 'Bastler und Kleingewerbe, die Holz, Acryl oder Leder gravieren wollen — ohne Profi-Budget.',
  nicht_fuer         = 'Wer nur gelegentlich ein Schild braucht; Einarbeitung und Platzbedarf lohnen sich dann nicht.',
  key_fact           = 'Graviert Holz, Acryl, Leder und anodisiertes Aluminium, 90 W Spitzenleistung.',
  pros               = array['Deckt viele Materialien ab','Läuft mit Open-Source-Software (LaserGRBL, LightBurn)','Aufbau in rund 20 Minuten','Maker-Einstieg ohne 5-stelliges Budget'],
  cons               = array['Braucht einen festen, belüfteten Arbeitsplatz','Arbeiten mit Laser erfordert Schutzbrille und Vorsicht'],
  alternative_slug   = null,
  alternative_kind   = null,
  alternative_reason = null,
  editorial_note     = 'Der Einstieg für alle, die eigene Sachen gravieren wollen, ohne eine Werkstatt zu finanzieren. Viele Materialien, offene Software, überschaubarer Aufbau. Laser bleibt Laser — Schutz gehört dazu.'
where slug = 'sculpfun-s9-laser-engraver';

-- 4) Arc Reaktor MK1 – Schwebend & Rotierend (babo/tech) — Relation: KEINE (kein gleichwertiges Ersatzprodukt)
update public.products set
  fuer_wen           = 'Marvel- und Iron-Man-Fans, die ein Hingucker-Objekt für den Schreibtisch wollen.',
  nicht_fuer         = 'Wer ein funktionales Gadget sucht — das hier ist reine Deko.',
  key_fact           = 'Magnetisch schwebende und rotierende 1:1-Replika mit film-getreuer LED.',
  pros               = array['Schwebt und rotiert magnetisch','1:1-Größe mit film-getreuer LED','Für Dauerbetrieb ausgelegt'],
  cons               = array['Reine Deko ohne Zusatzfunktion','Magnetschwebe braucht einen stabilen, erschütterungsarmen Standort'],
  alternative_slug   = null,
  alternative_kind   = null,
  alternative_reason = null,
  editorial_note     = 'Ein Angeber-Objekt im besten Sinn: schwebt, dreht sich, leuchtet wie im Film. Nützlich ist nichts daran — beeindruckend alles. Für die Ecke des Schreibtischs, auf die Gäste sofort zeigen.'
where slug = 'arc-reaktor-mk1-schwebend';

-- 5) Elektrische Wasserpistole mit LED (babo/outdoor) — Relation: ALTERNATIVE
update public.products set
  fuer_wen           = 'Alle, die Wasserkämpfe ohne Dauerpumpen austragen wollen — Erwachsene wie Kinder.',
  nicht_fuer         = 'Sehr kleine Kinder — Größe und Reichweite sind auf ältere Nutzer ausgelegt.',
  key_fact           = 'Selbstansaugend, elektrischer Abzug, LED-Beleuchtung — kein manuelles Pumpen.',
  pros               = array['Kein Pumpen — nur Abzug halten','Große Kapazität und lange Reichweite','LED-Beleuchtung','Für Erwachsene und Kinder'],
  cons               = array['Braucht eine Strom- oder Akkuquelle','Größer und schwerer als klassische Pumppistolen'],
  alternative_slug   = 'derayee-schaumstoff-wasserpistole',
  alternative_kind   = 'alternative',
  alternative_reason = 'Günstiger und leichter — dieselbe Idee für kleinere Kinder und den schmalen Geldbeutel.',
  editorial_note     = 'Verschiebt das Kräfteverhältnis im Garten: kein Pumpen mehr, nur Abzug halten. Große Reichweite, LED für den Show-Effekt — ehrlich gesagt für Erwachsene fast lustiger als für Kinder.'
where slug = 'elektrische-wasserpistole-mit-led';

-- 6) Hot Wheels Ultimative Garage 3ft (miniboss/spielzeug) — Relation: KEINE (kein zweites Parkhaus / kein Auto-Set im Katalog)
update public.products set
  fuer_wen           = 'Hot-Wheels-Kinder und Sammler, deren Auto-Sammlung längst überläuft.',
  nicht_fuer         = 'Kleine Kinderzimmer — das Teil ist fast einen Meter hoch und braucht Platz.',
  key_fact           = '3-stöckig, rund 1 m hoch, mit Aufzug, Waschanlage und Tankstelle, 2 Autos inklusive.',
  pros               = array['Drei Spielebenen mit Aufzug, Waschanlage und Tankstelle','Fast 1 m hoch — großer Spielwert','Zwei Die-Cast-Autos direkt dabei'],
  cons               = array['Braucht viel Platz','Nur zwei Autos enthalten — weitere separat'],
  alternative_slug   = null,
  alternative_kind   = null,
  alternative_reason = null,
  editorial_note     = 'Die Lösung fürs Luxusproblem „zu viele Hot-Wheels-Autos": drei Etagen, Aufzug, Waschanlage, fast ein Meter hoch. Sorgt beim Auspacken sofort für Jubel — und braucht danach dauerhaft Platz.'
where slug = 'hot-wheels-ultimative-garage-3ft';

-- 7) LEGO Creator 3-in-1 Retro-Kamera (31147) (miniboss/spielzeug) — Relation: KEINE (kein gleichwertiges Kinder-Bauset im Katalog)
update public.products set
  fuer_wen           = 'Kinder ab 8 mit Bau-Lust — und Erwachsene mit Lego- plus Nostalgie-Tick.',
  nicht_fuer         = 'Kinder unter 8 Jahren (laut Hersteller ab 8).',
  key_fact           = '3-in-1-Set, 261 Teile: baubar als Fotokamera, Videokamera oder Retro-Fernseher, ab 8 Jahren.',
  pros               = array['Drei Baumodelle aus einem Set','261 Teile für mehrere Bauerlebnisse','Günstiger Einstieg','Retro-Optik trifft Nostalgie'],
  cons               = array['Erst ab 8 Jahren','Nur ein Modell gleichzeitig baubar'],
  alternative_slug   = null,
  alternative_kind   = null,
  alternative_reason = null,
  editorial_note     = 'Clever gemacht: einmal kaufen, dreimal bauen — Kamera, Videokamera oder Retro-Fernseher. Für den Preis ein starker Einstieg und ein sicheres Geschenk für bauwütige Kinder ab 8.'
where slug = 'lego-creator-3in1-retro-kamera-31147';

-- 8) Ninja StaySharp Messerset 6-teilig (queen/kueche) — Relation: KEINE (kein zweites Messerset / kein echtes Ergänzungsprodukt im Katalog)
update public.products set
  fuer_wen           = 'Haushalte, in denen wirklich täglich gekocht wird und niemand separat schärfen will.',
  nicht_fuer         = 'Profis, die ihre Klingen am Stein abziehen und den Winkel frei wählen wollen.',
  key_fact           = '6-teiliges Set mit integrierten Schärf-Slots im Block, 15-Grad-Klingenwinkel.',
  pros               = array['Schärfen ist im Block eingebaut — kein Extra-Zubehör','Komplettes Set (Koch, Brot, Santoku, Fleisch, Zubereitung, Schere)','Definierter 15-Grad-Winkel','Aufbewahrung im Block inklusive'],
  cons               = array['Fester Schärfwinkel — keine freie Winkelwahl','Preisband deutlich über Einsteiger-Sets'],
  alternative_slug   = null,
  alternative_kind   = null,
  alternative_reason = null,
  editorial_note     = 'Löst das nervigste Messer-Problem: Es schärft sich beim Reinstecken selbst. 6-teilig, mit Block, definierter Winkel. Für Küchen, in denen echt gekocht wird — nicht für Puristen mit eigenem Schleifstein.'
where slug = 'ninja-staysharp-messerset-6-teilig';

-- 9) N4 Nussmilchbereiter (queen/kueche) — Relation: PASST DAZU (complement) — Zeitangabe BLOCKED (KEINE Zeit in den Feldern)
update public.products set
  fuer_wen           = 'Pflanzenmilch-Vieltrinker, die Zutaten und Kosten selbst kontrollieren wollen.',
  nicht_fuer         = 'Wer nur selten mal Hafermilch trinkt — die Anschaffung amortisiert sich dann kaum.',
  key_fact           = '800-W-Bereiter mit Selbstreinigung für Hafer-, Mandel-, Soja-, Reis- und Cashew-Milch.',
  pros               = array['Mixt, kocht und filtert automatisch','Selbstreinigung','Fünf Milchsorten','800 W'],
  cons               = array['Lohnt sich nur bei regelmäßigem Konsum','Ein weiteres Küchengerät, das gereinigt werden will'],
  alternative_slug   = 'aeropress-go-tragbare-kaffeemaschine',
  alternative_kind   = 'complement',
  alternative_reason = 'Wer die frische Hafer- oder Mandelmilch für Kaffee nutzt: die AeroPress macht den Kaffee dazu — die Heim-Barista-Kombi.',
  editorial_note     = 'Macht frische Pflanzenmilch auf Knopfdruck und reinigt sich selbst. Für Menschen, die Milch-Alternativen ernst nehmen und die Bio-Laden-Preise satt haben. Lohnt sich, wenn täglich getrunken — sonst steht er nur rum.'
where slug = 'n4-nussmilchbereiter-pflanzenmilch';

-- 10) Welpen USB-Ladekabel Hunde-Design (queen/lifestyle) — Relation: ALTERNATIVE
update public.products set
  fuer_wen           = 'Hunde-Fans, die ein Alltagskabel mit Charakter statt Standard-Schwarz wollen.',
  nicht_fuer         = 'Wer maximale Ladeleistung oder Datenrate braucht — hier zählt vor allem das Design.',
  key_fact           = '1,5-m-Kabel mit verstärktem Anschluss (USB-C oder Lightning) und integrierter Zugentlastung.',
  pros               = array['Verstärkter Anschluss und Zugentlastung gegen Kabelbruch','1,5 m Länge','Süßes Welpen-Design','Als USB-C oder Lightning erhältlich'],
  cons               = array['Design-Produkt — keine Angabe zur Schnellladeleistung','Das Motiv ist Geschmackssache'],
  alternative_slug   = 'cbdywvr-2in1-ladekabel-mit-staender',
  alternative_kind   = 'alternative',
  alternative_reason = 'Ein anderes Ladekabel — 2-in-1 mit integriertem Ständer, wenn Funktion vor Design geht.',
  editorial_note     = 'Macht aus dem langweiligsten Alltagsteil ein kleines Deko-Statement — mit verstärktem Anschluss und Zugentlastung gegen den klassischen Kabelbruch an der Buchse. Für Hunde-Fans, nicht für Ladegeschwindigkeits-Nerds.'
where slug = 'welpen-usb-ladekabel-hunde-design';

commit;

-- ============================================================
-- VERIFIKATION (read-only, nach dem Backfill ausführen)
-- ============================================================
-- (a) Alle 10 Kernfelder befüllt? Erwartet: 10 Zeilen, Flags true.
-- (b) Relation korrekt? Erwartet: 3× 'alternative', 2× 'complement', 5× NULL.
-- select slug, alternative_kind, alternative_slug
-- from public.products
-- where slug in (
--   'pinecil-usbc-loetkolben','divoom-pixoo-led-panel','sculpfun-s9-laser-engraver',
--   'arc-reaktor-mk1-schwebend','elektrische-wasserpistole-mit-led','hot-wheels-ultimative-garage-3ft',
--   'lego-creator-3in1-retro-kamera-31147','ninja-staysharp-messerset-6-teilig',
--   'n4-nussmilchbereiter-pflanzenmilch','welpen-usb-ladekabel-hunde-design'
-- ) order by slug;
--
-- (c) Referenz-Integrität: jedes gesetzte alternative_slug zeigt auf ein
--     veröffentlichtes Produkt? Erwartet: 0 Zeilen.
-- select p.slug, p.alternative_slug
-- from public.products p
-- left join public.products a on a.slug = p.alternative_slug and a.is_published = true
-- where p.alternative_slug is not null and a.slug is null;
--
-- (d) BLOCKED-Kontrolle: divoom-Preis bleibt NULL, n4-Zeittext unverändert.
-- select slug, price_cents, tagline, description
-- from public.products where slug in ('divoom-pixoo-led-panel','n4-nussmilchbereiter-pflanzenmilch');
