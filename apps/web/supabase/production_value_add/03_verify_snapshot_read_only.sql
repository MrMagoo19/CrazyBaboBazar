-- ============================================================================
-- PRODUCTION VALUE-ADD — 03 VERIFY: READ-ONLY POSTCHECK NACH SCHRITT 03
-- ============================================================================
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 03
--      (03_backup_value_add.sql, Ergebnis backup_rows = 10) und VOR Schritt 04.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE,
--      keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
--      steuerung. Nichts an der Datenbank wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu. Vor dem Ausfuehren im
--      SQL-Editor pruefen, dass genau dieses Projekt ausgewaehlt ist. Die
--      ersten beiden Ergebniszeilen (INFO) zeigen current_user und
--      current_database zur Protokollierung.
--   4. Bei IRGENDEINEM FAIL: Schritt 04 (04_backfill_value_add.sql) NICHT
--      starten. Stattdessen Befund melden und Ursache klaeren.
--   5. Fehlt die Snapshot-Tabelle cbb_private_backup.value_add_pre_backfill_v1,
--      scheitert das Statement bewusst hart mit "relation does not exist".
--      Das ist der gewollte fail-closed Ausgang: dann ist 03 nicht (mehr)
--      wirksam und 04 darf ebenfalls nicht laufen.
--
-- ERWARTETES ERGEBNIS: 17 Zeilen — 2x INFO (current_user, current_database)
-- und 15 harte PASS-Zeilen (Sortierung 30 bis 170). Jede andere Kombination
-- blockiert Schritt 04.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige statement-trennende Semikolon am Dateiende. Weitere Semikolons
-- stehen nur innerhalb von Text-Literalen der Rechte-Pruefungen 13/14
-- ('Rollen n/2; PUBLIC ...') und trennen dort nichts. Es kommen
-- ausschliesslich lesende Konstrukte vor (with, select, values, from, join,
-- lateral, where, filter, case, exists, union all, order by) sowie die
-- lesenden Katalogfunktionen to_regclass, aclexplode und acldefault. Kein
-- DDL-, DML- oder Rechte-Schluesselwort ist enthalten. "PUBLIC" erscheint nur
-- als Grantee-Bezeichner in Textausgaben, nicht als Rechte-Anweisung.
-- ============================================================================

with
-- ---------------------------------------------------------------------------
-- Referenzmengen
-- ---------------------------------------------------------------------------
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
-- PUBLIC ist in aclexplode die Grantee-OID 0, anon/authenticated ueber pg_roles.
app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Snapshot-Inhalt (Pruefungen 1, 4, 5, 6)
-- Die drei erwarteten editorial_note-Slugs stehen bewusst als Literale in der
-- FILTER-Bedingung, damit hier keine Unteranfrage noetig ist.
-- ---------------------------------------------------------------------------
snapshot_rows as (
  select
    count(*)::integer as zeilen,
    count(distinct b.id)::integer as eindeutige_ids,
    count(distinct b.slug)::integer as eindeutige_slugs,
    count(*) filter (
      where b.fuer_wen is not null
         or b.nicht_fuer is not null
         or b.key_fact is not null
         or b.pros is not null
         or b.cons is not null
         or b.alternative_slug is not null
         or b.alternative_reason is not null
         or b.alternative_kind is not null
    )::integer as value_add_nicht_null,
    count(*) filter (where b.editorial_note is not null)::integer as notes,
    count(*) filter (
      where b.editorial_note is not null
        and b.slug not in (
          'n4-nussmilchbereiter-pflanzenmilch',
          'ninja-staysharp-messerset-6-teilig',
          'welpen-usb-ladekabel-hunde-design'
        )
    )::integer as notes_unerwartet,
    count(*) filter (
      where b.editorial_note is null
        and b.slug in (
          'n4-nussmilchbereiter-pflanzenmilch',
          'ninja-staysharp-messerset-6-teilig',
          'welpen-usb-ladekabel-hunde-design'
        )
    )::integer as notes_fehlend
  from cbb_private_backup.value_add_pre_backfill_v1 b
),

