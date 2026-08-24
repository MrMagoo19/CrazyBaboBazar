-- ============================================================
-- PILOT-/STAGING-BOOTSTRAP — Minimalschema für die Produktseiten-Pilotvorschau
-- ============================================================
-- STATUS: ENTWURF — NICHT AUSGEFÜHRT.
-- Ziel: ausschließlich das Pilot-/Staging-Supabase-Projekt. NIEMALS Production.
--
-- Zweck
--   Legt in einer leeren Pilot-DB genau die Tabellen, Spalten, Indizes,
--   Grants und RLS-Policies an, die die lokale Web-App braucht, um
--     • die 10 Pilot-Produktseiten,
--     • deren 5 Alternative-/Passt-dazu-Ziele und
--     • 5 unveränderte Kontrollseiten
--   mit dem Publishable-/Anon-Key zu rendern.
--
-- Abgeleitet aus dem echten Code, nicht aus einem DB-Dump:
--   lib/db.ts                 — alle Queries der öffentlichen Seiten
--   lib/db-types.ts           — DbProduct / DbCategory / DbList
--   app/produkt/[slug]/page.tsx — welche Felder die Produktseite rendert
--   supabase/add_value_add_fields.sql — die neuen Value-Add-Spalten
--
-- Bewusst NICHT enthalten (vom Pilot nicht benötigt):
--   page_content, discovery_queue — von keiner Produktseiten-Query gelesen.
--   Guides liegen als TypeScript in lib/guides/ und brauchen keine Tabelle.
--   swipes — /entdecken und /entdecken/likes sind nicht Teil des
--   Produktseiten-Piloten und funktionieren in dieser Minimal-DB nicht.
--   seo_updated_at_trigger — die Vorschau prüft Darstellung/Datenzugriff,
--   nicht den später separat zu auditierenden Production-lastmod-Pfad.
--
-- Idempotent: mehrfaches Ausführen ist unschädlich (if not exists /
-- drop policy if exists). Auf einer leeren DB läuft die Datei komplett durch.
--
-- Ausführen NUR über den SQL-Editor des Pilot-Projekts oder eine explizit auf
-- das Pilot-Projekt gerichtete Verbindung. Diese Datei enthält keine
-- Verbindungsdaten, keine Keys und keine Projekt-URL — die Zielumgebung
-- bestimmt allein, wo sie ausgeführt wird.
-- ============================================================

begin;

-- DB-seitiger Umgebungs-Guard. Beim ersten Lauf sind die drei öffentlichen
-- Pilottabellen zwingend noch nicht vorhanden. Wiederholungsläufe sind nur
-- erlaubt, wenn der Bootstrap zuvor den privaten Marker mit exakt der
-- freigegebenen Pilot-Ref angelegt hat. Damit bricht die Datei auf der
-- bestehenden Production-DB ab, bevor Rechte, RLS oder Tabellen verändert
-- werden.
do $$
declare
  marker_valid boolean := false;
  existing_target_tables integer;
begin
  select count(*) into existing_target_tables
  from information_schema.tables
  where table_schema = 'public'
    and table_name in ('categories', 'products', 'lists');

  if to_regclass('pilot_meta.environment_guard') is not null then
    execute 'select exists (
      select 1 from pilot_meta.environment_guard
      where project_ref = ''nmzuycveumyfvtxdcnuc''
    )' into marker_valid;

    if not marker_valid then
      raise exception 'Pilot-Bootstrap abgebrochen: vorhandener Umgebungsmarker passt nicht zur Pilot-Ref.';
    end if;
  end if;

  if not marker_valid and existing_target_tables <> 0 then
    raise exception 'Pilot-Bootstrap abgebrochen: % Zieltabelle(n) existieren ohne gültigen Pilot-Marker.', existing_target_tables;
  end if;
end $$;

create schema if not exists pilot_meta;
revoke all on schema pilot_meta from public, anon, authenticated;

create table if not exists pilot_meta.environment_guard (
  project_ref text primary key,
  created_at timestamptz not null default now(),
  constraint pilot_environment_ref_check
    check (project_ref = 'nmzuycveumyfvtxdcnuc')
);

revoke all on pilot_meta.environment_guard from public, anon, authenticated;
alter table pilot_meta.environment_guard enable row level security;

insert into pilot_meta.environment_guard (project_ref)
values ('nmzuycveumyfvtxdcnuc')
on conflict (project_ref) do nothing;

-- ============================================================
-- 1) TABELLEN
-- ============================================================

-- ── categories ──────────────────────────────────────────────
-- Zwingend, auch wenn die meisten Pilotprodukte category_id = NULL haben:
-- jede Produkt-Query in lib/db.ts selektiert `*, categories(*)`. Fehlt die
-- Tabelle, schlägt der Embed fehl, die Query liefert null und die
-- Produktseite läuft in notFound().
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  name        text not null,
  description text,
  emoji       text,
  sort_order  integer default 0,
  created_at  timestamptz default now()
);

