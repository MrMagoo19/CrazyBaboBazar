-- Nach dem Abbruch am fehlenden Vorgaenger-Artefakt: Batch 3 hat nichts
-- angelegt, die drei uebrigen Vorgaenger-Tabellen stehen unveraendert, und der
-- Bestand entspricht weiterhin der Baseline.
do $$
declare
  gesamt_drift integer;
  value_add_gesamt integer;
begin
  if to_regclass('cbb_private_backup.value_add_payload_v2') is not null then
    raise exception 'Erwartet war ein fehlendes value_add_payload_v2.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null
     or to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Der abgebrochene Lauf hat ein weiteres Vorgaenger-Artefakt entfernt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
     or to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Der abgebrochene Lauf hat ein v3-Artefakt angelegt.';
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 20 then
    raise exception 'Der abgebrochene Lauf veraenderte die Befuellung: % (erwartet 20).',
      value_add_gesamt;
  end if;

  select count(*) into gesamt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.pros is distinct from b.pros
     or p.alternative_slug is distinct from b.alternative_slug;
  if gesamt_drift <> 0 then
    raise exception 'Der abgebrochene Lauf veraenderte % Produktzeile(n).', gesamt_drift;
  end if;

  raise notice 'Abbruch am fehlenden Vorgaenger-Artefakt OK: nichts angelegt, nichts veraendert.';
end $$;