-- ---------------------------------------------------------------------------
-- Snapshot-Zielmenge: exakt die 10 Slugs aus 03 (Pruefung 3)
-- ---------------------------------------------------------------------------
slug_set as (
  select
    (select count(*)
     from target_slugs t
     where not exists (
       select 1
       from cbb_private_backup.value_add_pre_backfill_v1 b
       where b.slug = t.slug
     ))::integer as slugs_fehlend,
    (select count(*)
     from cbb_private_backup.value_add_pre_backfill_v1 b
     where not exists (
       select 1 from target_slugs t where t.slug = b.slug
     ))::integer as slugs_zusaetzlich
),

-- ---------------------------------------------------------------------------
-- Snapshot-Struktur: exakt 12 Spalten mit exakt diesen Namen (Pruefung 2)
-- spalten_gesamt = 12 und spalten_erwartet = 12 erzwingen zusammen die exakte
-- Namensmenge: 12 Treffer aus der Namensliste bei 12 Spalten insgesamt lassen
-- weder eine fehlende noch eine zusaetzliche Spalte zu.
-- ---------------------------------------------------------------------------
snapshot_shape as (
  select
    count(*)::integer as spalten_gesamt,
    count(*) filter (
      where a.attname in (
        'id', 'slug', 'editorial_note', 'updated_at',
        'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
        'alternative_slug', 'alternative_reason', 'alternative_kind'
      )
    )::integer as spalten_erwartet
  from pg_attribute a
  where a.attrelid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
    and a.attnum > 0
    and not a.attisdropped
),

-- ---------------------------------------------------------------------------
-- Drift Snapshot <-> aktuelle products ueber ALLE gespeicherten Felder,
-- inklusive editorial_note, updated_at und die 8 Value-Add-Felder (Pruefung 7)
-- ---------------------------------------------------------------------------
drift_state as (
  select count(*)::integer as drift
  from cbb_private_backup.value_add_pre_backfill_v1 b
  left join public.products p on p.id = b.id
  where p.id is null
     or p.slug is distinct from b.slug
     or p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind
),

-- ---------------------------------------------------------------------------
-- Live-Zustand: Produktbestand und Value-Add noch leer (Pruefungen 8, 9)
-- ---------------------------------------------------------------------------
products_state as (
  select
    (select count(*) from public.products)::bigint as produkte,
    (select count(*)
     from public.products p
     join target_slugs t on t.slug = p.slug
     where p.fuer_wen is not null
        or p.nicht_fuer is not null
        or p.key_fact is not null
        or p.pros is not null
        or p.cons is not null
        or p.alternative_slug is not null
        or p.alternative_reason is not null
        or p.alternative_kind is not null)::integer as ziel_value_add_nicht_null
),

-- ---------------------------------------------------------------------------
-- Absicherung der Snapshot-Tabelle: RLS, Policies, Constraints (10, 11, 12)
-- ---------------------------------------------------------------------------
snapshot_guard as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid)::integer
      as policies,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'p')::integer as pk_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'u'
        and (
          select array_agg(a.attname::text order by a.attname)
          from pg_attribute a
          where a.attrelid = con.conrelid
            and a.attnum = any(con.conkey)
        ) = array['slug']::text[])::integer as slug_unique_constraints
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
),

