-- ============================================================
-- Value-Add Produktseiten-Template — additive Migration
-- ============================================================
-- Fügt die strukturierten Kaufhilfe-Felder für das neue
-- Produktseiten-Template hinzu. ALLE Felder sind NULLABLE und
-- ohne DEFAULT: bestehende 372 Produkte bleiben unverändert und
-- rendern die neuen Blöcke schlicht nicht (graceful degradation).
--
-- Additive nullable Spalten ohne Default sind in Postgres ein reiner
-- Katalog-Eintrag (kein Table-Rewrite, nur kurzer ACCESS EXCLUSIVE Lock)
-- → unkritisch für den Live-Betrieb.
--
-- editorial_note wird bewusst NICHT global NOT NULL gesetzt (existiert
-- bereits auf 83 % der Zeilen). Der Pilot befüllt es nur für die 10
-- Pilotprodukte über backfill_pilot_value_add.sql.
-- ============================================================

alter table public.products
  add column if not exists fuer_wen           text,        -- "Am besten für" (1 Satz)
  add column if not exists nicht_fuer         text,        -- "Weniger geeignet für" (1 ehrlicher Contra)
  add column if not exists key_fact           text,        -- 1 Hard-Fact, im UI als Herstellerangabe gekennzeichnet
  add column if not exists pros               text[],      -- 2–4 Vorteile (konsistent mit shop_tags text[])
  add column if not exists cons               text[],      -- 1–3 ehrliche Nachteile
  add column if not exists alternative_slug   text,        -- loser Verweis auf products.slug (wie lists.product_slugs, keine FK)
  add column if not exists alternative_reason text,         -- 1 Satz WARUM dieser Verweis
  add column if not exists alternative_kind   text;         -- 'alternative' (echtes Ersatzprodukt) | 'complement' (Passt dazu)

-- alternative_kind darf nur zwei Werte (oder NULL) annehmen. CHECK auf frisch
-- angelegter, komplett NULL-gefüllter Spalte validiert sofort (kein Rewrite).
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

-- Alternative/Ergänzung nur als vollständige Relation zulassen. Alle drei
-- Spalten bleiben für Produkte ohne Relation gemeinsam NULL.
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

-- Hinweis zu alternative_slug:
-- Bewusst KEINE Foreign-Key-Constraint. Der Codebase-Konvention folgend
-- (lists.product_slugs ist ebenfalls ein loser text[]-Verweis ohne FK)
-- bleibt der Verweis lose. Referenz-Integrität wird stattdessen im
-- Backfill geprüft (siehe backfill_pilot_value_add.sql) und kann im
-- Template graceful behandelt werden (Alternative rendert nur, wenn das
-- Zielprodukt existiert und veröffentlicht ist).
