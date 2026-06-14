-- =============================================================================
-- unpublish_batch23_duplicates.sql
-- Deaktiviert 3 batch23-Produkte ohne Bilder — ältere Versionen bleiben aktiv
-- Erstellt: 2026-06-14
-- =============================================================================

UPDATE products SET is_published = false
WHERE slug IN (
  'renpho-led-gesichtsmaske-rotlicht',
  'ems-gua-sha-gesichtsmassagegeraet-elektrisch',
  'tessan-universal-reiseadapter-weltweit'
);
