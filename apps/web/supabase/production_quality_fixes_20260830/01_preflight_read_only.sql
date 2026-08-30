-- ============================================================================
-- PRODUCTION QUALITY-FIXES 2026-08-30 — 01 READ-ONLY PREFLIGHT
-- ============================================================================
-- Zielprojekt ausserhalb von SQL sichtbar pruefen:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WOFUER DIESES PAKET DA IST
--   Es korrigiert genau fuenf belegte Produktionsbefunde (A4, A5, B2, B5, D6)
--   und nichts sonst:
--     A4  zwei Listen verweisen auf einen Produkt-Slug mit Schreibfehler
--         (verrueckte-amazon-gadgets Position 4, witzige-geschenke-maenner
--         Position 2). Die korrekten Produkte existieren, die Listeneintraege
--         zeigen ins Leere.
--         Derselbe Tippfehler hat eine siebte Produktzeile hinterlassen:
--         reassign_all_categories.sql Z. 144-162 stellt einen Block
--         ausdruecklich auf babo / tech / gadgets, fuehrt in seiner Slug-Liste
--         (Z. 158) aber den Tippfehler-Slug
--         plasmakugel-8-zoll-beruehlungsempfindlich. Das echte Produkt
--         plasmakugel-8-zoll-beruehrungsempfindlich wurde davon nie getroffen
--         und steht deshalb bis heute auf shop_sub_category = 'basteln'.
--         Korrigiert wird an dieser Zeile ausschliesslich shop_sub_category
--         -> 'gadgets'. Persona (babo), Hauptkategorie (tech) und shop_tags
--         bleiben unveraendert.
--     A5  geschenke-fuer-gamer traegt 16 statt 13 Eintraege: die letzten drei
--         sind exakte Wiederholungen der Positionen 11 bis 13
--         (Quelle: supabase/update_list_add_gamer_products.sql, zweimal gelaufen).
--     B2  drei Produkte stehen noch auf den Spaltendefaults
--         unknown / sonstiges / ungeordnet (Quelle: supabase/add_shop_fields.sql)
--         und tragen nur Preis-Tags, also keinen Persona-Tag.
--     B5  divoom-pixoo-led-panel hat keinen Preis; divoom-minitoo-... hat ein
--         einzelnes Nicht-Amazon-Bild.
--     D6  cream-noise-machine-baby-tragbar heisst in Name, Beschreibung und
--         Redaktionsnotiz "Cream Noise Machine" statt "White Noise Machine".
--
--   NICHT Teil dieses Pakets ist D7 (die beiden TOSY-Flying-Disc-Produkte).
--   Der Befund ist nach Repo-Audit KEIN Datenfehler, sondern eine bewusste
--   redaktionelle Variante. Belegt sind aus dem Repo: getrennte Slugs,
--   getrennte Preise (3599 / 2999), getrennte aktuelle Bilder
--   (51QWMABiNIL / 81vsAxy1YLL) und getrennte redaktionelle Einordnung
--   (babo/lifestyle/gadgets gegen miniboss/spass/outdoor, mit dem
--   ausdruecklichen Kommentar "Miniboss-Version" in
--   reassign_all_categories.sql Z. 752). Im Klartext belegt das Repo dagegen
--   nur EINE ASIN — B0B1YMNGS2 fuer die 108-RGB-Variante
--   (import_products_batch8.sql Z. 49); die zweite Zeile traegt dort nur einen
--   Amazon-Kurzlink. Von "zwei verschiedenen ASINs" wird deshalb nicht mehr
--   ausgegangen; die Trennung haengt nicht daran. Begruendung und Beleg stehen
--   in RUNBOOK.md, Abschnitt 6. Es gibt kein DML fuer D7, dieses Paket fasst
--   die beiden Zeilen nicht an.
--
-- FORM
--   Genau ein lesendes WITH ... SELECT. Kein DDL, kein DML, keine
--   Transaktionssteuerung, kein DO-Block. Nichts wird veraendert.
--
-- FAIL-CLOSED-RAENDER
--   * public.products und public.lists werden direkt referenziert. Fehlt eine
--     der beiden, bricht bereits die Planung ab.
--   * Die beiden Backup-Tabellen dieses Pakets duerfen hier noch NICHT
--     existieren und werden deshalb nur weich ueber to_regclass geprueft.
--   * Der deployte updated_at-Triggervertrag auf public.products wird gegen
--     den Systemkatalog geprueft (Sortierung 156). Fehlt er oder weicht er ab,
--     meldet diese Zeile FAIL — und Schritt 04 darf nicht laufen.
--
-- ERWARTETES ERGEBNIS: 29 Zeilen — 23 harte PASS-Zeilen (Sortierung 30 bis 220)
-- und 6 INFO-Zeilen (10, 20, 230 bis 260). Jede FAIL-Zeile ist ein Befund und
-- keine Freigabe fuer Schritt 02.
-- ============================================================================

