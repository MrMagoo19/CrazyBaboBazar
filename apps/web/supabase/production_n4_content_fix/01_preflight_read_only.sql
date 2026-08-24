-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 01 READ-ONLY PREFLIGHT
-- ============================================================================
-- Zielprojekt ausserhalb von SQL sichtbar pruefen:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WOFUER DIESE DATEI DA IST
--   Der Value-Add-Rollout (supabase/production_value_add/01..07) hat den
--   bekannten Zeit-Widerspruch der N4-Produktseite bewusst NICHT angefasst
--   (siehe Kopfkommentar von 04_backfill_value_add.sql und Pruefzeile 150 in
--   05_verify_read_only.sql). Dieses eigenstaendige Paket korrigiert genau
--   diesen Inhaltsfehler — und nichts sonst.
--
-- BELEGTER SACHVERHALT
--   * tagline behauptet "unter 2 Minuten"  (Quelle: import_products_batch13.sql)
--   * description behauptet "15 Minuten" und "Amortisiert sich nach 2 Monaten"
--     (Quelle: expand_descriptions_batch6.sql)
--   Beides widerspricht sich gegenseitig bzw. ist unbelegt.
--   Unabhaengige Belege fuer den korrigierten Text stehen in RUNBOOK.md.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein DDL, kein DML, keine
--   Transaktionssteuerung, kein DO-Block. Nichts wird veraendert.
--
-- FAIL-CLOSED-RAENDER
--   * cbb_private_backup.value_add_pre_backfill_v1 und
--     cbb_private_backup.value_add_payload_v1 werden DIREKT referenziert.
--     Fehlt eine der beiden, bricht bereits die Planung mit
--     "relation ... does not exist" ab. Das ist der gewollte Ausgang: ohne den
--     abgeschlossenen Value-Add-Zustand ist dieses Paket nicht anwendbar.
--   * public.products wird ebenfalls direkt referenziert.
--   * cbb_private_backup.n4_content_pre_fix_v1 darf hier noch NICHT existieren
--     und wird deshalb nur weich ueber to_regclass geprueft.
--
-- ERWARTETES ERGEBNIS: 21 Zeilen — 18 harte PASS-Zeilen (Sortierung 30 bis 200)
-- und 3 INFO-Zeilen (10, 20, 210). Jede FAIL-Zeile ist ein Befund und keine
-- Freigabe fuer Schritt 02.
-- ============================================================================

