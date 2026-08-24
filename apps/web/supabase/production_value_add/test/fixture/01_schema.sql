-- ============================================================================
-- FIXTURE 01 — Production-aehnliches Schema (Stand VOR 02_migrate_value_add)
-- ============================================================================
-- Abgeleitet aus:
--   supabase/schema.sql                  (categories, products, page_content,
--                                         discovery_queue)
--   supabase/add_shop_fields.sql,
--   add_shop_tags.sql, add_video_url.sql (Shop-Taxonomie)
--   supabase/pilot_staging_bootstrap.sql (vollstaendiger DbProduct-Spaltensatz)
--   lib/db-types.ts                      (Feldnamen und Typen)
--
-- Bewusst OHNE die acht Value-Add-Spalten und ohne die beiden CHECK-Constraints:
-- genau diesen Zustand hat der Production-Preflight am 2026-08-23 gemeldet
-- (0/8 Spalten, 0/2 Constraints). 02_migrate_value_add.sql muss sie anlegen.
--
-- Der Fingerprint, den alle Guards pruefen, verlangt public.products,
-- public.page_content, public.discovery_queue und public.swipes.
-- ============================================================================

create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  name        text not null,
  description text,
  emoji       text,
  sort_order  integer default 0,
  created_at  timestamptz default now()
);

create table public.products (
  id                 uuid primary key default gen_random_uuid(),
  category_id        uuid references public.categories(id) on delete set null,
  slug               text unique not null,
  name               text not null,
  tagline            text,
  description        text,
  price_cents        integer,
  currency           text default 'EUR',
  affiliate_url      text not null,
  image_url          text,
  image_urls         text[],
  is_published       boolean default false,
  is_featured        boolean default false,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now(),
  shop_persona       text,
  shop_main_category text,
  shop_sub_category  text,
  amazon_category    text,
  brand              text,
  shop_tags          text[],
  video_url          text,
  editorial_note     text
);

create table public.lists (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,
  title         text not null,
  intro         text,
  body          text,
  product_slugs text[] not null default '{}',
  is_published  boolean default false,
  created_at    timestamptz default now()
);

create table public.page_content (
  id          uuid primary key default gen_random_uuid(),
  page_key    text unique not null,
  title       text,
  intro       text,
  body        text,
  meta_title  text,
  meta_desc   text,
  updated_at  timestamptz default now()
);

create table public.discovery_queue (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  source_url text,
  notes      text,
  status     text default 'pending'
               check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now()
);

-- /entdecken speichert Swipes. Fuer den Value-Add-Pfad inhaltlich irrelevant,
-- aber Teil des Production-Fingerprints in jedem Guard.
create table public.swipes (
  id           uuid primary key default gen_random_uuid(),
  product_slug text not null,
  direction    text not null check (direction in ('like', 'skip')),
  session_id   text,
  created_at   timestamptz default now()
);

create index products_is_published_idx  on public.products (is_published);
create index products_persona_maincat_idx
  on public.products (shop_persona, shop_main_category);
create index products_shop_tags_gin     on public.products using gin (shop_tags);
create index lists_product_slugs_gin    on public.lists using gin (product_slugs);

-- ----------------------------------------------------------------------------
-- Grants wie auf Production: dort meldete 01_preflight app_grants_products = 14,
-- also die vollen sieben Privilegien je App-Rolle (Supabase-Default
-- "Automatically expose new tables"). Der Pilot ist absichtlich strenger; hier
-- wird Production nachgebildet, nicht der Pilot.
-- ----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
grant all privileges on public.products    to anon, authenticated, service_role;
grant all privileges on public.categories  to anon, authenticated, service_role;
grant all privileges on public.lists       to anon, authenticated, service_role;
grant all privileges on public.page_content     to anon, authenticated, service_role;
grant all privileges on public.discovery_queue  to anon, authenticated, service_role;
grant all privileges on public.swipes           to anon, authenticated, service_role;

-- RLS mit genau zwei Policies auf products — der Production-Preflight meldete
-- products_rls = true und products_policies = 2.
alter table public.products enable row level security;

create policy "public_read_published_products"
  on public.products for select to anon, authenticated
  using (is_published = true);

create policy "service_role_full_products"
  on public.products for all to service_role
  using (true) with check (true);
