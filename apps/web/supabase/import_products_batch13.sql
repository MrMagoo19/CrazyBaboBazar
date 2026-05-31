-- Batch 13 — 4 Produkte
-- is_published = false → nach Review manuell publishen

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category, shop_tags)
VALUES (
  'Dyson Zone Absolute Kopfhörer',
  'dyson-zone-absolute-kopfhoerer',
  E'Kopfhörer und Luftreiniger in einem Gerät. Der Dyson Zone filtert PM2.5-Partikel, Pollen, Bakterien und NO2-Gase aus der Luft — gleichzeitig, während du Musik hörst. Kein Schlauch, kein Clip, keine separate Maske: Die gereinigte Luft kommt direkt aus dem Bügel.\n\nGeräuschunterdrückung auf Flaggschiff-Niveau, bis zu 50 Stunden Akku, 11-Treiber-Audiosystem. Für alle, die in der Stadt oder viel im Transit unterwegs sind und aufgehört haben, schlechte Luft als normal zu akzeptieren. Absurdes Gerät — aber auf die einzig richtige Art absurd.',
  'Kopfhörer mit eingebautem Luftreiniger — filtert PM2.5, Pollen und NOx direkt vor deinem Gesicht',
  34999,
  'https://m.media-amazon.com/images/I/41suGHRihZL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0C9R88Q1H?linkCode=ll2&tag=geeklist-21&ref_=as_li_ss_tl',
  false, true, 'babo', 'tech', 'gadgets',
  ARRAY['queen:lifestyle']
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Dusch WC Aufsatz mit Warmwasser',
  'dusch-wc-aufsatz-warmwasser',
  E'Japanisches Bidet-Prinzip für jede normale Toilette. Warmes Wasser, beheizter Sitz, Warmluft-Trocknung — alles einstellbar, kein Einbauen, kein Klempner. Der Aufsatz sitzt auf deiner bestehenden Toilette und braucht nur eine Steckdose.\n\nWer einmal damit gearbeitet hat, versteht die Frage nicht mehr, warum das in Europa noch Nische ist. Weniger Toilettenpapier, mehr Komfort, deutlich hygienischer. Das Upgrade, das in Hotelzimmern in Tokyo selbstverständlich ist.',
  'Beheizter Bidet-Aufsatz mit Warmwasser und Trocknung — japanischer Standard für jede Toilette',
  29290,
  'https://m.media-amazon.com/images/I/31yK68CSHhL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CQVTQ21G?linkCode=ll2&tag=geeklist-21&ref_=as_li_ss_tl',
  false, false, 'wellness', 'beauty', 'pflege'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'N4 Nussmilchbereiter Pflanzenmilch',
  'n4-nussmilchbereiter-pflanzenmilch',
  E'800 Watt, selbstreinigend, BPA-frei. Der N4 macht in unter zwei Minuten Hafer-, Mandel-, Soja-, Cashew-, Reis- oder Kokosmilch aus Rohzutaten — ohne Einweichen, ohne separaten Filter, ohne Aufräumaufwand.\n\nFür alle, die aufgehört haben, Tetrapacks zu kaufen, und das auch konsequent umsetzen wollen. Kein Plastikabfall, keine Verdickungsmittel, keine Zutaten, die man nicht ausspricht. Einfach die Zutaten rein, Deckel zu, Knopf drücken — fertig ist die Milch.',
  '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten',
  11999,
  'https://m.media-amazon.com/images/I/41bCLL0vUjL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FKMBPLBF?linkCode=ll2&tag=geeklist-21&ref_=as_li_ss_tl',
  false, false, 'queen', 'kueche', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'StirMATE Smart Pot Rührer Gen 2',
  'stirmate-smart-pot-ruehrer-gen2',
  E'Automatischer Topfrührer, der einfach im Topf sitzt und seinen Job macht — während du deinen machst. Batteriebetrieben, drei Geschwindigkeitsstufen, für Töpfe bis 30 cm Durchmesser. Kein Ankleben, kein Rühren vergessen, kein angebrannter Reis.\n\nFür alle, die beim Kochen nebenbei noch etwas anderes erledigen wollen. Risotto, Béchamel, Grieß, Pudding — alles, was eigentlich ständige Aufmerksamkeit verlangt, läuft jetzt von allein.',
  'Automatischer Topfrührer, batteriebetrieben — damit Risotto nicht mehr dein ganzes Abend verlangt',
  10001,
  'https://m.media-amazon.com/images/I/41xQnltB30L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B076HH4WZM?linkCode=ll2&tag=geeklist-21&ref_=as_li_ss_tl',
  false, false, 'queen', 'kueche', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;
