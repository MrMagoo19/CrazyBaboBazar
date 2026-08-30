-- ============================================================================
-- FIXTURE 03 — Die privaten Artefakte von BATCH 1 und BATCH 2
-- ============================================================================
-- Batch 3 verlangt in jedem schreibenden Guard, dass
--   cbb_private_backup.value_add_pre_backfill_v1
--   cbb_private_backup.value_add_payload_v1
--   cbb_private_backup.value_add_pre_backfill_v2
--   cbb_private_backup.value_add_payload_v2
-- existieren, und darf sie unter keinen Umstaenden veraendern. Ohne diese
-- Fixture wuerde der Harness die Vorgaenger-Guards gar nicht erst erreichen.
--
-- WICHTIG — Snapshot und Payload haben unterschiedliche Zeitstaende:
--   * value_add_pre_backfill_vN haelt den Zustand VOR dem jeweiligen Backfill:
--     alle acht Value-Add-Felder NULL, dazu die damaligen editorial_note-Texte
--     und historischen updated_at-Werte.
--   * value_add_payload_vN haelt den Zustand NACH dem jeweiligen Backfill und
--     ist deshalb aus public.products abgeleitet — sie stimmt per Konstruktion
--     mit dem aktuellen Bestand ueberein.
--
-- Diese Datei baut die Struktur nach, die die Originaldateien der Chargen 1
-- und 2 erzeugen: 12 bzw. 10 Spalten, Primaerschluessel, UNIQUE(slug) beim
-- Snapshot, RLS an, keine Policies, keine Rechte fuer PUBLIC/anon/authenticated.
-- Die Originaldateien werden dabei NICHT ausgefuehrt und NICHT veraendert —
-- Batch 1 und Batch 2 gelten hier als bereits abgeschlossene Zustaende.
-- CASE 0 des Harness belegt zusaetzlich per sha256, dass beide Verzeichnisse
-- byteweise unangetastet sind.
-- ============================================================================

create schema cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Snapshot v1 — Zustand VOR dem Batch-1-Backfill.
-- Drei Slugs trugen damals bereits eine editorial_note (ninja, n4, welpen).
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

-- ----------------------------------------------------------------------------
-- Snapshot v2 — Zustand VOR dem Batch-2-Backfill. Auf Production trugen alle
-- zehn Zielzeilen bereits eine editorial_note.
-- ----------------------------------------------------------------------------
create table cbb_private_backup.value_add_pre_backfill_v2 as
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
  ('livondo-terracotta-pflanzenbewaesserung',
     'B2-ALT-NOTE livondo: Text vor dem Batch-2-Backfill.'::text,
     timestamptz '2026-06-01 11:15:00+00'),
  ('wixies-wichstuecher-scherzartikel',
     'B2-ALT-NOTE wixies: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-02 12:20:00+00'),
  ('kaffeewaermer-tassenwaermer-elektrisch',
     'B2-ALT-NOTE kaffeewaermer: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-03 13:25:00+00'),
  ('gluecksgut-anti-stress-wuerfel',
     'B2-ALT-NOTE gluecksgut: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-04 14:30:00+00'),
  ('infactory-boyfriend-kissen',
     'B2-ALT-NOTE infactory: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-07-05 15:35:00+00'),
  ('scheisse-quartett-kartenspiel',
     'B2-ALT-NOTE quartett: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-06 16:40:00+00'),
  ('riesige-aufblasbare-ente-pool',
     'B2-ALT-NOTE ente: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-07 17:45:00+00'),
  ('shashibo-formwechsel-box-magnetisch',
     'B2-ALT-NOTE shashibo: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-08 18:50:00+00'),
  ('eiswuerfelform-todesstern-star-wars',
     'B2-ALT-NOTE todesstern: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-07-09 19:55:00+00'),
  ('katzenschlafsack-fuer-menschen',
     'B2-ALT-NOTE katzenschlafsack: Text vor dem Batch-2-Backfill.',
     timestamptz '2026-06-10 20:00:00+00')
) as v(slug, editorial_note, updated_at) on v.slug = p.slug;

