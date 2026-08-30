-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 04 ATOMARE KORREKTUR (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WAS GENAU PASSIERT — neun Zeilen, sonst nichts
--
--   public.products, sechs Zeilen:
--     B2  fingerabdruck-vorhaengeschloss-eseesmart,
--         flauschige-handschuhe-weihnachten,
--         pizza-socks-box-pepperoni
--         -> shop_persona, shop_main_category, shop_sub_category, shop_tags,
--            updated_at
--     B5a divoom-pixoo-led-panel
--         -> price_cents, updated_at
--     B5b divoom-minitoo-retro-pc-lautsprecher-pixel
--         -> image_url, image_urls, updated_at
--     D6  cream-noise-machine-baby-tragbar
--         -> name, description, editorial_note, updated_at
--
--   public.lists, drei Zeilen, jeweils nur product_slugs:
--     A4  verrueckte-amazon-gadgets   Position 4  Schreibfehler korrigiert
--     A4  witzige-geschenke-maenner   Position 2  Schreibfehler korrigiert
--     A5  geschenke-fuer-gamer        16 -> 13, erste Vorkommen, Reihenfolge
--                                     bleibt erhalten
--   public.lists hat keine Spalte updated_at; dort wird deshalb kein
--   Zeitstempel geschrieben.
--
--   Der Slug cream-noise-machine-baby-tragbar bleibt absichtlich unveraendert.
--   Die URL ist indexiert; eine Slug-Aenderung waere ein SEO-Eingriff mit
--   Redirect-Bedarf und kein Textfix. Sie ist nicht Teil dieses Pakets.
--
--   D7 (die beiden TOSY-Flying-Disc-Produkte) wird NICHT angefasst. Begruendung
--   in RUNBOOK.md, Abschnitt 6.
--
-- updated_at = now() ist Absicht und wird ausdruecklich mitgeschrieben. Der
-- Trigger products_set_updated_at (supabase/seo_updated_at_trigger.sql)
-- ueberschreibt einen ausdruecklich gesetzten Wert nicht. Alle vier
-- Produktaenderungen sind sichtbare Seitenaenderungen: Persona und
-- Hauptkategorie bauen Breadcrumb und interne Links, image_url ist das
-- primaere Produktbild, name und description sind Titel und Fliesstext, und
-- price_cents wechselt hier von "kein Preis" auf ein sichtbares Preisband.
--
-- WIEDERHOLBARKEIT
--   Stehen alle neun Zeilen bereits exakt im Zielzustand, ist dieser Lauf ein
--   No-Op: kein UPDATE, kein neues updated_at. Stehen alle neun exakt im
--   Vorzustand, wird korrigiert. Jeder gemischte oder gedriftete Zustand
--   bricht die Transaktion ab.
--
-- FAIL CLOSED GEGEN NEBENLAEUFIGKEIT
--   Die sperrfreie Vorpruefung ist nur ein Vorfilter. Verbindlich ist die
--   Pruefung NACH dem Row-Lock: gesperrt werden alle sechs Produktzeilen und
--   alle drei Listenzeilen zusammen mit ihren Backup-Zeilen, danach werden
--   Zustandsklassifizierung und Driftfreiheit vollstaendig wiederholt. Eine
--   konkurrierende Aenderung, die vor dem Lock committet, wird dadurch erkannt
--   und NICHT ueberschrieben.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung, Backup-Existenz, Backup-Sicherheit.
-- ---------------------------------------------------------------------------
do $$
declare
  product_rows bigint;
  backup_produkt_zeilen integer;
  backup_listen_zeilen integer;
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
    raise exception 'QF-Korrektur abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.lists') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'QF-Korrektur abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'QF-Korrektur abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  if to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1') is null
     or to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1') is null then
    raise exception 'QF-Korrektur abgebrochen: privates Backup fehlt.';
  end if;

  select count(*) into backup_produkt_zeilen
  from cbb_private_backup.quality_fixes_20260830_products_v1;
  select count(*) into backup_listen_zeilen
  from cbb_private_backup.quality_fixes_20260830_lists_v1;
  if backup_produkt_zeilen <> 6 or backup_listen_zeilen <> 3 then
    raise exception 'QF-Korrektur abgebrochen: Backup hat %/6 Produkt- und %/3 Listenzeilen.',
      backup_produkt_zeilen, backup_listen_zeilen;
  end if;

  -- -------------------------------------------------------------------------
  -- Harte Vorbedingung der Rechtepruefung: fehlt eine der App-Rollen, liefern
  -- die Zaehler still 0 — das waere kein Beleg fuer "keine Rechte", sondern
  -- nur einer fuer "keine Rolle". Ein schreibender Guard darf sich darauf
  -- nicht stuetzen.
  -- -------------------------------------------------------------------------
  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 2 then
    raise exception 'QF-Korrektur abgebrochen: %/2 App-Rollen (anon, authenticated) vorhanden — Rechtepruefung nicht aussagekraeftig.',
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
  -- Rollenmitgliedschaft und PUBLIC-Rechte mit auf; ein nur geerbtes Recht ist
  -- in (a) unsichtbar.
  select count(*) into effektiv_schema
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  where r.rolname in ('anon', 'authenticated', 'service_role')
    and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

  if direkt_schema <> 0 or effektiv_schema <> 0 then
    raise exception 'QF-Korrektur abgebrochen: Schema cbb_private_backup unsicher (direkt %, effektiv %).',
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
      raise exception 'QF-Korrektur abgebrochen: Backup-Tabelle % unsicher (RLS=%, Policies=%).',
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
      raise exception 'QF-Korrektur abgebrochen: Backup-Tabelle % unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt %, effektiv %).',
        tabelle_oid::regclass, direkt_tabelle, effektiv_tabelle;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Vorzustand und Zielzustand — genau einmal als Literal in dieser Datei.
