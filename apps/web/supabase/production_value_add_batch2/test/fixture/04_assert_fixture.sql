-- ============================================================================
-- FIXTURE 04 — Selbsttest der Fixture gegen den Production-Fingerprint
-- ============================================================================
-- Laeuft nach Seed, echtem seo_updated_at_trigger.sql und den Batch-1-Artefakten.
-- Schlaegt hier etwas fehl, ist die Fixture unbrauchbar und jeder spaetere PASS
-- waere wertlos. Deshalb: harte Exception statt Report-Zeile.
--
-- Zielbild (Production, 2026-08-26):
--   376 Produkte, 372 published
--   Batch 2: 10/10 published, 0/8 Value-Add-Felder gesetzt
--   Batch 1: 10/10 published, vollstaendig befuellt, Verteilung 3/2/5
--   Value-Add gesamt: exakt 10 Zeilen
--   Value-Add-Schema: 8/8 Spalten, 2/2 Constraints
--   v1-Artefakte vorhanden, v2-Artefakte NICHT vorhanden
-- ============================================================================

do $$
declare
  produkte bigint;
  published bigint;
  b2_ziele integer;
  b2_value_add integer;
  b2_relationsziele integer;
  b1_vollstaendig integer;
  b1_alt integer;
  b1_comp integer;
  b1_ohne integer;
  value_add_gesamt integer;
  value_add_spalten integer;
  constraints integer;
  grants integer;
  rls boolean;
  policies integer;
  trigger_defs text;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  anon_da boolean;
  auth_da boolean;
  vachichi_da integer;
  infactory_verweis integer;
begin
  select count(*), count(*) filter (where is_published is true)
  into produkte, published
  from public.products;
  if produkte <> 376 then
    raise exception 'Fixture kaputt: % Produkte, erwartet 376.', produkte;
  end if;
  if published <> 372 then
    raise exception 'Fixture kaputt: % published, erwartet 372.', published;
  end if;

  -- --- Batch 2 ------------------------------------------------------------
  select count(*) filter (where is_published is true),
         count(*) filter (
           where fuer_wen is not null or nicht_fuer is not null
              or key_fact is not null or pros is not null or cons is not null
              or alternative_slug is not null or alternative_reason is not null
              or alternative_kind is not null)
  into b2_ziele, b2_value_add
  from public.products
  where slug in (
    'livondo-terracotta-pflanzenbewaesserung',
    'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch',
    'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen',
    'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool',
    'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars',
    'katzenschlafsack-fuer-menschen');
  if b2_ziele <> 10 then
    raise exception 'Fixture kaputt: %/10 Batch-2-Zielprodukte published.', b2_ziele;
  end if;
  if b2_value_add <> 0 then
    raise exception 'Fixture kaputt: % Batch-2-Zeilen tragen bereits Value-Add-Daten, erwartet 0.',
      b2_value_add;
  end if;

  select count(*) into b2_relationsziele from public.products
  where is_published is true and slug in (
    'gluecksgut-anti-stress-wuerfel', 'shashibo-formwechsel-box-magnetisch');
  if b2_relationsziele <> 2 then
    raise exception 'Fixture kaputt: %/2 Batch-2-Relationsziele published.', b2_relationsziele;
  end if;

  -- --- Batch 1 ------------------------------------------------------------
  select
    count(*) filter (
      where fuer_wen is not null and nicht_fuer is not null
        and key_fact is not null and pros is not null and cons is not null
        and editorial_note is not null),
    count(*) filter (where alternative_kind = 'alternative'),
    count(*) filter (where alternative_kind = 'complement'),
    count(*) filter (where alternative_kind is null
                       and alternative_slug is null
                       and alternative_reason is null)
  into b1_vollstaendig, b1_alt, b1_comp, b1_ohne
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design');
  if b1_vollstaendig <> 10 then
    raise exception 'Fixture kaputt: nur %/10 Batch-1-Zeilen vollstaendig befuellt.', b1_vollstaendig;
  end if;
  if b1_alt <> 3 or b1_comp <> 2 or b1_ohne <> 5 then
    raise exception 'Fixture kaputt: Batch-1-Verteilung %/%/% , erwartet 3/2/5.',
      b1_alt, b1_comp, b1_ohne;
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 10 then
    raise exception 'Fixture kaputt: % Zeilen mit Value-Add gesamt, erwartet 10 (nur Batch 1).',
      value_add_gesamt;
  end if;

  -- --- Schema -------------------------------------------------------------
  select count(*) into value_add_spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');
  if value_add_spalten <> 8 then
    raise exception 'Fixture kaputt: %/8 Value-Add-Spalten.', value_add_spalten;
  end if;

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');
  if constraints <> 2 then
    raise exception 'Fixture kaputt: %/2 Value-Add-Constraints.', constraints;
  end if;

  -- --- Rechte, RLS, Trigger ------------------------------------------------
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

  -- --- Private Artefakte ---------------------------------------------------
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into v1_snapshot_da, v1_payload_da, v2_snapshot_da, v2_payload_da;
  if not v1_snapshot_da or not v1_payload_da then
    raise exception 'Fixture kaputt: Batch-1-Artefakte fehlen (snapshot %, payload %).',
      v1_snapshot_da, v1_payload_da;
  end if;
  if v2_snapshot_da or v2_payload_da then
    raise exception 'Fixture kaputt: Batch-2-Artefakte existieren bereits (snapshot %, payload %).',
      v2_snapshot_da, v2_payload_da;
  end if;

  -- --- Rollen und Fingerprint ---------------------------------------------
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

  -- --- Der manuelle Querverweis, wegen dem infactory relationslos bleibt ---
  select count(*) into vachichi_da from public.products
  where slug = 'vachichi-boyfriend-kissen-muskuloeser-arm' and is_published is true;
  if vachichi_da <> 1 then
    raise exception 'Fixture kaputt: vachichi-boyfriend-kissen-muskuloeser-arm fehlt oder ist unpublished.';
  end if;

  select count(*) into infactory_verweis from public.products
  where slug = 'infactory-boyfriend-kissen'
    and description like '%vachichi-boyfriend-kissen-muskuloeser-arm%';
  if infactory_verweis <> 1 then
    raise exception 'Fixture kaputt: infactory traegt den manuellen Querverweis nicht im Beschreibungstext.';
  end if;

  raise notice 'Fixture OK: 376 Produkte / 372 published, Batch 2 10/10 leer, Batch 1 10/10 befuellt (3/2/5), Schema 8/8 + 2/2, v1 da, v2 fehlt, 14 Grants, RLS an, 2 Policies, Trigger aktiv.';
end $$;
