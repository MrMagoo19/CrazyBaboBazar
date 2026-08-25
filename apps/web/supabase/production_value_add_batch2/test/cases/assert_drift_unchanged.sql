-- Nach dem Drift-Abbruch in 03: die fremde Aenderung bleibt stehen, es
-- entsteht keine Audit-Payload und keine Zielzeile wird befuellt.
do $$
declare
  payload_da boolean;
  snapshot_zeilen integer;
  fremdaenderung integer;
  batch2_befuellt integer;
  befuellt_gesamt integer;
  drift_ausserhalb integer;
begin
  select to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into payload_da;

  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v2;

  select count(*) into fremdaenderung from public.products
  where slug = 'scheisse-quartett-kartenspiel'
    and editorial_note = 'PARALLELE REDAKTIONSAENDERUNG nach dem Snapshot.';

  select count(*) into batch2_befuellt
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 s on s.id = p.id
  where p.fuer_wen is not null or p.nicht_fuer is not null
     or p.key_fact is not null or p.pros is not null or p.cons is not null
     or p.alternative_slug is not null or p.alternative_reason is not null
     or p.alternative_kind is not null;

  select count(*) into befuellt_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  -- Ausser der einen bewusst gedrifteten Zeile darf sich nichts veraendert haben.
  select count(*) into drift_ausserhalb
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug <> 'scheisse-quartett-kartenspiel'
    and (p.editorial_note is distinct from b.editorial_note
      or p.updated_at is distinct from b.updated_at
      or p.fuer_wen is distinct from b.fuer_wen
      or p.nicht_fuer is distinct from b.nicht_fuer
      or p.key_fact is distinct from b.key_fact
      or p.pros is distinct from b.pros
      or p.cons is distinct from b.cons
      or p.alternative_slug is distinct from b.alternative_slug
      or p.alternative_reason is distinct from b.alternative_reason
      or p.alternative_kind is distinct from b.alternative_kind);

  if payload_da then
    raise exception 'Drift-Abbruch unvollstaendig: value_add_payload_v2 wurde angelegt.';
  end if;
  if snapshot_zeilen <> 10 then
    raise exception 'Drift-Abbruch: Snapshot v2 hat %/10 Zeilen.', snapshot_zeilen;
  end if;
  if fremdaenderung <> 1 then
    raise exception 'Drift-Abbruch: 03 hat die fremde Aenderung veraendert oder entfernt.';
  end if;
  if batch2_befuellt <> 0 then
    raise exception 'Drift-Abbruch: % Batch-2-Zeilen wurden trotzdem befuellt.', batch2_befuellt;
  end if;
  if befuellt_gesamt <> 10 then
    raise exception 'Drift-Abbruch: % Zeilen mit Value-Add gesamt (erwartet 10, nur Batch 1).',
      befuellt_gesamt;
  end if;
  if drift_ausserhalb <> 0 then
    raise exception 'Drift-Abbruch: % weitere Zeilen wurden veraendert.', drift_ausserhalb;
  end if;

  raise notice 'Drift-Abbruch OK: keine Payload v2, Snapshot 10/10, fremde Aenderung unangetastet, 0 befuellte Batch-2-Zeilen, sonst 0 Drift.';
end $$;
