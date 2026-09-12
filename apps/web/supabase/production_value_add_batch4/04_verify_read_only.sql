-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 4 — 04 READ-ONLY NACHPRUEFUNG (INHALT)
-- ============================================================================
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 03
--      (03_backfill_value_add_batch4.sql). Sie prueft den INHALT. Die
--      Absicherung der Audit-Payload (RLS, Policies, Rechte, Shape) prueft
--      04b_verify_payload_security_read_only.sql — beide Dateien gehoeren
--      zusammen und ersetzen einander nicht.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE,
--      keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
--      steuerung. Nichts an der Datenbank wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu.
--   4. Fehlt der Snapshot v4 oder die Payload v4, scheitert das Statement
--      bewusst hart mit "relation does not exist". Das ist der gewollte
--      fail-closed Ausgang: dann ist der Zustand nach 03 nicht (mehr) gegeben
--      und der Befund ist zu klaeren, nicht zu deuten.
--   5. Bei IRGENDEINEM FAIL: nichts korrigieren, nichts nachtragen, nichts
--      loeschen. Befund melden und Ursache klaeren.
--
-- GRENZE (bewusst, siehe RUNBOOK Abschnitt 8): die Artefakte von Batch 1, 2
-- und 3 werden nur ueber to_regclass geprueft, damit ihr Fehlen als lesbare
-- FAIL-Zeile erscheint statt als Planungsfehler. Der inhaltliche Beleg, dass
-- alle drei unveraendert sind, kommt aus public.products (Zeilen 90 und 100).
--
-- ERWARTETES ERGEBNIS: 20 Zeilen — 16 harte PASS-Zeilen (Sortierung 30 bis 180)
-- und 4 INFO-Zeilen (10, 20, 190, 200). Jede FAIL-Zeile ist ein Befund.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. Innerhalb von Text-Literalen
-- kommt bewusst KEIN Semikolon vor (Trenner in Ausgabetexten ist ' | ').
-- Es kommen ausschliesslich lesende Konstrukte vor (with, select, values,
-- from, join, left join, cross join, where, filter, case, union all, order by)
-- sowie die lesende Katalogfunktion to_regclass.
-- ============================================================================

with
target_slugs(slug) as (
  values
    ('aarke-wasserkocher-edelstahl-1-2l'),
    ('anker-nano-powerbank-magsafe-5000mah'),
    ('dji-osmo-pocket-4-kreativ-combo'),
    ('dyson-zone-absolute-kopfhoerer'),
    ('ferrofluid-sound-visualizer-lampe'),
    ('fontastic-mesu-bluetooth-lautsprecher'),
    ('khadas-mind-2-mini-pc'),
    ('lego-pokemon-bisaflor-glurak-turtok-72153'),
    ('plaud-note-pro-ki-diktiergeraet'),
    ('teenage-engineering-tp7-audio-recorder'),
    ('vivo-x300-ultra-smartphone'),
    ('xgimi-horizon-ultra-4k-projektor')
),
batch1_slugs(slug) as (
  values
    ('pinecil-usbc-loetkolben'),
    ('divoom-pixoo-led-panel'),
    ('sculpfun-s9-laser-engraver'),
    ('arc-reaktor-mk1-schwebend'),
    ('elektrische-wasserpistole-mit-led'),
    ('hot-wheels-ultimative-garage-3ft'),
    ('lego-creator-3in1-retro-kamera-31147'),
    ('ninja-staysharp-messerset-6-teilig'),
    ('n4-nussmilchbereiter-pflanzenmilch'),
    ('welpen-usb-ladekabel-hunde-design')
),
batch2_slugs(slug) as (
  values
    ('livondo-terracotta-pflanzenbewaesserung'),
    ('wixies-wichstuecher-scherzartikel'),
    ('kaffeewaermer-tassenwaermer-elektrisch'),
    ('gluecksgut-anti-stress-wuerfel'),
    ('infactory-boyfriend-kissen'),
    ('scheisse-quartett-kartenspiel'),
    ('riesige-aufblasbare-ente-pool'),
    ('shashibo-formwechsel-box-magnetisch'),
    ('eiswuerfelform-todesstern-star-wars'),
    ('katzenschlafsack-fuer-menschen')
),
batch3_slugs(slug) as (
  values
    ('bartesian-cocktailmaschine-mit-kapseln'),
    ('dicmky-hoehenverstellbarer-schreibtisch-aufsatz'),
    ('laptop-staender-hoehenverstellbar-360-drehbar'),
    ('tecknet-ergonomische-kabellose-maus-bluetooth'),
    ('rocketbook-wiederverwendbares-notizbuch-a4'),
    ('ticktime-tk3-wuerfel-timer-countdown'),
    ('kabeltasche-edc-elektronik-organizer-reise'),
    ('silikon-magnete-airfryer-backpapier-4er-set'),
    ('tre-feuerstahl-xxl'),
    ('bbq-wuerstchenhalter-maennchen-3er-set')
),

