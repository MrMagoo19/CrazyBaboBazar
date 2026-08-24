-- ============================================================================
-- PRODUCTION VALUE-ADD — 04 ATOMARER BACKFILL (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
-- project/ydiihvzcxaaoqhmgoqvu
--
-- Bewusste Content-Overwrites bei bereits vorhandener editorial_note:
--   ninja-staysharp-messerset-6-teilig
--   n4-nussmilchbereiter-pflanzenmilch
--   welpen-usb-ladekabel-hunde-design
-- Die vorherigen Texte und updated_at-Werte liegen im privaten Snapshot v1.
-- divoom-pixoo-led-panel: price_cents bleibt unveraendert NULL.
-- n4: der Zeitwiderspruch in tagline/description bleibt bewusst unangetastet.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  product_rows bigint;
  target_rows integer;
  relation_rows integer;
  backup_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Production-Backfill abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Production-Backfill abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Production-Backfill abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
  from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led',
    'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147',
    'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch',
    'welpen-usb-ladekabel-hunde-design'
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Production-Backfill abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  select count(*) into relation_rows
  from public.products
  where slug in (
    'ifixit-antistatik-matte-faltbar-esd',
    'divoom-minitoo-retro-pc-lautsprecher-pixel',
    'derayee-schaumstoff-wasserpistole',
    'aeropress-go-tragbare-kaffeemaschine',
    'cbdywvr-2in1-ladekabel-mit-staender'
  ) and is_published is true;
  if relation_rows <> 5 then
    raise exception 'Production-Backfill abgebrochen: %/5 Relationsziele published.', relation_rows;
  end if;

  select count(*) into column_rows
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );
  select count(*) into correct_types
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and (
      (column_name in (
        'fuer_wen', 'nicht_fuer', 'key_fact', 'alternative_slug',
        'alternative_reason', 'alternative_kind'
      ) and data_type = 'text' and udt_name = 'text')
      or
      (column_name in ('pros', 'cons')
        and data_type = 'ARRAY' and udt_name = '_text')
    );
  select count(*) into constraint_rows
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );
  if column_rows <> 8 or correct_types <> 8 or constraint_rows <> 2 then
    raise exception 'Production-Backfill abgebrochen: Migration unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Production-Backfill abgebrochen: privater Snapshot v1 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  if backup_rows <> 10 then
    raise exception 'Production-Backfill abgebrochen: Snapshot hat %/10 Zeilen.', backup_rows;
  end if;
end $$;

-- Sperrt exakt die Snapshot-Zeilen und verhindert einen parallelen Drift.
do $$
declare
  locked_rows integer;
  drift_rows integer;
begin
  perform p.id
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Production-Backfill abgebrochen: nur %/10 Zielzeilen gesperrt.', locked_rows;
  end if;

  select count(*) into drift_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind;
  if drift_rows <> 0 then
    raise exception 'Production-Backfill abgebrochen: % Zielzeilen sind seit dem Snapshot gedriftet.',
      drift_rows;
  end if;
end $$;

create temporary table cbb_value_add_payload (
  slug text primary key,
  fuer_wen text not null,
  nicht_fuer text not null,
  key_fact text not null,
  pros text[] not null,
  cons text[] not null,
  alternative_slug text,
  alternative_reason text,
  alternative_kind text,
  editorial_note text not null
) on commit drop;