-- Dieselben Werte stehen in 01, 02, 03, 05 und 06; Herkunft und Belege stehen
-- im Kopf von 01 und in RUNBOOK.md.
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

-- Die sechs Zielprodukte mit der Liste der Spalten, die an ihnen geaendert
-- werden duerfen. Sie ist die Grundlage des Beweises "an einer Zielzeile wurde
-- NUR das geaendert".
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

-- ---------------------------------------------------------------------------
-- Fingerabdruck ALLER Nichtzielzeilen, aufgenommen VOR dem Schreibvorgang.
-- Damit ist die Zusage "keine andere Zeile veraendert" nicht nur eine Aussage
-- ueber die WHERE-Klauseln, sondern eine gemessene Nachbedingung.
-- ---------------------------------------------------------------------------
create temporary table cbb_qf_fremde_produkte on commit drop as
select p.id, md5(to_jsonb(p)::text) as fingerabdruck
from public.products p
where not exists (select 1 from cbb_qf_produkte g where g.slug = p.slug);

create temporary table cbb_qf_fremde_listen on commit drop as
select l.id, md5(to_jsonb(l)::text) as fingerabdruck
from public.lists l
where not exists (select 1 from cbb_qf_listen e where e.slug = l.slug);

-- ---------------------------------------------------------------------------
-- Guard 2, Sperre, Guard 3 und die Korrektur.
--
-- WARUM ALLE PRUEFUNGEN NACH DEM LOCK WIEDERHOLT WERDEN
--   Guard 2 liest ohne Sperre. Zwischen Guard 2 und dem Row-Lock darf eine
--   konkurrierende Transaktion jederzeit committen — ihre Aenderung wuerde vom
--   UPDATE sonst kommentarlos ueberschrieben und waere verloren. Deshalb:
--     1. Alle neun Zielzeilen gemeinsam mit ihren Backup-Zeilen sperren.
--     2. Nach erfolgreichem Lock erneut pruefen:
--        (a) in welchem Zustand die neun Zeilen stehen (Vorzustand, Zielzustand
--            oder gemischt),
--        (b) dass das Backup exakt der bekannte Vorzustand ist,
--        (c) dass Backup und Quelle im Vorzustandsfall vollstaendig driftfrei
--            sind, jede Spalte eingeschlossen.
--     3. Erst danach schreiben.
--   Der Lock haelt bis zum COMMIT; ab Schritt 2 ist der Stand festgeschrieben.
-- ---------------------------------------------------------------------------
do $$
declare
  produkte_pre integer;
  produkte_ziel integer;
  listen_pre integer;
  listen_ziel integer;
  backup_pre_produkte integer;
  backup_pre_listen integer;
  gesperrt integer;
  drift integer;
  betroffen integer;
  fremd_abweichungen integer;
  fremd_anzahl integer;
  gamer_laenge integer;
  gamer_eindeutig integer;
  tote_slugs integer;
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
    raise exception 'QF-Korrektur abgebrochen: Backup entspricht nicht dem bekannten Vorzustand (%/6 Produkte, %/3 Listen).',
      backup_pre_produkte, backup_pre_listen;
  end if;

  -- ---- Guard 2: sperrfreie Klassifizierung als billiger Vorfilter --------
  select
    (select count(*) from public.products p join cbb_qf_b2 e on e.slug = p.slug
     where p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from public.products p join cbb_qf_b5_preis e on e.slug = p.slug
       where p.price_cents is null)
    + (select count(*) from public.products p join cbb_qf_b5_bilder e on e.slug = p.slug
       where p.image_url is not distinct from e.pre_image_url
         and p.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from public.products p join cbb_qf_d6 e on e.slug = p.slug
       where p.name is not distinct from e.pre_name
         and p.description is not distinct from e.pre_description
         and p.editorial_note is not distinct from e.pre_note)
  into produkte_pre;

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

  select count(*) into listen_pre
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.pre_slugs;

  select count(*) into listen_ziel
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.ziel_slugs;

  if not ((produkte_pre = 6 and listen_pre = 3)
          or (produkte_ziel = 6 and listen_ziel = 3)) then
    raise exception 'QF-Korrektur abgebrochen: gemischter oder gedrifteter Zustand (Vorzustand %/6 Produkte und %/3 Listen, Zielzustand %/6 und %/3).',
      produkte_pre, listen_pre, produkte_ziel, listen_ziel;
  end if;

  -- ---- Sperre auf allen neun Zielzeilen samt Backup-Zeilen ---------------
  -- READ COMMITTED: blockiert FOR UPDATE, wird nach dem fremden COMMIT auf der
  -- NEUEN Zeilenversion neu ausgewertet. Passt id/slug dann nicht mehr oder ist
  -- die Zeile geloescht, kommen weniger Zeilen zurueck.
  perform p.id
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  for update of p, b;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 6 then
    raise exception 'QF-Korrektur abgebrochen: %/6 Produkt-Zeilenpaare aus products und Backup gesperrt.',
      gesperrt;
  end if;

  perform l.id
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  for update of l, b;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 3 then
    raise exception 'QF-Korrektur abgebrochen: %/3 Listen-Zeilenpaare aus lists und Backup gesperrt.',
      gesperrt;
  end if;

  -- ---- Guard 3: dieselbe Klassifizierung erneut, jetzt unter dem Lock ----
  select
    (select count(*) from public.products p join cbb_qf_b2 e on e.slug = p.slug
     where p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from public.products p join cbb_qf_b5_preis e on e.slug = p.slug
       where p.price_cents is null)
    + (select count(*) from public.products p join cbb_qf_b5_bilder e on e.slug = p.slug
       where p.image_url is not distinct from e.pre_image_url
         and p.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from public.products p join cbb_qf_d6 e on e.slug = p.slug
       where p.name is not distinct from e.pre_name
         and p.description is not distinct from e.pre_description
         and p.editorial_note is not distinct from e.pre_note)
  into produkte_pre;

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

  select count(*) into listen_pre
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.pre_slugs;

  select count(*) into listen_ziel
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.ziel_slugs;

  -- ---- Fall A: bereits im Zielzustand -> No-Op ---------------------------
  if produkte_ziel = 6 and listen_ziel = 3 then
    -- Auch der No-Op belegt, dass an den neun Zeilen ausserhalb der erlaubten
    -- Spalten nichts gedriftet ist.
    select count(*) into drift
    from public.products p
    join cbb_private_backup.quality_fixes_20260830_products_v1 b
      on b.id = p.id and b.slug = p.slug
    join cbb_qf_produkte g on g.slug = p.slug
    where to_jsonb(p) - g.geaenderte_spalten
          is distinct from to_jsonb(b) - g.geaenderte_spalten;
    if drift <> 0 then
      raise exception 'QF-Korrektur abgebrochen: % Zielprodukte weichen ausserhalb der erlaubten Spalten vom Backup ab.',
        drift;
    end if;

    select count(*) into drift
    from public.lists l
    join cbb_private_backup.quality_fixes_20260830_lists_v1 b
      on b.id = l.id and b.slug = l.slug
    where to_jsonb(l) - array['product_slugs']
          is distinct from to_jsonb(b) - array['product_slugs'];
    if drift <> 0 then
      raise exception 'QF-Korrektur abgebrochen: % Ziellisten weichen ausserhalb von product_slugs vom Backup ab.',
        drift;
    end if;

    raise notice 'QF-Korrektur: alle neun Zeilen stehen bereits exakt im Zielzustand — No-Op, kein UPDATE, kein neues updated_at.';
    return;
  end if;

  -- ---- Fall B: Vorzustand -> korrigieren ---------------------------------
  if produkte_pre <> 6 or listen_pre <> 3 then
    raise exception 'QF-Korrektur abgebrochen: Zielzeilen wurden zwischen Vorpruefung und Sperre veraendert (Vorzustand %/6 Produkte und %/3 Listen, Zielzustand %/6 und %/3).',
      produkte_pre, listen_pre, produkte_ziel, listen_ziel;
  end if;

  -- Backup und Quelle muessen im Vorzustand VOLLSTAENDIG driftfrei sein, jede
  -- Spalte und updated_at eingeschlossen. Damit ist der Rollback in 06 exakt.
  select count(*) into drift
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  full join (
    select p.* from public.products p join cbb_qf_produkte g on g.slug = p.slug
  ) p on p.id = b.id and p.slug = b.slug
  where b.id is null or p.id is null
     or to_jsonb(p) is distinct from to_jsonb(b);
  if drift <> 0 then
    raise exception 'QF-Korrektur abgebrochen: % Abweichungen zwischen Backup und public.products nach dem Lock.',
      drift;
  end if;

  select count(*) into drift
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  full join (
    select l.* from public.lists l join cbb_qf_listen e on e.slug = l.slug
  ) l on l.id = b.id and l.slug = b.slug
  where b.id is null or l.id is null
     or to_jsonb(l) is distinct from to_jsonb(b);
  if drift <> 0 then
    raise exception 'QF-Korrektur abgebrochen: % Abweichungen zwischen Backup und public.lists nach dem Lock.',
      drift;
  end if;

  -- ---- B2: drei Produkte kategorisieren ----------------------------------
  update public.products p set
    shop_persona       = e.ziel_persona,
    shop_main_category = e.ziel_main,
    shop_sub_category  = e.ziel_sub,
    shop_tags          = e.ziel_tags,
    updated_at         = now()
  from cbb_qf_b2 e
  where p.slug = e.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 3 then
    raise exception 'QF-Korrektur abgebrochen: B2-UPDATE traf %/3 Zeilen.', betroffen;
  end if;

  -- ---- B5a: Preis nachtragen ---------------------------------------------
  update public.products p set
    price_cents = e.ziel_price,
    updated_at  = now()
  from cbb_qf_b5_preis e
  where p.slug = e.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Korrektur abgebrochen: B5a-UPDATE traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- B5b: Bilder ersetzen ----------------------------------------------
  update public.products p set
    image_url  = e.ziel_image_url,
    image_urls = e.ziel_image_urls,
    updated_at = now()
  from cbb_qf_b5_bilder e
  where p.slug = e.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Korrektur abgebrochen: B5b-UPDATE traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- D6: Cream -> White -------------------------------------------------
  update public.products p set
    name           = e.ziel_name,
    description    = e.ziel_description,
    editorial_note = e.ziel_note,
    updated_at     = now()
  from cbb_qf_d6 e
  where p.slug = e.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 1 then
    raise exception 'QF-Korrektur abgebrochen: D6-UPDATE traf %/1 Zeilen.', betroffen;
  end if;

  -- ---- A4 und A5: drei Listen --------------------------------------------
  update public.lists l set
    product_slugs = e.ziel_slugs
  from cbb_qf_listen e
  where l.slug = e.slug;
  get diagnostics betroffen = row_count;
  if betroffen <> 3 then
    raise exception 'QF-Korrektur abgebrochen: Listen-UPDATE traf %/3 Zeilen.', betroffen;
  end if;

  -- ======================= Nachbedingungen ================================

  -- 1 — alle sechs Produktzeilen tragen exakt den Zielzustand.
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
  if produkte_ziel <> 6 then
    raise exception 'QF-Korrektur inkonsistent: nur %/6 Produktzeilen im Zielzustand.', produkte_ziel;
  end if;

  -- 2 — alle drei Listenzeilen tragen exakt den Zielzustand.
  select count(*) into listen_ziel
  from public.lists l join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.ziel_slugs;
  if listen_ziel <> 3 then
    raise exception 'QF-Korrektur inkonsistent: nur %/3 Listenzeilen im Zielzustand.', listen_ziel;
  end if;

  -- 3 — an den Zielprodukten wurde NUR das geaendert, was erlaubt war.
  select count(*) into drift
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  join cbb_qf_produkte g on g.slug = p.slug
  where to_jsonb(p) - g.geaenderte_spalten
        is distinct from to_jsonb(b) - g.geaenderte_spalten;
  if drift <> 0 then
    raise exception 'QF-Korrektur inkonsistent: % Zielprodukte wurden ausserhalb der erlaubten Spalten veraendert.',
      drift;
  end if;

  -- 4 — an den Ziellisten wurde NUR product_slugs geaendert.
  select count(*) into drift
  from public.lists l
  join cbb_private_backup.quality_fixes_20260830_lists_v1 b
    on b.id = l.id and b.slug = l.slug
  where to_jsonb(l) - array['product_slugs']
        is distinct from to_jsonb(b) - array['product_slugs'];
  if drift <> 0 then
    raise exception 'QF-Korrektur inkonsistent: % Ziellisten wurden ausserhalb von product_slugs veraendert.',
      drift;
  end if;

  -- 5 — neues lastmod fuer genau diese sechs Seiten.
  select count(*) into drift
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b on b.id = p.id
  where p.updated_at > b.updated_at;
  if drift <> 6 then
    raise exception 'QF-Korrektur inkonsistent: updated_at wurde nur bei %/6 Zielprodukten neu gesetzt.', drift;
  end if;

  -- 6 — keine andere Produktzeile veraendert (gemessen, nicht behauptet).
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
    raise exception 'QF-Korrektur inkonsistent: % von % Nichtzielzeilen in products veraendert.',
      fremd_abweichungen, fremd_anzahl;
  end if;

  -- 7 — keine andere Listenzeile veraendert.
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
    raise exception 'QF-Korrektur inkonsistent: % von % Nichtzielzeilen in lists veraendert.',
      fremd_abweichungen, fremd_anzahl;
  end if;

  -- 8 — das Backup ist unangetastet geblieben.
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
    raise exception 'QF-Korrektur inkonsistent: das Backup wurde veraendert (%/6 Produkte, %/3 Listen).',
      backup_pre_produkte, backup_pre_listen;
  end if;

  -- 9 — A5: exakt 13 Eintraege, keine Dublette mehr.
  select coalesce(array_length(l.product_slugs, 1), 0),
         (select count(distinct t.s) from unnest(l.product_slugs) as t(s))
  into gamer_laenge, gamer_eindeutig
  from public.lists l
  where l.slug = 'geschenke-fuer-gamer';
  if gamer_laenge <> 13 or gamer_eindeutig <> 13 then
    raise exception 'QF-Korrektur inkonsistent: geschenke-fuer-gamer hat % Eintraege, davon % eindeutig (erwartet 13/13).',
      gamer_laenge, gamer_eindeutig;
  end if;

  -- 10 — A4: die beiden fehlerhaften Slugs stehen in keiner der drei Listen
  --      mehr, und die korrekten Produkte existieren je genau einmal und
  --      published.
  select count(*) into tote_slugs
  from public.lists l
  join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs
        && array['plasmakugel-8-zoll-beruehlungsempfindlich',
                 'bug-a-salt-3-0-fliegenjager-salzgewehr'];
  if tote_slugs <> 0 then
    raise exception 'QF-Korrektur inkonsistent: % Ziellisten enthalten weiterhin einen fehlerhaften Slug.',
      tote_slugs;
  end if;

  select count(*) into tote_slugs
  from public.products p
  where p.slug in ('plasmakugel-8-zoll-beruehrungsempfindlich',
                   'bug-a-salt-3-0-fliegenjaeger-salzgewehr')
    and p.is_published is true;
  if tote_slugs <> 2 then
    raise exception 'QF-Korrektur inkonsistent: %/2 korrigierte Zielprodukte vorhanden und published.',
      tote_slugs;
  end if;
end $$;

commit;
