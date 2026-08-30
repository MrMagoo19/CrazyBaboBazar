-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 02 PRIVATES BACKUP (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Diese Datei fasst public.products und public.lists NUR LESEND an. Sie legt
-- ausschliesslich zwei Tabellen im privaten Schema cbb_private_backup an:
--   quality_fixes_20260830_products_v1   genau 7 Zeilen, VOLLSTAENDIG
--   quality_fixes_20260830_lists_v1      genau 3 Zeilen, VOLLSTAENDIG
--
-- Die siebte Produktzeile ist plasmakugel-8-zoll-beruehrungsempfindlich (A4).
-- Sie kam mit der Erweiterung des Pakets hinzu; siehe RUNBOOK Abschnitt 2.1.
--
-- "Vollstaendig" heisst: SELECT * — jede Spalte der Originalzeile, nicht nur
-- die spaeter geaenderten. Damit ist der Rollback in 06 nicht auf die heute
-- bekannte Spaltenauswahl angewiesen.
--
-- WIEDERHOLBARKEIT
--   Existieren beide Backup-Tabellen bereits UND enthalten sie exakt den
--   bekannten Vorzustand (Zeilenzahl, Zeilenidentitaet ueber id UND slug,
--   Slug-Menge, alle Vorwerte, updated_at nicht NULL, RLS, 0
--   Policies, keine direkten oder geerbten App-Rechte auf Schema und Tabellen),
--   ist dieser Lauf ein No-Op: er schreibt nichts
--   und meldet das. Jede Abweichung — nur eine der beiden Tabellen vorhanden,
--   falsche Zeilenzahl, fremde id, veraenderter Inhalt, geoeffnete Rechte —
--   bricht die Transaktion ab. Es wird nie ein zweites Mal ueber einen bereits
--   korrigierten Stand gesichert.
--
-- FAIL CLOSED GEGEN NEBENLAEUFIGKEIT
--   Der verbindliche Vorzustandsbeweis steht NACH dem Row-Lock auf allen zehn
--   Zielzeilen und umfasst alle spaeter geaenderten Felder plus Identitaet
--   (id, slug) und is_published. Eine Aenderung, die zwischen der sperrfreien
--   Vorpruefung und dem Lock committet, fuehrt zum Abbruch, statt in den
--   Snapshot zu geraten.
--
-- Das Backup bleibt nach einem Restore als Audit-Artefakt bestehen. Keine
-- Datei dieses Pakets loescht es. Es gibt in diesem Paket kein DROP und kein
-- DELETE.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung. Dieselben Pruefungen wie in 01, hier als harte
-- Abbruchbedingungen statt als Bericht.
-- ---------------------------------------------------------------------------
do $$
declare
  product_rows bigint;
  app_rollen integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'QF-Backup abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.lists') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'QF-Backup abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'QF-Backup abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- -------------------------------------------------------------------------
  -- Harte Vorbedingung der Rechtepruefung — dieselbe wie in 04 und 06.
  -- Saemtliche Rechte-Zaehler dieser Datei laufen ueber
  --   pg_roles ... where rolname in ('anon', 'authenticated', 'service_role')
  -- Fehlt eine der beiden App-Rollen, faellt sie aus dem Join heraus und der
  -- Zaehler meldet still 0. Das waere kein Beleg fuer "keine Rechte", sondern
  -- nur einer fuer "keine Rolle" — und damit fail-open.
  --
  -- Der Guard steht bewusst in Guard 1, also VOR jeder Verzweigung. Sonst
  -- koennte ausgerechnet der No-Op-Zweig (Backup existiert bereits) eine
  -- Backup-Tabelle als "sicher" durchwinken, deren Rechtelage gar nicht
  -- gemessen wurde.
  --
  -- service_role bleibt bewusst draussen: 02 revoked sie nur, wenn es sie gibt,
  -- und ein Cluster ohne service_role ist kein Fehlerfall. anon und
  -- authenticated dagegen sind auf Supabase immer vorhanden; ihr Fehlen
  -- bedeutet, dass die Messung nicht die Realitaet dieses Clusters abbildet.
  -- -------------------------------------------------------------------------
  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 2 then
    raise exception 'QF-Backup abgebrochen: %/2 App-Rollen (anon, authenticated) vorhanden — Rechtepruefung nicht aussagekraeftig.',
      app_rollen;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Der erwartete Vorzustand und der Zielzustand — genau einmal als Literal in
