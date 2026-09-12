-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 4 — 02 PRIVATER SNAPSHOT (SCHREIBEND)
-- ============================================================================
-- WARNUNG — SCHREIBENDE DATEI:
--   Diese Datei veraendert die Datenbank. Sie darf NUR mit einer eigenen,
--   ausdruecklichen Benutzerfreigabe ausgefuehrt werden. Vor dem Start ist im
--   SQL-Editor SICHTBAR gegenzupruefen, dass exakt dieses Projekt ausgewaehlt
--   ist:
--     project/ydiihvzcxaaoqhmgoqvu
--   Pilot/Staging (nmzuycveumyfvtxdcnuc) ist KEIN Ziel dieses Changesets. Wer
--   die Projektkennung nicht sichtbar geprueft hat, fuehrt diese Datei nicht
--   aus.
--
-- Erst nach einem FAIL-freien 01_preflight_read_only.sql ausfuehren.
--
-- Der Snapshot heisst cbb_private_backup.value_add_pre_backfill_v4 und ist
-- strikt getrennt von den Artefakten der Chargen 1, 2 und 3. Diese werden von
-- dieser Datei ausschliesslich GELESEN (Existenzpruefung) und nie veraendert:
--   cbb_private_backup.value_add_pre_backfill_v1  — nur to_regclass
--   cbb_private_backup.value_add_payload_v1       — nur to_regclass
--   cbb_private_backup.value_add_pre_backfill_v2  — nur to_regclass
--   cbb_private_backup.value_add_payload_v2       — nur to_regclass
--   cbb_private_backup.value_add_pre_backfill_v3  — nur to_regclass
--   cbb_private_backup.value_add_payload_v3       — nur to_regclass
--
-- KEINE SCHEMA-MIGRATION: die acht Value-Add-Spalten und die zwei
-- CHECK-Constraints existieren auf Production bereits. Diese Datei legt
-- ausschliesslich eine private Sicherungskopie der zwoelf Zielzeilen an.
--
-- Der Snapshot bleibt bestehen, bis der Rollout samt Beobachtungsfenster
-- abgeschlossen ist. Er wird von keinem Artefakt dieses Verzeichnisses
-- geloescht — auch 05_restore_value_add_batch4.sql loescht ihn nicht.
--
-- WIEDERHOLUNGSVERHALTEN: existiert value_add_pre_backfill_v4 bereits, bricht
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
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
  already_filled integer;
  vorgaenger_overlap integer;
  befuellt_gesamt integer;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung: keine Pilot-Artefakte, vollstaendiger Production-Fingerprint
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-4-Backup abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-4-Backup abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-4-Backup abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Zielmenge Batch 4: exakt zwoelf, alle published
  -- ---------------------------------------------------------------------
  select count(*) into target_rows
  from public.products
  where slug in (
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  ) and is_published is true;
  if target_rows <> 12 then
    raise exception 'Batch-4-Backup abgebrochen: %/12 Zielprodukte published.', target_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- KEINE RELATIONSZIELE: Batch 4 legt bewusst keine Relation an. Alle zwoelf
  -- Zeilen bekommen alternative_slug, alternative_reason und alternative_kind
  -- als NULL. Es gibt deshalb keine Relationsziel-Pruefung wie in Batch 3.
  -- ---------------------------------------------------------------------

  -- ---------------------------------------------------------------------
  -- Disjunktheit gegen Batch 1, Batch 2 UND Batch 3: kein Slug darf mehrfach
  -- vorkommen. Alle drei Vorgaengermengen stehen hier als Literale.
  -- ---------------------------------------------------------------------
  select count(*) into vorgaenger_overlap
  from public.products
  where slug in (
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  ) and slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design',
    'livondo-terracotta-pflanzenbewaesserung',
    'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch',
    'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen',
    'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool',
    'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars',
    'katzenschlafsack-fuer-menschen',
    'bartesian-cocktailmaschine-mit-kapseln',
    'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'tecknet-ergonomische-kabellose-maus-bluetooth',
    'rocketbook-wiederverwendbares-notizbuch-a4',
    'ticktime-tk3-wuerfel-timer-countdown',
    'kabeltasche-edc-elektronik-organizer-reise',
    'silikon-magnete-airfryer-backpapier-4er-set',
    'tre-feuerstahl-xxl',
    'bbq-wuerstchenhalter-maennchen-3er-set'
  );
  if vorgaenger_overlap <> 0 then
    raise exception 'Batch-4-Backup abgebrochen: % Slug(s) liegen bereits in Batch 1, 2 oder 3.',
      vorgaenger_overlap;
  end if;

  -- ---------------------------------------------------------------------
  -- Value-Add-Schema muss VOLLSTAENDIG vorhanden sein. Batch 4 migriert nicht.
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
    raise exception 'Batch-4-Backup abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Batch 1, 2 und 3 muessen unveraendert vorliegen. Nur Existenzpruefung,
  -- kein Zugriff auf den Inhalt und kein Schreibzugriff.
  -- ---------------------------------------------------------------------
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-2-Snapshot v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-2-Payload v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-3-Snapshot v3 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v3') is null then
    raise exception 'Batch-4-Backup abgebrochen: Batch-3-Payload v3 fehlt.';
  end if;

  -- ---------------------------------------------------------------------
  -- Batch-4-Snapshot darf noch nicht existieren. Niemals ueberschreiben.
  -- ---------------------------------------------------------------------
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v4') is not null then
    raise exception 'Batch-4-Backup abgebrochen: Snapshot v4 existiert bereits.';
  end if;

  -- ---------------------------------------------------------------------
  -- Zielzeilen tragen noch keine Value-Add-Daten. Diese spezifische Pruefung
  -- steht bewusst vor der globalen Zaehlung: eine fremdbefuellte Zielzeile
  -- soll als solche gemeldet werden und nicht als "31 Zeilen tragen
  -- Value-Add-Daten".
  -- ---------------------------------------------------------------------
  select count(*) into already_filled
  from public.products
  where slug in (
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Batch-4-Backup abgebrochen: % Zielprodukte enthalten bereits Value-Add-Daten.',
      already_filled;
  end if;

  -- Inhaltlicher Beleg aus public.products: genau 30 befuellte Zeilen. Weniger
  -- hiesse beschaedigte Vorgaenger, mehr ein Treffer ausserhalb der Zielmengen.
  select count(*) into befuellt_gesamt
  from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if befuellt_gesamt <> 30 then
    raise exception 'Batch-4-Backup abgebrochen: % Zeilen tragen Value-Add-Daten (erwartet 30).',
      befuellt_gesamt;
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
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  )
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 12 then
    raise exception 'Batch-4-Backup abgebrochen: nur %/12 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  select count(*) into already_filled
  from public.products
  where slug in (
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Batch-4-Backup abgebrochen: % Zielprodukte wurden waehrend der Vorpruefung befuellt.',
      already_filled;
  end if;
end $$;

-- Das Schema existiert seit Batch 1. `if not exists` und das erneute REVOKE
-- sind idempotent und aendern an einem bereits korrekt abgesicherten Schema
-- nichts — sie halten den Pfad aber auch dann geschlossen, wenn Batch 4 in
-- einer Umgebung laeuft, in der das Schema noch nicht abgesichert waere.
create schema if not exists cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

create table cbb_private_backup.value_add_pre_backfill_v4 as
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
  'aarke-wasserkocher-edelstahl-1-2l',
  'anker-nano-powerbank-magsafe-5000mah',
  'dji-osmo-pocket-4-kreativ-combo',
  'dyson-zone-absolute-kopfhoerer',
  'ferrofluid-sound-visualizer-lampe',
  'fontastic-mesu-bluetooth-lautsprecher',
  'khadas-mind-2-mini-pc',
  'lego-pokemon-bisaflor-glurak-turtok-72153',
  'plaud-note-pro-ki-diktiergeraet',
  'teenage-engineering-tp7-audio-recorder',
  'vivo-x300-ultra-smartphone',
  'xgimi-horizon-ultra-4k-projektor'
);

