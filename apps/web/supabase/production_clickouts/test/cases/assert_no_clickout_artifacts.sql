-- Belegt, dass ein abgebrochener Lauf NICHTS hinterlassen hat.
-- Wird nach jedem Negativfall aufgerufen: ein halb angelegtes Schema waere ein
-- Befund, kein Detail.
do $$
declare
  value_add bigint;
begin
  if to_regclass('public.click_outs') is not null then
    raise exception 'Negativfall hinterliess public.click_outs.';
  end if;
  if exists (select 1 from pg_namespace where nspname = 'cbb_private_analytics') then
    raise exception 'Negativfall hinterliess das Schema cbb_private_analytics.';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
  ) then
    raise exception 'Negativfall hinterliess die Retention-Funktion.';
  end if;

  -- Fremde Artefakte bleiben unberuehrt.
  select count(*) into value_add from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null;
  if value_add <> 20 then
    raise exception 'Negativfall veraenderte die Value-Add-Befuellung: % (erwartet 20).', value_add;
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null
     or to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null
     or to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Negativfall beschaedigte ein Value-Add-Artefakt.';
  end if;

  raise notice 'Negativfall sauber: keine Klick-out-Artefakte, Value-Add unveraendert.';
end $$;