-- ---------------------------------------------------------------------------
-- Zustand der zwoelf Batch-4-Zielprodukte (Pruefungen 4, 6, 9, 10, 11, 12)
-- ---------------------------------------------------------------------------
target_state as (
  select
    count(*)::integer as zielprodukte,
    count(*) filter (where p.is_published is true)::integer as published,
    count(*) filter (
      where p.fuer_wen is not null
        and p.nicht_fuer is not null
        and p.key_fact is not null
        and p.pros is not null
        and p.cons is not null
        and p.editorial_note is not null
    )::integer as vollstaendig_befuellt,
    count(*) filter (
      where p.pros is not null
        and array_length(p.pros, 1) between 2 and 4
    )::integer as pros_in_spanne,
    count(*) filter (
      where p.cons is not null
        and array_length(p.cons, 1) >= 1
    )::integer as cons_mindestens_eins,
    count(*) filter (where p.alternative_kind = 'alternative')::integer
      as alternativen,
    count(*) filter (where p.alternative_kind = 'complement')::integer
      as ergaenzungen,
    count(*) filter (
      where p.alternative_kind is null
        and p.alternative_slug is null
        and p.alternative_reason is null
    )::integer as ohne_relation,
    count(*) filter (
      where not (
        (p.alternative_kind is null and p.alternative_slug is null
          and p.alternative_reason is null)
        or
        (p.alternative_kind in ('alternative', 'complement')
          and p.alternative_slug is not null
          and p.alternative_reason is not null)
      )
    )::integer as inkonsistente_relationen,
    coalesce(
      string_agg(
        p.slug || ' -> ' || p.alternative_slug || ' (' || p.alternative_kind || ')',
        ' | ' order by p.slug
      ) filter (where p.alternative_slug is not null),
      'KEINE'
    ) as relationsliste
  from public.products p
  join target_slugs t on t.slug = p.slug
),

-- ---------------------------------------------------------------------------
-- Globalzustand: Batch 1 bis 4, sonst nichts (Pruefungen 7, 8)
-- ---------------------------------------------------------------------------
global_state as (
  select
    (select count(*)
     from public.products p
     where p.fuer_wen is not null
        or p.nicht_fuer is not null
        or p.key_fact is not null
        or p.pros is not null
        or p.cons is not null
        or p.alternative_slug is not null
        or p.alternative_reason is not null
        or p.alternative_kind is not null)::integer as value_add_gesamt,
    (select count(*)
     from public.products p
     join batch1_slugs b on b.slug = p.slug
     where p.fuer_wen is not null
       and p.nicht_fuer is not null
       and p.key_fact is not null
       and p.pros is not null
       and p.cons is not null
       and p.editorial_note is not null)::integer as batch1_vollstaendig,
    (select count(*)
     from public.products p
     join batch2_slugs b on b.slug = p.slug
     where p.fuer_wen is not null
       and p.nicht_fuer is not null
       and p.key_fact is not null
       and p.pros is not null
       and p.cons is not null
       and p.editorial_note is not null)::integer as batch2_vollstaendig,
    (select count(*)
     from public.products p
     join batch3_slugs b on b.slug = p.slug
     where p.fuer_wen is not null
       and p.nicht_fuer is not null
       and p.key_fact is not null
       and p.pros is not null
       and p.cons is not null
       and p.editorial_note is not null)::integer as batch3_vollstaendig
),

