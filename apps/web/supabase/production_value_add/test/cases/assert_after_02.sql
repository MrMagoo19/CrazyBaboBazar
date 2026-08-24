-- Nach 02_migrate_value_add.sql: Schema da, Daten unangetastet.
do $$
declare
  spalten integer;
  typen integer;
  constraints integer;
  produkte bigint;
  befuellt integer;
  note_drift integer;
  lastmod_drift integer;
begin
  select count(*) into spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');

  select count(*) into typen from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and ((column_name in ('fuer_wen', 'nicht_fuer', 'key_fact',
                          'alternative_slug', 'alternative_reason',
                          'alternative_kind')
          and data_type = 'text' and udt_name = 'text')
      or (column_name in ('pros', 'cons')
          and data_type = 'ARRAY' and udt_name = '_text'));

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

  select count(*) into produkte from public.products;

  select count(*) into befuellt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select count(*) into note_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note;

  select count(*) into lastmod_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.updated_at is distinct from b.updated_at;

  if spalten <> 8 or typen <> 8 or constraints <> 2 then
    raise exception 'nach 02: % Spalten, % Typen, % Constraints (erwartet 8/8/2).',
      spalten, typen, constraints;
  end if;
  if produkte <> 376 then
    raise exception 'nach 02: % Produkte (erwartet 376).', produkte;
  end if;
  if befuellt <> 0 then
    raise exception 'nach 02: % Zeilen tragen bereits Value-Add-Daten (erwartet 0).', befuellt;
  end if;
  if note_drift <> 0 or lastmod_drift <> 0 then
    raise exception 'nach 02: additive Migration hat Daten veraendert (% notes, % lastmods).',
      note_drift, lastmod_drift;
  end if;

  raise notice 'nach 02 OK: 8/8 Spalten, 2/2 Constraints, 376 Produkte, 0 befuellt, 0 Daten-Drift.';
end $$;
