-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 01 READ-ONLY PREFLIGHT
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene, ausdrueckliche Benutzerfreigabe.
-- Zielprojekt ausserhalb von SQL sichtbar pruefen:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Dieses Artefakt ist genau ein lesendes WITH ... SELECT. Es veraendert weder
-- Schema noch Daten. Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/
-- TRUNCATE, keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
-- steuerung.
--
-- ZWECK: belegen, dass die Klick-out-Artefakte auf Production noch NICHT
-- existieren und dass die Umgebung die erwartete Production-Umgebung ist. Jede
-- FAIL-Zeile blockiert Schritt 02.
--
-- ROBUSTHEIT UND IHRE GRENZE: die noch nicht existierenden Artefakte werden
-- AUSSCHLIESSLICH ueber to_regclass geprueft. Eine direkte Referenz wuerde bei
-- fehlender Relation bereits die PLANUNG abbrechen — es gaebe dann gar keinen
-- Report. public.products dagegen wird direkt gelesen: ohne diese Tabelle ist
-- der ganze Vorgang gegenstandslos, ein harter Planungsfehler ist dort gewollt.
--
-- ERWARTETES ERGEBNIS: 18 Zeilen — 11 harte PASS-Zeilen (Sortierung 30 bis 130)
-- und 7 INFO-Zeilen (10, 20, 200 bis 250).
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. In Text-Literalen kommt kein
-- Semikolon vor (Trenner in Ausgabetexten ist ' | '). Es kommen ausschliesslich
-- lesende Konstrukte vor (with, select, values, from, join, cross join, where,
-- filter, case, union all, order by) sowie die lesende Katalogfunktion
-- to_regclass.
-- ============================================================================

with
production_tables(name) as (
  values ('products'), ('page_content'), ('discovery_queue'), ('swipes')
),

-- ---------------------------------------------------------------------------
-- Umgebungs-Fingerprint
-- ---------------------------------------------------------------------------
fingerprint as (
  select
    current_user as ausfuehrende_rolle,
    current_database() as datenbank,
    (select count(*) from production_tables t
      where to_regclass('public.' || t.name) is not null)::integer
      as production_tabellen,
    (select count(*) from public.products)::bigint as produkte,
    (select count(*) from public.products where is_published is true)::bigint
      as produkte_published,
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    )::integer as pilot_artefakte
),

-- ---------------------------------------------------------------------------
-- Rollen. Fehlt eine App-Rolle, waeren spaetere Rechte-Pruefungen still 0 und
-- damit wertlos — deshalb ist die Rollenpraesenz eine eigene harte Zeile.
-- ---------------------------------------------------------------------------
role_state as (
  select
    (select count(*) from pg_roles where rolname in ('anon', 'authenticated'))::integer
      as app_rollen,
    (select count(*) from pg_roles where rolname = 'service_role')::integer
      as service_rolle
),

-- ---------------------------------------------------------------------------
-- Die Klick-out-Artefakte muessen vor dem Erstlauf FEHLEN
-- ---------------------------------------------------------------------------
artefakt_state as (
  select
    to_regclass('public.click_outs') is null as tabelle_fehlt,
    (select count(*) from pg_namespace where nspname = 'cbb_private_analytics')::integer
      as analytics_schema,
    to_regclass('cbb_private_analytics.click_outs_daily') is null as view_fehlt,
    (select count(*) from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'cbb_private_analytics'
        and p.proname = 'purge_click_outs')::integer as purge_funktion
),

-- ---------------------------------------------------------------------------
-- Value-Add-Artefakte: dieser Vorgang fasst sie NICHT an. Die Zeilen belegen
-- nur, dass der Ausgangszustand der frueheren Chargen unveraendert ist.
-- ---------------------------------------------------------------------------
value_add_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null as v1_snapshot,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null as v1_payload,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null as v2_snapshot,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null as v2_payload,
    (select count(*)
     from public.products p
     where p.fuer_wen is not null
        or p.nicht_fuer is not null
        or p.key_fact is not null
        or p.pros is not null
        or p.cons is not null
        or p.alternative_slug is not null
        or p.alternative_reason is not null
        or p.alternative_kind is not null)::integer as value_add_gesamt
),

