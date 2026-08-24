-- ============================================================================
-- PRODUCTION VALUE-ADD — 07 DOWN-MIGRATION (DESTRUKTIV)
-- ============================================================================
-- Nur nach erfolgreich verifiziertem 06_restore_value_add.sql und mit einer
-- weiteren ausdruecklichen Benutzerfreigabe ausfuehren.
-- Entfernt nur die 8 Value-Add-Spalten und 2 Constraints. editorial_note und
-- updated_at werden NIEMALS entfernt. Der private Snapshot bleibt bestehen.
-- Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  product_rows bigint;
  target_rows integer;
  relation_rows integer;
  backup_rows integer;
  mismatch_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Production-Down abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Production-Down abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Production-Down abgebrochen: nur % Produkte (< 300).', product_rows;
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
  );
  if target_rows <> 10 then
    raise exception 'Production-Down abgebrochen: %/10 Zielprodukte vorhanden.', target_rows;
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
    raise exception 'Production-Down abgebrochen: %/5 Relationsziele published.', relation_rows;
  end if;

  select count(*) into column_rows
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
  select count(*) into constraint_rows
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );
  if column_rows <> 8 or correct_types <> 8 or constraint_rows <> 2 then
    raise exception 'Production-Down abgebrochen: Migration unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Production-Down abgebrochen: privater Snapshot v1 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  if backup_rows <> 10 then
    raise exception 'Production-Down abgebrochen: Snapshot hat %/10 Zeilen.', backup_rows;
  end if;

  select count(*) into mismatch_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind;
  if mismatch_rows <> 0 then
    raise exception 'Production-Down abgebrochen: Restore nicht exakt (% Abweichungen).',
      mismatch_rows;
  end if;
end $$;

-- Restore-Zustand unter Zeilensperre unmittelbar vor dem destruktiven DDL
-- erneut bestaetigen.
do $$
declare
  locked_rows integer;
  mismatch_rows integer;
  value_add_rows integer;
begin
  perform p.id
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Production-Down abgebrochen: nur %/10 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  select count(*) into mismatch_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind;
  if mismatch_rows <> 0 then
    raise exception 'Production-Down abgebrochen: Restore driftete vor DDL (% Abweichungen).',
      mismatch_rows;
  end if;

  select count(*) into value_add_rows
  from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_rows <> 0 then
    raise exception 'Production-Down abgebrochen: % Produktzeilen tragen noch Value-Add-Daten.',
      value_add_rows;
  end if;
end $$;

create temporary table cbb_value_add_down_state
on commit drop
as select count(*)::bigint as products_before from public.products;

alter table public.products
  drop constraint products_alternative_relation_check,
  drop constraint products_alternative_kind_check,
  drop column alternative_kind,
  drop column alternative_reason,
  drop column alternative_slug,
  drop column cons,
  drop column pros,
  drop column key_fact,
  drop column nicht_fuer,
  drop column fuer_wen;

do $$
declare
  saved_products_before bigint;
  products_after bigint;
  remaining_columns integer;
  remaining_constraints integer;
begin
  select s.products_before into saved_products_before
  from cbb_value_add_down_state s;
  select count(*) into products_after from public.products;
  select count(*) into remaining_columns
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );
  select count(*) into remaining_constraints
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );

  if products_after <> saved_products_before
     or remaining_columns <> 0
     or remaining_constraints <> 0 then
    raise exception
      'Production-Down inkonsistent: Produkte %/%, Spalten %, Constraints %.',
      products_after, saved_products_before, remaining_columns, remaining_constraints;
  end if;
end $$;

commit;
