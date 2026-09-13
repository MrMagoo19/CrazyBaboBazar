-- Production target: ydiihvzcxaaoqhmgoqvu.supabase.co
-- PREPARED ONLY: requires explicit approval before production execution.
-- Adds 10 products for /guide/uglydolls-vs-fuggler. Idempotent by slug.
-- Preflight aborts if any of the 10 ASINs already exists under a slug
-- other than the ones this script intends to write (no silent overwrite
-- of unrelated existing product data).

BEGIN;

DO $$
DECLARE conflict_count integer;
BEGIN
  SELECT count(*) INTO conflict_count FROM public.products
  WHERE affiliate_url ~ '/(B07Q3827QL|B0DC1YGDW4|B07M5C4JKX|B0DS96FQ59|B07MY4Z9V3|B0H6YJQ6KM|B07FK852WL|B0F1YRWBTW|B07STLLNLL|B0GZHQZ84P)([/?]|$)'
    AND slug NOT IN (
      'uglydolls-babo-briefkumpel-plueschfigur-22cm',
      'fuggler-laboratory-misfits-annoyed-alien',
      'uglydolls-moxy-sound-plueschfigur-29cm',
      'fuggler-misfit-monsters-rabid-rabbit-old-tooth',
      'uglydolls-ox-schmuse-pluesch-45cm',
      'bigg-fugg-grumpy-grumps-46cm',
      'uglydoll-lotsa-ugly-mini-figures-blindpack',
      'fuggler-sammelfigur-mit-sammelposter',
      'uglydolls-jeero-pfannkuchenheld',
      'fuggler-gold-edition-spielfigur'
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
('uglydolls-babo-briefkumpel-plueschfigur-22cm','Hasbro UglyDolls Brieffreunde BABO Plüschfigur, 22 cm','Der Brieffreund, der garantiert nie zurückschreibt.','Offizielle Hasbro-UglyDolls-Plüschfigur BABO aus der Brieffreunde-Serie, rund 22 cm groß. Marketplace-Angebot mit Amazon-Versand (docsmagic), laut Bestandsanzeige nur noch 10 Exemplare.',2530,'EUR','https://www.amazon.de/dp/B07Q3827QL?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81MYa3O5PNL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81MYa3O5PNL._AC_SL1500_.jpg'],true,false,'miniboss','spielzeug','plueschfigur','Spielzeug','Hasbro',ARRAY['miniboss:spielzeug','uglydolls','babo','plueschfigur'],'Teureres, aber charismatischeres Los im ersten Duell.','BABO-Plüschfigur, rund 22 cm, Hasbro UglyDolls Brieffreunde-Serie.',ARRAY['offizielle Hasbro-Lizenz','bekannter Charakter'],ARRAY['Marketplace-Angebot','nur noch 10 Exemplare laut Bestandsanzeige','Restbestand der 2019er-Welle']),
('fuggler-laboratory-misfits-annoyed-alien','ZURU Fuggler Laboratory Misfits Annoyed Alien Plüschfigur','Genervt, haarig, sofort lieferbar.','Fuggler-Plüschfigur Annoyed Alien aus der offiziellen Laboratory-Misfits-Serie von ZURU, direkt bei Amazon auf Lager.',1495,'EUR','https://www.amazon.de/dp/B0DC1YGDW4?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81W0T9rPx2L._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81W0T9rPx2L._AC_SL1500_.jpg'],true,false,'miniboss','spielzeug','plueschfigur','Spielzeug','ZURU',ARRAY['miniboss:spielzeug','fuggler','laboratory-misfits','plueschfigur'],'Günstigeres und direkt lieferbares Gegenstück zu BABO.','Fuggler Annoyed Alien, Laboratory-Misfits-Serie, ZURU.',ARRAY['Amazon-Angebot, auf Lager','offizielle ZURU-Fuggler-Serie'],ARRAY['reine Geschmacksfrage, wie bei jedem Fuggler']),
('uglydolls-moxy-sound-plueschfigur-29cm','Hasbro UglyDolls Moxy Knuddel-Plüschfigur mit Sound, 29 cm','Über fünfzehn Sounds. Drei Knopfzellen. Kein Vibrato.','Offizielle UglyDolls-Moxy-Plüschfigur mit mehr als 15 Soundeffekten, rund 29 cm groß, Batteriefach für drei LR44-Knopfzellen. Angebot aus dem Amazon-UK-Lager, laut Bestandsanzeige zuletzt nur noch 2 Exemplare.',3425,'EUR','https://www.amazon.de/dp/B07M5C4JKX?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/71LoxC+3XLL._AC_SL1024_.jpg',ARRAY['https://m.media-amazon.com/images/I/71LoxC+3XLL._AC_SL1024_.jpg'],true,false,'miniboss','spielzeug','sound-plueschfigur','Spielzeug','Hasbro',ARRAY['miniboss:spielzeug','uglydolls','moxy','sound','plueschfigur'],'Teuerstes Los des Guides, dafür mit Soundfunktion.','Moxy-Plüschfigur mit über 15 Sounds, 29 cm, 3x LR44-Knopfzellen.',ARRAY['über 15 Soundeffekte','offizielle Hasbro-Lizenz'],ARRAY['Amazon-UK-Lager, längere Lieferzeit möglich','nur noch 2 Exemplare laut Bestandsanzeige','Knopfzellen enthalten – Batteriefach bei Kleinkindern sichern']),
('fuggler-misfit-monsters-rabid-rabbit-old-tooth','ZURU Fuggler Misfit Monsters Rabid Rabbit & Old Tooth, ca. 23 cm','Zwei Monster, ein Kaninchenohr zu viel.','Fuggler-Plüschfigur Rabid Rabbit & Old Tooth aus der offiziellen Misfit-Monsters-Serie von ZURU, rund 23 cm, direkt bei Amazon auf Lager.',1299,'EUR','https://www.amazon.de/dp/B0DS96FQ59?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81R9mYM3XcL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81R9mYM3XcL._AC_SL1500_.jpg'],true,false,'miniboss','spielzeug','plueschfigur','Spielzeug','ZURU',ARRAY['miniboss:spielzeug','fuggler','misfit-monsters','plueschfigur'],'Deutlich günstigeres Doppelfigur-Gegenstück zu Moxy.','Fuggler Rabid Rabbit & Old Tooth, Misfit-Monsters-Serie, ca. 23 cm.',ARRAY['Amazon-Angebot, auf Lager','offizielle ZURU-Fuggler-Serie'],ARRAY['reine Geschmacksfrage']),
('uglydolls-ox-schmuse-pluesch-45cm','Hasbro UglyDolls Super Schmuse-Uglys Ox, ca. 45 cm','XXL-Plüsch für alle, die es ehrlich meinen.','Große UglyDolls-Plüschfigur Ox aus der Super-Schmuse-Uglys-Serie, rund 45 cm. Marketplace-Angebot mit Amazon-Versand (docsmagic), laut Bestandsanzeige nur noch 10 Exemplare.',2540,'EUR','https://www.amazon.de/dp/B07MY4Z9V3?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61RI-JPm1UL._AC_SL1024_.jpg',ARRAY['https://m.media-amazon.com/images/I/61RI-JPm1UL._AC_SL1024_.jpg'],true,false,'miniboss','spielzeug','xxl-plueschfigur','Spielzeug','Hasbro',ARRAY['miniboss:spielzeug','uglydolls','ox','xxl','plueschfigur'],'Einziger UglyDolls-Sieger des Guides: günstiger als das Gegenstück.','Ox-Plüschfigur, ca. 45 cm, Super-Schmuse-Uglys-Serie.',ARRAY['großes XXL-Format','günstiger als das Gegenstück'],ARRAY['Marketplace-Angebot','nur noch 10 Exemplare laut Bestandsanzeige','Restbestand der 2019er-Welle']),
('bigg-fugg-grumpy-grumps-46cm','ZURU Bigg Fugg Grumpy Grumps, ca. 45,7 cm','Groß, grummelig, Herkunft mit Fragezeichen.','XXL-Plüschfigur Bigg Fugg im Grumpy-Grumps-Design, rund 45,7 cm. Angebot eines Marketplace-Händlers (BalticVaris DE), laut Angabe 4-5 Tage versandfertig. Zum Recherchezeitpunkt keine sichtbaren Bewertungen; die Zuordnung zur Grumpy-Grumps-Serie ist anhand des Listings nur schwach belegt.',5688,'EUR','https://www.amazon.de/dp/B0H6YJQ6KM?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/61vGkTmNhRL._AC_SL1000_.jpg',ARRAY['https://m.media-amazon.com/images/I/61vGkTmNhRL._AC_SL1000_.jpg'],true,false,'miniboss','spielzeug','xxl-plueschfigur','Spielzeug','ZURU',ARRAY['miniboss:spielzeug','fuggler','bigg-fugg','xxl','plueschfigur'],'Verliert trotz Größe: teurer, ohne Bewertungen, schwach belegte Serie.','Bigg Fugg, ca. 45,7 cm, XXL-Format.',ARRAY['großes XXL-Format'],ARRAY['Marketplace-Händler, 4-5 Tage Versandfertigkeit','keine sichtbaren Bewertungen','Serienzuordnung nur schwach belegt']),
('uglydoll-lotsa-ugly-mini-figures-blindpack','UglyDoll Lotsa Ugly Mini Figures Series 1 Blindpack','Eine zufällige Figur. Kein Rückgaberecht auf Enttäuschung.','Blindpack aus der Lotsa-Ugly-Mini-Figures-Serie 1 mit einer zufälligen Miniaturfigur plus Zubehör. Marketplace-Angebot mit Amazon-Versand.',1663,'EUR','https://www.amazon.de/dp/B07FK852WL?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/91QaMqiuWrL._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/91QaMqiuWrL._AC_SL1500_.jpg'],true,false,'miniboss','spielzeug','blindbox','Spielzeug','UglyDoll',ARRAY['miniboss:spielzeug','uglydolls','blindpack','sammelfigur'],'Günstigerer, aber inhaltlich zufälliger Gegenpart.','Zufällige Mini-Figur aus der Lotsa-Ugly-Serie 1, Blindpack.',ARRAY['günstiger Sammel-Einstieg','Amazon-Versand über Marketplace'],ARRAY['Zufallsinhalt – welche Figur enthalten ist, ist beim Kauf nicht bekannt']),
('fuggler-sammelfigur-mit-sammelposter','Bizak Fuggler Sammelfigur mit Sammelposter','Titel verspricht fünf, Bild zeigt vier, Text sagt drei.','Fuggler-Sammelfigur mit Sammelposter von Bizak/PMI. Das Listing ist in sich uneinheitlich: Der Titel nennt ein 5er-Pack, der Beschreibungstext spricht von drei Figuren, das Produktbild zeigt vier plus eine verdeckte Figur. Auch die Altersangabe ist im Listing nicht einheitlich. Vor dem Kauf lohnt ein genauer Blick auf die aktuelle Artikelbeschreibung.',2213,'EUR','https://www.amazon.de/dp/B0F1YRWBTW?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/81+AZ-OuKML._AC_SL1500_.jpg',ARRAY['https://m.media-amazon.com/images/I/81+AZ-OuKML._AC_SL1500_.jpg'],true,false,'miniboss','spielzeug','sammelfigur','Spielzeug','Bizak',ARRAY['miniboss:spielzeug','fuggler','sammelfigur','sammelposter'],'Knapper Sieger nur mit Vorbehalt – Listing vor Kauf gegenlesen.','Fuggler-Sammelfigur mit Sammelposter; Stückzahl laut Listing uneinheitlich angegeben.',ARRAY['Sammelposter enthalten','Amazon-Angebot'],ARRAY['widersprüchliche Stückzahl-Angabe im Listing (5er-Pack/drei/vier plus verdeckt)','uneinheitliche Altersangabe im Listing']),
('uglydolls-jeero-pfannkuchenheld','Hasbro Ugly Dolls Pfannkuchenheld Jeero Sammelfigur','Ein Pfannkuchen mit Heldenkomplex und Lieferzeit.','UglyDolls-Kunststofffigur Jeero als Pfannkuchenheld mit Verkleidungszubehör. Angebot eines selbst versendenden Händlers (ARFA7), laut Bestandsanzeige nur noch 2 Exemplare, Lieferzeit deutlich länger als bei Amazon-Versand.',912,'EUR','https://www.amazon.de/dp/B07STLLNLL?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/51LZNFIhSwL._AC_SL1000_.jpg',ARRAY['https://m.media-amazon.com/images/I/51LZNFIhSwL._AC_SL1000_.jpg'],true,false,'miniboss','spielzeug','sammelfigur','Spielzeug','Hasbro',ARRAY['miniboss:spielzeug','uglydolls','jeero','sammelfigur','verkleidungszubehoer'],'Günstigstes Produkt des Guides, dafür längere Lieferzeit.','Jeero-Sammelfigur als Pfannkuchenheld mit Verkleidungszubehör.',ARRAY['bekannte UglyDolls-Figur','Verkleidungszubehör enthalten','günstiger Preis'],ARRAY['selbst versendender Händler, längere Lieferzeit','nur noch 2 Exemplare laut Bestandsanzeige','Restbestand der 2019er-Welle']),
('fuggler-gold-edition-spielfigur','Fuggler Gold Edition Spielfigur','Eine von vier möglichen, plus Zubehör obendrauf.','Fuggler Gold Edition Spielfigur, zufällig aus vier möglichen Varianten plus zwei Zubehörteilen. Direktes Amazon-Angebot, zum Recherchezeitpunkt ohne sichtbare Bewertungen.',1499,'EUR','https://www.amazon.de/dp/B0GZHQZ84P?tag=geeklist-21&linkCode=ogi&th=1','https://m.media-amazon.com/images/I/51JwOoIvY7L._AC_.jpg',ARRAY['https://m.media-amazon.com/images/I/51JwOoIvY7L._AC_.jpg'],true,false,'miniboss','spielzeug','sammelfigur','Spielzeug','Fuggler',ARRAY['miniboss:spielzeug','fuggler','gold-edition','sammelfigur'],'Gewinnt über zuverlässige Lieferung trotz fehlender Bewertungen.','Fuggler Gold Edition, Zufallsfigur aus vier Varianten plus Zubehör.',ARRAY['Amazon-Angebot','Zubehör enthalten'],ARRAY['Zufallsfigur aus vier Varianten','keine sichtbaren Bewertungen zum Recherchezeitpunkt'])
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

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.products
  WHERE affiliate_url ~ '/(B07Q3827QL|B0DC1YGDW4|B07M5C4JKX|B0DS96FQ59|B07MY4Z9V3|B0H6YJQ6KM|B07FK852WL|B0F1YRWBTW|B07STLLNLL|B0GZHQZ84P)([/?]|$)'
    AND is_published=true;
  IF n <> 10 THEN RAISE EXCEPTION 'Postflight failed: expected 10 published ASINs, found %', n; END IF;
END $$;

COMMIT;

SELECT slug,name,price_cents,affiliate_url,is_published
FROM public.products
WHERE slug IN (
  'uglydolls-babo-briefkumpel-plueschfigur-22cm',
  'fuggler-laboratory-misfits-annoyed-alien',
  'uglydolls-moxy-sound-plueschfigur-29cm',
  'fuggler-misfit-monsters-rabid-rabbit-old-tooth',
  'uglydolls-ox-schmuse-pluesch-45cm',
  'bigg-fugg-grumpy-grumps-46cm',
  'uglydoll-lotsa-ugly-mini-figures-blindpack',
  'fuggler-sammelfigur-mit-sammelposter',
  'uglydolls-jeero-pfannkuchenheld',
  'fuggler-gold-edition-spielfigur'
)
ORDER BY slug;
