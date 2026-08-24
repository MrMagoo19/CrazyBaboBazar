-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 05 READ-ONLY NACHPRUEFUNG
-- ============================================================================
-- Laeuft NACH 04_correct_n4_content.sql.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein INSERT/UPDATE/DELETE/MERGE, kein
--   CREATE/ALTER/DROP/TRUNCATE, keine Rechtevergabe, kein DO-Block, keine
--   Transaktionssteuerung. Nichts an der Datenbank wird veraendert.
--   Anders als 03 enthaelt diese Datei Inhaltstexte als Literale; in einigen
--   davon kommt ein Semikolon vor (z. B. im key_fact-Zieltext). Ausfuehrbar ist
--   trotzdem nur ein einziges Statement — das abschliessende Semikolon am
--   Dateiende. Semikolons innerhalb von Text-Literalen trennen kein Statement.
--   Die Woerter SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER,
--   USAGE und CREATE erscheinen ausserhalb von Kommentaren ausschliesslich als
--   Privilegnamen in values-Listen fuer has_table_privilege bzw.
--   has_schema_privilege.
--
-- FAIL CLOSED
--   cbb_private_backup.n4_content_pre_fix_v1 und
--   cbb_private_backup.value_add_payload_v1 werden direkt referenziert. Fehlt
--   eine der beiden, bricht bereits die Planung ab.
--
-- TRENNUNG PASS/FAIL VS. INFO
--   Sortierung 30 bis 200: harte Pruefungen, Status ist PASS oder FAIL.
--   Sortierung 10, 20 und 210 bis 260: reine INFO-Zeilen ohne jede Zusage.
--   service_role wird nur als INFO ausgegeben (Begruendung wie in 03).
--
-- ERWARTETES ERGEBNIS: 26 Zeilen — 18 harte PASS-Zeilen und 8 INFO-Zeilen.
-- Jede FAIL-Zeile ist ein Befund und Anlass fuer 06_restore_n4_content.sql.
-- ============================================================================

with
app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Der SOLL-Zustand nach der Korrektur.
-- ---------------------------------------------------------------------------
n4_target(
  tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
) as (
  values (
    '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm'::text,
    'Der Ariceck N4 ist ein 1,5-Liter-Pflanzenmilchbereiter mit Programmen für Getreide, Nüsse und Bohnen. Das Gerät mixt und erhitzt die Zutaten; ein Reinigungsprogramm unterstützt anschließend beim Saubermachen. Für Menschen, die Hafer-, Mandel- oder Sojamilch selbst zubereiten und die Zutaten kontrollieren wollen.'::text,
    'Wer nur selten Pflanzenmilch selbst zubereitet oder nach dem Programm keinerlei manuelle Nachreinigung erwartet.'::text,
    '1,5-Liter-Behälter, 800-W-Motor und Programme für Getreide, Nüsse und Bohnen; das Reinigungsprogramm unterstützt, ersetzt die manuelle Nachreinigung aber nicht immer.'::text,
    array[
      'Programme für Getreide, Nüsse und Bohnen',
      '1,5 Liter Fassungsvermögen',
      '800-W-Motor',
      'Reinigungsprogramm unterstützt beim Saubermachen'
    ]::text[],
    array[
      'Die Laufzeit hängt vom gewählten Programm ab',
      'Manuelle Nachreinigung kann weiterhin nötig sein'
    ]::text[],
    'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.'::text
  )
),

