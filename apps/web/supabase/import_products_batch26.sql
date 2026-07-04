-- =============================================================================
-- import_products_batch26.sql
-- 1 Produkt: PONGBOT Tischtennis-Roboter
-- Erstellt: 2026-06-21
-- HINWEIS: image_url muss manuell ergänzt werden (Amazon-Seite → Rechtsklick Bild → Adresse kopieren)
-- =============================================================================

INSERT INTO products (
  slug, name, tagline, description,
  price_cents, currency, affiliate_url,
  image_url, image_urls,
  is_published, is_featured,
  shop_persona, shop_main_category, shop_sub_category, shop_tags
)
VALUES (
  'pongbot-tischtennis-roboter-ballmaschine',
  'PONGBOT Tischtennis-Roboter',
  '114 Programme. Kein Trainingspartner. Keine Ausreden.',
  E'Wer braucht schon einen Trainingspartner, der pünktlich kommt, nie meckert und auch um Mitternacht noch eine Runde dranhängt?\n\nDer PONGBOT ist eine automatische Tischtennis-Ballmaschine mit 114 vorinstallierten Trainingsprogrammen und Fernbedienung. Du wählst dein Programm, stellst dich an den Tisch — und der Rest erledigt sich. Für Anfänger, die Aufschlag und Rückhand üben wollen, genauso wie für Fortgeschrittene, die an Reaktion und Ausdauer arbeiten.\n\n114 Programme. Keine Wiederholung. Kein Stillstand.\n\nDer Preis ist Premium — das ist nichts für den Gelegenheitsspieler. Aber für alle, die Tischtennis ernstnehmen und keinen festen Trainingspartner haben: das hier ist die Antwort.',
  149999,
  'EUR',
  'https://www.amazon.de/dp/B0CV7NF83J?tag=geeklist-21',
  'https://m.media-amazon.com/images/I/612uMoaMaHL._AC_SL1500_.jpg',
  ARRAY['https://m.media-amazon.com/images/I/612uMoaMaHL._AC_SL1500_.jpg']::text[],
  false,
  false,
  'babo',
  'fitness',
  'tischtennis',
  ARRAY['fitness', 'sport', 'tischtennis', 'training', 'heimtraining', 'gadget', 'ueber-200-euro']
)
ON CONFLICT (slug) DO UPDATE SET
  name               = EXCLUDED.name,
  tagline            = EXCLUDED.tagline,
  description        = EXCLUDED.description,
  price_cents        = EXCLUDED.price_cents,
  currency           = EXCLUDED.currency,
  affiliate_url      = EXCLUDED.affiliate_url,
  image_url          = EXCLUDED.image_url,
  image_urls         = EXCLUDED.image_urls,
  shop_persona       = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category,
  shop_sub_category  = EXCLUDED.shop_sub_category,
  shop_tags          = EXCLUDED.shop_tags,
  updated_at         = now();
