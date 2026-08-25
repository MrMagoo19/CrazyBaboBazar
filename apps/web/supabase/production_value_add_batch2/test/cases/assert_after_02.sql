-- Nach 02_backup_value_add_batch2.sql: Snapshot v2 vollstaendig, privat,
-- inhaltsgleich mit der Baseline, und der Bestand ist unveraendert.
do $$
declare
  zeilen integer;
  drift integer;
  value_add_nicht_null integer;
  notes integer;
  rls boolean;
  policies integer;
  pk integer;
  slug_unique integer;
  spalten integer;
  tabellen_grants integer;
  schema_grants integer;
  payload_v2_da boolean;
  bestand_drift integer;
begin
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'nach 02: Snapshot v2 fehlt.';
  end if;

  select count(*) into zeilen
  from cbb_private_backup.value_add_pre_backfill_v2;

  -- Der Snapshot muss die Baseline exakt abbilden — sonst kann 05 die
  -- Originaltexte und -zeitstempel spaeter nicht beweisbar zurueckholen.
  select count(*) into drift
  from cbb_private_backup.value_add_pre_backfill_v2 b
  join cbb_test_baseline.products_before z on z.id = b.id
  where b.slug is distinct from z.slug
     or b.editorial_note is distinct from z.editorial_note
     or b.updated_at is distinct from z.updated_at
     or b.fuer_wen is distinct from z.fuer_wen
     or b.nicht_fuer is distinct from z.nicht_fuer
     or b.key_fact is distinct from z.key_fact
     or b.pros is distinct from z.pros
     or b.cons is distinct from z.cons
     or b.alternative_slug is distinct from z.alternative_slug
     or b.alternative_reason is distinct from z.alternative_reason
     or b.alternative_kind is distinct from z.alternative_kind;

  select count(*) into value_add_nicht_null
  from cbb_private_backup.value_add_pre_backfill_v2
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  -- Die zwei bestehenden ALT-NOTE-Texte muessen wortgleich im Snapshot liegen.
  select count(*) into notes
  from cbb_private_backup.value_add_pre_backfill_v2 b
  join cbb_test_baseline.products_before z on z.id = b.id
  where b.editorial_note is not null
    and b.editorial_note = z.editorial_note
    and b.editorial_note like 'ALT-NOTE%';

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid),
         (select count(*) from pg_constraint con
            where con.conrelid = c.oid and con.contype = 'p'),
         (select count(*) from pg_constraint con
            where con.conrelid = c.oid and con.contype = 'u'),
         (select count(*) from pg_attribute a
            where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped)
  into rls, policies, pk, slug_unique, spalten
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v2'::regclass;

  select count(*) into tabellen_grants
  from information_schema.role_table_grants
  where table_schema = 'cbb_private_backup'
    and table_name = 'value_add_pre_backfill_v2'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  select count(*) into schema_grants
  from information_schema.usage_privileges
  where object_schema = 'cbb_private_backup'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  select to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into payload_v2_da;

  -- 02 ist ein reiner Lese-plus-Kopier-Schritt: der Bestand darf sich in
  -- KEINER der 376 Zeilen veraendert haben.
  select count(*) into bestand_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
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

  if zeilen <> 10 then
    raise exception 'nach 02: Snapshot v2 hat %/10 Zeilen.', zeilen;
  end if;
  if drift <> 0 then
    raise exception 'nach 02: % Snapshot-Zeilen weichen von der Baseline ab.', drift;
  end if;
  if value_add_nicht_null <> 0 then
    raise exception 'nach 02: % Snapshot-Zeilen tragen bereits Value-Add-Daten.',
      value_add_nicht_null;
  end if;
  if notes <> 2 then
    raise exception 'nach 02: % statt 2 bestehende ALT-NOTE im Snapshot.', notes;
  end if;
  if spalten <> 12 then
    raise exception 'nach 02: Snapshot v2 hat % Spalten, erwartet 12.', spalten;
  end if;
  if rls is not true then
    raise exception 'nach 02: RLS auf dem Snapshot v2 ist nicht aktiv.';
  end if;
  if policies <> 0 then
    raise exception 'nach 02: % Policies auf dem Snapshot v2 (erwartet 0).', policies;
  end if;
  if pk <> 1 or slug_unique <> 1 then
    raise exception 'nach 02: Snapshot v2 hat % PK und % UNIQUE (erwartet 1/1).',
      pk, slug_unique;
  end if;
  if tabellen_grants <> 0 then
    raise exception 'nach 02: % App-Grants auf dem Snapshot v2 (erwartet 0).', tabellen_grants;
  end if;
  if schema_grants <> 0 then
    raise exception 'nach 02: % App-Grants auf dem Schema cbb_private_backup (erwartet 0).',
      schema_grants;
  end if;
  if payload_v2_da then
    raise exception 'nach 02: value_add_payload_v2 existiert bereits — 02 darf sie nicht anlegen.';
  end if;
  if bestand_drift <> 0 then
    raise exception 'nach 02: % Produktzeilen wurden veraendert — 02 schreibt nicht in products.',
      bestand_drift;
  end if;

  raise notice 'nach 02 OK: 10 Snapshot-Zeilen, 0 Drift, 2 ALT-NOTE, 12 Spalten, RLS an, 0 Policies, PK+UNIQUE, 0 App-Grants, keine Payload, Bestand unveraendert.';
end $$;
