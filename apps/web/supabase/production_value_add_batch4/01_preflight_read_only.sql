-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 4 — 01 READ-ONLY PREFLIGHT
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
-- UNTERSCHIED ZU BATCH 3:
--   Batch 4 muss gegen DREI abgeschlossene Chargen disjunkt sein, nicht nur
--   gegen zwei. Der Ausgangszustand ist deshalb 30 befuellte Zeilen (10 aus
--   Batch 1, 10 aus Batch 2, 10 aus Batch 3), und es werden sechs v1-/v2-/v3-
--   Artefakte auf Existenz und Form geprueft statt vier. Die Zielmenge ist
--   zwoelf Zeilen gross statt zehn. Eine Schema-Migration bringt Batch 4 wie
--   Batch 2 und Batch 3 nicht mit.
--
--   ZWEITER UNTERSCHIED: Batch 4 legt KEINE Relation an. Alle zwoelf Zeilen
--   bekommen alternative_slug, alternative_reason und alternative_kind als
--   NULL. Es gibt deshalb keine Relationsziel-Pruefung wie in Batch 3 — wohl
--   aber die Pruefung, dass die BESTEHENDEN Relationen aus Batch 1 bis 3
--   weiterhin auf veroeffentlichte Produkte zeigen.
--
-- ROBUSTHEIT UND IHRE GRENZE (bewusst, siehe RUNBOOK Abschnitt 6):
--   Die Artefakte von Batch 1, 2 und 3 werden hier AUSSCHLIESSLICH ueber
--   den Systemkatalog geprueft (to_regclass, pg_class, pg_attribute, pg_policy,
--   pg_constraint). Es gibt keine direkte Referenz auf diese Tabellen. Grund:
--   eine direkte Referenz wuerde bei fehlender Tabelle bereits die PLANUNG
--   abbrechen. Dann gaebe es ueberhaupt keinen Report, sondern nur
--   "relation does not exist". Gewollt ist hier das Gegenteil: ein
--   kontrollierter FAIL-Report, der zeigt, WAS fehlt.
--   Preis dieser Robustheit: die EXAKTE Zeilenzahl der v1-/v2-/v3-Tabellen kann
--   dieses Artefakt nicht lesen. Zeile 290 gibt nur die Katalogschaetzung
--   reltuples aus (INFO, ohne Zusage). Der harte Beleg, dass Batch 1 bis 3
--   unangetastet sind, kommt aus Zeile 190 ueber public.products.
--
--   public.products dagegen wird direkt gelesen. Fehlt diese Tabelle, bricht
--   bereits die Planung fail-closed ab. Das ist gewollt: ohne products ist der
--   ganze Vorgang gegenstandslos.
--
-- ERWARTETES ERGEBNIS: 29 Zeilen — 20 harte PASS-Zeilen (Sortierung 30 bis 220)
-- und 9 INFO-Zeilen (10, 20, 230 bis 290). Jede FAIL-Zeile blockiert Schritt 02.
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
-- Die zehn Slugs aus Batch 2, aus demselben Grund als Literale.
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
-- Die zehn Slugs aus Batch 3, aus demselben Grund als Literale.
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
-- Value-Add-Schema: fuer Batch 4 muss es VOLLSTAENDIG vorhanden sein
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
-- Zustand der zwoelf Batch-4-Zielprodukte
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

-- ---------------------------------------------------------------------------
-- Disjunktheit gegen Batch 1, Batch 2 UND Batch 3 — rein literal
-- ---------------------------------------------------------------------------
disjunkt_state as (
  select
    (select count(*) from target_slugs t join batch1_slugs b on b.slug = t.slug)::integer
      as ueberschneidung_b1,
    (select count(*) from target_slugs t join batch2_slugs b on b.slug = t.slug)::integer
      as ueberschneidung_b2,
    (select count(*) from target_slugs t join batch3_slugs b on b.slug = t.slug)::integer
      as ueberschneidung_b3
),

