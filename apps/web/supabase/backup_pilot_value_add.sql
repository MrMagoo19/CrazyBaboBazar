-- ============================================================
-- SICHERUNG — aktuelle Werte der exakt 10 Pilotprodukte
-- ============================================================
-- Zweck: exakter Rollback des Pilot-Backfills.
-- Reihenfolge (auf der ZIEL-DB, NICHT Production):
--   1. pilot_staging_bootstrap.sql (Minimalschema inklusive neuer Spalten)
--   2. pilot_staging_seed.sql      (20 Produkte, Value-Add noch leer)
--   3. backup_pilot_value_add.sql  (DIESE Datei — Snapshot VOR Backfill)
--   4. backfill_pilot_value_add.sql
--
-- Der Snapshot hält id + slug + alle vom Backfill berührten Felder fest.
-- Vor dem Backfill sind die neuen Felder NULL und editorial_note trägt nur
-- bei 3 der 10 Produkte einen Wert — genau dieser Zustand wird gesichert
-- und beim Rollback exakt wiederhergestellt.

begin;

-- Nie ohne den vom Bootstrap angelegten Pilot-Marker schreiben.
do $$
begin
  if to_regclass('pilot_meta.environment_guard') is null then
    raise exception 'Pilot-Backup abgebrochen: Umgebungsmarker fehlt.';
  end if;

  perform 1
  from pilot_meta.environment_guard
  where project_ref = 'nmzuycveumyfvtxdcnuc';

  if not found then
    raise exception 'Pilot-Backup abgebrochen: falscher Umgebungsmarker.';
  end if;
end $$;

-- Eigenes, nicht von der Data API exponiertes Schema. Zusätzlich werden alle
-- Rechte entzogen und RLS ohne öffentliche Policy aktiviert.
create schema if not exists pilot_backup;
revoke all on schema pilot_backup from public, anon, authenticated;

-- Fail closed: Ein Snapshot darf nur exakt einmal, mit allen 10 Pilotzeilen
-- und vor jedem Value-Add-Backfill entstehen. Ein alter Snapshot wird niemals
-- still weiterverwendet oder überschrieben.
do $$
declare
  pilot_rows integer;
  already_filled integer;
begin
  if to_regclass('pilot_backup.value_add_pre_backfill') is not null then
    raise exception 'Pilot-Backup existiert bereits; nicht überschreiben.';
  end if;

  select count(*) into pilot_rows
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben',
    'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver',
    'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  );

  if pilot_rows <> 10 then
    raise exception 'Pilot-Backup abgebrochen: erwartet 10 Pilotzeilen, gefunden %.', pilot_rows;
  end if;

  select count(*) into already_filled
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben',
    'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver',
    'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  )
    and (
      fuer_wen is not null
      or nicht_fuer is not null
      or key_fact is not null
      or pros is not null
      or cons is not null
      or alternative_slug is not null
      or alternative_reason is not null
      or alternative_kind is not null
    );

  if already_filled <> 0 then
    raise exception 'Pilot-Backup abgebrochen: % Pilotzeilen enthalten bereits Value-Add-Daten.', already_filled;
  end if;
end $$;

-- ── SNAPSHOT ────────────────────────────────────────────────
create table pilot_backup.value_add_pre_backfill as
select
  id,
  slug,
  editorial_note,
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
  'pinecil-usbc-loetkolben',
  'divoom-pixoo-led-panel',
  'sculpfun-s9-laser-engraver',
  'arc-reaktor-mk1-schwebend',
  'elektrische-wasserpistole-mit-led',
  'hot-wheels-ultimative-garage-3ft',
  'lego-creator-3in1-retro-kamera-31147',
  'ninja-staysharp-messerset-6-teilig',
  'n4-nussmilchbereiter-pflanzenmilch',
  'welpen-usb-ladekabel-hunde-design'
);

alter table pilot_backup.value_add_pre_backfill
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on pilot_backup.value_add_pre_backfill from public, anon, authenticated;

do $$
declare
  backup_rows integer;
begin
  select count(*) into backup_rows from pilot_backup.value_add_pre_backfill;
  if backup_rows <> 10 then
    raise exception 'Pilot-Backup unvollständig: erwartet 10 Zeilen, gefunden %.', backup_rows;
  end if;
end $$;

commit;

-- Read-only-Kontrolle: muss exakt 10 sein.
select count(*) as backup_rows from pilot_backup.value_add_pre_backfill;

-- ============================================================
-- ROLLBACK (nur bei Bedarf ausführen) — stellt exakt den Snapshot wieder her
-- ============================================================
-- update public.products p set
--   editorial_note     = b.editorial_note,
--   fuer_wen           = b.fuer_wen,
--   nicht_fuer         = b.nicht_fuer,
--   key_fact           = b.key_fact,
--   pros               = b.pros,
--   cons               = b.cons,
--   alternative_slug   = b.alternative_slug,
--   alternative_reason = b.alternative_reason,
--   alternative_kind   = b.alternative_kind
-- from pilot_backup.value_add_pre_backfill b
-- where p.id = b.id;
--
-- Verifikation nach Rollback (erwartet: 0 Zeilen Abweichung):
-- select p.slug from public.products p join pilot_backup.value_add_pre_backfill b on p.id = b.id
-- where p.editorial_note is distinct from b.editorial_note
--    or p.fuer_wen is distinct from b.fuer_wen
--    or p.nicht_fuer is distinct from b.nicht_fuer
--    or p.key_fact is distinct from b.key_fact
--    or p.pros is distinct from b.pros
--    or p.cons is distinct from b.cons
--    or p.alternative_slug is distinct from b.alternative_slug
--    or p.alternative_reason is distinct from b.alternative_reason
--    or p.alternative_kind is distinct from b.alternative_kind;
--
-- Aufräumen (optional, erst wenn Pilot final freigegeben/verworfen):
-- drop table if exists pilot_backup.value_add_pre_backfill;
-- drop schema if exists pilot_backup;