-- dieser Datei. Dieselben Werte stehen in 01, 03, 04, 05 und 06; Herkunft und
-- Belege stehen im Kopf von 01 und in RUNBOOK.md.
--
-- Der Zielzustand wird hier nur gebraucht, um sicher zu unterscheiden, ob eine
-- Zeile noch im Vorzustand oder schon im Zielzustand steht. 02 schreibt ihn
-- nirgendwohin.
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

-- A4 (Kategorie) — plasmakugel-8-zoll-beruehrungsempfindlich.
-- Vorzustand read-only auf Production verifiziert (2026-08-30):
-- babo / tech / basteln mit shop_tags ['babo:tech','preis:unter50',
-- 'preis:unter100'], published, updated_at 2026-07-04T00:00:00+00.
-- Zielzustand: NUR shop_sub_category = 'gadgets'. Persona, Hauptkategorie und
-- Tags stehen hier als Vorwerte und bleiben damit Teil der Abbruchbedingung.
create temporary table cbb_qf_a4_kategorie (
  slug text primary key,
  pre_persona text not null,
  pre_main text not null,
  pre_sub text not null,
  pre_tags text[] not null,
  ziel_sub text not null
) on commit drop;

insert into cbb_qf_a4_kategorie values (
  'plasmakugel-8-zoll-beruehrungsempfindlich',
  'babo', 'tech', 'basteln',
  array['babo:tech','preis:unter50','preis:unter100'],
  'gadgets'
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

-- Die sieben Zielprodukte mit der Liste der Spalten, die 04 an ihnen aendert.
-- Sie wird in 04, 05 und 06 gebraucht, um zu beweisen, dass an einer Zielzeile
-- NUR diese Spalten angefasst wurden.
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
   array['name','description','editorial_note','updated_at']),
  ('plasmakugel-8-zoll-beruehrungsempfindlich', 'A4',
   array['shop_sub_category']);

-- ---------------------------------------------------------------------------
-- Identitaetsanker. Die Guards weiter unten sind getrennte DO-Bloecke und
-- teilen keine Variablen. Damit der Recheck nach dem Row-Lock nachweislich
-- DIESELBEN Zeilen wiederfindet und nicht nur "irgendeine Zeile mit diesem
-- Slug", werden ihre ids hier festgehalten.
-- ---------------------------------------------------------------------------
create temporary table cbb_qf_identitaet_produkte on commit drop as
select p.id, p.slug
from public.products p
join cbb_qf_produkte g on g.slug = p.slug;

create temporary table cbb_qf_identitaet_listen on commit drop as
select l.id, l.slug
from public.lists l
join cbb_qf_listen e on e.slug = l.slug;

-- ---------------------------------------------------------------------------
-- Guard 2 + Snapshot.
--
-- Ablauf:
--   1. Ist genau eine der beiden Backup-Tabellen vorhanden -> Abbruch.
--      Ein halbes Backup ist kein Backup.
--   2. Sind BEIDE vorhanden -> vollstaendig pruefen (Zeilenzahl, Zeilenidentitaet
--      ueber id UND slug, Inhalt gegen den bekannten Vorzustand, updated_at
--      nicht NULL, RLS, Policies, Rechte). Bestehen sie die Pruefung, ist dieser
--      Lauf ein No-Op. Sonst Abbruch.
--   3. Ist keine vorhanden -> Vorzustand sperrfrei pruefen, dann alle zehn
--      Zielzeilen sperren, den Vorzustand NACH dem Lock erneut vollstaendig
--      pruefen, und erst danach den Snapshot anlegen und absichern.
--
-- Warum der Recheck nach dem Lock alle Vorwerte umfasst: die sperrfreie
-- Vorpruefung liest ohne Sperre. Zwischen ihr und dem Lock darf eine
-- konkurrierende Transaktion jederzeit committen. Wuerde danach nur ein Teil
-- der Felder geprueft, geriete eine fremde Aenderung unbemerkt in den Snapshot
-- und der Rollback-Pfad waere still falsch.
-- ---------------------------------------------------------------------------
do $$
declare
  hat_produkte boolean;
  hat_listen boolean;
  backup_produkt_zeilen integer;
  backup_listen_zeilen integer;
  backup_produkt_pre integer;
  backup_listen_pre integer;
  produkte_pre integer;
  listen_pre integer;
  identitaet_produkte integer;
  identitaet_listen integer;
  gesperrt integer;
  updated_at_null integer;
  drift integer;
  backup_nsp oid;
  tabelle_oid oid;
  rls_aktiv boolean;
  policies integer;
  direkte_schemarechte integer;
  effektive_schemarechte integer;
  direkte_tabellenrechte integer;
  effektive_tabellenrechte integer;
