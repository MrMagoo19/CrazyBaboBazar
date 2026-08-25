-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 2 — 01 READ-ONLY PREFLIGHT
-- ============================================================================
-- Zielprojekt ausserhalb von SQL sichtbar pruefen:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Dieses Artefakt ist genau ein lesendes WITH ... SELECT. Es veraendert weder
-- Schema noch Daten. Kein INSERT/UPDATE/DELETE/MERGE, kein CREATE/ALTER/DROP/
-- TRUNCATE, keine Rechtevergabe, kein CALL, kein DO-Block, keine Transaktions-
-- steuerung.
--
-- UNTERSCHIED ZU BATCH 1:
--   Batch 2 bringt KEINE Schema-Migration mit. Die acht Value-Add-Spalten und
--   die zwei CHECK-Constraints existieren auf Production bereits. Dieser
--   Preflight verlangt sie deshalb als 8/8 + 2/2 vorhanden, nicht als 0/8.
--
-- ROBUSTHEIT UND IHRE GRENZE (bewusst, siehe RUNBOOK Abschnitt 6):
--   Die Batch-1-Artefakte cbb_private_backup.value_add_pre_backfill_v1 und
--   cbb_private_backup.value_add_payload_v1 werden hier AUSSCHLIESSLICH ueber
--   den Systemkatalog geprueft (to_regclass, pg_class, pg_attribute, pg_policy,
--   pg_constraint). Es gibt keine direkte Referenz auf diese Tabellen. Grund:
--   eine direkte Referenz wuerde bei fehlender Tabelle bereits die PLANUNG
--   abbrechen; dann gaebe es ueberhaupt keinen Report, sondern nur
--   "relation does not exist". Gewollt ist hier das Gegenteil: ein
--   kontrollierter FAIL-Report, der zeigt, WAS fehlt.
--   Preis dieser Robustheit: die EXAKTE Zeilenzahl der v1-Tabellen kann dieses
--   Artefakt nicht lesen. Zeile 250 gibt nur die Katalogschaetzung reltuples
--   aus (INFO, ohne Zusage). Der harte Beleg, dass Batch 1 unangetastet ist,
--   kommt aus Zeile 160 ueber public.products, nicht aus den v1-Tabellen.
--
--   public.products dagegen wird direkt gelesen. Fehlt diese Tabelle, bricht
--   bereits die Planung fail-closed ab. Das ist gewollt: ohne products ist der
--   ganze Vorgang gegenstandslos.
--
-- ERWARTETES ERGEBNIS: 25 Zeilen — 16 harte PASS-Zeilen (Sortierung 30 bis 180)
-- und 9 INFO-Zeilen (10, 20, 190 bis 250). Jede FAIL-Zeile blockiert Schritt 02.
--
-- SELBSTPRUEFUNG (Form): Die Datei enthaelt neben Kommentaren genau ein
-- Statement — ein einziges `with ... select ... order by`, abgeschlossen durch
-- das einzige Semikolon der Datei am Dateiende. In Text-Literalen kommt kein
-- Semikolon vor (Trenner in Ausgabetexten ist ' | '). Es kommen ausschliesslich
-- lesende Konstrukte vor (with, select, values, from, join, left join, cross
-- join, where, filter, case, exists, union all, order by) sowie die lesenden
-- Katalogfunktionen to_regclass und pg_get_triggerdef.
-- ============================================================================

