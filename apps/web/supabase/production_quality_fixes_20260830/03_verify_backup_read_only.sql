-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 03 READ-ONLY PRUEFUNG DES BACKUPS
-- ============================================================================
-- Laeuft NACH 02_backup_quality_fixes.sql und VOR 04_apply_quality_fixes.sql.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein INSERT/UPDATE/DELETE/MERGE, kein
--   CREATE/ALTER/DROP/TRUNCATE, keine Rechtevergabe, kein DO-Block, keine
--   Transaktionssteuerung. Nichts an der Datenbank wird veraendert.
--   Die Woerter SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER,
--   USAGE und CREATE erscheinen ausserhalb von Kommentaren ausschliesslich als
--   Privilegnamen in values-Listen fuer has_table_privilege bzw.
--   has_schema_privilege. "PUBLIC" erscheint nur als Grantee-Bezeichner.
--
-- FAIL CLOSED
--   Beide Backup-Tabellen werden direkt per ::regclass referenziert. Fehlt
--   eine davon, bricht bereits die Planung mit "relation ... does not exist"
--   ab. Das ist der gewollte Ausgang.
--
-- GEPRUEFTE ROLLEN — und die bewusste Grenze
--   Hart geprueft werden PUBLIC, anon und authenticated, jeweils mit zwei
--   unabhaengigen Messungen: (a) direkte ACL-Eintraege ueber aclexplode und
--   (b) effektive Privilegien ueber has_table_privilege bzw.
--   has_schema_privilege, die Rollenmitgliedschaft und PUBLIC-Rechte mit
--   aufloesen. (a) allein waere fail-open, sobald ein Recht nur geerbt wird.
--
--   service_role erscheint ausschliesslich als INFO, nie als PASS. 02 revoked
--   service_role zwar, wenn die Rolle existiert, aber service_role ist auf
--   Supabase typischerweise BYPASSRLS; RLS allein ist gegen sie kein Schutz.
--
-- ERWARTETES ERGEBNIS: 23 Zeilen — 16 harte PASS-Zeilen (Sortierung 30 bis 180)
-- und 7 INFO-Zeilen (10, 20, 200 bis 240). Jede FAIL-Zeile ist ein Befund.
-- ============================================================================

with
backup_tabellen(bezeichnung, tabelle, quelle) as (
  select 'products'::text,
         'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass,
         'public.products'::regclass
  union all
  select 'lists'::text,
         'cbb_private_backup.quality_fixes_20260830_lists_v1'::regclass,
         'public.lists'::regclass
),