-- ---------------------------------------------------------------------------
-- Batch 4 legt keine Relation an. Diese CTE bleibt trotzdem stehen: sie ist der
-- Beleg, dass auch nachtraeglich keine Relation aus der Zielmenge ins Leere
-- zeigt (Pruefung 13).
-- ---------------------------------------------------------------------------
relation_state as (
  select count(*)::integer as defekte_relationsziele
  from public.products p
  join target_slugs t on t.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true)
),

-- ---------------------------------------------------------------------------
-- Snapshot v4 und Payload v4 (Pruefungen 3, 5, 14)
-- ---------------------------------------------------------------------------
snapshot_state as (
  select
    count(*)::integer as snapshot_zeilen,
    count(*) filter (where p.updated_at is distinct from b.updated_at)::integer
      as geaenderte_lastmods
  from cbb_private_backup.value_add_pre_backfill_v4 b
  left join public.products p on p.id = b.id and p.slug = b.slug
),
payload_state as (
  select
    count(*)::integer as payload_zeilen,
    count(*) filter (
      where p.slug is null
         or p.fuer_wen is distinct from v.fuer_wen
         or p.nicht_fuer is distinct from v.nicht_fuer
         or p.key_fact is distinct from v.key_fact
         or p.pros is distinct from v.pros
         or p.cons is distinct from v.cons
         or p.alternative_slug is distinct from v.alternative_slug
         or p.alternative_reason is distinct from v.alternative_reason
         or p.alternative_kind is distinct from v.alternative_kind
         or p.editorial_note is distinct from v.editorial_note
    )::integer as payload_abweichungen
  from cbb_private_backup.value_add_payload_v4 v
  left join public.products p on p.slug = v.slug
),

-- ---------------------------------------------------------------------------
-- Schema und Umgebung (Pruefungen 1, 2, 15, 16)
-- ---------------------------------------------------------------------------
schema_state as (
  select
    (select count(*) from information_schema.columns
      where table_schema = 'public' and table_name = 'products'
        and column_name in (
          'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
          'alternative_slug', 'alternative_reason', 'alternative_kind'
        ))::integer as spalten,
    (select count(*) from pg_constraint
      where conrelid = 'public.products'::regclass
        and contype = 'c'
        and conname in (
          'products_alternative_kind_check',
          'products_alternative_relation_check'
        ))::integer as constraints
),
environment_state as (
  select
    (select count(*) from public.products)::bigint as produkte,
    (select count(*) from public.products where is_published is true)::bigint
      as produkte_published,
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    )::integer as pilot_artefakte,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null
      as v1_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null
      as v1_payload_da,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null
      as v2_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null
      as v2_payload_da,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
      as v3_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v3') is not null
      as v3_payload_da
),

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from target_state
  cross join global_state
  cross join relation_state
  cross join snapshot_state
  cross join payload_state
  cross join schema_state
  cross join environment_state
),