with
-- ---------------------------------------------------------------------------
-- Referenzmengen (reine Literale, kein Tabellenzugriff)
-- ---------------------------------------------------------------------------
target_slugs(slug) as (
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
-- Beide Relationsziele liegen INNERHALB von Batch 2. Damit ist die Relation
-- vollstaendig aus derselben, bereits bestaetigten Zielmenge guardbar.
relation_slugs(slug) as (
  values
    ('gluecksgut-anti-stress-wuerfel'),
    ('shashibo-formwechsel-box-magnetisch')
),
-- Die zehn Slugs aus Batch 1. Sie stehen hier als Literale, damit die
-- Disjunktheitspruefung ohne Zugriff auf die v1-Tabellen auskommt.
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
-- Value-Add-Schema: fuer Batch 2 muss es VOLLSTAENDIG vorhanden sein
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Zustand der zehn Batch-2-Zielprodukte
-- ---------------------------------------------------------------------------
target_state as (
  select
    count(*)::integer as zielprodukte,
    count(*) filter (where p.is_published is true)::integer
      as veroeffentlichte_zielprodukte,
    count(*) filter (
      where p.fuer_wen is not null
         or p.nicht_fuer is not null
         or p.key_fact is not null
         or p.pros is not null
         or p.cons is not null
         or p.alternative_slug is not null
         or p.alternative_reason is not null
         or p.alternative_kind is not null
    )::integer as bereits_befuellt,
    count(*) filter (where p.editorial_note is not null)::integer
      as bestehende_editorial_notes,
    coalesce(
      string_agg(p.slug, ' | ' order by p.slug)
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

-- ---------------------------------------------------------------------------
-- Disjunktheit gegen Batch 1 — rein literal, ohne Zugriff auf v1-Tabellen
-- ---------------------------------------------------------------------------
disjunkt_state as (
  select count(*)::integer as ueberschneidungen
  from target_slugs t
  join batch1_slugs b on b.slug = t.slug
),

-- ---------------------------------------------------------------------------
-- Batch 1 in public.products: genau die zehn v1-Slugs tragen Value-Add-Daten
-- und sonst niemand. Das ist der harte Beleg, dass Batch 1 intakt ist — er
-- kommt bewusst aus products und nicht aus den v1-Tabellen (siehe Kopf).
-- ---------------------------------------------------------------------------
batch1_state as (
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
        or p.alternative_kind is not null)::integer as befuellt_gesamt,
    (select count(*)
     from public.products p
     join batch1_slugs b on b.slug = p.slug
     where p.fuer_wen is not null
        and p.nicht_fuer is not null
        and p.key_fact is not null
        and p.pros is not null
        and p.cons is not null
        and p.editorial_note is not null)::integer as batch1_vollstaendig
),

-- ---------------------------------------------------------------------------
-- Batch-1-Artefakte: Existenz und Form, ausschliesslich ueber den Katalog
-- ---------------------------------------------------------------------------
v1_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null
      as v1_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v1') is not null
      as v1_payload_da,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')),
      false) as v1_snapshot_rls,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_payload_v1')),
      false) as v1_payload_rls,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')
    )::integer as v1_snapshot_policies,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_payload_v1')
    )::integer as v1_payload_policies,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')
        and a.attnum > 0 and not a.attisdropped)::integer as v1_snapshot_spalten,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_payload_v1')
        and a.attnum > 0 and not a.attisdropped)::integer as v1_payload_spalten,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')
        and con.contype = 'p')::integer as v1_snapshot_pk,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_payload_v1')
        and con.contype = 'p')::integer as v1_payload_pk,
    coalesce((select c.reltuples::bigint from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')),
      -1) as v1_snapshot_reltuples,
    coalesce((select c.reltuples::bigint from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_payload_v1')),
      -1) as v1_payload_reltuples
),

-- ---------------------------------------------------------------------------
-- Batch-2-Artefakte muessen vor dem Erstlauf FEHLEN
-- ---------------------------------------------------------------------------
v2_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null
      as v2_snapshot_fehlt,
    to_regclass('cbb_private_backup.value_add_payload_v2') is null
      as v2_payload_fehlt
),

