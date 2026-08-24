-- ============================================================================
-- PRODUCTION VALUE-ADD — 01 READ-ONLY PREFLIGHT
-- ============================================================================
-- Zielprojekt ausserhalb von SQL sichtbar pruefen:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Dieses Artefakt ist genau ein lesendes WITH ... SELECT. Es veraendert weder
-- Schema noch Daten. PostgreSQL kennt die Supabase-Projekt-Ref nicht; die
-- Tabellen-Fingerprints sind nur ein zusaetzlicher Fail-closed-Beleg.
-- Fehlt public.products vollstaendig, bricht bereits die Planung fail-closed ab.
-- ============================================================================

with
target_slugs(slug) as (
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
relation_slugs(slug) as (
  values
    ('ifixit-antistatik-matte-faltbar-esd'),
    ('divoom-minitoo-retro-pc-lautsprecher-pixel'),
    ('derayee-schaumstoff-wasserpistole'),
    ('aeropress-go-tragbare-kaffeemaschine'),
    ('cbdywvr-2in1-ladekabel-mit-staender')
),
expected_columns(column_name, data_type, udt_name) as (
  values
    ('fuer_wen', 'text', 'text'),
    ('nicht_fuer', 'text', 'text'),
    ('key_fact', 'text', 'text'),
    ('pros', 'ARRAY', '_text'),
    ('cons', 'ARRAY', '_text'),
    ('alternative_slug', 'text', 'text'),
    ('alternative_reason', 'text', 'text'),
    ('alternative_kind', 'text', 'text')
),
production_tables(name) as (
  values ('products'), ('page_content'), ('discovery_queue'), ('swipes')
),
fingerprint as (
  select
    current_user as ausfuehrende_rolle,
    current_database() as datenbank,
    (select count(*) from production_tables t
      where to_regclass('public.' || t.name) is not null) as production_tabellen,
    (select count(*) from public.products) as produkte,
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    ) as pilot_artefakte,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1')::text
      as production_snapshot
),
column_state as (
  select
    count(c.column_name)::integer as vorhandene_spalten,
    count(*) filter (
      where c.column_name is not null
        and c.data_type = e.data_type
        and c.udt_name = e.udt_name
    )::integer as korrekt_typisierte_spalten
  from expected_columns e
  left join information_schema.columns c
    on c.table_schema = 'public'
   and c.table_name = 'products'
   and c.column_name = e.column_name
),
constraint_state as (
  select count(*)::integer as vorhandene_constraints
  from pg_constraint
  where conrelid = to_regclass('public.products')
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    )
),
target_state as (
  select
    count(*)::integer as zielprodukte,
    count(*) filter (where p.is_published is true)::integer
      as veroeffentlichte_zielprodukte,
    count(*) filter (
      where coalesce(
        to_jsonb(p) ->> 'fuer_wen',
        to_jsonb(p) ->> 'nicht_fuer',
        to_jsonb(p) ->> 'key_fact',
        to_jsonb(p) ->> 'pros',
        to_jsonb(p) ->> 'cons',
        to_jsonb(p) ->> 'alternative_slug',
        to_jsonb(p) ->> 'alternative_reason',
        to_jsonb(p) ->> 'alternative_kind'
      ) is not null
    )::integer as bereits_befuellt,
    count(*) filter (where p.editorial_note is not null)::integer
      as bestehende_editorial_notes,
    coalesce(
      string_agg(p.slug, ', ' order by p.slug)
        filter (where p.editorial_note is not null),
      'KEINE'
    ) as editorial_note_slugs
  from public.products p
  join target_slugs t on t.slug = p.slug
),
relation_state as (
  select
    count(*)::integer as relationsziele,
    count(*) filter (where p.is_published is true)::integer
      as veroeffentlichte_relationsziele
  from public.products p
  join relation_slugs r on r.slug = p.slug
),
security_state as (
  select
    coalesce((
      select c.relrowsecurity
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = 'products'
    ), false) as products_rls,
    (select count(*) from pg_policies
      where schemaname = 'public' and tablename = 'products') as products_policies,
    (select count(*) from information_schema.role_table_grants
      where table_schema = 'public'
        and table_name = 'products'
        and grantee in ('anon', 'authenticated')) as app_grants
),
trigger_state as (
  select
    count(*)::integer as trigger_anzahl,
    coalesce(string_agg(pg_get_triggerdef(t.oid), ' | ' order by t.tgname), 'FEHLT')
      as trigger_definition
  from pg_trigger t
  where t.tgrelid = to_regclass('public.products')
    and not t.tgisinternal
),
summary as (
  select *
  from fingerprint f
  cross join column_state c
  cross join constraint_state k
  cross join target_state z
  cross join relation_state r
  cross join security_state s
  cross join trigger_state g
),
checks as (
  select 10 as sortierung, 'ausfuehrende_rolle' as pruefung,
    ausfuehrende_rolle::text as ist, 'INFO' as erwartet, 'INFO' as status
  from summary
  union all
  select 20, 'datenbank', datenbank::text, 'INFO', 'INFO' from summary
  union all
  select 30, 'production_tabellen', production_tabellen::text, '4',
    case when production_tabellen = 4 then 'PASS' else 'FAIL' end from summary
  union all
  select 40, 'produkte_mindestens_300', produkte::text, '>= 300',
    case when produkte >= 300 then 'PASS' else 'FAIL' end from summary
  union all
  select 50, 'pilot_artefakte', pilot_artefakte::text, '0',
    case when pilot_artefakte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 60, 'zielprodukte', zielprodukte::text, '10',
    case when zielprodukte = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'veroeffentlichte_zielprodukte',
    veroeffentlichte_zielprodukte::text, '10',
    case when veroeffentlichte_zielprodukte = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 80, 'veroeffentlichte_relationsziele',
    (relationsziele::text || '/' || veroeffentlichte_relationsziele::text),
    '5/5',
    case when relationsziele = 5 and veroeffentlichte_relationsziele = 5
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 90, 'value_add_schema_zustand',
    (vorhandene_spalten::text || '/8 Spalten, '
      || korrekt_typisierte_spalten::text || '/8 Typen, '
      || vorhandene_constraints::text || '/2 Constraints'),
    '0/8 + 0/2 vor Migration ODER 8/8 + 2/2 vollstaendig',
    case
      when vorhandene_spalten = 0 and korrekt_typisierte_spalten = 0
        and vorhandene_constraints = 0 then 'PASS'
      when vorhandene_spalten = 8 and korrekt_typisierte_spalten = 8
        and vorhandene_constraints = 2 then 'PASS'
      else 'FAIL'
    end
  from summary
  union all
  select 100, 'value_add_bereits_befuellt', bereits_befuellt::text, '0',
    case when bereits_befuellt = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'production_snapshot', coalesce(production_snapshot, 'FEHLT'),
    'FEHLT vor Backup',
    case when production_snapshot is null then 'PASS' else 'FAIL' end from summary
  union all
  select 115, 'bestehende_editorial_notes',
    (bestehende_editorial_notes::text || ': ' || editorial_note_slugs),
    'INFO: jeder genannte Slug wird durch den Backfill bewusst ueberschrieben',
    'INFO' from summary
  union all
  select 120, 'products_rls', products_rls::text, 'INFO', 'INFO' from summary
  union all
  select 130, 'products_policies', products_policies::text, 'INFO', 'INFO' from summary
  union all
  select 140, 'app_grants_products', app_grants::text, 'INFO', 'INFO' from summary
  union all
  select 150, 'products_user_trigger',
    (trigger_anzahl::text || ': ' || trigger_definition), 'INFO', 'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