with
production_tables(name) as (
  values ('products'), ('lists'), ('page_content'), ('discovery_queue'), ('swipes')
),

-- ---------------------------------------------------------------------------
-- B2 — erwarteter Vorzustand der drei unkategorisierten Produkte.
--   shop_persona / shop_main_category / shop_sub_category stehen auf den
--   Spaltendefaults aus supabase/add_shop_fields.sql.
--   shop_tags enthaelt ausschliesslich die bereits vorhandenen Preis-Tags.
--   Quelle der Preisbaender: die Preise aus supabase/products_update.sql
--   (3899 / 2999 / 1998 Cent) und die Bandlogik aus lib/db-types.ts.
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

-- ---------------------------------------------------------------------------
-- B5a — divoom-pixoo-led-panel: price_cents IS NULL, Ziel 4249 (42,49 EUR).
--   Quelle des Zielpreises: Amazon.de-Produktseite ASIN B07HHXWN3C, abgelesen
--   am 2026-08-30. Vor einer spaeteren Production-Ausfuehrung ist der Preis
--   laut RUNBOOK Abschnitt 4.2 unmittelbar erneut zu pruefen.
-- ---------------------------------------------------------------------------
b5_preis_erwartet(slug, ziel_price) as (
  values ('divoom-pixoo-led-panel'::text, 4249::integer)
),

-- ---------------------------------------------------------------------------
-- B5b — divoom-minitoo-...: ein Nicht-Amazon-Bild, Ziel sind neun am
--   2026-08-30 mit GET 200 / image/jpeg gepruefte Amazon-Bilder zu ASIN
--   B0FRF3XGQ4. image_url wird auf das erste Bild gesetzt.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- D6 — nur die drei Vorkommen von "Cream Noise Machine" werden ersetzt.
--   Der Slug bleibt absichtlich cream-noise-machine-baby-tragbar: die URL ist
--   indexiert, eine Slug-Aenderung waere ein SEO-Eingriff und kein Textfix.
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- A4 (Kategorie) — plasmakugel-8-zoll-beruehrungsempfindlich.
--   Vorzustand read-only auf Production verifiziert (2026-08-30):
--   babo / tech / basteln, shop_tags ['babo:tech','preis:unter50',
--   'preis:unter100'], is_published = true, updated_at 2026-07-04T00:00:00+00.
--   Repo-Beleg fuer die beabsichtigte Zielkategorie:
--   reassign_all_categories.sql Z. 144-162 (Block babo/tech/gadgets) mit dem
--   Tippfehler-Slug in Z. 158.
--   Geaendert wird NUR shop_sub_category. Persona, Hauptkategorie und Tags
--   bleiben Bestandteil der Vorzustandspruefung und damit unveraendert.
-- ---------------------------------------------------------------------------
a4_kategorie_erwartet(slug, pre_persona, pre_main, pre_sub, pre_tags, ziel_sub) as (
  values (
    'plasmakugel-8-zoll-beruehrungsempfindlich'::text,
    'babo'::text, 'tech'::text, 'basteln'::text,
    array['babo:tech','preis:unter50','preis:unter100']::text[],
    'gadgets'::text
  )
),

