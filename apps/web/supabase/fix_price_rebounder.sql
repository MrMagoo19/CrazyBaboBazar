-- =============================================================================
-- fix_price_rebounder.sql
-- Preis für Fußball-Rebounder korrigiert: 4499 → 66291 (662,91 €)
-- Erstellt: 2026-06-14
-- =============================================================================

UPDATE products SET price_cents = 66291
WHERE slug = 'fussball-rebounder-trainingswand-faltbar';
