-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 03 READ-ONLY PRUEFUNG DES PRIVATEN BACKUPS
-- ============================================================================
-- Laeuft NACH 02_backup_n4_content.sql und VOR 04_correct_n4_content.sql.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein INSERT/UPDATE/DELETE/MERGE, kein
--   CREATE/ALTER/DROP/TRUNCATE, keine Rechtevergabe, kein DO-Block, keine
--   Transaktionssteuerung. Nichts an der Datenbank wird veraendert.
--   Das einzige ausfuehrbare Semikolon steht am Dateiende. In den Text-
--   Literalen dieser Datei kommt kein Semikolon vor (Trenner ist ' | ').
--   Die Woerter SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER,
--   USAGE und CREATE erscheinen ausserhalb von Kommentaren ausschliesslich als
--   Privilegnamen in values-Listen fuer has_table_privilege bzw.
--   has_schema_privilege. "PUBLIC" erscheint nur als Grantee-Bezeichner.
--
-- FAIL CLOSED
--   cbb_private_backup.n4_content_pre_fix_v1 wird direkt per ::regclass
--   referenziert. Fehlt die Tabelle, bricht bereits die Planung mit
--   "relation ... does not exist" ab. Das ist der gewollte Ausgang.
--
-- GEPRUEFTE ROLLEN — und die bewusste Grenze
--   Hart geprueft werden PUBLIC, anon und authenticated, jeweils mit zwei
--   unabhaengigen Messungen: (a) direkte ACL-Eintraege ueber aclexplode und
--   (b) effektive Privilegien ueber has_table_privilege bzw.
--   has_schema_privilege, die Rollenmitgliedschaft und PUBLIC-Rechte mit
--   aufloesen. (a) allein waere fail-open, sobald ein Recht nur geerbt wird.
--
--   service_role erscheint ausschliesslich als INFO, nie als PASS — dasselbe
--   Muster wie in 05b_verify_payload_security_read_only.sql des Value-Add-
--   Pakets. 02 revoked service_role zwar, wenn die Rolle existiert, aber
--   service_role ist auf Supabase typischerweise BYPASSRLS; RLS allein ist
--   gegen sie kein Schutz. Wer eine Zusage ueber service_role braucht, braucht
--   dafuer einen eigenen, getrennt freigegebenen Vorgang.
--
-- ERWARTETES ERGEBNIS: 17 Zeilen — 10 harte PASS-Zeilen (Sortierung 30 bis 120)
-- und 7 INFO-Zeilen (10, 20, 200 bis 240). Jede FAIL-Zeile ist ein Befund.
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
-- Zeilenzahl und exakte Zielmenge (Pruefungen 1 und 3)
-- ---------------------------------------------------------------------------
backup_rows as (
  select
    count(*)::integer as zeilen,
    count(*) filter (
      where b.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    )::integer as n4_zeilen
  from cbb_private_backup.n4_content_pre_fix_v1 b
),

-- ---------------------------------------------------------------------------
-- Shape: exakt 10 Spalten mit exakt diesen Namen (Pruefung 2)
-- spalten_gesamt = 10 und spalten_erwartet = 10 erzwingen zusammen die exakte
-- Namensmenge. Die Liste ist die Spaltenmenge aus 02 und deckt sich mit den
-- Feldern, die 04 aendert, plus id, slug und updated_at.
-- ---------------------------------------------------------------------------
backup_shape as (
  select
    count(*)::integer as spalten_gesamt,
    count(*) filter (
      where a.attname in (
        'id', 'slug', 'updated_at', 'tagline', 'description',
        'nicht_fuer', 'key_fact', 'pros', 'cons', 'editorial_note'
      )
    )::integer as spalten_erwartet
  from pg_attribute a
  where a.attrelid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
    and a.attnum > 0
    and not a.attisdropped
),

-- ---------------------------------------------------------------------------
-- Drift gegen public.products (Pruefung 4)
-- FULL JOIN, damit auch eine fehlende Gegenseite als Abweichung zaehlt:
-- Backup-Zeile ohne Produktzeile ebenso wie Produktzeile ohne Backup-Zeile.
-- Der Join laeuft bewusst gegen die auf die N4-Zeile eingegrenzte Menge
-- (n4_product), nicht gegen public.products insgesamt: sonst zaehlte jede der
-- 375 Nichtzielzeilen als "Backup-Zeile fehlt" und die Pruefung waere sinnlos.
-- ---------------------------------------------------------------------------
n4_product as (
  select *
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
),
backup_drift as (
  select count(*)::integer as abweichungen
  from cbb_private_backup.n4_content_pre_fix_v1 b
  full join n4_product p on p.id = b.id and p.slug = b.slug
  where b.id is null
     or p.id is null
     or p.updated_at is distinct from b.updated_at
     or p.tagline is distinct from b.tagline
     or p.description is distinct from b.description
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.editorial_note is distinct from b.editorial_note
),