-- ---------------------------------------------------------------------------
-- Kontext ohne Zusage
-- ---------------------------------------------------------------------------
extension_state as (
  select
    (select count(*) from pg_extension where extname = 'pg_cron')::integer as pg_cron,
    (select count(*) from pg_available_extensions where name = 'pg_cron')::integer
      as pg_cron_verfuegbar
),

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from fingerprint
  cross join role_state
  cross join artefakt_state
  cross join value_add_state
  cross join extension_state
),

checks as (
  select 10 as sortierung, 'ausfuehrende_rolle' as pruefung,
    ausfuehrende_rolle::text as ist, 'INFO' as erwartet, 'INFO' as status
  from summary
  union all
  select 20, 'datenbank', datenbank::text, 'INFO', 'INFO' from summary
  union all
  -- 1
  select 30, 'production_tabellen', production_tabellen::text, '4',
    case when production_tabellen = 4 then 'PASS' else 'FAIL' end from summary
  union all
  -- 2
  select 40, 'produkte_mindestens_300', produkte::text, '>= 300',
    case when produkte >= 300 then 'PASS' else 'FAIL' end from summary
  union all
  -- 3
  select 50, 'pilot_artefakte', pilot_artefakte::text, '0',
    case when pilot_artefakte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 4
  select 60, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end from summary
  union all
  -- 5
  select 70, 'service_role_vorhanden', service_rolle::text || '/1', '1/1',
    case when service_rolle = 1 then 'PASS' else 'FAIL' end from summary
  union all
  -- 6
  select 80, 'click_outs_tabelle_fehlt', tabelle_fehlt::text, 'true',
    case when tabelle_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  -- 7
  select 90, 'analytics_schema_fehlt', analytics_schema::text, '0',
    case when analytics_schema = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 8
  select 100, 'auswertungs_view_fehlt', view_fehlt::text, 'true',
    case when view_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  -- 9
  select 110, 'purge_funktion_fehlt', purge_funktion::text, '0',
    case when purge_funktion = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 10
  select 120, 'value_add_artefakte_unveraendert',
    ('v1 snapshot ' || v1_snapshot::text
      || ' | v1 payload ' || v1_payload::text
      || ' | v2 snapshot ' || v2_snapshot::text
      || ' | v2 payload ' || v2_payload::text),
    'alle vier true',
    case when v1_snapshot and v1_payload and v2_snapshot and v2_payload
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 11
  select 130, 'value_add_befuellung_unveraendert', value_add_gesamt::text,
    '20 (Batch 1 + Batch 2)',
    case when value_add_gesamt = 20 then 'PASS' else 'FAIL' end from summary
  union all
  select 200, 'produkte_gesamt_und_published',
    (produkte::text || ' gesamt | ' || produkte_published::text || ' published'),
    'INFO: am 2026-08-26 waren es 376 gesamt und 372 published',
    'INFO' from summary
  union all
  select 210, 'pg_cron_installiert', pg_cron::text,
    'INFO: 0 bedeutet, dass die Retention manuell oder ueber einen externen Scheduler laufen muss',
    'INFO' from summary
  union all
  select 220, 'pg_cron_verfuegbar', pg_cron_verfuegbar::text,
    'INFO: reine Verfuegbarkeit im Katalog, keine Installation und keine Zusage',
    'INFO' from summary
  union all
  select 230, 'zielprojekt',
    'ydiihvzcxaaoqhmgoqvu',
    'INFO: vor jedem Schritt sichtbar im SQL-Editor gegenpruefen',
    'INFO' from summary
  union all
  select 240, 'schreibender_zugang',
    'nur service_role',
    'INFO: die Anwendung schreibt ueber SUPABASE_SERVICE_ROLE_KEY, nie ueber den oeffentlichen Schluessel',
    'INFO' from summary
  union all
  select 250, 'datenumfang',
    'product_slug | merchant | source_path | device_class | consented_session_id | created_at',
    'INFO: keine IP-Adresse, kein IP-Hashwert, keine vollstaendige Browserkennung, keine vollstaendige Herkunfts-URL, keine Adressparameter',
    'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
