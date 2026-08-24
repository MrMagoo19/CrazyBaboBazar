-- ============================================================================
-- PRODUCTION VALUE-ADD — 02 ADDITIVE MIGRATION (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne ausdrueckliche Benutzerfreigabe und sichtbare
-- Dashboard-Zielpruefung: project/ydiihvzcxaaoqhmgoqvu
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- Fail closed: negativer Pilot-Guard plus Production-Fingerprint.
do $$
declare
  product_rows bigint;
  target_rows integer;
  relation_rows integer;
  existing_columns integer;
  correct_types integer;
  existing_constraints integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Production-Migration abgebrochen: Pilot-Artefakt gefunden.';
  end if;

  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Production-Migration abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Production-Migration abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Production-Migration abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  select count(*) into relation_rows
  from public.products
  where slug in (
    'ifixit-antistatik-matte-faltbar-esd',
    'divoom-minitoo-retro-pc-lautsprecher-pixel',
    'derayee-schaumstoff-wasserpistole',
    'aeropress-go-tragbare-kaffeemaschine',
    'cbdywvr-2in1-ladekabel-mit-staender'
  ) and is_published is true;
  if relation_rows <> 5 then
    raise exception 'Production-Migration abgebrochen: %/5 Relationsziele published.', relation_rows;
  end if;

  select count(*) into existing_columns
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );

  select count(*) into correct_types
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and (
      (column_name in (
        'fuer_wen', 'nicht_fuer', 'key_fact', 'alternative_slug',
        'alternative_reason', 'alternative_kind'
      ) and data_type = 'text' and udt_name = 'text')
      or
      (column_name in ('pros', 'cons')
        and data_type = 'ARRAY' and udt_name = '_text')
    );

  select count(*) into existing_constraints
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );

  if existing_columns = 8 and correct_types = 8 and existing_constraints = 2 then
    raise exception 'Production-Migration abgebrochen: Migration ist bereits vollstaendig vorhanden.';
  end if;

  if existing_columns <> 0 or correct_types <> 0 or existing_constraints <> 0 then
    raise exception
      'Production-Migration abgebrochen: Teilzustand (% Spalten, % Typen, % Constraints).',
      existing_columns, correct_types, existing_constraints;
  end if;
end $$;

create temporary table cbb_value_add_migration_state
on commit drop
as select count(*)::bigint as products_before from public.products;

alter table public.products
  add column fuer_wen           text,
  add column nicht_fuer         text,
  add column key_fact           text,
  add column pros               text[],
  add column cons               text[],
  add column alternative_slug   text,
  add column alternative_reason text,
  add column alternative_kind   text;

alter table public.products
  add constraint products_alternative_kind_check
    check (alternative_kind in ('alternative', 'complement')),
  add constraint products_alternative_relation_check
    check (
      (alternative_slug is null and alternative_reason is null and alternative_kind is null)
      or
      (alternative_slug is not null and alternative_reason is not null and alternative_kind is not null)
    );

do $$
declare
  saved_products_before bigint;
  products_after bigint;
  existing_columns integer;
  correct_types integer;
  existing_constraints integer;
begin
  select s.products_before into saved_products_before
  from cbb_value_add_migration_state s;
  select count(*) into products_after from public.products;

  select count(*) into existing_columns
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );

  select count(*) into correct_types
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and (
      (column_name in (
        'fuer_wen', 'nicht_fuer', 'key_fact', 'alternative_slug',
        'alternative_reason', 'alternative_kind'
      ) and data_type = 'text' and udt_name = 'text')
      or
      (column_name in ('pros', 'cons')
        and data_type = 'ARRAY' and udt_name = '_text')
    );

  select count(*) into existing_constraints
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );

  if products_after <> saved_products_before then
    raise exception 'Production-Migration inkonsistent: Produkte vorher %, nachher %.',
      saved_products_before, products_after;
  end if;
  if existing_columns <> 8 or correct_types <> 8 or existing_constraints <> 2 then
    raise exception
      'Production-Migration inkonsistent: % Spalten, % Typen, % Constraints.',
      existing_columns, correct_types, existing_constraints;
  end if;
end $$;

commit;
