-- Nach einem abgebrochenen 04: die gesamte Transaktion ist zurueckgerollt.
-- Entscheidend ist value_add_payload_v1 — diese Tabelle entsteht INNERHALB der
-- Backfill-Transaktion vor dem UPDATE. Existiert sie nach dem Abbruch, waere
-- 04 nicht atomar und ein Retry liefe in den "Payload existiert bereits"-Guard.
do $$
declare
  payload_da boolean;
  befuellt integer;
  drift integer;
  snapshot_zeilen integer;
begin
  select to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into payload_da;

  select count(*) into befuellt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select count(*) into drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at;

  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v1;

  if payload_da then
    raise exception 'Rollback unvollstaendig: value_add_payload_v1 hat den Abbruch ueberlebt.';
  end if;
  if befuellt <> 0 then
    raise exception 'Rollback unvollstaendig: % Zeilen tragen Value-Add-Daten.', befuellt;
  end if;
  if drift <> 0 then
    raise exception 'Rollback unvollstaendig: % Zeilen weichen von der Baseline ab.', drift;
  end if;
  if snapshot_zeilen <> 10 then
    raise exception 'Rollback hat den Snapshot beschaedigt: %/10 Zeilen.', snapshot_zeilen;
  end if;

  raise notice 'Rollback OK: keine Audit-Payload, 0 befuellte Zeilen, 0 Daten-Drift, Snapshot 10/10.';
end $$;
