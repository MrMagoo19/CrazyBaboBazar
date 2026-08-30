-- Belegt, dass ein abgebrochener Lauf NICHTS hinterlassen hat: weder ein
-- v3-Artefakt noch eine veraenderte Produktzeile.
do $$
declare
  gesamt_drift integer;
  value_add_gesamt integer;
begin
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null then
    raise exception 'Abgebrochener Lauf hinterliess den Snapshot v3.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Abgebrochener Lauf hinterliess die Payload v3.';
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 20 then
    raise exception 'Abgebrochener Lauf veraenderte die Befuellung: % (erwartet 20).',
      value_add_gesamt;
  end if;

  select count(*) into gesamt_drift
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
  if gesamt_drift <> 0 then
    raise exception 'Abgebrochener Lauf veraenderte % Produktzeile(n).', gesamt_drift;
  end if;

  raise notice 'Abgebrochener Lauf sauber: keine v3-Artefakte, Bestand identisch zur Baseline.';
end $$;