-- ---------------------------------------------------------------------------
-- Der Vorzustand, der im privaten Backup liegen MUSS. Identisch mit dem
-- Literalblock in 04 und mit den Quellen import_products_batch13.sql,
-- expand_descriptions_batch6.sql und production_value_add/04_backfill_value_add.sql.
-- ---------------------------------------------------------------------------
n4_pre(
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

n4_state as (
  select
    (select count(*) from n4_row)::integer as n4_zeilen,
    (select count(*) from n4_row where is_published is true)::integer
      as n4_published,
    (select count(*) from n4_row r, n4_target t
      where r.tagline is not distinct from t.tagline)::integer as soll_tagline,
    (select count(*) from n4_row r, n4_target t
      where r.description is not distinct from t.description)::integer
      as soll_description,
    (select count(*) from n4_row r, n4_target t
      where r.nicht_fuer is not distinct from t.nicht_fuer)::integer
      as soll_nicht_fuer,
    (select count(*) from n4_row r, n4_target t
      where r.key_fact is not distinct from t.key_fact)::integer as soll_key_fact,
    (select count(*) from n4_row r, n4_target t
      where r.pros is not distinct from t.pros)::integer as soll_pros,
    (select count(*) from n4_row r, n4_target t
      where r.cons is not distinct from t.cons)::integer as soll_cons,
    (select count(*) from n4_row r, n4_target t
      where r.editorial_note is not distinct from t.editorial_note)::integer
      as soll_editorial_note,
    (select count(*) from n4_row r, n4_target t
      where r.tagline is not distinct from t.tagline
        and r.description is not distinct from t.description
        and r.nicht_fuer is not distinct from t.nicht_fuer
        and r.key_fact is not distinct from t.key_fact
        and r.pros is not distinct from t.pros
        and r.cons is not distinct from t.cons
        and r.editorial_note is not distinct from t.editorial_note)::integer
      as soll_gesamt,
    coalesce(
      (select concat_ws(' | ', r.tagline, r.description) from n4_row r),
      'FEHLT'
    ) as n4_zeittext
),

-- ---------------------------------------------------------------------------
-- Backup: genau eine Zeile, exakt der Vorzustand, unangetastet.
-- ---------------------------------------------------------------------------
backup_state as (
  select
    (select count(*) from cbb_private_backup.n4_content_pre_fix_v1)::integer
      as backup_zeilen,
    (select count(*)
       from cbb_private_backup.n4_content_pre_fix_v1 b, n4_pre e
      where b.slug = 'n4-nussmilchbereiter-pflanzenmilch'
        and b.tagline is not distinct from e.tagline
        and b.description is not distinct from e.description
        and b.nicht_fuer is not distinct from e.nicht_fuer
        and b.key_fact is not distinct from e.key_fact
        and b.pros is not distinct from e.pros
        and b.cons is not distinct from e.cons
        and b.editorial_note is not distinct from e.editorial_note)::integer
      as backup_unveraendert,
    (select count(*)
       from public.products p
       join cbb_private_backup.n4_content_pre_fix_v1 b on b.id = p.id
      where p.updated_at > b.updated_at)::integer as lastmod_neu
),

-- ---------------------------------------------------------------------------
-- Die vier Value-Add-Felder, die 04 NICHT anfasst, muessen weiterhin exakt der
-- Audit-Payload entsprechen. Die uebrigen neun Pilotzeilen komplett.
-- ---------------------------------------------------------------------------
payload_state as (
  select
    (select count(*)
       from public.products p
       join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug
      where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
        and p.fuer_wen is not distinct from v.fuer_wen
        and p.alternative_slug is not distinct from v.alternative_slug
        and p.alternative_reason is not distinct from v.alternative_reason
        and p.alternative_kind is not distinct from v.alternative_kind)::integer
      as n4_unveraenderte_felder,
    (select count(*)
       from cbb_private_backup.value_add_payload_v1 v
      where v.slug <> 'n4-nussmilchbereiter-pflanzenmilch')::integer
      as uebrige_pilotzeilen,
    (select count(*)
       from cbb_private_backup.value_add_payload_v1 v
       left join public.products p on p.slug = v.slug
      where v.slug <> 'n4-nussmilchbereiter-pflanzenmilch'
        and (
          p.slug is null
          or p.fuer_wen is distinct from v.fuer_wen
          or p.nicht_fuer is distinct from v.nicht_fuer
          or p.key_fact is distinct from v.key_fact
          or p.pros is distinct from v.pros
          or p.cons is distinct from v.cons
          or p.alternative_slug is distinct from v.alternative_slug
          or p.alternative_reason is distinct from v.alternative_reason
          or p.alternative_kind is distinct from v.alternative_kind
          or p.editorial_note is distinct from v.editorial_note
        ))::integer as uebrige_pilotzeilen_drift
),

-- ---------------------------------------------------------------------------
-- Absicherung des Backups (RLS, Policies, Rechte) — dieselbe Methodik wie 03.
-- ---------------------------------------------------------------------------
backup_guard as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid)::integer
      as policies
  from pg_class c
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
),
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),
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
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
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
    where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
  )
),
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
          'cbb_private_backup.n4_content_pre_fix_v1'::regclass::oid,
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
    on c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
),
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
     where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
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
       where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
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
             'cbb_private_backup.n4_content_pre_fix_v1'::regclass::oid,
             p.priv::text)
    ) as tabelle_effektiv,
    (select coalesce(string_agg(p.priv, ', ' order by p.priv), 'keine')
     from pg_roles r
     cross join (values ('USAGE'), ('CREATE')) as p(priv)
     join pg_class c
       on c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
     where r.rolname = 'service_role'
       and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
    ) as schema_effektiv,
    (select coalesce(bool_or(r.rolbypassrls), false)
     from pg_roles r where r.rolname = 'service_role') as bypassrls
),