app_grantees(rolle, grantee_oid) as (
  select 'PUBLIC'::text, 0::oid
  union all
  select r.rolname::text, r.oid
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- ---------------------------------------------------------------------------
-- Der bekannte Vorzustand — dieselben Literale wie in 01, 02, 04, 05 und 06.
-- ---------------------------------------------------------------------------
b2_erwartet(slug, pre_persona, pre_main, pre_sub, pre_tags) as (
  values
    ('fingerabdruck-vorhaengeschloss-eseesmart'::text,
     'unknown'::text, 'sonstiges'::text, 'ungeordnet'::text,
     array['preis:unter50','preis:unter100']::text[]),
    ('flauschige-handschuhe-weihnachten',
     'unknown', 'sonstiges', 'ungeordnet',
     array['preis:unter50','preis:unter100']::text[]),
    ('pizza-socks-box-pepperoni',
     'unknown', 'sonstiges', 'ungeordnet',
     array['preis:unter20','preis:unter50','preis:unter100']::text[])
),
b5_preis_erwartet(slug) as (
  values ('divoom-pixoo-led-panel'::text)
),
b5_bilder_erwartet(slug, pre_image_url, pre_image_urls) as (
  values (
    'divoom-minitoo-retro-pc-lautsprecher-pixel'::text,
    'https://divoom.com/cdn/shop/files/minitoo-1.jpg'::text,
    array['https://divoom.com/cdn/shop/files/minitoo-1.jpg']::text[]
  )
),
d6_erwartet(slug, pre_name, pre_description, pre_note) as (
  values (
    'cream-noise-machine-baby-tragbar'::text,
    'Cream Noise Machine Baby Tragbar'::text,
    'Tragbare Cream Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.'::text,
    'Die tragbare Cream-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.'::text
  )
),
listen_erwartet(slug, pre_slugs) as (
  values (
    'verrueckte-amazon-gadgets'::text,
    array[
      'flipper-zero',
      'seek-thermal-compact-usbc',
      'arc-reaktor-mk1-schwebend',
      'plasmakugel-8-zoll-beruehlungsempfindlich',
      'ameisenfarm-acryl-set-natursand',
      'periodensystem-mit-echten-elementen-acryl',
      'hoverair-x1-pro-drohne',
      'prisma-brille-lazy-glasses',
      'bite-away-two-elektronischer-insektenstichheiler',
      'bitzee-disney-interaktives-digital-haustier',
      'schachroboter-mit-ki-roboterarm-sense-robot',
      'drehbare-kosmos-sternkarte-planeten',
      'led-leuchtbrille-aufladbar-party',
      'shashibo-formwechsel-box-magnetisch',
      'phonesoap-3-uv-desinfektion',
      'dji-osmo-pocket-4-kreativ-combo'
    ]::text[]
  ),
  (
    'witzige-geschenke-maenner',
    array[
      'faelnk-toilettengolf-set',
      'bug-a-salt-3-0-fliegenjager-salzgewehr',
      'toilettenbuerste-gag-geschenk-set-lustig',
      'kiayoo-wackelfigur-armaturenbrett-auto',
      'bbq-wuerstchenhalter-maennchen-3er-set',
      'brubaker-weinflaschenhalter-totenkopf',
      'snoop-dogg-kochbuch-from-crook-to-cook',
      'prisma-brille-lazy-glasses',
      'deadpool-auto-anhaenger-ornament',
      'stress-baelle-quetschball-set',
      'bierbrauset-pils-5-liter-fass',
      'bartesian-cocktailmaschine-mit-kapseln'
    ]::text[]
  ),
  (
    'geschenke-fuer-gamer',
    array[
      'street-fighter-arcade-machine',
      'dnd-starter-set-helden-der-grenzlande-deutsch',
      'mayflash-f300-arcade-joystick',
      'nintendo-classic-mini-snes',
      'mad-monkey-retro-spielekonsole',
      'gan-356me-speed-cube-3x3-magnetisch',
      'krimispiel-escape-room-detektivspiel-erwachsene',
      'ps5-horizontale-tasche-tragetasche',
      'kytok-controller-staender-4-etagen',
      'shashibo-formwechsel-box-magnetisch',
      'weiminli-switch-skull-case',
      'giiker-super-slide-puzzle',
      'dealkit-3d-labyrinth-wuerfel',
      'weiminli-switch-skull-case',
      'giiker-super-slide-puzzle',
      'dealkit-3d-labyrinth-wuerfel'
    ]::text[]
  )
),
alle_zielslugs(slug) as (
  select slug from b2_erwartet
  union all select slug from b5_preis_erwartet
  union all select slug from b5_bilder_erwartet
  union all select slug from d6_erwartet
),

-- ---------------------------------------------------------------------------
-- Zeilenzahl und exakte Zielmenge
-- ---------------------------------------------------------------------------
mengen as (
  select
    (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1)::integer
      as produkt_zeilen,
    (select count(*) from cbb_private_backup.quality_fixes_20260830_lists_v1)::integer
      as listen_zeilen,
    (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
      join alle_zielslugs z on z.slug = b.slug)::integer as produkt_slugtreffer,
    (select count(*) from cbb_private_backup.quality_fixes_20260830_lists_v1 b
      join listen_erwartet e on e.slug = b.slug)::integer as listen_slugtreffer
),

-- ---------------------------------------------------------------------------
-- Shape: die Backup-Tabellen tragen exakt die Spaltenmenge ihrer Quelltabelle.
-- 02 hat sie mit SELECT * angelegt; weicht die Menge ab, ist das Backup kein
-- vollstaendiges Abbild mehr und der Restore in 06 waere unvollstaendig.
-- ---------------------------------------------------------------------------
spalten as (
  select
    t.bezeichnung,
    (select array_agg(a.attname::text order by a.attname)
     from pg_attribute a
     where a.attrelid = t.tabelle and a.attnum > 0 and not a.attisdropped)
      as backup_spalten,
    (select array_agg(a.attname::text order by a.attname)
     from pg_attribute a
     where a.attrelid = t.quelle and a.attnum > 0 and not a.attisdropped)
      as quell_spalten
  from backup_tabellen t
),
spalten_summe as (
  select
    count(*) filter (where backup_spalten = quell_spalten)::integer as gleich,
    coalesce(sum(coalesce(array_length(backup_spalten, 1), 0)), 0)::integer
      as backup_spalten_gesamt
  from spalten
),

-- ---------------------------------------------------------------------------
-- Inhalt gegen den bekannten Vorzustand
-- ---------------------------------------------------------------------------
inhalt as (
  select
    (
      (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join b2_erwartet e on e.slug = b.slug
       where b.shop_persona is not distinct from e.pre_persona
         and b.shop_main_category is not distinct from e.pre_main
         and b.shop_sub_category is not distinct from e.pre_sub
         and b.shop_tags is not distinct from e.pre_tags)
      + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
          join b5_preis_erwartet e on e.slug = b.slug
         where b.price_cents is null)
      + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
          join b5_bilder_erwartet e on e.slug = b.slug
         where b.image_url is not distinct from e.pre_image_url
           and b.image_urls is not distinct from e.pre_image_urls)
      + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
          join d6_erwartet e on e.slug = b.slug
         where b.name is not distinct from e.pre_name
           and b.description is not distinct from e.pre_description
           and b.editorial_note is not distinct from e.pre_note)
    )::integer as produkt_vorzustand,
    (select count(*) from cbb_private_backup.quality_fixes_20260830_lists_v1 b
      join listen_erwartet e on e.slug = b.slug
     where b.product_slugs is not distinct from e.pre_slugs)::integer
      as listen_vorzustand
),

