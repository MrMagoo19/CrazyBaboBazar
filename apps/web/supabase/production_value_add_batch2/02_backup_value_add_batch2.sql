-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 2 — 02 PRIVATER SNAPSHOT (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Erst nach einem FAIL-freien 01_preflight_read_only.sql ausfuehren.
--
-- Der Snapshot heisst cbb_private_backup.value_add_pre_backfill_v2 und ist
-- strikt getrennt von den Batch-1-Artefakten. Batch 1 wird von dieser Datei
-- ausschliesslich GELESEN (Existenzpruefung) und nie veraendert:
--   cbb_private_backup.value_add_pre_backfill_v1  — nur to_regclass
--   cbb_private_backup.value_add_payload_v1       — nur to_regclass
--
-- KEINE SCHEMA-MIGRATION: die acht Value-Add-Spalten und die zwei
-- CHECK-Constraints existieren auf Production bereits. Diese Datei legt
-- ausschliesslich eine private Sicherungskopie der zehn Zielzeilen an.
--
-- Der Snapshot bleibt bestehen, bis der Rollout samt Beobachtungsfenster
-- abgeschlossen ist. Er wird von keinem Artefakt dieses Verzeichnisses
-- geloescht — auch 05_restore_value_add_batch2.sql loescht ihn nicht.
--
-- WIEDERHOLUNGSVERHALTEN: existiert value_add_pre_backfill_v2 bereits, bricht
-- die Datei fail-closed ab. Sie ueberschreibt und ersetzt niemals.
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
  relation_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
  already_filled integer;
  batch1_overlap integer;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung: keine Pilot-Artefakte, vollstaendiger Production-Fingerprint
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-2-Backup abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-2-Backup abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-2-Backup abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Zielmenge Batch 2: exakt zehn, alle published
  -- ---------------------------------------------------------------------
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
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Batch-2-Backup abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Beide Relationsziele liegen innerhalb der Batch-2-Zielmenge und muessen
  -- published sein, sonst zeigt eine Relation spaeter ins Leere.
  -- ---------------------------------------------------------------------
  select count(*) into relation_rows
  from public.products
  where slug in (
    'gluecksgut-anti-stress-wuerfel',
    'shashibo-formwechsel-box-magnetisch'
  ) and is_published is true;
  if relation_rows <> 2 then
    raise exception 'Batch-2-Backup abgebrochen: %/2 Relationsziele published.', relation_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Disjunktheit gegen Batch 1: kein Slug darf in beiden Mengen stehen.
  -- ---------------------------------------------------------------------
  select count(*) into batch1_overlap
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
  ) and slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  );
  if batch1_overlap <> 0 then
    raise exception 'Batch-2-Backup abgebrochen: % Slug(s) liegen in Batch 1 und Batch 2.',
      batch1_overlap;
  end if;

  -- ---------------------------------------------------------------------
  -- Value-Add-Schema muss VOLLSTAENDIG vorhanden sein. Batch 2 migriert nicht.
  -- ---------------------------------------------------------------------
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
    raise exception 'Batch-2-Backup abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Batch 1 muss unveraendert vorliegen. Nur Existenzpruefung, kein Zugriff
  -- auf den Inhalt und kein Schreibzugriff.
  -- ---------------------------------------------------------------------
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-2-Backup abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-2-Backup abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;

  -- ---------------------------------------------------------------------
  -- Batch-2-Snapshot darf noch nicht existieren. Niemals ueberschreiben.
  -- ---------------------------------------------------------------------
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null then
    raise exception 'Batch-2-Backup abgebrochen: Snapshot v2 existiert bereits.';
  end if;

  -- ---------------------------------------------------------------------
  -- Zielzeilen tragen noch keine Value-Add-Daten.
  -- ---------------------------------------------------------------------
  select count(*) into already_filled
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
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Batch-2-Backup abgebrochen: % Zielprodukte enthalten bereits Value-Add-Daten.',
      already_filled;
  end if;
end $$;

-- Zwischen Vorpruefung und Snapshot darf keine Zielzeile veraendert werden.
do $$
declare
  locked_rows integer;
  already_filled integer;
begin
  perform p.id
  from public.products p
  where p.slug in (
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
  )
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Batch-2-Backup abgebrochen: nur %/10 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  select count(*) into already_filled
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
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Batch-2-Backup abgebrochen: % Zielprodukte wurden waehrend der Vorpruefung befuellt.',
      already_filled;
  end if;
end $$;

-- Das Schema existiert seit Batch 1. `if not exists` und das erneute REVOKE
-- sind idempotent und aendern an einem bereits korrekt abgesicherten Schema
-- nichts — sie halten den Pfad aber auch dann geschlossen, wenn Batch 2 in
-- einer Umgebung laeuft, in der das Schema noch nicht abgesichert waere.
create schema if not exists cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

create table cbb_private_backup.value_add_pre_backfill_v2 as
select
  id,
  slug,
  editorial_note,
  updated_at,
  fuer_wen,
  nicht_fuer,
  key_fact,
  pros,
  cons,
  alternative_slug,
  alternative_reason,
  alternative_kind
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

alter table cbb_private_backup.value_add_pre_backfill_v2
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v2
  from public, anon, authenticated;

do $$
declare
  backup_rows integer;
  value_add_rows integer;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
begin
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v2;
  if backup_rows <> 10 then
    raise exception 'Batch-2-Backup unvollstaendig: %/10 Zeilen.', backup_rows;
  end if;

  select count(*) into value_add_rows
  from cbb_private_backup.value_add_pre_backfill_v2
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_rows <> 0 then
    raise exception 'Batch-2-Backup inkonsistent: % Snapshot-Zeilen tragen bereits Value-Add-Daten.',
      value_add_rows;
  end if;

  -- Letzter Beleg innerhalb derselben Transaktion: Batch 1 ist noch da.
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into v1_snapshot_da, v1_payload_da;
  if not v1_snapshot_da or not v1_payload_da then
    raise exception 'Batch-2-Backup abgebrochen: Batch-1-Artefakt waehrend des Laufs verschwunden (snapshot %, payload %).',
      v1_snapshot_da, v1_payload_da;
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: exakt 10.
select count(*) as backup_rows
from cbb_private_backup.value_add_pre_backfill_v2;
