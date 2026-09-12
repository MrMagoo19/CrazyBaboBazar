-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit user approval before production execution.
-- Adds the 17 missing products for /guide/star-trek-vs-star-wars.
-- Three guide products already exist: LEGO Enterprise, Funko Darth Vader,
-- and the Death Star ice mould.

BEGIN;

DO $$
DECLARE
  expected_asins CONSTANT text[] := ARRAY[
    'B0D19PVKQV', 'B07JND5HC7', 'B0789RMK9W', 'B0D98SM3VV',
    'B0BP6JNZC5', 'B0GQFR41QQ', 'B01N227FMM', 'B073W8RJH1',
    'B07JND9WB2', 'B0CD2B3NSP', 'B0C5DKF5N8', 'B0CTS9V6GH',
    'B0CRKQT1ML', 'B093Y3W6SD', '3966589508', '3833244097',
    'B0G53LTYD8'
  ];
  expected_slugs CONSTANT text[] := ARRAY[
    'funko-pop-picard-borg-locutus',
    'revell-star-trek-uss-enterprise-ncc-1701-modellbausatz',
    'revell-star-wars-millennium-falcon-1-72-modellbausatz',
    'funko-pop-kirk-transporter',
    'star-trek-tos-command-bademantel-gold',
    'star-wars-jedi-bademantel-braun',
    'logoshirt-star-trek-enterprise-crew-tasse',
    'paladone-star-wars-lichtschwert-farbwechsel-tasse',
    'winning-moves-risiko-star-trek-deutsch',
    'hasbro-monopoly-star-wars-light-side-deutsch',
    'elbenwald-star-trek-enterprise-schneidebrett-buche',
    'picnic-time-star-wars-millennium-falcon-servierbrett',
    'numskull-star-trek-3d-logo-leuchte',
    'paladone-star-wars-logo-leuchte',
    'star-trek-cocktails-unendliche-drinks',
    'star-wars-das-ultimative-kochbuch',
    'raven-forge-star-trek-commbadge-eiswuerfelform'
  ];
  i integer;
  conflicting_slug text;
BEGIN
  FOR i IN 1..array_length(expected_asins, 1) LOOP
    SELECT slug INTO conflicting_slug
    FROM public.products
    WHERE affiliate_url ~ ('/(' || expected_asins[i] || ')([/?]|$)')
      AND slug <> expected_slugs[i]
    LIMIT 1;

    IF conflicting_slug IS NOT NULL THEN
      RAISE EXCEPTION 'ASIN/ISBN % already exists under slug % (expected %)',
        expected_asins[i], conflicting_slug, expected_slugs[i];
    END IF;
  END LOOP;
END
$$;

