-- Batch 1 ist tabu. Diese Datei vergleicht beide privaten Batch-1-Artefakte
-- UND die zehn Batch-1-Produktzeilen Zelle fuer Zelle gegen die Baseline aus
-- fixture/05_baseline.sql. Sie laeuft nach jedem Fall, in dem Batch 2 etwas
-- geschrieben oder abgebrochen hat.
do $$
declare
  snapshot_da boolean;
  payload_da boolean;
  snapshot_zeilen integer;
  payload_zeilen integer;
  snapshot_drift integer;
  payload_drift integer;
  snapshot_rls boolean;
  payload_rls boolean;
  snapshot_policies integer;
  payload_policies integer;
  produkt_drift integer;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into snapshot_da, payload_da;
  if not snapshot_da or not payload_da then
    raise exception 'Batch 1 beschaedigt: Artefakt fehlt (snapshot %, payload %).',
      snapshot_da, payload_da;
  end if;

  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_zeilen
  from cbb_private_backup.value_add_payload_v1;

  -- Voller Aussenvergleich in beide Richtungen: fehlende UND zusaetzliche
  -- Zeilen fallen auf, nicht nur geaenderte.
  select count(*) into snapshot_drift
  from (
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_private_backup.value_add_pre_backfill_v1
    except all
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_test_baseline.v1_snapshot_before
    union all
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_test_baseline.v1_snapshot_before
    except all
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_private_backup.value_add_pre_backfill_v1
  ) d;

  select count(*) into payload_drift
  from (
    select slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
           alternative_slug, alternative_reason, alternative_kind, editorial_note
    from cbb_private_backup.value_add_payload_v1
    except all
    select slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
           alternative_slug, alternative_reason, alternative_kind, editorial_note
    from cbb_test_baseline.v1_payload_before
    union all
    select slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
           alternative_slug, alternative_reason, alternative_kind, editorial_note
    from cbb_test_baseline.v1_payload_before
    except all
    select slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
           alternative_slug, alternative_reason, alternative_kind, editorial_note
    from cbb_private_backup.value_add_payload_v1
  ) d;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into snapshot_rls, snapshot_policies
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into payload_rls, payload_policies
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_payload_v1'::regclass;

  -- Die zehn Batch-1-Produktzeilen selbst, inklusive updated_at.
  select count(*) into produkt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design')
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

  if snapshot_zeilen <> 10 or payload_zeilen <> 10 then
    raise exception 'Batch 1 beschaedigt: Snapshot %/10, Payload %/10 Zeilen.',
      snapshot_zeilen, payload_zeilen;
  end if;
  if snapshot_drift <> 0 or payload_drift <> 0 then
    raise exception 'Batch 1 beschaedigt: % Snapshot- und % Payload-Abweichungen gegen die Baseline.',
      snapshot_drift, payload_drift;
  end if;
  if snapshot_rls is not true or payload_rls is not true then
    raise exception 'Batch 1 beschaedigt: RLS abgeschaltet (snapshot %, payload %).',
      snapshot_rls, payload_rls;
  end if;
  if snapshot_policies <> 0 or payload_policies <> 0 then
    raise exception 'Batch 1 beschaedigt: % Snapshot- und % Payload-Policies (erwartet 0/0).',
      snapshot_policies, payload_policies;
  end if;
  if produkt_drift <> 0 then
    raise exception 'Batch 1 beschaedigt: % der 10 Batch-1-Produktzeilen weichen von der Baseline ab.',
      produkt_drift;
  end if;

  raise notice 'Batch 1 unangetastet: Snapshot 10/10, Payload 10/10, 0 Drift, RLS an, 0 Policies, 10 Produktzeilen unveraendert.';
end $$;
