-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 3 — 02b VERIFY: READ-ONLY POSTCHECK NACH 02
-- ============================================================================
-- SICHERHEITSHINWEISE — vor dem Ausfuehren lesen:
--
--   1. Diese Datei laeuft AUSSCHLIESSLICH nach abgeschlossenem Schritt 02
--      (02_backup_value_add_batch3.sql, Ergebnis backup_rows = 10) und VOR
--      Schritt 03.
--   2. Sie ist strikt read-only: genau ein lesendes `with ... select`.
--      Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/TRUNCATE,
--      keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
--      steuerung. Nichts an der Datenbank wird veraendert.
--   3. Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu. Vor dem Ausfuehren im
--      SQL-Editor pruefen, dass genau dieses Projekt ausgewaehlt ist. Die
--      ersten beiden Ergebniszeilen (INFO) zeigen current_user und
--      current_database zur Protokollierung.
--   4. Bei IRGENDEINEM FAIL: Schritt 03 (03_backfill_value_add_batch3.sql)
--      NICHT starten. Befund melden und Ursache klaeren.
--   5. Fehlt cbb_private_backup.value_add_pre_backfill_v3, scheitert das
--      Statement bewusst hart mit "relation does not exist". Das ist der
--      gewollte fail-closed Ausgang: dann ist 02 nicht (mehr) wirksam und 03
--      darf ebenfalls nicht laufen.
--
-- GRENZE DER KONTROLLIERTEN FAIL-MELDUNG (bewusst, siehe RUNBOOK Abschnitt 8):
--   Der Batch-3-Snapshot wird direkt referenziert — sein Fehlen ist ein
--   Planungsfehler, kein Report. Die Artefakte von Batch 1 und Batch 2 werden
--   dagegen nur ueber to_regclass geprueft, damit ihr Fehlen als lesbare
--   FAIL-Zeile erscheint (Zeile 180) statt als "relation does not exist".
--   Preis: die exakte Zeilenzahl dieser Tabellen liest diese Datei bewusst
--   nicht. Der harte Beleg, dass beide Vorgaenger inhaltlich intakt sind,
--   kommt aus public.products (Zeile 190).
--
-- ERWARTETES ERGEBNIS: 21 Zeilen — 17 harte PASS-Zeilen (Sortierung 30 bis 190)
-- und 4 INFO-Zeilen (10, 20, 200, 210). Jede FAIL-Zeile blockiert Schritt 03.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. Innerhalb von Text-Literalen
-- kommt bewusst KEIN Semikolon vor (Trenner in Ausgabetexten ist ' | ').
-- Es kommen ausschliesslich lesende Konstrukte vor (with, select, values,
-- from, join, left join, cross join, lateral, where, filter, case, exists,
-- union all, order by) sowie die lesenden Katalogfunktionen to_regclass,
-- aclexplode, acldefault, has_table_privilege und has_schema_privilege. Die
-- Woerter SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, USAGE
-- und CREATE erscheinen ausserhalb von Kommentaren ausschliesslich als
-- Privilegnamen in values-Listen, die an has_table_privilege bzw.
-- has_schema_privilege uebergeben werden. "PUBLIC" erscheint nur als
-- Grantee-Bezeichner in Textausgaben, nicht als Rechte-Anweisung.
-- ============================================================================

with
-- ---------------------------------------------------------------------------
-- Referenzmengen
-- ---------------------------------------------------------------------------
target_slugs(slug) as (
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
-- PUBLIC ist in aclexplode die Grantee-OID 0, anon/authenticated ueber pg_roles.
app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Snapshot-Inhalt (Pruefungen 1, 4, 5)
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
    coalesce(
      string_agg(b.slug, ' | ' order by b.slug)
        filter (where b.editorial_note is not null),
      'KEINE'
    ) as note_slugs
  from cbb_private_backup.value_add_pre_backfill_v3 b
),