checks as (
  select
    10 as sortierung,
    'current_user'::text as pruefung,
    current_user::text as ist,
    'INFO'::text as erwartet,
    'INFO'::text as status
  union all
  select 20, 'current_database', current_database()::text, 'INFO', 'INFO'
  union all
  -- 1
  select 30, 'pilot_artefakte', pilot_artefakte::text, '0',
    case when pilot_artefakte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 2
  select 40, 'value_add_schema',
    spalten::text || '/8 Spalten | ' || constraints::text || '/2 Constraints',
    '8/8 Spalten | 2/2 Constraints',
    case when spalten = 8 and constraints = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'snapshot_v4_zeilen', snapshot_zeilen::text, '12',
    case when snapshot_zeilen = 12 then 'PASS' else 'FAIL' end from summary
  union all
  -- 4
  select 60, 'zielprodukte_published',
    zielprodukte::text || '/' || published::text, '12/12',
    case when zielprodukte = 12 and published = 12 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'audit_payload_v4',
    payload_zeilen::text || ' Zeilen | ' || payload_abweichungen::text
      || ' Abweichungen',
    '12 Zeilen | 0 Abweichungen',
    case when payload_zeilen = 12 and payload_abweichungen = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'zielprodukte_vollstaendig_befuellt',
    vollstaendig_befuellt::text || ' vollstaendig | ' || pros_in_spanne::text
      || ' mit 2-4 pros | ' || cons_mindestens_eins::text || ' mit >= 1 cons',
    '12 vollstaendig | 12 mit 2-4 pros | 12 mit >= 1 cons',
    case when vollstaendig_befuellt = 12 and pros_in_spanne = 12
           and cons_mindestens_eins = 12
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'value_add_gesamt', value_add_gesamt::text,
    '42 (10 aus Batch 1 + 10 aus Batch 2 + 10 aus Batch 3 + 12 aus Batch 4)',
    case when value_add_gesamt = 42 then 'PASS' else 'FAIL' end from summary
  union all
  -- 8
  select 100, 'vorgaenger_befuellung_intakt',
    'Batch 1 ' || batch1_vollstaendig::text || ' | Batch 2 '
      || batch2_vollstaendig::text || ' | Batch 3 '
      || batch3_vollstaendig::text,
    'Batch 1 10 | Batch 2 10 | Batch 3 10',
    case when batch1_vollstaendig = 10 and batch2_vollstaendig = 10
           and batch3_vollstaendig = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'alternativen', alternativen::text, '0',
    case when alternativen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 10
  select 120, 'ergaenzungen', ergaenzungen::text, '0',
    case when ergaenzungen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 11
  select 130, 'ohne_relation', ohne_relation::text, '12',
    case when ohne_relation = 12 then 'PASS' else 'FAIL' end from summary
  union all
  -- 12
  select 140, 'inkonsistente_relationen', inkonsistente_relationen::text, '0',
    case when inkonsistente_relationen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 13
  select 150, 'defekte_relationsziele', defekte_relationsziele::text, '0',
    case when defekte_relationsziele = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 14
  select 160, 'geaenderte_lastmods', geaenderte_lastmods::text, '12',
    case when geaenderte_lastmods = 12 then 'PASS' else 'FAIL' end from summary
  union all
  -- 15
  select 170, 'vorgaenger_artefakte_vorhanden',
    'snapshot v1 ' || v1_snapshot_da::text
      || ' | payload v1 ' || v1_payload_da::text
      || ' | snapshot v2 ' || v2_snapshot_da::text
      || ' | payload v2 ' || v2_payload_da::text
      || ' | snapshot v3 ' || v3_snapshot_da::text
      || ' | payload v3 ' || v3_payload_da::text,
    'alle sechs true',
    case when v1_snapshot_da and v1_payload_da
           and v2_snapshot_da and v2_payload_da
           and v3_snapshot_da and v3_payload_da
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 16
  select 180, 'produkte_mindestens_300', produkte::text, '>= 300',
    case when produkte >= 300 then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'produkte_gesamt_und_published',
    produkte::text || ' gesamt | ' || produkte_published::text || ' published',
    'INFO: am 2026-08-26 waren es 376 gesamt und 372 published',
    'INFO' from summary
  union all
  select 200, 'relationsliste', relationsliste,
    'INFO: erwartet ist KEINE — Batch 4 legt bewusst keine Relation an',
    'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
