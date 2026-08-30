-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 05 READ-ONLY ABSCHLUSSPRUEFUNG
-- ============================================================================
-- Laeuft NACH 04_apply_quality_fixes.sql.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein DDL, kein DML, keine
--   Transaktionssteuerung, kein DO-Block. Nichts wird veraendert.
--
-- FAIL CLOSED
--   public.products, public.lists und beide Backup-Tabellen werden direkt
--   referenziert. Fehlt eine davon, bricht bereits die Planung ab.
--
-- WAS DIESE DATEI BEWEIST
--   1. Alle zehn Zielzeilen stehen exakt im Zielzustand.
--   2. Keine der zehn Zeilen wurde ausserhalb der erlaubten Spalten veraendert
--      — geprueft ueber den vollstaendigen Zeilenvergleich gegen das Backup,
--      abzueglich genau der Spalten, die 04 aendern durfte.
--   3. Die sechs sichtbar geaenderten Produktseiten tragen ein neues lastmod;
--      die nicht gerenderte A4-Unterkategorie behaelt ihren Zeitstempel.
--   4. Das Backup ist unveraendert und damit weiterhin ein gueltiger
--      Rollback-Pfad.
--   5. Die beiden fehlerhaften Slugs stehen in keiner der drei Listen mehr,
--      und die beiden korrekten Zielprodukte existieren je genau einmal und
--      published.
--
--   Was diese Datei NICHT beweist: dass keine andere Zeile der Tabellen
--   veraendert wurde. Dieser Nachweis ist nur innerhalb der Transaktion von 04
--   moeglich (Nachbedingungen 6 und 7 dort) und wird hier nicht wiederholt.
--
-- ERWARTETES ERGEBNIS: 28 Zeilen — 23 harte PASS-Zeilen (Sortierung 30 bis 240)
-- und 5 INFO-Zeilen (10, 20, 300, 310, 320). Jede FAIL-Zeile ist ein Befund.
-- ============================================================================

with
production_tables(name) as (
  values ('products'), ('lists'), ('page_content'), ('discovery_queue'), ('swipes')
),

-- ---------------------------------------------------------------------------
-- Vorzustand und Zielzustand — dieselben Literale wie in 01 bis 04 und 06.
-- ---------------------------------------------------------------------------
b2_erwartet(slug, pre_persona, pre_main, pre_sub, pre_tags, ziel_persona, ziel_main, ziel_sub, ziel_tags) as (
  values
    ('fingerabdruck-vorhaengeschloss-eseesmart'::text,
     'unknown'::text, 'sonstiges'::text, 'ungeordnet'::text,
     array['preis:unter50','preis:unter100']::text[],
     'babo'::text, 'tech'::text, 'gadgets'::text,
     array['babo:tech','preis:unter50','preis:unter100']::text[]),
    ('flauschige-handschuhe-weihnachten',
     'unknown', 'sonstiges', 'ungeordnet',
     array['preis:unter50','preis:unter100']::text[],
     'queen', 'lifestyle', 'mode',
     array['queen:lifestyle','preis:unter50','preis:unter100']::text[]),
    ('pizza-socks-box-pepperoni',
     'unknown', 'sonstiges', 'ungeordnet',
     array['preis:unter20','preis:unter50','preis:unter100']::text[],
     'queen', 'lifestyle', 'mode',
     array['queen:lifestyle','preis:unter20','preis:unter50','preis:unter100']::text[])
),
b5_preis_erwartet(slug, ziel_price) as (
  values ('divoom-pixoo-led-panel'::text, 4249::integer)
),
b5_bilder_erwartet(slug, pre_image_url, pre_image_urls, ziel_image_url, ziel_image_urls) as (
  values (
    'divoom-minitoo-retro-pc-lautsprecher-pixel'::text,
    'https://divoom.com/cdn/shop/files/minitoo-1.jpg'::text,
    array['https://divoom.com/cdn/shop/files/minitoo-1.jpg']::text[],
    'https://m.media-amazon.com/images/I/717Wh8lpS2L._AC_SL1500_.jpg'::text,
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
    ]::text[]
  )
),
d6_erwartet(slug, pre_name, ziel_name, pre_description, ziel_description, pre_note, ziel_note) as (
  values (
    'cream-noise-machine-baby-tragbar'::text,
    'Cream Noise Machine Baby Tragbar'::text,
    'White Noise Machine Baby Tragbar'::text,
    'Tragbare Cream Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.'::text,
    'Tragbare White Noise Machine für Kinderwagen, Auto oder Reisen. Klein, wiederaufladbar via USB, mehrere Sound-Modi (weißes Rauschen, Regen, Herzschlag). Karabinerhaken für Kinderwagen. Für Eltern, die gemerkt haben: Schlaf des Babys = Ruhe des Hauses. Basic für unterwegs-schlafende Kinder.'::text,
    'Die tragbare Cream-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.'::text,
    'Die tragbare White-Noise-Machine für Kinderwagen, Auto oder Reise. Klein, wiederaufladbar, mehrere Geräusche. Für alle, die gemerkt haben, dass Schlaf des Babys = Ruhe der Eltern = Frieden im Haus.'::text
  )
),
-- A4 (Kategorie) — die siebte Produktzeile. Persona, Hauptkategorie und Tags
-- sind Vorwerte und muessen unveraendert sein; geaendert wurde nur
-- shop_sub_category 'basteln' -> 'gadgets'.
a4_kategorie_erwartet(slug, pre_persona, pre_main, pre_sub, pre_tags, ziel_sub) as (
  values (
    'plasmakugel-8-zoll-beruehrungsempfindlich'::text,
    'babo'::text, 'tech'::text, 'basteln'::text,
    array['babo:tech','preis:unter50','preis:unter100']::text[],
    'gadgets'::text
  )
),
listen_erwartet(slug, pre_slugs, ziel_slugs) as (
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
    ]::text[],
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
    ]::text[],
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
    ]::text[],
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
    ]::text[]
  )
),

