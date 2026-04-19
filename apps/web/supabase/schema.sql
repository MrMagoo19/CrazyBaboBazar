-- ============================================================
-- CrazyBaboBazar – MVP Schema
-- ============================================================

-- CATEGORIES
create table categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  name        text not null,
  description text,
  emoji       text,
  sort_order  integer default 0,
  created_at  timestamptz default now()
);

-- PRODUCTS
create table products (
  id              uuid primary key default gen_random_uuid(),
  category_id     uuid references categories(id) on delete set null,
  slug            text unique not null,
  name            text not null,
  tagline         text,
  description     text,
  price_cents     integer,          -- Preis in Cent (z.B. 1999 = 19,99 €)
  currency        text default 'EUR',
  affiliate_url   text not null,
  image_url       text,
  is_published    boolean default false,
  is_featured     boolean default false,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- PAGE CONTENT (für CMS-artige Texte auf Kategorie- und Guide-Seiten)
create table page_content (
  id          uuid primary key default gen_random_uuid(),
  page_key    text unique not null,  -- z.B. 'category:lustige-gadgets' oder 'guide:bestes-buero-gadget'
  title       text,
  intro       text,
  body        text,
  meta_title  text,
  meta_desc   text,
  updated_at  timestamptz default now()
);

-- DISCOVERY QUEUE (manuelle Produktideen / Kandidaten vor Review)
create table discovery_queue (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  source_url    text,
  notes         text,
  status        text default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at    timestamptz default now()
);

-- ============================================================
-- BEISPIELDATEN
-- ============================================================

-- 5 Kategorien
insert into categories (slug, name, description, emoji, sort_order) values
  ('lustige-gadgets',       'Lustige Gadgets',        'Kuriose und witzige Produkte für jeden Anlass',    '😂', 1),
  ('geschenke-maenner',     'Geschenke für Männer',   'Coole Geschenkideen für Männer jeden Alters',      '🎁', 2),
  ('buero-gadgets',         'Büro-Gadgets',           'Smarte Helfer für den Schreibtisch',               '💼', 3),
  ('kuechen-gadgets',       'Küchen-Gadgets',         'Praktische und verrückte Küchenhelfer',            '🍳', 4),
  ('geschenke-unter-20',    'Geschenke unter 20 €',   'Die besten Geschenke für kleines Budget',         '💶', 5);

-- 3 Produkte
insert into products (category_id, slug, name, tagline, description, price_cents, affiliate_url, image_url, is_published, is_featured)
values
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'sprechender-kaktus',
    'Sprechender Kaktus',
    'Der Kaktus, der mehr redet als du',
    'Dieser animierte Kaktus wiederholt alles was du sagst – in einer quietschigen Stimme. Pflege nicht nötig.',
    2499,
    'https://example.com/affiliate/kaktus',
    '/images/products/kaktus.jpg',
    true,
    true
  ),
  (
    (select id from categories where slug = 'buero-gadgets'),
    'usb-mini-kuehlschrank',
    'USB Mini-Kühlschrank',
    'Kalte Getränke direkt am Schreibtisch',
    'Kleiner Kühlschrank der per USB betrieben wird. Fasst 2 Dosen. Ideal für lange Meeting-Tage.',
    3499,
    'https://example.com/affiliate/mini-kuehlschrank',
    '/images/products/mini-kuehlschrank.jpg',
    true,
    false
  ),
  (
    (select id from categories where slug = 'geschenke-unter-20'),
    'magnetische-bausteine',
    'Magnetische Bausteine (32-teilig)',
    'Für Erwachsene die heimlich spielen wollen',
    'Hochwertiges Magnetbaustein-Set für Schreibtisch und Zuhause. Stresslöser und Kreativitätskick in einem.',
    1799,
    'https://example.com/affiliate/magnetbausteine',
    '/images/products/magnetbausteine.jpg',
    true,
    false
  );
