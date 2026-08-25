-- ============================================================================
-- FIXTURE 03 — Die privaten BATCH-1-Artefakte, wie sie auf Production liegen
-- ============================================================================
-- Batch 2 verlangt in jedem schreibenden Guard, dass
--   cbb_private_backup.value_add_pre_backfill_v1  und
--   cbb_private_backup.value_add_payload_v1
-- existieren, und darf sie unter keinen Umstaenden veraendern. Ohne diese
-- Fixture wuerde der Harness die Batch-1-Guards gar nicht erst erreichen.
--
-- WICHTIG — die beiden Tabellen haben unterschiedliche Zeitstaende:
--   * value_add_pre_backfill_v1 haelt den Zustand VOR dem Batch-1-Backfill:
--     alle acht Value-Add-Felder NULL, die drei damals bestehenden
--     editorial_note-Texte und die historischen updated_at-Werte.
--   * value_add_payload_v1 haelt den Zustand NACH dem Batch-1-Backfill und ist
--     deshalb aus public.products abgeleitet — sie stimmt per Konstruktion mit
--     dem aktuellen Bestand ueberein.
--
-- Diese Datei baut die Struktur nach, die 03_backup_value_add.sql und
-- 04_backfill_value_add.sql aus dem Verzeichnis production_value_add erzeugen:
-- 12 bzw. 10 Spalten, Primaerschluessel, UNIQUE(slug) beim Snapshot, RLS an,
-- keine Policies, keine Rechte fuer PUBLIC/anon/authenticated.
-- Die Originaldateien aus production_value_add werden dabei NICHT ausgefuehrt
-- und NICHT veraendert — Batch 1 gilt hier als bereits abgeschlossener Zustand.
-- ============================================================================

create schema cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Snapshot v1 — Zustand VOR dem Batch-1-Backfill.
-- Drei Slugs trugen damals bereits eine editorial_note (ninja, n4, welpen),
-- die anderen sieben nicht. Die acht Value-Add-Felder waren alle NULL.
-- ----------------------------------------------------------------------------
create table cbb_private_backup.value_add_pre_backfill_v1 as
select
  p.id,
  p.slug,
  v.editorial_note,
  v.updated_at,
  null::text   as fuer_wen,
  null::text   as nicht_fuer,
  null::text   as key_fact,
  null::text[] as pros,
  null::text[] as cons,
  null::text   as alternative_slug,
  null::text   as alternative_reason,
  null::text   as alternative_kind
from public.products p
join (values
  ('pinecil-usbc-loetkolben',
     null::text, timestamptz '2026-03-01 11:15:00+00'),
  ('divoom-pixoo-led-panel',
     null, timestamptz '2026-03-02 12:20:00+00'),
  ('sculpfun-s9-laser-engraver',
     null, timestamptz '2026-03-03 13:25:00+00'),
  ('arc-reaktor-mk1-schwebend',
     null, timestamptz '2026-03-04 14:30:00+00'),
  ('elektrische-wasserpistole-mit-led',
     null, timestamptz '2026-03-05 15:35:00+00'),
  ('hot-wheels-ultimative-garage-3ft',
     null, timestamptz '2026-03-06 16:40:00+00'),
  ('lego-creator-3in1-retro-kamera-31147',
     null, timestamptz '2026-03-07 17:45:00+00'),
  ('ninja-staysharp-messerset-6-teilig',
     'B1-ALT-NOTE ninja: Text vor dem Batch-1-Backfill.',
     timestamptz '2026-07-04 18:50:00+00'),
  ('n4-nussmilchbereiter-pflanzenmilch',
     'B1-ALT-NOTE n4: Text vor dem Batch-1-Backfill.',
     timestamptz '2026-07-04 19:55:00+00'),
  ('welpen-usb-ladekabel-hunde-design',
     'B1-ALT-NOTE welpen: Text vor dem Batch-1-Backfill.',
     timestamptz '2026-07-04 20:00:00+00')
) as v(slug, editorial_note, updated_at) on v.slug = p.slug;

alter table cbb_private_backup.value_add_pre_backfill_v1
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v1
  from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Payload v1 — Zustand NACH dem Batch-1-Backfill, aus dem Bestand abgeleitet.
-- ----------------------------------------------------------------------------
create table cbb_private_backup.value_add_payload_v1 as
select
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
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

alter table cbb_private_backup.value_add_payload_v1
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v1
  from public, anon, authenticated;

do $$
declare
  snapshot_zeilen integer;
  payload_zeilen integer;
  snapshot_spalten integer;
  payload_spalten integer;
  snapshot_value_add integer;
  payload_drift integer;
begin
  select count(*) into snapshot_zeilen
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_zeilen
  from cbb_private_backup.value_add_payload_v1;

  select count(*) into snapshot_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
    and attnum > 0 and not attisdropped;
  select count(*) into payload_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_payload_v1'::regclass
    and attnum > 0 and not attisdropped;

  select count(*) into snapshot_value_add
  from cbb_private_backup.value_add_pre_backfill_v1
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select count(*) into payload_drift
  from cbb_private_backup.value_add_payload_v1 v
  left join public.products p on p.slug = v.slug
  where p.slug is null
     or p.fuer_wen is distinct from v.fuer_wen
     or p.nicht_fuer is distinct from v.nicht_fuer
     or p.key_fact is distinct from v.key_fact
     or p.pros is distinct from v.pros
     or p.cons is distinct from v.cons
     or p.alternative_slug is distinct from v.alternative_slug
     or p.alternative_reason is distinct from v.alternative_reason
     or p.alternative_kind is distinct from v.alternative_kind
     or p.editorial_note is distinct from v.editorial_note;

  if snapshot_zeilen <> 10 or payload_zeilen <> 10 then
    raise exception 'Batch-1-Fixture kaputt: Snapshot %/10, Payload %/10 Zeilen.',
      snapshot_zeilen, payload_zeilen;
  end if;
  if snapshot_spalten <> 12 or payload_spalten <> 10 then
    raise exception 'Batch-1-Fixture kaputt: Snapshot % Spalten (erwartet 12), Payload % Spalten (erwartet 10).',
      snapshot_spalten, payload_spalten;
  end if;
  if snapshot_value_add <> 0 then
    raise exception 'Batch-1-Fixture kaputt: % Snapshot-Zeilen tragen Value-Add-Daten (erwartet 0).',
      snapshot_value_add;
  end if;
  if payload_drift <> 0 then
    raise exception 'Batch-1-Fixture kaputt: % Payload-Zeilen weichen vom Bestand ab.',
      payload_drift;
  end if;

  raise notice 'Batch-1-Artefakte OK: Snapshot 10/12, Payload 10/10, RLS an, keine App-Rechte.';
end $$;