insert into cbb_value_add_payload (
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
) values
(
  'pinecil-usbc-loetkolben',
  'Maker, Reparatur-Fans und alle, die unterwegs an der Powerbank löten wollen.',
  'Wer nur einmal im Jahr ein Kabel flickt — dafür ist das Feature-Set zu viel.',
  '30 g, USB-C-betrieben, in 6 Sekunden auf Temperatur, Genauigkeit 1 °C.',
  array['In 6 Sekunden heiß','Läuft an jeder USB-C-Quelle oder Powerbank','Open-Source-Firmware, erweiterbar','Automatischer Schlafmodus'],
  array['Eigene USB-C-Stromquelle nötig','Volles Potenzial erst nach Firmware-Setup'],
  'ifixit-antistatik-matte-faltbar-esd',
  'Beim Löten und Reparieren schützt die faltbare ESD-Matte Bauteile und Tisch vor statischer Entladung — der natürliche Begleiter.',
  'complement',
  'In die Hosentasche und trotzdem ernst zu nehmen: USB-C rein, sechs Sekunden warten, löten. Open-Source heißt, er wird eher besser als schlechter. Für alle, die reparieren statt wegwerfen.'
),
(
  'divoom-pixoo-led-panel',
  'Wer Schreibtisch oder Stream mit Pixel-Art, Uhr oder Spotify-Visualizer aufwerten will.',
  'Wer ein hochauflösendes Info-Display erwartet — 16×16 ist bewusst grob.',
  '16×16-Pixel-LED-Panel, komplett per App konfigurierbar.',
  array['Zeigt Pixel-Art, GIFs, Uhr, Spotify-Visualizer und Benachrichtigungen','Alles per App steuerbar','Starker Retro- und Arcade-Look'],
  array['Nur 16×16 Pixel — für Text oder Details ungeeignet','Funktion hängt an der Hersteller-App'],
  'divoom-minitoo-retro-pc-lautsprecher-pixel',
  'Ebenfalls ein konfigurierbares Pixel-Display fürs Desk-Setup, zusätzlich mit Lautsprecher — wenn du Pixel-Anzeige und Sound kombinieren willst.',
  'alternative',
  'Reines Deko-mit-Funktion: ein Pixel-Display, das den Schreibtisch nach Arcade aussehen lässt und nebenbei die Uhrzeit oder den Spotify-Track zeigt. Kein Tool, ein Stimmungsmacher.'
),
(
  'sculpfun-s9-laser-engraver',
  'Bastler und Kleingewerbe, die Holz, Acryl oder Leder gravieren wollen — ohne Profi-Budget.',
  'Wer nur gelegentlich ein Schild braucht; Einarbeitung und Platzbedarf lohnen sich dann nicht.',
  'Graviert Holz, Acryl, Leder und anodisiertes Aluminium, 90 W Spitzenleistung.',
  array['Deckt viele Materialien ab','Läuft mit Open-Source-Software (LaserGRBL, LightBurn)','Aufbau in rund 20 Minuten','Maker-Einstieg ohne 5-stelliges Budget'],
  array['Braucht einen festen, belüfteten Arbeitsplatz','Arbeiten mit Laser erfordert Schutzbrille und Vorsicht'],
  null, null, null,
  'Der Einstieg für alle, die eigene Sachen gravieren wollen, ohne eine Werkstatt zu finanzieren. Viele Materialien, offene Software, überschaubarer Aufbau. Laser bleibt Laser — Schutz gehört dazu.'
),
(
  'arc-reaktor-mk1-schwebend',
  'Marvel- und Iron-Man-Fans, die ein Hingucker-Objekt für den Schreibtisch wollen.',
  'Wer ein funktionales Gadget sucht — das hier ist reine Deko.',
  'Magnetisch schwebende und rotierende 1:1-Replika mit film-getreuer LED.',
  array['Schwebt und rotiert magnetisch','1:1-Größe mit film-getreuer LED','Für Dauerbetrieb ausgelegt'],
  array['Reine Deko ohne Zusatzfunktion','Magnetschwebe braucht einen stabilen, erschütterungsarmen Standort'],
  null, null, null,
  'Ein Angeber-Objekt im besten Sinn: schwebt, dreht sich, leuchtet wie im Film. Nützlich ist nichts daran — beeindruckend alles. Für die Ecke des Schreibtischs, auf die Gäste sofort zeigen.'
),
(
  'elektrische-wasserpistole-mit-led',
  'Alle, die Wasserkämpfe ohne Dauerpumpen austragen wollen — Erwachsene wie Kinder.',
  'Sehr kleine Kinder — Größe und Reichweite sind auf ältere Nutzer ausgelegt.',
  'Selbstansaugend, elektrischer Abzug, LED-Beleuchtung — kein manuelles Pumpen.',
  array['Kein Pumpen — nur Abzug halten','Große Kapazität und lange Reichweite','LED-Beleuchtung','Für Erwachsene und Kinder'],
  array['Braucht eine Strom- oder Akkuquelle','Größer und schwerer als klassische Pumppistolen'],
  'derayee-schaumstoff-wasserpistole',
  'Günstiger und leichter — dieselbe Idee für kleinere Kinder und den schmalen Geldbeutel.',
  'alternative',
  'Verschiebt das Kräfteverhältnis im Garten: kein Pumpen mehr, nur Abzug halten. Große Reichweite, LED für den Show-Effekt — ehrlich gesagt für Erwachsene fast lustiger als für Kinder.'
),
(
  'hot-wheels-ultimative-garage-3ft',
  'Hot-Wheels-Kinder und Sammler, deren Auto-Sammlung längst überläuft.',
  'Kleine Kinderzimmer — das Teil ist fast einen Meter hoch und braucht Platz.',
  '3-stöckig, rund 1 m hoch, mit Aufzug, Waschanlage und Tankstelle, 2 Autos inklusive.',
  array['Drei Spielebenen mit Aufzug, Waschanlage und Tankstelle','Fast 1 m hoch — großer Spielwert','Zwei Die-Cast-Autos direkt dabei'],
  array['Braucht viel Platz','Nur zwei Autos enthalten — weitere separat'],
  null, null, null,
  'Die Lösung fürs Luxusproblem „zu viele Hot-Wheels-Autos": drei Etagen, Aufzug, Waschanlage, fast ein Meter hoch. Sorgt beim Auspacken sofort für Jubel — und braucht danach dauerhaft Platz.'
),
(
  'lego-creator-3in1-retro-kamera-31147',
  'Kinder ab 8 mit Bau-Lust — und Erwachsene mit Lego- plus Nostalgie-Tick.',
  'Kinder unter 8 Jahren (laut Hersteller ab 8).',
  '3-in-1-Set, 261 Teile: baubar als Fotokamera, Videokamera oder Retro-Fernseher, ab 8 Jahren.',
  array['Drei Baumodelle aus einem Set','261 Teile für mehrere Bauerlebnisse','Günstiger Einstieg','Retro-Optik trifft Nostalgie'],
  array['Erst ab 8 Jahren','Nur ein Modell gleichzeitig baubar'],
  null, null, null,
  'Clever gemacht: einmal kaufen, dreimal bauen — Kamera, Videokamera oder Retro-Fernseher. Für den Preis ein starker Einstieg und ein sicheres Geschenk für bauwütige Kinder ab 8.'
),
(
  'ninja-staysharp-messerset-6-teilig',
  'Haushalte, in denen wirklich täglich gekocht wird und niemand separat schärfen will.',
  'Profis, die ihre Klingen am Stein abziehen und den Winkel frei wählen wollen.',
  '6-teiliges Set mit integrierten Schärf-Slots im Block, 15-Grad-Klingenwinkel.',
  array['Schärfen ist im Block eingebaut — kein Extra-Zubehör','Komplettes Set (Koch, Brot, Santoku, Fleisch, Zubereitung, Schere)','Definierter 15-Grad-Winkel','Aufbewahrung im Block inklusive'],
  array['Fester Schärfwinkel — keine freie Winkelwahl','Preisband deutlich über Einsteiger-Sets'],
  null, null, null,
  'Löst das nervigste Messer-Problem: Es schärft sich beim Reinstecken selbst. 6-teilig, mit Block, definierter Winkel. Für Küchen, in denen echt gekocht wird — nicht für Puristen mit eigenem Schleifstein.'
),
(
  'n4-nussmilchbereiter-pflanzenmilch',
  'Pflanzenmilch-Vieltrinker, die Zutaten und Kosten selbst kontrollieren wollen.',
  'Wer nur selten mal Hafermilch trinkt — die Anschaffung amortisiert sich dann kaum.',
  '800-W-Bereiter mit Selbstreinigung für Hafer-, Mandel-, Soja-, Reis- und Cashew-Milch.',
  array['Mixt, kocht und filtert automatisch','Selbstreinigung','Fünf Milchsorten','800 W'],
  array['Lohnt sich nur bei regelmäßigem Konsum','Ein weiteres Küchengerät, das gereinigt werden will'],
  'aeropress-go-tragbare-kaffeemaschine',
  'Wer die frische Hafer- oder Mandelmilch für Kaffee nutzt: die AeroPress macht den Kaffee dazu — die Heim-Barista-Kombi.',
  'complement',
  'Macht frische Pflanzenmilch auf Knopfdruck und reinigt sich selbst. Für Menschen, die Milch-Alternativen ernst nehmen und die Bio-Laden-Preise satt haben. Lohnt sich, wenn täglich getrunken — sonst steht er nur rum.'
),
(
  'welpen-usb-ladekabel-hunde-design',
  'Hunde-Fans, die ein Alltagskabel mit Charakter statt Standard-Schwarz wollen.',
  'Wer maximale Ladeleistung oder Datenrate braucht — hier zählt vor allem das Design.',
  '1,5-m-Kabel mit verstärktem Anschluss (USB-C oder Lightning) und integrierter Zugentlastung.',
  array['Verstärkter Anschluss und Zugentlastung gegen Kabelbruch','1,5 m Länge','Süßes Welpen-Design','Als USB-C oder Lightning erhältlich'],
  array['Design-Produkt — keine Angabe zur Schnellladeleistung','Das Motiv ist Geschmackssache'],
  'cbdywvr-2in1-ladekabel-mit-staender',
  'Ein anderes Ladekabel — 2-in-1 mit integriertem Ständer, wenn Funktion vor Design geht.',
  'alternative',
  'Macht aus dem langweiligsten Alltagsteil ein kleines Deko-Statement — mit verstärktem Anschluss und Zugentlastung gegen den klassischen Kabelbruch an der Buchse. Für Hunde-Fans, nicht für Ladegeschwindigkeits-Nerds.'
);