-- ---------------------------------------------------------------------------
-- Snapshot-Zielmenge: exakt die 10 Slugs aus 02 (Pruefung 3)
-- ---------------------------------------------------------------------------
slug_set as (
  select
    (select count(*)
     from target_slugs t
     where not exists (
       select 1
       from cbb_private_backup.value_add_pre_backfill_v3 b
       where b.slug = t.slug
     ))::integer as slugs_fehlend,
    (select count(*)
     from cbb_private_backup.value_add_pre_backfill_v3 b
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
  where a.attrelid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
    and a.attnum > 0
    and not a.attisdropped
),

-- ---------------------------------------------------------------------------
-- Drift Snapshot <-> aktuelle products ueber ALLE gespeicherten Felder,
-- inklusive editorial_note, updated_at und die acht Value-Add-Felder
-- (Pruefung 6)
-- ---------------------------------------------------------------------------
drift_state as (
  select count(*)::integer as drift
  from cbb_private_backup.value_add_pre_backfill_v3 b
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
-- Live-Zustand (Pruefungen 7, 8) und Vorgaenger-Beleg (Pruefung 17)
-- ---------------------------------------------------------------------------
products_state as (
  select
    (select count(*) from public.products)::bigint as produkte,
    (select count(*) from public.products where is_published is true)::bigint
      as produkte_published,
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
        or p.alternative_kind is not null)::integer as ziel_value_add_nicht_null,
    (select count(*)
     from public.products p
     where p.fuer_wen is not null
        or p.nicht_fuer is not null
        or p.key_fact is not null
        or p.pros is not null
        or p.cons is not null
        or p.alternative_slug is not null
        or p.alternative_reason is not null
        or p.alternative_kind is not null)::integer as befuellt_gesamt,
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
       and p.editorial_note is not null)::integer as batch2_vollstaendig
),

-- ---------------------------------------------------------------------------
-- Absicherung der Snapshot-Tabelle: RLS, Policies, Constraints (9, 10, 11)
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
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
),

-- ---------------------------------------------------------------------------
-- Harte Vorbedingung der Rechte-Pruefungen (Pruefung 12)
-- Fehlt eine der Rollen anon/authenticated, liefert der Grantee-Join fuer sie
-- still 0 Treffer. Ein Zaehler von 0 waere dann KEIN Beleg fuer "keine Rechte",
-- sondern nur fuer "keine Rolle". Deshalb ist die Rollenpraesenz eine eigene
-- harte Zeile und zusaetzlich Bedingung in den Pruefungen 13 und 14.
-- ---------------------------------------------------------------------------
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Direkte ACL-Eintraege auf Snapshot-Tabelle und Schema (Teil a von 13, 14)
-- Bewusst NICHT ueber information_schema: dort fehlen Default-ACLs
-- (acl is null) und PUBLIC-Eintraege. Stattdessen pg_class bzw. pg_namespace
-- mit aclexplode(coalesce(acl, acldefault(...))). Erwartet: jeweils 0.
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
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
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
    where c.oid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
  )
),

