-- ============================================================================
-- PRODUCTION VALUE-ADD — 03 PRIVATER SNAPSHOT (SCHREIBEND)
-- ============================================================================
-- Erst nach bestandener Migration und eigener Benutzerfreigabe ausfuehren.
-- Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu
-- Der Snapshot bleibt bestehen, bis der Rollout samt Beobachtungsfenster
-- abgeschlossen ist. Er wird von keinem Artefakt automatisch geloescht.
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
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Production-Backup abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Production-Backup abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Production-Backup abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Production-Backup abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  select count(*) into relation_rows
  from public.products
  where slug in (
    'ifixit-antistatik-matte-faltbar-esd',
    'divoom-minitoo-retro-pc-lautsprecher-pixel',
    'derayee-schaumstoff-wasserpistole',
    'aeropress-go-tragbare-kaffeemaschine',
    'cbdywvr-2in1-ladekabel-mit-staender'
  ) and is_published is true;
  if relation_rows <> 5 then
    raise exception 'Production-Backup abgebrochen: %/5 Relationsziele published.', relation_rows;
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
    raise exception 'Production-Backup abgebrochen: Migration unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null then
    raise exception 'Production-Backup abgebrochen: Snapshot v1 existiert bereits.';
  end if;

  select count(*) into already_filled
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Production-Backup abgebrochen: % Zielprodukte enthalten bereits Value-Add-Daten.',
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
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  )
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Production-Backup abgebrochen: nur %/10 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  select count(*) into already_filled
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  ) and (
    fuer_wen is not null or nicht_fuer is not null or key_fact is not null
    or pros is not null or cons is not null or alternative_slug is not null
    or alternative_reason is not null or alternative_kind is not null
  );
  if already_filled <> 0 then
    raise exception 'Production-Backup abgebrochen: % Zielprodukte wurden waehrend der Vorpruefung befuellt.',
      already_filled;
  end if;
end $$;

create schema if not exists cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

create table cbb_private_backup.value_add_pre_backfill_v1 as
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
  'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
  'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
  'elektrische-wasserpistole-mit-led',
  'hot-wheels-ultimative-garage-3ft',
  'lego-creator-3in1-retro-kamera-31147',
  'ninja-staysharp-messerset-6-teilig',
  'n4-nussmilchbereiter-pflanzenmilch',
  'welpen-usb-ladekabel-hunde-design'
);

alter table cbb_private_backup.value_add_pre_backfill_v1
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v1
  from public, anon, authenticated;

do $$
declare
  backup_rows integer;
begin
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  if backup_rows <> 10 then
    raise exception 'Production-Backup unvollstaendig: %/10 Zeilen.', backup_rows;
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: exakt 10.
select count(*) as backup_rows
from cbb_private_backup.value_add_pre_backfill_v1;