-- Persistente Audit-Payload fuer die read-only Inhaltspruefung nach dem Commit.
-- Die Tabelle entsteht in derselben Transaktion und bleibt fuer das
-- Beobachtungs-/Rollback-Fenster privat erhalten.
do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v1') is not null then
    raise exception 'Production-Backfill abgebrochen: Audit-Payload v1 existiert bereits.';
  end if;
end $$;

create table cbb_private_backup.value_add_payload_v1 as
select * from cbb_value_add_payload;

alter table cbb_private_backup.value_add_payload_v1
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v1
  from public, anon, authenticated;

do $$
declare
  affected_rows integer;
begin
  update public.products p set
    fuer_wen = v.fuer_wen,
    nicht_fuer = v.nicht_fuer,
    key_fact = v.key_fact,
    pros = v.pros,
    cons = v.cons,
    alternative_slug = v.alternative_slug,
    alternative_reason = v.alternative_reason,
    alternative_kind = v.alternative_kind,
    editorial_note = v.editorial_note,
    updated_at = now()
  from cbb_value_add_payload v
  where p.slug = v.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 10 then
    raise exception 'Production-Backfill abgebrochen: UPDATE traf %/10 Zeilen.',
      affected_rows;
  end if;
end $$;

do $$
declare
  payload_mismatches integer;
  payload_rows integer;
  alternatives integer;
  complements integer;
  no_relation integer;
  inconsistent_relations integer;
  broken_targets integer;
  changed_timestamps integer;