-- ---------------------------------------------------------------------------
-- Effektive Privilegien von anon/authenticated (Teil b von 13, 14)
-- aclexplode sieht nur DIREKTE Grantees. Erbt anon oder authenticated ein Recht
-- ueber eine Rollenmitgliedschaft, taucht der Grantee in der ACL gar nicht auf
-- und die direkten Zaehler blieben faelschlich 0. has_table_privilege bzw.
-- has_schema_privilege loesen Mitgliedschaft UND PUBLIC-Rechte mit auf und
-- schliessen genau diesen Fail-open-Rand. Erwartet: jeweils 0.
-- Beide CTEs aggregieren ohne group by und liefern deshalb immer genau eine
-- Zeile, auch wenn keine einzige Kombination zutrifft.
-- ---------------------------------------------------------------------------
table_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer as tabelle_anon_effektiv,
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
          'cbb_private_backup.value_add_pre_backfill_v3'::regclass::oid,
          p.priv::text)
),
schema_privileges_effective as (
  select
    count(*) filter (where r.rolname = 'anon')::integer as schema_anon_effektiv,
    count(*) filter (where r.rolname = 'authenticated')::integer
      as schema_auth_effektiv
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  join pg_class c
    on c.oid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- Batch-3-Payload aus 03 darf noch NICHT existieren (Pruefung 15).
-- Die Artefakte von Batch 1 und Batch 2 muessen noch da sein (Pruefung 16).
-- Beides ueber to_regclass, damit ein Befund als FAIL-Zeile erscheint.
-- ---------------------------------------------------------------------------
artefakt_state as (
  select
    to_regclass('cbb_private_backup.value_add_payload_v3') is null
      as payload_v3_fehlt,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null
      as v1_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null
      as v1_payload_da,
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null
      as v2_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null
      as v2_payload_da
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
  cross join role_presence
  cross join table_privileges
  cross join schema_privileges
  cross join table_privileges_effective
  cross join schema_privileges_effective
  cross join artefakt_state
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
  select 30, 'snapshot_v3_zeilen', zeilen::text, '10',
    case when zeilen = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'snapshot_v3_spalten',
    spalten_gesamt::text || ' gesamt, ' || spalten_erwartet::text
      || ' erwartete Namen',
    '12 gesamt, 12 erwartete Namen',
    case when spalten_gesamt = 12 and spalten_erwartet = 12
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'snapshot_v3_zielmenge',
    slugs_fehlend::text || ' fehlend, ' || slugs_zusaetzlich::text
      || ' zusaetzlich',
    '0 fehlend, 0 zusaetzlich',
    case when slugs_fehlend = 0 and slugs_zusaetzlich = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'snapshot_v3_ids_slugs_eindeutig',
    eindeutige_ids::text || '/' || eindeutige_slugs::text,
    '10/10',
    case when eindeutige_ids = 10 and eindeutige_slugs = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'snapshot_v3_value_add_nicht_null', value_add_nicht_null::text, '0',
    case when value_add_nicht_null = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'snapshot_v3_gegen_products_drift', drift::text, '0',
    case when drift = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'produkte_mindestens_300', produkte::text, '>= 300',
    case when produkte >= 300 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'aktuelle_zielprodukte_value_add_nicht_null',
    ziel_value_add_nicht_null::text, '0',
    case when ziel_value_add_nicht_null = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'snapshot_v3_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 10
  select 120, 'snapshot_v3_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 11
  select 130, 'snapshot_v3_constraints',
    'PK ' || pk_constraints::text || ', UNIQUE(slug) '
      || slug_unique_constraints::text,
    'PK 1, UNIQUE(slug) 1',
    case when pk_constraints = 1 and slug_unique_constraints = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 12
  select 140, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 13
  select 150, 'snapshot_v3_tabellenrechte_app_rollen',
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
  -- 14
  select 160, 'snapshot_v3_schemarechte_app_rollen',
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
  -- 15
  select 170, 'payload_v3_fehlt_noch', payload_v3_fehlt::text, 'true',
    case when payload_v3_fehlt then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 16
  select 180, 'vorgaenger_artefakte_vorhanden',
    'snapshot v1 ' || v1_snapshot_da::text
      || ' | payload v1 ' || v1_payload_da::text
      || ' | snapshot v2 ' || v2_snapshot_da::text
      || ' | payload v2 ' || v2_payload_da::text,
    'alle vier true',
    case when v1_snapshot_da and v1_payload_da and v2_snapshot_da and v2_payload_da
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 17
  select 190, 'vorgaenger_befuellung_intakt',
    befuellt_gesamt::text || ' Zeilen mit Value-Add gesamt'
      || ' | Batch 1 vollstaendig ' || batch1_vollstaendig::text
      || ' | Batch 2 vollstaendig ' || batch2_vollstaendig::text,
    '20 Zeilen mit Value-Add gesamt | Batch 1 vollstaendig 10 | Batch 2 vollstaendig 10',
    case when befuellt_gesamt = 20 and batch1_vollstaendig = 10
           and batch2_vollstaendig = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 200, 'snapshot_v3_bestehende_editorial_notes',
    notes::text || ': ' || note_slugs,
    'INFO: jeder genannte Slug wird durch 03 bewusst ueberschrieben'
      || ' und von 05 wortgleich zurueckgeholt',
    'INFO'
  from summary
  union all
  select 210, 'produkte_gesamt_und_published',
    produkte::text || ' gesamt | ' || produkte_published::text || ' published',
    'INFO: am 2026-08-26 waren es 376 gesamt und 372 published',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
