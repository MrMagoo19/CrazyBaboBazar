-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 2 — 05 DATEN-RESTORE (SCHREIBEND, ROLLBACK)
-- ============================================================================
-- Nur mit neuer ausdruecklicher Benutzerfreigabe ausfuehren.
-- Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu
--
-- WAS DIESE DATEI TUT: Sie stellt exakt die zehn Zeilen aus
-- cbb_private_backup.value_add_pre_backfill_v2 wieder her — editorial_note,
-- updated_at und die acht Value-Add-Felder. Danach sieht Batch 2 aus wie vor
-- Schritt 03.
--
-- WAS SIE NICHT TUT:
--   * Sie loescht den Snapshot v2 NICHT.
--   * Sie loescht die Audit-Payload v2 NICHT. Beide bleiben fuer das
--     Beobachtungsfenster erhalten und sind Voraussetzung fuer einen
--     nachvollziehbaren Befund.
--   * Sie fasst Batch 1 NICHT an (weder value_add_pre_backfill_v1 noch
--     value_add_payload_v1 noch die zehn Batch-1-Produktzeilen).
--   * Es gibt bewusst KEINE Down-Migration in Batch 2. Die acht Spalten und
--     die zwei Constraints tragen Batch 1 und duerfen nicht entfernt werden.
--
-- IDEMPOTENZ: mehrfaches Ausfuehren ist zulaessig und aendert nach dem ersten
-- erfolgreichen Lauf nichts mehr. Der Trigger products_set_updated_at
-- ueberschreibt ein ausdruecklich mitgeschriebenes updated_at nicht — genau
-- darauf stuetzt sich das Zurueckspielen der historischen Zeitstempel.
--
-- BEWUSSTE GRENZE DER GUARDS (siehe RUNBOOK Abschnitt 8): dieser Rollback
-- prueft ausschliesslich seine eigenen zehn Zeilen. Er zaehlt NICHT, wie viele
-- Produkte insgesamt Value-Add-Daten tragen. Grund: ein spaeterer Batch 3
-- wuerde diese Zahl veraendern und wuerde damit einen dringend noetigen
-- Rollback von Batch 2 blockieren. Ein Rollback darf nie an einem Zustand
-- scheitern, den er gar nicht anfasst.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  product_rows bigint;
  target_rows integer;
  backup_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-2-Restore abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-2-Restore abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-2-Restore abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- Bewusst OHNE is_published: ein Rollback muss auch dann laufen, wenn eine
  -- Zielseite zwischenzeitlich offline genommen wurde.
  select count(*) into target_rows
  from public.products
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
    'katzenschlafsack-fuer-menschen'
  );
  if target_rows <> 10 then
    raise exception 'Batch-2-Restore abgebrochen: %/10 Zielprodukte vorhanden.', target_rows;
  end if;

  select count(*) into column_rows
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );
  select count(*) into correct_types
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and (
      (column_name in (
        'fuer_wen', 'nicht_fuer', 'key_fact', 'alternative_slug',
        'alternative_reason', 'alternative_kind'
      ) and data_type = 'text' and udt_name = 'text')
      or
      (column_name in ('pros', 'cons')
        and data_type = 'ARRAY' and udt_name = '_text')
    );
  select count(*) into constraint_rows
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );
  if column_rows <> 8 or correct_types <> 8 or constraint_rows <> 2 then
    raise exception 'Batch-2-Restore abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-2-Restore abgebrochen: privater Snapshot v2 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v2;
  if backup_rows <> 10 then
    raise exception 'Batch-2-Restore abgebrochen: Snapshot v2 hat %/10 Zeilen.', backup_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-2-Restore abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-2-Restore abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;
end $$;

do $$
declare
  locked_rows integer;
  affected_rows integer;
  mismatch_rows integer;
begin
  perform p.id
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Batch-2-Restore abgebrochen: nur %/10 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  update public.products p set
    editorial_note = b.editorial_note,
    updated_at = b.updated_at,
    fuer_wen = b.fuer_wen,
    nicht_fuer = b.nicht_fuer,
    key_fact = b.key_fact,
    pros = b.pros,
    cons = b.cons,
    alternative_slug = b.alternative_slug,
    alternative_reason = b.alternative_reason,
    alternative_kind = b.alternative_kind
  from cbb_private_backup.value_add_pre_backfill_v2 b
  where p.id = b.id and p.slug = b.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 10 then
    raise exception 'Batch-2-Restore abgebrochen: UPDATE traf %/10 Zeilen.', affected_rows;
  end if;

  select count(*) into mismatch_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 b
    on b.id = p.id and b.slug = p.slug
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
  if mismatch_rows <> 0 then
    raise exception 'Batch-2-Restore inkonsistent: % Snapshot-Abweichungen.', mismatch_rows;
  end if;
end $$;

-- Letzter Beleg innerhalb derselben Transaktion: Snapshot und Payload leben
-- weiter, Batch 1 ist unangetastet.
do $$
declare
  snapshot_da boolean;
  payload_da boolean;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into snapshot_da, payload_da, v1_snapshot_da, v1_payload_da;

  if not snapshot_da then
    raise exception 'Batch-2-Restore abgebrochen: Snapshot v2 waehrend des Laufs verschwunden.';
  end if;
  if not v1_snapshot_da or not v1_payload_da then
    raise exception 'Batch-2-Restore abgebrochen: Batch-1-Artefakt waehrend des Laufs verschwunden (snapshot %, payload %).',
      v1_snapshot_da, v1_payload_da;
  end if;
  -- payload_da ist bewusst KEIN Abbruchgrund: laeuft der Restore nach einem
  -- abgebrochenen 03, gibt es noch gar keine Payload v2. Der Zustand wird nur
  -- protokolliert.
  raise notice 'Batch-2-Restore: 10 Zeilen zurueckgespielt. Snapshot v2 erhalten, Payload v2 vorhanden = %, Batch 1 unangetastet.',
    payload_da;
end $$;

commit;
