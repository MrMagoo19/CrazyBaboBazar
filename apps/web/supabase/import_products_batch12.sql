-- Batch 12 — 5 Produkte
-- is_published = false → nach Review manuell publishen

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Tefola Wäscheständer Wandmontage',
  'tefola-waeschestaender-wandmontage',
  'Kompakter Wäscheständer für die Wand — Befestigung per Saugnapf, kein Bohren, kein Werkzeug, keine Löcher. Dreifach gefaltet braucht er kaum Platz, ausgeklappt bietet er genug Raum für Alltags- oder Reisewäsche.

Funktioniert auf Fliesen, Glas und glatten Oberflächen. Für Balkon, Bad, Terrasse, Wohnwagen oder überall, wo man wäscht, aber nicht bohren darf.',
  'Wandmontage per Saugnapf — 3-fach faltbar, kein Bohren, für Balkon und Bad',
  4098,
  'https://m.media-amazon.com/images/I/31cMLJxL34L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0DNFFF38Z?coliid=I2ZL6X7Q2Z5QI6&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=1133760c1939686d8e20c411c9933715&ref_=as_li_ss_tl',
  false, false, 'queen', 'lifestyle', 'deko'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'VONMÄHLEN Evergreen Go Powerbank',
  'vonmaehlen-evergreen-go-powerbank',
  'Eine Powerbank für den Schlüsselbund. 1.000 mAh, USB-C, aus 34 % recycelten Materialien. Nicht für den Notfall, der nie kommt — sondern für das tote Handy kurz vor dem Eingang.

Klein genug, um sie immer dabei zu haben. Groß genug, um das Wichtigste zu retten: einen letzten Anruf, eine QR-Code-Buchung oder die Nachricht, die erklärt, wo man gerade wirklich ist.',
  'USB-C Schlüsselbund-Powerbank aus 34 % recycelten Materialien — 1.000 mAh immer dabei',
  1699,
  'https://m.media-amazon.com/images/I/31dEH4ua8kL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FN5BS9GF?coliid=I274LC9E65Z5BD&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=6b17f7f3071f5583f3b0da8ab6853b50&ref_=as_li_ss_tl',
  false, false, 'babo', 'tech', 'setup'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'DJI Osmo Pocket 4 Kreativ Combo',
  'dji-osmo-pocket-4-kreativ-combo',
  'Die kleinste Profi-Kamera in der DJI-Linie. Einzoll-Sensor, 4K mit bis zu 240 Frames pro Sekunde, 3-Achsen-Gimbal-Stabilisierung und 107 GB integrierter Speicher. Die Kreativ-Combo enthält zusätzlich ein Mic 3 Sender-Empfänger-Set und ein Fülllicht.

Wer regelmäßig filmt — Reisen, Sport, Content, Familienerinnerungen — und sich nicht mehr mit verwackelten Handy-Videos abfinden will, bekommt hier ein Gerät, das wie ein Stift aussieht und wie ein Profi-Setup funktioniert.',
  '1″ CMOS, 4K/240fps, 3-Achsen-Gimbal — professionelle Videostabilisierung in der Hosentasche',
  61900,
  'https://m.media-amazon.com/images/I/51T0vkkJx9L._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FKT9K6CB?coliid=I1QJ2ZCND7BP6K&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=b28e1fc2c23a3d979979397bd9dcbce0&ref_=as_li_ss_tl',
  false, true, 'babo', 'tech', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Funko Pop! Han Solo in Carbonite',
  'funko-pop-han-solo-in-carbonite-esb',
  'Han Solo in Carbonite — das ikonischste Ende eines Cliffhangers in der Filmgeschichte, jetzt als offiziell lizenzierter Funko Pop. Erschienen zum 40. Jahrestag von Das Imperium schlägt zurück.

Mit genau der richtigen Mischung aus Nostalgie, Ironie und Star-Wars-Liebe. Passt zu jedem Regal, das bereits erklärt, dass man die Filme in der richtigen Reihenfolge gesehen hat.',
  'ESB 40th Anniversary — Han Solo eingefroren für die Ewigkeit, jetzt fürs Regal',
  2645,
  'https://m.media-amazon.com/images/I/41uClY0P0yS._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B07YQH9FKC?coliid=I3L9FSZ6D0TRTK&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=01d6982e91a9b1f651b46112ea809af6&ref_=as_li_ss_tl',
  false, false, 'babo', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'Whiskey Decanter Set mit 2 Gläsern',
  'whiskey-decanter-set-2-glaeser',
  'Whiskey-Dekanter aus transparentem Glas mit zwei 150-ml-Gläsern. Klar, schlicht, edel — ohne den Gold-und-Schwarz-Designgeschmack, den günstige Sets meistens mitbringen.

Funktioniert für Whisky, Brandy, Scotch, Wodka oder Cognac. Als Geschenk für alle, die auf ihrem Sideboard lieber ein gutes Set stehen haben, als Flaschen zu sammeln, die man irgendwann aufmacht.',
  'Transparente Karaffe mit 2 Gläsern — für Whisky, Brandy und stilvolle Abende',
  3599,
  'https://m.media-amazon.com/images/I/51Fkt1nxWiL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0CQGBBVM6?coliid=I32LFYAECN42Q1&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=4f52d4e7ba4a17f412740137e6d1e91a&ref_=as_li_ss_tl',
  false, false, 'babo', 'lifestyle', 'gadgets'
) ON CONFLICT (slug) DO NOTHING;
