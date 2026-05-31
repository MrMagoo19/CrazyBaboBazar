-- Batch 16 — 2 Produkte (Pokémon bereits in Supabase)
-- is_published = false → nach Review manuell publishen

-- B0FQP4PJKX — LEGO Cristiano Ronaldo 43016 — babo · gaming · collectibles — 62,89€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LEGO Cristiano Ronaldo Figur (43016)',
  'lego-cristiano-ronaldo-figur-43016',
  E'Cristiano Ronaldo als LEGO-Figur zum Selbstbauen — offiziell lizenziert, 3D-Modell, ab 12 Jahren. Für Kinderzimmer, Schreibtisch oder das Regal, das erklärt, wen man für den besten Fußballer hält.\n\nFür alle Ronaldo-Fans, die LEGO-Sets ernstnehmen. Oder für alle, die einem Ronaldo-Fan ein Geschenk suchen, das definitiv hängen bleibt.',
  'Offiziell lizenzierte LEGO-Figur von Cristiano Ronaldo — 3D-Modell für Fans und Sammler',
  6289,
  'https://m.media-amazon.com/images/I/71mwGrXX9pL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FQP4PJKX?coliid=I1FMVMBCZAXPJM&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=f10367baf7113e1e518b67a80049daf5&ref_=as_li_ss_tl',
  false, false, 'babo', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;

-- B0FR9KGKYY — LEGO Lionel Messi 43015 — babo · gaming · collectibles — 62,99€
INSERT INTO products (name, slug, description, tagline, price_cents, image_url, affiliate_url, is_published, is_featured, shop_persona, shop_main_category, shop_sub_category)
VALUES (
  'LEGO Lionel Messi Figur (43015)',
  'lego-lionel-messi-figur-43015',
  E'Lionel Messi als LEGO-Figur zum Selbstbauen — offiziell lizenziert, 3D-Modell, ab 12 Jahren. Für das Regal, das erklärt, auf welcher Seite der ewigen Debatte man steht.\n\nFür alle Messi-Fans, die wissen, dass die Antwort längst gegeben ist. Oder für alle, die einem Messi-Fan ein Geschenk suchen, das keine weitere Diskussion zulässt.',
  'Offiziell lizenzierte LEGO-Figur von Lionel Messi — 3D-Modell für Fans und Sammler',
  6299,
  'https://m.media-amazon.com/images/I/71ybegViWSL._AC_SL1500_.jpg',
  'https://www.amazon.de/dp/B0FR9KGKYY?coliid=I1FMVMBCZAXPJM&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=ba654c3d2879705697a79314775306ea&ref_=as_li_ss_tl',
  false, false, 'babo', 'gaming', 'collectibles'
) ON CONFLICT (slug) DO NOTHING;