begin
  hat_produkte := to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1') is not null;
  hat_listen   := to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1') is not null;

  -- ---- 1. halbes Backup --------------------------------------------------
  if hat_produkte <> hat_listen then
    raise exception 'QF-Backup abgebrochen: nur eine der beiden Backup-Tabellen existiert (products=%, lists=%).',
      hat_produkte, hat_listen;
  end if;

  -- ---- 2. bereits vorhandenes Backup -------------------------------------
  if hat_produkte and hat_listen then
    select count(*) into backup_produkt_zeilen
    from cbb_private_backup.quality_fixes_20260830_products_v1;
    select count(*) into backup_listen_zeilen
    from cbb_private_backup.quality_fixes_20260830_lists_v1;
    if backup_produkt_zeilen <> 7 or backup_listen_zeilen <> 3 then
      raise exception 'QF-Backup abgebrochen: vorhandenes Backup hat %/7 Produkt- und %/3 Listenzeilen.',
        backup_produkt_zeilen, backup_listen_zeilen;
    end if;

    -- ---- Zeilenidentitaet des vorhandenen Snapshots -----------------------
    -- Der Neuanlage-Pfad sichert ueber cbb_qf_identitaet_* ausdruecklich
    -- DIESELBEN Zeilen (id UND slug, siehe die beiden
    -- "create table cbb_private_backup..."-Bloecke weiter unten); 04 sperrt spaeter
    -- Zeilenpaare ueber b.id = p.id and b.slug = p.slug, und 06 schreibt ueber
    -- die id zurueck. Der No-Op-Zweig verglich bisher nur Inhalte je slug. Ein
    -- Snapshot mit passendem Inhalt, aber fremder id waere damit still als
    -- gueltiger Rollback-Pfad durchgegangen, obwohl 06 ihn nirgends mehr
    -- zuordnen kann. Deshalb hier dieselbe Identitaetspruefung, fail-closed und
    -- VOR jedem fruehen RETURN.
    select count(*) into identitaet_produkte
    from cbb_private_backup.quality_fixes_20260830_products_v1 b
    join cbb_qf_identitaet_produkte i on i.id = b.id and i.slug = b.slug;

    select count(*) into identitaet_listen
    from cbb_private_backup.quality_fixes_20260830_lists_v1 b
    join cbb_qf_identitaet_listen i on i.id = b.id and i.slug = b.slug;

    if identitaet_produkte <> 7 or identitaet_listen <> 3 then
      raise exception 'QF-Backup abgebrochen: vorhandenes Backup beschreibt nicht dieselben Zeilen wie public.products/public.lists (Identitaet ueber id und slug: %/7 Produkte, %/3 Listen).',
        identitaet_produkte, identitaet_listen;
    end if;

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
      + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
          join cbb_qf_a4_kategorie e on e.slug = b.slug
         where b.shop_persona is not distinct from e.pre_persona
           and b.shop_main_category is not distinct from e.pre_main
           and b.shop_sub_category is not distinct from e.pre_sub
           and b.shop_tags is not distinct from e.pre_tags)
    into backup_produkt_pre;

    select count(*) into backup_listen_pre
    from cbb_private_backup.quality_fixes_20260830_lists_v1 b
    join cbb_qf_listen e on e.slug = b.slug
    where b.product_slugs is not distinct from e.pre_slugs;

    if backup_produkt_pre <> 7 or backup_listen_pre <> 3 then
      raise exception 'QF-Backup abgebrochen: vorhandenes Backup entspricht nicht dem bekannten Vorzustand (%/7 Produkte, %/3 Listen).',
        backup_produkt_pre, backup_listen_pre;
    end if;

    -- Der No-Op-Pfad muss denselben Rollback-Qualitaetsstandard erfuellen wie
    -- ein neu erzeugter Snapshot. Die fachlichen Vorwerte oben enthalten
    -- updated_at absichtlich nicht als Literal; deshalb ist der NULL-Guard
    -- separat und muss VOR dem fruehen RETURN stehen.
    select count(*) into updated_at_null
    from cbb_private_backup.quality_fixes_20260830_products_v1 b
    join cbb_qf_produkte g on g.slug = b.slug
    where 'updated_at' = any(g.geaenderte_spalten)
      and b.updated_at is null;
    if updated_at_null <> 0 then
      raise exception 'QF-Backup abgebrochen: vorhandenes Backup hat % der sechs lastmod-Zielprodukte mit updated_at IS NULL.',
        updated_at_null;
    end if;

    select c.relnamespace into backup_nsp
    from pg_class c
    where c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass;

    select count(*) into direkte_schemarechte
    from pg_namespace n
    cross join lateral aclexplode(
      coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
    ) as acl
    left join pg_roles r on r.oid = acl.grantee
    where n.oid = backup_nsp
      and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

    select count(*) into effektive_schemarechte
    from pg_roles r
    cross join (values ('USAGE'), ('CREATE')) as p(priv)
    where r.rolname in ('anon', 'authenticated', 'service_role')
      and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

    if direkte_schemarechte <> 0 or effektive_schemarechte <> 0 then
      raise exception 'QF-Backup abgebrochen: vorhandenes Backup-Schema unsicher (direkt %, effektiv %).',
        direkte_schemarechte, effektive_schemarechte;
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

      select count(*) into direkte_tabellenrechte
      from pg_class c
      cross join lateral aclexplode(
        coalesce(c.relacl, acldefault('r'::"char", c.relowner))
      ) as acl
      left join pg_roles r on r.oid = acl.grantee
      where c.oid = tabelle_oid
        and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

      select count(*) into effektive_tabellenrechte
      from pg_roles r
      cross join (values
        ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
        ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
      ) as p(priv)
      where r.rolname in ('anon', 'authenticated', 'service_role')
        and has_table_privilege(r.oid, tabelle_oid, p.priv::text);

      if rls_aktiv is not true or policies <> 0
         or direkte_tabellenrechte <> 0 or effektive_tabellenrechte <> 0 then
        raise exception 'QF-Backup abgebrochen: vorhandene Backup-Tabelle % unsicher (RLS=%, Policies=%, direkt %, effektiv %).',
          tabelle_oid::regclass, rls_aktiv, policies,
          direkte_tabellenrechte, effektive_tabellenrechte;
      end if;
    end loop;

    raise notice 'QF-Backup: identischer Snapshot bereits vorhanden — No-Op, nichts geschrieben.';
    return;
  end if;

  -- ---- 3. Snapshot neu anlegen -------------------------------------------
  select
    (select count(*) from public.products p
      join cbb_qf_b2 e on e.slug = p.slug
     where p.is_published is true
       and p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from public.products p
        join cbb_qf_b5_preis e on e.slug = p.slug
       where p.is_published is true and p.price_cents is null)
    + (select count(*) from public.products p
        join cbb_qf_b5_bilder e on e.slug = p.slug
       where p.is_published is true
         and p.image_url is not distinct from e.pre_image_url
         and p.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from public.products p
        join cbb_qf_d6 e on e.slug = p.slug
       where p.is_published is true
         and p.name is not distinct from e.pre_name
         and p.description is not distinct from e.pre_description
         and p.editorial_note is not distinct from e.pre_note)
    + (select count(*) from public.products p
        join cbb_qf_a4_kategorie e on e.slug = p.slug
       where p.is_published is true
         and p.shop_persona is not distinct from e.pre_persona
         and p.shop_main_category is not distinct from e.pre_main
         and p.shop_sub_category is not distinct from e.pre_sub
         and p.shop_tags is not distinct from e.pre_tags)
  into produkte_pre;

  select count(*) into listen_pre
  from public.lists l
  join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.pre_slugs;

  if produkte_pre <> 7 or listen_pre <> 3 then
    raise exception 'QF-Backup abgebrochen: Vorzustand weicht ab (%/7 Produkte, %/3 Listen im erwarteten Vorzustand).',
      produkte_pre, listen_pre;
  end if;

  select count(*) into identitaet_produkte from cbb_qf_identitaet_produkte;
  select count(*) into identitaet_listen   from cbb_qf_identitaet_listen;
  if identitaet_produkte <> 7 or identitaet_listen <> 3 then
    raise exception 'QF-Backup abgebrochen: %/7 Produkt- und %/3 Listen-Identitaetsanker gefunden.',
      identitaet_produkte, identitaet_listen;
  end if;

  -- READ COMMITTED: blockiert FOR UPDATE, wird nach dem fremden COMMIT auf der
  -- NEUEN Zeilenversion neu ausgewertet. Passt id/slug dann nicht mehr oder ist
  -- die Zeile geloescht, kommen hier weniger Zeilen zurueck.
  perform p.id
  from public.products p
  join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
  for update of p;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 7 then
    raise exception 'QF-Backup abgebrochen: %/7 Produktzeilen gesperrt (Identitaet passt nicht mehr).', gesperrt;
  end if;

  perform l.id
  from public.lists l
  join cbb_qf_identitaet_listen i on i.id = l.id and i.slug = l.slug
  for update of l;
  get diagnostics gesperrt = row_count;
  if gesperrt <> 3 then
    raise exception 'QF-Backup abgebrochen: %/3 Listenzeilen gesperrt (Identitaet passt nicht mehr).', gesperrt;
  end if;

  -- Neues Statement, neuer Snapshot: sieht jetzt garantiert den Stand, der
  -- unter dem Lock steht.
  select
    (select count(*) from public.products p
      join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
      join cbb_qf_b2 e on e.slug = p.slug
     where p.is_published is true
       and p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)
    + (select count(*) from public.products p
        join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
        join cbb_qf_b5_preis e on e.slug = p.slug
       where p.is_published is true and p.price_cents is null)
    + (select count(*) from public.products p
        join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
        join cbb_qf_b5_bilder e on e.slug = p.slug
       where p.is_published is true
         and p.image_url is not distinct from e.pre_image_url
         and p.image_urls is not distinct from e.pre_image_urls)
    + (select count(*) from public.products p
        join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
        join cbb_qf_d6 e on e.slug = p.slug
       where p.is_published is true
         and p.name is not distinct from e.pre_name
         and p.description is not distinct from e.pre_description
         and p.editorial_note is not distinct from e.pre_note)
    + (select count(*) from public.products p
        join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
        join cbb_qf_a4_kategorie e on e.slug = p.slug
       where p.is_published is true
         and p.shop_persona is not distinct from e.pre_persona
         and p.shop_main_category is not distinct from e.pre_main
         and p.shop_sub_category is not distinct from e.pre_sub
         and p.shop_tags is not distinct from e.pre_tags)
  into produkte_pre;

  select count(*) into listen_pre
  from public.lists l
  join cbb_qf_identitaet_listen i on i.id = l.id and i.slug = l.slug
  join cbb_qf_listen e on e.slug = l.slug
  where l.product_slugs is not distinct from e.pre_slugs;

  if produkte_pre <> 7 or listen_pre <> 3 then
    raise exception 'QF-Backup abgebrochen: Zielzeilen wurden zwischen Vorpruefung und Sperre veraendert (%/7 Produkte, %/3 Listen).',
      produkte_pre, listen_pre;
  end if;

  -- -------------------------------------------------------------------------
  -- Bei den sechs lastmod-Zielprodukten ist updated_at der Rollback-Wert: 06
  -- spielt genau ihn zurueck, und 04/05 belegen ueber "neu > alt", dass ein
  -- neues lastmod entstanden ist. Ein NULL-Zeitstempel macht beides
  -- unmoeglich. Die A4-Unterkategorie erhaelt bewusst kein neues lastmod und
  -- ist deshalb nicht Teil dieses Guards.
  -- -------------------------------------------------------------------------
  select count(*) into updated_at_null
  from public.products p
  join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
  join cbb_qf_produkte g on g.slug = p.slug
  where 'updated_at' = any(g.geaenderte_spalten)
    and p.updated_at is null;
  if updated_at_null <> 0 then
    raise exception 'QF-Backup abgebrochen: % der sechs lastmod-Zielprodukte haben updated_at IS NULL — der Snapshot waere als Rollback-Quelle wertlos.',
      updated_at_null;
  end if;

  -- Privates Backup-Schema. Es stammt aus frueheren Paketen und existiert in
  -- der Regel bereits; beide Anweisungen sind idempotent und stellen die
  -- Absicherung auch dann her, wenn das Schema hier neu entsteht.
  execute 'create schema if not exists cbb_private_backup';
  execute 'revoke all on schema cbb_private_backup from public, anon, authenticated';

  execute $ddl$
    create table cbb_private_backup.quality_fixes_20260830_products_v1 as
    select p.*
    from public.products p
    join cbb_qf_identitaet_produkte i on i.id = p.id and i.slug = p.slug
  $ddl$;

  execute $ddl$
    create table cbb_private_backup.quality_fixes_20260830_lists_v1 as
    select l.*
    from public.lists l
    join cbb_qf_identitaet_listen i on i.id = l.id and i.slug = l.slug
  $ddl$;

  execute 'alter table cbb_private_backup.quality_fixes_20260830_products_v1
             add primary key (id), add unique (slug), enable row level security';
  execute 'alter table cbb_private_backup.quality_fixes_20260830_lists_v1
             add primary key (id), add unique (slug), enable row level security';

  execute 'revoke all on cbb_private_backup.quality_fixes_20260830_products_v1
             from public, anon, authenticated';
  execute 'revoke all on cbb_private_backup.quality_fixes_20260830_lists_v1
             from public, anon, authenticated';

  -- service_role wird nur angesprochen, wenn die Rolle existiert. Auf einem
  -- Cluster ohne Supabase-Rollen wuerde ein statisches REVOKE mit
  -- "role does not exist" abbrechen.
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'revoke all on schema cbb_private_backup from service_role';
    execute 'revoke all on cbb_private_backup.quality_fixes_20260830_products_v1 from service_role';
    execute 'revoke all on cbb_private_backup.quality_fixes_20260830_lists_v1 from service_role';
  end if;

  -- ---- Nachbedingungen ---------------------------------------------------
  select count(*) into backup_produkt_zeilen
  from cbb_private_backup.quality_fixes_20260830_products_v1;
  select count(*) into backup_listen_zeilen
  from cbb_private_backup.quality_fixes_20260830_lists_v1;
  if backup_produkt_zeilen <> 7 or backup_listen_zeilen <> 3 then
    raise exception 'QF-Backup unvollstaendig: %/7 Produkt- und %/3 Listenzeilen.',
      backup_produkt_zeilen, backup_listen_zeilen;
  end if;

  -- Vollstaendiger Zeilenvergleich ueber to_jsonb: jede Spalte, nicht nur die
  -- spaeter geaenderten. Der FULL JOIN laeuft bewusst gegen die auf die sieben
  -- Zielzeilen eingegrenzte Menge, nicht gegen public.products insgesamt —
  -- sonst zaehlte jede Nichtzielzeile als "Backup-Zeile fehlt".
  select count(*) into drift
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  full join (
    select p.* from public.products p join cbb_qf_produkte g on g.slug = p.slug
  ) p on p.id = b.id and p.slug = b.slug
  where b.id is null or p.id is null
     or to_jsonb(p) is distinct from to_jsonb(b);
  if drift <> 0 then
    raise exception 'QF-Backup inkonsistent: % Abweichungen gegen public.products.', drift;
  end if;

  select count(*) into drift
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  full join (
    select l.* from public.lists l join cbb_qf_listen e on e.slug = l.slug
  ) l on l.id = b.id and l.slug = b.slug
  where b.id is null or l.id is null
     or to_jsonb(l) is distinct from to_jsonb(b);
  if drift <> 0 then
    raise exception 'QF-Backup inkonsistent: % Abweichungen gegen public.lists.', drift;
  end if;

  select c.relnamespace into backup_nsp
  from pg_class c
  where c.oid = 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass;

  select count(*) into direkte_schemarechte
  from pg_namespace n
  cross join lateral aclexplode(
    coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where n.oid = backup_nsp
    and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

  select count(*) into effektive_schemarechte
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  where r.rolname in ('anon', 'authenticated', 'service_role')
    and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

  if direkte_schemarechte <> 0 or effektive_schemarechte <> 0 then
    raise exception 'QF-Backup unsicher: Schemarechte fuer PUBLIC/anon/authenticated/service_role direkt %, effektiv %.',
      direkte_schemarechte, effektive_schemarechte;
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

    select count(*) into direkte_tabellenrechte
    from pg_class c
    cross join lateral aclexplode(
      coalesce(c.relacl, acldefault('r'::"char", c.relowner))
    ) as acl
    left join pg_roles r on r.oid = acl.grantee
    where c.oid = tabelle_oid
      and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));

    select count(*) into effektive_tabellenrechte
    from pg_roles r
    cross join (values
      ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
      ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
    ) as p(priv)
    where r.rolname in ('anon', 'authenticated', 'service_role')
      and has_table_privilege(r.oid, tabelle_oid, p.priv::text);

    if rls_aktiv is not true or policies <> 0
       or direkte_tabellenrechte <> 0 or effektive_tabellenrechte <> 0 then
      raise exception 'QF-Backup unsicher: Tabelle % (RLS=%, Policies=%, direkt %, effektiv %).',
        tabelle_oid::regclass, rls_aktiv, policies,
        direkte_tabellenrechte, effektive_tabellenrechte;
    end if;
  end loop;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: exakt 7 und 3.
select
  (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1)
    as backup_produkt_zeilen,
  (select count(*) from cbb_private_backup.quality_fixes_20260830_lists_v1)
    as backup_listen_zeilen;