alter table cbb_private_backup.value_add_pre_backfill_v4
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v4
  from public, anon, authenticated;

do $$
declare
  backup_rows integer;
  value_add_rows integer;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  v3_snapshot_da boolean;
  v3_payload_da boolean;
begin
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v4;
  if backup_rows <> 12 then
    raise exception 'Batch-4-Backup unvollstaendig: %/12 Zeilen.', backup_rows;
  end if;

  select count(*) into value_add_rows
  from cbb_private_backup.value_add_pre_backfill_v4
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_rows <> 0 then
    raise exception 'Batch-4-Backup inkonsistent: % Snapshot-Zeilen tragen bereits Value-Add-Daten.',
      value_add_rows;
  end if;

  -- Letzter Beleg innerhalb derselben Transaktion: alle drei Vorgaenger sind da.
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v3') is not null
  into v1_snapshot_da, v1_payload_da, v2_snapshot_da, v2_payload_da,
       v3_snapshot_da, v3_payload_da;
  if not v1_snapshot_da or not v1_payload_da
     or not v2_snapshot_da or not v2_payload_da
     or not v3_snapshot_da or not v3_payload_da then
    raise exception 'Batch-4-Backup abgebrochen: Vorgaenger-Artefakt waehrend des Laufs verschwunden (v1 %/%, v2 %/%, v3 %/%).',
      v1_snapshot_da, v1_payload_da, v2_snapshot_da, v2_payload_da,
      v3_snapshot_da, v3_payload_da;
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: exakt 12.
select count(*) as backup_rows
from cbb_private_backup.value_add_pre_backfill_v4;
