-- Fix dead-route products — 18 Produkte die auf nicht existierende Routen zeigen
-- Ausführen in Supabase SQL Editor

-- babo·diy → babo·tech (6 Produkte, /babos/diy existiert nicht)
UPDATE products
SET shop_main_category = 'tech'
WHERE shop_persona = 'babo' AND shop_main_category = 'diy';

-- babo·sammeln → babo·gaming + collectibles (2 Produkte, /babos/sammeln existiert nicht)
UPDATE products
SET shop_main_category = 'gaming', shop_sub_category = 'collectibles'
WHERE shop_persona = 'babo' AND shop_main_category = 'sammeln';

-- queen·accessoires → queen·lifestyle (6 Produkte, /queens/accessoires existiert nicht)
UPDATE products
SET shop_main_category = 'lifestyle'
WHERE shop_persona = 'queen' AND shop_main_category = 'accessoires';

-- wellness·sport → wellness·fitness (4 Produkte, /wellness/sport existiert nicht, korrekte Route ist /wellness/fitness)
UPDATE products
SET shop_main_category = 'fitness'
WHERE shop_persona = 'wellness' AND shop_main_category = 'sport';