-- ---------------------------------------------------------------------------
-- Drift gegen die Quelltabellen — vollstaendiger Zeilenvergleich ueber
-- to_jsonb, also jede Spalte. FULL JOIN, damit auch eine fehlende Gegenseite
-- zaehlt. Der Join laeuft bewusst gegen die auf die Zielzeilen eingegrenzte
-- Menge, nicht gegen public.products insgesamt.
-- ---------------------------------------------------------------------------
ziel_produkte as (
  select p.* from public.products p join alle_zielslugs z on z.slug = p.slug
),
ziel_listen as (
  select l.* from public.lists l join listen_erwartet e on e.slug = l.slug
),
drift as (
  select
    (select count(*)
     from cbb_private_backup.quality_fixes_20260830_products_v1 b
     full join ziel_produkte p on p.id = b.id and p.slug = b.slug
     where b.id is null or p.id is null
        or to_jsonb(p) is distinct from to_jsonb(b))::integer as produkt_drift,
    (select count(*)
     from cbb_private_backup.quality_fixes_20260830_lists_v1 b
     full join ziel_listen l on l.id = b.id and l.slug = b.slug
     where b.id is null or l.id is null
        or to_jsonb(l) is distinct from to_jsonb(b))::integer as listen_drift
),

-- ---------------------------------------------------------------------------
-- Absicherung der Backup-Tabellen: RLS, Policies, Constraints
-- pk_id = 2 bedeutet: beide Tabellen haben genau einen Primaerschluessel und
-- der besteht exakt aus (id). Analog fuer UNIQUE auf (slug).
-- ---------------------------------------------------------------------------
absicherung_je as (
  select
    c.relrowsecurity as rls,
    (select count(*) from pg_policy pol where pol.polrelid = c.oid) as policies,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'p') as pk_anzahl,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'p'
        and (select array_agg(a.attname::text order by a.attname)
             from pg_attribute a
             where a.attrelid = con.conrelid
               and a.attnum = any(con.conkey)) = array['id']::text[]) as pk_auf_id,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'u') as unique_anzahl,
    (select count(*) from pg_constraint con
      where con.conrelid = c.oid and con.contype = 'u'
        and (select array_agg(a.attname::text order by a.attname)
             from pg_attribute a
             where a.attrelid = con.conrelid
               and a.attnum = any(con.conkey)) = array['slug']::text[]) as unique_auf_slug
  from backup_tabellen t
  join pg_class c on c.oid = t.tabelle
),
absicherung as (
  select
    count(*)::integer as tabellen,
    count(*) filter (where rls)::integer as rls_aktiv,
    coalesce(sum(policies), 0)::integer as policies,
    count(*) filter (where pk_anzahl = 1 and pk_auf_id = 1)::integer as pk_id,
    count(*) filter (where unique_anzahl = 1 and unique_auf_slug = 1)::integer
      as unique_slug
  from absicherung_je
),

