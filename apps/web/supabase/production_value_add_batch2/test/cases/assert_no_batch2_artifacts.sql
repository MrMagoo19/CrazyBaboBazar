-- Nach einem erwarteten Guard-Abbruch in 02: es darf KEIN Batch-2-Artefakt
-- entstanden sein, kein Zielprodukt darf Value-Add-Daten tragen und der Bestand
-- muss der Baseline entsprechen. Batch 1 bleibt unberuehrt.
--
-- Diese Datei setzt voraus, dass alle acht Value-Add-Spalten existieren. Fuer
-- den Teilzustands-Fall (eine Spalte fehlt) ist assert_schema_teilzustand.sql
-- zustaendig.
do $$
declare
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  batch2_befuellt integer;
  befuellt_gesamt integer;
  drift integer;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into v2_snapshot_da, v2_payload_da, v1_snapshot_da, v1_payload_da;

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

  -- Der Bestand kann durch das jeweilige Setup absichtlich veraendert sein
  -- (z. B. geloeschte Fuellprodukte). Verglichen wird deshalb nur ueber die
  -- Zeilen, die es noch gibt.
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
    raise exception 'Guard-Abbruch unvollstaendig: Batch-2-Artefakt entstanden (snapshot %, payload %).',
      v2_snapshot_da, v2_payload_da;
  end if;
  if batch2_befuellt <> 0 then
    raise exception 'Guard-Abbruch unvollstaendig: % Batch-2-Zeilen tragen Value-Add-Daten.',
      batch2_befuellt;
  end if;
  if befuellt_gesamt <> 10 then
    raise exception 'Guard-Abbruch unvollstaendig: % Zeilen mit Value-Add gesamt (erwartet 10, nur Batch 1).',
      befuellt_gesamt;
  end if;
  if drift <> 0 then
    raise exception 'Guard-Abbruch unvollstaendig: % Zeilen weichen von der Baseline ab.', drift;
  end if;
  if not v1_snapshot_da or not v1_payload_da then
    raise exception 'Guard-Abbruch hat Batch 1 beschaedigt (snapshot %, payload %).',
      v1_snapshot_da, v1_payload_da;
  end if;

  raise notice 'Guard-Abbruch OK: keine v2-Artefakte, 0 befuellte Batch-2-Zeilen, weiterhin 10 Value-Add-Zeilen aus Batch 1, 0 Drift, Batch-1-Artefakte da.';
end $$;