begin
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v1;

  select count(*) into payload_mismatches
  from public.products p
  join cbb_value_add_payload v on v.slug = p.slug
  where p.fuer_wen is distinct from v.fuer_wen
     or p.nicht_fuer is distinct from v.nicht_fuer
     or p.key_fact is distinct from v.key_fact
     or p.pros is distinct from v.pros
     or p.cons is distinct from v.cons
     or p.alternative_slug is distinct from v.alternative_slug
     or p.alternative_reason is distinct from v.alternative_reason
     or p.alternative_kind is distinct from v.alternative_kind
     or p.editorial_note is distinct from v.editorial_note;

  select
    count(*) filter (where p.alternative_kind = 'alternative'),
    count(*) filter (where p.alternative_kind = 'complement'),
    count(*) filter (
      where p.alternative_kind is null
        and p.alternative_slug is null
        and p.alternative_reason is null
    ),
    count(*) filter (
      where not (
        (p.alternative_kind is null and p.alternative_slug is null
          and p.alternative_reason is null)
        or
        (p.alternative_kind in ('alternative', 'complement')
          and p.alternative_slug is not null
          and p.alternative_reason is not null)
      )
    )
  into alternatives, complements, no_relation, inconsistent_relations
  from public.products p
  join cbb_value_add_payload v on v.slug = p.slug;

  select count(*) into broken_targets
  from public.products p
  join cbb_value_add_payload v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  select count(*) into changed_timestamps
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.updated_at is distinct from b.updated_at;

  if payload_rows <> 10
     or payload_mismatches <> 0
     or alternatives <> 3
     or complements <> 2
     or no_relation <> 5
     or inconsistent_relations <> 0
     or broken_targets <> 0
     or changed_timestamps <> 10 then
    raise exception
      'Production-Backfill inkonsistent: payload %, mismatch %, alt %, comp %, ohne %, inkonsistent %, defekt %, lastmod %.',
      payload_rows, payload_mismatches, alternatives, complements, no_relation,
      inconsistent_relations, broken_targets, changed_timestamps;
  end if;
end $$;

commit;
