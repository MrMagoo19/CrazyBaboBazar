-- Batch 20 — 1 Produkt — is_published = TRUE (sofort live)
-- ON CONFLICT DO UPDATE → Upsert

INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LEGO Star Wars Mandalorian Helm (75328)',
  'lego-star-wars-mandalorian-helm-75328',
  E'Nicht zum Spielen — zum Ausstellen. Das LEGO-Modell des ikonischen Mandalorian-Helms aus der gleichnamigen Disney+-Serie. 584 Teile, Details wie aus dem Original, inklusive Display-Ständer und Namensschild.\n\nFür alle, die Star Wars ernst nehmen und ihr Regal als Galerie betreiben. Oder für alle, die einen Mando-Fan beschenken wollen, der eigentlich schon alles hat.',
  'LEGO-Modell des Mandalorian-Helms — 584 Teile, Display-Ständer, für Fans und Sammler',
  4426,
  'https://m.media-amazon.com/images/I/812oT9JHpUL._AC_SL1500_.jpg',
  'https://www.amazon.de/LEGO-75408-Star-Wars/dp/B09BNWZF68?th=1&linkCode=ll2&tag=geeklist-21&linkId=99fff86644a1c78ca02d0159a583c817&ref_=as_li_ss_tl',
  true, false, 'babo', 'gaming', 'collectibles'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, tagline = EXCLUDED.tagline,
  price_cents = EXCLUDED.price_cents, image_url = EXCLUDED.image_url, affiliate_url = EXCLUDED.affiliate_url,
  is_published = EXCLUDED.is_published, shop_persona = EXCLUDED.shop_persona,
  shop_main_category = EXCLUDED.shop_main_category, shop_sub_category = EXCLUDED.shop_sub_category,
  is_featured = EXCLUDED.is_featured;
