-- ============================================================================
-- FIXTURE 02 — Production-aehnlicher Datenbestand
-- ============================================================================
-- Zielbild ist der Zustand nach Value-Add Batch 2:
--   376 Produkte gesamt, 372 published
--   20 Produkte mit Value-Add-Daten (Batch 1 plus Batch 2)
--
-- Alle Texte sind Testdaten. Sie stammen nicht aus Production und werden nie
-- dorthin geschrieben — der Harness laeuft ausschliesslich gegen einen eigenen
-- lokalen Cluster ohne TCP-Port.
--
-- Die Klick-out-Dateien lesen von diesen Zeilen nur `count(*)`. Inhaltlich
-- relevant ist einzig, dass der Fingerprint stimmt und dass die
-- Value-Add-Befuellung bei 20 liegt — 01 und 03 pruefen genau diese Zahl als
-- Beleg, dass dieses Changeset die frueheren Chargen nicht anfasst.
-- ============================================================================

insert into public.categories (slug, name, emoji, sort_order) values
  ('lustige-gadgets', 'Lustige Gadgets', '😂', 1);

-- 20 Produkte mit vollstaendigen Value-Add-Daten (Batch 1 plus Batch 2).
insert into public.products (
  slug, name, description, price_cents, affiliate_url, is_published,
  shop_persona, shop_main_category, editorial_note,
  fuer_wen, nicht_fuer, key_fact, pros, cons, created_at, updated_at
)
select
  'valueadd-produkt-' || to_char(g, 'FM00'),
  'Value-Add-Produkt ' || g,
  'Testbeschreibung ' || g || '.',
  1000 + g * 7,
  'https://amzn.to/test-va-' || g,
  true,
  (array['babo', 'queen', 'miniboss'])[1 + (g % 3)],
  (array['tech', 'kueche', 'outdoor'])[1 + (g % 3)],
  'VA-NOTE ' || g,
  'VA fuer_wen ' || g,
  'VA nicht_fuer ' || g,
  'VA key_fact ' || g,
  array['VA pro ' || g || ' a', 'VA pro ' || g || ' b'],
  array['VA con ' || g],
  timestamptz '2026-01-10 09:00:00+00' + (g || ' days')::interval,
  timestamptz '2026-08-26 09:00:00+00'
from generate_series(1, 20) as g;

-- 356 weitere Produkte -> 376 gesamt. g = 1 bis 4 bleiben unpublished,
-- das ergibt 372 published wie auf Production am 2026-08-26.
insert into public.products (
  slug, name, description, price_cents, affiliate_url, is_published, is_featured,
  shop_persona, shop_main_category, editorial_note, category_id,
  created_at, updated_at
)
select
  'fuellprodukt-' || to_char(g, 'FM000'),
  'Füllprodukt ' || g,
  'Testbeschreibung für Füllprodukt ' || g || '.',
  case when g % 17 = 0 then null else 500 + (g * 37) % 24500 end,
  'https://amzn.to/test-fuell-' || g,
  g > 4,
  (g % 29) = 0,
  (array['babo', 'queen', 'miniboss'])[1 + (g % 3)],
  (array['tech', 'kueche', 'lifestyle', 'outdoor'])[1 + (g % 4)],
  case when g % 2 = 0 then 'ALT-NOTE fuell-' || g else null end,
  (select id from public.categories where slug = 'lustige-gadgets'),
  timestamptz '2025-09-01 08:00:00+00' + (g || ' hours')::interval,
  timestamptz '2026-04-01 08:00:00+00' + (g || ' minutes')::interval
from generate_series(1, 356) as g;

insert into public.lists (slug, title, intro, product_slugs, is_published) values
  ('fuer-den-schreibtisch', 'Für den Schreibtisch', 'Testintro.',
   array['valueadd-produkt-01', 'valueadd-produkt-02'], true);

insert into public.page_content (page_key, title, intro) values
  ('category:lustige-gadgets', 'Lustige Gadgets', 'Testintro.');

insert into public.discovery_queue (name, source_url, status) values
  ('Testkandidat A', 'https://example.invalid/a', 'pending');

insert into public.swipes (product_slug, direction, session_id) values
  ('valueadd-produkt-01', 'like', 'test-session-1');

-- Die privaten Value-Add-Artefakte bekommen je zehn Zeilen, damit ihr
-- Vorhandensein nicht nur strukturell, sondern auch inhaltlich belegt ist.
insert into cbb_private_backup.value_add_pre_backfill_v1 (id, slug)
select p.id, p.slug from public.products p
where p.slug like 'valueadd-produkt-%' and split_part(p.slug, '-', 3)::integer <= 10;

insert into cbb_private_backup.value_add_payload_v1 (slug)
select p.slug from public.products p
where p.slug like 'valueadd-produkt-%' and split_part(p.slug, '-', 3)::integer <= 10;

insert into cbb_private_backup.value_add_pre_backfill_v2 (id, slug)
select p.id, p.slug from public.products p
where p.slug like 'valueadd-produkt-%' and split_part(p.slug, '-', 3)::integer > 10;

insert into cbb_private_backup.value_add_payload_v2 (slug)
select p.slug from public.products p
where p.slug like 'valueadd-produkt-%' and split_part(p.slug, '-', 3)::integer > 10;
