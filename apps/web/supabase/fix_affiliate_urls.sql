-- ============================================================
-- FIX: Affiliate-URLs um 1 Position vorwärts rotiert
-- Ursache: URLs ab Produkt 28 zeigen jeweils auf das vorherige Produkt
-- Fix: Jedes Produkt bekommt die URL des nächsten Produkts
-- ============================================================

-- Produkte 1–27 sind korrekt, keine Änderung nötig
-- Ab Produkt 28 (wasserfilter) bis 85 (mangoschneider): URLs tauschen

update products set affiliate_url = 'https://amzn.to/4w6rl74'  where slug = 'wasserfilter-trinkflasche-edelstahl';
update products set affiliate_url = 'https://amzn.to/3QZXg8U'  where slug = 'azengear-paracord-survival-armband-set';
update products set affiliate_url = 'https://amzn.to/3OPlKRw'  where slug = 'reise-haengematte-nylon-schnelltrocknend';
update products set affiliate_url = 'https://amzn.to/4cvV9Cf'  where slug = 'suboos-aufladbare-campinglaterne';
update products set affiliate_url = 'https://amzn.to/48mejbl'  where slug = 'tre-feuerstahl-xxl';
update products set affiliate_url = 'https://amzn.to/4e9aj1E'  where slug = 'mad-monkey-retro-spielekonsole';
update products set affiliate_url = 'https://amzn.to/3QxdO8b'  where slug = 'mayflash-f300-arcade-joystick';
update products set affiliate_url = 'https://amzn.to/4mTklGm'  where slug = 'personalisiertes-led-nachtlicht-jugendzimmer';
update products set affiliate_url = 'https://amzn.to/4tEnPzc'  where slug = 'kytok-controller-staender-4-etagen';
update products set affiliate_url = 'https://amzn.to/4mTWvKD'  where slug = 'jdvootd-programmierbare-led-laufschrift-tafel';
update products set affiliate_url = 'https://amzn.to/3OsG7UJ'  where slug = 'fiyapoo-ergonomischer-smartphone-staender';
update products set affiliate_url = 'https://amzn.to/4tA68AI'  where slug = 'yusing-gaming-haengevitrine-regal';
update products set affiliate_url = 'https://amzn.to/4tsZjkl'  where slug = 'empation-cocktailshaker-set';
update products set affiliate_url = 'https://amzn.to/4cH2WvL'  where slug = 'newl-reflektierende-holographic-windbreaker';
update products set affiliate_url = 'https://amzn.to/4u1KIfE'  where slug = 'rfid-blocker-karte-neueste-technologie';
update products set affiliate_url = 'https://amzn.to/41VG72x'  where slug = 'mfi-zertifiziert-magsafe-wireless-ladestation-15w';
update products set affiliate_url = 'https://amzn.to/3Qxky5Z'  where slug = 'findchic-edelstahl-drehring';
update products set affiliate_url = 'https://amzn.to/4ty1jbb'  where slug = 'fenree-business-rucksack-wasserdicht-usb';
update products set affiliate_url = 'https://amzn.to/4vS9Mra'  where slug = 'joyroom-brillenhalter-auto-sonnenblende';
update products set affiliate_url = 'https://amzn.to/3QuvJMO'  where slug = 'toureal-nachfuellbarer-parfuemzerstaeuber-reise';
update products set affiliate_url = 'https://amzn.to/3Qv3uh6'  where slug = 'hyako-massagepistole-triggerpunkt';
update products set affiliate_url = 'https://amzn.to/3OBDVdz'  where slug = 'caspor-akupressurmatte-ganzkoerper';
update products set affiliate_url = 'https://amzn.to/4mNxCA2'  where slug = 'musicozy-bluetooth-schlafkopfhoerer';
update products set affiliate_url = 'https://amzn.to/4cLlLhv'  where slug = 'fussmassage-igelball-faszienrolle';
update products set affiliate_url = 'https://amzn.to/4sVUdMw'  where slug = 'porseme-ultraschall-luftbefeuchter-farbwechsel';
update products set affiliate_url = 'https://amzn.to/4mPGYeJ'  where slug = 'yoga-design-lab-trainingsrad';
update products set affiliate_url = 'https://amzn.to/4cxSzMb'  where slug = 'eisroller-gesicht-augen-hautpflege';
update products set affiliate_url = 'https://amzn.to/4vMKzyp'  where slug = 'lifepro-infrarot-saunadecke';
update products set affiliate_url = 'https://amzn.to/4cyN285'  where slug = 'elektrisches-nackenmassagegeraet-schultermassage';
update products set affiliate_url = 'https://amzn.to/4tJkNJG'  where slug = 'inner-peace-meditationskissen-yogakissen';
update products set affiliate_url = 'https://amzn.to/3OD5jrF'  where slug = 'ubergames-riesenwackelturm-jumbo-jenga';
update products set affiliate_url = 'https://amzn.to/4ubsMiJ'  where slug = 'talking-tables-partyspiel-geburtstag';
update products set affiliate_url = 'https://amzn.to/4vPzDQr'  where slug = 'huch-what-kartenspiel-deutsche-ausgabe';
update products set affiliate_url = 'https://amzn.to/3QuwxkO'  where slug = 'tosy-flying-disc-wiederaufladbar';
update products set affiliate_url = 'https://amzn.to/4cyOG9L'  where slug = 'shuffleboard-tischset-curling-familienspiel';
update products set affiliate_url = 'https://amzn.to/42sL2bl'  where slug = 'derayee-schaumstoff-wasserpistole';
update products set affiliate_url = 'https://amzn.to/3QtubCJ'  where slug = 'costway-tischkicker-kickertisch';
update products set affiliate_url = 'https://amzn.to/4tJmwPa'  where slug = 'mejasg-elektronischer-lcd-wuerfel';
update products set affiliate_url = 'https://amzn.to/4vRPfTB'  where slug = 'wuerfelturm-lasergeaetzt-brettspiel';
update products set affiliate_url = 'https://amzn.to/4e9ZeND'  where slug = 'asmodee-unlock-tombstone-express-raetselspiel';
update products set affiliate_url = 'https://amzn.to/4sTNlio'  where slug = 'lamicall-magsafe-autohalterung';
update products set affiliate_url = 'https://amzn.to/4tr6iu2'  where slug = 'dicmky-hoehenverstellbarer-schreibtisch-aufsatz';
update products set affiliate_url = 'https://amzn.to/4mTvIy2'  where slug = 'superone-zigarettenanzuender-schnellladegeraet';
update products set affiliate_url = 'https://amzn.to/48jljFR'  where slug = 'vivo-hoehenverstellbares-stehpult';
update products set affiliate_url = 'https://amzn.to/3QriCfn'  where slug = '6-teiliges-schubladen-ordnungssystem';
update products set affiliate_url = 'https://amzn.to/4cNdmu4'  where slug = 'tecknet-ergonomische-kabellose-maus-bluetooth';
update products set affiliate_url = 'https://amzn.to/4vH5dzM'  where slug = 'magnetisches-whiteboard-kontaktpapier-selbstklebend';
update products set affiliate_url = 'https://amzn.to/4mQqqTX'  where slug = 'ticktime-tk3-wuerfel-timer-countdown';
update products set affiliate_url = 'https://amzn.to/4cyjYh0'  where slug = 'riesige-aufblasbare-ente-pool';
update products set affiliate_url = 'https://amzn.to/4d6tUhK'  where slug = 'eiswuerfelform-todesstern-star-wars';
update products set affiliate_url = 'https://amzn.to/4cR5jfD'  where slug = 'personalisierter-foto-kalender';
update products set affiliate_url = 'https://amzn.to/4tJoHSQ'  where slug = 'kiayoo-wackelfigur-armaturenbrett-auto';
update products set affiliate_url = 'https://amzn.to/48mqRPZ'  where slug = 'ckb-retro-kaugummi-maschine-suessigkeitenspender';
update products set affiliate_url = 'https://amzn.to/4mPPUAX'  where slug = 'pizza-socks-box-pepperoni';
update products set affiliate_url = 'https://amzn.to/3P1Zh3S'  where slug = 'flauschige-handschuhe-weihnachten';
update products set affiliate_url = 'https://amzn.to/3QHfprZ'  where slug = 'einhorn-jahresvorrat-kondome';
update products set affiliate_url = 'https://amzn.to/4mU8wzJ'  where slug = 'lichtschwert-metallgriff-erwachsene';
update products set affiliate_url = 'https://amzn.to/48oo3St'  where slug = 'mangoschneider-fruchthalter';