-- ---------------------------------------------------------------------------
-- A4 und A5 — die drei Listen, jeweils als vollstaendiges Array. Reihenfolge
-- ist Teil des Vergleichs: product_slugs ist ein geordnetes text[], die
-- Reihenfolge steuert die Anzeige auf der Listenseite.
-- ---------------------------------------------------------------------------
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

-- Die beiden Produkte, auf die die korrigierten Listeneintraege zeigen.
a4_zielprodukte(slug) as (
  values ('plasmakugel-8-zoll-beruehrungsempfindlich'::text),
         ('bug-a-salt-3-0-fliegenjaeger-salzgewehr')
),

-- Die beiden fehlerhaften Slugs. Sie sollten in products NICHT vorkommen —
-- genau deshalb sind die Listeneintraege tot. Nur INFO, kein Guard: ein
-- vorhandenes Produkt mit dem Fehler-Slug waere ein eigener, groesserer Befund
-- und wuerde diesen Fix nicht falsch machen.
a4_fehlerslugs(slug) as (
  values ('plasmakugel-8-zoll-beruehlungsempfindlich'::text),
         ('bug-a-salt-3-0-fliegenjager-salzgewehr')
),

alle_zielslugs(slug) as (
  select slug from b2_erwartet
  union all select slug from b5_preis_erwartet
  union all select slug from b5_bilder_erwartet
  union all select slug from d6_erwartet
  union all select slug from a4_kategorie_erwartet
),

-- Nur diese sechs Produktseiten erhalten in 04 ein neues lastmod. Die
-- A4-Unterkategorie wird nicht gerendert; ihr historisches updated_at bleibt
-- deshalb bewusst unveraendert.
lastmod_zielslugs(slug) as (
  select slug from b2_erwartet
  union all select slug from b5_preis_erwartet
  union all select slug from b5_bilder_erwartet
  union all select slug from d6_erwartet
),

fingerprint as (
  select
    current_user as ausfuehrende_rolle,
    current_database() as datenbank,
    (select count(*) from production_tables t
      where to_regclass('public.' || t.name) is not null)::integer
      as production_tabellen,
    (select count(*) from public.products)::bigint as produkte,
    (select count(*) from public.lists)::bigint as listen,
    (case when to_regclass('pilot_meta.environment_guard') is null then 0 else 1 end
      + case when to_regclass('pilot_backup.value_add_pre_backfill') is null then 0 else 1 end
      + case when to_regclass('public.pilot_value_add_backup_20260823') is null then 0 else 1 end
    )::integer as pilot_artefakte,
    to_regclass('cbb_private_backup.quality_fixes_20260830_products_v1')::text
      as backup_produkte,
    to_regclass('cbb_private_backup.quality_fixes_20260830_lists_v1')::text
      as backup_listen
),

ziel_state as (
  select
    (select count(*) from public.products p
      join alle_zielslugs z on z.slug = p.slug)::integer as zielprodukte,
    (select count(*) from public.products p
      join alle_zielslugs z on z.slug = p.slug
     where p.is_published is true)::integer as zielprodukte_published,
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug)::integer as ziellisten,
    (select count(*) from public.products p
      join a4_zielprodukte a on a.slug = p.slug)::integer as a4_produkte,
    (select count(*) from public.products p
      join a4_zielprodukte a on a.slug = p.slug
     where p.is_published is true)::integer as a4_produkte_published,
    (select count(*) from public.products p
      join a4_fehlerslugs a on a.slug = p.slug)::integer as a4_fehlerprodukte,
    -- Fail-closed-Vorbedingung fuer den lastmod-Nachweis in 04/05 und fuer den
    -- exakten Restore in 06: ein NULL-Zeitstempel liesse jeden spaeteren
    -- Vergleich "neu > alt" still auf NULL laufen, also weder wahr noch falsch.
    (select count(*) from public.products p
      join lastmod_zielslugs z on z.slug = p.slug
     where p.updated_at is not null)::integer as lastmod_zielprodukte_updated_at
),

