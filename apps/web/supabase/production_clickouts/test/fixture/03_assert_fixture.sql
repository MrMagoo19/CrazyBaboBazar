-- ============================================================================
-- FIXTURE 03 — Selbstpruefung der Fixture
-- ============================================================================
-- Wenn die Fixture nicht dem Zielbild entspricht, sind alle Folgeergebnisse
-- wertlos. Diese Datei bricht deshalb hart ab statt zu warnen.
-- ============================================================================

do $$
declare
  produkte bigint;
  published bigint;
  value_add bigint;
  v1_snapshot bigint;
  v1_payload bigint;
  v2_snapshot bigint;
  v2_payload bigint;
  app_grants integer;
  cron_api integer;
  cron_jobs bigint;
  cron_runs bigint;
begin
  select count(*) into produkte from public.products;
  select count(*) into published from public.products where is_published is true;
  select count(*) into value_add from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  if produkte <> 376 or published <> 372 then
    raise exception 'Fixture kaputt: % Produkte (erwartet 376), % published (erwartet 372).',
      produkte, published;
  end if;
  if value_add <> 20 then
    raise exception 'Fixture kaputt: % Zeilen mit Value-Add (erwartet 20).', value_add;
  end if;

  select count(*) into v1_snapshot from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into v1_payload  from cbb_private_backup.value_add_payload_v1;
  select count(*) into v2_snapshot from cbb_private_backup.value_add_pre_backfill_v2;
  select count(*) into v2_payload  from cbb_private_backup.value_add_payload_v2;
  if v1_snapshot <> 10 or v1_payload <> 10 or v2_snapshot <> 10 or v2_payload <> 10 then
    raise exception 'Fixture kaputt: Value-Add-Artefakte % / % / % / % (erwartet je 10).',
      v1_snapshot, v1_payload, v2_snapshot, v2_payload;
  end if;

  -- Der REVOKE-Test von 02 ist nur aussagekraeftig, wenn es vorher wirklich
  -- etwas zu entziehen gibt. Genau das belegt diese Zeile.
  select count(*) into app_grants
  from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'products'
    and grantee in ('anon', 'authenticated');
  if app_grants <> 14 then
    raise exception 'Fixture kaputt: % App-Grants auf products (erwartet 14).', app_grants;
  end if;

  if to_regclass('public.click_outs') is not null then
    raise exception 'Fixture kaputt: public.click_outs existiert bereits.';
  end if;

  -- ---------------------------------------------------------------------
  -- pg_cron-Nachbildung: die API muss vollstaendig sein UND der Jobkatalog
  -- muss leer sein. Ein vorbelegter Katalog wuerde den Happy Path von 04a
  -- still in den No-op-Zweig schieben.
  -- ---------------------------------------------------------------------
  if to_regclass('cron.job') is null or to_regclass('cron.job_run_details') is null then
    raise exception 'Fixture kaputt: cron.job oder cron.job_run_details fehlt.';
  end if;

  select count(*) into cron_api
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'cron'
    and (
      (p.proname = 'schedule'   and oidvectortypes(p.proargtypes) = 'text, text, text')
      or
      (p.proname = 'unschedule' and oidvectortypes(p.proargtypes) = 'bigint')
    );
  if cron_api <> 2 then
    raise exception 'Fixture kaputt: % passende cron-Funktionen (erwartet 2).', cron_api;
  end if;

  select count(*) into cron_jobs from cron.job;
  select count(*) into cron_runs from cron.job_run_details;
  if cron_jobs <> 0 or cron_runs <> 0 then
    raise exception 'Fixture kaputt: % Job(s) und % Lauf/Laeufe im cron-Katalog (erwartet je 0).',
      cron_jobs, cron_runs;
  end if;

  raise notice 'Fixture OK: 376/372 Produkte, 20 Value-Add, v1/v2 je 10, 14 App-Grants, keine Klick-out-Artefakte, cron-API vollstaendig und Jobkatalog leer.';
end $$;