-- ============================================================
-- Beschreibungen zurücksetzen (wurden fälschlich angepasst)
-- ============================================================

update products set description = 'Der Kytok Controller-Ständer bietet 4 Etagen für Gamepads aller gängigen Systeme — PlayStation, Xbox, Nintendo Switch, PC. Stabile Konstruktion aus ABS-Kunststoff, rutschfeste Füße, keine Montage nötig. Für jeden Gaming-Setup, bei dem Controller auf dem Schreibtisch herumliegen und nie da sind, wo man sie braucht.' where slug = 'kytok-controller-staender-4-etagen';

update products set description = 'Die JDVOOTD LED-Laufschrifttafel wird per App programmiert und zeigt Text, Emojis und Animationen in leuchtenden LED-Farben. Per Bluetooth mit dem Smartphone verbunden, lässt sich der Inhalt jederzeit ändern. Als Schaufensterwerbung, Büro-Gimmick, Partydekoration oder einfach zum Anzeigen was gerade wichtig ist — ohne Papier, ohne Drucken.' where slug = 'jdvootd-programmierbare-led-laufschrift-tafel';

update products set description = 'Der FIYAPOO Smartphone-Ständer ist höhenverstellbar, in der Neigung anpassbar und hält Handys aller Größen sicher. Die rutschfeste Silikonauflage verhindert Kratzer, der Klappmechanismus ist stabil genug für tägliches Auf- und Abbauen. Für Video-Calls, Rezepte in der Küche oder alle, die ihr Handy beim Arbeiten im Blick behalten wollen.' where slug = 'fiyapoo-ergonomischer-smartphone-staender';

