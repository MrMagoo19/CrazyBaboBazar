-- ============================================================================
-- FIXTURE 03 — Selbsttest der Fixture gegen den echten Production-Fingerprint
-- ============================================================================
-- Laeuft direkt nach dem Seed und nach dem echten seo_updated_at_trigger.sql.
-- Schlaegt hier etwas fehl, ist die Fixture unbrauchbar und jeder spaetere
-- PASS waere wertlos. Deshalb: harte Exception statt Report-Zeile.
-- ============================================================================

do $$
declare
  produkte bigint;
  ziele integer;
  relationen integer;
  notes integer;
  value_add_spalten integer;
  constraints integer;
  grants integer;
  rls boolean;
  policies integer;
  trigger_defs text;
  divoom_null integer;
  anon_da boolean;
  auth_da boolean;
begin
  select count(*) into produkte from public.products;
  if produkte <> 376 then
    raise exception 'Fixture kaputt: % Produkte, erwartet 376.', produkte;
  end if;

  select count(*) into ziele from public.products
  where is_published is true and slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design');
  if ziele <> 10 then
    raise exception 'Fixture kaputt: %/10 Zielprodukte published.', ziele;
  end if;

  select count(*) into relationen from public.products
  where is_published is true and slug in (
    'ifixit-antistatik-matte-faltbar-esd',
    'divoom-minitoo-retro-pc-lautsprecher-pixel',
    'derayee-schaumstoff-wasserpistole',
    'aeropress-go-tragbare-kaffeemaschine',
    'cbdywvr-2in1-ladekabel-mit-staender');
  if relationen <> 5 then
    raise exception 'Fixture kaputt: %/5 Relationsziele published.', relationen;
  end if;

  select count(*) into notes from public.products
  where editorial_note is not null and slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design');
  if notes <> 3 then
    raise exception 'Fixture kaputt: % bestehende editorial_note in der Zielmenge, erwartet 3.', notes;
  end if;

  select count(*) into value_add_spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');
  if value_add_spalten <> 0 then
    raise exception 'Fixture kaputt: % Value-Add-Spalten bereits vorhanden, erwartet 0.', value_add_spalten;
  end if;

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');
  if constraints <> 0 then
    raise exception 'Fixture kaputt: % Value-Add-Constraints vorhanden, erwartet 0.', constraints;
  end if;

  select count(*) into grants from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'products'
    and grantee in ('anon', 'authenticated');
  if grants <> 14 then
    raise exception 'Fixture kaputt: % App-Grants auf products, erwartet 14.', grants;
  end if;

  select c.relrowsecurity into rls from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'products';
  if rls is not true then
    raise exception 'Fixture kaputt: RLS auf products ist nicht aktiv.';
  end if;

  select count(*) into policies from pg_policies
  where schemaname = 'public' and tablename = 'products';
  if policies <> 2 then
    raise exception 'Fixture kaputt: % Policies auf products, erwartet 2.', policies;
  end if;

  select coalesce(string_agg(pg_get_triggerdef(t.oid), ' | '), 'FEHLT')
  into trigger_defs
  from pg_trigger t
  where t.tgrelid = 'public.products'::regclass and not t.tgisinternal;
  if trigger_defs not like '%products_set_updated_at%'
     or trigger_defs not like '%products_touch_updated_at()%' then
    raise exception 'Fixture kaputt: products_set_updated_at fehlt (%).', trigger_defs;
  end if;

  select count(*) into divoom_null from public.products
  where slug = 'divoom-pixoo-led-panel' and price_cents is null;
  if divoom_null <> 1 then
    raise exception 'Fixture kaputt: divoom price_cents ist nicht NULL.';
  end if;

  select exists (select 1 from pg_roles where rolname = 'anon'),
         exists (select 1 from pg_roles where rolname = 'authenticated')
  into anon_da, auth_da;
  if not anon_da or not auth_da then
    raise exception 'Fixture kaputt: Rollen anon/authenticated fehlen.';
  end if;

  if to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Fixture kaputt: Production-Fingerprint unvollstaendig.';
  end if;

  raise notice 'Fixture OK: 376 Produkte, 10/10 Ziele, 5/5 Relationen, 3 editorial_note, 0/8 Spalten, 0/2 Constraints, 14 Grants, RLS an, 2 Policies, Trigger aktiv.';
end $$;