vorzustand as (
  select
    (select count(*) from public.products p
      join b2_erwartet e on e.slug = p.slug
     where p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)::integer as b2_pre,
    (select count(*) from public.products p
      join b5_preis_erwartet e on e.slug = p.slug
     where p.price_cents is null)::integer as b5_preis_pre,
    (select count(*) from public.products p
      join b5_bilder_erwartet e on e.slug = p.slug
     where p.image_url is not distinct from e.pre_image_url
       and p.image_urls is not distinct from e.pre_image_urls)::integer
      as b5_bilder_pre,
    (select count(*) from public.products p
      join d6_erwartet e on e.slug = p.slug
     where p.name is not distinct from e.pre_name
       and p.description is not distinct from e.pre_description
       and p.editorial_note is not distinct from e.pre_note)::integer as d6_pre,
    (select count(*) from public.products p
      join a4_kategorie_erwartet e on e.slug = p.slug
     where p.shop_persona is not distinct from e.pre_persona
       and p.shop_main_category is not distinct from e.pre_main
       and p.shop_sub_category is not distinct from e.pre_sub
       and p.shop_tags is not distinct from e.pre_tags)::integer as a4_kat_pre,
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug
     where l.slug = 'verrueckte-amazon-gadgets'
       and l.product_slugs is not distinct from e.pre_slugs)::integer as l_verrueckte_pre,
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug
     where l.slug = 'witzige-geschenke-maenner'
       and l.product_slugs is not distinct from e.pre_slugs)::integer as l_witzige_pre,
    (select count(*) from public.lists l
      join listen_erwartet e on e.slug = l.slug
     where l.slug = 'geschenke-fuer-gamer'
       and l.product_slugs is not distinct from e.pre_slugs)::integer as l_gamer_pre
),

-- Zaehlt Zeilen, die BEREITS im Zielzustand stehen. Vor Schritt 04 muss das
-- ueberall 0 sein, sonst ist der Ausgangspunkt ein anderer als angenommen.
zielzustand as (
  select
    (select count(*) from public.products p
      join b2_erwartet e on e.slug = p.slug
     where p.shop_persona is not distinct from e.ziel_persona
       and p.shop_main_category is not distinct from e.ziel_main
       and p.shop_sub_category is not distinct from e.ziel_sub
       and p.shop_tags is not distinct from e.ziel_tags)::integer
    + (select count(*) from public.products p
        join b5_preis_erwartet e on e.slug = p.slug
       where p.price_cents is not distinct from e.ziel_price)::integer
    + (select count(*) from public.products p
        join b5_bilder_erwartet e on e.slug = p.slug
       where p.image_url is not distinct from e.ziel_image_url
         and p.image_urls is not distinct from e.ziel_image_urls)::integer
    + (select count(*) from public.products p
        join d6_erwartet e on e.slug = p.slug
       where p.name is not distinct from e.ziel_name
         and p.description is not distinct from e.ziel_description
         and p.editorial_note is not distinct from e.ziel_note)::integer
    + (select count(*) from public.products p
        join a4_kategorie_erwartet e on e.slug = p.slug
       where p.shop_persona is not distinct from e.pre_persona
         and p.shop_main_category is not distinct from e.pre_main
         and p.shop_sub_category is not distinct from e.ziel_sub
         and p.shop_tags is not distinct from e.pre_tags)::integer
    + (select count(*) from public.lists l
        join listen_erwartet e on e.slug = l.slug
       where l.product_slugs is not distinct from e.ziel_slugs)::integer
      as bereits_ziel
),

gamer_info as (
  select coalesce(
    (select array_length(l.product_slugs, 1)
     from public.lists l where l.slug = 'geschenke-fuer-gamer'), -1)::integer
    as gamer_laenge
),