-- ---------------------------------------------------------------------------
-- Harte Vorbedingung der Rechte-Pruefungen. Fehlt eine der Rollen, liefert der
-- Grantee-Join fuer sie still 0 Treffer. Ein Zaehler von 0 waere dann kein
-- Beleg fuer "keine Rechte", sondern nur einer fuer "keine Rolle".
-- ---------------------------------------------------------------------------
role_presence as (
  select count(*)::integer as app_rollen
  from pg_roles r
  where r.rolname in ('anon', 'authenticated')
),

-- Direkte ACL-Eintraege. Bewusst nicht ueber information_schema: dort fehlen
-- Default-ACLs (acl is null) und PUBLIC-Eintraege. grantee = 0 ist PUBLIC.
tabellen_acl as (
  select count(*)::integer as tabellen_direkt
  from backup_tabellen t
  join pg_class c on c.oid = t.tabelle
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  join app_grantees g on g.grantee_oid = acl.grantee
),
schema_acl as (
  select count(*)::integer as schema_direkt
  from pg_namespace n
  cross join lateral aclexplode(
    coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
  ) as acl
  join app_grantees g on g.grantee_oid = acl.grantee
  -- Das Schema wird ueber die Backup-Tabelle aufgeloest, damit auch dieser
  -- Zweig hart scheitert, wenn das Backup fehlt.
  where n.oid = (
    select c.relnamespace from pg_class c
    where c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass
  )
),

-- Effektive Privilegien. has_table_privilege und has_schema_privilege loesen
-- Rollenmitgliedschaft und PUBLIC-Rechte mit auf. Ein nur geerbtes Recht ist in
-- den direkten ACL-Zaehlern unsichtbar, hier aber sichtbar.
tabellen_effektiv as (
  select count(*)::integer as tabellen_effektiv_n
  from backup_tabellen t
  cross join pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid, t.tabelle::oid, p.priv::text)
),
schema_effektiv as (
  select count(*)::integer as schema_effektiv_n
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  join pg_class c
    on c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
),

-- ---------------------------------------------------------------------------
-- service_role — NUR INFO, nie PASS
-- ---------------------------------------------------------------------------
service_role_state as (
  select
    (select count(*) from pg_roles r where r.rolname = 'service_role')::integer
      as rolle_vorhanden,
    (select coalesce(bool_or(r.rolbypassrls), false)
     from pg_roles r where r.rolname = 'service_role') as bypassrls,
    (select coalesce(
       string_agg(distinct acl.privilege_type, ', ' order by acl.privilege_type),
       'keine')
     from backup_tabellen t
     join pg_class c on c.oid = t.tabelle
     cross join lateral aclexplode(
       coalesce(c.relacl, acldefault('r'::"char", c.relowner))
     ) as acl
     join pg_roles r on r.oid = acl.grantee and r.rolname = 'service_role'
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
       select c.relnamespace from pg_class c
       where c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass
     )
    ) as schema_acl,
    (select coalesce(string_agg(distinct p.priv, ', ' order by p.priv), 'keine')
     from backup_tabellen t
     cross join pg_roles r
     cross join (values
       ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
       ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
     ) as p(priv)
     where r.rolname = 'service_role'
       and has_table_privilege(r.oid, t.tabelle::oid, p.priv::text)
    ) as tabelle_effektiv,
    (select coalesce(string_agg(distinct p.priv, ', ' order by p.priv), 'keine')
     from pg_roles r
     cross join (values ('USAGE'), ('CREATE')) as p(priv)
     join pg_class c
       on c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass
     where r.rolname = 'service_role'
       and has_schema_privilege(r.oid, c.relnamespace::oid, p.priv::text)
    ) as schema_effektiv
),

