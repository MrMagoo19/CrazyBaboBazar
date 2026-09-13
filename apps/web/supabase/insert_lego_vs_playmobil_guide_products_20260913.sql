-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit approval before production execution.
-- Adds 20 products for /guide/lego-vs-playmobil. Idempotent by slug.
-- Preflight aborts if any of the 20 ASINs already exists under a slug
-- other than the ones this script intends to write (no silent overwrite
-- of unrelated existing product data).
--
-- Data basis (no live Amazon research available in this run):
-- - ASINs and pairing as supplied by the user (binding).
-- - price_cents = manufacturer UVP as supplied by the user.
-- - LEGO 42221 UVP 59,99 EUR, verified on the official LEGO DE product page.
-- - Set names are thematic labels (set number + duel theme), not verified
--   official set titles. Only LEGO Technic 42221 NASA Artemis SLS and
--   LEGO Star Wars 75419 Todesstern are named as supplied.
-- - Verified manufacturer or Amazon image URLs are attached after the upsert.
-- - No piece counts, age ratings, sellers, stock or reviews are claimed.

BEGIN;

DO $$
DECLARE conflict_count integer;
BEGIN
  SELECT count(*) INTO conflict_count FROM public.products
  WHERE affiliate_url ~ '/(B0DWDT5BQ9|B0G7LNS8DX|B0F6YR2NN4|B0DQVMNQ4P|B0DWF9F6TN|B081HQ5S8H|B0CHD88C1B|B07P581CK8|B0FR9JYZBR|B0DQVMTRKS|B0DHSCYDL2|B09QV55L2V|B0GGSBK9FM|B0BT8BHPCQ|B0FPXGBPR6|B0CK2KK34J|B0FPXDRV4H|B0G671HMMC|B0FPXFMGVT|B09R6SYRK8)([/?]|$)'
    AND slug NOT IN (
      'lego-31168-ritterburg',
      'playmobil-72113-ritterburg',
      'lego-76976-dinosaurier',
      'playmobil-71819-dinosaurier',
      'lego-technic-42215-baustelle',
      'playmobil-70441-baustelle',
      'lego-10788-puppenhaus',
      'playmobil-70205-puppenhaus',
      'lego-43297-maerchenschloss',
      'playmobil-71845-maerchenschloss',
      'lego-technic-42207-supersportwagen',
      'playmobil-71020-supersportwagen',
      'lego-technic-42239-kultauto',
      'playmobil-71343-kultauto',
      'lego-31387-piraten',
      'playmobil-71530-piraten',
      'lego-technic-42221-nasa-artemis-sls',
      'playmobil-72011-raumfahrt',
      'lego-star-wars-75419-todesstern',
      'playmobil-70890'
    );
  IF conflict_count > 0 THEN
    RAISE EXCEPTION 'Preflight failed: % ASIN(s) already exist under a different slug', conflict_count;
  END IF;
END $$;