-- Die Spalten, die 04 an der jeweiligen Zielzeile aendern darf. Alles andere
-- muss dem Backup entsprechen.
produkt_spalten(slug, geaenderte_spalten) as (
  values
    ('fingerabdruck-vorhaengeschloss-eseesmart'::text,
     array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']::text[]),
    ('flauschige-handschuhe-weihnachten',
     array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']::text[]),
    ('pizza-socks-box-pepperoni',
     array['shop_persona','shop_main_category','shop_sub_category','shop_tags','updated_at']::text[]),
    ('divoom-pixoo-led-panel',
     array['price_cents','updated_at']::text[]),
    ('divoom-minitoo-retro-pc-lautsprecher-pixel',
     array['image_url','image_urls','updated_at']::text[]),
    ('cream-noise-machine-baby-tragbar',
     array['name','description','editorial_note','updated_at']::text[]),
    ('plasmakugel-8-zoll-beruehrungsempfindlich',
     array['shop_sub_category']::text[])
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
    )::integer as pilot_artefakte
),

mengen as (
  select
    (select count(*) from public.products p
      join produkt_spalten g on g.slug = p.slug)::integer as zielprodukte,
    (select count(*) from public.products p
      join produkt_spalten g on g.slug = p.slug
     where p.is_published is true)::integer as zielprodukte_published,
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug)::integer as ziellisten
),

zielzustand as (
  select
    (select count(*) from public.products p join b2_erwartet e on e.slug = p.slug
     where p.shop_persona is not distinct from e.ziel_persona
       and p.shop_main_category is not distinct from e.ziel_main
       and p.shop_sub_category is not distinct from e.ziel_sub
       and p.shop_tags is not distinct from e.ziel_tags)::integer as b2_ziel,
    (select count(*) from public.products p join b5_preis_erwartet e on e.slug = p.slug
     where p.price_cents is not distinct from e.ziel_price)::integer as b5_preis_ziel,
    (select count(*) from public.products p join b5_bilder_erwartet e on e.slug = p.slug
     where p.image_url is not distinct from e.ziel_image_url
       and p.image_urls is not distinct from e.ziel_image_urls)::integer as b5_bilder_ziel,
    (select count(*) from public.products p join d6_erwartet e on e.slug = p.slug
     where p.name is not distinct from e.ziel_name
       and p.description is not distinct from e.ziel_description
       and p.editorial_note is not distinct from e.ziel_note)::integer as d6_ziel,
    (select count(*) from public.products p join a4_kategorie_erwartet e on e.slug = p.slug
     where p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.ziel_sub
       and p.shop_tags is not distinct from e.pre_tags)::integer as a4_kat_ziel,
    (select count(*) from public.lists l join listen_erwartet e on e.slug = l.slug
     where l.product_slugs is not distinct from e.ziel_slugs)::integer as listen_ziel
),

