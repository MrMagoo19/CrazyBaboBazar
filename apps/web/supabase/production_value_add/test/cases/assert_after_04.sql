-- Nach 04_backfill_value_add.sql: exakt 10 Zeilen befuellt, sonst nichts.
do $$
declare
  befuellt_gesamt integer;
  ziel_vollstaendig integer;
  payload_zeilen integer;
  payload_drift integer;
  alternativen integer;
  ergaenzungen integer;
  ohne_relation integer;
  defekte_ziele integer;
  ziel_lastmod_neu integer;
  fremd_lastmod_drift integer;
  fremd_note_drift integer;
  ueberschrieben integer;
  payload_rls boolean;
  payload_grants integer;
  produkte bigint;
begin
  select count(*) into produkte from public.products;

  select count(*) into befuellt_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select count(*) into ziel_vollstaendig
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b on b.id = p.id
  where p.fuer_wen is not null and p.nicht_fuer is not null
    and p.key_fact is not null and p.pros is not null and p.cons is not null
    and p.editorial_note is not null;

  select count(*) into payload_zeilen
  from cbb_private_backup.value_add_payload_v1;

  select count(*) into payload_drift
  from cbb_private_backup.value_add_payload_v1 v
  left join public.products p on p.slug = v.slug
  where p.slug is null
     or p.fuer_wen is distinct from v.fuer_wen
     or p.nicht_fuer is distinct from v.nicht_fuer
     or p.key_fact is distinct from v.key_fact
     or p.pros is distinct from v.pros
     or p.cons is distinct from v.cons
     or p.alternative_slug is distinct from v.alternative_slug
     or p.alternative_reason is distinct from v.alternative_reason
     or p.alternative_kind is distinct from v.alternative_kind
     or p.editorial_note is distinct from v.editorial_note;

  select
    count(*) filter (where p.alternative_kind = 'alternative'),
    count(*) filter (where p.alternative_kind = 'complement'),
    count(*) filter (where p.alternative_kind is null
                       and p.alternative_slug is null
                       and p.alternative_reason is null)
  into alternativen, ergaenzungen, ohne_relation
  from public.products p
  join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug;

  select count(*) into defekte_ziele
  from public.products p
  join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  -- Genau die zehn Zielseiten bekommen ein neues lastmod ...
  select count(*) into ziel_lastmod_neu
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug
  where p.updated_at > b.updated_at;

  -- ... und die 366 anderen Zeilen keines. Sonst meldet die Sitemap Google
  -- Aenderungen, die es nicht gab.
  select count(*) into fremd_lastmod_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.updated_at is distinct from b.updated_at
    and p.slug not in (select slug from cbb_private_backup.value_add_payload_v1);

  select count(*) into fremd_note_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
    and p.slug not in (select slug from cbb_private_backup.value_add_payload_v1);

  -- Die drei bewussten Overwrites muessen tatsaechlich stattgefunden haben.
  select count(*) into ueberschrieben
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where b.editorial_note is not null
    and p.editorial_note is distinct from b.editorial_note
    and p.slug in ('ninja-staysharp-messerset-6-teilig',
                   'n4-nussmilchbereiter-pflanzenmilch',
                   'welpen-usb-ladekabel-hunde-design');

  select c.relrowsecurity into payload_rls from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'cbb_private_backup' and c.relname = 'value_add_payload_v1';

  select count(*) into payload_grants
  from information_schema.role_table_grants
  where table_schema = 'cbb_private_backup' and table_name = 'value_add_payload_v1'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  if produkte <> 376 then
    raise exception 'nach 04: % Produkte (erwartet 376).', produkte;
  end if;
  if befuellt_gesamt <> 10 or ziel_vollstaendig <> 10 then
    raise exception 'nach 04: % Zeilen befuellt, % Ziele vollstaendig (erwartet 10/10).',
      befuellt_gesamt, ziel_vollstaendig;
  end if;
  if payload_zeilen <> 10 or payload_drift <> 0 then
    raise exception 'nach 04: Audit-Payload % Zeilen, % Abweichungen (erwartet 10/0).',
      payload_zeilen, payload_drift;
  end if;
  if alternativen <> 3 or ergaenzungen <> 2 or ohne_relation <> 5 then
    raise exception 'nach 04: Verteilung %/%/% (erwartet 3/2/5).',
      alternativen, ergaenzungen, ohne_relation;
  end if;
  if defekte_ziele <> 0 then
    raise exception 'nach 04: % defekte Relationsziele.', defekte_ziele;
  end if;
  if ziel_lastmod_neu <> 10 then
    raise exception 'nach 04: nur %/10 Zielseiten haben ein neueres updated_at.',
      ziel_lastmod_neu;
  end if;
  if fremd_lastmod_drift <> 0 or fremd_note_drift <> 0 then
    raise exception 'nach 04: Kollateralschaden ausserhalb der Zielmenge (% lastmod, % notes).',
      fremd_lastmod_drift, fremd_note_drift;
  end if;
  if ueberschrieben <> 3 then
    raise exception 'nach 04: nur % der 3 bewussten editorial_note-Overwrites erfolgt.',
      ueberschrieben;
  end if;
  if payload_rls is not true then
    raise exception 'nach 04: RLS auf value_add_payload_v1 ist nicht aktiv.';
  end if;
  if payload_grants <> 0 then
    raise exception 'nach 04: % App-Grants auf value_add_payload_v1 (erwartet 0).',
      payload_grants;
  end if;

  raise notice 'nach 04 OK: 10 befuellt, Payload 10/0, Verteilung 3/2/5, 10 neue lastmods, 0 Kollateralschaden, 3 bewusste Overwrites.';
end $$;
