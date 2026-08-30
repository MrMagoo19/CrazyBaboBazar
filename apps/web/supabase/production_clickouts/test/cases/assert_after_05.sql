-- Zustand nach 05_rollback.sql: alle Klick-out-Artefakte sind weg, alles
-- Fremde steht unveraendert.
do $$
declare
  produkte bigint;
  value_add bigint;
  cron_reste bigint;
begin
  if to_regclass('public.click_outs') is not null then
    raise exception 'Nach 05: public.click_outs existiert weiterhin.';
  end if;
  if exists (select 1 from pg_namespace where nspname = 'cbb_private_analytics') then
    raise exception 'Nach 05: Schema cbb_private_analytics existiert weiterhin.';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'cbb_private_analytics'
  ) then
    raise exception 'Nach 05: eine Funktion im Auswertungsschema existiert weiterhin.';
  end if;

  select count(*) into produkte from public.products;
  select count(*) into value_add from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null;
  if produkte <> 376 or value_add <> 20 then
    raise exception 'Nach 05: % Produkte (erwartet 376), % mit Value-Add (erwartet 20).',
      produkte, value_add;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null
     or to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null
     or to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Nach 05: ein Value-Add-Artefakt fehlt.';
  end if;

  -- Kein verwaister Job darf auf die geloeschte Funktion zeigen. Ein solcher
  -- Eintrag wuerde ab jetzt jede Nacht scheitern, ohne dass irgendetwas darauf
  -- hinweist.
  if to_regclass('cron.job') is not null then
    select count(*) into cron_reste
    from cron.job j
    where j.jobname::text = 'cbb-click-outs-retention-12m'
       or j.command like '%purge_click_outs%';
    if cron_reste <> 0 then
      raise exception 'Nach 05: % Retention-Job(s) weiterhin eingetragen (erwartet 0).', cron_reste;
    end if;
  end if;

  raise notice 'Nach 05 OK: Klick-out-Artefakte entfernt, kein Retention-Job mehr eingetragen, Produkte und Value-Add unveraendert.';
end $$;