-- ---------------------------------------------------------------------------
-- Der deployte updated_at-Triggervertrag auf public.products.
--
--   Zwei Zusagen dieses Pakets haengen nicht am Paket-SQL, sondern an einem
--   Vertrag, der auf der Zieldatenbank deployt ist
--   (supabase/seo_updated_at_trigger.sql):
--     * die sechs sichtbaren Produktseiten bekommen GENAU den Zeitstempel, den
--       04 ausdruecklich mitschreibt — der Trigger darf ihn nicht mit now()
--       ueberschreiben;
--     * die A4-Unterkategorie bekommt KEIN neues lastmod — shop_sub_category
--       darf keinen Zeitstempel-Bump ausloesen.
--   Beides ist auf Production nicht nachlesbar, sondern nur im Systemkatalog
--   nachweisbar. Deshalb wird hier der Katalog gelesen (pg_trigger, pg_proc,
--   pg_get_triggerdef, pg_get_functiondef) und nicht eine Repo-Datei.
--
--   Geprueft werden fuenf Groessen:
--     1. aktive_before_update_trigger  Auf public.products liegt genau EIN
--        nicht-interner, aktiver BEFORE UPDATE FOR EACH ROW Trigger. Mehr als
--        einer hiesse: ein zweiter, unbekannter Schreiber auf NEW.
--     2. vertragstrigger  Dieser eine Trigger heisst products_set_updated_at,
--        haengt an public.products_touch_updated_at, hat keine WHEN-Klausel und
--        traegt genau die erwartete Definition.
--     3. ohne_sub_category  Der von Block- und Zeilenkommentaren bereinigte
--        Funktionsrumpf nennt shop_sub_category nirgends. Damit kann die
--        A4-Aenderung keinen Bump ausloesen; ein reiner Pflegekommentar sperrt
--        den Preflight nicht.
--     4. explizit_gesetzt_bleibt  Der von Block- und Zeilenkommentaren
--        bereinigte Rumpf setzt updated_at genau einmal, und nur unter der
--        Bedingung, dass der Aufrufer die Spalte NICHT selbst geschrieben hat.
--        Guard, THEN, Zuweisung und END IF muessen in dieser Reihenfolge
--        stehen; sowohl := als auch = werden als PL/pgSQL-Zuweisungsoperator
--        gezaehlt. Gezaehlt wird OHNE Ruecksicht auf die Statementposition:
--        jedes new.updated_at := / = im bereinigten Rumpf ist ein Treffer,
--        egal ob es nach begin, then, else, loop oder einem Semikolon steht.
--        Ein Vergleich der Form  new.updated_at = ...  faellt dabei bewusst
--        mit in die Zaehlung — das ist fail-closed und sperrt hoechstens einen
--        ungewoehnlichen, aber harmlosen Rumpf, statt einen gefaehrlichen
--        durchzulassen.
--     5. fremde_updated_at_trigger  Keine andere aktive Triggerfunktion auf
--        public.products fasst updated_at ueberhaupt an.
--
--   Fehlt der Trigger, ist er abgeschaltet, zeigt er auf eine andere Funktion
--   oder weicht der Rumpf ab, faellt mindestens eine der fuenf Groessen aus
--   dem Soll und die Pruefzeile meldet FAIL. Das ist die Freigabesperre fuer
--   Schritt 04.
-- ---------------------------------------------------------------------------
trigger_roh as (
  select
    t.tgname::text as tgname,
    (t.tgtype & 1) <> 0 as fuer_jede_zeile,
    (t.tgtype & 2) <> 0 as vor_der_aenderung,
    (t.tgtype & 16) <> 0 as bei_update,
    t.tgqual is null as ohne_when_klausel,
    (p.pronamespace::regnamespace)::text || '.' || p.proname::text as funktion,
    pg_catalog.pg_get_triggerdef(t.oid) as triggerdef,
    pg_catalog.pg_get_functiondef(p.oid) as rohdef
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgenabled in ('O', 'A')
),