-- Jede CTE oben liefert genau eine Zeile, summary damit ebenfalls.
summary as (
  select *
  from mengen
  cross join spalten_summe
  cross join inhalt
  cross join drift
  cross join absicherung
  cross join role_presence
  cross join tabellen_acl
  cross join schema_acl
  cross join tabellen_effektiv
  cross join schema_effektiv
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
  select 30, 'backup_produkt_zeilen', produkt_zeilen::text, '6',
    case when produkt_zeilen = 6 then 'PASS' else 'FAIL' end from summary
  union all
  select 40, 'backup_listen_zeilen', listen_zeilen::text, '3',
    case when listen_zeilen = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 50, 'backup_produkt_zielmenge',
    produkt_zeilen::text || ' Zeilen, davon erwartete Slugs '
      || produkt_slugtreffer::text,
    '6 Zeilen, davon erwartete Slugs 6',
    case when produkt_zeilen = 6 and produkt_slugtreffer = 6
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 60, 'backup_listen_zielmenge',
    listen_zeilen::text || ' Zeilen, davon erwartete Slugs '
      || listen_slugtreffer::text,
    '3 Zeilen, davon erwartete Slugs 3',
    case when listen_zeilen = 3 and listen_slugtreffer = 3
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 70, 'backup_spaltenmenge_wie_quelle',
    gleich::text || '/2 Tabellen spaltengleich',
    '2/2 Tabellen spaltengleich',
    case when gleich = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 80, 'backup_spalten_nicht_leer', backup_spalten_gesamt::text, '> 0',
    case when backup_spalten_gesamt > 0 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 90, 'backup_produkt_inhalt_vorzustand', produkt_vorzustand::text, '6',
    case when produkt_vorzustand = 6 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'backup_listen_inhalt_vorzustand', listen_vorzustand::text, '3',
    case when listen_vorzustand = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'backup_produkt_drift_gegen_products', produkt_drift::text, '0',
    case when produkt_drift = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'backup_listen_drift_gegen_lists', listen_drift::text, '0',
    case when listen_drift = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'backup_rls',
    rls_aktiv::text || '/' || tabellen::text || ' Tabellen mit RLS',
    '2/2 Tabellen mit RLS',
    case when tabellen = 2 and rls_aktiv = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 140, 'backup_policies', policies::text, '0',
    case when policies = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'backup_constraints',
    'PK(id) ' || pk_id::text || '/2 | UNIQUE(slug) ' || unique_slug::text || '/2',
    'PK(id) 2/2 | UNIQUE(slug) 2/2',
    case when pk_id = 2 and unique_slug = 2 then 'PASS' else 'FAIL' end
  from summary
  union all
  select 160, 'app_rollen_vorhanden', app_rollen::text || '/2', '2/2',
    case when app_rollen = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'backup_tabellenrechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2'
      || ' | direkte ACL ' || tabellen_direkt::text
      || ' | effektiv ' || tabellen_effektiv_n::text,
    'Rollen 2/2 | direkte ACL 0 | effektiv 0',
    case when app_rollen = 2
           and tabellen_direkt = 0
           and tabellen_effektiv_n = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 180, 'backup_schemarechte_app_rollen',
    'Rollen ' || app_rollen::text || '/2'
      || ' | direkte ACL ' || schema_direkt::text
      || ' | effektiv ' || schema_effektiv_n::text,
    'Rollen 2/2 | direkte ACL 0 | effektiv 0',
    case when app_rollen = 2
           and schema_direkt = 0
           and schema_effektiv_n = 0
      then 'PASS' else 'FAIL' end
  from summary
  union all
  select 200, 'service_role_vorhanden',
    case when rolle_vorhanden = 1 then 'ja' else 'nein' end
      || ' | bypassrls ' || bypassrls::text,
    'INFO: keine Zusage, service_role ist typischerweise BYPASSRLS',
    'INFO'
  from summary
  union all
  select 210, 'service_role_tabellen_acl',
    case when rolle_vorhanden = 1 then tabelle_acl else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf beiden Backup-Tabellen',
    'INFO'
  from summary
  union all
  select 220, 'service_role_schema_acl',
    case when rolle_vorhanden = 1 then schema_acl else 'Rolle nicht vorhanden' end,
    'INFO: direkte ACL-Eintraege auf cbb_private_backup',
    'INFO'
  from summary
  union all
  select 230, 'service_role_tabellenrechte_effektiv',
    case when rolle_vorhanden = 1 then tabelle_effektiv else 'Rolle nicht vorhanden' end,
    'INFO: effektive Tabellenrechte inkl. Mitgliedschaft und PUBLIC',
    'INFO'
  from summary
  union all
  select 240, 'service_role_schemarechte_effektiv',
    case when rolle_vorhanden = 1 then schema_effektiv else 'Rolle nicht vorhanden' end,
    'INFO: effektive Schemarechte inkl. Mitgliedschaft und PUBLIC',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