update products set description = 'Der NewL Holographic Windbreaker reflektiert Licht in Regenbogenfarben und ist dabei leicht, wind- und wasserabweisend. Die Jacke wiegt unter 300 Gramm und lässt sich in die eigene Tasche packen. Für Festival, Fahrrad, Stadt oder alle, die auffallen wollen ohne zu frieren.' where slug = 'newl-reflektierende-holographic-windbreaker';

update products set description = 'Der Fenree Business-Rucksack ist aus wasserdichtem Material gefertigt und hat ein gepolstertes Laptopfach für bis zu 15,6 Zoll, einen USB-A-Ladeausgang und mehr Innenfächer als man auf den ersten Blick vermutet. Für Pendler, Reisende und alle, die alles dabei haben wollen und trotzdem ordentlich aussehen möchten.' where slug = 'fenree-business-rucksack-wasserdicht-usb';

update products set description = 'Das Yoga Design Lab Trainingsrad ist breiter als herkömmliche Yoga-Räder und hat eine rutschfeste Oberfläche aus TPE-Schaum. Es dehnt die Wirbelsäule, öffnet den Brustkorb und stärkt die Rückenmuskulatur — in der richtigen Reihenfolge angewendet. Mit Anleitung für Einsteiger, für Fortgeschrittene selbsterklärend.' where slug = 'yoga-design-lab-trainingsrad';

update products set description = 'Die LifePro Infrarot-Saunadecke erhitzt sich auf bis zu 75 Grad und erzeugt Infrarotwärme, die tiefer in die Muskulatur eindringt als normale Wärme. Laut Hersteller verbrennt eine 45-minütige Session bis zu 600 Kalorien — ähnlich wie ein moderates Ausdauertraining. Für alle, die eine Sauna wollen ohne den Platzbedarf und den Handwerker.' where slug = 'lifepro-infrarot-saunadecke';

