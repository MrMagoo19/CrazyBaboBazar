-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 03 READ-ONLY NACHPRUEFUNG
-- ============================================================================
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 02.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE,
--      keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
--      steuerung. Nichts an der Datenbank wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu.
--   4. Fehlt public.click_outs, scheitert das Statement bewusst hart mit
--      "relation does not exist". Das ist der gewollte fail-closed Ausgang.
--   5. Bei IRGENDEINEM FAIL: nichts nachgranten, nichts korrigieren, nichts
--      loeschen. Befund melden und Ursache klaeren.
--
-- ERWARTETES ERGEBNIS: 23 Zeilen — 17 harte PASS-Zeilen (Sortierung 30 bis 185)
-- und 6 INFO-Zeilen (10, 20, 200 bis 230).
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. Innerhalb von Text-Literalen
-- kommt bewusst KEIN Semikolon vor (Trenner in Ausgabetexten ist ' | ').
-- Es kommen ausschliesslich lesende Konstrukte vor (with, select, values,
-- from, join, cross join, lateral, where, filter, case, union all, order by)
-- sowie die lesenden Katalogfunktionen to_regclass, aclexplode, acldefault,
-- has_table_privilege, has_schema_privilege, has_sequence_privilege,
-- pg_get_serial_sequence und has_function_privilege. Die
-- Woerter SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, USAGE,
-- CREATE und EXECUTE erscheinen ausserhalb von Kommentaren ausschliesslich als
-- Privilegnamen in values-Listen. "PUBLIC" erscheint nur als Grantee-Bezeichner
-- in Textausgaben, nicht als Rechte-Anweisung.
-- ============================================================================

with
app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),
expected_columns(column_name, udt_name) as (
  values
    ('id', 'int8'),
    ('product_slug', 'text'),
    ('merchant', 'text'),
    ('source_path', 'text'),
    ('device_class', 'text'),
    ('consented_session_id', 'uuid'),
    ('created_at', 'timestamptz')
),

-- ---------------------------------------------------------------------------
-- Struktur der Tabelle (Pruefungen 1, 2)
-- ---------------------------------------------------------------------------
table_shape as (
  select
    count(*)::integer as spalten_gesamt,
    (select count(*)
     from expected_columns e
     join information_schema.columns c
       on c.table_schema = 'public'
      and c.table_name = 'click_outs'
      and c.column_name = e.column_name
      and c.udt_name = e.udt_name)::integer as spalten_erwartet
  from pg_attribute a
  where a.attrelid = 'public.click_outs'::regclass
    and a.attnum > 0
    and not a.attisdropped
),

-- ---------------------------------------------------------------------------
-- Absicherung der Tabelle (Pruefungen 3, 4, 5, 6)
-- ---------------------------------------------------------------------------
table_guard as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid)::integer as policies,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'c')::integer as check_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'p')::integer as pk_constraints,
    (select count(*) from pg_index i where i.indrelid = c.oid)::integer as indizes,
    -- Ein Index auf der Sitzungskennung waere ausschliesslich fuer die
    -- Rekonstruktion einzelner Klickfolgen nuetzlich. Er darf nicht existieren.
    (select count(*)
     from pg_index i
     join pg_attribute a
       on a.attrelid = i.indrelid and a.attnum = any(i.indkey)
     where i.indrelid = c.oid
       and a.attname = 'consented_session_id')::integer as sitzungs_indizes
  from pg_class c
  where c.oid = 'public.click_outs'::regclass
),

-- ---------------------------------------------------------------------------
-- Rollenpraesenz als harte Vorbedingung (Pruefung 7)
-- Fehlt eine App-Rolle, waeren die Rechte-Zaehler still 0 und damit kein Beleg
-- fuer "keine Rechte", sondern nur fuer "keine Rolle".
-- ---------------------------------------------------------------------------
role_presence as (
  select
    (select count(*) from pg_roles where rolname in ('anon', 'authenticated'))::integer
      as app_rollen,
    (select count(*) from pg_roles where rolname = 'service_role')::integer
      as service_rolle
),

