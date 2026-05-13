#!/usr/bin/env python3
import requests
import time

SUPABASE_URL = "https://ydiihvzcxaaoqhmgoqvu.supabase.co"
SERVICE_KEY = "***REDACTED***"
HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

notes = {
    "toureal-nachfuellbarer-parfuemzerstaeuber-reise": "Parfüm im Handgepäck mitführen ohne den Originalflakon zu riskieren — das ist die ganze Idee. Befüllen, mitnehmen, fertig. Für alle die regelmäßig reisen und trotzdem gut riechen wollen.",
    "tecknet-ergonomische-kabellose-maus-bluetooth": "Ergonomische Mäuse sind kein Luxus für alle die täglich stundenlang klicken. TeckNet macht solide Peripherie ohne Premium-Preis — gut für den täglichen Einsatz im Büro oder Home Office.",
    "riesige-aufblasbare-ente-pool": "Eine riesige aufblasbare Ente im Pool ist das ehrlichste Statement das man über Sommer machen kann. Kein tieferer Sinn, nur Freude. Poolparty-Pflicht.",
    "musicozy-bluetooth-schlafkopfhoerer": "Schlafen mit normalen Kopfhörern ist unbequem. Diese Stirnband-Variante liegt flach am Kopf und spielt trotzdem Musik oder Podcasts. Für Seitenschläfer oder alle die Einschlafrituale ernst nehmen.",
    "flauschige-handschuhe-weihnachten": "Flauschige Handschuhe die sich anfühlen wie Kuscheldecken für die Hände — im Winter ist das keine Übertreibung. Als Geschenk charmant, als Alltagsgegenstand unterschätzt.",
    "hyako-massagepistole-triggerpunkt": "Massagepistolen sind mittlerweile Standard nach dem Training — und diese hier macht was sie soll ohne dabei zu klingen wie ein Presslufthammer. Für Schulter, Nacken, Waden nach Sport oder langen Tagen.",
    "talking-tables-partyspiel-geburtstag": "Partyspiele die man beim ersten Mal spielen kann ohne die Anleitung dreimal zu lesen — das ist das Konzept. Talking Tables trifft das gut: schnell erklärt, trotzdem Spaß für den ganzen Abend.",
    "costway-tischkicker-kickertisch": "Ein echter Kicker im Wohnzimmer ist ein Statement. Costway macht solide Einsteiger-Modelle — kein Profigerät, aber ausreichend für Freunde und Familienabende ohne Profi-Anspruch.",
    "rocketbook-wiederverwendbares-notizbuch-a4": "Notizen schreiben, abfotografieren, Seite abwischen und von vorne — das Konzept ist clever. Wer viel handschriftlich notiert aber alles digital haben will: Rocketbook ist die ehrlichste Lösung dafür.",
    "sprossenwand-mit-klimmzugstange-erwachsene": "Sprossenwände sind das unterschätzteste Heimtrainingsequipment — Klimmzüge, Hängen, Schultertraining, Kernkraft. Einmal montiert hält das Jahrzehnte und braucht keinen Strom.",
    "cream-noise-machine-baby-tragbar": "White Noise funktioniert bei Babys — das ist kein Mythos. Diese tragbare Version kann mit ins Kinderzimmer, in die Krippe oder auf Reisen. Für Eltern die schlaflose Nächte ernst nehmen.",
    "nfc-qr-aufsteller-instagram-schild": "Handy drauf, direkt auf Instagram — für Cafés, Friseure oder jeden der mehr Follower über physische Orte gewinnen will. Einmal programmiert, läuft von selbst. Kleines Ding, echter Nutzen.",
    "kabeltasche-edc-elektronik-organizer-reise": "Wer Ladekabel, Adapter, Powerbank und Kopfhörer in einer Tasche ordentlich verstauen will statt sie lose im Rucksack zu suchen: genau dafür ist das. Auf Reisen unverzichtbar.",
    "sticker-set-200-stueck-neon-vinyl-wasserfest": "200 wasserfeste Vinyl-Sticker in Neon sind für Laptops, Wasserflaschen oder Notizbücher — wer seinen Sachen Persönlichkeit geben will ohne dauerhaften Schaden anzurichten.",
    "lego-botanicals-japanischer-roter-ahorn": "Der japanische Ahorn ist eines der schönsten Botanicals-Sets — die roten Blätter sehen täuschend echt aus. Für alle die eine Pflanze wollen die den Winter überlebt.",
    "magnetisches-schachspiel-klappbar-reise": "Schach auf Reisen hat immer das Problem der fliegenden Figuren. Die magnetische Version löst das — und die klappbare Box ist gleichzeitig das Brett. Kompakt, durchdacht, funktioniert.",
    "ultraleichter-faltbarer-rucksack-20l": "Ein Rucksack der sich auf Taschengröße zusammenfalten lässt ist das ideale Backup in jedem Koffer. Für Tagesausflüge, Einkäufe oder Notfälle — wiegt nichts und ist immer dabei.",
    "snagger-snackspender-saubere-haende": "Chips essen ohne Fettfinger — das Konzept ist simpel und funktioniert. Für Büro, Couch oder alle die ihren Laptop lieben und Tastaturkrümel hassen.",
    "harry-potter-nachtwecker-lcd-sounds": "Ein Wecker mit Harry-Potter-Sounds ist für Fans ein Morgenritual das Stimmung macht. LCD-Display, Hogwarts-Melodien — für alle die auch beim Aufwachen in der Welt bleiben wollen.",
    "japanische-gelstifte-0-5mm-5er-set": "Japanische Gelstifte haben eine Fangemeinde aus gutem Grund — die Tinte fließt gleichmäßig, der Strich ist präzise, und 0,5mm ist die goldene Mitte für Handschrift und Skizzieren.",
    "experimentierset-kinder-100-experimente-stem": "100 Experimente klingen nach viel — und das sind sie. Für Kinder die Fragen stellen und Antworten selbst herausfinden wollen ist das besser als jeder Bildschirm.",
    "mx2-digitales-mikroskop-kinder-1000x": "1000-fache Vergrößerung für Kinder — das klingt nach Labor. Ist es auch, nur zuhause. Für alle die neugierig sind was in einem Wassertropfen oder einem Blatt wirklich steckt.",
    "spider-man-tom-holland-spardose-20cm": "Spider-Man in Tom-Holland-Version als Spardose — für MCU-Fans der jüngeren Generation ist das kein Wahlrecht. 20cm, gute Verarbeitung, erkennbar. Spar-Motivation durch Held.",
    "elektronische-atm-spardose-kinder": "Eine ATM-Spardose die Geld zählt und eine PIN braucht — macht Sparen für Kinder zu einem echten Erlebnis. Besser als die Dose die man einfach aufmacht wenn man Geld braucht.",
    "laptop-staender-hoehenverstellbar-360-drehbar": "Laptop auf Augenhöhe statt Nackenpein nach unten — das ist der ganze Deal. 360-Grad-Drehung ist für Präsentationen nützlich. Wer täglich am Laptop arbeitet sollte das haben.",
    "white-noise-machine-baby-einschlafhilfe": "Speziell für Babys und Kleinkinder entwickelt — verschiedene Geräusche, Timer, tragbar. Der Unterschied zu günstigeren Varianten liegt in der Lautstärke und den Frequenzen die tatsächlich beruhigen.",
    "rite-in-the-rain-allwetter-notizbuch-field": "Notizbuch im Regen — das klingt nach Nische bis man es braucht. Rite in the Rain ist Standard bei Forschern, Soldaten und Outdoor-Professionals. Wer im Freien arbeitet oder notiert: das hier überlebt alles.",
    "lamy-safari-harry-potter-gryffindor-fueller": "Lamy Safari ist ein verlässlicher Einstiegsfüller — die Gryffindor-Edition macht ihn zum Sammlerstück. Für Harry-Potter-Fans die gerne schreiben: Funktion und Fandom in einem.",
    "fusselroller-tierhaare-540-blatt-tragbar": "540 Blatt bedeutet lange Ruhe vor dem Nachkaufen. Für Haushalte mit Tier ist ein Fusselroller kein Gadget sondern Grundausstattung. Tragbar heißt: auch unterwegs einsetzbar.",
    "ameisenfarm-acryl-set-natursand": "Ameisenfarm beobachten ist hypnotisch — wirklich. Das Acryl-Set mit Natursand ist die moderne Version des Kindheitskults. Für neugierige Kinder und Erwachsene die das nie hatten.",
    "petkit-futterautomat-mit-kamera-ki-3l": "Tier alleine lassen und gleichzeitig füttern und beobachten — PETKIT macht das mit App, Kamera und KI-Portionskontrolle. Für alle die reisen und trotzdem sichergehen wollen.",
    "bug-beam-insektenfalle-uv-licht": "UV-Licht zieht Insekten an, die Falle hält sie fest — kein Gift, kein Spray, kein Lärm. Für Balkone, Gärten oder Schlafzimmer im Sommer eine saubere Alternative zu allem anderen.",
    "lego-icons-star-trek-uss-enterprise": "Das LEGO-Set zur USS Enterprise ist für Star-Trek-Fans das was der Millennium Falcon für Star-Wars-Fans ist. Komplex, detailreich, und am Ende ein Objekt das ins Regal gehört.",
    "nintendo-classic-mini-snes": "Das SNES Mini ist Nostalgie in Reinform — 21 Spiele drauf, alles vorinstalliert, einfach anschließen. Wer mit Super Mario World oder Zelda aufgewachsen ist wird das nicht zwei Stunden stehen lassen.",
    "weinbeluefter-dekanter-ausgiesser": "Wein aus der Flasche direkt in den Dekanter — in einem Zug, mit Belüftung. Wer Rotwein trinkt und nicht 30 Minuten warten will: das hier beschleunigt den Prozess spürbar.",
    "yoga-gartenzwerg-buddha-meditation-20cm": "Ein meditierender Gartenzwerg ist die ruhigste Aussage die man im Garten machen kann. Ironie oder Ernst — beides funktioniert. Für Gartenliebhaber mit Sinn für Details.",
    "periodensystem-mit-echten-elementen-acryl": "Ein Periodensystem das echte Elementproben enthält — für Chemie-Begeisterte, Lehrer oder alle die Wissenschaft anfassbar machen wollen. Das ist kein Poster, das ist ein Objekt.",
    "drehbare-kosmos-sternkarte-planeten": "Drehbare Sternkarte bedeutet: Datum einstellen, Uhrzeit einstellen, Himmel ablesen. Für Hobbyastronomen oder alle die beim nächsten Sternschauen wissen wollen was sie sehen.",
    "digitales-mikroskop-kinder-1000-fach": "Das zweite Mikroskop in der Auflistung — dieses hier ist für ältere Kinder oder Erwachsene die es ernsthafter nehmen. 1000-fach, digital, mit Display. Für echte Entdecker.",
    "tennis-trainer-solo-trainingsgeraet": "Tennis ohne Partner trainieren — der Trainer hält den Ball am Gummiband und man schlägt einfach. Klingt simpel, ist es auch. Für alle die ihre Technik verbessern wollen ohne einen Platz buchen zu müssen.",
    "stress-baelle-quetschball-set": "Quetschbälle sind das analoge Fidget-Toy — einfach, effektiv, lautlos. Im Büro, beim Lesen oder einfach so. Wer Stress in den Händen verarbeitet weiß was das bedeutet.",
    "wurfzelt-3-4-personen-2-sekunden-aufbau": "2 Sekunden Aufbau ist kein Marketing-Trick — man wirft das Zelt in die Luft und es steht. Für spontane Übernachtungen oder Festivals wo man keine Lust auf Zeltbau-Stress hat.",
    "personalisiertes-foto-puzzle-1000-teile": "Ein Puzzle aus einem eigenen Foto ist eines dieser Geschenke die zeigen dass man sich Mühe gemacht hat. 1000 Teile bedeutet genug Beschäftigung um es wertzuschätzen.",
    "tipi-zelt-4-6-personen-mit-stehoehe": "Stehhöhe im Zelt verändert alles — man zieht sich an ohne Akrobatik, kann sich umschauen, fühlt sich nicht wie in einem Schlafsack-Gefängnis. Für Familien oder Gruppen die Komfort beim Camping wollen.",
    "personalisiertes-malen-nach-zahlen-eigenes-foto": "Malen nach Zahlen mit eigenem Foto — das eigene Haustier, die Familie, eine Landschaft. Das Ergebnis ist kein Kunstwerk aber ein persönliches Objekt das man aufhängt. Für kreative Abende.",
    "skullcandy-crusher-anc-2-wireless-kopfhoerer": "Skullcandy Crusher ist für Bass-Liebhaber bekannt — der haptische Bass ist ein Alleinstellungsmerkmal das man entweder liebt oder zu viel findet. ANC dazu macht ihn zum ernsthaften Alltagskopfhörer.",
    "lego-technic-ferrari-sf-24-f1-rennauto": "Das Ferrari F1-Set im 1:8 Maßstab ist für Technic-Enthusiasten und Formel-1-Fans gleichzeitig. Komplex im Bau, beeindruckend im Ergebnis — kein Kinderspielzeug sondern Erwachsenenmodell.",
    "bierbrauset-pils-5-liter-fass": "Eigenes Bier brauen klingt nach Aufwand — und ist es auch. Aber der Prozess ist lehrreich und das Ergebnis nach 1-2 Wochen tatsächlich trinkbar. Für alle die wissen wollen wie Pils entsteht.",
    "ki-go-brett-mit-roboterarm-sense-robot": "Ein Roboter der Go spielt — nicht als Gimmick, sondern als echter Gegner der lernt und sich anpasst. Für Go-Spieler die einen geduldigen Sparring-Partner suchen der nie müde wird.",
    "bitzee-disney-interaktives-digital-haustier": "Digitale Haustiere aus der Tamagotchi-Ära sind zurück — Bitzee bringt das ins 3D-Display mit Disney-Charakteren. Für Kinder die ein Haustier wollen ohne dass jemand putzen muss.",
    "tosy-flying-disc-108-rgb-leds-leuchtfrisbee": "108 LEDs sind kein Understatement — diese Disc leuchtet nachts wie ein UFO. Für abendliche Runden am Strand oder im Park. Die Leucht-Version vom TOSY macht Frisbee zu einem Abendspektakel.",
    "lego-fifa-fussball-wm-pokal-editions-set": "Der FIFA WM-Pokal aus LEGO — für Fußball-Fans die auch bauen. Das fertige Modell ist detailgetreu genug dass man es ins Regal stellt. Kombiniert zwei Leidenschaften in einem Objekt.",
    "shashibo-formwechsel-box-magnetisch": "Shashibo ist eines dieser Objekte die man nicht weglegen kann — 70 Formen aus einer magnetischen Box. Für alle die mit den Händen denken oder einfach etwas Faszinierendes auf dem Schreibtisch wollen.",
    "led-leuchtbrille-aufladbar-party": "LED-Leuchtbrille für Partys, Festivals oder Faschingskostüme — aufladbar bedeutet kein Batteriewechsel-Stress mitten in der Nacht. Kein ernsthaftes Produkt, aber exakt das was es sein soll.",
    "4k-mini-ueberwachungskamera-wlan-nachtsicht": "Kleine 4K-Kamera mit WLAN — für Eingangsbereich, Kinderzimmer oder als Zweitkamera innen. Nachtsicht und App-Anbindung sind Standard in dieser Klasse, die Kompaktheit ist das Alleinstellungsmerkmal.",
    "mammotion-luba-3-awd-maehroboter-lidar": "LiDAR-Navigation ohne Begrenzungsdraht — das ist der Unterschied zu günstigeren Mährobotern. Der LUBA 3 fährt präzise, kennt seinen Bereich und braucht keine Installation im Rasen. Für alle die es einmal richtig machen wollen.",
    "welpen-usb-ladekabel-hunde-design": "Ein USB-Kabel das aussieht wie ein kleiner Hund — vollkommen unnötig, vollkommen charmant. Für Hundeliebhaber die auch beim Laden lächeln wollen.",
    "cosrx-pdrn-exosome-skinplaning-glaze-mask": "COSRX ist in der K-Beauty-Community keine Unbekannte — die PDRN-Maske richtet sich an alle die Hautpflege ernst nehmen und Inhaltsstoffe verstehen. Für Skincare-Enthusiasten kein Experiment sondern eine fundierte Wahl.",
    "ninabella-haarbuerste-ohne-ziepen": "Eine Bürste die durch nasses Haar gleitet ohne zu reißen — für alle mit langen oder lockigen Haaren ist das kein Bonus sondern Grundanforderung. Ninabella hat das Konzept gut umgesetzt.",
    "makeblock-codey-rocky-programmierbarer-roboter": "Codey Rocky ist für Kinder ab 6 Jahren gedacht und führt spielerisch ins Programmieren ein. Scratch-basiert, visuell, sofort befriedigend — der Roboter reagiert auf Code und das macht den Unterschied.",
    "fifa-world-cup-2026-ballers-minifiguren-2er-pack": "WM 2026 Minifiguren — für Fußballfans und Sammler. Als Geschenk für Kinder oder Fans der eigenen Nationalmannschaft ein unkomplizierter Treffer.",
    "ramen-katze-japan-y2k-kawaii-t-shirt": "Ramen-Katze auf Y2K-Shirt — entweder man versteht die Ästhetik oder nicht. Wer Anime, Japan und 2000er-Nostalgie mag: das ist das Shirt das alle ansprechen werden.",
    "rokr-3d-holzpuzzle-raumfaehre-modellbausatz": "ROKR macht Holzpuzzle-Modelle die am Ende wirklich wie Modelle aussehen. Die Raumfähre ist komplex genug für mehrere Abende und das Ergebnis ist ausstellungswürdig. Für geduldige Bastler.",
    "dnd-starter-set-helden-der-grenzlande-deutsch": "Das offizielle D&D Starter Set auf Deutsch — für alle die Dungeons & Dragons ausprobieren wollen ohne einen erfahrenen Spielleiter zu kennen. Enthält alles was man braucht um anzufangen.",
    "bialetti-moka-express-stranger-things-edition": "Bialetti Moka ist ein Klassiker, die Stranger Things Edition macht ihn zum Sammlerstück. Für alle die Kaffee mögen und die Serie kennen: funktional und Fandom in einem.",
    "masters-of-the-universe-t-shirt-80er-jahre": "He-Man-Shirt für alle die mit dem Original aufgewachsen sind — oder für alle die Retro-Ästhetik mögen ohne die Referenz zu kennen. Beides funktioniert.",
    "stranger-things-lucas-t-shirt-offiziell": "Offizielles Lizenzprodukt, Lucas-Design — für Stranger-Things-Fans die ihren Lieblings-Charakter tragen wollen. Qualität wie bei offiziellen Merch-Produkten üblich.",
    "lehrergeschenk-baumwollbeutel-klassenarbeit-spruch": "Lehrergeschenke sind schwer — dieses hier trifft den richtigen Ton zwischen Humor und Wertschätzung. Baumwolle, praktisch, der Spruch macht den Unterschied zu generischen Geschenken.",
    "lehrergeschenk-stofftasche-abschiedsgeschenk": "Zum Schuljahresende etwas Persönliches mitbringen — eine Stofftasche mit passendem Motiv ist praktisch und zeigt Nachdenken. Für Klassen die ihrem Lehrer etwas Dauerhaftes geben wollen.",
    "bite-away-two-elektronischer-insektenstichheiler": "Wärme auf den Stich — das klingt nach Mythos und ist trotzdem klinisch belegt. Bite away funktioniert wenn man es sofort nach dem Stich anwendet. Für alle die im Sommer viel draußen sind.",
    "beheizte-wimpernzange-s600": "Beheizte Wimpernzange statt klassischem Eyelash Curler — die Wärme hält die Kurve länger. Für alle die täglich ihre Wimpern schwingen und wissen dass der normale Zanger nach zwei Stunden nachgibt.",
    "prunus-notfall-kurbelradio-j366": "Kurbelradio ohne Strom — für Camping, Stromausfälle oder als Notfallreserve im Auto. PRUNUS macht verlässliche Geräte in diesem Segment. Wer vorbereitet sein will ohne zu übertreiben.",
    "thopeb-sicherheitsalarm-schluesselhaenger": "Ein Schlüsselanhänger der Alarm schlägt wenn man ihn aktiviert — für Frauen die nachts alleine unterwegs sind oder einfach mehr Sicherheitsgefühl wollen. Klein, laut, unkompliziert.",
    "infactory-boyfriend-kissen": "Ein Kissen mit Arm zum Kuscheln — klingt nach Witz, ist aber tatsächlich ein Bestseller. Für alle die die Umarmung vermissen oder einfach beim Schlafen etwas zum Festhalten wollen.",
    "wixies-wichstuecher-scherzartikel": "Scherzartikel der einfachsten Kategorie — der Name sagt alles. Als Gag-Geschenk für Menschen mit dem richtigen Humor perfekt. Erwartet keine tiefere Produktkritik.",
    "wahrheit-oder-pflicht-kartenspiel-paare": "Wahrheit oder Pflicht als Kartenspiel für Paare ist die elaboriertere Version des Klassikers — mit Fragen die tatsächlich Gespräche starten. Für neue Paare und alte Paare die sich neu entdecken wollen.",
    "asien-vegetarisch-kochbuch": "120 Rezepte aus ganz Asien ohne Fleisch — das Buch zeigt wie vielfältig vegetarische Asienküche ist jenseits von Tofu-Klischees. Für alle die kochen lernen wollen und dabei entdecken statt wiederholen.",
    "gluecksgut-voodoo-puppe": "Eine Voodoo-Puppe als Stress-Therapie — Nadeln rein, Frustration raus. Kein ernsthafter Schadenszauber sondern das witzigste Schreibtischobjekt das es gibt. Bürogeschenk mit garantierter Reaktion.",
    "scheisse-quartett-kartenspiel": "32 verschiedene Kackhaufen-Charaktere im Quartett-Format — das klingt absurder als es ist. Das Spiel funktioniert wie klassisches Quartett und ist für alle die ihren Humor kennen sofort ein Favorit.",
    "gluecksgut-anti-stress-wuerfel": "Der Cubizin ist ein Fidget-Würfel mit sechs verschiedenen Funktionen — drücken, klicken, drehen, schieben. Für alle die beim Denken etwas in den Händen brauchen ohne es zu merken.",
    "nourished-led-gesichtsmaske-nir": "912 LEDs und NIR-Licht auf professionellem Niveau — diese Maske richtet sich an ernsthafte Skincare-Anwender die Lichttherapie zu Hause wollen ohne Kompromisse bei der Technik.",
    "hasbro-twister-klassik": "Twister ist einer dieser Klassiker der funktioniert weil er Körperkontakt und Lachen erzwingt. Das Original von Hasbro braucht keine Verbesserung — ab sechs Personen wird es interessant.",
    "street-fighter-arcade-machine": "Street Fighter auf einem echten Arcade-Automaten im Wohnzimmer — 14 Games, 17-Zoll-Display, WiFi. Das ist kein Gadget sondern ein Möbelstück für alle die das ernst nehmen.",
    "vtech-kidi-dj-mix": "10-in-1 DJ-Pult für Kinder zwischen 6 und 12 mit echtem Bluetooth — VTech macht das kindgerecht ohne es zu simplifizieren. Für kleine Musiker die mehr wollen als einen Plastik-Lautsprecher.",
    "lumineo-ultraschall-peelinggeraet": "29.000 Schwingungen pro Sekunde plus Ionen und EMS — das klingt nach viel weil es viel ist. Für alle die ihr Hautpflege-Ritual aufwerten wollen ohne sofort eine Profi-Behandlung zu buchen.",
    "batman-fuggler-pluesch": "Fuggler sind Plüschtiere mit Zähnen — verstörend ist das Konzept, charmant die Umsetzung. Batman als Fuggler ist für Fans der dunklen Seite des Superhelden-Universums das richtige Objekt.",
    "led-gesichtsmaske-wireless-4-modi": "Kabellose LED-Maske für unterwegs oder beim Fernsehen — vier Modi für verschiedene Hautbedürfnisse. Wer Lichttherapie regelmäßig anwenden will braucht Komfort, und der kommt hier ohne Kabel.",
    "uag-macbook-air-15-huelle": "UAG macht Schutzhüllen nach US-Militärstandard — transparent-schwarz bedeutet man sieht das MacBook noch und schützt es trotzdem ernsthaft. Für alle die ihr Equipment nicht ungeschützt tragen.",
    "hwwr-karaoke-maschine-2-mikrofone": "120 Watt, zwei Mikrofone, RGB-Licht und Bluetooth 5.3 — das ist keine Party-Spielerei sondern eine echte Karaoke-Anlage. Für alle die Karaoke-Abende zu Hause ernst nehmen.",
    "vicseed-magnet-handyhalterung-auto": "20 N55-Magnete und 20 kg Haltekraft — das Handy bleibt wo es soll auch auf der schlechtesten Straße. MagSafe-kompatibel bedeutet für iPhone-Nutzer: einfach drauflegen, sitzt.",
    "schachroboter-mit-ki-roboterarm-sense-robot": "Ein Roboterarm der Schachfiguren bewegt und dabei KI-Stärke nach eigenem Niveau anpasst — das ist Schach auf einem anderen Level. Für alle die einen Gegner suchen der immer Zeit hat und nie meckert.",
    "katzenschlafsack-fuer-menschen": "Ein Schlafsack in Katzenform für Menschen — Kopf raus, Körper drin, Pfoten drumrum. Vollkommen absurd und trotzdem eines dieser Produkte die man kauft weil man nichts dagegen tun kann.",
}

def update_note(slug, note):
    url = f"{SUPABASE_URL}/rest/v1/products?slug=eq.{slug}"
    resp = requests.patch(url, headers=HEADERS, json={"editorial_note": note})
    return resp.status_code

total = len(notes)
success = 0
failed = []

for i, (slug, note) in enumerate(notes.items(), 1):
    status = update_note(slug, note)
    if status in (200, 204):
        success += 1
        print(f"[{i}/{total}] ✓ {slug}")
    else:
        failed.append(slug)
        print(f"[{i}/{total}] ✗ {slug} (status {status})")
    time.sleep(0.1)

print(f"\n=== Fertig: {success}/{total} erfolgreich ===")
if failed:
    print(f"Fehlgeschlagen: {failed}")