with
production_tables(name) as (
  values ('products'), ('page_content'), ('discovery_queue'), ('swipes')
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

-- ---------------------------------------------------------------------------
-- Der erwartete IST-Zustand der N4-Zeile VOR der Korrektur.
--   tagline      -> supabase/import_products_batch13.sql
--   description  -> supabase/expand_descriptions_batch6.sql
--   nicht_fuer / key_fact / pros / cons / editorial_note
--                -> supabase/production_value_add/04_backfill_value_add.sql
-- Weicht auch nur ein Feld ab, ist der Vorzustand ein anderer als angenommen
-- und Schritt 02 darf nicht laufen.
-- ---------------------------------------------------------------------------
n4_expected(
  tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
) as (
  values (
    '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten'::text,
    'N4 Nussmilchbereiter für frische Pflanzenmilch. Hafer-, Mandel-, Soja-, Reis- oder Cashew-Milch in 15 Minuten. Mixt, kocht, filtert automatisch. Für Menschen, die Bio-Milch-Preise satt haben und ihre Zutaten selbst kontrollieren wollen. Amortisiert sich nach 2 Monaten täglichem Frühstück.'::text,
    'Wer nur selten mal Hafermilch trinkt — die Anschaffung amortisiert sich dann kaum.'::text,
    '800-W-Bereiter mit Selbstreinigung für Hafer-, Mandel-, Soja-, Reis- und Cashew-Milch.'::text,
    array[
      'Mixt, kocht und filtert automatisch',
      'Selbstreinigung',
      'Fünf Milchsorten',
      '800 W'
    ]::text[],
    array[
      'Lohnt sich nur bei regelmäßigem Konsum',
      'Ein weiteres Küchengerät, das gereinigt werden will'
    ]::text[],
    'Macht frische Pflanzenmilch auf Knopfdruck und reinigt sich selbst. Für Menschen, die Milch-Alternativen ernst nehmen und die Bio-Laden-Preise satt haben. Lohnt sich, wenn täglich getrunken — sonst steht er nur rum.'::text
  )
),

n4_row as (
  select p.*
  from public.products p
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
),

fingerprint as (
  select
    current_user as ausfuehrende_rolle,
    current_database() as datenbank,
    (select count(*) from production_tables t
      where to_regclass('public.' || t.name) is not null)::integer
      as production_tabellen,
    (select count(*) from public.products)::bigint as produkte,
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    )::integer as pilot_artefakte,
    to_regclass('cbb_private_backup.n4_content_pre_fix_v1')::text as n4_backup
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

-- Value-Add-Marker: beide Tabellen direkt referenziert -> fail closed.
marker_state as (
  select
    (select count(*) from cbb_private_backup.value_add_pre_backfill_v1)::integer
      as snapshot_zeilen,
    (select count(*) from cbb_private_backup.value_add_payload_v1)::integer
      as payload_zeilen,
    (select count(*)
       from cbb_private_backup.value_add_payload_v1 v
      where v.slug = 'n4-nussmilchbereiter-pflanzenmilch'
        and v.fuer_wen is not null
        and v.nicht_fuer is not null
        and v.key_fact is not null
        and v.pros is not null
        and v.cons is not null
        and v.editorial_note is not null)::integer as payload_n4_befuellt
),

n4_state as (
  select
    (select count(*) from n4_row)::integer as n4_zeilen,
    (select count(*) from n4_row where is_published is true)::integer
      as n4_published,
    (select count(*) from n4_row r, n4_expected e
      where r.tagline is not distinct from e.tagline)::integer as ist_tagline,
    (select count(*) from n4_row r, n4_expected e
      where r.description is not distinct from e.description)::integer
      as ist_description,
    (select count(*) from n4_row r, n4_expected e
      where r.nicht_fuer is not distinct from e.nicht_fuer)::integer
      as ist_nicht_fuer,
    (select count(*) from n4_row r, n4_expected e
      where r.key_fact is not distinct from e.key_fact)::integer as ist_key_fact,
    (select count(*) from n4_row r, n4_expected e
      where r.pros is not distinct from e.pros)::integer as ist_pros,
    (select count(*) from n4_row r, n4_expected e
      where r.cons is not distinct from e.cons)::integer as ist_cons,
    (select count(*) from n4_row r, n4_expected e
      where r.editorial_note is not distinct from e.editorial_note)::integer
      as ist_editorial_note,
    (select count(*) from n4_row r, n4_expected e
      where r.tagline is not distinct from e.tagline
        and r.description is not distinct from e.description
        and r.nicht_fuer is not distinct from e.nicht_fuer
        and r.key_fact is not distinct from e.key_fact
        and r.pros is not distinct from e.pros
        and r.cons is not distinct from e.cons
        and r.editorial_note is not distinct from e.editorial_note)::integer
      as ist_gesamt,
    coalesce(
      (select concat_ws(' | ', r.tagline, r.description) from n4_row r),
      'FEHLT'
    ) as n4_zeittext
),

summary as (
  select *
  from fingerprint f
  cross join column_state c
  cross join constraint_state k
  cross join marker_state m
  cross join n4_state n
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
  select 60, 'n4_zeilen', n4_zeilen::text, '1',
    case when n4_zeilen = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'n4_published', n4_published::text, '1',
    case when n4_published = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 80, 'value_add_schema_vollstaendig',
    (vorhandene_spalten::text || '/8 Spalten, '
      || korrekt_typisierte_spalten::text || '/8 Typen, '
      || vorhandene_constraints::text || '/2 Constraints'),
    '8/8 Spalten, 8/8 Typen, 2/2 Constraints',
    case when vorhandene_spalten = 8 and korrekt_typisierte_spalten = 8
           and vorhandene_constraints = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 90, 'value_add_snapshot_v1', snapshot_zeilen::text, '10',
    case when snapshot_zeilen = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'value_add_payload_v1', payload_zeilen::text, '10',
    case when payload_zeilen = 10 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'payload_n4_befuellt', payload_n4_befuellt::text, '1',
    case when payload_n4_befuellt = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'n4_backup_fehlt_noch', coalesce(n4_backup, 'FEHLT'),
    'FEHLT vor Schritt 02',
    case when n4_backup is null then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'n4_ist_tagline', ist_tagline::text, '1',
    case when ist_tagline = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 140, 'n4_ist_description', ist_description::text, '1',
    case when ist_description = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'n4_ist_nicht_fuer', ist_nicht_fuer::text, '1',
    case when ist_nicht_fuer = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 160, 'n4_ist_key_fact', ist_key_fact::text, '1',
    case when ist_key_fact = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'n4_ist_pros', ist_pros::text, '1',
    case when ist_pros = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 180, 'n4_ist_cons', ist_cons::text, '1',
    case when ist_cons = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'n4_ist_editorial_note', ist_editorial_note::text, '1',
    case when ist_editorial_note = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 200, 'n4_vorzustand_vollstaendig', ist_gesamt::text, '1',
    case when ist_gesamt = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 210, 'n4_zeitwiderspruch_aktuell', n4_zeittext,
    'INFO: genau dieser Widerspruch wird in Schritt 04 aufgeloest', 'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