-- ---------------------------------------------------------------------------
-- Batch 1, 2 und 3 in public.products: genau diese dreissig Slugs tragen
-- Value-Add-Daten und sonst niemand. Das ist der harte Beleg, dass alle drei
-- Chargen intakt sind — er kommt bewusst aus products und nicht aus den
-- v1-/v2-/v3-Tabellen (siehe Kopf).
-- ---------------------------------------------------------------------------
vorgaenger_state as (
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
-- Artefakte von Batch 1, 2 und 3: Existenz und Form, nur ueber den Katalog
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
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')
        and a.attnum > 0 and not a.attisdropped)::integer as v1_snapshot_spalten,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_payload_v1')
        and a.attnum > 0 and not a.attisdropped)::integer as v1_payload_spalten,
    coalesce((select c.reltuples::bigint from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v1')),
      -1) as v1_snapshot_reltuples
),
v2_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null
      as v2_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v2') is not null
      as v2_payload_da,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v2')),
      false) as v2_snapshot_rls,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_payload_v2')),
      false) as v2_payload_rls,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v2')
    )::integer as v2_snapshot_policies,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_payload_v2')
    )::integer as v2_payload_policies,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v2')
        and a.attnum > 0 and not a.attisdropped)::integer as v2_snapshot_spalten,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_payload_v2')
        and a.attnum > 0 and not a.attisdropped)::integer as v2_payload_spalten,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v2')
        and con.contype = 'p')::integer as v2_snapshot_pk,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_payload_v2')
        and con.contype = 'p')::integer as v2_payload_pk,
    coalesce((select c.reltuples::bigint from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v2')),
      -1) as v2_snapshot_reltuples
),
v3_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
      as v3_snapshot_da,
    to_regclass('cbb_private_backup.value_add_payload_v3') is not null
      as v3_payload_da,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v3')),
      false) as v3_snapshot_rls,
    coalesce((select c.relrowsecurity from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_payload_v3')),
      false) as v3_payload_rls,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v3')
    )::integer as v3_snapshot_policies,
    (select count(*) from pg_policy pol
      where pol.polrelid = to_regclass('cbb_private_backup.value_add_payload_v3')
    )::integer as v3_payload_policies,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v3')
        and a.attnum > 0 and not a.attisdropped)::integer as v3_snapshot_spalten,
    (select count(*) from pg_attribute a
      where a.attrelid = to_regclass('cbb_private_backup.value_add_payload_v3')
        and a.attnum > 0 and not a.attisdropped)::integer as v3_payload_spalten,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_pre_backfill_v3')
        and con.contype = 'p')::integer as v3_snapshot_pk,
    (select count(*) from pg_constraint con
      where con.conrelid = to_regclass('cbb_private_backup.value_add_payload_v3')
        and con.contype = 'p')::integer as v3_payload_pk,
    coalesce((select c.reltuples::bigint from pg_class c
      where c.oid = to_regclass('cbb_private_backup.value_add_pre_backfill_v3')),
      -1) as v3_snapshot_reltuples
),

-- ---------------------------------------------------------------------------
-- Batch-4-Artefakte muessen vor dem Erstlauf FEHLEN
-- ---------------------------------------------------------------------------
v4_state as (
  select
    to_regclass('cbb_private_backup.value_add_pre_backfill_v4') is null
      as v4_snapshot_fehlt,
    to_regclass('cbb_private_backup.value_add_payload_v4') is null
      as v4_payload_fehlt
),

