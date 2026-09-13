-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit approval before production execution.
-- Adds 20 products for /guide/dinge-die-beim-einzug-fehlen. Idempotent by slug.
-- Preflight aborts if any of the 20 ASINs already exists under a slug
-- other than the ones this script intends to write, AND aborts if any of
-- the 20 target slugs already exists but belongs to a different ASIN
-- (no silent overwrite of unrelated existing product data in either direction).

BEGIN;

DO $$
DECLARE conflict_count integer;
BEGIN
  SELECT count(*) INTO conflict_count FROM public.products
  WHERE affiliate_url ~ '/(B00O7RRK5K|B0001P0TNM|B0CFVVN65B|B0BQYW8LZ4|B0B28Y3DZJ|B00GC3OSPC|B0DNMRNRF2|B000GA3KCE|B0001IWVD0|B00D19MSIO|B001QFEVBC|B00CFY26S8|B0CWWL396Z|B07WKG364H|B07TV364MZ|B000YBXU6Q|B07Z6RGXV8|B01J43ILNG|B08ZSGJ3H7|B00022749Q)([/?]|$)'
    AND slug NOT IN (
      'merriway-gummi-tuerkeil',
      'stabila-torpedo-wasserwaage-70t-25cm',
      'bosch-leitungssuchgeraet-truvo',
      'bosch-akkuschrauber-ixo-7',
      'x-protector-filzgleiter-235-set',
      'wenko-abfluss-sieb-edelstahl-2er',
      'temppro-kuehlschrankthermometer-digital',
      'vacu-vin-weinpumpe-2-stopfen',
      'kitchencraft-backofenthermometer',
      'westmark-spritzschutz-picante-30cm',
      'rothenberger-ropump-saug-druckreiniger',
      'connex-rohr-reinigungsspirale-9mm-5m',
      'petex-betriebsverbandkasten-din13157',
      'guetewerk-duschabzieher-silikon-23cm',
      'temppro-thermo-hygrometer',
      'brennenstuhl-super-solid-steckdosenleiste-5fach',
      'brennenstuhl-verlaengerungskabel-flachstecker-3m',
      'brennenstuhl-led-nachtlicht-bewegungsmelder',
      'varta-stirnlampe-outdoor-sports-h20-pro',
      'shoulder-dolly-tragegurt-2-personen'
    );
  IF conflict_count > 0 THEN
    RAISE EXCEPTION 'Preflight failed: % ASIN(s) already exist under a different slug', conflict_count;
  END IF;
END $$;

DO $$
DECLARE conflict_count integer;
BEGIN
  SELECT count(*) INTO conflict_count
  FROM public.products p
  JOIN (VALUES
    ('merriway-gummi-tuerkeil','B00O7RRK5K'),
    ('stabila-torpedo-wasserwaage-70t-25cm','B0001P0TNM'),
    ('bosch-leitungssuchgeraet-truvo','B0CFVVN65B'),
    ('bosch-akkuschrauber-ixo-7','B0BQYW8LZ4'),
    ('x-protector-filzgleiter-235-set','B0B28Y3DZJ'),
    ('wenko-abfluss-sieb-edelstahl-2er','B00GC3OSPC'),
    ('temppro-kuehlschrankthermometer-digital','B0DNMRNRF2'),
    ('vacu-vin-weinpumpe-2-stopfen','B000GA3KCE'),
    ('kitchencraft-backofenthermometer','B0001IWVD0'),
    ('westmark-spritzschutz-picante-30cm','B00D19MSIO'),
    ('rothenberger-ropump-saug-druckreiniger','B001QFEVBC'),
    ('connex-rohr-reinigungsspirale-9mm-5m','B00CFY26S8'),
    ('petex-betriebsverbandkasten-din13157','B0CWWL396Z'),
    ('guetewerk-duschabzieher-silikon-23cm','B07WKG364H'),
    ('temppro-thermo-hygrometer','B07TV364MZ'),
    ('brennenstuhl-super-solid-steckdosenleiste-5fach','B000YBXU6Q'),
    ('brennenstuhl-verlaengerungskabel-flachstecker-3m','B07Z6RGXV8'),
    ('brennenstuhl-led-nachtlicht-bewegungsmelder','B01J43ILNG'),
    ('varta-stirnlampe-outdoor-sports-h20-pro','B08ZSGJ3H7'),
    ('shoulder-dolly-tragegurt-2-personen','B00022749Q')
  ) AS expected(slug, asin) ON p.slug = expected.slug
  WHERE p.affiliate_url !~ ('/' || expected.asin || '([/?]|$)');
  IF conflict_count > 0 THEN
    RAISE EXCEPTION 'Preflight failed: % target slug(s) already exist under a different ASIN', conflict_count;
  END IF;
