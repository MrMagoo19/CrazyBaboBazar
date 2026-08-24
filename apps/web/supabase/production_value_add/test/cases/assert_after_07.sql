-- Nach 07_down_migration.sql: nur das Value-Add-Schema ist weg.
do $$
declare
  spalten integer;
  constraints integer;
  produkte bigint;
  gesamt_drift integer;
  snapshot_zeilen integer;
  payload_zeilen integer;
  trigger_da integer;
  policies integer;
  grants integer;
begin
  select count(*) into spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

  select count(*) into produkte from public.products;

  select count(*) into gesamt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.is_published is distinct from b.is_published
     or p.created_at is distinct from b.created_at;

  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_zeilen
  from cbb_private_backup.value_add_payload_v1;

  select count(*) into trigger_da from pg_trigger
  where tgrelid = 'public.products'::regclass and not tgisinternal
    and tgname = 'products_set_updated_at';

  select count(*) into policies from pg_policies
  where schemaname = 'public' and tablename = 'products';

  select count(*) into grants from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'products'
    and grantee in ('anon', 'authenticated');

  if spalten <> 0 or constraints <> 0 then
    raise exception 'nach 07: % Spalten, % Constraints uebrig (erwartet 0/0).',
      spalten, constraints;
  end if;
  if produkte <> 376 then
    raise exception 'nach 07: % Produkte (erwartet 376).', produkte;
  end if;
  if gesamt_drift <> 0 then
    raise exception 'nach 07: % von 376 Zeilen weichen von der Baseline ab.', gesamt_drift;
  end if;
  if snapshot_zeilen <> 10 or payload_zeilen <> 10 then
    raise exception 'nach 07: Snapshot % / Payload % (erwartet 10/10, beide bleiben erhalten).',
      snapshot_zeilen, payload_zeilen;
  end if;
  if trigger_da <> 1 then
    raise exception 'nach 07: products_set_updated_at wurde entfernt.';
  end if;
  if policies <> 2 or grants <> 14 then
    raise exception 'nach 07: RLS/Grants veraendert (% Policies, % Grants; erwartet 2/14).',
      policies, grants;
  end if;

  raise notice 'nach 07 OK: 0/8 Spalten, 0/2 Constraints, 376 Produkte, 0 Drift, Snapshot+Payload 10/10, Trigger/Policies/Grants unveraendert.';
end $$;