-- ---------------------------------------------------------------------------
-- Die bereits bestehenden Relationen aus Batch 1 bis 3 muessen intakt sein.
-- Waere eines ihrer Ziele zwischenzeitlich offline gegangen, zeigte auf
-- Production schon jetzt eine Alternative ins Leere — das ist zu klaeren,
-- bevor eine vierte Charge dazukommt. Batch 4 selbst legt KEINE Relation an.
-- ---------------------------------------------------------------------------
bestehende_relationen as (
  select count(*)::integer as defekte_relationen
  from public.products p
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true)
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
  cross join disjunkt_state
  cross join vorgaenger_state
  cross join v1_state
  cross join v2_state
  cross join v3_state
  cross join v4_state
  cross join bestehende_relationen
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
  select 60, 'zielprodukte_batch4', zielprodukte::text, '12',
    case when zielprodukte = 12 then 'PASS' else 'FAIL' end from summary
  union all
  -- 5
  select 70, 'veroeffentlichte_zielprodukte',
    veroeffentlichte_zielprodukte::text, '12',
    case when veroeffentlichte_zielprodukte = 12 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'value_add_schema_vollstaendig',
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
  -- 7
  select 90, 'batch4_bereits_befuellt', bereits_befuellt::text, '0',
    case when bereits_befuellt = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 8
  select 100, 'v1_artefakte_vorhanden',
    ('snapshot ' || v1_snapshot_da::text || ' | payload ' || v1_payload_da::text),
    'snapshot true | payload true',
    case when v1_snapshot_da and v1_payload_da then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'v2_artefakte_vorhanden',
    ('snapshot ' || v2_snapshot_da::text || ' | payload ' || v2_payload_da::text),
    'snapshot true | payload true',
    case when v2_snapshot_da and v2_payload_da then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 10
  select 120, 'v3_artefakte_vorhanden',
    ('snapshot ' || v3_snapshot_da::text || ' | payload ' || v3_payload_da::text),
    'snapshot true | payload true',
    case when v3_snapshot_da and v3_payload_da then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 11
  select 130, 'v1_form',
    ('snapshot RLS ' || v1_snapshot_rls::text
      || ' Spalten ' || v1_snapshot_spalten::text
      || ' | payload RLS ' || v1_payload_rls::text
      || ' Spalten ' || v1_payload_spalten::text),
    'snapshot RLS true Spalten 12 | payload RLS true Spalten 10',
    case when v1_snapshot_da and v1_payload_da
           and v1_snapshot_rls is true and v1_payload_rls is true
           and v1_snapshot_spalten = 12 and v1_payload_spalten = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 12
  select 140, 'v2_form',
    ('snapshot RLS ' || v2_snapshot_rls::text
      || ' Policies ' || v2_snapshot_policies::text
      || ' Spalten ' || v2_snapshot_spalten::text
      || ' PK ' || v2_snapshot_pk::text
      || ' | payload RLS ' || v2_payload_rls::text
      || ' Policies ' || v2_payload_policies::text
      || ' Spalten ' || v2_payload_spalten::text
      || ' PK ' || v2_payload_pk::text),
    'snapshot RLS true Policies 0 Spalten 12 PK 1 | payload RLS true Policies 0 Spalten 10 PK 1',
    case when v2_snapshot_da and v2_payload_da
           and v2_snapshot_rls is true and v2_payload_rls is true
           and v2_snapshot_policies = 0 and v2_payload_policies = 0
           and v2_snapshot_spalten = 12 and v2_payload_spalten = 10
           and v2_snapshot_pk = 1 and v2_payload_pk = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 13
  select 150, 'v3_form',
    ('snapshot RLS ' || v3_snapshot_rls::text
      || ' Policies ' || v3_snapshot_policies::text
      || ' Spalten ' || v3_snapshot_spalten::text
      || ' PK ' || v3_snapshot_pk::text
      || ' | payload RLS ' || v3_payload_rls::text
      || ' Policies ' || v3_payload_policies::text
      || ' Spalten ' || v3_payload_spalten::text
      || ' PK ' || v3_payload_pk::text),
    'snapshot RLS true Policies 0 Spalten 12 PK 1 | payload RLS true Policies 0 Spalten 10 PK 1',
    case when v3_snapshot_da and v3_payload_da
           and v3_snapshot_rls is true and v3_payload_rls is true
           and v3_snapshot_policies = 0 and v3_payload_policies = 0
           and v3_snapshot_spalten = 12 and v3_payload_spalten = 10
           and v3_snapshot_pk = 1 and v3_payload_pk = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 14
  select 160, 'batch4_disjunkt_zu_batch1', ueberschneidung_b1::text, '0',
    case when ueberschneidung_b1 = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 15
  select 170, 'batch4_disjunkt_zu_batch2', ueberschneidung_b2::text, '0',
    case when ueberschneidung_b2 = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 16
  select 180, 'batch4_disjunkt_zu_batch3', ueberschneidung_b3::text, '0',
    case when ueberschneidung_b3 = 0 then 'PASS' else 'FAIL' end from summary
  union all
  -- 17
  select 190, 'vorgaenger_befuellung_intakt',
    (befuellt_gesamt::text || ' Zeilen mit Value-Add gesamt | Batch 1 vollstaendig '
      || batch1_vollstaendig::text || ' | Batch 2 vollstaendig '
      || batch2_vollstaendig::text || ' | Batch 3 vollstaendig '
      || batch3_vollstaendig::text),
    '30 Zeilen mit Value-Add gesamt | Batch 1 vollstaendig 10 | Batch 2 vollstaendig 10 | Batch 3 vollstaendig 10',
    case when befuellt_gesamt = 30 and batch1_vollstaendig = 10
           and batch2_vollstaendig = 10 and batch3_vollstaendig = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 18
  select 200, 'v4_snapshot_fehlt', v4_snapshot_fehlt::text, 'true',
    case when v4_snapshot_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  -- 19
  select 210, 'v4_payload_fehlt', v4_payload_fehlt::text, 'true',
    case when v4_payload_fehlt then 'PASS' else 'FAIL' end from summary
  union all
  -- 20
  select 220, 'bestehende_relationen_intakt', defekte_relationen::text, '0',
    case when defekte_relationen = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 230, 'produkte_gesamt_und_published',
    (produkte::text || ' gesamt | ' || produkte_published::text || ' published'),
    'INFO: am 2026-08-26 waren es 376 gesamt und 372 published',
    'INFO' from summary
  union all
  select 240, 'bestehende_editorial_notes',
    (bestehende_editorial_notes::text || ': ' || editorial_note_slugs),
    'INFO: jeder genannte Slug wird durch den Backfill bewusst ueberschrieben und von 05 wortgleich zurueckgeholt',
    'INFO' from summary
  union all
  select 250, 'products_rls', products_rls::text, 'INFO', 'INFO' from summary
  union all
  select 260, 'products_policies', products_policies::text, 'INFO', 'INFO'
  from summary
  union all
  select 270, 'app_grants_products', app_grants::text, 'INFO', 'INFO' from summary
  union all
  select 280, 'products_user_trigger',
    (trigger_anzahl::text || ': ' || trigger_definition), 'INFO', 'INFO'
  from summary
  union all
  select 290, 'vorgaenger_artefakte_geschaetzte_zeilen',
    ('v1 snapshot reltuples ' || v1_snapshot_reltuples::text
      || ' | v2 snapshot reltuples ' || v2_snapshot_reltuples::text
      || ' | v3 snapshot reltuples ' || v3_snapshot_reltuples::text),
    'INFO: Katalogschaetzung ohne Zusage, exakte Zeilenzahl liest 01 bewusst nicht',
    'INFO' from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