trigger_kandidaten as (
  select
    r.tgname,
    r.fuer_jede_zeile,
    r.vor_der_aenderung,
    r.bei_update,
    r.ohne_when_klausel,
    r.funktion,
    r.triggerdef,
    -- Block- und Zeilenkommentare raus, solange die Zeilenumbrueche noch da
    -- sind; erst danach Whitespace normalisieren. So kann Kommentartext weder
    -- einen Vertragsbeleg vortaeuschen noch shop_sub_category faelschlich als
    -- ausgefuehrten Code erscheinen lassen.
    --
    -- DIE REIHENFOLGE IST HIER DER GANZE PUNKT: ZUERST die Zeilenkommentare,
    -- DANACH die Blockkommentare. Umgekehrt liesse sich echter Code verstecken.
    -- Ein Rumpf mit
    --     -- Pflegehinweis: /*
    --     ...gefaehrlicher Code...
    --     -- Ende des Pflegehinweises: */
    -- enthaelt ein /* und ein */, die BEIDE nur Kommentartext sind. Wer erst
    -- Blockkommentare entfernt, loescht alles dazwischen — der gefaehrliche
    -- Code verschwindet aus der Pruefung und der Vertrag meldet faelschlich
    -- PASS. Wer erst die Zeilenkommentare entfernt, loescht beide Marker
    -- mitsamt ihrer Zeile; der Code dazwischen bleibt sichtbar und faellt auf.
    -- Der Negativfall setup_trigger_bumpt_sub_category.sql baut genau diese
    -- Falle nach.
    --
    -- Echte verschachtelte Blockkommentare deckt das absichtlich nicht ab: ein
    -- inneres */ beendet den Ausdruck hier zu frueh, es bleiben Reste stehen —
    -- und Reste lassen den Vertragscheck fehlschlagen, nicht durchgehen. Auch
    -- das ist fail-closed.
    regexp_replace(
      regexp_replace(
        regexp_replace(
          r.rohdef,
          '--[^\n\r]*',
          ' ',
          'g'
        ),
        '/\*([^*]|\*+[^*/])*\*+/',
        ' ',
        'g'
      ),
      '\s+',
      ' ',
      'g'
    ) as funktionsdef
  from trigger_roh r
),

-- Zaehlungen im bereinigten Rumpf. Bewusst ueber regexp_matches(..., 'g') in
-- einem LATERAL statt ueber regexp_count(): regexp_count gibt es erst ab
-- PostgreSQL 15. regexp_matches mit dem g-Flag ist seit Jahren vorhanden und
-- laeuft damit auch auf aelteren Supabase-Instanzen — ohne dass dieses Paket
-- eine Mindestversion voraussetzen muesste, die nirgends belegt ist.
-- Beide Zaehlungen sind read-only.
trigger_messung as (
  select
    k.*,
    z.anzahl as updated_at_zuweisungen,
    e.anzahl as end_if_bloecke
  from trigger_kandidaten k
  -- Jedes new.updated_at := / = im bereinigten Rumpf, unabhaengig davon, an
  -- welcher Statementposition es steht (begin, then, else, loop, nach einem
  -- Semikolon ...). Ein Vergleich  new.updated_at = ...  wird bewusst
  -- mitgezaehlt: fail-closed ist hier richtig.
  cross join lateral (
    select count(*)::integer as anzahl
    from pg_catalog.regexp_matches(
           k.funktionsdef,
           'new\.updated_at[[:space:]]*(:=|=)',
           'gi')
  ) z
  cross join lateral (
    select count(*)::integer as anzahl
    from pg_catalog.regexp_matches(
           k.funktionsdef,
           'end[[:space:]]+if;',
           'gi')
  ) e
),