INSERT INTO public.products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, key_fact, pros, cons
)
VALUES
-- Runde 1: Ritterburg (Sieger: Playmobil)
('lego-31168-ritterburg','LEGO Set 31168 – Ritterburg','Erst bauen, dann belagern. Die Burg kommt nicht fertig.','LEGO-Set 31168 zum Thema Ritterburg, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 72113. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',11999,'EUR','https://www.amazon.de/dp/B0DWDT5BQ9?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','bauset','Spielzeug','LEGO',ARRAY['miniboss:spielzeug','lego','lego-vs-playmobil','ritterburg'],'Verliert Runde 1 gegen die günstigere Playmobil-Burg.','LEGO-Set 31168, Thema Ritterburg, UVP-Band 100 – 200 €.',ARRAY['Burg als Bauprojekt aus LEGO-Steinen'],ARRAY['höheres UVP-Band als das Playmobil-Gegenstück']),
('playmobil-72113-ritterburg','PLAYMOBIL Set 72113 – Ritterburg','Auspacken, Tor zu, Belagerung läuft.','Playmobil-Set 72113 zum Thema Ritterburg, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO 31168. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',8999,'EUR','https://www.amazon.de/dp/B0G7LNS8DX?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','ritterburg'],'Gewinnt Runde 1: Spielort statt Bauprojekt, nach UVP günstiger.','Playmobil-Set 72113, Thema Ritterburg, UVP-Band 50 – 100 €.',ARRAY['niedrigeres UVP-Band als das LEGO-Gegenstück','Burg als Spielort für Rollenspiel'],ARRAY['wer vor allem bauen will, ist bei LEGO richtiger']),
-- Runde 2: Dinosaurier (Sieger: Playmobil)
('lego-76976-dinosaurier','LEGO Set 76976 – Dinosaurier','Urzeit zum Selberbauen.','LEGO-Set 76976 zum Thema Dinosaurier, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 71819. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',14999,'EUR','https://www.amazon.de/dp/B0F6YR2NN4?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','bauset','Spielzeug','LEGO',ARRAY['miniboss:spielzeug','lego','lego-vs-playmobil','dinosaurier'],'Verliert Runde 2: nach UVP fast doppelt so teuer wie Playmobil.','LEGO-Set 76976, Thema Dinosaurier, UVP-Band 100 – 200 €.',ARRAY['Dino-Thema als Bauprojekt'],ARRAY['nach UVP fast doppelt so teuer wie das Playmobil-Gegenstück']),
('playmobil-71819-dinosaurier','PLAYMOBIL Set 71819 – Dinosaurier','Auspacken und direkt Urzeit spielen.','Playmobil-Set 71819 zum Thema Dinosaurier, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO 76976. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',7999,'EUR','https://www.amazon.de/dp/B0DQVMNQ4P?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','dinosaurier'],'Gewinnt Runde 2 über den deutlich niedrigeren Preis.','Playmobil-Set 71819, Thema Dinosaurier, UVP-Band 50 – 100 €.',ARRAY['gut die Hälfte der LEGO-UVP','Dino-Thema zum direkten Bespielen'],ARRAY['wer vor allem bauen will, ist bei LEGO richtiger']),
-- Runde 3: Baustelle (Sieger: Playmobil)
('lego-technic-42215-baustelle','LEGO Technic Set 42215 – Baustelle','Die Baustelle, auf der du selbst der Bautrupp bist.','LEGO-Technic-Set 42215 zum Thema Baustelle, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 70441. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',39999,'EUR','https://www.amazon.de/dp/B0DWF9F6TN?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'babo','spielzeug','bauset','Spielzeug','LEGO',ARRAY['babo:spielzeug','lego','lego-technic','lego-vs-playmobil','baustelle'],'Verliert Runde 3: mehr als die dreifache UVP des Playmobil-Sets.','LEGO-Technic-Set 42215, Thema Baustelle, UVP-Band über 200 €.',ARRAY['Technic-Linie für mechanisches Bauen'],ARRAY['nach UVP mehr als dreimal so teuer wie das Playmobil-Gegenstück']),
('playmobil-70441-baustelle','PLAYMOBIL Set 70441 – Baustelle','Bauarbeiten im Kinderzimmer. Ohne Lärmschutzverordnung.','Playmobil-Set 70441 zum Thema Baustelle, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO Technic 42215. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',12999,'EUR','https://www.amazon.de/dp/B081HQ5S8H?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','baustelle'],'Gewinnt Runde 3 für die meisten Kinderzimmer.','Playmobil-Set 70441, Thema Baustelle, UVP-Band 100 – 200 €.',ARRAY['deutlich niedrigere UVP als das Technic-Gegenstück','Baustelle zum Bespielen'],ARRAY['kein mechanisches Bauprojekt wie Technic']),
-- Runde 4: Puppenhaus (Sieger: LEGO)
('lego-10788-puppenhaus','LEGO Set 10788 – Puppenhaus','Das Puppenhaus, das zuerst gebaut werden will.','LEGO-Set 10788 zum Thema Puppenhaus, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 70205. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',7999,'EUR','https://www.amazon.de/dp/B0CHD88C1B?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','bauset','Spielzeug','LEGO',ARRAY['miniboss:spielzeug','lego','lego-vs-playmobil','puppenhaus'],'Gewinnt Runde 4 über den Einstiegspreis.','LEGO-Set 10788, Thema Puppenhaus, UVP-Band 50 – 100 €.',ARRAY['weniger als die Hälfte der Playmobil-UVP'],ARRAY['Puppenhaus-Thema ist klassisch eher Rollenspiel-Terrain']),
('playmobil-70205-puppenhaus','PLAYMOBIL Set 70205 – Puppenhaus','Einziehen, einrichten, Alltagsdrama spielen.','Playmobil-Set 70205 zum Thema Puppenhaus, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO 10788. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',17999,'EUR','https://www.amazon.de/dp/B07P581CK8?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','puppenhaus'],'Verliert Runde 4: mehr als die doppelte UVP des LEGO-Sets.','Playmobil-Set 70205, Thema Puppenhaus, UVP-Band 100 – 200 €.',ARRAY['Puppenhaus als Bühne für Rollenspiel'],ARRAY['nach UVP mehr als doppelt so teuer wie das LEGO-Gegenstück']),
-- Runde 5: Märchenschloss (Sieger: LEGO)
('lego-43297-maerchenschloss','LEGO Set 43297 – Märchenschloss','Das Märchen beginnt mit der Bauanleitung.','LEGO-Set 43297 zum Thema Märchenschloss, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 71845. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',9999,'EUR','https://www.amazon.de/dp/B0FR9JYZBR?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','bauset','Spielzeug','LEGO',ARRAY['miniboss:spielzeug','lego','lego-vs-playmobil','maerchenschloss'],'Gewinnt Runde 5 knapp über die niedrigere UVP.','LEGO-Set 43297, Thema Märchenschloss, UVP-Band 50 – 100 €.',ARRAY['nach UVP 40 € günstiger als das Playmobil-Gegenstück'],ARRAY['erst Bauzeit, dann Märchen']),
('playmobil-71845-maerchenschloss','PLAYMOBIL Set 71845 – Märchenschloss','Schloss auf, Märchen an.','Playmobil-Set 71845 zum Thema Märchenschloss, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO 43297. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',13999,'EUR','https://www.amazon.de/dp/B0DQVMTRKS?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','maerchenschloss'],'Verliert Runde 5 knapp über den Preis.','Playmobil-Set 71845, Thema Märchenschloss, UVP-Band 100 – 200 €.',ARRAY['Schloss zum direkten Bespielen'],ARRAY['höheres UVP-Band als das LEGO-Gegenstück']),
-- Runde 6: Supersportwagen (Sieger: LEGO)
('lego-technic-42207-supersportwagen','LEGO Technic Set 42207 – Supersportwagen','Der Sportwagen, bei dem der Bau die Probefahrt ist.','LEGO-Technic-Set 42207 zum Thema Supersportwagen, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 71020. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',22999,'EUR','https://www.amazon.de/dp/B0DHSCYDL2?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'babo','spielzeug','bauset','Spielzeug','LEGO',ARRAY['babo:spielzeug','lego','lego-technic','lego-vs-playmobil','supersportwagen'],'Gewinnt Runde 6: Beim Sportwagen-Modell ist das Bauen der Reiz.','LEGO-Technic-Set 42207, Thema Supersportwagen, UVP-Band über 200 €.',ARRAY['Sportwagen als Technic-Bauprojekt'],ARRAY['nach UVP mehr als dreimal so teuer wie das Playmobil-Gegenstück']),
('playmobil-71020-supersportwagen','PLAYMOBIL Set 71020 – Supersportwagen','Sportwagen-Gefühl im Kinderzimmer-Format.','Playmobil-Set 71020 zum Thema Supersportwagen, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO Technic 42207. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',6999,'EUR','https://www.amazon.de/dp/B09QV55L2V?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','supersportwagen'],'Verliert Runde 6 trotz deutlich niedrigerer UVP.','Playmobil-Set 71020, Thema Supersportwagen, UVP-Band 50 – 100 €.',ARRAY['weniger als ein Drittel der Technic-UVP','Spielauto zum direkten Losfahren'],ARRAY['kein Bauprojekt wie das Technic-Gegenstück']),
-- Runde 7: Film-/Kultauto (Unentschieden)
('lego-technic-42239-kultauto','LEGO Technic Set 42239 – Film- und Kultauto','Kultauto fürs Regal. Erst bauen, dann bewundern.','LEGO-Technic-Set 42239 zum Thema Film- und Kultauto, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 71343. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Lizenz, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',18999,'EUR','https://www.amazon.de/dp/B0GGSBK9FM?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'babo','spielzeug','bauset','Spielzeug','LEGO',ARRAY['babo:spielzeug','lego','lego-technic','lego-vs-playmobil','kultauto'],'Runde 7 endet unentschieden: LEGO fürs Regal.','LEGO-Technic-Set 42239, Thema Film- und Kultauto, UVP-Band 100 – 200 €.',ARRAY['Kultauto als Technic-Bauprojekt'],ARRAY['nach UVP fast dreimal so teuer wie das Playmobil-Gegenstück']),
('playmobil-71343-kultauto','PLAYMOBIL Set 71343 – Film- und Kultauto','Kultauto zum Nachspielen statt Abstauben.','Playmobil-Set 71343 zum Thema Film- und Kultauto, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO Technic 42239. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Lizenz, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',6999,'EUR','https://www.amazon.de/dp/B0BT8BHPCQ?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','kultauto'],'Runde 7 endet unentschieden: Playmobil fürs Nachspielen.','Playmobil-Set 71343, Thema Film- und Kultauto, UVP-Band 50 – 100 €.',ARRAY['deutlich niedrigere UVP als das Technic-Gegenstück','Auto zum Nachspielen'],ARRAY['kein Bauprojekt wie das Technic-Gegenstück']),
-- Runde 8: Piraten (Sieger: Playmobil)
('lego-31387-piraten','LEGO Set 31387 – Piraten','Piratenabenteuer mit Bauphase vorab.','LEGO-Set 31387 zum Thema Piraten, im Guide „LEGO vs. Playmobil“ das Gegenstück zu Playmobil 71530. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',9999,'EUR','https://www.amazon.de/dp/B0FPXGBPR6?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','bauset','Spielzeug','LEGO',ARRAY['miniboss:spielzeug','lego','lego-vs-playmobil','piraten'],'Verliert Runde 8 bei gleicher UVP über die Spielidee.','LEGO-Set 31387, Thema Piraten, UVP-Band 50 – 100 €.',ARRAY['gleiche UVP wie das Playmobil-Gegenstück','Piratenthema als Bauprojekt'],ARRAY['Piratenthema ist klassisch eher Rollenspiel-Terrain']),
('playmobil-71530-piraten','PLAYMOBIL Set 71530 – Piraten','Piratengeschichten ab dem ersten Auspacken.','Playmobil-Set 71530 zum Thema Piraten, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO 31387. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',9999,'EUR','https://www.amazon.de/dp/B0CK2KK34J?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','piraten'],'Gewinnt Runde 8 bei gleicher UVP: Piraten wollen gespielt werden.','Playmobil-Set 71530, Thema Piraten, UVP-Band 50 – 100 €.',ARRAY['gleiche UVP wie das LEGO-Gegenstück','Piratenthema zum direkten Bespielen'],ARRAY['wer vor allem bauen will, ist bei LEGO richtiger']),
-- Runde 9: Raumfahrt (Sieger: LEGO)
('lego-technic-42221-nasa-artemis-sls','LEGO Technic 42221 NASA Artemis SLS-Schwerlastrakete','NASA-Rakete zum Selberbauen. Der Countdown beginnt beim ersten Stein.','LEGO-Technic-Set 42221 NASA Artemis SLS-Schwerlastrakete mit 632 Teilen, vier Astronauten-Nanofiguren und dreistufiger Trennfunktion. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen.',5999,'EUR','https://www.amazon.de/dp/B0FPXDRV4H?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'babo','spielzeug','bauset','Spielzeug','LEGO',ARRAY['babo:spielzeug','lego','lego-technic','lego-vs-playmobil','raumfahrt','nasa'],'Gewinnt Runde 9: echte NASA-Rakete als Bauprojekt.','LEGO-Technic-Set 42221 NASA Artemis SLS; UVP-Band 50 – 100 €.',ARRAY['632 Teile und vier Astronauten-Nanofiguren','dreistufige Trennfunktion','mit NASA und ESA entwickelt'],ARRAY['wer sofort spielen will, ist bei Playmobil schneller']),
('playmobil-72011-raumfahrt','PLAYMOBIL Set 72011 – Raumfahrt','Raumfahrt zum Losspielen. Ohne Countdown-Wartezeit.','Playmobil-Set 72011 zum Thema Raumfahrt, im Guide „LEGO vs. Playmobil“ das Gegenstück zu LEGO Technic 42221. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',5999,'EUR','https://www.amazon.de/dp/B0G671HMMC?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','raumfahrt'],'Verliert Runde 9, ist aber das günstigste Set des Guides.','Playmobil-Set 72011, Thema Raumfahrt, UVP-Band 50 – 100 €.',ARRAY['niedrigste UVP im gesamten Vergleich','Raumfahrt zum direkten Bespielen'],ARRAY['kein Bauprojekt wie das Technic-Gegenstück']),
-- Runde 10: Finale (Sieger: LEGO)
('lego-star-wars-75419-todesstern','LEGO Star Wars 75419 Todesstern','Der Todesstern als Bauprojekt. Planung ist die halbe Miete.','LEGO-Star-Wars-Set 75419 Todesstern, im Guide „LEGO vs. Playmobil“ das Finale gegen Playmobil 70890 und das teuerste Set des Vergleichs. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',99999,'EUR','https://www.amazon.de/dp/B0FPXFMGVT?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'babo','spielzeug','bauset','Spielzeug','LEGO',ARRAY['babo:spielzeug','lego','lego-star-wars','lego-vs-playmobil','todesstern'],'Gewinnt das Finale als Bauprojekt – bei fünffacher UVP.','LEGO-Star-Wars-Set 75419 Todesstern, UVP-Band über 200 €.',ARRAY['Star-Wars-Todesstern als Bauprojekt'],ARRAY['teuerstes Set des Vergleichs, nach UVP das Fünffache des Playmobil-Gegenstücks']),
('playmobil-70890','PLAYMOBIL Set 70890','Playmobils Spitzenset im Duell gegen den Todesstern.','Playmobil-Set 70890, im Guide „LEGO vs. Playmobil“ das Finale gegen LEGO Star Wars 75419 und das teuerste Playmobil-Set des Vergleichs. Der hinterlegte Preis entspricht der Hersteller-UVP; der aktuelle Amazon-Preis kann abweichen. Thema, Teilezahl, Altersempfehlung, Verkäufer und Lieferbarkeit bitte im Amazon-Listing prüfen.',19999,'EUR','https://www.amazon.de/dp/B09R6SYRK8?tag=geeklist-21&linkCode=ogi&th=1',NULL,NULL,true,false,'miniboss','spielzeug','spielset','Spielzeug','PLAYMOBIL',ARRAY['miniboss:spielzeug','playmobil','lego-vs-playmobil','finale'],'Verliert das ungleichste Duell des Guides.','Playmobil-Set 70890, UVP-Band 100 – 200 €.',ARRAY['ein Fünftel der UVP des LEGO-Gegenstücks'],ARRAY['kein echtes Gegenstück zum Todesstern-Bauprojekt'])
ON CONFLICT (slug) DO UPDATE SET
  name=EXCLUDED.name, tagline=EXCLUDED.tagline, description=EXCLUDED.description,
  price_cents=EXCLUDED.price_cents, currency=EXCLUDED.currency,
  affiliate_url=EXCLUDED.affiliate_url, image_url=EXCLUDED.image_url,
  image_urls=EXCLUDED.image_urls, is_published=EXCLUDED.is_published,
  shop_persona=EXCLUDED.shop_persona, shop_main_category=EXCLUDED.shop_main_category,
  shop_sub_category=EXCLUDED.shop_sub_category, amazon_category=EXCLUDED.amazon_category,
  brand=EXCLUDED.brand, shop_tags=EXCLUDED.shop_tags,
  editorial_note=EXCLUDED.editorial_note, key_fact=EXCLUDED.key_fact,
  pros=EXCLUDED.pros, cons=EXCLUDED.cons;

-- Verified manufacturer/Amazon product images. Keeping this separate makes the
-- product rows readable while ensuring the live cards never ship as placeholders.
WITH product_images(slug, url) AS (VALUES
  ('lego-31168-ritterburg','https://www.lego.com/cdn/cs/set/assets/blt704380e8e257025f/31168_Prod.png'),
  ('playmobil-72113-ritterburg','https://media.playmobil.com/i/playmobil/72113_product_detail'),
  ('lego-76976-dinosaurier','https://www.lego.com/cdn/cs/set/assets/blt380694221ffbc765/76976_Prod_en-gb.png'),
  ('playmobil-71819-dinosaurier','https://media.playmobil.com/i/playmobil/71819_product_detail'),
  ('lego-technic-42215-baustelle','https://www.lego.com/cdn/cs/set/assets/blt6027837d523f859d/42215_Prod.png'),
  ('playmobil-70441-baustelle','https://media.playmobil.com/i/playmobil/70441_product_detail'),
  ('lego-10788-puppenhaus','https://m.media-amazon.com/images/I/81CAXXBsPvL._AC_SL1500_.jpg'),
  ('playmobil-70205-puppenhaus','https://media.playmobil.com/i/playmobil/70205_product_detail'),
  ('lego-43297-maerchenschloss','https://m.media-amazon.com/images/I/81foyGHbHZL._AC_SL1500_.jpg'),
  ('playmobil-71845-maerchenschloss','https://media.playmobil.com/i/playmobil/71845_product_detail'),
  ('lego-technic-42207-supersportwagen','https://www.lego.com/cdn/cs/set/assets/blt1dd4e21e38b03edd/42207_Prod_en-gb.png'),
  ('playmobil-71020-supersportwagen','https://media.playmobil.com/i/playmobil/71020_product_detail'),
  ('lego-technic-42239-kultauto','https://m.media-amazon.com/images/I/81kLQdho38L._AC_SL1500_.jpg'),
  ('playmobil-71343-kultauto','https://media.playmobil.com/i/playmobil/71343_product_detail'),
  ('lego-31387-piraten','https://m.media-amazon.com/images/I/81AcAvxeT3L._AC_SL1500_.jpg'),
  ('playmobil-71530-piraten','https://media.playmobil.com/i/playmobil/71530_product_detail'),
  ('lego-technic-42221-nasa-artemis-sls','https://m.media-amazon.com/images/I/81YP1ZFq+9L._AC_SL1500_.jpg'),
  ('playmobil-72011-raumfahrt','https://media.playmobil.com/i/playmobil/72011_product_detail'),
  ('lego-star-wars-75419-todesstern','https://www.lego.com/cdn/cs/set/assets/blt725a94446f56dbe2/75419_Prod.png'),
  ('playmobil-70890','https://media.playmobil.com/i/playmobil/70890_product_detail')
)
UPDATE public.products AS p
SET image_url = i.url, image_urls = ARRAY[i.url]
FROM product_images AS i
WHERE p.slug = i.slug;

DO $$
DECLARE n integer;
DECLARE image_n integer;
BEGIN
  SELECT count(*) INTO n FROM public.products
  WHERE affiliate_url ~ '/(B0DWDT5BQ9|B0G7LNS8DX|B0F6YR2NN4|B0DQVMNQ4P|B0DWF9F6TN|B081HQ5S8H|B0CHD88C1B|B07P581CK8|B0FR9JYZBR|B0DQVMTRKS|B0DHSCYDL2|B09QV55L2V|B0GGSBK9FM|B0BT8BHPCQ|B0FPXGBPR6|B0CK2KK34J|B0FPXDRV4H|B0G671HMMC|B0FPXFMGVT|B09R6SYRK8)([/?]|$)'
    AND is_published=true;
  IF n <> 20 THEN RAISE EXCEPTION 'Postflight failed: expected 20 published ASINs, found %', n; END IF;
  SELECT count(*) INTO image_n FROM public.products
  WHERE slug IN (
    'lego-31168-ritterburg','playmobil-72113-ritterburg',
    'lego-76976-dinosaurier','playmobil-71819-dinosaurier',
    'lego-technic-42215-baustelle','playmobil-70441-baustelle',
    'lego-10788-puppenhaus','playmobil-70205-puppenhaus',
    'lego-43297-maerchenschloss','playmobil-71845-maerchenschloss',
    'lego-technic-42207-supersportwagen','playmobil-71020-supersportwagen',
    'lego-technic-42239-kultauto','playmobil-71343-kultauto',
    'lego-31387-piraten','playmobil-71530-piraten',
    'lego-technic-42221-nasa-artemis-sls','playmobil-72011-raumfahrt',
    'lego-star-wars-75419-todesstern','playmobil-70890'
  ) AND image_url IS NOT NULL;
  IF image_n <> 20 THEN RAISE EXCEPTION 'Postflight failed: expected 20 product images, found %', image_n; END IF;
END $$;

COMMIT;

SELECT slug,name,price_cents,affiliate_url,is_published
FROM public.products
WHERE slug IN (
  'lego-31168-ritterburg',
  'playmobil-72113-ritterburg',
  'lego-76976-dinosaurier',
  'playmobil-71819-dinosaurier',
  'lego-technic-42215-baustelle',
  'playmobil-70441-baustelle',
  'lego-10788-puppenhaus',
  'playmobil-70205-puppenhaus',
  'lego-43297-maerchenschloss',
  'playmobil-71845-maerchenschloss',
  'lego-technic-42207-supersportwagen',
  'playmobil-71020-supersportwagen',
  'lego-technic-42239-kultauto',
  'playmobil-71343-kultauto',
  'lego-31387-piraten',
  'playmobil-71530-piraten',
  'lego-technic-42221-nasa-artemis-sls',
  'playmobil-72011-raumfahrt',
  'lego-star-wars-75419-todesstern',
  'playmobil-70890'
)
ORDER BY slug;