END $$;

INSERT INTO public.products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, key_fact, pros, cons
)
VALUES
('merriway-gummi-tuerkeil','Merriway Gummi-Türkeil','Hält die Tür. Fragt nicht nach Danke.','Türstopper aus Gummi zum Fixieren von Türen in offener Position. Rutschfest durch die Materialwahl, für verschiedene Türspalt-Breiten geeignet.',357,'EUR','https://www.amazon.de/dp/B00O7RRK5K?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/51Ubw-my7YL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/51Ubw-my7YL._AC_SL1500_.jpg'],true,false,'babo','tools','werkzeug','Baumarkt','Merriway',ARRAY['babo:tools','einzug','tuerkeil'],NULL,'Türkeil aus Gummi, ohne Bohren oder Montage nutzbar.',ARRAY['Sofort einsatzbereit','Kein Werkzeug nötig','Rutschfeste Unterseite'],ARRAY['Wandert bei sehr glatten Böden trotzdem manchmal']),
('stabila-torpedo-wasserwaage-70t-25cm','STABILA Torpedo-Wasserwaage Type 70 T, 25 cm','Klein genug für die Schublade, ehrlich genug für die Wand.','Kompakte Wasserwaage von STABILA mit 25 cm Länge für Ausrichtungsarbeiten in Wohnung und Werkstatt. Passt in Werkzeugkiste oder Schublade.',1143,'EUR','https://www.amazon.de/dp/B0001P0TNM?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/511wAp887VL._AC_SL1000_.jpg',ARRAY['https://m.media-amazon.com/images/I/511wAp887VL._AC_SL1000_.jpg'],true,false,'babo','tools','werkzeug','Baumarkt','STABILA',ARRAY['babo:tools','einzug','wasserwaage'],NULL,'Wasserwaage, 25 cm, Marke STABILA.',ARRAY['Handliches Format','Markenqualität','Für schnelle Checks zwischendurch'],ARRAY['Für lange Regale braucht es zusätzlich eine größere Wasserwaage']),
('bosch-leitungssuchgeraet-truvo','Bosch Leitungssuchgerät Truvo (2. Generation)','Bevor der Dübel in die Leitung fährt, lieber kurz nachsehen.','Ortungsgerät von Bosch, das laut Herstellerangaben stromführende Leitungen und Metall in der Wand erkennt. Ersetzt keine Garantie auf lückenlose Erkennung.',4139,'EUR','https://www.amazon.de/dp/B0CFVVN65B?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/71H6VRbyCHL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/71H6VRbyCHL._AC_SL1500_.jpg'],true,false,'babo','tools','werkzeug','Baumarkt','Bosch',ARRAY['babo:tools','einzug','leitungssucher'],NULL,'Erkennt laut Listing stromführende Leitungen und Metall in Wänden.',ARRAY['Kompakt und einfach zu bedienen','Bosch-Markengerät','Sinnvoll vor jedem Bohrloch'],ARRAY['Keine Garantie, jede Leitung sicher zu finden']),
('bosch-akkuschrauber-ixo-7','Bosch Akkuschrauber IXO 7','Für das Regal, das heute noch an die Wand soll.','Kompakter Akkuschrauber aus der Bosch-IXO-Serie, 7. Generation, für kleinere Schraubarbeiten im Haushalt.',4853,'EUR','https://www.amazon.de/dp/B0BQYW8LZ4?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/71+W+xIdpjL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/71+W+xIdpjL._AC_SL1500_.jpg'],true,false,'babo','tools','werkzeug','Baumarkt','Bosch',ARRAY['babo:tools','einzug','akkuschrauber'],NULL,'Akkuschrauber, Bosch IXO, 7. Generation.',ARRAY['Handlich und leicht','Für schnelle Handgriffe im Haushalt gedacht','Markengerät von Bosch'],ARRAY['Kein Werkzeug für schwere Bauarbeiten']),
('x-protector-filzgleiter-235-set','X-PROTECTOR Filzgleiter, 235 Stück','Der Boden merkt sich jeden Stuhl, der ohne die kommt.','Set aus 235 Filzgleitern zum Anbringen unter Möbelfüßen, schützt Boden vor Kratzern beim Verschieben.',1399,'EUR','https://www.amazon.de/dp/B0B28Y3DZJ?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81odsDQvAxL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81odsDQvAxL._AC_SL1500_.jpg'],true,false,'queen','haushalt','wohnen','Baumarkt','X-PROTECTOR',ARRAY['queen:haushalt','einzug','filzgleiter'],NULL,'235 Filzgleiter im Set.',ARRAY['Große Menge für die ganze Wohnung','Passend für viele Möbelstücktypen','Einfach aufzukleben'],ARRAY['Auf sehr rauen Böden geringere Klebedauer']),
('wenko-abfluss-sieb-edelstahl-2er','WENKO Abfluss-Sieb Edelstahl, 2er-Set','Zwischen dir und der verstopften Leitung steht ab jetzt ein Sieb.','Zweier-Set aus Edelstahl-Sieben zum Einsetzen in den Abfluss, fängt Haare und Essensreste vor dem Rohr ab.',365,'EUR','https://www.amazon.de/dp/B00GC3OSPC?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61DrUHYA3uL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61DrUHYA3uL._AC_SL1500_.jpg'],true,false,'queen','kueche','kueche-helfer','Küche & Haushalt','WENKO',ARRAY['queen:kueche','einzug','abfluss-sieb'],NULL,'Edelstahl-Abflusssieb, 2er-Set.',ARRAY['Zwei Stück für Küche und Bad','Edelstahl statt Plastik','Einfach herausnehmbar zum Reinigen'],ARRAY['Muss regelmäßig geleert werden']),
('temppro-kuehlschrankthermometer-digital','TempPro digitales Kühlschrankthermometer','Weißt du wirklich, wie kalt dein Kühlschrank ist.','Digitales Thermometer zur Anzeige der Innentemperatur im Kühlschrank.',999,'EUR','https://www.amazon.de/dp/B0DNMRNRF2?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61hXppU+MwL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61hXppU+MwL._AC_SL1500_.jpg'],true,false,'queen','kueche','kueche-helfer','Küche & Haushalt','TempPro',ARRAY['queen:kueche','einzug','kuehlschrankthermometer'],NULL,'Digitales Kühlschrankthermometer.',ARRAY['Einfache digitale Anzeige','Für Kühlschrank oder Gefrierfach nutzbar','Schnell platziert'],ARRAY['Batteriewechsel nach Herstellerangaben beachten']),
('vacu-vin-weinpumpe-2-stopfen','Vacu Vin Weinpumpe mit 2 Stopfen','Die halbe Flasche muss nicht heute Abend weg.','Vakuumpumpe mit zwei Stopfen, die angebrochene Weinflaschen luftdicht verschließt und so länger frisch hält.',1084,'EUR','https://www.amazon.de/dp/B000GA3KCE?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/51RYH+PR9lL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/51RYH+PR9lL._AC_SL1500_.jpg'],true,false,'queen','kueche','kueche-helfer','Küche & Haushalt','Vacu Vin',ARRAY['queen:kueche','einzug','weinpumpe'],NULL,'Vakuum-Weinpumpe inklusive 2 Stopfen.',ARRAY['Zwei Stopfen für mehrere Flaschen','Kompakt in der Schublade verstaubar','Ohne Strom oder Batterien nutzbar'],ARRAY['Wirkung hängt von Weinsorte und Lagerdauer ab']),
('kitchencraft-backofenthermometer','KitchenCraft Backofenthermometer','Der Backofen lügt öfter, als du denkst.','Freistehendes oder hängendes Thermometer zur Kontrolle der tatsächlichen Backofentemperatur.',1338,'EUR','https://www.amazon.de/dp/B0001IWVD0?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/51gMkC6ou5L._AC_SL1080_.jpg',ARRAY['https://m.media-amazon.com/images/I/51gMkC6ou5L._AC_SL1080_.jpg'],true,false,'queen','kueche','kueche-helfer','Küche & Haushalt','KitchenCraft',ARRAY['queen:kueche','einzug','backofenthermometer'],NULL,'Backofenthermometer zum Aufstellen oder Aufhängen im Ofen.',ARRAY['Zeigt die reale Innentemperatur an','Flexibel platzierbar','Einfache mechanische Anzeige'],ARRAY['Herstellerangaben zum Messbereich sind uneinheitlich']),
('westmark-spritzschutz-picante-30cm','Westmark Spritzschutz Picante, 30 cm','Das Fett soll in der Pfanne bleiben, nicht auf dem Herd.','Spritzschutz-Sieb mit 30 cm Durchmesser, wird auf die Pfanne gelegt und fängt Fettspritzer beim Braten ab.',1499,'EUR','https://www.amazon.de/dp/B00D19MSIO?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/618SLKp6FCL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/618SLKp6FCL._AC_SL1500_.jpg'],true,false,'queen','kueche','kueche-helfer','Küche & Haushalt','Westmark',ARRAY['queen:kueche','einzug','spritzschutz'],NULL,'Spritzschutz-Sieb, 30 cm Durchmesser.',ARRAY['Reduziert Fettspritzer auf dem Herd','Passt auf gängige Pfannengrößen','Leicht zu reinigen'],ARRAY['Muss zur Pfannengröße passen, sonst schlechter Sitz']),
('rothenberger-ropump-saug-druckreiniger','ROTHENBERGER Industrial Saug-Druckreiniger RoPump','Für den Abfluss, der einfach nicht mehr will.','Handpumpe zum mechanischen Freimachen verstopfter Abflüsse mittels Saug- und Druckwirkung. Laut Hersteller nicht für Toiletten vorgesehen.',1490,'EUR','https://www.amazon.de/dp/B001QFEVBC?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/613Xdaw-DGL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/613Xdaw-DGL._AC_SL1500_.jpg'],true,false,'babo','tools','sanitaer','Baumarkt','ROTHENBERGER',ARRAY['babo:tools','einzug','abflussreiniger'],NULL,'Handpumpe für Abflüsse, laut Listing nicht für Toiletten geeignet.',ARRAY['Ohne Chemie einsetzbar','Für Waschbecken und Dusche gedacht','Mehrfach verwendbar'],ARRAY['Laut Herstellerangabe nicht für Toiletten geeignet']),
('connex-rohr-reinigungsspirale-9mm-5m','CONNEX Rohr-Reinigungsspirale, 9 mm x 5 m','5 Meter Spirale gegen das, was die Pumpe nicht schafft.','Mechanische Reinigungsspirale mit 9 mm Durchmesser und 5 m Länge zum Lösen hartnäckiger Verstopfungen in Rohren.',1818,'EUR','https://www.amazon.de/dp/B00CFY26S8?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/91aVD1Zj0TL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/91aVD1Zj0TL._AC_SL1500_.jpg'],true,false,'babo','tools','sanitaer','Baumarkt','CONNEX',ARRAY['babo:tools','einzug','reinigungsspirale'],NULL,'Reinigungsspirale, 9 mm x 5 m.',ARRAY['Reicht auch für längere Leitungsabschnitte','Mechanisch ohne Chemie','Wiederverwendbar'],ARRAY['Handhabung erfordert etwas Kraft und Übung']),
('petex-betriebsverbandkasten-din13157','PETEX Betriebsverbandkasten DIN 13157','Hoffentlich brauchst du ihn nie. Aber dann sofort.','Erste-Hilfe-Kasten nach DIN 13157 mit genormtem Inhalt für den Grundbedarf im Haushalt.',1149,'EUR','https://www.amazon.de/dp/B0CWWL396Z?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81yP1oaXxBL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81yP1oaXxBL._AC_SL1500_.jpg'],true,false,'babo','haushalt','erste-hilfe','Drogerie & Körperpflege','PETEX',ARRAY['babo:haushalt','einzug','verbandskasten'],NULL,'Verbandkasten nach DIN 13157.',ARRAY['Genormter Inhalt nach DIN 13157','Kompakte Aufbewahrung','Für den Grundbedarf im Haushalt gedacht'],ARRAY['Verfallsdaten des Inhalts müssen regelmäßig selbst geprüft werden']),
('guetewerk-duschabzieher-silikon-23cm','GÜTEWERK Duschabzieher Silikon, 23 cm, mit Halterung','Zwei Minuten Abziehen sparen dir das Wochenende mit dem Fugenreiniger.','Duschabzieher mit 23 cm breiter Silikonlippe inklusive Wandhalterung zur Aufbewahrung.',1799,'EUR','https://www.amazon.de/dp/B07WKG364H?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61xQWg1kJEL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61xQWg1kJEL._AC_SL1500_.jpg'],true,false,'queen','haushalt','bad','Küche & Haushalt','GÜTEWERK',ARRAY['queen:haushalt','einzug','duschabzieher'],NULL,'Duschabzieher, Silikon, 23 cm, mit Wandhalterung.',ARRAY['Silikonlippe statt Gummi','Halterung für griffbereite Aufbewahrung','Breite Klinge für zügiges Abziehen'],ARRAY['Ersetzt keine regelmäßige Fugenreinigung']),
('temppro-thermo-hygrometer','TempPro Thermo-Hygrometer','Die Luft in der neuen Wohnung, endlich in Zahlen.','Gerät zur Anzeige von Raumtemperatur und Luftfeuchtigkeit.',899,'EUR','https://www.amazon.de/dp/B07TV364MZ?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61szvRpcT+L._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61szvRpcT+L._AC_SL1500_.jpg'],true,false,'queen','haushalt','klima','Baumarkt','TempPro',ARRAY['queen:haushalt','einzug','thermo-hygrometer'],NULL,'Thermo-Hygrometer misst Temperatur und Luftfeuchtigkeit.',ARRAY['Zeigt Temperatur und Luftfeuchtigkeit gleichzeitig','Kompakte Bauform','Für jeden Raum nutzbar'],ARRAY['Zeigt nur Messwerte an, keine Bewertung oder Warnung']),
('brennenstuhl-super-solid-steckdosenleiste-5fach','Brennenstuhl Super-Solid Steckdosenleiste, 5-fach','Fünf Stecker, ein Kabel, ein Problem weniger.','5-fach-Steckdosenleiste mit Überspannungsschutz gegen Spannungsspitzen im Stromnetz.',1899,'EUR','https://www.amazon.de/dp/B000YBXU6Q?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61b9HE7mYoL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61b9HE7mYoL._AC_SL1500_.jpg'],true,false,'babo','haushalt','strom','Elektronik','Brennenstuhl',ARRAY['babo:haushalt','einzug','steckdosenleiste'],NULL,'5-fach-Steckdosenleiste mit Überspannungsschutz.',ARRAY['Fünf Anschlüsse an einer Leiste','Überspannungsschutz gegen Spannungsspitzen','Robuste Bauweise'],ARRAY['Kein Ersatz für Blitzschutz']),
('brennenstuhl-verlaengerungskabel-flachstecker-3m','Brennenstuhl Verlängerungskabel mit Flachstecker, 3 m','Die Steckdose ist immer da, wo das Kabel nicht hinreicht.','Verlängerungskabel mit Flachstecker und 3 m Länge, geeignet für den Einsatz hinter Möbeln oder Türen.',783,'EUR','https://www.amazon.de/dp/B07Z6RGXV8?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/41JTUNofxZL._AC_SL1000_.jpg',ARRAY['https://m.media-amazon.com/images/I/41JTUNofxZL._AC_SL1000_.jpg'],true,false,'babo','haushalt','strom','Elektronik','Brennenstuhl',ARRAY['babo:haushalt','einzug','verlaengerungskabel'],NULL,'Verlängerungskabel mit Flachstecker, 3 m.',ARRAY['Flachstecker für enge Stellen hinter Möbeln','3 m Länge überbrückt größere Distanzen','Einfache Handhabung'],ARRAY['Nur eine Steckdose am Ende, keine Mehrfachleiste']),
('brennenstuhl-led-nachtlicht-bewegungsmelder','Brennenstuhl LED-Nachtlicht mit Bewegungsmelder','Der Flur um drei Uhr nachts, ohne gegen den Schrank zu laufen.','LED-Nachtlicht mit Bewegungssensor, batteriebetrieben mit 3 AA-Batterien und unabhängig von einer Steckdose. Für Flur, Schrank oder kleinen Kellerbereich gedacht, keine Raumbeleuchtung.',1829,'EUR','https://www.amazon.de/dp/B01J43ILNG?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61fx1T84ADL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/61fx1T84ADL._AC_SL1500_.jpg'],true,false,'queen','haushalt','strom','Elektronik','Brennenstuhl',ARRAY['queen:haushalt','einzug','nachtlicht'],NULL,'LED-Nachtlicht mit Bewegungssensor, batteriebetrieben mit 3 AA-Batterien.',ARRAY['Automatisches Einschalten bei Bewegung','Kein Tasten im Dunkeln mehr nötig','Batteriebetrieben, unabhängig von einer Steckdose'],ARRAY['Nur Orientierungslicht, ersetzt keine Raumbeleuchtung']),
('varta-stirnlampe-outdoor-sports-h20-pro','VARTA Stirnlampe Outdoor Sports H20 Pro','Beide Hände frei, für den Umzugskarton, der um die Ecke muss.','Stirnlampe aus der VARTA-Reihe Outdoor Sports H20 Pro für freihändiges Arbeiten bei schlechter Beleuchtung.',995,'EUR','https://www.amazon.de/dp/B08ZSGJ3H7?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/71WymO-IsEL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/71WymO-IsEL._AC_SL1500_.jpg'],true,false,'babo','tools','outdoor','Sport & Freizeit','VARTA',ARRAY['babo:tools','einzug','stirnlampe'],NULL,'Stirnlampe, VARTA Outdoor Sports H20 Pro.',ARRAY['Freihändige Nutzung möglich','Markenprodukt von VARTA','Für den Einsatz im Dunkeln gedacht'],ARRAY['Details zu Leuchtstärke laut Listing nicht einheitlich angegeben']),
('shoulder-dolly-tragegurt-2-personen','SHOULDER DOLLY Tragegurt für zwei Personen','Der Kühlschrank kommt die Treppe hoch. Zu zweit.','Trage- und Hebegurt-System zum gemeinsamen Tragen schwerer Möbelstücke, ausgelegt für zwei Personen.',6199,'EUR','https://www.amazon.de/dp/B00022749Q?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81LruVGbg+L._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81LruVGbg+L._AC_SL1500_.jpg'],true,false,'babo','tools','umzug','Baumarkt','SHOULDER DOLLY',ARRAY['babo:tools','einzug','tragegurt'],NULL,'Tragegurt-System für zwei Personen, nicht für den Einsatz allein konzipiert.',ARRAY['Verteilt das Gewicht auf zwei Trägerpersonen','Für sperrige Möbelstücke gedacht','Wiederverwendbar für weitere Umzüge'],ARRAY['Funktioniert nur zu zweit, nicht allein einsetzbar'])
ON CONFLICT (slug) DO UPDATE SET
  name=EXCLUDED.name, tagline=EXCLUDED.tagline, description=EXCLUDED.description,
  price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency,
  affiliate_url=EXCLUDED.affiliate_url,
  image_url=COALESCE(EXCLUDED.image_url, public.products.image_url),
  image_urls=COALESCE(EXCLUDED.image_urls, public.products.image_urls),
  is_published=EXCLUDED.is_published,
  shop_persona=EXCLUDED.shop_persona, shop_main_category=EXCLUDED.shop_main_category,
  shop_sub_category=EXCLUDED.shop_sub_category, amazon_category=EXCLUDED.amazon_category,
  brand=EXCLUDED.brand, shop_tags=EXCLUDED.shop_tags,
  editorial_note=EXCLUDED.editorial_note, key_fact=EXCLUDED.key_fact,
  pros=EXCLUDED.pros, cons=EXCLUDED.cons;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.products
  WHERE affiliate_url ~ '/(B00O7RRK5K|B0001P0TNM|B0CFVVN65B|B0BQYW8LZ4|B0B28Y3DZJ|B00GC3OSPC|B0DNMRNRF2|B000GA3KCE|B0001IWVD0|B00D19MSIO|B001QFEVBC|B00CFY26S8|B0CWWL396Z|B07WKG364H|B07TV364MZ|B000YBXU6Q|B07Z6RGXV8|B01J43ILNG|B08ZSGJ3H7|B00022749Q)([/?]|$)'
    AND is_published=true;
  IF n <> 20 THEN RAISE EXCEPTION 'Postflight failed: expected 20 published ASINs, found %', n; END IF;