-- ── products ────────────────────────────────────────────────
-- Spaltensatz = DbProduct (lib/db-types.ts) minus dem eingebetteten
-- categories-Objekt, das aus dem Join stammt.
create table if not exists public.products (
  id                 uuid primary key default gen_random_uuid(),
  category_id        uuid references public.categories(id) on delete set null,
  slug               text unique not null,
  name               text not null,
  tagline            text,
  description        text,
  price_cents        integer,                 -- Preis in Cent; UI zeigt nur ein Preisband
  currency           text default 'EUR',
  affiliate_url      text not null,
  image_url          text,
  image_urls         text[],                  -- >1 Bild → ImageSlider statt Einzelbild
  is_published       boolean default false,
  is_featured        boolean default false,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now(),

  -- Shop-Taxonomie: steuert Breadcrumb, Persona-Hub-Link und die
  -- "Könnte dich auch interessieren"-Auswahl (getRelatedProducts).
  shop_persona       text,                    -- 'babo' | 'queen' | 'miniboss'
  shop_main_category text,
  shop_sub_category  text,
  amazon_category    text,
  brand              text,                    -- einzige Quelle für schema.org Brand
  shop_tags          text[],                  -- 'persona:kategorie', per contains() abgefragt

  video_url          text,                    -- optionaler Embed-Block
  editorial_note     text,                    -- "Unser Urteil"

  -- ── Value-Add-Template-Felder ─────────────────────────────
  -- Identisch zu supabase/add_value_add_fields.sql: alle nullable, ohne
  -- Default. Bleiben nach dem Seed leer und werden erst durch
  -- backfill_pilot_value_add.sql befüllt — so testet der Pilot denselben
  -- Migrations- und Backfill-Pfad, der später auf Production laufen soll.
  fuer_wen           text,                    -- "Am besten für"
  nicht_fuer         text,                    -- "Weniger geeignet für"
  key_fact           text,                    -- Herstellerangabe, im UI gekennzeichnet
  pros               text[],
  cons               text[],
  alternative_slug   text,                    -- loser Verweis auf products.slug, bewusst ohne FK
  alternative_reason text,
  alternative_kind   text                     -- 'alternative' | 'complement'
);

-- Nachrüsten, falls die Tabelle aus einem älteren Stand bereits existiert.
alter table public.products
  add column if not exists image_urls         text[],
  add column if not exists shop_persona       text,
  add column if not exists shop_main_category text,
  add column if not exists shop_sub_category  text,
  add column if not exists amazon_category    text,
  add column if not exists brand              text,
  add column if not exists shop_tags          text[],
  add column if not exists video_url          text,
  add column if not exists editorial_note     text,
  add column if not exists fuer_wen           text,
  add column if not exists nicht_fuer         text,
  add column if not exists key_fact           text,
  add column if not exists pros               text[],
  add column if not exists cons               text[],
  add column if not exists alternative_slug   text,
  add column if not exists alternative_reason text,
  add column if not exists alternative_kind   text;

-- alternative_kind darf nur zwei Werte (oder NULL) annehmen — wortgleich zu
-- add_value_add_fields.sql, damit Pilot und spätere Production identisch sind.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_alternative_kind_check'
      and conrelid = 'public.products'::regclass
      and contype = 'c'
  ) then
    alter table public.products
      add constraint products_alternative_kind_check
      check (alternative_kind in ('alternative', 'complement'));
  end if;
end $$;

-- Relation ist entweder vollständig gesetzt oder vollständig leer. Dadurch
-- kann das Template niemals einen gesetzten Slug mit falschem/fehlendem Label
-- oder ohne Begründung rendern.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_alternative_relation_check'
      and conrelid = 'public.products'::regclass
      and contype = 'c'
  ) then
    alter table public.products
      add constraint products_alternative_relation_check
      check (
        (alternative_slug is null and alternative_reason is null and alternative_kind is null)
        or
        (alternative_slug is not null and alternative_reason is not null and alternative_kind is not null)
      );
  end if;
end $$;

-- ── lists ───────────────────────────────────────────────────
-- Nötig für den "Enthalten in Listen & Guides"-Block der Produktseite
-- (getListsForProduct, lib/db.ts). Ohne die Tabelle liefert PostgREST einen
-- Fehler, der Block bliebe dauerhaft leer — der Pilot wäre nicht bewertbar.
create table if not exists public.lists (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,
  title         text not null,
  intro         text,
  body          text,
  product_slugs text[] not null default '{}',  -- loser Verweis auf products.slug, ohne FK
  is_published  boolean default false,
  created_at    timestamptz default now()
);

-- ============================================================
-- 2) INDIZES
-- ============================================================
-- Bei 20 Zeilen irrelevant für die Laufzeit, aber sie halten das Pilotschema
-- deckungsgleich mit dem, was auf Production sinnvoll ist.

create index if not exists products_is_published_idx
  on public.products (is_published);

-- getRelatedProducts / getProductsByPersona filtern auf diese Kombination.
create index if not exists products_persona_maincat_idx
  on public.products (shop_persona, shop_main_category);

-- shop_tags.cs.{...} und product_slugs @> ARRAY[...] brauchen GIN.
create index if not exists products_shop_tags_gin
  on public.products using gin (shop_tags);

