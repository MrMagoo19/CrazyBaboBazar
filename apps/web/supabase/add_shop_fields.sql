-- Add shop categorization columns to products
alter table products
  add column if not exists shop_persona      text default 'unknown',
  add column if not exists shop_main_category text default 'sonstiges',
  add column if not exists shop_sub_category  text default 'ungeordnet',
  add column if not exists amazon_category    text,
  add column if not exists brand              text;

-- Index for persona-based filtering
create index if not exists idx_products_shop_persona on products(shop_persona);
