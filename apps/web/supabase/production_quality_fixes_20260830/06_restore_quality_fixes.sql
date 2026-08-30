-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 06 RESTORE (SCHREIBEND, ROLLBACK)
-- ============================================================================
-- Nur mit neuer ausdruecklicher Benutzerfreigabe ausfuehren.
-- Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu
--
-- Stellt exakt die in 02 gesicherten Felder der sechs Produktzeilen und der
-- drei Listenzeilen wieder her — einschliesslich des historischen updated_at
-- der Produkte. Danach ist der Stand vor der Korrektur wiederhergestellt,
-- inklusive der alten lastmod-Werte fuer die Sitemap. public.lists hat keine
-- Spalte updated_at.
--
-- Das Backup bleibt als Audit-Artefakt bestehen. Diese Datei loescht es NICHT.
-- Sie ist damit wiederholbar: steht bereits alles wieder im Vorzustand, ist
-- der Lauf ein No-Op.
--
-- DAS BACKUP IST HIER DIE DATENQUELLE — ALSO WIRD ES GEPRUEFT, NICHT GEGLAUBT
--   Ein Restore schreibt Backup-Inhalt nach public.products und public.lists.
--   Ein manipuliertes Backup wuerde dabei ungeprueft zu Seiteninhalt. Deshalb
--   gilt vor jedem Schreibvorgang:
--     1. Der Backup-Inhalt muss exakt dem bekannten Vorzustand entsprechen —
--        denselben Literalen wie in 01 bis 05. Weicht auch nur ein Feld ab,
--        wird nichts geschrieben.
--     2. Das Backup muss weiterhin ein privates Artefakt sein: RLS aktiv,
--        0 Policies, und fuer PUBLIC/anon/authenticated weder direkte
--        ACL-Eintraege noch effektive Rechte auf Tabellen oder Schema.
--        Effektiv heisst: has_table_privilege/has_schema_privilege, also
--        inklusive Rollenmitgliedschaft und geerbter PUBLIC-Rechte — ein nur
--        geerbtes Recht ist in den direkten ACLs unsichtbar. Existiert
--        service_role, gilt dieselbe Null-Forderung fuer sie.
--     3. Erst sperren, dann Backup- und Zustandspruefung NACH dem Lock
--        wiederholen, erst danach UPDATE.
--   Anders als in 03/05, wo service_role nur als INFO-Zeile berichtet wird,
--   ist sie hier eine harte Abbruchbedingung: 03/05 berichten, diese Datei
--   schreibt.
--
-- ZUM TRIGGER products_set_updated_at:
--   Der Trigger ueberschreibt updated_at nur, wenn der Aufrufer die Spalte
--   NICHT selbst mitschreibt. Hier wird sie ausdruecklich mitgeschrieben, der
--   historische Wert bleibt also stehen. Sollte in einem kaputten Zwischenstand
--   products.updated_at zufaellig schon dem Backup-Wert entsprechen, waehrend
--   der Inhalt abweicht, greift der Trigger doch und setzt now(). Genau das
--   faengt die Gleichheitspruefung am Ende ab: die Transaktion bricht dann ab,
--   statt einen falschen Zeitstempel zu hinterlassen.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung, Zielzeilen, Backup-Existenz und Backup-Sicherheit.
-- ---------------------------------------------------------------------------
do $$
declare
  product_rows bigint;
  backup_produkt_zeilen integer;
  backup_listen_zeilen integer;
  paare integer;
  backup_nsp oid;
  app_rollen integer;
  tabelle_oid oid;
  rls_aktiv boolean;
  policies integer;
  direkt_tabelle integer;
  direkt_schema integer;
  effektiv_tabelle integer;
  effektiv_schema integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'QF-Restore abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.lists') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'QF-Restore abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'QF-Restore abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  if to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1') is null
     or to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1') is null then
    raise exception 'QF-Restore abgebrochen: privates Backup fehlt.';
  end if;

  select count(*) into backup_produkt_zeilen
  from cbb_private_backup.quality_fixes_20260830_products_v1;
  select count(*) into backup_listen_zeilen
  from cbb_private_backup.quality_fixes_20260830_lists_v1;
  if backup_produkt_zeilen <> 6 or backup_listen_zeilen <> 3 then
    raise exception 'QF-Restore abgebrochen: Backup hat %/6 Produkt- und %/3 Listenzeilen.',
      backup_produkt_zeilen, backup_listen_zeilen;
  end if;

  -- Backup und Zielzeilen muessen dieselbe Identitaet haben.
  select count(*) into paare
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join public.products p on p.id = b.id and p.slug = b.slug;
  if paare <> 6 then
    raise exception 'QF-Restore abgebrochen: Produkt-Backup passt zu %/6 Produktzeilen.', paare;
  end if;

  select count(*) into paare
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  join public.lists l on l.id = b.id and l.slug = b.slug;
  if paare <> 3 then
    raise exception 'QF-Restore abgebrochen: Listen-Backup passt zu %/3 Listenzeilen.', paare;
  end if;

  -- -------------------------------------------------------------------------
  -- Harte Vorbedingung der Rechtepruefung: fehlt eine der App-Rollen, liefern
  -- die Zaehler still 0 — das waere kein Beleg fuer "keine Rechte", sondern
  -- nur einer fuer "keine Rolle". Ein schreibender Sicherheitsguard darf sich
  -- darauf nicht stuetzen.
  -- -------------------------------------------------------------------------
  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 2 then
    raise exception 'QF-Restore abgebrochen: %/2 App-Rollen (anon, authenticated) vorhanden — Rechtepruefung nicht aussagekraeftig.',
      app_rollen;
  end if;

  select c.relnamespace into backup_nsp
  from pg_class c
  where c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass;

  -- (a) direkte ACL-Eintraege am Schema. Bewusst nicht ueber
  -- information_schema: dort fehlen Default-ACLs (acl is null) und
  -- PUBLIC-Eintraege. grantee = 0 ist PUBLIC.
  select count(*) into direkt_schema
  from pg_namespace n
  cross join lateral aclexplode(
    coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where n.oid = backup_nsp
    and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

  -- (b) effektive Schemarechte. has_schema_privilege loest
  -- Rollenmitgliedschaft und PUBLIC-Rechte mit auf.
  select count(*) into effektiv_schema
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  where r.rolname in ('anon', 'authenticated', 'service_role')
    and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

  if direkt_schema <> 0 or effektiv_schema <> 0 then
    raise exception 'QF-Restore abgebrochen: Schema cbb_private_backup unsicher (direkt %, effektiv %).',
      direkt_schema, effektiv_schema;
  end if;

  for tabelle_oid in
    select unnest(array[
      'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass::oid,
      'cbb_private_backup.quality_fixes_20260830_lists_v1'::regclass::oid
    ])
  loop
    select c.relrowsecurity,
           (select count(*) from pg_policy pol where pol.polrelid = c.oid)
    into rls_aktiv, policies
    from pg_class c where c.oid = tabelle_oid;
    if rls_aktiv is not true or policies <> 0 then
      raise exception 'QF-Restore abgebrochen: Backup-Tabelle % unsicher (RLS=%, Policies=%).',
        tabelle_oid::regclass, rls_aktiv, policies;
    end if;

    select count(*) into direkt_tabelle
    from pg_class c
    cross join lateral aclexplode(
      coalesce(c.relacl, acldefault('r'::"char", c.relowner))
    ) as acl
    left join pg_roles r on r.oid = acl.grantee
    where c.oid = tabelle_oid
      and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

    select count(*) into effektiv_tabelle
    from pg_roles r
    cross join (values
      ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
      ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
    ) as p(priv)
    where r.rolname in ('anon', 'authenticated', 'service_role')
      and has_table_privilege(r.oid, tabelle_oid, p.priv::text);

    if direkt_tabelle <> 0 or effektiv_tabelle <> 0 then
      raise exception 'QF-Restore abgebrochen: Backup-Tabelle % unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt %, effektiv %).',
        tabelle_oid::regclass, direkt_tabelle, effektiv_tabelle;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Der bekannte Vorzustand und der Zielzustand — dieselben Literale wie in 01
-- bis 05.
--
-- Der Vorzustand ist hier der Pruefmassstab fuer den Backup-INHALT: geprueft
-- wird, dass die Datenquelle des Schreibvorgangs unveraendert ist.
-- Der Zielzustand sagt, ob ueberhaupt etwas zurueckzurollen ist.
-- ---------------------------------------------------------------------------
create temporary table cbb_qf_b2 (
  slug text primary key,
  pre_persona text not null,
  pre_main text not null,
  pre_sub text not null,
  pre_tags text[] not null,
  ziel_persona text not null,
  ziel_main text not null,
  ziel_sub text not null,
  ziel_tags text[] not null
) on commit drop;

insert into cbb_qf_b2 values
  ('fingerabdruck-vorhaengeschloss-eseesmart',
   'unknown', 'sonstiges', 'ungeordnet',
   array['preis:unter50','preis:unter100'],
   'babo', 'tech', 'gadgets',
   array['babo:tech','preis:unter50','preis:unter100']),
  ('flauschige-handschuhe-weihnachten',
   'unknown', 'sonstiges', 'ungeordnet',
   array['preis:unter50','preis:unter100'],
   'queen', 'lifestyle', 'mode',
   array['queen:lifestyle','preis:unter50','preis:unter100']),
  ('pizza-socks-box-pepperoni',
   'unknown', 'sonstiges', 'ungeordnet',
   array['preis:unter20','preis:unter50','preis:unter100'],
   'queen', 'lifestyle', 'mode',
   array['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100']);

create temporary table cbb_qf_b5_preis (
  slug text primary key,
  ziel_price integer not null
) on commit drop;

insert into cbb_qf_b5_preis values ('divoom-pixoo-led-panel', 4249);

create temporary table cbb_qf_b5_bilder (
  slug text primary key,
  pre_image_url text not null,
  pre_image_urls text[] not null,
  ziel_image_url text not null,
  ziel_image_urls text[] not null
) on commit drop;

insert into cbb_qf_b5_bilder values (
  'divoom-minitoo-retro-pc-lautsprecher-pixel',
  'https://divoom.com/cdn/shop/files/minitoo-1.jpg',
  array['https://divoom.com/cdn/shop/files/minitoo-1.jpg'],
  'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg',
  array[
    'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71v8gQDca6L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/714WnHwLo9L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71jxiRQdS5L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71GkuzGfSGL._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71VTCrKHb0L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71r9B960j6L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71-2D0RTF4L._AC_SL1500_.jpg',
    'https://m.media-amazon.com/images/I/71C2JOSo0IL._AC_SL1500_.jpg'
  ]
);

create temporary table cbb_qf_d6 (
  slug text primary key,
  pre_name text not null,
  ziel_name text not null,
  pre_description text not null,
  ziel_description text not null,
  pre_note text not null,
  ziel_note text not null
) on commit drop;

insert into cbb_qf_d6 values (
  'cream-noise-machine-baby-tragbar',
  'Cream Noise Machine Baby Tragbar',
  'White Noise Machine Baby Tragbar',
  'Tragbare Cream Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.',
  'Tragbare White Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.',
  'Die tragbare Cream-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.',
  'Die tragbare White-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.'
);

create temporary table cbb_qf_listen (
  slug text primary key,
  pre_slugs text[] not null,
  ziel_slugs text[] not null
) on commit drop;

insert into cbb_qf_listen values
  ('verrueckte-amazon-gadgets',
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
   ],
   array[
     'flipper-zero',
     'seek-thermal-compact-usbc',
     'arc-reaktor-mk1-schwebend',
     'plasmakugel-8-zoll-beruehrungsempfindlich',
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
   ]),
  ('witzige-geschenke-maenner',
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
   ],
   array[
     'faelnk-toilettengolf-set',
     'bug-a-salt-3-0-fliegenjaeger-salzgewehr',
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
   ]),
  ('geschenke-fuer-gamer',
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
   ],
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
     'dealkit-3d-labyrinth-wuerfel'
   ]);