-- ---------------------------------------------------------------------------
-- Rechte auf der Tabelle (Pruefung 8)
-- Direkte ACL-Eintraege UND effektive Privilegien. aclexplode sieht nur direkte
-- Grantees; ein ueber Rollenmitgliedschaft geerbtes Recht bliebe dort
-- unsichtbar. has_table_privilege loest Mitgliedschaft und PUBLIC mit auf.
-- ---------------------------------------------------------------------------
table_privileges as (
  select
    count(*) filter (where g.rolle = 'PUBLIC')::integer as tabelle_public_rechte,
    count(*) filter (where g.rolle = 'anon')::integer as tabelle_anon_rechte,
    count(*) filter (where g.rolle = 'authenticated')::integer as tabelle_auth_rechte
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  join app_grantees g on g.grantee_oid = acl.grantee
  where c.oid = 'public.click_outs'::regclass
),
table_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer as tabelle_anon_effektiv,
    count(*) filter (where r.rolname = 'authenticated')::integer as tabelle_auth_effektiv
  from pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid, 'public.click_outs'::regclass::oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- service_role darf GENAU EIN Recht haben: INSERT (Pruefung 9)
-- Das ist hier ausdruecklich eine harte Pruefung und keine INFO-Zeile: die
-- Rolle ist der einzige Schreibpfad der Anwendung, und mehr als INSERT waere
-- ein echter Regress. SELECT haette sie nur noetig, um Einzelereignisse zu
-- lesen — genau das soll die Anwendung nicht koennen.
-- ---------------------------------------------------------------------------
service_role_privileges as (
  select
    coalesce(string_agg(p.priv, ', ' order by p.priv), 'keine') as rechte,
    count(*)::integer as anzahl
  from (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where exists (select 1 from pg_roles where rolname = 'service_role')
    and has_table_privilege('service_role', 'public.click_outs'::regclass::oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- Identity-Sequenz (Pruefung 17)
-- Die Sequenz haengt an public.click_outs, ist aber ein eigenes Objekt mit
-- eigener ACL. Ohne Entzug gaebe `last_value` den Klick-Zaehler preis und
-- `setval` liesse die Nummernfolge verbiegen — beides an der ansonsten dichten
-- Tabelle vorbei. Geprueft werden der Name (damit der Entzug nachweislich die
-- richtige Sequenz getroffen hat) und die effektiven Rechte.
-- ---------------------------------------------------------------------------
sequence_state as (
  select
    coalesce(pg_get_serial_sequence('public.click_outs', 'id'), 'keine') as sequenzname,
    coalesce((
      select count(*)
      from pg_roles r
      cross join (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
      where r.rolname in ('anon', 'authenticated')
        and to_regclass('public.click_outs_id_seq') is not null
        and has_sequence_privilege(r.oid, to_regclass('public.click_outs_id_seq')::oid, p.priv::text)
    ), 0)::integer as sequenz_app_rechte,
    coalesce((
      select string_agg(p.priv, ', ' order by p.priv)
      from (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
      where exists (select 1 from pg_roles where rolname = 'service_role')
        and to_regclass('public.click_outs_id_seq') is not null
        and has_sequence_privilege('service_role', to_regclass('public.click_outs_id_seq')::oid, p.priv::text)
    ), 'keine') as sequenz_service_rechte
),

-- ---------------------------------------------------------------------------
-- Privates Auswertungsschema (Pruefungen 10, 11)
-- ---------------------------------------------------------------------------
schema_state as (
  select
    (select count(*) from pg_namespace where nspname = 'cbb_private_analytics')::integer
      as schema_vorhanden
),
schema_privileges as (
  select
    count(*) filter (where g.rolle = 'PUBLIC')::integer as schema_public_rechte,
    count(*) filter (where g.rolle = 'anon')::integer as schema_anon_rechte,
    count(*) filter (where g.rolle = 'authenticated')::integer as schema_auth_rechte
  from pg_namespace n
  cross join lateral aclexplode(
    coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
  ) as acl
  join app_grantees g on g.grantee_oid = acl.grantee
  where n.nspname = 'cbb_private_analytics'
),
schema_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer as schema_anon_effektiv,
    count(*) filter (where r.rolname = 'authenticated')::integer as schema_auth_effektiv
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  join pg_namespace n on n.nspname = 'cbb_private_analytics'
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, n.oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- Auswertungs-View (Pruefungen 12, 13)
-- ---------------------------------------------------------------------------
view_state as (
  select
    to_regclass('cbb_private_analytics.click_outs_daily') is not null as view_da,
    coalesce((
      select array_to_string(c.reloptions, ' | ')
      from pg_class c
      where c.oid = to_regclass('cbb_private_analytics.click_outs_daily')
    ), 'keine') as view_optionen,
    coalesce((
      select count(*)
      from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_analytics.click_outs_daily')
        and a.attnum > 0
        and not a.attisdropped
        and a.attname = 'consented_session_id'
    ), 0)::integer as view_gibt_sitzungskennung_aus
),

-- ---------------------------------------------------------------------------
-- Retention-Funktion (Pruefungen 14, 15)
-- ---------------------------------------------------------------------------
function_state as (
  select
    coalesce((
      select count(*)
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
    ), 0)::integer as funktionen,
    coalesce((
      select bool_and(p.prosecdef)
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
    ), false) as security_definer,
    coalesce((
      select count(*)
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      cross join (values ('anon'), ('authenticated')) as r(rolle)
      where n.nspname = 'cbb_private_analytics'
        and p.proname = 'purge_click_outs'
        and has_function_privilege(r.rolle::text, p.oid, 'EXECUTE')
    ), 0)::integer as funktion_app_rechte
),

-- ---------------------------------------------------------------------------
-- Value-Add-Artefakte bleiben unangetastet (Pruefung 16)
-- ---------------------------------------------------------------------------
value_add_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null as v1_snapshot,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null as v1_payload,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null as v2_snapshot,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null as v2_payload
),

-- ---------------------------------------------------------------------------
-- Inhaltlicher Kontext ohne Zusage
-- ---------------------------------------------------------------------------
content_state as (
  select
    (select count(*) from public.click_outs)::bigint as ereignisse,
    coalesce((select min(created_at)::text from public.click_outs), 'keine') as aeltestes,
    coalesce((select max(created_at)::text from public.click_outs), 'keine') as juengstes,
    (select count(distinct consented_session_id) from public.click_outs)::bigint as sitzungen,
    (select count(*) from public.click_outs
      where created_at < now() - interval '12 months')::bigint as ueberfaellig
),

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from table_shape
  cross join table_guard
  cross join role_presence
  cross join table_privileges
  cross join table_privileges_effective
  cross join service_role_privileges
  cross join sequence_state
  cross join schema_state
  cross join schema_privileges
  cross join schema_privileges_effective
  cross join view_state
  cross join function_state
  cross join value_add_state
  cross join content_state
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
  select 30, 'click_outs_spalten',
    spalten_gesamt::text || ' gesamt | ' || spalten_erwartet::text || ' erwartete Namen und Typen',
    '7 gesamt | 7 erwartete Namen und Typen',
    case when spalten_gesamt = 7 and spalten_erwartet = 7 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'click_outs_constraints',
    'CHECK ' || check_constraints::text || ' | PK ' || pk_constraints::text,
    'CHECK 5 | PK 1',
    case when check_constraints = 5 and pk_constraints = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'click_outs_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'click_outs_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'click_outs_indizes', indizes::text, '3 (PK plus zwei fachliche)',
    case when indizes = 3 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'kein_index_auf_sitzungskennung', sitzungs_indizes::text, '0',
    case when sitzungs_indizes = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'rollen_vorhanden',
    'app ' || app_rollen::text || '/2 | service_role ' || service_rolle::text || '/1',
    'app 2/2 | service_role 1/1',
    case when app_rollen = 2 and service_rolle = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'click_outs_tabellenrechte_app_rollen',
    'direkte ACL: PUBLIC ' || tabelle_public_rechte::text
      || ', anon ' || tabelle_anon_rechte::text
      || ', authenticated ' || tabelle_auth_rechte::text
      || ' | effektiv: anon ' || tabelle_anon_effektiv::text
      || ', authenticated ' || tabelle_auth_effektiv::text,
    'direkte ACL: PUBLIC 0, anon 0, authenticated 0 | effektiv: anon 0, authenticated 0',
    case when app_rollen = 2
           and tabelle_public_rechte = 0
           and tabelle_anon_rechte = 0
           and tabelle_auth_rechte = 0
           and tabelle_anon_effektiv = 0
           and tabelle_auth_effektiv = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'click_outs_rechte_service_role',
    anzahl::text || ' Recht(e): ' || rechte,
    '1 Recht(e): INSERT',
    case when service_rolle = 1 and anzahl = 1 and rechte = 'INSERT'
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 10
  select 120, 'analytics_schema_vorhanden', schema_vorhanden::text, '1',
    case when schema_vorhanden = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 11
  select 130, 'analytics_schemarechte_app_rollen',
    'direkte ACL: PUBLIC ' || schema_public_rechte::text
      || ', anon ' || schema_anon_rechte::text
      || ', authenticated ' || schema_auth_rechte::text
      || ' | effektiv: anon ' || schema_anon_effektiv::text
      || ', authenticated ' || schema_auth_effektiv::text,
    'direkte ACL: PUBLIC 0, anon 0, authenticated 0 | effektiv: anon 0, authenticated 0',
    case when app_rollen = 2
           and schema_public_rechte = 0
           and schema_anon_rechte = 0
           and schema_auth_rechte = 0
           and schema_anon_effektiv = 0
           and schema_auth_effektiv = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 12
  select 140, 'auswertungs_view_vorhanden',
    view_da::text || ' | Optionen ' || view_optionen,
    'true | Optionen enthalten security_invoker=true',
    case when view_da and view_optionen like '%security_invoker=true%'
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 13
  select 150, 'view_gibt_keine_sitzungskennung_aus',
    view_gibt_sitzungskennung_aus::text, '0',
    case when view_gibt_sitzungskennung_aus = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 14
  select 160, 'retention_funktion',
    funktionen::text || ' Funktion(en) | security definer ' || security_definer::text,
    '1 Funktion(en) | security definer true',
    case when funktionen = 1 and security_definer then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 15
  select 170, 'retention_funktion_ohne_app_rechte', funktion_app_rechte::text, '0',
    case when funktion_app_rechte = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 16
  select 180, 'value_add_artefakte_unveraendert',
    'v1 snapshot ' || v1_snapshot::text
      || ' | v1 payload ' || v1_payload::text
      || ' | v2 snapshot ' || v2_snapshot::text
      || ' | v2 payload ' || v2_payload::text,
    'alle vier true',
    case when v1_snapshot and v1_payload and v2_snapshot and v2_payload
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 17
  select 185, 'click_outs_sequenzrechte',
    'Sequenz ' || sequenzname
      || ' | anon und authenticated ' || sequenz_app_rechte::text
      || ' | service_role ' || sequenz_service_rechte,
    'Sequenz public.click_outs_id_seq | anon und authenticated 0 | service_role USAGE',
    case when app_rollen = 2
           and service_rolle = 1
           and sequenzname = 'public.click_outs_id_seq'
           and sequenz_app_rechte = 0
           and sequenz_service_rechte = 'USAGE'
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 200, 'ereignisse_gesamt', ereignisse::text,
    'INFO: direkt nach Schritt 02 erwartungsgemaess 0', 'INFO'
  from summary
  union all
  select 210, 'zeitfenster',
    'aeltestes ' || aeltestes || ' | juengstes ' || juengstes,
    'INFO: reine Beobachtung', 'INFO'
  from summary
  union all
  select 220, 'unterschiedliche_sitzungen', sitzungen::text,
    'INFO: Zaehlwert, keine Zuordnung zu Personen moeglich', 'INFO'
  from summary
  union all
  select 230, 'retention_faellig', ueberfaellig::text,
    'INFO: Zeilen aelter als 12 Monate. Loeschung ausschliesslich ueber 04_retention.sql',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
