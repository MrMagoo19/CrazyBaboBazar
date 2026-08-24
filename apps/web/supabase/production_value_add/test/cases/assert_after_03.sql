-- Nach 03_backup_value_add.sql: Snapshot vollstaendig, privat, inhaltsgleich.
do $$
declare
  zeilen integer;
  notes integer;
  drift integer;
  rls boolean;
  tabellen_grants integer;
  schema_grants integer;
  value_add_nicht_null integer;
begin
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'nach 03: Snapshot v1 fehlt.';
  end if;

  select count(*) into zeilen
  from cbb_private_backup.value_add_pre_backfill_v1;

  -- Die drei bestehenden Notizen muessen wortgleich im Snapshot liegen,
  -- sonst kann 06 sie spaeter nicht beweisbar zurueckholen.
  select count(*) into notes
  from cbb_private_backup.value_add_pre_backfill_v1 b
  join cbb_test_baseline.products_before z on z.id = b.id
  where b.editorial_note is not null
    and b.editorial_note = z.editorial_note;

  select count(*) into drift
  from cbb_private_backup.value_add_pre_backfill_v1 b
  join cbb_test_baseline.products_before z on z.id = b.id
  where b.editorial_note is distinct from z.editorial_note
     or b.updated_at is distinct from z.updated_at;

  select count(*) into value_add_nicht_null
  from cbb_private_backup.value_add_pre_backfill_v1
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select c.relrowsecurity into rls from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'cbb_private_backup'
    and c.relname = 'value_add_pre_backfill_v1';

  select count(*) into tabellen_grants
  from information_schema.role_table_grants
  where table_schema = 'cbb_private_backup'
    and table_name = 'value_add_pre_backfill_v1'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  select count(*) into schema_grants
  from information_schema.usage_privileges
  where object_schema = 'cbb_private_backup'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  if zeilen <> 10 then
    raise exception 'nach 03: Snapshot hat %/10 Zeilen.', zeilen;
  end if;
  if notes <> 3 then
    raise exception 'nach 03: % statt 3 bestehende editorial_note im Snapshot.', notes;
  end if;
  if drift <> 0 then
    raise exception 'nach 03: % Snapshot-Zeilen weichen von der Baseline ab.', drift;
  end if;
  if value_add_nicht_null <> 0 then
    raise exception 'nach 03: % Snapshot-Zeilen tragen bereits Value-Add-Daten.',
      value_add_nicht_null;
  end if;
  if rls is not true then
    raise exception 'nach 03: RLS auf dem Snapshot ist nicht aktiv.';
  end if;
  if tabellen_grants <> 0 then
    raise exception 'nach 03: % App-Grants auf dem Snapshot (erwartet 0).', tabellen_grants;
  end if;
  if schema_grants <> 0 then
    raise exception 'nach 03: % App-Grants auf dem Schema cbb_private_backup (erwartet 0).',
      schema_grants;
  end if;

  raise notice 'nach 03 OK: 10 Snapshot-Zeilen, 3 Original-Notizen, 0 Drift, RLS an, 0 App-Grants.';
end $$;