restvorzustand as (
  select
    (
      (select count(*) from public.products p join b2_erwartet e on e.slug = p.slug
       where p.shop_persona is not distinct from e.pre_persona
         and p.shop_main_category is not distinct from e.pre_main
         and p.shop_sub_category is not distinct from e.pre_sub
         and p.shop_tags is not distinct from e.pre_tags)
      + (select count(*) from public.products p join b5_preis_erwartet e on e.slug = p.slug
         where p.price_cents is null)
      + (select count(*) from public.products p join b5_bilder_erwartet e on e.slug = p.slug
         where p.image_url is not distinct from e.pre_image_url
           and p.image_urls is not distinct from e.pre_image_urls)
      + (select count(*) from public.products p join d6_erwartet e on e.slug = p.slug
         where p.name is not distinct from e.pre_name
           and p.description is not distinct from e.pre_description
           and p.editorial_note is not distinct from e.pre_note)
      + (select count(*) from public.products p join a4_kategorie_erwartet e on e.slug = p.slug
         where p.shop_persona is not distinct from e.pre_persona
           and p.shop_main_category is not distinct from e.pre_main
           and p.shop_sub_category is not distinct from e.pre_sub
           and p.shop_tags is not distinct from e.pre_tags)
      + (select count(*) from public.lists l join listen_erwartet e on e.slug = l.slug
         where l.product_slugs is not distinct from e.pre_slugs)
    )::integer as noch_vorzustand
),

-- Vollstaendiger Zeilenvergleich gegen das Backup, abzueglich genau der
-- Spalten, die 04 aendern durfte.
unveraendert as (
  select
    (select count(*)
     from public.products p
     join cbb_private_backup.quality_fixes_20260830_products_v1 b
       on b.id = p.id and b.slug = p.slug
     join produkt_spalten g on g.slug = p.slug
     where to_jsonb(p) - g.geaenderte_spalten
           is not distinct from to_jsonb(b) - g.geaenderte_spalten)::integer
      as produkte_sonst_gleich,
    (select count(*)
     from public.lists l
     join cbb_private_backup.quality_fixes_20260830_lists_v1 b
       on b.id = l.id and b.slug = l.slug
     where to_jsonb(l) - array['product_slugs']
           is not distinct from to_jsonb(b) - array['product_slugs'])::integer
      as listen_sonst_gleich,
    (select count(*)
     from public.products p
     join cbb_private_backup.quality_fixes_20260830_products_v1 b on b.id = p.id
     join produkt_spalten g on g.slug = p.slug
     where 'updated_at' = any(g.geaenderte_spalten)
       and p.updated_at > b.updated_at)::integer as lastmod_neu
),

backup_zustand as (
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
      + (select count(*) from cbb_private_backup.quality_fixes_20260830_products_v1 b
          join a4_kategorie_erwartet e on e.slug = b.slug
         where b.shop_persona is not distinct from e.pre_persona
           and b.shop_main_category is not distinct from e.pre_main
           and b.shop_sub_category is not distinct from e.pre_sub
           and b.shop_tags is not distinct from e.pre_tags)
    )::integer as backup_produkte_pre,
    (select count(*) from cbb_private_backup.quality_fixes_20260830_lists_v1 b
      join listen_erwartet e on e.slug = b.slug
     where b.product_slugs is not distinct from e.pre_slugs)::integer
      as backup_listen_pre
),

slug_zustand as (
  select
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug
     where l.product_slugs
           && array['plasmakugel-8-zoll-beruehlungsempfindlich',
                    'bug-a-salt-3-0-fliegenjager-salzgewehr'])::integer
      as fehlerslugs_in_listen,
    (select count(*) from public.products p
      where p.slug in ('plasmakugel-8-zoll-beruehrungsempfindlich',
                       'bug-a-salt-3-0-fliegenjaeger-salzgewehr')
        and p.is_published is true)::integer as a4_zielprodukte_published,
    coalesce((select array_length(l.product_slugs, 1)
              from public.lists l where l.slug = 'geschenke-fuer-gamer'), -1)::integer
      as gamer_laenge,
    coalesce((select count(distinct t.s)
              from public.lists l
              cross join lateral unnest(l.product_slugs) as t(s)
              where l.slug = 'geschenke-fuer-gamer'), -1)::integer
      as gamer_eindeutig,
    (select count(*) from public.products p
      where p.slug = 'cream-noise-machine-baby-tragbar'
        and (p.name like '%Cream Noise%'
          or p.description like '%Cream Noise%'
          or p.editorial_note like '%Cream-Noise%'
          or p.editorial_note like '%Cream Noise%'))::integer as d6_restbestand
),

summary as (
  select *
  from fingerprint
  cross join mengen
  cross join zielzustand
  cross join restvorzustand
  cross join unveraendert
  cross join backup_zustand
  cross join slug_zustand
),

