-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 3 — 04b VERIFY: READ-ONLY SICHERHEITSPRUEFUNG DER
-- AUDIT-PAYLOAD cbb_private_backup.value_add_payload_v3
-- ============================================================================
-- WARUM ES DIESE DATEI GIBT:
--
--   04_verify_read_only.sql prueft die Audit-Payload ausschliesslich
--   INHALTLICH (10 Zeilen, 0 Feldabweichungen gegen public.products). Es prueft
--   NICHT RLS, NICHT Policies und NICHT die Rechte auf Tabelle oder Schema.
--   Fuer den Snapshot aus Schritt 02 leistet das
--   02b_verify_snapshot_read_only.sql — fuer die in Schritt 03 neu erzeugte
--   Payload leistet es diese Datei. Sie ist das Batch-3-Gegenstueck zu
--   ../production_value_add_batch2/04b_verify_payload_security_read_only.sql
--   und folgt demselben Muster.
--
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 03
--      (03_backfill_value_add_batch3.sql) und ergaenzt Schritt 04. Sie ersetzt
--      04 nicht und wird nicht von 04 ersetzt.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE,
--      keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
--      steuerung. Nichts an der Datenbank wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu. Vor dem Ausfuehren im
--      SQL-Editor pruefen, dass genau dieses Projekt ausgewaehlt ist.
--   4. Fehlt die Payload-Tabelle cbb_private_backup.value_add_payload_v3,
--      scheitert das Statement bewusst hart mit "relation does not exist".
--      Das ist der gewollte fail-closed Ausgang.
--   5. Bei IRGENDEINEM FAIL: nichts korrigieren, nichts nachgranten, nichts
--      loeschen. Befund melden und Ursache klaeren. Diese Datei erteilt keine
--      Freigabe fuer irgendeine schreibende Aktion.
--
-- GEPRUEFTE ROLLEN — und die bewusste Grenze:
--
--   Hart geprueft werden genau die zwei App-Rollen `anon` und `authenticated`
--   sowie `PUBLIC`. Das ist dieselbe Definition von "App-Rollen", die
--   02b_verify_snapshot_read_only.sql verwendet, und dieselbe Menge, die 03
--   explizit revoked (`revoke all ... from public, anon, authenticated`).
--
--   Fuer diese zwei Rollen werden ZWEI unabhaengige Messungen gefordert, beide
--   auf 0:
--     (a) direkte ACL-Eintraege (aclexplode) fuer PUBLIC, anon, authenticated,
--     (b) effektive Privilegien ueber has_table_privilege bzw.
--         has_schema_privilege fuer anon und authenticated.
--   Grund: aclexplode zaehlt nur Eintraege, deren Grantee direkt PUBLIC, anon
--   oder authenticated ist. Erbt anon oder authenticated ein Recht ueber eine
--   Rollenmitgliedschaft, taucht dieser Grantee in der ACL der Payload gar
--   nicht auf — die direkten Zaehler blieben 0 und die Pruefung meldete
--   faelschlich PASS. Genau dieser Fail-open-Rand ist hier geschlossen.
--
--   `service_role` wird ausschliesslich als INFO ausgegeben, NIE als PASS:
--   03 revoked diese Rolle nicht explizit, und die Policy dieses Changesets
--   definiert sie nicht als eine der zwei geprueften App-Rollen. Ausserdem ist
--   `service_role` auf Supabase typischerweise BYPASSRLS — RLS allein ist gegen
--   sie kein Schutz. Die INFO-Zeilen dokumentieren den tatsaechlichen
--   Ist-Zustand ohne jede Zusage.
--
-- ERWARTETES ERGEBNIS: 17 Zeilen — 10 harte PASS-Zeilen (Sortierung 30 bis 120)
-- und 7 INFO-Zeilen (2x Kontext bei 10/20, 5x service_role bei 200 bis 240).
-- Jede FAIL-Zeile ist ein Befund.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. Innerhalb von Text-Literalen
-- kommt bewusst KEIN Semikolon vor (Trenner in Ausgabetexten ist ' | ').
-- Es kommen ausschliesslich lesende Konstrukte vor (with, select, values,
-- from, join, cross join, lateral, where, filter, case, union all, order by)
-- sowie die lesenden Katalogfunktionen to_regclass, aclexplode, acldefault,
-- has_table_privilege und has_schema_privilege. Die Woerter SELECT, INSERT,
-- UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, USAGE und CREATE erscheinen
-- ausserhalb von Kommentaren ausschliesslich als Privilegnamen in
-- values-Listen. "PUBLIC" erscheint nur als Grantee-Bezeichner in
-- Textausgaben, nicht als Rechte-Anweisung.
-- ============================================================================