trigger_vertrag as (
  select
    (select count(*) from trigger_messung
      where fuer_jede_zeile and vor_der_aenderung and bei_update)::integer
      as aktive_before_update_trigger,
    (select count(*) from trigger_messung
      where fuer_jede_zeile and vor_der_aenderung and bei_update
        and ohne_when_klausel
        and tgname = 'products_set_updated_at'
        and funktion = 'public.products_touch_updated_at'
        and triggerdef ~ ('BEFORE UPDATE ON (public\.)?products '
                          || 'FOR EACH ROW EXECUTE FUNCTION '
                          || '(public\.)?products_touch_updated_at\(\)$'))::integer
      as vertragstrigger,
    (select count(*) from trigger_messung
      where tgname = 'products_set_updated_at'
        and funktionsdef !~* 'shop_sub_category')::integer
      as ohne_sub_category,
    (select count(*) from trigger_messung
      where tgname = 'products_set_updated_at'
        -- Nicht nur Guard und Zuweisung irgendwo im Text finden: die einzige
        -- Zuweisung muss zwischen THEN und dem einzigen END IF desselben
        -- geordneten Guard-Blocks stehen. Kommentare sind oben entfernt.
        --
        -- Zwischen Guard und THEN steht ".*" fuer die zusaetzliche
        -- Tupelbedingung des echten Triggers. Sie darf auch LEER sein: der
        -- minimale gueltige Guard
        --   if new.updated_at is not distinct from old.updated_at
        --   then new.updated_at := now(); end if;
        -- muss ebenso PASS liefern wie die reale Funktion mit AND-Tupel.
        -- Deshalb steht das Trennzeichen vor THEN als eigene
        -- [[:space:]]-Klasse hinter dem ".*" und nicht als fester Anteil des
        -- Guard-Literals. Die verlangte Reihenfolge
        -- Guard -> THEN -> Zuweisung -> END IF bleibt dabei unveraendert hart.
        and funktionsdef ~* (
          'if new\.updated_at is not distinct from old\.updated_at'
          || '.*[[:space:]]then[[:space:]]+new\.updated_at[[:space:]]*(:=|=)'
          || '[[:space:]]*now\(\);[[:space:]]*end[[:space:]]+if;'
        )
        -- Genau eine Zuweisung im ganzen bereinigten Rumpf. Eine zweite,
        -- bedingungslose Zuweisung — auch in einer LOOP, einem ELSE-Zweig oder
        -- hinter einem Semikolon — hebt den Guard praktisch auf und muss
        -- deshalb sperren.
        and updated_at_zuweisungen = 1
        and end_if_bloecke = 1)::integer
      as explizit_gesetzt_bleibt,
    (select count(*) from trigger_messung
      where tgname <> 'products_set_updated_at'
        and funktionsdef ~* 'updated_at')::integer
      as fremde_updated_at_trigger
),

