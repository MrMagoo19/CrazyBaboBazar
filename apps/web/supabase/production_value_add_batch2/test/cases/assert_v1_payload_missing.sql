-- Nach dem Guard-Abbruch wegen eines fehlenden Batch-1-Artefakts:
-- 02 darf weder ein v2-Artefakt anlegen noch das fehlende v1-Artefakt
-- "reparieren" — und der Snapshot v1, den es noch gibt, bleibt unangetastet.
--
-- Diese Datei ersetzt in case_k bewusst assert_no_batch2_artifacts.sql und
-- assert_v1_untouched.sql: beide verlangen ein vollstaendiges Batch 1, das der
-- Setup-Schritt hier absichtlich zerstoert hat.
do $$
declare
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
  v1_snapshot_drift integer;
  batch2_befuellt integer;
  befuellt_gesamt integer;
  drift integer;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into v2_snapshot_da, v2_payload_da, v1_snapshot_da, v1_payload_da;

  select count(*) into v1_snapshot_drift
  from (
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_private_backup.value_add_pre_backfill_v1
    except all
    select id, slug, editorial_note, updated_at, fuer_wen, nicht_fuer, key_fact,
           pros, cons, alternative_slug, alternative_reason, alternative_kind
    from cbb_test_baseline.v1_snapshot_before
  ) d;

  select count(*) into batch2_befuellt from public.products
  where slug in (
    'livondo-terracotta-pflanzenbewaesserung',
    'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch',
    'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen',
    'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool',
    'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars',
    'katzenschlafsack-fuer-menschen')
    and (fuer_wen is not null or nicht_fuer is not null or key_fact is not null
      or pros is not null or cons is not null or alternative_slug is not null
      or alternative_reason is not null or alternative_kind is not null);

  select count(*) into befuellt_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

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

  if v2_snapshot_da or v2_payload_da then
    raise exception 'Batch-1-Luecke: Batch-2-Artefakt entstanden (snapshot %, payload %).',
      v2_snapshot_da, v2_payload_da;
  end if;
  if not v1_snapshot_da then
    raise exception 'Batch-1-Luecke: 02 hat auch den v1-Snapshot verloren.';
  end if;
  if v1_payload_da then
    raise exception 'Batch-1-Luecke: value_add_payload_v1 ist wieder da — 02 legt nichts nach.';
  end if;
  if v1_snapshot_drift <> 0 then
    raise exception 'Batch-1-Luecke: % Abweichungen im verbliebenen v1-Snapshot.', v1_snapshot_drift;
  end if;
  if batch2_befuellt <> 0 then
    raise exception 'Batch-1-Luecke: % Batch-2-Zeilen tragen Value-Add-Daten.', batch2_befuellt;
  end if;
  if befuellt_gesamt <> 10 then
    raise exception 'Batch-1-Luecke: % Zeilen mit Value-Add gesamt (erwartet 10).', befuellt_gesamt;
  end if;
  if drift <> 0 then
    raise exception 'Batch-1-Luecke: % Produktzeilen weichen von der Baseline ab.', drift;
  end if;

  raise notice 'Batch-1-Luecke OK: kein v2-Artefakt, v1-Snapshot unveraendert, v1-Payload bleibt fehlend, 0 befuellte Batch-2-Zeilen, 0 Drift.';
end $$;
