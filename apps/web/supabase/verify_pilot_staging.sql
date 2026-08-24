-- ============================================================
-- PILOT-/STAGING-VERIFIKATION — STRIKT READ-ONLY
-- ============================================================
-- Ziel: ausschließlich project/nmzuycveumyfvtxdcnuc im Supabase-Dashboard.
--
-- Die komplette Datei ist genau EIN lesendes Statement. Sie liefert eine
-- übersichtliche PASS/FAIL-Tabelle und verändert weder Schema noch Daten.
-- ============================================================

with
rls_state as (
  select
    count(*) as tabellen_gefunden,
    count(*) filter (where c.relrowsecurity) as rls_aktiv
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p')
    and c.relname in ('categories', 'products', 'lists')
),
policy_state as (
  select
    count(*) filter (where cmd = 'SELECT') as select_policies,
    count(*) filter (where cmd <> 'SELECT') as schreib_policies
  from pg_policies
  where schemaname = 'public'
    and tablename in ('categories', 'products', 'lists')
),
grant_state as (
  select
    count(*) filter (where privilege_type = 'SELECT') as select_rechte,
    count(*) filter (
      where privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
    ) as schreib_rechte
  from information_schema.role_table_grants
  where table_schema = 'public'
    and table_name in ('categories', 'products', 'lists')
    and grantee in ('anon', 'authenticated')
),
value_add_state as (
  select
    count(*) as value_add_befuellt,
    count(*) filter (where p.alternative_kind = 'alternative') as alternativen,
    count(*) filter (where p.alternative_kind = 'complement') as ergaenzungen,
    count(*) filter (
      where p.alternative_kind is null
        and p.alternative_slug is null
        and p.alternative_reason is null
    ) as ohne_relation,
    count(*) filter (
      where not (
        (
          p.alternative_kind is null
          and p.alternative_slug is null
          and p.alternative_reason is null
        )
        or
        (
          p.alternative_kind in ('alternative', 'complement')
          and p.alternative_slug is not null
          and p.alternative_reason is not null
        )
      )
    ) as inkonsistente_relationen,
    count(*) filter (
      where p.alternative_slug is not null
        and (z.slug is null or z.is_published is not true)
    ) as defekte_relationsziele
  from public.products p
  left join public.products z on z.slug = p.alternative_slug
  where p.fuer_wen is not null
    and p.nicht_fuer is not null
    and p.key_fact is not null
    and p.pros is not null
    and p.cons is not null
),
summary as (
  select
    current_user as ausfuehrende_rolle,
    current_database() as datenbank,
    to_regclass('pilot_meta.environment_guard')::text as neuer_pilot_marker,
    to_regclass('pilot_backup.value_add_pre_backfill')::text as neuer_snapshot,
    to_regclass('public.pilot_value_add_backup_20260823')::text
      as legacy_snapshot,
    (select count(*) from public.products) as produkte,
    (select count(*) from public.categories) as kategorien,
    (select count(*) from public.lists) as listen,
    r.tabellen_gefunden,
    r.rls_aktiv,
    p.select_policies,
    p.schreib_policies,
    g.select_rechte,
    g.schreib_rechte,
    v.value_add_befuellt,
    v.alternativen,
    v.ergaenzungen,
    v.ohne_relation,
    v.inkonsistente_relationen,
    v.defekte_relationsziele
  from rls_state r
  cross join policy_state p
  cross join grant_state g
  cross join value_add_state v
),
checks as (
  select 10 as sortierung, 'ausfuehrende_rolle' as pruefung,
    ausfuehrende_rolle::text as ist, 'INFO' as erwartet, 'INFO' as status
  from summary
  union all
  select 20, 'datenbank', datenbank::text, 'INFO', 'INFO' from summary
  union all
  select 30, 'neuer_pilot_marker', coalesce(neuer_pilot_marker, 'FEHLT'),
    'INFO: Legacy-Pilot darf keinen Marker haben', 'INFO' from summary
  union all
  select 40, 'neuer_snapshot', coalesce(neuer_snapshot, 'FEHLT'),
    'INFO', 'INFO' from summary
  union all
  select 50, 'legacy_snapshot', coalesce(legacy_snapshot, 'FEHLT'),
    'INFO', 'INFO' from summary
  union all
  select 60, 'produkte', produkte::text, '20',
    case when produkte = 20 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'kategorien', kategorien::text, '4',
    case when kategorien = 4 then 'PASS' else 'FAIL' end from summary
  union all
  select 80, 'listen', listen::text, '7',
    case when listen = 7 then 'PASS' else 'FAIL' end from summary
  union all
  select 90, 'zieltabellen_gefunden', tabellen_gefunden::text, '3',
    case when tabellen_gefunden = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'rls_aktiv', rls_aktiv::text, '3',
    case when rls_aktiv = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'select_policies', select_policies::text, '3',
    case when select_policies = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'schreib_policies', schreib_policies::text, '0',
    case when schreib_policies = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'select_rechte_app_rollen', select_rechte::text, '6',
    case when select_rechte = 6 then 'PASS' else 'FAIL' end from summary
  union all
  select 140, 'schreib_rechte_app_rollen', schreib_rechte::text, '0',
    case when schreib_rechte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'value_add_befuellt', value_add_befuellt::text, '10',
    case when value_add_befuellt = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 160, 'alternativen', alternativen::text, '3',
    case when alternativen = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'ergaenzungen', ergaenzungen::text, '2',
    case when ergaenzungen = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 180, 'ohne_relation', ohne_relation::text, '5',
    case when ohne_relation = 5 then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'inkonsistente_relationen', inkonsistente_relationen::text, '0',
    case when inkonsistente_relationen = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 200, 'defekte_relationsziele', defekte_relationsziele::text, '0',
    case when defekte_relationsziele = 0 then 'PASS' else 'FAIL' end
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