END $$;

COMMIT;

SELECT slug,name,price_cents,affiliate_url,image_url,is_published
FROM public.products
WHERE slug IN (
  'merriway-gummi-tuerkeil',
  'stabila-torpedo-wasserwaage-70t-25cm',
  'bosch-leitungssuchgeraet-truvo',
  'bosch-akkuschrauber-ixo-7',
  'x-protector-filzgleiter-235-set',
  'wenko-abfluss-sieb-edelstahl-2er',
  'temppro-kuehlschrankthermometer-digital',
  'vacu-vin-weinpumpe-2-stopfen',
  'kitchencraft-backofenthermometer',
  'westmark-spritzschutz-picante-30cm',
  'rothenberger-ropump-saug-druckreiniger',
  'connex-rohr-reinigungsspirale-9mm-5m',
  'petex-betriebsverbandkasten-din13157',
  'guetewerk-duschabzieher-silikon-23cm',
  'temppro-thermo-hygrometer',
  'brennenstuhl-super-solid-steckdosenleiste-5fach',
  'brennenstuhl-verlaengerungskabel-flachstecker-3m',
  'brennenstuhl-led-nachtlicht-bewegungsmelder',
  'varta-stirnlampe-outdoor-sports-h20-pro',
  'shoulder-dolly-tragegurt-2-personen'
)
ORDER BY slug;
