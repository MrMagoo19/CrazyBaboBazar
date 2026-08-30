-- ============================================================================
-- FIXTURE 01 — Production-aehnliches Schema, Stand NACH Value-Add Batch 2
-- ============================================================================
-- Abgeleitet aus:
--   supabase/schema.sql, add_shop_fields.sql, add_shop_tags.sql, add_video_url.sql
--   supabase/pilot_staging_bootstrap.sql          (vollstaendiger Spaltensatz)
--   lib/db-types.ts                               (Feldnamen und Typen)
--   production_value_add/02_migrate_value_add.sql (die acht Value-Add-Spalten)
--
-- Der Fingerprint, den alle Guards pruefen, verlangt public.products,
-- public.page_content, public.discovery_queue und public.swipes.
--
-- WICHTIG FUER DIESEN HARNESS: die Default-Privilegien werden wie auf Supabase
-- nachgebaut. Dort bekommen neue Tabellen in `public` automatisch alle Rechte
-- fuer anon, authenticated und service_role. Genau das muss 02 wieder entziehen
-- — ohne diese Default-Privilegien waere der REVOKE-Test wertlos, weil gar
-- nichts zu entziehen waere.
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
  editorial_note     text,
  fuer_wen           text,
  nicht_fuer         text,
  key_fact           text,
  pros               text[],
  cons               text[],
  alternative_slug   text,
  alternative_reason text,
  alternative_kind   text
);

alter table public.products
  add constraint products_alternative_kind_check
    check (alternative_kind in ('alternative', 'complement')),
  add constraint products_alternative_relation_check
    check (
      (alternative_slug is null and alternative_reason is null and alternative_kind is null)
      or
      (alternative_slug is not null and alternative_reason is not null and alternative_kind is not null)
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
  id         uuid primary key default gen_random_uuid(),
  page_key   text unique not null,
  title      text,
  intro      text,
  body       text,
  meta_title text,
  meta_desc  text,
  updated_at timestamptz default now()
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

create table public.swipes (
  id           uuid primary key default gen_random_uuid(),
  product_slug text not null,
  direction    text not null check (direction in ('like', 'skip')),
  session_id   text,
  created_at   timestamptz default now()
);

create index products_is_published_idx on public.products (is_published);

-- ----------------------------------------------------------------------------
-- Grants wie auf Production: dort meldete der Value-Add-Preflight
-- app_grants_products = 14, also die vollen sieben Privilegien je App-Rolle
-- (Supabase-Default "Automatically expose new tables").
-- ----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
grant all privileges on public.products        to anon, authenticated, service_role;
grant all privileges on public.categories      to anon, authenticated, service_role;
grant all privileges on public.lists           to anon, authenticated, service_role;
grant all privileges on public.page_content    to anon, authenticated, service_role;
grant all privileges on public.discovery_queue to anon, authenticated, service_role;
grant all privileges on public.swipes          to anon, authenticated, service_role;

-- DAS ist der entscheidende Teil fuer diesen Harness: neue Tabellen in `public`
-- bekommen automatisch alle Rechte. 02_create_clickouts.sql muss sie danach
-- explizit wieder entziehen.
alter default privileges in schema public
  grant all privileges on tables to anon, authenticated, service_role;

alter table public.products enable row level security;

create policy "public_read_published_products"
  on public.products for select to anon, authenticated
  using (is_published = true);

create policy "service_role_full_products"
  on public.products for all to service_role
  using (true) with check (true);

-- ----------------------------------------------------------------------------
-- Die privaten Value-Add-Artefakte aus Batch 1 und Batch 2.
-- Die Klick-out-Dateien fassen sie nie an — 01, 03 und 05 belegen genau das.
-- ----------------------------------------------------------------------------
create schema cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

create table cbb_private_backup.value_add_pre_backfill_v1 (
  id uuid primary key, slug text unique not null, editorial_note text,
  updated_at timestamptz, fuer_wen text, nicht_fuer text, key_fact text,
  pros text[], cons text[], alternative_slug text, alternative_reason text,
  alternative_kind text
);
create table cbb_private_backup.value_add_payload_v1 (
  slug text primary key, fuer_wen text, nicht_fuer text, key_fact text,
  pros text[], cons text[], alternative_slug text, alternative_reason text,
  alternative_kind text, editorial_note text
);
create table cbb_private_backup.value_add_pre_backfill_v2 (
  id uuid primary key, slug text unique not null, editorial_note text,
  updated_at timestamptz, fuer_wen text, nicht_fuer text, key_fact text,
  pros text[], cons text[], alternative_slug text, alternative_reason text,
  alternative_kind text
);
create table cbb_private_backup.value_add_payload_v2 (
  slug text primary key, fuer_wen text, nicht_fuer text, key_fact text,
  pros text[], cons text[], alternative_slug text, alternative_reason text,
  alternative_kind text, editorial_note text
);

alter table cbb_private_backup.value_add_pre_backfill_v1 enable row level security;
alter table cbb_private_backup.value_add_payload_v1      enable row level security;
alter table cbb_private_backup.value_add_pre_backfill_v2 enable row level security;
alter table cbb_private_backup.value_add_payload_v2      enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v1 from public, anon, authenticated;
revoke all on cbb_private_backup.value_add_payload_v1      from public, anon, authenticated;
revoke all on cbb_private_backup.value_add_pre_backfill_v2 from public, anon, authenticated;
revoke all on cbb_private_backup.value_add_payload_v2      from public, anon, authenticated;
