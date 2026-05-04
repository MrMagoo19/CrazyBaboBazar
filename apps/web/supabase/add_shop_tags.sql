-- Migration: shop_tags array für Multi-Kategorisierung
ALTER TABLE products ADD COLUMN IF NOT EXISTS shop_tags text[] DEFAULT '{}';

-- Index für schnelle Array-Suche (@> contains operator)
CREATE INDEX IF NOT EXISTS idx_products_shop_tags ON products USING GIN (shop_tags);