alter table cbb_private_backup.value_add_pre_backfill_v2
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_pre_backfill_v2
  from public, anon, authenticated;

create table cbb_private_backup.value_add_payload_v2 as
select
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
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

alter table cbb_private_backup.value_add_payload_v2
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v2
  from public, anon, authenticated;

do $$
declare
  v1_snapshot integer;
  v1_payload integer;
  v2_snapshot integer;
  v2_payload integer;
  v1_snapshot_spalten integer;
  v2_snapshot_spalten integer;
  v1_payload_spalten integer;
  v2_payload_spalten integer;
  value_add_in_snapshots integer;
  payload_drift integer;
begin
  select count(*) into v1_snapshot from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into v1_payload  from cbb_private_backup.value_add_payload_v1;
  select count(*) into v2_snapshot from cbb_private_backup.value_add_pre_backfill_v2;
  select count(*) into v2_payload  from cbb_private_backup.value_add_payload_v2;
  if v1_snapshot <> 10 or v1_payload <> 10 or v2_snapshot <> 10 or v2_payload <> 10 then
    raise exception 'Vorgaenger-Fixture kaputt: Zeilen % / % / % / % (erwartet je 10).',
      v1_snapshot, v1_payload, v2_snapshot, v2_payload;
  end if;

  select count(*) into v1_snapshot_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
    and attnum > 0 and not attisdropped;
  select count(*) into v2_snapshot_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_pre_backfill_v2'::regclass
    and attnum > 0 and not attisdropped;
  select count(*) into v1_payload_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_payload_v1'::regclass
    and attnum > 0 and not attisdropped;
  select count(*) into v2_payload_spalten from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_payload_v2'::regclass
    and attnum > 0 and not attisdropped;
  if v1_snapshot_spalten <> 12 or v2_snapshot_spalten <> 12
     or v1_payload_spalten <> 10 or v2_payload_spalten <> 10 then
    raise exception 'Vorgaenger-Fixture kaputt: Spalten % / % (Snapshots, erwartet 12) und % / % (Payloads, erwartet 10).',
      v1_snapshot_spalten, v2_snapshot_spalten, v1_payload_spalten, v2_payload_spalten;
  end if;

  select
    (select count(*) from cbb_private_backup.value_add_pre_backfill_v1
      where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
         or pros is not null or cons is not null or alternative_slug is not null
         or alternative_reason is not null or alternative_kind is not null)
    + (select count(*) from cbb_private_backup.value_add_pre_backfill_v2
      where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
         or pros is not null or cons is not null or alternative_slug is not null
         or alternative_reason is not null or alternative_kind is not null)
  into value_add_in_snapshots;
  if value_add_in_snapshots <> 0 then
    raise exception 'Vorgaenger-Fixture kaputt: % Snapshot-Zeilen tragen Value-Add-Daten (erwartet 0).',
      value_add_in_snapshots;
  end if;

  select
    (select count(*) from cbb_private_backup.value_add_payload_v1 v
      left join public.products p on p.slug = v.slug
      where p.slug is null
         or p.fuer_wen is distinct from v.fuer_wen
         or p.editorial_note is distinct from v.editorial_note)
    + (select count(*) from cbb_private_backup.value_add_payload_v2 v
      left join public.products p on p.slug = v.slug
      where p.slug is null
         or p.fuer_wen is distinct from v.fuer_wen
         or p.editorial_note is distinct from v.editorial_note)
  into payload_drift;
  if payload_drift <> 0 then
    raise exception 'Vorgaenger-Fixture kaputt: % Payload-Zeilen weichen vom Bestand ab.',
      payload_drift;
  end if;

  raise notice 'Vorgaenger-Artefakte OK: v1 und v2 je Snapshot 10/12 und Payload 10/10, RLS an, keine App-Rechte.';
end $$;
