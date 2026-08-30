-- ============================================================================
-- Batch 1 und Batch 2 sind tabu.
-- ============================================================================
-- Diese Datei vergleicht alle VIER privaten Vorgaenger-Artefakte UND die
-- zwanzig zugehoerigen Produktzeilen Zelle fuer Zelle gegen die Baseline aus
-- fixture/05_baseline.sql. Sie laeuft nach jedem Fall, in dem Batch 3 etwas
-- geschrieben oder abgebrochen hat.
--
-- Der Vergleich laeuft bewusst in BEIDE Richtungen (except all / union all /
-- except all): so fallen fehlende UND zusaetzliche Zeilen auf, nicht nur
-- geaenderte.
-- ============================================================================
do $$
declare
  fehlend text := '';
  v1s_drift integer;
  v1p_drift integer;
  v2s_drift integer;
  v2p_drift integer;
  rls_defekt integer;
  policies_gesamt integer;
  produkt_drift integer;
begin
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    fehlend := fehlend || ' v1_snapshot';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    fehlend := fehlend || ' v1_payload';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    fehlend := fehlend || ' v2_snapshot';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    fehlend := fehlend || ' v2_payload';
  end if;
  if fehlend <> '' then
    raise exception 'Vorgaenger beschaedigt: Artefakt(e) fehlen —%', fehlend;
  end if;

  select count(*) into v1s_drift from (
    select * from cbb_private_backup.value_add_pre_backfill_v1
    except all select * from cbb_test_baseline.v1_snapshot_before
    union all
    select * from cbb_test_baseline.v1_snapshot_before
    except all select * from cbb_private_backup.value_add_pre_backfill_v1
  ) d;

  select count(*) into v1p_drift from (
    select * from cbb_private_backup.value_add_payload_v1
    except all select * from cbb_test_baseline.v1_payload_before
    union all
    select * from cbb_test_baseline.v1_payload_before
    except all select * from cbb_private_backup.value_add_payload_v1
  ) d;

  select count(*) into v2s_drift from (
    select * from cbb_private_backup.value_add_pre_backfill_v2
    except all select * from cbb_test_baseline.v2_snapshot_before
    union all
    select * from cbb_test_baseline.v2_snapshot_before
    except all select * from cbb_private_backup.value_add_pre_backfill_v2
  ) d;

  select count(*) into v2p_drift from (
    select * from cbb_private_backup.value_add_payload_v2
    except all select * from cbb_test_baseline.v2_payload_before
    union all
    select * from cbb_test_baseline.v2_payload_before
    except all select * from cbb_private_backup.value_add_payload_v2
  ) d;

  if v1s_drift <> 0 or v1p_drift <> 0 or v2s_drift <> 0 or v2p_drift <> 0 then
    raise exception 'Vorgaenger beschaedigt: Abweichungen v1 %/% und v2 %/% gegen die Baseline.',
      v1s_drift, v1p_drift, v2s_drift, v2p_drift;
  end if;

  select count(*) into rls_defekt
  from pg_class c
  where c.oid in (
      'cbb_private_backup.value_add_pre_backfill_v1'::regclass,
      'cbb_private_backup.value_add_payload_v1'::regclass,
      'cbb_private_backup.value_add_pre_backfill_v2'::regclass,
      'cbb_private_backup.value_add_payload_v2'::regclass
    )
    and c.relrowsecurity is not true;
  if rls_defekt <> 0 then
    raise exception 'Vorgaenger beschaedigt: bei % Tabelle(n) ist RLS abgeschaltet.', rls_defekt;
  end if;

  select count(*) into policies_gesamt
  from pg_policy pol
  where pol.polrelid in (
    'cbb_private_backup.value_add_pre_backfill_v1'::regclass,
    'cbb_private_backup.value_add_payload_v1'::regclass,
    'cbb_private_backup.value_add_pre_backfill_v2'::regclass,
    'cbb_private_backup.value_add_payload_v2'::regclass
  );
  if policies_gesamt <> 0 then
    raise exception 'Vorgaenger beschaedigt: % Policy(s) auf den privaten Tabellen (erwartet 0).',
      policies_gesamt;
  end if;

  -- Die zwanzig Vorgaenger-Produktzeilen selbst, inklusive updated_at.
  select count(*) into produkt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design',
    'livondo-terracotta-pflanzenbewaesserung', 'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch', 'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen', 'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool', 'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars', 'katzenschlafsack-fuer-menschen')
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
  if produkt_drift <> 0 then
    raise exception 'Vorgaenger beschaedigt: % der 20 Produktzeilen weichen von der Baseline ab.',
      produkt_drift;
  end if;

  raise notice 'Batch 1 und Batch 2 unangetastet: vier Artefakte ohne Drift, RLS an, 0 Policies, 20 Produktzeilen unveraendert.';
end $$;
