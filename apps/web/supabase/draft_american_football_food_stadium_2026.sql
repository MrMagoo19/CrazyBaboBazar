-- =============================================================================
-- draft_american_football_food_stadium_2026.sql
-- Kuratierte Game-Day-Food-Kollektion fuer CrazyBaboBazar
--
-- Amazon-Partner-Tag: geeklist-21
-- Status: Entwurf; vor Ausfuehrung jeden Amazon-Link/Preis live pruefen.
-- Quellen der Vorauswahl: 40YARDS, moebel.de/Idealo, LECKER.
-- =============================================================================

INSERT INTO products (
  slug, name, tagline, description, price_cents, currency, affiliate_url,
  image_url, image_urls, is_published, is_featured, shop_persona,
  shop_main_category, shop_sub_category, amazon_category, brand, shop_tags,
  editorial_note, fuer_wen, nicht_fuer, key_fact, pros, cons
)
VALUES
(
  '40yards-american-football-snack-stadium-bambus',
  '40YARDS American Football Snack Stadium aus Bambusholz',
  'Das Stadion fuer Nachos, Dips und alles, was im vierten Quarter verschwindet',
  E'Das ist kein normales Servierbrett, sondern die Haupttribuene deines Game Days.\n\nDas Snack Stadium aus Bambusholz kommt mit Filz-Spielfeld und zwei Field Goals. Die Faecher bieten Platz fuer Chips, Nachos, Popcorn, Nuesse, Suessigkeiten und Fingerfood. Es wird aufgebaut geliefert und laesst sich nach dem Spiel einfach feucht auswischen.\n\nUnser Urteil: Der Hingucker fuer jede Watch Party und ein Geschenk, das nicht nach einem Abend im Schrank verschwindet.',
  5999,
  'EUR',
  'https://www.amazon.de/dp/B0DBJ8975B?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, true, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'snacks', 'watch-party', 'party', 'essen', 'trinken'],
  'Der visuelle Mittelpunkt der Kollektion: ein wiederverwendbares Snack-Stadion statt einer Wegwerf-Pappschale.',
  'Hosts von Football-Abenden, Super-Bowl-Fans und alle, die Snacks gern als Erlebnis servieren.',
  'Nicht fuer die Spuelmaschine oder sehr fluessige Speisen ohne Einlage; Lebensmittel sind nicht enthalten.',
  'Bambusholz, Filz-Spielfeld, zwei Field Goals, ca. 50 x 36 x 10 cm.',
  ARRAY['starker Wow-Effekt', 'wiederverwendbar', 'viel Platz fuer mehrere Snack-Sorten'],
  ARRAY['braucht eine groessere Tischflaeche', 'Handreinigung empfohlen']
),
(
  '40yards-american-football-bowl-keramik-xxl',
  '40YARDS American Football Schuessel XXL aus Keramik',
  'Die Bowl fuer Nachos, Wings und den grossen Hunger',
  E'Eine Schuessel in echter Football-Form: gross genug fuer Nachos, Chicken Wings, Popcorn oder Salat und auffaellig genug, um neben dem Snack Stadium nicht unterzugehen.\n\nDie erhabene Naht fuehlt sich wie ein echter Football an. Mit 1,9 Litern Volumen ist sie die richtige Groesse fuer den zentralen Snack auf dem Tisch. Spuelmaschinen- und mikrowellengeeignet.',
  2999,
  'EUR',
  'https://www.amazon.de/dp/B092RDM3QH?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, false, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'nachos', 'chicken-wings', 'snacks', 'watch-party'],
  'Der beste Einzelkauf, wenn ein komplettes Stadion zu gross ist, aber die Football-Optik bleiben soll.',
  'Nacho-Fans, Gastgeber und Football-Fans mit wenig Platz auf dem Tisch.',
  'Nicht ideal fuer sehr kleine Snacks oder fuer Menschen, die neutrales Geschirr suchen.',
  '1,9 Liter Volumen; ca. 28 x 16 x 9 cm; spuelmaschinengeeignet.',
  ARRAY['auffaellige Football-Form', 'grosses Fassungsvermoegen', 'leicht zu reinigen'],
  ARRAY['Keramik ist schwerer und bruchgefaehrdeter als Bambus']
),
(
  '40yards-american-football-dipschalen-3er-set',
  '40YARDS American Football Snack- & Dipschalen, 3er-Set',
  'Salsa, Guacamole und Kaese-Dip bekommen ihre eigene Endzone',
  E'Drei unterschiedlich grosse Football-Schalen fuer Dips, Saucen, Nuesse und kleine Beilagen. So bleibt das Snack Stadium uebersichtlich und jeder Dip bekommt seinen eigenen Platz.\n\nDie Keramik ist robust, dekorativ und spuelmaschinengeeignet. Ein kleines Set mit grosser Wirkung — besonders zusammen mit Nachos oder Burgern.',
  2499,
  'EUR',
  'https://www.amazon.de/dp/B0CGB3SM3S?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, false, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'dips', 'snacks', 'party'],
  'Ergaenzt das Hauptprodukt sinnvoll und erhoeht den Warenkorb ohne beliebiges Party-Zubehoer.',
  'Dip-Liebhaber und Gastgeber, die mehrere Saucen gleichzeitig servieren.',
  'Nicht fuer grosse Hauptgerichte; drei Schalen ersetzen kein komplettes Geschirrset.',
  'Drei Football-Schalen fuer Dips, Saucen und Snacks; spuelmaschinengeeignet.',
  ARRAY['passender Look zur Kollektion', 'drei Groessen', 'einfach zu reinigen'],
  ARRAY['weniger Volumen als eine grosse Snack-Bowl']
),
(
  '40yards-american-football-bierglaeser-2er-set',
  '40YARDS American Football Bierglaeser, 2er-Set',
  '600 ml fuer Bier, Cola und das naechste Play-by-Play',
  E'Zwei mundgeblasene Glaeser mit erhabener Football-Naht. Jedes Glas fasst 0,5 Liter plus Schaum und funktioniert genauso gut fuer Cola, Wasser oder alkoholfreie Drinks.\n\nDas Set bringt den Drink-Bereich optisch auf dasselbe Niveau wie das Snack Stadium und ist gleichzeitig ein brauchbares Geschenk fuer Football-Fans.',
  1999,
  'EUR',
  'https://www.amazon.de/dp/B08546KYFF?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, false, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'bier', 'getraenke', 'watch-party'],
  'Das staerkste Trinkprodukt der Kollektion: sichtbar besonders, aber trotzdem alltagstauglich.',
  'Bierfans, Gastgeber und Fans von auffaelligem Bar-Zubehoer.',
  'Nicht fuer heisse Getraenke; trotz Spuelmaschinentauglichkeit vorsichtig mit der erhabenen Naht umgehen.',
  '2 Glaeser; je 600 ml Gesamtvolumen; fuer kalte Getraenke geeignet.',
  ARRAY['hoher Nutzwert', 'stimmiges Design', 'auch alkoholfrei einsetzbar'],
  ARRAY['Glas ist bruchempfindlicher als Kunststoff']
),
(
  '40yards-american-football-zahnstocher-30er',
  '40YARDS American Football Zahnstocher, 30er-Set',
  'Der kleine Touchdown fuer Burger, Sandwiches und Fingerfood',
  E'Football aus Ahornholz, Spiess aus Bambus: Diese Zahnstocher machen aus Burgern, Club-Sandwiches und Cocktail-Haeppchen sofort Game-Day-Food.\n\nEin guenstiger Mitnahmeartikel, der das grosse Snack Stadium auf Fotos und am Tisch zusammenhaelt.',
  599,
  'EUR',
  'https://www.amazon.de/dp/B0C9KKX162?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, false, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'party', 'fingerfood', 'burger'],
  'Perfekter Add-on-Artikel: niedriger Preis, klare Verwendung, hoher Fotoeffekt.',
  'Hosts, Burger-Fans und alle, die Fingerfood dekorativ servieren.',
  'Nicht als Spielzeug fuer Kinder verwenden; nach einmaligem Gebrauch entsorgen.',
  '30 lebensmittelechte Football-Spiesse aus Holz und Bambus.',
  ARRAY['sehr niedrige Einstiegshuerde', 'macht Fingerfood sofort thematisch', 'kein Plastik'],
  ARRAY['Einwegprodukt', 'nicht fuer sehr schwere Speisen']
),
(
  '40yards-american-football-servietten-spielfeld',
  '40YARDS American Football Servietten im Spielfeld-Design',
  'Das Spielfeld endet nicht an der Tischkante',
  E'24 Servietten im Spielfeld-Design fuer den praktischen Teil des Game Days: Nachos, Wings, Burger und Drinks hinterlassen Spuren — diese Servietten machen daraus trotzdem eine runde Tafel.\n\nDer guenstige Zusatzartikel passt neben das Holz-Stadion, ohne die Optik mit beliebiger Super-Bowl-Deko zu verwischen.',
  699,
  'EUR',
  'https://www.amazon.de/dp/B0DH8NBWVT?tag=geeklist-21&linkCode=ogi&th=1',
  '', ARRAY[]::text[], true, false, 'babo', 'outdoor', 'sport',
  'Küche & Haushalt', '40YARDS',
  ARRAY['babo:outdoor', 'american-football', 'gameday', 'food-stadium', 'party', 'tischdeko'],
  'Kleiner Warenkorb-Booster, der die Kollektion am Tisch komplett aussehen laesst.',
  'Hosts von Watch-Partys und Fans von abgestimmter Tischdeko.',
  'Nicht als Ersatz fuer waschbare Stoffservietten gedacht.',
  '24 Servietten im American-Football-Spielfeld-Design.',
  ARRAY['preisguenstiger Add-on', 'sofortiger Themen-Look', 'praktisch bei Fingerfood'],
  ARRAY['Verbrauchsartikel', 'weniger langlebig als das Holzgeschirr']
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  tagline = EXCLUDED.tagline,
  description = EXCLUDED.description,
  price_cents = EXCLUDED.price_cents,
  affiliate_url = EXCLUDED.affiliate_url,
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
  cons = EXCLUDED.cons,
  is_published = EXCLUDED.is_published;

INSERT INTO lists (slug, title, intro, body, product_slugs, is_published)
VALUES (
  'american-football-food-stadium',
  'American Football Food Stadium',
  E'Das Spiel laeuft. Die Snacks stehen. Und jeder Bissen fuehlt sich nach Touchdown an.',
  E'Ein Football-Abend lebt nicht nur vom Spiel, sondern vom Tisch davor: Nachos, Dips, Wings, Burger, Bier und gute Drinks.\n\nDiese Auswahl baut den Game Day von der Mitte aus auf: Das wiederverwendbare Snack Stadium ist der Hingucker, dazu kommen passende Schalen, Glaeser und kleine Details fuer Fingerfood und Tischdeko.\n\nAlle Links fuehren mit unserem Amazon-Partner-Tag zu den jeweiligen Angeboten. Preise und Verfuegbarkeit koennen sich aendern.',
  ARRAY[
    '40yards-american-football-snack-stadium-bambus',
    '40yards-american-football-bowl-keramik-xxl',
    '40yards-american-football-dipschalen-3er-set',
    '40yards-american-football-bierglaeser-2er-set',
    '40yards-american-football-zahnstocher-30er',
    '40yards-american-football-servietten-spielfeld'
  ],
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  intro = EXCLUDED.intro,
  body = EXCLUDED.body,
  product_slugs = EXCLUDED.product_slugs,
  is_published = EXCLUDED.is_published;
