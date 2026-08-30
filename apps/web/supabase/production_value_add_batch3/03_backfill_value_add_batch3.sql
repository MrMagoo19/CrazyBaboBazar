-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 3 — 03 ATOMARER BACKFILL (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Voraussetzung: 01 FAIL-frei, 02 mit backup_rows = 10, 02b FAIL-frei.
--
-- KEINE SCHEMA-MIGRATION. Diese Datei schreibt ausschliesslich Daten in exakt
-- zehn Zeilen von public.products und legt die private Audit-Payload
-- cbb_private_backup.value_add_payload_v3 an.
--
-- BATCH 1 UND BATCH 2 WERDEN NICHT ANGEFASST. Die vier Tabellen
-- value_add_pre_backfill_v1, value_add_payload_v1, value_add_pre_backfill_v2
-- und value_add_payload_v2 werden ausschliesslich per to_regclass auf Existenz
-- geprueft. Kein SELECT auf ihren Inhalt, kein UPDATE, kein DROP.
--
-- RELATIONEN: genau zwei strukturierte Triplets, beide innerhalb von Batch 3.
--   dicmky-hoehenverstellbarer-schreibtisch-aufsatz
--     -> laptop-staender-hoehenverstellbar-360-drehbar    kind = alternative
--   laptop-staender-hoehenverstellbar-360-drehbar
--     -> tecknet-ergonomische-kabellose-maus-bluetooth    kind = complement
--   Die anderen acht Zeilen bekommen alternative_slug, alternative_reason und
--   alternative_kind ausdruecklich NULL.
--
-- KETTE STATT KREIS: Die beiden Triplets bilden dicmky -> laptop-staender ->
-- tecknet. Das Ende der Kette, tecknet-ergonomische-kabellose-maus-bluetooth,
-- bleibt bewusst relationslos. Zeigte tecknet zurueck auf laptop-staender,
-- entstuende ein Kreis, den die Produktseite als endloses Hin und Her rendert.
-- Der Guard weiter unten prueft ausdruecklich, dass genau diese eine Zeile
-- relationslos bleibt. laptop-staender ist gleichzeitig Ziel UND Quelle — das
-- ist zulaessig, weil es kein Kreis ist, sondern ein Weiterreichen.
--
-- EDITORIAL_NOTE: alle zehn Zeilen bekommen eine editorial_note. Trug eine
-- Zielzeile vorher bereits eine Notiz, wird diese bewusst ueberschrieben. Der
-- Originaltext und der Original-updated_at-Wert liegen im privaten Snapshot
-- cbb_private_backup.value_add_pre_backfill_v3 und werden von
-- 05_restore_value_add_batch3.sql wortgleich zurueckgeholt. Welche Zielzeilen
-- betroffen sind, meldet 02b in der INFO-Zeile
-- snapshot_v3_bestehende_editorial_notes.
--
-- QUELLENBINDUNG: jede Aussage in dieser Payload stammt aus vorhandenen
-- Repo-Quellen (Produktbeschreibungen und redaktionelle Notizen unter
-- apps/web/supabase/). Die Zuordnung Aussage -> Quelldatei steht im RUNBOOK
-- Abschnitt 4, die bewusst NICHT uebernommenen Behauptungen in Abschnitt 5.
--
-- WIEDERHOLUNGSVERHALTEN: ein zweiter Lauf bricht fail-closed ab — entweder am
-- Drift-Guard (die Zielzeilen weichen vom Snapshot ab) oder daran, dass
-- value_add_payload_v3 bereits existiert. Ueberschrieben wird nie.
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
  snapshot_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
  befuellt_gesamt integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-3-Backfill abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-3-Backfill abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-3-Backfill abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
  from public.products
  where slug in (
    'bartesian-cocktailmaschine-mit-kapseln',
    'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'tecknet-ergonomische-kabellose-maus-bluetooth',
    'rocketbook-wiederverwendbares-notizbuch-a4',
    'ticktime-tk3-wuerfel-timer-countdown',
    'kabeltasche-edc-elektronik-organizer-reise',
    'silikon-magnete-airfryer-backpapier-4er-set',
    'tre-feuerstahl-xxl',
    'bbq-wuerstchenhalter-maennchen-3er-set'
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Batch-3-Backfill abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  select count(*) into relation_rows
  from public.products
  where slug in (
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'tecknet-ergonomische-kabellose-maus-bluetooth'
  ) and is_published is true;
  if relation_rows <> 2 then
    raise exception 'Batch-3-Backfill abgebrochen: %/2 Relationsziele published.', relation_rows;
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
    raise exception 'Batch-3-Backfill abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-3-Backfill abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-3-Backfill abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-3-Backfill abgebrochen: Batch-2-Snapshot v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Batch-3-Backfill abgebrochen: Batch-2-Payload v2 fehlt.';
  end if;

  -- Reihenfolge ist Absicht: erst der eigene Vorlauf (Snapshot v3 da und
  -- vollstaendig, Payload v3 noch nicht da), dann die globale Zaehlung. Sonst
  -- meldet ein zweiter erfolgreicher Lauf "30 Zeilen tragen Value-Add-Daten"
  -- statt der eigentlichen Ursache "Audit-Payload v3 existiert bereits".
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is null then
    raise exception 'Batch-3-Backfill abgebrochen: privater Snapshot v3 fehlt.';
  end if;
  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v3;
  if snapshot_rows <> 10 then
    raise exception 'Batch-3-Backfill abgebrochen: Snapshot v3 hat %/10 Zeilen.', snapshot_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Batch-3-Backfill abgebrochen: Audit-Payload v3 existiert bereits.';
  end if;

  select count(*) into befuellt_gesamt
  from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if befuellt_gesamt <> 20 then
    raise exception 'Batch-3-Backfill abgebrochen: % Zeilen tragen Value-Add-Daten (erwartet 20).',
      befuellt_gesamt;
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
  join cbb_private_backup.value_add_pre_backfill_v3 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Batch-3-Backfill abgebrochen: nur %/10 Zielzeilen gesperrt.', locked_rows;
  end if;

  select count(*) into drift_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v3 b
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
    raise exception 'Batch-3-Backfill abgebrochen: % Zielzeilen sind seit dem Snapshot gedriftet.',
      drift_rows;
  end if;
end $$;

create temporary table cbb_value_add_payload_b3 (
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

insert into cbb_value_add_payload_b3 (
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
) values
(
  'bartesian-cocktailmaschine-mit-kapseln',
  'Alle, die abends einen fertig abgestimmten Cocktail wollen, ohne Sirupe, Bitters und Rezepte selbst zusammenzusuchen.',
  'Wer gern selbst mixt und dosiert — hier gibt die Kapsel das Rezept vor.',
  'Cocktailmaschine mit Kapselsystem: Die Kapsel enthält Sirupe und Bitters, die Spirituosen kommen aus eigenen Flaschen dazu.',
  array[
    'Kapselprinzip wie bei einer Kaffeemaschine — Kapsel einlegen, Gerät mischt',
    'Kapseln enthalten Sirupe und Bitters, unter anderem für Old Fashioned, Espresso Martini und Margarita',
    'Die vorhandene Produktbeschreibung nennt über 40 Cocktail-Varianten',
    'Kein Abmessen einzelner Zutaten'
  ],
  array[
    'Folgekosten: Ohne passende Kapseln steht die Maschine still, die Spirituosen kommen zusätzlich dazu',
    'Braucht dauerhaft Stellfläche samt Platz für die Flaschen',
    'Welche Kapselsorten und Varianten aktuell erhältlich sind, vor dem Kauf beim Händler prüfen'
  ],
  null, null, null,
  'Das Kapselprinzip, angewendet auf die Hausbar: Sirupe und Bitters stecken in der Kapsel, die Spirituose kommt aus der eigenen Flasche. Das nimmt einem das Abmessen ab — und bindet einen an Nachschub, denn ohne Kapseln passiert nichts. Vor dem Kauf lohnt der Blick auf Stellfläche und auf das, was an Kapseln gerade lieferbar ist.'
),
(
  'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
  'Alle, die im Stehen arbeiten wollen, den Bürotisch aber nicht austauschen können oder dürfen.',
  'Wer eine verbindlich belegte Traglast braucht — dazu liegen uns keine gesicherten Angaben vor.',
  'Höhenverstellbarer Schreibtischaufsatz für Monitor oder Laptop; der vorhandene Tisch bleibt stehen.',
  array[
    'Verwandelt den vorhandenen Tisch in ein Steh-Sitz-Setup',
    'Für Monitor oder Laptop beschrieben',
    'Der vorhandene Tisch bleibt stehen'
  ],
  array[
    'Der Aufsatz steht dauerhaft auf der Tischplatte und braucht dort Fläche',
    'Zur zulässigen Traglast liegen uns keine gesicherten Angaben vor — die aktuelle Herstellerangabe vor dem Kauf prüfen'
  ],
  'laptop-staender-hoehenverstellbar-360-drehbar',
  'Wer nur den Laptop-Bildschirm anheben will und wenig Platz hat, kommt mit dem kompakten Laptop-Ständer weiter als mit einem Aufsatz für den ganzen Arbeitsplatz.',
  'alternative',
  'Der klare Vorteil ist die Nachrüstung: Der vorhandene Bürotisch bleibt stehen, der Aufsatz schafft die höhere Arbeitsposition. Zur zulässigen Traglast liegen uns keine gesicherten Angaben vor; deshalb ist die aktuelle Herstellerangabe vor dem Kauf Pflicht.'
),
(
  'laptop-staender-hoehenverstellbar-360-drehbar',
  'Alle, die dauerhaft am Laptop arbeiten und den Bildschirm auf Augenhöhe haben wollen.',
  'Wer den Laptop im Zug oder auf dem Sofa benutzt — der Ständer bleibt auf dem Tisch.',
  'Höhenverstellbarer Aluminium-Ständer, um 360 Grad drehbar, passend für Laptops bis 17 Zoll.',
  array[
    'Höhenverstellbar bis auf Augenhöhe',
    'Um 360 Grad drehbar für Video-Calls und Screen-Sharing',
    'Aus Aluminium',
    'Nimmt Laptops bis 17 Zoll auf'
  ],
  array[
    'Steht der Laptop oben, braucht es externe Tastatur und Maus',
    'Belegt dauerhaft Standfläche auf dem Schreibtisch'
  ],
  'tecknet-ergonomische-kabellose-maus-bluetooth',
  'Steht der Laptop auf Augenhöhe, wird ohnehin extern gemaust — die vertikale Bluetooth-Maus gehört auf denselben Tisch.',
  'complement',
  'Der Bildschirm wandert auf Augenhöhe, der Nacken bleibt gerade — mehr macht das Ding nicht, und mehr braucht es auch nicht. Die 360 Grad helfen, sobald jemand mitschauen soll. Was der Ständer nicht löst: Tippen und Mausen laufen ab sofort extern.'
),
(
  'tecknet-ergonomische-kabellose-maus-bluetooth',
  'Alle, die lange am Rechner sitzen und die Hand lieber senkrecht als flach halten.',
  'Wer maximale Präzision im Spiel braucht — bei 1600 DPI ist Schluss.',
  'Vertikale Bluetooth-Maus mit drei DPI-Stufen (800, 1200, 1600), geräuscharmem Klicken und USB-C-Ladung.',
  array[
    'Drei DPI-Stufen: 800, 1200 und 1600',
    'Geräuscharmes Klicken',
    'Verbindet sich mit mehreren Geräten',
    'Lädt per USB-C'
  ],
  array[
    'Die senkrechte Handhaltung ist Gewöhnungssache',
    'Höchste DPI-Stufe liegt bei 1600 — für kompetitives Gaming knapp'
  ],
  null, null, null,
  'Die Hand steht senkrecht statt flach — das ist der ganze Unterschied und eine Frage der Gewöhnung. Drei DPI-Stufen bis 1600, leises Klicken, Laden per USB-C, mehrere Geräte gekoppelt. Für kompetitives Gaming ist bei 1600 DPI die Grenze erreicht.'
),
(
  'rocketbook-wiederverwendbares-notizbuch-a4',
  'Alle, die von Hand schreiben wollen und die Notizen trotzdem digital brauchen.',
  'Wer mit normalem Kugelschreiber schreiben will — gelöscht wird nur, was mit Frixion-Stiften geschrieben ist.',
  'A4-Notizbuch, beschreibbar mit Frixion-Stiften, mit feuchtem Tuch löschbar, per App an Google Drive, Dropbox, Evernote oder Slack.',
  array[
    'Mit feuchtem Tuch komplett löschbar und wiederverwendbar',
    'Per App direkt an Google Drive, Dropbox, Evernote oder Slack',
    'Format A4'
  ],
  array[
    'Funktioniert nur mit Frixion-Stiften',
    'Ohne die App bleibt es ein gewöhnliches Notizbuch'
  ],
  null, null, null,
  'Handschrift bleibt Handschrift, landet aber trotzdem in Drive, Dropbox, Evernote oder Slack. Feuchtes Tuch drüber, Seite ist wieder leer. Zwei Bedingungen: Frixion-Stift und App — ohne beides ist es ein hübsches A4-Heft.'
),
(
  'ticktime-tk3-wuerfel-timer-countdown',
  'Alle, die mit Pomodoro oder festen Zeitblöcken arbeiten und dafür nicht zum Handy greifen wollen.',
  'Wer frei wählbare Zeiten braucht — die sechs Seiten sind fest vorbelegt.',
  'Würfel-Timer mit sechs voreingestellten Zeiten von 3 bis 60 Minuten, Vibrations- und Tonalarm, ohne App.',
  array[
    'Sechs feste Zeiten zwischen 3 und 60 Minuten',
    'Countdown startet automatisch beim Umdrehen',
    'Vibrations- und Tonalarm',
    'Kommt ohne App aus'
  ],
  array[
    'Nur die sechs voreingestellten Zeiten, nichts dazwischen',
    'Ein weiteres Gerät auf dem Schreibtisch'
  ],
  null, null, null,
  'Umdrehen, Countdown läuft, Handy bleibt liegen. Sechs Zeiten von 3 bis 60 Minuten, Alarm per Vibration oder Ton, keine App dazwischen. Genau das ist die Stärke — und die Grenze: Zwischenwerte gibt es nicht.'
),
(
  'kabeltasche-edc-elektronik-organizer-reise',
  'Alle, die regelmäßig mit Ladegerät, Kabeln und Powerbank unterwegs sind.',
  'Wer nur ein einzelnes Kabel mitnimmt — dafür ist die Tasche zu viel Gehäuse.',
  'Elektronik-Organizer aus wasserabweisendem Nylon mit mehreren Innenfächern und Netz-Slots für Ladegerät, Kabel, USB-Sticks, SD-Karten, Powerbank und Adapter.',
  array[
    'Eigene Fächer für Ladegerät, Kabel, USB-Sticks, SD-Karten, Powerbank und Adapter',
    'Wasserabweisendes Nylon',
    'Mehrere Innenfächer und Netz-Slots'
  ],
  array[
    'Braucht selbst Platz im Rucksack',
    'Zu Maßen und Innenaufteilung im Detail liegen uns keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  'Der Grund, warum im Rucksack nicht mehr alles gleichzeitig Kabel ist. Fächer für Ladegerät, Kabel, Sticks, SD-Karten, Powerbank und Adapter, außen wasserabweisendes Nylon. Konkrete Maße nennt der Hersteller nicht — vor dem Kauf kurz gegen den eigenen Rucksack halten.'
),
(
  'silikon-magnete-airfryer-backpapier-4er-set',
  'Alle mit Heißluftfritteuse, deren Backpapier beim Vorheizen nach oben fliegt.',
  'Wer ohne Backpapier frittiert — dann gibt es nichts zu beschweren.',
  '4er-Set Silikon-Magnete, hitzebeständig bis 240 °C, wiederverwendbar und spülmaschinenfest.',
  array[
    'Halten das Papier am Rand fest, damit es nicht in den Ventilator gezogen wird',
    'Hitzebeständig bis 240 °C',
    'Wiederverwendbar und spülmaschinenfest',
    'Vier Stück im Set'
  ],
  array[
    'Löst genau ein Problem und sonst keines',
    'Oberhalb von 240 °C nicht mehr einsetzbar'
  ],
  null, null, null,
  'Vier kleine Magnete gegen ein Problem, das jeder mit Heißluftfritteuse kennt: Das Papier flattert beim Vorheizen ins Heizelement. Bis 240 Grad hitzebeständig, spülmaschinenfest, wiederverwendbar. Mehr können sie nicht — mehr sollen sie auch nicht.'
),
(
  'tre-feuerstahl-xxl',
  'Bushcraft- und Zeltcamping-Leute, die Feuermachen als Fertigkeit üben wollen.',
  'Wer schnell und bequem zünden will — dafür bleibt das Feuerzeug die einfachere Wahl.',
  '12 cm langer Feuerstahl aus Magnesium-Legierung mit Schaber, laut Hersteller für über 10.000 Zündungen.',
  array[
    '12 cm Länge, entsprechend griffig',
    'Magnesium-Legierung mit passendem Schaber',
    'Funktioniert auch bei Regen, Kälte und nasser Kleidung',
    'Laut Hersteller über 10.000 Zündungen'
  ],
  array[
    'Ist bewusst kein Ein-Klick-Ersatz fürs Feuerzeug',
    'Die Angabe von über 10.000 Zündungen stammt vom Hersteller, nicht aus einem eigenen Test'
  ],
  null, null, null,
  'Zwölf Zentimeter Magnesium mit passendem Schaber — Feuer machen wird damit zur Fertigkeit statt zur Handbewegung. Regen, Kälte und nasse Klamotten stören den Funken nicht. Die über 10.000 Zündungen sind eine Herstellerangabe, kein eigener Testwert.'
),
(
  'bbq-wuerstchenhalter-maennchen-3er-set',
  'Grillrunden, die ein Mitbringsel wollen, das am Rost sofort auffällt.',
  'Wer nur Steaks grillt — die Halter sind für Würstchen gebaut.',
  '3er-Set aus Edelstahl im Männchen-Look, hält sechs Würstchen stehend, spülmaschinenfest und hitzebeständig.',
  array[
    'Edelstahl, hitzebeständig und spülmaschinenfest',
    'Drei Halter im Set',
    'Sechs Würstchen stehen gleichzeitig am Rost'
  ],
  array[
    'Reiner Gag — am Grillergebnis ändert sich nichts',
    'Für alles außer Würstchen unbrauchbar'
  ],
  null, null, null,
  'Sechs Würstchen stehen am Rost, als hätten sie Karten für dasselbe Konzert. Edelstahl, hitzebeständig, spülmaschinenfest — das Set überlebt mehr Grillsaisons als der Witz. Am Ergebnis ändert es nichts, das ist auch nicht der Punkt.'
);

-- Persistente Audit-Payload fuer die read-only Inhalts- und Sicherheitspruefung
-- nach dem Commit. Die Tabelle entsteht in derselben Transaktion und bleibt
-- fuer das Beobachtungs- und Rollback-Fenster privat erhalten.
do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Batch-3-Backfill abgebrochen: Audit-Payload v3 existiert bereits.';
  end if;
end $$;

create table cbb_private_backup.value_add_payload_v3 as
select * from cbb_value_add_payload_b3;

alter table cbb_private_backup.value_add_payload_v3
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v3
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
  from cbb_value_add_payload_b3 v
  where p.slug = v.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 10 then
    raise exception 'Batch-3-Backfill abgebrochen: UPDATE traf %/10 Zeilen.',
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
  value_add_gesamt integer;
  batch1_vollstaendig integer;
  batch2_vollstaendig integer;
  ziele_relationslos integer;
  pros_in_spanne integer;
begin
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v3;

  select count(*) into payload_mismatches
  from public.products p
  join cbb_value_add_payload_b3 v on v.slug = p.slug
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
    ),
    count(*) filter (
      where p.pros is not null and array_length(p.pros, 1) between 2 and 4
    )
  into alternatives, complements, no_relation, inconsistent_relations, pros_in_spanne
  from public.products p
  join cbb_value_add_payload_b3 v on v.slug = p.slug;

  select count(*) into broken_targets
  from public.products p
  join cbb_value_add_payload_b3 v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  select count(*) into changed_timestamps
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v3 b
    on b.id = p.id and b.slug = p.slug
  where p.updated_at is distinct from b.updated_at;

  -- Batch 1 (10) plus Batch 2 (10) plus Batch 3 (10) = 30. Mehr waere ein
  -- Treffer ausserhalb der Zielmenge, weniger ein beschaedigter Vorgaenger.
  select count(*) into value_add_gesamt
  from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select count(*) into batch1_vollstaendig
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
  ) and fuer_wen is not null and nicht_fuer is not null
    and key_fact is not null and pros is not null and cons is not null
    and editorial_note is not null;

  select count(*) into batch2_vollstaendig
  from public.products
  where slug in (
    'livondo-terracotta-pflanzenbewaesserung',
    'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch',
    'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen',
    'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool',
    'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars',
    'katzenschlafsack-fuer-menschen'
  ) and fuer_wen is not null and nicht_fuer is not null
    and key_fact is not null and pros is not null and cons is not null
    and editorial_note is not null;

  -- Die bewusste Ausnahme: das ENDE der Relationskette bleibt selbst
  -- relationslos, damit kein Kreis entsteht. Das ist genau eine Zeile —
  -- laptop-staender ist zwar auch Relationsziel, reicht die Kette aber weiter
  -- an tecknet und traegt deshalb selbst eine Relation.
  select count(*) into ziele_relationslos
  from public.products
  where slug in (
    'tecknet-ergonomische-kabellose-maus-bluetooth'
  )
    and alternative_slug is null
    and alternative_reason is null
    and alternative_kind is null;

  if payload_rows <> 10
     or payload_mismatches <> 0
     or alternatives <> 1
     or complements <> 1
     or no_relation <> 8
     or inconsistent_relations <> 0
     or broken_targets <> 0
     or changed_timestamps <> 10
     or value_add_gesamt <> 30
     or batch1_vollstaendig <> 10
     or batch2_vollstaendig <> 10
     or ziele_relationslos <> 1
     or pros_in_spanne <> 10 then
    raise exception
      'Batch-3-Backfill inkonsistent: payload %, mismatch %, alt %, comp %, ohne %, inkonsistent %, defekt %, lastmod %, value_add_gesamt %, batch1 %, batch2 %, ziele_relationslos %, pros %.',
      payload_rows, payload_mismatches, alternatives, complements, no_relation,
      inconsistent_relations, broken_targets, changed_timestamps,
      value_add_gesamt, batch1_vollstaendig, batch2_vollstaendig,
      ziele_relationslos, pros_in_spanne;
  end if;
end $$;

commit;
