-- =============================================================================
-- VOICE BIBLE DESCRIPTION FIXES
-- Generische Floskeln entfernt: "perfekte Ergänzung für jeden", "für jeden X-Fan"
-- =============================================================================

UPDATE products SET description = 'Dreistöckiger, drehbarer Kosmetik-Organizer aus transparentem Acryl. Hält Lippenstifte, Pinsel und Nagellack ordentlich und griffbereit — alles auf Sicht, direkt auf dem Schminktisch.'
WHERE slug = 'drehbarer-make-up-organizer-3-ebenen';

UPDATE products SET description = 'Offiziell lizenzierte Keramikschale im One-Piece-Design mit Monkey D. Luffy. Für Ramen, Müsli oder als Regal-Deko — wer One Piece kennt, weiß Bescheid.'
WHERE slug = 'one-piece-ramen-bowl-keramik';

UPDATE products SET description = 'Offizieller Funko Pop! Darth Vader aus Star Wars — das ikonische Vinyl-Sammlerstück. Ca. 10 cm groß, ideal als Schreibtisch-Deko oder nächste Station in der Sammlung.'
WHERE slug = 'funko-pop-darth-vader-star-wars';

-- Prüfen
SELECT slug, description FROM products
WHERE slug IN ('drehbarer-make-up-organizer-3-ebenen','one-piece-ramen-bowl-keramik','funko-pop-darth-vader-star-wars');