create index if not exists lists_product_slugs_gin
  on public.lists using gin (product_slugs);

-- ============================================================
-- 3) GRANTS
-- ============================================================
-- Im Pilotprojekt ist "Automatically expose new tables" deaktiviert: neue
-- Tabellen bekommen keine Rechte für anon/authenticated und sind über die
-- Data API nicht erreichbar. Deshalb hier explizit — und ausschließlich SELECT.
-- Kein insert/update/delete, keine Sequenzen, keine Funktionen.

grant usage on schema public to anon, authenticated;

revoke all on public.categories from public, anon, authenticated;
revoke all on public.products   from public, anon, authenticated;
revoke all on public.lists      from public, anon, authenticated;

grant select on public.categories to anon, authenticated;
grant select on public.products   to anon, authenticated;
grant select on public.lists      to anon, authenticated;

-- ============================================================
-- 4) ROW LEVEL SECURITY
-- ============================================================
-- RLS ist im Pilotprojekt aktiv. Ohne passende Policy liefert jede Query eine
-- leere Menge — die Produktseiten liefen alle in notFound().
-- Es gibt ausschließlich SELECT-Policies. Für anon und authenticated
-- existiert bewusst KEINE Policy für insert, update oder delete: die
-- Pilotvorschau liest nur.

alter table public.categories enable row level security;
alter table public.products   enable row level security;
alter table public.lists      enable row level security;

-- Kategorien sind reine Anzeigedaten (Name, Emoji, Breadcrumb-Ziel).
drop policy if exists "pilot_public_read_categories" on public.categories;
create policy "pilot_public_read_categories"
  on public.categories
  for select
  to anon, authenticated
  using (true);

-- Nur veröffentlichte Produkte sind sichtbar. Wichtig, weil getProductBySlug
-- selbst NICHT auf is_published filtert (lib/db.ts): die Policy ist die
-- einzige Stelle, die einen unveröffentlichten Entwurf davor bewahrt, unter
-- /produkt/<slug> öffentlich erreichbar zu sein. Gilt auch für das per
-- alternative_slug nachgeladene Zielprodukt.
drop policy if exists "pilot_public_read_published_products" on public.products;
create policy "pilot_public_read_published_products"
  on public.products
  for select
  to anon, authenticated
  using (is_published = true);

-- Analog für Listen; getAllLists/getListBySlug filtern zwar zusätzlich selbst
-- auf is_published, die Policy zieht die Grenze aber serverseitig.
drop policy if exists "pilot_public_read_published_lists" on public.lists;
create policy "pilot_public_read_published_lists"
  on public.lists
  for select
  to anon, authenticated
  using (is_published = true);

commit;

-- PostgREST hält den Schema-Cache im Speicher. Supabase lädt ihn nach DDL
-- normalerweise selbst neu; dieser Anstoß stellt sicher, dass die neuen
-- Tabellen der Data API sofort bekannt sind und die erste Anfrage der
-- lokalen App nicht mit "relation does not exist" zurückkommt.
notify pgrst, 'reload schema';

-- ============================================================
-- VERIFIKATION (read-only, nach dem Bootstrap ausführen)
-- ============================================================
-- (a) Tabellen da? Erwartet: categories, lists, products.
-- select table_name from information_schema.tables
-- where table_schema = 'public' and table_name in ('categories','products','lists')
-- order by table_name;
--
-- (b) RLS überall aktiv? Erwartet: 3 Zeilen, rowsecurity = true.
-- select relname, relrowsecurity from pg_class
-- where relnamespace = 'public'::regnamespace
--   and relname in ('categories','products','lists');
--
-- (c) Nur SELECT-Policies? Erwartet: 3 Zeilen, cmd = 'SELECT'.
-- select tablename, policyname, cmd, roles from pg_policies
-- where schemaname = 'public' order by tablename;
--
-- (d) Keine Schreibrechte für anon/authenticated? Erwartet: 0 Zeilen.
-- select grantee, table_name, privilege_type
-- from information_schema.role_table_grants
-- where table_schema = 'public'
--   and grantee in ('anon','authenticated')
--   and privilege_type <> 'SELECT';
--
-- (e) Value-Add-Spalten vorhanden? Erwartet: 8 Zeilen.
-- select column_name, data_type, is_nullable from information_schema.columns
-- where table_schema = 'public' and table_name = 'products'
--   and column_name in ('fuer_wen','nicht_fuer','key_fact','pros','cons',
--                       'alternative_slug','alternative_reason','alternative_kind')
-- order by column_name;
--
-- (f) Privater Zielmarker korrekt? Erwartet: exakt 1 Zeile mit der Pilot-Ref.
-- select project_ref from pilot_meta.environment_guard;
--
-- Vollständiger Ablauf (siehe PILOT_ENVIRONMENT.md):
--   1) pilot_staging_bootstrap.sql (diese Datei)
--   2) pilot_staging_seed.sql
--   3) backup_pilot_value_add.sql
--   4) backfill_pilot_value_add.sql
