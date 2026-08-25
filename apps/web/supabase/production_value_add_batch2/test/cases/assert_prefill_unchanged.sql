-- Nach dem Guard-Abbruch wegen einer fremdbefuellten Zielzeile:
-- 02 darf die Fremdbefuellung weder uebernehmen noch aufraeumen. Der Zustand
-- bleibt exakt so, wie das Setup ihn hinterlassen hat.
do $$
declare
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  fremdbefuellung integer;
  batch2_befuellt integer;
  befuellt_gesamt integer;
  drift_ausserhalb integer;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into v2_snapshot_da, v2_payload_da;

  select count(*) into fremdbefuellung from public.products
  where slug = 'katzenschlafsack-fuer-menschen'
    and key_fact = 'FREMDBEFUELLUNG aus einem anderen Vorgang.';

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

  -- Alle Zeilen ausser der einen fremdbefuellten muessen der Baseline
  -- entsprechen.
  select count(*) into drift_ausserhalb
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug <> 'katzenschlafsack-fuer-menschen'
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

  if v2_snapshot_da or v2_payload_da then
    raise exception 'Fremdbefuellung: Batch-2-Artefakt entstanden (snapshot %, payload %).',
      v2_snapshot_da, v2_payload_da;
  end if;
  if fremdbefuellung <> 1 then
    raise exception 'Fremdbefuellung: 02 hat den fremden key_fact veraendert oder entfernt.';
  end if;
  if batch2_befuellt <> 1 then
    raise exception 'Fremdbefuellung: % befuellte Batch-2-Zeilen (erwartet genau 1).',
      batch2_befuellt;
  end if;
  if befuellt_gesamt <> 11 then
    raise exception 'Fremdbefuellung: % Zeilen mit Value-Add gesamt (erwartet 11 = 10 Batch 1 + 1 Fremdzeile).',
      befuellt_gesamt;
  end if;
  if drift_ausserhalb <> 0 then
    raise exception 'Fremdbefuellung: % weitere Zeilen wurden veraendert.', drift_ausserhalb;
  end if;

  raise notice 'Fremdbefuellung OK: kein v2-Artefakt, die eine Fremdzeile unveraendert, 11 Value-Add-Zeilen gesamt, sonst 0 Drift.';
end $$;
