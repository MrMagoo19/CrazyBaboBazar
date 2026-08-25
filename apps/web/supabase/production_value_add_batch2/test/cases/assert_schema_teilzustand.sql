-- Nach dem Guard-Abbruch bei unvollstaendigem Value-Add-Schema:
-- 02 darf weder die fehlende Spalte nachruesten noch die restlichen sieben
-- entfernen und kein Batch-2-Artefakt hinterlassen.
--
-- Bewusst OHNE Zugriff auf products.key_fact: diese Spalte existiert in diesem
-- Fall nicht mehr, ein Zugriff waere ein Planungsfehler statt einer Aussage.
do $$
declare
  spalten integer;
  constraints integer;
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
  batch2_befuellt integer;
begin
  select count(*) into spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

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
    and (fuer_wen is not null or nicht_fuer is not null
      or pros is not null or cons is not null or alternative_slug is not null
      or alternative_reason is not null or alternative_kind is not null);

  if spalten <> 7 then
    raise exception 'Teilzustand veraendert: % Value-Add-Spalten (erwartet unveraendert 7).', spalten;
  end if;
  if constraints <> 2 then
    raise exception 'Teilzustand veraendert: % Constraints (erwartet unveraendert 2).', constraints;
  end if;
  if v2_snapshot_da or v2_payload_da then
    raise exception 'Teilzustand: Batch-2-Artefakt entstanden (snapshot %, payload %).',
      v2_snapshot_da, v2_payload_da;
  end if;
  if not v1_snapshot_da or not v1_payload_da then
    raise exception 'Teilzustand: Batch-1-Artefakt verloren (snapshot %, payload %).',
      v1_snapshot_da, v1_payload_da;
  end if;
  if batch2_befuellt <> 0 then
    raise exception 'Teilzustand: % Batch-2-Zeilen tragen Value-Add-Daten.', batch2_befuellt;
  end if;

  raise notice 'Teilzustand OK: unveraendert 7 Spalten und 2 Constraints, keine v2-Artefakte, Batch 1 intakt, 0 befuellte Batch-2-Zeilen.';
end $$;