summary as (
  select *
  from n4_state
  cross join backup_state
  cross join payload_state
  cross join backup_guard
  cross join role_presence
  cross join table_privileges
  cross join schema_privileges
  cross join table_privileges_effective
  cross join schema_privileges_effective
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
  select 30, 'n4_zeilen_published',
    n4_zeilen::text || '/' || n4_published::text, '1/1',
    case when n4_zeilen = 1 and n4_published = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 40, 'n4_soll_tagline', soll_tagline::text, '1',
    case when soll_tagline = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 50, 'n4_soll_description', soll_description::text, '1',
    case when soll_description = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 60, 'n4_soll_nicht_fuer', soll_nicht_fuer::text, '1',
    case when soll_nicht_fuer = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'n4_soll_key_fact', soll_key_fact::text, '1',
    case when soll_key_fact = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 80, 'n4_soll_pros', soll_pros::text, '1',
    case when soll_pros = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 90, 'n4_soll_cons', soll_cons::text, '1',
    case when soll_cons = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'n4_soll_editorial_note', soll_editorial_note::text, '1',
    case when soll_editorial_note = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'n4_zieltext_vollstaendig', soll_gesamt::text, '1',
    case when soll_gesamt = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'backup_unveraendert',
    backup_zeilen::text || ' Zeilen, ' || backup_unveraendert::text
      || ' exakt im Vorzustand',
    '1 Zeilen, 1 exakt im Vorzustand',
    case when backup_zeilen = 1 and backup_unveraendert = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 130, 'n4_unveraenderte_felder_gegen_payload',
    n4_unveraenderte_felder::text, '1',
    case when n4_unveraenderte_felder = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 140, 'uebrige_neun_pilotzeilen',
    uebrige_pilotzeilen::text || ' Zeilen, '
      || uebrige_pilotzeilen_drift::text || ' Abweichungen',
    '9 Zeilen, 0 Abweichungen',
    case when uebrige_pilotzeilen = 9 and uebrige_pilotzeilen_drift = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 150, 'backup_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end from summary
  union all
  select 160, 'backup_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 180, 'backup_tabellenrechte_app_rollen',
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
  select 190, 'backup_schemarechte_app_rollen',
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
  select 200, 'n4_lastmod_neuer_als_backup', lastmod_neu::text, '1',
    case when lastmod_neu = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 210, 'n4_text_aktuell', n4_zeittext,
    'INFO: keine konkrete Laufzeit- und keine Amortisationszusage mehr', 'INFO'
  from summary
  union all
  select 220, 'service_role_vorhanden',
    case when rolle_vorhanden = 1 then 'ja' else 'nein' end
      || ' | bypassrls ' || bypassrls::text,
    'INFO: keine Zusage, service_role ist typischerweise BYPASSRLS', 'INFO'
  from summary
  union all
  select 230, 'service_role_tabellen_acl',
    case when rolle_vorhanden = 1 then tabelle_acl
      else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf n4_content_pre_fix_v1', 'INFO'
  from summary
  union all
  select 240, 'service_role_schema_acl',
    case when rolle_vorhanden = 1 then schema_acl
      else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf cbb_private_backup', 'INFO'
  from summary
  union all
  select 250, 'service_role_tabellenrechte_effektiv',
    case when rolle_vorhanden = 1 then tabelle_effektiv
      else 'Rolle nicht vorhanden' end,
    'INFO: effektive Tabellenrechte inkl. Mitgliedschaft und PUBLIC', 'INFO'
  from summary
  union all
  select 260, 'service_role_schemarechte_effektiv',
    case when rolle_vorhanden = 1 then schema_effektiv
      else 'Rolle nicht vorhanden' end,
    'INFO: effektive Schemarechte inkl. Mitgliedschaft und PUBLIC', 'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