with
-- ---------------------------------------------------------------------------
-- Grantees der harten Rechte-Pruefungen.
-- PUBLIC ist in aclexplode die Grantee-OID 0, anon/authenticated ueber pg_roles.
-- ---------------------------------------------------------------------------
app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Existenz der Payload-Tabelle (Pruefung 1)
-- Doppelt abgesichert: to_regclass liefert die weiche Anzeige, die direkten
-- ::regclass-Referenzen weiter unten brechen bei Fehlen bereits die Planung ab.
-- ---------------------------------------------------------------------------
payload_presence as (
  select to_regclass('cbb_private_backup.value_add_payload_v3') is not null
    as payload_vorhanden
),

-- ---------------------------------------------------------------------------
-- Zeilenzahl der Payload (Pruefung 2)
-- ---------------------------------------------------------------------------
payload_rows as (
  select count(*)::integer as zeilen
  from cbb_private_backup.value_add_payload_v3
),

-- ---------------------------------------------------------------------------
-- Payload-Struktur: exakt 10 Spalten mit exakt diesen Namen (Pruefung 3)
-- spalten_gesamt = 10 und spalten_erwartet = 10 erzwingen zusammen die exakte
-- Namensmenge. Die Namensliste ist die Payload-Definition aus 03 (temporaere
-- Tabelle cbb_value_add_payload_b3, uebernommen per `create table ... as
-- select *`).
-- ---------------------------------------------------------------------------
payload_shape as (
  select
    count(*)::integer as spalten_gesamt,
    count(*) filter (
      where a.attname in (
        'slug', 'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
        'alternative_slug', 'alternative_reason', 'alternative_kind',
        'editorial_note'
      )
    )::integer as spalten_erwartet
  from pg_attribute a
  where a.attrelid = 'cbb_private_backup.value_add_payload_v3'::regclass
    and a.attnum > 0
    and not a.attisdropped
),

-- ---------------------------------------------------------------------------
-- Absicherung der Payload-Tabelle: RLS, Policies, Primaerschluessel (4, 5, 6)
-- pk_constraints = 1 UND pk_slug_constraints = 1 zusammen bedeuten: es gibt
-- genau einen Primaerschluessel und dieser eine besteht exakt aus (slug).
-- ---------------------------------------------------------------------------
payload_guard as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid)::integer
      as policies,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'p')::integer as pk_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'p'
        and (
          select array_agg(a.attname::text order by a.attname)
          from pg_attribute a
          where a.attrelid = con.conrelid
            and a.attnum = any(con.conkey)
        ) = array['slug']::text[])::integer as pk_slug_constraints
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
),

-- ---------------------------------------------------------------------------
-- Harte Vorbedingung der Rechte-Pruefungen (Pruefung 7)
-- ---------------------------------------------------------------------------
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Direkte ACL-Eintraege auf Payload-Tabelle und Schema (Teil a von 8, 9)
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
  where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
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
  where n.oid = (
    select c.relnamespace
    from pg_class c
    where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
  )
),

-- ---------------------------------------------------------------------------
-- Effektive Privilegien der harten Rollen anon/authenticated (Teil b von 8, 9)
-- ---------------------------------------------------------------------------
table_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer
      as tabelle_anon_effektiv,
    count(*) filter (where r.rolname = 'authenticated')::integer
      as tabelle_auth_effektiv
  from pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(
          r.oid,
          'cbb_private_backup.value_add_payload_v3'::regclass::oid,
          p.priv::text)
),
schema_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer
      as schema_anon_effektiv,
    count(*) filter (where r.rolname = 'authenticated')::integer
      as schema_auth_effektiv
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  join pg_class c
    on c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- Artefakte von Batch 1 und Batch 2 muessen unveraendert vorliegen (Pruefung 10)
-- Bewusst nur ueber to_regclass, damit ihr Fehlen als lesbare FAIL-Zeile
-- erscheint und nicht als Planungsfehler.
-- ---------------------------------------------------------------------------
vorgaenger_presence as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null
      as v1_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null
      as v1_payload_da,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null
      as v2_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null
      as v2_payload_da
),

