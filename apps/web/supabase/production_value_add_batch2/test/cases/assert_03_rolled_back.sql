-- Nach einem abgebrochenen 03: die gesamte Transaktion ist zurueckgerollt.
-- Entscheidend ist value_add_payload_v2 — diese Tabelle entsteht INNERHALB der
-- Backfill-Transaktion vor dem UPDATE. Existiert sie nach dem Abbruch, waere
-- 03 nicht atomar und ein Retry liefe in den "Payload existiert bereits"-Guard.
do $$
declare
  payload_da boolean;
  befuellt integer;
  drift integer;
  snapshot_zeilen integer;
begin
  select to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into payload_da;

  select count(*) into befuellt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  -- Alle 376 Zeilen gegen die Baseline, ueber alle spaeter geschriebenen Felder.
  select count(*) into drift
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

  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v2;

  if payload_da then
    raise exception 'Rollback unvollstaendig: value_add_payload_v2 hat den Abbruch ueberlebt.';
  end if;
  if befuellt <> 10 then
    raise exception 'Rollback unvollstaendig: % Zeilen tragen Value-Add-Daten (erwartet 10, nur Batch 1).',
      befuellt;
  end if;
  if drift <> 0 then
    raise exception 'Rollback unvollstaendig: % Zeilen weichen von der Baseline ab.', drift;
  end if;
  if snapshot_zeilen <> 10 then
    raise exception 'Rollback hat den Snapshot v2 beschaedigt: %/10 Zeilen.', snapshot_zeilen;
  end if;

  raise notice 'Rollback OK: keine Audit-Payload v2, weiterhin nur 10 befuellte Zeilen (Batch 1), 0 Daten-Drift, Snapshot v2 10/10.';
end $$;