-- ---------------------------------------------------------------------------
-- Absicherung der Backup-Tabelle: RLS, Policies, Constraints
-- (Pruefungen 5, 6, 7)
-- pk_constraints = 1 UND pk_id_constraints = 1 bedeuten zusammen: es gibt genau
-- einen Primaerschluessel und der besteht exakt aus (id). Analog fuer UNIQUE
-- auf (slug).
-- ---------------------------------------------------------------------------
backup_guard as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid)::integer
      as policies,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'p')::integer
      as pk_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'p'
        and (
          select array_agg(a.attname::text order by a.attname)
          from pg_attribute a
          where a.attrelid = con.conrelid
            and a.attnum = any(con.conkey)
        ) = array['id']::text[])::integer as pk_id_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'u')::integer
      as unique_constraints,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid
        and con.contype = 'u'
        and (
          select array_agg(a.attname::text order by a.attname)
          from pg_attribute a
          where a.attrelid = con.conrelid
            and a.attnum = any(con.conkey)
        ) = array['slug']::text[])::integer as unique_slug_constraints
  from pg_class c
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
),

-- ---------------------------------------------------------------------------
-- Harte Vorbedingung der Rechte-Pruefungen (Pruefung 8)
-- Fehlt eine der Rollen, liefert der Grantee-Join fuer sie still 0 Treffer.
-- Ein Zaehler von 0 waere dann kein Beleg fuer "keine Rechte", sondern nur
-- einer fuer "keine Rolle". Deshalb eigene harte Zeile und zusaetzliche
-- Bedingung in den Pruefungen 9 und 10.
-- ---------------------------------------------------------------------------
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Direkte ACL-Eintraege (Teil a der Pruefungen 9 und 10)
-- Bewusst nicht ueber information_schema: dort fehlen Default-ACLs
-- (acl is null) und PUBLIC-Eintraege.
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
  -- Das Schema wird ueber die Backup-Tabelle aufgeloest, damit auch dieser
  -- Zweig hart scheitert, wenn das Backup fehlt.
  where n.oid = (
    select c.relnamespace
    from pg_class c
    where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
  )
),

-- ---------------------------------------------------------------------------
-- Effektive Privilegien von anon/authenticated (Teil b der Pruefungen 9, 10)
-- has_table_privilege und has_schema_privilege loesen Rollenmitgliedschaft und
-- PUBLIC-Rechte mit auf. Ein nur geerbtes Recht ist in den direkten ACL-
-- Zaehlern unsichtbar, hier aber sichtbar.
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

-- Jede CTE oben liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from backup_rows
  cross join backup_shape
  cross join backup_drift
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
  -- 1
  select 30, 'backup_zeilen', zeilen::text, '1',
    case when zeilen = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 2
  select 40, 'backup_spalten',
    spalten_gesamt::text || ' gesamt, ' || spalten_erwartet::text
      || ' erwartete Namen',
    '10 gesamt, 10 erwartete Namen',
    case when spalten_gesamt = 10 and spalten_erwartet = 10
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 3
  select 50, 'backup_zielmenge',
    zeilen::text || ' Zeilen, davon N4 ' || n4_zeilen::text,
    '1 Zeilen, davon N4 1',
    case when zeilen = 1 and n4_zeilen = 1 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 4
  select 60, 'backup_gegen_products_drift', abweichungen::text, '0',
    case when abweichungen = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 5
  select 70, 'backup_rls', rls::text, 'true',
    case when rls is true then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 6
  select 80, 'backup_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 7
  select 90, 'backup_constraints',
    'PK ' || pk_constraints::text || ', davon PK(id) ' || pk_id_constraints::text
      || ' | UNIQUE ' || unique_constraints::text
      || ', davon UNIQUE(slug) ' || unique_slug_constraints::text,
    'PK 1, davon PK(id) 1 | UNIQUE 1, davon UNIQUE(slug) 1',
    case when pk_constraints = 1 and pk_id_constraints = 1
           and unique_constraints = 1 and unique_slug_constraints = 1
      then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 8
  select 100, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  -- 9
  select 110, 'backup_tabellenrechte_app_rollen',
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
  -- 10
  select 120, 'backup_schemarechte_app_rollen',
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
  -- INFO A
  select 200, 'service_role_vorhanden',
    case when rolle_vorhanden = 1 then 'ja' else 'nein' end
      || ' | bypassrls ' || bypassrls::text,
    'INFO: keine Zusage, service_role ist typischerweise BYPASSRLS',
    'INFO'
  from summary
  union all
  -- INFO B
  select 210, 'service_role_tabellen_acl',
    case when rolle_vorhanden = 1 then tabelle_acl
      else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf n4_content_pre_fix_v1',
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