checks as (
  select 10 as sortierung, 'ausfuehrende_rolle' as pruefung,
    ausfuehrende_rolle::text as ist, 'INFO' as erwartet, 'INFO' as status
  from summary
  union all
  select 20, 'datenbank', datenbank::text, 'INFO', 'INFO' from summary
  union all
  select 30, 'production_tabellen', production_tabellen::text, '5',
    case when production_tabellen = 5 then 'PASS' else 'FAIL' end from summary
  union all
  select 40, 'produkte_mindestens_300', produkte::text, '>= 300',
    case when produkte >= 300 then 'PASS' else 'FAIL' end from summary
  union all
  select 50, 'pilot_artefakte', pilot_artefakte::text, '0',
    case when pilot_artefakte = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 60, 'zielprodukte_vorhanden', zielprodukte::text, '7',
    case when zielprodukte = 7 then 'PASS' else 'FAIL' end from summary
  union all
  select 70, 'zielprodukte_published', zielprodukte_published::text, '7',
    case when zielprodukte_published = 7 then 'PASS' else 'FAIL' end from summary
  union all
  select 80, 'ziellisten_vorhanden', ziellisten::text, '3',
    case when ziellisten = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 90, 'b2_zielzustand_kategorisiert', b2_ziel::text, '3',
    case when b2_ziel = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'b5_preis_zielzustand_4249', b5_preis_ziel::text, '1',
    case when b5_preis_ziel = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'b5_bilder_zielzustand_neun_amazon', b5_bilder_ziel::text, '1',
    case when b5_bilder_ziel = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'd6_zielzustand_white_noise', d6_ziel::text, '1',
    case when d6_ziel = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 125, 'a4_kategorie_zielzustand_gadgets', a4_kat_ziel::text, '1',
    case when a4_kat_ziel = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'produkte_zielzustand_gesamt',
    (b2_ziel + b5_preis_ziel + b5_bilder_ziel + d6_ziel + a4_kat_ziel)::text, '7',
    case when (b2_ziel + b5_preis_ziel + b5_bilder_ziel + d6_ziel + a4_kat_ziel) = 7
      then 'PASS' else 'FAIL' end from summary
  union all
  select 140, 'listen_zielzustand_gesamt', listen_ziel::text, '3',
    case when listen_ziel = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'kein_vorzustand_mehr', noch_vorzustand::text, '0',
    case when noch_vorzustand = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 160, 'zielprodukte_sonst_wie_backup', produkte_sonst_gleich::text, '7',
    case when produkte_sonst_gleich = 7 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'ziellisten_sonst_wie_backup', listen_sonst_gleich::text, '3',
    case when listen_sonst_gleich = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 180, 'lastmod_neu', lastmod_neu::text, '6',
    case when lastmod_neu = 6 then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'backup_produkte_unveraendert', backup_produkte_pre::text, '7',
    case when backup_produkte_pre = 7 then 'PASS' else 'FAIL' end from summary
  union all
  select 200, 'backup_listen_unveraendert', backup_listen_pre::text, '3',
    case when backup_listen_pre = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 210, 'a4_fehlerslugs_in_ziellisten', fehlerslugs_in_listen::text, '0',
    case when fehlerslugs_in_listen = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 220, 'a4_zielprodukte_published', a4_zielprodukte_published::text, '2',
    case when a4_zielprodukte_published = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 230, 'a5_gamer_13_eintraege_eindeutig',
    gamer_laenge::text || ' Eintraege, davon eindeutig ' || gamer_eindeutig::text,
    '13 Eintraege, davon eindeutig 13',
    case when gamer_laenge = 13 and gamer_eindeutig = 13
      then 'PASS' else 'FAIL' end from summary
  union all
  select 240, 'd6_kein_cream_noise_mehr', d6_restbestand::text, '0',
    case when d6_restbestand = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 300, 'a5_gamer_liste_laenge', gamer_laenge::text,
    'INFO: 16 vor der Korrektur, 13 danach', 'INFO'
  from summary
  union all
  select 310, 'd7_tosy_flying_disc', 'nicht Teil dieses Pakets',
    'INFO: bewusste redaktionelle Trennung zweier ASINs, siehe RUNBOOK Abschnitt 6',
    'INFO'
  from summary
  union all
  select 320, 'b5_preisquelle',
    'Amazon.de ASIN B07HHXWN3C, 42,49 EUR, abgelesen 2026-08-30',
    'INFO: Preis ist tagesaktuell, siehe RUNBOOK Abschnitt 4.2', 'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