update products set description = 'Der Ubergames Riesenwackelturm startet mit einer Turmhöhe von über 50 cm und wird im Spielverlauf deutlich höher — bis er fällt. 54 Holzklötze, inklusive Tragetasche, geeignet für drinnen und draußen. Für alle, die Jenga kennen und sich fragen warum sie immer das kleine gespielt haben.' where slug = 'ubergames-riesenwackelturm-jumbo-jenga';

update products set description = 'Das Shuffleboard-Tischset bringt das Prinzip des Eisstock-Schießens auf den Küchen- oder Esstisch — Scheiben werfen, Punkte zählen, gewinnen. Kompaktes Set aus Holz und Kunststoff, inklusive Spielscheiben und Anleitung. Für Spieleabende ohne Strom, App oder Mindestanzahl an Regelkenntnissen.' where slug = 'shuffleboard-tischset-curling-familienspiel';

update products set description = 'Die DERAYEE Schaumstoff-Wasserpistole saugt Wasser auf wie ein Schwamm und gibt es beim Drücken kontrolliert ab — keine scharfe Wasserstrahl-Optik, sondern ein sanftes Spritzen. Weich genug für Kinder, nass genug für ernsthafte Wasserschlachten. Keine Batterie, kein Laden, kein Befüllbehälter — nur nass machen.' where slug = 'derayee-schaumstoff-wasserpistole';

update products set description = 'Der COSTWAY Tischkicker hat stabile Stangen mit Schaumstoffgriffen, kugelgelagerte Spieler und eine rutschfeste Unterseite. Für Tischaufstellung in Spielzimmer oder Keller konzipiert — kein freistehender Profi-Kicker aber deutlich besser als die meisten Versionen unter 100 Euro. Für Spieleabende, WG-Gemeinschaftsräume und alle, die endlich wieder Kicker spielen wollen.' where slug = 'costway-tischkicker-kickertisch';

update products set description = 'Der Mejasg LCD-Würfel zeigt das Würfelergebnis auf einem beleuchteten Display an — kein Suchen unter dem Tisch, kein "ich hab eine 6 geworfen" wenn alle eine 2 gesehen haben. Per Knopf würfeln, Ergebnis ablesen, weiterspielen. Mit Sound-Option für dramatische Würfelmomente.' where slug = 'mejasg-elektronischer-lcd-wuerfel';

update products set description = 'Der lasergeätzte Würfelturm aus Holz verhindert, dass Würfel beim Rollen vom Tisch fallen oder andere Spieler treffen. Innen abgestufte Ebenen sorgen für echte Zufälligkeit. Als Brettspiel-Zubehör für Catan, Risiko und Co. oder einfach als Geschenk für alle, die regelmäßig Spieleabende veranstalten.' where slug = 'wuerfelturm-lasergeaetzt-brettspiel';

update products set description = 'Die CKB Retro Kaugummi-Maschine ist eine originalgetreue Nachbildung klassischer Kaugummiautomaten der 70er Jahre — befüllbar mit Kaugummis, Schokolinsen oder anderen kleinen Süßigkeiten. Metallgehäuse, echter Münzmechanismus, Drehmechanik funktioniert einwandfrei. Als Deko, Süßigkeitenspender oder Büroattraktion.' where slug = 'ckb-retro-kaugummi-maschine-suessigkeitenspender';

update products set description = 'Der Edelstahl-Mangoschneider trennt die Mangofrucht in einem einzigen Schritt vom Kern — einfach mittig aufsetzen, durchdrücken, fertig. Keine klebrigen Hände, kein Messer-Jonglieren, kein Mango-Chaos. Spülmaschinenfest und das Ende von Mangos die man nicht anrührt weil das Schneiden zu umständlich ist.' where slug = 'mangoschneider-fruchthalter';