summary as (
  select *
  from fingerprint f
  cross join ziel_state z
  cross join vorzustand v
  cross join zielzustand zz
  cross join gamer_info g
  cross join trigger_vertrag tv
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
  select 90, 'backup_produkte_fehlt_noch', coalesce(backup_produkte, 'FEHLT'),
    'FEHLT vor Schritt 02',
    case when backup_produkte is null then 'PASS' else 'FAIL' end from summary
  union all
  select 100, 'backup_listen_fehlt_noch', coalesce(backup_listen, 'FEHLT'),
    'FEHLT vor Schritt 02',
    case when backup_listen is null then 'PASS' else 'FAIL' end from summary
  union all
  select 110, 'b2_vorzustand_unkategorisiert', b2_pre::text, '3',
    case when b2_pre = 3 then 'PASS' else 'FAIL' end from summary
  union all
  select 120, 'b5_preis_vorzustand_null', b5_preis_pre::text, '1',
    case when b5_preis_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 130, 'b5_bilder_vorzustand_einzelbild', b5_bilder_pre::text, '1',
    case when b5_bilder_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 140, 'd6_vorzustand_cream', d6_pre::text, '1',
    case when d6_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 145, 'a4_kategorie_vorzustand_basteln', a4_kat_pre::text, '1',
    case when a4_kat_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 150, 'produkte_vorzustand_gesamt',
    (b2_pre + b5_preis_pre + b5_bilder_pre + d6_pre + a4_kat_pre)::text, '7',
    case when (b2_pre + b5_preis_pre + b5_bilder_pre + d6_pre + a4_kat_pre) = 7
      then 'PASS' else 'FAIL' end from summary
  union all
  select 155, 'lastmod_zielprodukte_updated_at_nicht_null',
    lastmod_zielprodukte_updated_at::text, '6',
    case when lastmod_zielprodukte_updated_at = 6 then 'PASS' else 'FAIL' end from summary
  union all
  -- Der deployte Triggervertrag. Read-only aus dem Systemkatalog gelesen, nicht
  -- aus einer Repo-Datei geschlossen. FAIL heisst: 04 darf nicht laufen.
  select 156, 'products_updated_at_triggervertrag',
    'aktive BEFORE UPDATE ROW Trigger=' || aktive_before_update_trigger::text
      || ', vertragskonform=' || vertragstrigger::text
      || ', ohne shop_sub_category=' || ohne_sub_category::text
      || ', explizites updated_at bleibt=' || explizit_gesetzt_bleibt::text
      || ', fremde updated_at-Trigger=' || fremde_updated_at_trigger::text,
    '1, 1, 1, 1, 0',
    case when aktive_before_update_trigger = 1
           and vertragstrigger = 1
           and ohne_sub_category = 1
           and explizit_gesetzt_bleibt = 1
           and fremde_updated_at_trigger = 0
      then 'PASS' else 'FAIL' end from summary
  union all
  select 160, 'a4_liste_verrueckte_vorzustand', l_verrueckte_pre::text, '1',
    case when l_verrueckte_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 170, 'a4_liste_witzige_vorzustand', l_witzige_pre::text, '1',
    case when l_witzige_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 180, 'a5_liste_gamer_vorzustand', l_gamer_pre::text, '1',
    case when l_gamer_pre = 1 then 'PASS' else 'FAIL' end from summary
  union all
  select 190, 'listen_vorzustand_gesamt',
    (l_verrueckte_pre + l_witzige_pre + l_gamer_pre)::text, '3',
    case when (l_verrueckte_pre + l_witzige_pre + l_gamer_pre) = 3
      then 'PASS' else 'FAIL' end from summary
  union all
  select 200, 'a4_zielprodukte_je_einmal_vorhanden', a4_produkte::text, '2',
    case when a4_produkte = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 210, 'a4_zielprodukte_published', a4_produkte_published::text, '2',
    case when a4_produkte_published = 2 then 'PASS' else 'FAIL' end from summary
  union all
  select 220, 'noch_keine_zeile_im_zielzustand', bereits_ziel::text, '0',
    case when bereits_ziel = 0 then 'PASS' else 'FAIL' end from summary
  union all
  select 230, 'a4_fehlerslugs_als_produkt', a4_fehlerprodukte::text,
    'INFO: 0 belegt, dass die beiden Listeneintraege ins Leere zeigen', 'INFO'
  from summary
  union all
  select 240, 'listen_gesamt', listen::text, 'INFO', 'INFO' from summary
  union all
  select 250, 'a5_gamer_liste_laenge_aktuell', gamer_laenge::text,
    'INFO: 16 vor der Korrektur, 13 danach', 'INFO'
  from summary
  union all
  select 260, 'd7_tosy_flying_disc',
    'nicht Teil dieses Pakets, kein DML',
    'INFO: bewusste redaktionelle Variante — getrennte Slugs, Preise, Bilder '
      || 'und Einordnung; das Repo belegt nur eine ASIN. Siehe RUNBOOK Abschnitt 6',
    'INFO'
  from summary
)
select pruefung, ist, erwartet, status
from checks
order by sortierung;
