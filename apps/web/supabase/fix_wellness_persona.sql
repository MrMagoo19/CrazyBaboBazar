-- =============================================================================
-- WELLNESS PERSONA CLEANUP
-- Laut Voice Bible ist "wellness" keine Persona, sondern nur eine Kategorie.
-- Alle Produkte mit shop_persona = 'wellness' werden auf babo oder queen umgestellt.
--
-- Regel (aus voice-bible.md §2):
--   sport/fitness/outdoor/training/tools → babo
--   beauty/pflege/kosmetik/nagelpflege/haushalt/lifestyle → queen
--   Ausnahme: bartpflege → babo (Produkte klar männlich)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BABO: Fitness & Sport
-- Sprossenwand, Power Tower, Tennis-Trainer, Powerball
-- Massagepistole, Akupressurmatte, Saunadecke, Schlafkopfhörer
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona       = 'babo',
  shop_main_category = 'fitness'
WHERE shop_persona = 'wellness'
  AND shop_main_category IN ('fitness', 'sport', 'training');

-- -----------------------------------------------------------------------------
-- BABO: Outdoor & Camping
-- Dry Bag, Solarpanel, Rucksack, Notizbuch
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona       = 'babo',
  shop_main_category = 'outdoor'
WHERE shop_persona = 'wellness'
  AND shop_main_category IN ('outdoor', 'camping');

-- -----------------------------------------------------------------------------
-- BABO: Bartpflege (explizit männlich)
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona       = 'babo',
  shop_main_category = 'beauty'
WHERE shop_persona = 'wellness'
  AND shop_sub_category IN ('bartpflege', 'bart');

-- -----------------------------------------------------------------------------
-- QUEEN: Beauty & Pflege (alles außer Bartpflege)
-- Make-up Organizer, Nagellampe, Luftbefeuchter, Fusselroller,
-- Handventilator, White Noise Machines
-- -----------------------------------------------------------------------------
UPDATE products SET
  shop_persona       = 'queen',
  shop_main_category = 'beauty'
WHERE shop_persona = 'wellness'
  AND shop_main_category IN ('beauty', 'pflege', 'nagelpflege', 'kosmetik');

-- Fallback: alle verbleibenden wellness-Produkte → babo
UPDATE products SET
  shop_persona = 'babo'
WHERE shop_persona = 'wellness';

-- =============================================================================
-- VOICE BIBLE TAGLINE FIX
-- Stopwort "ultimativ" entfernen
-- =============================================================================
UPDATE products SET
  tagline = 'Hinter dem Schirm bist du Gott.'
WHERE slug = 'dnd-spielleiterschirm-5e-dungeon-master';

-- Prüfen: sollte 0 zurückgeben
SELECT COUNT(*) AS verbleibende_wellness_produkte
FROM products
WHERE shop_persona = 'wellness';

-- Prüfen: sollte neue Tagline zeigen
SELECT slug, tagline FROM products WHERE slug = 'dnd-spielleiterschirm-5e-dungeon-master';