-- ---------------------------------------------------------------------------
-- service_role — NUR INFO, nie PASS (Zeilen 200 bis 240)
-- ---------------------------------------------------------------------------
service_role_state as (
  select
    (select count(*) from pg_roles r where r.rolname = 'service_role')::integer
      as rolle_vorhanden,
    (select coalesce(
       string_agg(distinct acl.privilege_type, ', ' order by acl.privilege_type),
       'keine')
     from pg_class c
     cross join lateral aclexplode(
       coalesce(c.relacl, acldefault('r'::"char", c.relowner))
     ) as acl
     join pg_roles r on r.oid = acl.grantee and r.rolname = 'service_role'
     where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
    ) as tabelle_acl,
    (select coalesce(
       string_agg(distinct acl.privilege_type, ', ' order by acl.privilege_type),
       'keine')
     from pg_namespace n
     cross join lateral aclexplode(
       coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
     ) as acl
     join pg_roles r on r.oid = acl.grantee and r.rolname = 'service_role'
     where n.oid = (
       select c.relnamespace
       from pg_class c
       where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
     )
    ) as schema_acl,
    (select coalesce(string_agg(p.priv, ', ' order by p.priv), 'keine')
     from pg_roles r
     cross join (values
       ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
       ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
     ) as p(priv)
     where r.rolname = 'service_role'
       and has_table_privilege(
             r.oid,
             'cbb_private_backup.value_add_payload_v3'::regclass::oid,
             p.priv::text)
    ) as tabelle_effektiv,
    (select coalesce(string_agg(p.priv, ', ' order by p.priv), 'keine')
     from pg_roles r
     cross join (values ('USAGE'), ('CREATE')) as p(priv)
     join pg_class c on c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass
     where r.rolname = 'service_role'
       and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
    ) as schema_effektiv,
    (select coalesce(bool_or(r.rolbypassrls), false)
     from pg_roles r where r.rolname = 'service_role') as bypassrls
),

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from payload_presence
  cross join payload_rows
  cross join payload_shape
  cross join payload_guard
  cross join role_presence
  cross join table_privileges
  cross join schema_privileges
  cross join table_privileges_effective
  cross join schema_privileges_effective
  cross join vorgaenger_presence
  cross join service_role_state
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
  select 30, 'payload_v3_vorhanden', payload_vorhanden::text, 'true',
    case when payload_vorhanden then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'payload_v3_zeilen', zeilen::text, '10',
    case when zeilen = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'payload_v3_spalten',
    spalten_gesamt::text || ' gesamt, ' || spalten_erwartet::text
      || ' erwartete Namen',
    '10 gesamt, 10 erwartete Namen',
    case when spalten_gesamt = 10 and spalten_erwartet = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'payload_v3_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'payload_v3_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'payload_v3_primaerschluessel',
    'PK ' || pk_constraints::text || ', davon PK(slug) '
      || pk_slug_constraints::text,
    'PK 1, davon PK(slug) 1',
    case when pk_constraints = 1 and pk_slug_constraints = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'payload_v3_tabellenrechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2'
      || ' | direkte ACL: PUBLIC ' || tabelle_public_rechte::text
      || ', anon ' || tabelle_anon_rechte::text
      || ', authenticated ' || tabelle_auth_rechte::text
      || ' | effektiv: anon ' || tabelle_anon_effektiv::text
      || ', authenticated ' || tabelle_auth_effektiv::text,
    'Rollen 2/2 | direkte ACL: PUBLIC 0, anon 0, authenticated 0'
      || ' | effektiv: anon 0, authenticated 0',
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
  select 110, 'payload_v3_schemarechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2'
      || ' | direkte ACL: PUBLIC ' || schema_public_rechte::text
      || ', anon ' || schema_anon_rechte::text
      || ', authenticated ' || schema_auth_rechte::text
      || ' | effektiv: anon ' || schema_anon_effektiv::text
      || ', authenticated ' || schema_auth_effektiv::text,
    'Rollen 2/2 | direkte ACL: PUBLIC 0, anon 0, authenticated 0'
      || ' | effektiv: anon 0, authenticated 0',
    case when app_rollen = 2
           and schema_public_rechte = 0
           and schema_anon_rechte = 0
           and schema_auth_rechte = 0
           and schema_anon_effektiv = 0
           and schema_auth_effektiv = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 10
  select 120, 'vorgaenger_artefakte_vorhanden',
    'snapshot v1 ' || v1_snapshot_da::text
      || ' | payload v1 ' || v1_payload_da::text
      || ' | snapshot v2 ' || v2_snapshot_da::text
      || ' | payload v2 ' || v2_payload_da::text,
    'alle vier true',
    case when v1_snapshot_da and v1_payload_da and v2_snapshot_da and v2_payload_da
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- INFO A
  select 200, 'service_role_vorhanden',
    case when rolle_vorhanden = 1 then 'ja' else 'nein' end
      || ' | bypassrls ' || bypassrls::text,
    'INFO: keine Zusage, 03 revoked service_role nicht explizit',
    'INFO'
  from summary
  union all
  -- INFO B
  select 210, 'service_role_tabellen_acl',
    case when rolle_vorhanden = 1 then tabelle_acl
      else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf value_add_payload_v3',
    'INFO'
  from summary
  union all
  -- INFO C
  select 220, 'service_role_schema_acl',
    case when rolle_vorhanden = 1 then schema_acl
      else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf cbb_private_backup',
    'INFO'
  from summary
  union all
  -- INFO D
  select 230, 'service_role_tabellenrechte_effektiv',
    case when rolle_vorhanden = 1 then tabelle_effektiv
      else 'Rolle nicht vorhanden' end,
    'INFO: effektive Tabellenrechte inkl. Mitgliedschaft und PUBLIC',
    'INFO'
  from summary
  union all
  -- INFO E
  select 240, 'service_role_schemarechte_effektiv',
    case when rolle_vorhanden = 1 then schema_effektiv
      else 'Rolle nicht vorhanden' end,
    'INFO: effektive Schemarechte inkl. Mitgliedschaft und PUBLIC',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