INSERT INTO public.products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, fuer_wen, nicht_fuer, key_fact, pros, cons
)
VALUES
(
  'funko-pop-picard-borg-locutus', 'Funko POP! Star Trek Picard als Borg Locutus',
  'Assimiliert dein Regal, aber wenigstens niedlich.',
  'Picard in seiner Borg-Phase als kompakte Funko-Sammelfigur. Ein kleines Geschenk für Star-Trek-Fans, das ohne freien Quadratmeter im Wohnzimmer auskommt.',
  1473, 'EUR', 'https://www.amazon.de/dp/B0D19PVKQV?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71kzfI7lSAL._AC_SL1300_.jpg', ARRAY['https://m.media-amazon.com/images/I/71kzfI7lSAL._AC_SL1300_.jpg'],
  true, false, 'babo', 'gaming', 'sammelfigur', 'Spielzeug', 'Funko',
  ARRAY['babo:gaming', 'star-trek', 'picard', 'borg', 'funko', 'nerdy'],
  'Das Star-Trek-Gegenstück zu Darth Vader im Figuren-Duell.',
  'Picard-, Borg- und Funko-Fans mit Platz für eine kleine Figur.',
  'Wer Funko-Figuren grundsätzlich wie Plastik mit übergroßem Kopf findet.',
  'Funko POP! Sammelfigur von Picard als Borg/Locutus.',
  ARRAY['klar erkennbares Fanmotiv', 'kompaktes Geschenk', 'günstiger Einstieg'],
  ARRAY['reine Deko', 'Funko-Optik ist Geschmackssache']
),
(
  'revell-star-trek-uss-enterprise-ncc-1701-modellbausatz', 'Revell Star Trek U.S.S. Enterprise NCC-1701 Modellbausatz',
  'Die klassische Enterprise für Kleber, Geduld und sehr ruhige Hände.',
  'Revell-Bausatz der klassischen U.S.S. Enterprise NCC-1701 aus der Originalserie. Gedacht für Modellbau-Fans, die ihr Raumschiff lieber selbst zusammensetzen als fertig ins Regal stellen.',
  3799, 'EUR', 'https://www.amazon.de/dp/B07JND5HC7?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71ph9L1lWTL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71ph9L1lWTL._AC_SL1500_.jpg'],
  true, false, 'babo', 'gaming', 'modellbau', 'Spielzeug', 'Revell',
  ARRAY['babo:gaming', 'star-trek', 'enterprise', 'revell', 'modellbau'],
  'Sauberes Modellbau-Duell mit dem Millennium Falcon vom selben Hersteller.',
  'Star-Trek-Fans und Modellbauer mit Lust auf ein mehrstündiges Projekt.',
  'Wer ein fertig montiertes Displaymodell erwartet.',
  'Revell-Modellbausatz der U.S.S. Enterprise NCC-1701 aus der Originalserie.',
  ARRAY['klassisches Enterprise-Motiv', 'bekannter Modellbau-Hersteller', 'echtes Bauprojekt'],
  ARRAY['Montage und je nach Anspruch Bemalung nötig', 'nicht als spontanes Kinderspielzeug gedacht']
),
(
  'revell-star-wars-millennium-falcon-1-72-modellbausatz', 'Revell Star Wars Millennium Falcon Modellbausatz 1:72',
  'Der schnellste Schrotthaufen der Galaxis, jetzt in Einzelteilen.',
  'Revell-Modellbausatz des Millennium Falcon im Maßstab 1:72. Das direkte Gegenstück zur klassischen Enterprise für alle, die beim Basteln eher Schmuggler als Sternenflotte sind.',
  4999, 'EUR', 'https://www.amazon.de/dp/B0789RMK9W?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/610FRZczpHL._AC_SL1000_.jpg', ARRAY['https://m.media-amazon.com/images/I/610FRZczpHL._AC_SL1000_.jpg'],
  true, false, 'babo', 'gaming', 'modellbau', 'Spielzeug', 'Revell',
  ARRAY['babo:gaming', 'star-wars', 'millennium-falcon', 'revell', 'modellbau'],
  'Das Star-Wars-Schiff im symmetrischsten Duell des Guides.',
  'Star-Wars-Fans und erfahrenere Modellbauer.',
  'Wer ein fertiges oder robust bespielbares Modell sucht.',
  'Revell-Modellbausatz des Millennium Falcon im Maßstab 1:72.',
  ARRAY['ikonisches Raumschiff', 'großer Maßstab', 'langes Bastelprojekt'],
  ARRAY['braucht Zeit und ruhige Hände', 'fertiges Modell benötigt Stellfläche']
),
(
  'funko-pop-kirk-transporter', 'Funko POP! Plus Star Trek Captain Kirk im Transporter',
  'Halb angekommen, vollständig fürs Regal geeignet.',
  'Captain Kirk als Funko-POP-Plus-Figur während des Beamens auf der Transporterplattform. Das transparente Glitzerdesign macht aus einer kleinen Figur eine komplette Szene.',
  1595, 'EUR', 'https://www.amazon.de/dp/B0D98SM3VV?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71-0EXvz1yL._AC_SL1300_.jpg', ARRAY['https://m.media-amazon.com/images/I/71-0EXvz1yL._AC_SL1300_.jpg'],
  true, false, 'babo', 'gaming', 'sammelfigur', 'Spielzeug', 'Funko',
  ARRAY['babo:gaming', 'star-trek', 'kirk', 'transporter', 'funko', 'nerdy'],
  'Belegbares Amazon-Gegenstück zu Han Solo in Carbonit; ersetzt das nicht verfügbare LEGO-Duell.',
  'TOS-, Kirk- und Funko-Fans, die eine kleine Szene statt einer Standardfigur suchen.',
  'Wer keine zweite Funko-Runde im selben Guide möchte.',
  'Funko POP! Plus Nr. 1689 mit Kirk auf einer Transporterplattform.',
  ARRAY['szenisches Transporterdesign', 'offizielles Merchandise laut Listing', 'günstiger Geschenkpreis'],
  ARRAY['reine Deko', 'zweites Funko-Duell im Guide']
),
(
  'star-trek-tos-command-bademantel-gold', 'Star Trek TOS Command Bademantel in Gold',
  'Captain auf der Brücke, nur eben mit Hausschuhen.',
  'Goldfarbener Star-Trek-Bademantel im Stil der Kommando-Uniform aus der Originalserie. Waffelgewebe und Einheitsgröße machen ihn zum auffälligen Fan-Geschenk für langsame Sonntage.',
  11600, 'EUR', 'https://www.amazon.de/dp/B0BP6JNZC5?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61aGkfrn16L._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61aGkfrn16L._AC_SL1500_.jpg'],
  true, false, 'queen', 'lifestyle', 'bademantel', 'Bekleidung', 'Robe Factory',
  ARRAY['queen:lifestyle', 'star-trek', 'tos', 'bademantel', 'cosy', 'nerdy'],
  'Das sichtbarste Star-Trek-Produkt des Guides, selbst vor dem ersten Kaffee.',
  'TOS-Fans, die Fanmode mit einem echten Alltagsgegenstand verbinden wollen.',
  'Wer Einheitsgrößen oder auffällige Fanbekleidung nicht mag.',
  'Goldener Erwachsenen-Bademantel im Stil der TOS-Kommando-Uniform.',
  ARRAY['witziges Kostüm ohne Kostümparty', 'alltagstaugliches Fanprodukt', 'auffälliges Geschenk'],
  ARRAY['teuer für einen Bademantel', 'Einheitsgröße passt nicht jedem']
),
(
  'star-wars-jedi-bademantel-braun', 'Star Wars Jedi Bademantel in Braun und Beige',
  'Möge die Macht mit deinem Sonntag sein.',
  'Braun-beiger Jedi-Bademantel für Erwachsene mit Kapuze. Er verbindet Star-Wars-Kostümoptik mit einem Kleidungsstück, das man tatsächlich jede Woche benutzen kann.',
  6314, 'EUR', 'https://www.amazon.de/dp/B0GQFR41QQ?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81Fo87vJaHL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81Fo87vJaHL._AC_SL1500_.jpg'],
  true, false, 'queen', 'lifestyle', 'bademantel', 'Bekleidung', 'Star Wars',
  ARRAY['queen:lifestyle', 'star-wars', 'jedi', 'bademantel', 'cosy', 'nerdy'],
  'Günstigeres und breiter bewertetes Gegenstück zum TOS-Kommandomantel.',
  'Star-Wars-Fans, die morgens ohne vollständige Robe nicht zur Kaffeemaschine gehen.',
  'Wer Importangebote vermeiden oder lieber Baumwolle statt Kostümoptik möchte.',
  'Unisex-Jedi-Bademantel in Braun und Beige mit Kapuze.',
  ARRAY['sofort erkennbarer Jedi-Look', 'praktisch und witzig', 'viele Käuferbewertungen'],
  ARRAY['Importangebot möglich', 'Passform vor Bestellung prüfen']
),
(
  'logoshirt-star-trek-enterprise-crew-tasse', 'Logoshirt Star Trek Enterprise Crew Tasse 300 ml',
  'Kaffee für die Brücke, ohne Replikator.',
  'Porzellantasse mit U.S.S.-Enterprise-Crew-Motiv und 300 Millilitern Volumen. Ein unkompliziertes Geschenk für Büro, Küche oder den Schreibtisch eines Star-Trek-Fans.',
  1495, 'EUR', 'https://www.amazon.de/dp/B01N227FMM?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/716H0IoHiVL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/716H0IoHiVL._AC_SL1500_.jpg'],
  true, false, 'queen', 'kueche', 'tasse', 'Küche & Haushalt', 'Logoshirt',
  ARRAY['queen:kueche', 'star-trek', 'enterprise', 'tasse', 'buero-geschenk'],
  'Schlichte Alltagsseite des Tassen-Duells; Lagerbestand vor Veröffentlichung prüfen.',
  'Star-Trek-Fans, die ein kleines und brauchbares Geschenk suchen.',
  'Wer Spezialeffekte oder eine besonders große Tasse erwartet.',
  'Porzellantasse mit Enterprise-Crew-Motiv und 300 ml Volumen.',
  ARRAY['alltagstauglich', 'kleines Geschenk', 'lizenziertes Originaldesign laut Listing'],
  ARRAY['nur 300 ml', 'zum Recherchezeitpunkt knapper Lagerbestand']
),
(
  'paladone-star-wars-lichtschwert-farbwechsel-tasse', 'Paladone Star Wars Lichtschwert Farbwechsel-Tasse',
  'Der Kaffee wird warm und plötzlich beginnt der Krieg.',
  'Star-Wars-Tasse mit Lichtschwert-Motiv, das sich bei einem heißen Getränk verändert. Ein kleines Fan-Geschenk mit sichtbarem Effekt statt nur aufgedrucktem Logo.',
  1497, 'EUR', 'https://www.amazon.de/dp/B073W8RJH1?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/71v1rKyVP+L._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/71v1rKyVP+L._AC_SL1500_.jpg'],
  true, false, 'queen', 'kueche', 'tasse', 'Küche & Haushalt', 'Paladone',
  ARRAY['queen:kueche', 'star-wars', 'lichtschwert', 'tasse', 'farbwechsel'],
  'Gewinnt das Tassen-Duell durch den Wärmeeffekt und den einfachen Geschenkpreis.',
  'Star-Wars-Fans, Kollegen und Wichtelrunden mit Nerd-Anteil.',
  'Wer eine spülmaschinenfeste Standardtasse ohne Temperatureffekt bevorzugt.',
  '290-ml-Tasse mit wärmeaktiviertem Lichtschwert-Farbwechselmotiv.',
  ARRAY['sichtbarer Wärmeeffekt', 'günstiges Geschenk', 'offiziell lizenziert laut Listing'],
  ARRAY['kleines Volumen', 'Effekttassen verlangen meist schonendere Reinigung']
),
(
  'winning-moves-risiko-star-trek-deutsch', 'Winning Moves Risiko Star Trek – deutsche Ausgabe',
  'Föderationswerte, jetzt mit flächendeckender Eroberung.',
  'Deutsche Star-Trek-Ausgabe des Strategiespiel-Klassikers Risiko mit Franchise-Komponenten wie Q-Karten und Tribble-Markern. Für längere Spieleabende mit Erwachsenen und älteren Kindern.',
  3995, 'EUR', 'https://www.amazon.de/dp/B07JND9WB2?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81gmQi+KCYL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81gmQi+KCYL._AC_SL1500_.jpg'],
  true, false, 'babo', 'gaming', 'brettspiel', 'Spielzeug', 'Winning Moves',
  ARRAY['babo:gaming', 'star-trek', 'risiko', 'brettspiel', 'spieleabend'],
  'Das strategischere der beiden Franchise-Brettspiele im Guide.',
  'Star-Trek-Fans, die lange Strategiespiel-Abende mögen.',
  'Runden, die nach 45 Minuten sicher fertig sein wollen.',
  'Deutsche Star-Trek-Sonderausgabe von Risiko.',
  ARRAY['deutsche Ausgabe', 'bekannte Spielmechanik', 'franchisespezifische Komponenten'],
  ARRAY['lange Spielzeit', 'Marketplace-Angebot']
),
(
  'hasbro-monopoly-star-wars-light-side-deutsch', 'Hasbro Monopoly Star Wars Light Side – deutsche Ausgabe',
  'Die helle Seite der Macht entdeckt Immobilienbesitz.',
  'Deutsche Star-Wars-Light-Side-Ausgabe von Monopoly. Ein zugängliches Familienspiel und das weniger strategische Gegenstück zu Star Trek Risiko.',
  2683, 'EUR', 'https://www.amazon.de/dp/B0CD2B3NSP?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/817pb4LzHWL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/817pb4LzHWL._AC_SL1500_.jpg'],
  true, false, 'miniboss', 'gaming', 'brettspiel', 'Spielzeug', 'Hasbro',
  ARRAY['miniboss:gaming', 'star-wars', 'monopoly', 'brettspiel', 'familie'],
  'Familientaugliche Star-Wars-Seite des Brettspiel-Duells.',
  'Familien und Star-Wars-Fans, die Monopoly bereits kennen.',
  'Strategiefans, die Würfelglück und Grundstückshandel nicht mögen.',
  'Deutsche Light-Side-Sonderausgabe von Monopoly, empfohlen ab 8 Jahren.',
  ARRAY['deutsche Ausgabe', 'niedrige Einstiegshürde', 'familientauglich'],
  ARRAY['Monopoly bleibt Monopoly', 'Marketplace-Angebot und knapper Bestand möglich']
),
(
  'elbenwald-star-trek-enterprise-schneidebrett-buche', 'Elbenwald Star Trek Enterprise Schneidebrett aus Buche',
  'Die Enterprise landet heute neben dem Käse.',
  'Großes Schneidebrett aus Buchenholz mit U.S.S.-Enterprise-Motiv. Es verbindet ein klar erkennbares Star-Trek-Geschenk mit einer tatsächlich nutzbaren Küchenfläche.',
  4695, 'EUR', 'https://www.amazon.de/dp/B0C5DKF5N8?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81pgZQCI4CL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81pgZQCI4CL._AC_SL1500_.jpg'],
  true, false, 'queen', 'kueche', 'schneidebrett', 'Küche & Haushalt', 'Elbenwald',
  ARRAY['queen:kueche', 'star-trek', 'enterprise', 'schneidebrett', 'holz'],
  'Klares Lizenzsignal und deutscher Händler geben ihm den Rundensieg.',
  'Star-Trek-Fans, die Fanartikel lieber benutzen als nur sammeln.',
  'Wer Holzbretter in die Spülmaschine werfen möchte.',
  'Buchenholz-Schneidebrett mit Enterprise-Motiv, etwa 42 × 30 × 2 cm.',
  ARRAY['Echtholz', 'große Arbeitsfläche', 'offiziell lizenziert laut Listing'],
  ARRAY['Handpflege für Holz nötig', 'Motiv kann durch Schneiden Gebrauchsspuren bekommen']
),
(
  'picnic-time-star-wars-millennium-falcon-servierbrett', 'Picnic Time Star Wars Millennium Falcon Servierbrett',
  'Käseplatte in unter zwölf Parsecs.',
  'Servier- und Charcuteriebrett aus Holz in Form des Millennium Falcon. Ein auffälliges Küchen- und Partygeschenk, das Snacks direkt nach Weltraumschmuggel aussehen lässt.',
  5969, 'EUR', 'https://www.amazon.de/dp/B0CTS9V6GH?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81gI2eDZMHL._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81gI2eDZMHL._AC_SL1500_.jpg'],
  true, false, 'queen', 'kueche', 'servierbrett', 'Küche & Haushalt', 'Picnic Time',
  ARRAY['queen:kueche', 'star-wars', 'millennium-falcon', 'servierbrett', 'holz'],
  'Optisch starkes Gegenstück zum Enterprise-Brett, aber mit Import-Hinweis.',
  'Star-Wars-Fans, Gastgeber und Menschen mit ernsthaften Käseplatten-Plänen.',
  'Wer Importangebote oder unklare Lizenzangaben vermeiden möchte.',
  'Holz-Servierbrett in Form des Millennium Falcon.',
  ARRAY['starkes Displaymotiv', 'als Servierbrett nutzbar', 'ungewöhnliches Geschenk'],
  ARRAY['Importangebot aus den USA', 'Lizenzhinweis im Listing nicht eindeutig']
),
(
  'numskull-star-trek-3d-logo-leuchte', 'Numskull Star Trek 3D-Logo-Leuchte',
  'Die Sternenflotte übernimmt deinen Schreibtisch.',
  'Dreidimensionale Star-Trek-Logo-Leuchte von Numskull für Schreibtisch oder Wand. Sie eignet sich als Hintergrundlicht im Gaming-Setup oder als sichtbares Fan-Statement im Regal.',
  3624, 'EUR', 'https://www.amazon.de/dp/B0CRKQT1ML?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81BsityQx6L._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81BsityQx6L._AC_SL1500_.jpg'],
  true, false, 'babo', 'gaming', 'beleuchtung', 'Beleuchtung', 'Numskull',
  ARRAY['babo:gaming', 'star-trek', 'logo', 'lampe', 'setup'],
  'Markantere, aber teurere Seite des Logo-Leuchten-Duells.',
  'Star-Trek-Fans mit Gaming-, Streaming- oder Homeoffice-Setup.',
  'Wer eine helle Arbeitsleuchte statt atmosphärischer Dekoration sucht.',
  '3D-Logo-Leuchte für Tisch- oder Wandplatzierung.',
  ARRAY['Tisch und Wand möglich', 'markantes Logo', 'offizielles Merchandise laut Listing'],
  ARRAY['reine Akzentbeleuchtung', 'deutlich teurer als das Star-Wars-Gegenstück']
),
(
  'paladone-star-wars-logo-leuchte', 'Paladone Star Wars Logo-Leuchte',
  'Mehr Imperium pro Schreibtisch, weniger Kosten pro Logo.',
  'Kompakte Leuchte mit dem klassischen Star-Wars-Schriftzug. Als Akzentlicht passt sie auf Schreibtisch, Regal oder in den Hintergrund eines Streaming-Setups.',
  1599, 'EUR', 'https://www.amazon.de/dp/B093Y3W6SD?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/61gyTe8f61L._AC_SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/61gyTe8f61L._AC_SL1500_.jpg'],
  true, false, 'babo', 'gaming', 'beleuchtung', 'Beleuchtung', 'Paladone',
  ARRAY['babo:gaming', 'star-wars', 'logo', 'lampe', 'setup'],
  'Gewinnt über Preis, Verfügbarkeit und ein sofort verständliches Motiv.',
  'Star-Wars-Fans, Gamer und Streaming-Setups mit Platz für Akzentlicht.',
  'Wer eine vollwertige Raum- oder Arbeitsbeleuchtung sucht.',
  'Kompakte, offiziell lizenzierte Logo-Leuchte laut Listing.',
  ARRAY['günstiger Geschenkpreis', 'bekanntes Logo', 'kompakte Deko'],
  ARRAY['kein Arbeitslicht', 'weniger plastisch als die Star-Trek-Leuchte']
),
(
  'star-trek-cocktails-unendliche-drinks', 'Star Trek Cocktails: Unendliche Drinks in unendlicher Kombination',
  'Unendliche Weiten, vernünftigerweise mit Messbecher.',
  'Deutschsprachiges Star-Trek-Cocktailbuch von Glenn Dakin mit Rezepten und Franchise-Thema. Ein Fanbuch für die Hausbar, das nicht nur dekorativ im Regal bleiben muss.',
  2500, 'EUR', 'https://www.amazon.de/dp/3966589508?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/815ALMKglWL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/815ALMKglWL._SL1500_.jpg'],
  true, false, 'babo', 'kueche', 'cocktailbuch', 'Bücher', 'Cross Cult',
  ARRAY['babo:kueche', 'star-trek', 'cocktails', 'buch', 'hausbar'],
  'Originelle Drink-Seite eines bewusst nicht ganz symmetrischen Kulinarik-Duells.',
  'Star-Trek-Fans, Hobby-Barkeeper und Gastgeber.',
  'Wer alkoholfreie oder rein praktische Standardrezepte ohne Fan-Thema sucht.',
  'Deutschsprachiges Star-Trek-Cocktailbuch, erschienen bei Cross Cult.',
  ARRAY['ungewöhnliches Fanbuch', 'praktischer Einsatz in der Hausbar', 'deutsche Ausgabe'],
  ARRAY['wenige Bewertungen', 'Preis und Buybox vor Kauf prüfen']
),
(
  'star-wars-das-ultimative-kochbuch', 'Star Wars: Das ultimative Kochbuch',
  'Der offizielle Kochleitfaden für eine hungrige Galaxis.',
  'Deutschsprachiges Star-Wars-Kochbuch von Jenn Fujikawa und Marc Sumerak. Rezepte und Franchise-Aufmachung machen es zum Geschenk für Fans, die ihre Sammlung bis in die Küche verlängern.',
  3300, 'EUR', 'https://www.amazon.de/dp/3833244097?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/81SQmpmkSPL._SL1500_.jpg', ARRAY['https://m.media-amazon.com/images/I/81SQmpmkSPL._SL1500_.jpg'],
  true, false, 'queen', 'kueche', 'kochbuch', 'Bücher', 'Panini',
  ARRAY['queen:kueche', 'star-wars', 'kochbuch', 'rezepte', 'fanbuch'],
  'Alltagstauglicheres Gegenstück zum Star-Trek-Cocktailbuch.',
  'Star-Wars-Fans, die gern kochen oder ein hochwertiges Fanbuch suchen.',
  'Wer nur schnell nach nüchternen Alltagsrezepten sucht.',
  'Deutscher offizieller Kochleitfaden für die Star-Wars-Galaxis.',
  ARRAY['deutsche Ausgabe', 'offizieller Kochleitfaden laut Titel', 'Geschenk und Nutzbuch'],
  ARRAY['wenige Bewertungen', 'zum Recherchezeitpunkt knapper Bestand']
),
(
  'raven-forge-star-trek-commbadge-eiswuerfelform', 'Raven Forge Star Trek Commbadge Eiswürfelform',
  'Achtmal Sternenflotte, danach langsam Wasser.',
  'Silikonform für acht Eiswürfel im Star-Trek-Commbadge-Design. Ein kleines Bar-Gadget für Fans, bei dem die Lizenzbeschreibung des Listings vor dem Kauf kritisch gelesen werden sollte.',
  2238, 'EUR', 'https://www.amazon.de/dp/B0G53LTYD8?tag=geeklist-21&linkCode=ogi&th=1',
  'https://m.media-amazon.com/images/I/617T+5m3vWL._AC_SL1471_.jpg', ARRAY['https://m.media-amazon.com/images/I/617T+5m3vWL._AC_SL1471_.jpg'],
  true, false, 'babo', 'kueche', 'eiswuerfelform', 'Küche & Haushalt', 'Raven Forge',
  ARRAY['babo:kueche', 'star-trek', 'commbadge', 'eiswuerfel', 'bar-zubehoer'],
  'Direktes Funktions-Gegenstück zur Todesstern-Eisform, mit transparentem Lizenzhinweis.',
  'Star-Trek-Fans mit Hausbar und Freude an kleinen Details.',
  'Wer nur klar ausgewiesenes offizielles Merchandise kauft.',
  'Silikonform für acht Commbadge-förmige Eiswürfel.',
  ARRAY['acht Eiswürfel pro Durchgang', 'klares Fanmotiv', 'kleines Bar-Geschenk'],
  ARRAY['kaum Käuferbewertungen', 'widersprüchliche Lizenzformulierung im Listing']
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  tagline = EXCLUDED.tagline,
  description = EXCLUDED.description,
  price_cents = EXCLUDED.price_cents,
  currency = EXCLUDED.currency,
  affiliate_url = EXCLUDED.affiliate_url,
  image_url = EXCLUDED.image_url,
  image_urls = EXCLUDED.image_urls,
  is_published = EXCLUDED.is_published,
  is_featured = EXCLUDED.is_featured,
  shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category = EXCLUDED.shop_sub_category,
  amazon_category = EXCLUDED.amazon_category,
  brand = EXCLUDED.brand,
  shop_tags = EXCLUDED.shop_tags,
  editorial_note = EXCLUDED.editorial_note,
  fuer_wen = EXCLUDED.fuer_wen,
  nicht_fuer = EXCLUDED.nicht_fuer,
  key_fact = EXCLUDED.key_fact,
  pros = EXCLUDED.pros,
  cons = EXCLUDED.cons;

DO $$
DECLARE
  wanted_slugs CONSTANT text[] := ARRAY[
    'funko-pop-picard-borg-locutus', 'revell-star-trek-uss-enterprise-ncc-1701-modellbausatz',
    'revell-star-wars-millennium-falcon-1-72-modellbausatz', 'funko-pop-kirk-transporter',
    'star-trek-tos-command-bademantel-gold', 'star-wars-jedi-bademantel-braun',
    'logoshirt-star-trek-enterprise-crew-tasse', 'paladone-star-wars-lichtschwert-farbwechsel-tasse',
    'winning-moves-risiko-star-trek-deutsch', 'hasbro-monopoly-star-wars-light-side-deutsch',
    'elbenwald-star-trek-enterprise-schneidebrett-buche', 'picnic-time-star-wars-millennium-falcon-servierbrett',
    'numskull-star-trek-3d-logo-leuchte', 'paladone-star-wars-logo-leuchte',
    'star-trek-cocktails-unendliche-drinks', 'star-wars-das-ultimative-kochbuch',
    'raven-forge-star-trek-commbadge-eiswuerfelform'
  ];
  inserted_count integer;
BEGIN
  SELECT count(*) INTO inserted_count
  FROM public.products
  WHERE slug = ANY(wanted_slugs) AND is_published = true;

  IF inserted_count <> array_length(wanted_slugs, 1) THEN
    RAISE EXCEPTION 'Postflight failed: expected 17 published products, found %', inserted_count;
  END IF;
END
$$;

COMMIT;

SELECT slug, name, price_cents, affiliate_url, is_published
FROM public.products
WHERE slug IN (
  'funko-pop-picard-borg-locutus', 'revell-star-trek-uss-enterprise-ncc-1701-modellbausatz',
  'revell-star-wars-millennium-falcon-1-72-modellbausatz', 'funko-pop-kirk-transporter',
  'star-trek-tos-command-bademantel-gold', 'star-wars-jedi-bademantel-braun',
  'logoshirt-star-trek-enterprise-crew-tasse', 'paladone-star-wars-lichtschwert-farbwechsel-tasse',
  'winning-moves-risiko-star-trek-deutsch', 'hasbro-monopoly-star-wars-light-side-deutsch',
  'elbenwald-star-trek-enterprise-schneidebrett-buche', 'picnic-time-star-wars-millennium-falcon-servierbrett',
  'numskull-star-trek-3d-logo-leuchte', 'paladone-star-wars-logo-leuchte',
  'star-trek-cocktails-unendliche-drinks', 'star-wars-das-ultimative-kochbuch',
  'raven-forge-star-trek-commbadge-eiswuerfelform'
)
ORDER BY slug;