create temporary table cbb_qf_produkte (
  slug text primary key,
  gruppe text not null,
  geaenderte_spalten text[] not null
) on commit drop;

insert into cbb_qf_produkte values
  ('fingerabdruck-vorhaengeschloss-eseesmart', 'B2',
   array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']),
  ('flauschige-handschuhe-weihnachten', 'B2',
   array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']),
  ('pizza-socks-box-pepperoni', 'B2',
   array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']),
  ('divoom-pixoo-led-panel', 'B5a',
   array['price_cents','updated_at']),
  ('divoom-minitoo-retro-pc-lautsprecher-pixel', 'B5b',
   array['image_url','image_urls','updated_at']),
  ('cream-noise-machine-baby-tragbar', 'D6',
   array['name','description','editorial_note','updated_at']);

-- Fingerabdruck ALLER Nichtzielzeilen, aufgenommen VOR dem Schreibvorgang.
create temporary table cbb_qf_fremde_produkte on commit drop as
select p.id, md5(to_jsonb(p)::text) as fingerabdruck
from public.products p
where not exists (select 1 from cbb_qf_produkte g where g.slug = p.slug);

create temporary table cbb_qf_fremde_listen on commit drop as
select l.id, md5(to_jsonb(l)::text) as fingerabdruck
from public.lists l
where not exists (select 1 from cbb_qf_listen e where e.slug = l.slug);

-- ---------------------------------------------------------------------------
-- Guard 2, Sperre, Guard 3 und der Restore.
--
-- Gesperrt werden alle neun Zielzeilen gemeinsam mit ihren Backup-Zeilen. Erst
-- danach sind Backup-Inhalt und Identitaet stabil; ohne diesen zweiten Beweis
-- koennte eine konkurrierende Transaktion das Backup zwischen Vorpruefung und
-- UPDATE noch veraendern, und der Restore wuerde fremden Inhalt als
-- Seiteninhalt schreiben.
-- ---------------------------------------------------------------------------
do $$
declare
  backup_pre_produkte integer;
  backup_pre_listen integer;
  produkte_wie_backup integer;
  listen_wie_backup integer;
  produkte_ziel integer;
  listen_ziel integer;
  gesperrt integer;
  drift integer;
  betroffen integer;
  fremd_abweichungen integer;
  fremd_anzahl integer;
begin
  -- ---- Backup gegen den bekannten Vorzustand (Manipulationsschutz) --------
  select
    (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
      join cbb_qf_b2 e on e.slug = b.slug
     where b.shop_persona is not distinct from e.pre_persona
       and b.shop_main_category is not distinct from e.pre_main
       and b.shop_sub_category is not distinct from e.pre_sub
       and b.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_preis e on e.slug = b.slug
       where b.price_cents is null)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_bilder e on e.slug = b.slug
       where b.image_url is not distinct from e.pre_image_url
         and b.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_d6 e on e.slug = b.slug
       where b.name is not distinct from e.pre_name
         and b.description is not distinct from e.pre_description
         and b.editorial_note is not distinct from e.pre_note)
  into backup_pre_produkte;

  select count(*) into backup_pre_listen
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  join cbb_qf_listen e on e.slug = b.slug
  where b.product_slugs is not distinct from e.pre_slugs;

  if backup_pre_produkte <> 6 or backup_pre_listen <> 3 then
    raise exception 'QF-Restore abgebrochen: Backup entspricht nicht dem bekannten Vorzustand (%/6 Produkte, %/3 Listen).',
      backup_pre_produkte, backup_pre_listen;
  end if;

  -- ---- Sperre auf allen neun Zielzeilen samt Backup-Zeilen ---------------
  perform p.id
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  for update of p, b;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 6 then
    raise exception 'QF-Restore abgebrochen: %/6 Produkt-Zeilenpaare gesperrt.', gesperrt;
  end if;

  perform l.id
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  for update of l, b;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 3 then
    raise exception 'QF-Restore abgebrochen: %/3 Listen-Zeilenpaare gesperrt.', gesperrt;
  end if;

  -- Neues Statement, neuer Snapshot: der Backup-Inhalt steht jetzt unter dem
  -- Lock fest und wird erneut gegen den bekannten Vorzustand geprueft.
  select
    (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
      join cbb_qf_b2 e on e.slug = b.slug
     where b.shop_persona is not distinct from e.pre_persona
       and b.shop_main_category is not distinct from e.pre_main
       and b.shop_sub_category is not distinct from e.pre_sub
       and b.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_preis e on e.slug = b.slug
       where b.price_cents is null)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_bilder e on e.slug = b.slug
       where b.image_url is not distinct from e.pre_image_url
         and b.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_d6 e on e.slug = b.slug
       where b.name is not distinct from e.pre_name
         and b.description is not distinct from e.pre_description
         and b.editorial_note is not distinct from e.pre_note)
  into backup_pre_produkte;

  select count(*) into backup_pre_listen
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  join cbb_qf_listen e on e.slug = b.slug
  where b.product_slugs is not distinct from e.pre_slugs;

  if backup_pre_produkte <> 6 or backup_pre_listen <> 3 then
    raise exception 'QF-Restore abgebrochen: Backup wurde zwischen Vorpruefung und Sperre veraendert (%/6 Produkte, %/3 Listen).',
      backup_pre_produkte, backup_pre_listen;
  end if;

  -- ---- Fall A: bereits vollstaendig im Vorzustand -> No-Op ---------------
  select count(*) into produkte_wie_backup
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where to_jsonb(p) is not distinct from to_jsonb(b);

  select count(*) into listen_wie_backup
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  where to_jsonb(l) is not distinct from to_jsonb(b);

  if produkte_wie_backup = 6 and listen_wie_backup = 3 then
    raise notice 'QF-Restore: alle neun Zeilen entsprechen bereits exakt dem Backup — No-Op, kein UPDATE.';
    return;
  end if;

  -- ---- Fall B: Zielzustand -> zurueckrollen ------------------------------
  select
    (select count(*) from public.products p join cbb_qf_b2 e on e.slug = p.slug
     where p.shop_persona is not distinct from e.ziel_persona
       and p.shop_main_category is not distinct from e.ziel_main
       and p.shop_sub_category is not distinct from e.ziel_sub
       and p.shop_tags is not distinct from e.ziel_tags)
    + (select count(*) from public.products p join cbb_qf_b5_preis e on e.slug = p.slug
       where p.price_cents is not distinct from e.ziel_price)
    + (select count(*) from public.products p join cbb_qf_b5_bilder e on e.slug = p.slug
       where p.image_url is not distinct from e.ziel_image_url
         and p.image_urls is not distinct from e.ziel_image_urls)
    + (select count(*) from public.products p join cbb_qf_d6 e on e.slug = p.slug
       where p.name is not distinct from e.ziel_name
         and p.description is not distinct from e.ziel_description
         and p.editorial_note is not distinct from e.ziel_note)
  into produkte_ziel;

  select count(*) into listen_ziel
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.ziel_slugs;

  if produkte_ziel <> 6 or listen_ziel <> 3 then
    raise exception 'QF-Restore abgebrochen: gemischter oder gedrifteter Zustand (wie Backup %/6 und %/3, im Zielzustand %/6 und %/3).',
      produkte_wie_backup, listen_wie_backup, produkte_ziel, listen_ziel;
  end if;

  -- Ausserhalb der von 04 geaenderten Spalten muss bereits alles dem Backup
  -- entsprechen. Andernfalls hat eine dritte Stelle an den Zielzeilen
  -- gearbeitet, und ein blinder Restore wuerde deren Aenderung verdecken.
  select count(*) into drift
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  join cbb_qf_produkte g on g.slug = p.slug
  where to_jsonb(p) - g.geaenderte_spalten
        is distinct from to_jsonb(b) - g.geaenderte_spalten;
  if drift <> 0 then
    raise exception 'QF-Restore abgebrochen: % Zielprodukte weichen ausserhalb der von 04 geaenderten Spalten vom Backup ab.',
      drift;
  end if;

  select count(*) into drift
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  where to_jsonb(l) - array['product_slugs']
        is distinct from to_jsonb(b) - array['product_slugs'];
  if drift <> 0 then
    raise exception 'QF-Restore abgebrochen: % Ziellisten weichen ausserhalb von product_slugs vom Backup ab.',
      drift;
  end if;

  -- ---- B2 zurueckrollen ---------------------------------------------------
  update public.products p set
    shop_persona       = b.shop_persona,
    shop_main_category = b.shop_main_category,
    shop_sub_category  = b.shop_sub_category,
    shop_tags          = b.shop_tags,
    updated_at         = b.updated_at
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join cbb_qf_b2 e on e.slug = b.slug
  where p.id = b.id and p.slug = b.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 3 then
    raise exception 'QF-Restore abgebrochen: B2-Restore traf %/3 Zeilen.', betroffen;
  end if;

  -- ---- B5a zurueckrollen --------------------------------------------------
  update public.products p set
    price_cents = b.price_cents,
    updated_at  = b.updated_at
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join cbb_qf_b5_preis e on e.slug = b.slug
  where p.id = b.id and p.slug = b.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Restore abgebrochen: B5a-Restore traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- B5b zurueckrollen --------------------------------------------------
  update public.products p set
    image_url  = b.image_url,
    image_urls = b.image_urls,
    updated_at = b.updated_at
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join cbb_qf_b5_bilder e on e.slug = b.slug
  where p.id = b.id and p.slug = b.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Restore abgebrochen: B5b-Restore traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- D6 zurueckrollen ---------------------------------------------------
  update public.products p set
    name           = b.name,
    description    = b.description,
    editorial_note = b.editorial_note,
    updated_at     = b.updated_at
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join cbb_qf_d6 e on e.slug = b.slug
  where p.id = b.id and p.slug = b.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Restore abgebrochen: D6-Restore traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- Listen zurueckrollen ----------------------------------------------
  update public.lists l set
    product_slugs = b.product_slugs
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  where l.id = b.id and l.slug = b.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 3 then
    raise exception 'QF-Restore abgebrochen: Listen-Restore traf %/3 Zeilen.', betroffen;
  end if;

  -- ======================= Nachbedingungen ================================

  -- 1 — alle sechs Produktzeilen sind vollstaendig identisch mit dem Backup,
  --     updated_at eingeschlossen. Damit ist auch der historische lastmod-Wert
  --     wieder da und ein doch gefeuerter Trigger faellt hier auf.
  select count(*) into produkte_wie_backup
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where to_jsonb(p) is not distinct from to_jsonb(b);
  if produkte_wie_backup <> 6 then
    raise exception 'QF-Restore inkonsistent: nur %/6 Produktzeilen exakt wie im Backup.',
      produkte_wie_backup;
  end if;

  -- 2 — alle drei Listenzeilen sind vollstaendig identisch mit dem Backup.
  select count(*) into listen_wie_backup
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  where to_jsonb(l) is not distinct from to_jsonb(b);
  if listen_wie_backup <> 3 then
    raise exception 'QF-Restore inkonsistent: nur %/3 Listenzeilen exakt wie im Backup.',
      listen_wie_backup;
  end if;

  -- 3 — keine andere Produktzeile veraendert (gemessen, nicht behauptet).
  select count(*) into fremd_anzahl from cbb_qf_fremde_produkte;
  select count(*) into fremd_abweichungen
  from cbb_qf_fremde_produkte f
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck
    from public.products p
    where not exists (select 1 from cbb_qf_produkte g where g.slug = p.slug)
  ) n on n.id = f.id
  where f.id is null or n.id is null
     or n.fingerabdruck is distinct from f.fingerabdruck;
  if fremd_abweichungen <> 0 then
    raise exception 'QF-Restore inkonsistent: % von % Nichtzielzeilen in products veraendert.',
      fremd_abweichungen, fremd_anzahl;
  end if;

  -- 4 — keine andere Listenzeile veraendert.
  select count(*) into fremd_anzahl from cbb_qf_fremde_listen;
  select count(*) into fremd_abweichungen
  from cbb_qf_fremde_listen f
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck
    from public.lists l
    where not exists (select 1 from cbb_qf_listen e where e.slug = l.slug)
  ) n on n.id = f.id
  where f.id is null or n.id is null
     or n.fingerabdruck is distinct from f.fingerabdruck;
  if fremd_abweichungen <> 0 then
    raise exception 'QF-Restore inkonsistent: % von % Nichtzielzeilen in lists veraendert.',
      fremd_abweichungen, fremd_anzahl;
  end if;

  -- 5 — das Backup ist unangetastet geblieben.
  select
    (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
      join cbb_qf_b2 e on e.slug = b.slug
     where b.shop_persona is not distinct from e.pre_persona
       and b.shop_main_category is not distinct from e.pre_main
       and b.shop_sub_category is not distinct from e.pre_sub
       and b.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_preis e on e.slug = b.slug
       where b.price_cents is null)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_b5_bilder e on e.slug = b.slug
       where b.image_url is not distinct from e.pre_image_url
         and b.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
        join cbb_qf_d6 e on e.slug = b.slug
       where b.name is not distinct from e.pre_name
         and b.description is not distinct from e.pre_description
         and b.editorial_note is not distinct from e.pre_note)
  into backup_pre_produkte;
  select count(*) into backup_pre_listen
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  join cbb_qf_listen e on e.slug = b.slug
  where b.product_slugs is not distinct from e.pre_slugs;
  if backup_pre_produkte <> 6 or backup_pre_listen <> 3 then
    raise exception 'QF-Restore inkonsistent: das Backup wurde veraendert (%/6 Produkte, %/3 Listen).',
      backup_pre_produkte, backup_pre_listen;
  end if;
end $$;

commit;
