-- Liste "Geschenke für echte Gamer" — 3 Produkte hinzufügen
UPDATE lists
SET product_slugs = product_slugs || ARRAY[
  'weiminli-switch-skull-case',
  'giiker-super-slide-puzzle',
  'dealkit-3d-labyrinth-wuerfel'
]
WHERE slug = 'geschenke-fuer-gamer';

-- Prüfen ob es geklappt hat
SELECT slug, array_length(product_slugs, 1) as anzahl, product_slugs
FROM lists
WHERE slug = 'geschenke-fuer-gamer';