-- ---------------------------------------------------------------------------
-- Rechte (Pruefungen 13, 14)
-- Bewusst NICHT ueber information_schema.usage_privileges: dort fehlen
-- Default-ACLs (acl is null) und PUBLIC-Eintraege. Stattdessen pg_class bzw.
-- pg_namespace mit aclexplode(coalesce(acl, acldefault(...))). Gezaehlt wird
-- jede einzelne explizite oder per Default gesetzte Berechtigung der drei
-- App-Grantees PUBLIC (OID 0), anon und authenticated. Erwartet: jeweils 0.
-- WICHTIG: Fehlt eine der Rollen anon/authenticated, liefert der Join fuer sie
-- still 0 Treffer. Ein Zaehler von 0 allein ist deshalb kein Beleg fuer
-- "keine Rechte". Beide Rechte-Pruefungen (13, 14) fordern daher zusaetzlich
-- app_rollen = 2 aus role_presence — sonst FAIL statt stillem PASS.
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
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
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
  -- Das Schema wird ueber die Snapshot-Tabelle aufgeloest, damit auch dieser
  -- Zweig hart scheitert, wenn der Snapshot fehlt.
  where n.oid = (
    select c.relnamespace
    from pg_class c
    where c.oid = 'cbb_private_backup.value_add_pre_backfill_v1'::regclass
  )
),
-- Harte Vorbedingung der Pruefungen 13 und 14: existieren anon und
-- authenticated ueberhaupt? Fehlende Rollen wuerden die Rechtezaehlung sonst
-- still auf 0 druecken und beide Pruefungen faelschlich auf PASS setzen.
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Audit-Payload aus 04 darf noch NICHT existieren (Pruefung 15)
-- ---------------------------------------------------------------------------
payload_state as (
  select to_regclass('cbb_private_backup.value_add_payload_v1') is null
    as payload_fehlt
),

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from snapshot_rows
  cross join slug_set
  cross join snapshot_shape
  cross join drift_state
  cross join products_state
  cross join snapshot_guard
  cross join table_privileges
  cross join schema_privileges
  cross join role_presence
  cross join payload_state
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
  select 30, 'snapshot_zeilen', zeilen::text, '10',
    case when zeilen = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'snapshot_spalten',
    spalten_gesamt::text || ' gesamt, ' || spalten_erwartet::text
      || ' erwartete Namen',
    '12 gesamt, 12 erwartete Namen',
    case when spalten_gesamt = 12 and spalten_erwartet = 12
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'snapshot_zielmenge',
    slugs_fehlend::text || ' fehlend, ' || slugs_zusaetzlich::text
      || ' zusaetzlich',
    '0 fehlend, 0 zusaetzlich',
    case when slugs_fehlend = 0 and slugs_zusaetzlich = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'snapshot_ids_slugs_eindeutig',
    eindeutige_ids::text || '/' || eindeutige_slugs::text,
    '10/10',
    case when eindeutige_ids = 10 and eindeutige_slugs = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'snapshot_value_add_nicht_null', value_add_nicht_null::text, '0',
    case when value_add_nicht_null = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'snapshot_editorial_notes',
    notes::text || ' Notes, ' || notes_fehlend::text || ' fehlend, '
      || notes_unerwartet::text || ' unerwartet',
    '3 Notes, 0 fehlend, 0 unerwartet',
    case when notes = 3 and notes_fehlend = 0 and notes_unerwartet = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'snapshot_gegen_products_drift', drift::text, '0',
    case when drift = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'products_zeilen', produkte::text, '376',
    case when produkte = 376 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'aktuelle_zielprodukte_value_add_nicht_null',
    ziel_value_add_nicht_null::text, '0',
    case when ziel_value_add_nicht_null = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 10
  select 120, 'snapshot_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 11
  select 130, 'snapshot_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 12
  select 140, 'snapshot_constraints',
    'PK ' || pk_constraints::text || ', UNIQUE(slug) '
      || slug_unique_constraints::text,
    'PK 1, UNIQUE(slug) 1',
    case when pk_constraints = 1 and slug_unique_constraints = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 13
  select 150, 'snapshot_tabellenrechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2; PUBLIC '
      || tabelle_public_rechte::text
      || ', anon ' || tabelle_anon_rechte::text
      || ', authenticated ' || tabelle_auth_rechte::text,
    'Rollen 2/2; PUBLIC 0, anon 0, authenticated 0',
    case when app_rollen = 2
           and tabelle_public_rechte = 0
           and tabelle_anon_rechte = 0
           and tabelle_auth_rechte = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 14
  select 160, 'snapshot_schemarechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2; PUBLIC '
      || schema_public_rechte::text
      || ', anon ' || schema_anon_rechte::text
      || ', authenticated ' || schema_auth_rechte::text,
    'Rollen 2/2; PUBLIC 0, anon 0, authenticated 0',
    case when app_rollen = 2
           and schema_public_rechte = 0
           and schema_anon_rechte = 0
           and schema_auth_rechte = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 15
  select 170, 'audit_payload_v1_fehlt', payload_fehlt::text, 'true',
    case when payload_fehlt then 'PASS' else 'FAIL' end
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
