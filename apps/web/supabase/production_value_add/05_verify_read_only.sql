-- ============================================================================
-- PRODUCTION VALUE-ADD — 05 READ-ONLY NACHPRUEFUNG
-- ============================================================================
-- Genau ein lesendes WITH ... SELECT. Erwartet den privaten Snapshot v1, die
-- persistente Audit-Payload v1 und die vollstaendig migrierten Spalten. Fehlt
-- eines davon, bricht die Planung fail-closed ab. Keine Schreiboperation.
-- ============================================================================

with
target_slugs(slug) as (
  values
    ('pinecil-usbc-loetkolben'), ('divoom-pixoo-led-panel'),
    ('sculpfun-s9-laser-engraver'), ('arc-reaktor-mk1-schwebend'),
    ('elektrische-wasserpistole-mit-led'),
    ('hot-wheels-ultimative-garage-3ft'),
    ('lego-creator-3in1-retro-kamera-31147'),
    ('ninja-staysharp-messerset-6-teilig'),
    ('n4-nussmilchbereiter-pflanzenmilch'),
    ('welpen-usb-ladekabel-hunde-design')
),
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
    )::integer as inkonsistente_relationen
  from public.products p
  join target_slugs t on t.slug = p.slug
),
global_state as (
  select count(*)::integer as value_add_irgendwo
  from public.products p
  where p.fuer_wen is not null
     or p.nicht_fuer is not null
     or p.key_fact is not null
     or p.pros is not null
     or p.cons is not null
     or p.alternative_slug is not null
     or p.alternative_reason is not null
     or p.alternative_kind is not null
),
relation_state as (
  select count(*)::integer as defekte_relationsziele
  from public.products p
  join target_slugs t on t.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true)
),
snapshot_state as (
  select
    count(*)::integer as snapshot_zeilen,
    count(*) filter (where p.updated_at is distinct from b.updated_at)::integer
      as geaenderte_lastmods
  from cbb_private_backup.value_add_pre_backfill_v1 b
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
  from cbb_private_backup.value_add_payload_v1 v
  left join public.products p on p.slug = v.slug
),
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
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    ) as pilot_artefakte,
    (select count(*) from public.products
      where slug = 'divoom-pixoo-led-panel' and price_cents is null)::integer
      as divoom_preis_null,
    (select concat_ws(' | ', tagline, description) from public.products
      where slug = 'n4-nussmilchbereiter-pflanzenmilch') as n4_zeittext
),
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
  select 10 as sortierung, 'produkte' as pruefung, produkte::text as ist,
    'INFO' as erwartet, 'INFO' as status from summary
  union all
  select 20, 'pilot_artefakte', pilot_artefakte::text, '0',
    case when pilot_artefakte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 30, 'schema', (spalten::text || '/8, ' || constraints::text || '/2'),
    '8/8, 2/2',
    case when spalten = 8 and constraints = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 40, 'snapshot_zeilen', snapshot_zeilen::text, '10',
    case when snapshot_zeilen = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 50, 'zielprodukte_published',
    (zielprodukte::text || '/' || published::text), '10/10',
    case when zielprodukte = 10 and published = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 55, 'audit_payload',
    (payload_zeilen::text || ' Zeilen, ' || payload_abweichungen::text || ' Abweichungen'),
    '10 Zeilen, 0 Abweichungen',
    case when payload_zeilen = 10 and payload_abweichungen = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 60, 'vollstaendig_befuellt', vollstaendig_befuellt::text, '10',
    case when vollstaendig_befuellt = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'value_add_irgendwo', value_add_irgendwo::text, '10',
    case when value_add_irgendwo = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 80, 'alternativen', alternativen::text, '3',
    case when alternativen = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 90, 'ergaenzungen', ergaenzungen::text, '2',
    case when ergaenzungen = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'ohne_relation', ohne_relation::text, '5',
    case when ohne_relation = 5 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'inkonsistente_relationen', inkonsistente_relationen::text, '0',
    case when inkonsistente_relationen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'defekte_relationsziele', defekte_relationsziele::text, '0',
    case when defekte_relationsziele = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'geaenderte_lastmods', geaenderte_lastmods::text, '10',
    case when geaenderte_lastmods = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 140, 'divoom_preis_null', divoom_preis_null::text, '1',
    case when divoom_preis_null = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'n4_zeittext_unveraendert', coalesce(n4_zeittext, 'FEHLT'),
    'INFO: bekannter Widerspruch bleibt bestehen', 'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