-- ---------------------------------------------------------------------------
-- Kontext ohne Zusage
-- ---------------------------------------------------------------------------
security_state as (
  select
    coalesce((
      select c.relrowsecurity
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = 'products'
    ), false) as products_rls,
    (select count(*) from pg_policies
      where schemaname = 'public' and tablename = 'products')::integer
      as products_policies,
    (select count(*) from information_schema.role_table_grants
      where table_schema = 'public'
        and table_name = 'products'
        and grantee in ('anon', 'authenticated'))::integer as app_grants
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

-- Jede der obigen CTEs liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from fingerprint
  cross join column_state
  cross join constraint_state
  cross join target_state
  cross join relation_state
  cross join disjunkt_state
  cross join batch1_state
  cross join v1_state
  cross join v2_state
  cross join security_state
  cross join trigger_state
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
  select 60, 'zielprodukte_batch2', zielprodukte::text, '10',
    case when zielprodukte = 10 then 'PASS' else 'FAIL' end from summary
  union all
  -- 5
  select 70, 'veroeffentlichte_zielprodukte',
    veroeffentlichte_zielprodukte::text, '10',
    case when veroeffentlichte_zielprodukte = 10 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'veroeffentlichte_relationsziele',
    (relationsziele::text || '/' || veroeffentlichte_relationsziele::text),
    '2/2',
    case when relationsziele = 2 and veroeffentlichte_relationsziele = 2
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'value_add_schema_vollstaendig',
    (vorhandene_spalten::text || '/8 Spalten, '
      || korrekt_typisierte_spalten::text || '/8 Typen, '
      || vorhandene_constraints::text || '/2 Constraints'),
    '8/8 Spalten, 8/8 Typen, 2/2 Constraints',
    case
      when vorhandene_spalten = 8 and korrekt_typisierte_spalten = 8
        and vorhandene_constraints = 2 then 'PASS'
      else 'FAIL'
    end
  from summary
  union all
  -- 8
  select 100, 'batch2_bereits_befuellt', bereits_befuellt::text, '0',
    case when bereits_befuellt = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 9
  select 110, 'v1_snapshot_vorhanden', v1_snapshot_da::text, 'true',
    case when v1_snapshot_da then 'PASS' else 'FAIL' end from summary
  union all
  -- 10
  select 120, 'v1_payload_vorhanden', v1_payload_da::text, 'true',
    case when v1_payload_da then 'PASS' else 'FAIL' end from summary
  union all
  -- 11
  select 130, 'v1_snapshot_form',
    ('RLS ' || v1_snapshot_rls::text
      || ' | Policies ' || v1_snapshot_policies::text
      || ' | Spalten ' || v1_snapshot_spalten::text
      || ' | PK ' || v1_snapshot_pk::text),
    'RLS true | Policies 0 | Spalten 12 | PK 1',
    case when v1_snapshot_da
           and v1_snapshot_rls is true
           and v1_snapshot_policies = 0
           and v1_snapshot_spalten = 12
           and v1_snapshot_pk = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 12
  select 140, 'v1_payload_form',
    ('RLS ' || v1_payload_rls::text
      || ' | Policies ' || v1_payload_policies::text
      || ' | Spalten ' || v1_payload_spalten::text
      || ' | PK ' || v1_payload_pk::text),
    'RLS true | Policies 0 | Spalten 10 | PK 1',
    case when v1_payload_da
           and v1_payload_rls is true
           and v1_payload_policies = 0
           and v1_payload_spalten = 10
           and v1_payload_pk = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 13
  select 150, 'batch2_disjunkt_zu_batch1', ueberschneidungen::text, '0',
    case when ueberschneidungen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 14
  select 160, 'batch1_befuellung_intakt',
    (befuellt_gesamt::text || ' Zeilen mit Value-Add gesamt | davon Batch 1 vollstaendig '
      || batch1_vollstaendig::text),
    '10 Zeilen mit Value-Add gesamt | davon Batch 1 vollstaendig 10',
    case when befuellt_gesamt = 10 and batch1_vollstaendig = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 15
  select 170, 'v2_snapshot_fehlt', v2_snapshot_fehlt::text, 'true',
    case when v2_snapshot_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  -- 16
  select 180, 'v2_payload_fehlt', v2_payload_fehlt::text, 'true',
    case when v2_payload_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'produkte_gesamt_und_published',
    (produkte::text || ' gesamt | ' || produkte_published::text || ' published'),
    'INFO: am 2026-08-26 waren es 376 gesamt und 372 published',
    'INFO' from summary
  union all
  select 200, 'bestehende_editorial_notes',
    (bestehende_editorial_notes::text || ': ' || editorial_note_slugs),
    'INFO: jeder genannte Slug wird durch den Backfill bewusst ueberschrieben',
    'INFO' from summary
  union all
  select 210, 'products_rls', products_rls::text, 'INFO', 'INFO' from summary
  union all
  select 220, 'products_policies', products_policies::text, 'INFO', 'INFO'
  from summary
  union all
  select 230, 'app_grants_products', app_grants::text, 'INFO', 'INFO' from summary
  union all
  select 240, 'products_user_trigger',
    (trigger_anzahl::text || ': ' || trigger_definition), 'INFO', 'INFO'
  from summary
  union all
  select 250, 'v1_artefakte_geschaetzte_zeilen',
    ('snapshot reltuples ' || v1_snapshot_reltuples::text
      || ' | payload reltuples ' || v1_payload_reltuples::text),
    'INFO: Katalogschaetzung ohne Zusage, exakte Zeilenzahl liest 01 bewusst nicht',
    'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
