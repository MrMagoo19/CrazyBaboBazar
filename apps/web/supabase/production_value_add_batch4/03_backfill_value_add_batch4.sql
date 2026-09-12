-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 4 — 03 ATOMARER BACKFILL (SCHREIBEND)
-- ============================================================================
-- WARNUNG — SCHREIBENDE DATEI:
--   Diese Datei veraendert die Datenbank. Sie darf NUR mit einer eigenen,
--   ausdruecklichen Benutzerfreigabe ausgefuehrt werden. Vor dem Start ist im
--   SQL-Editor SICHTBAR gegenzupruefen, dass exakt dieses Projekt ausgewaehlt
--   ist:
--     project/ydiihvzcxaaoqhmgoqvu
--   Pilot/Staging (nmzuycveumyfvtxdcnuc) ist KEIN Ziel dieses Changesets. Wer
--   die Projektkennung nicht sichtbar geprueft hat, fuehrt diese Datei nicht
--   aus.
--
-- Voraussetzung: 01 FAIL-frei, 02 mit backup_rows = 12, 02b FAIL-frei.
--
-- KEINE SCHEMA-MIGRATION. Diese Datei schreibt ausschliesslich Daten in exakt
-- zwoelf Zeilen von public.products und legt die private Audit-Payload
-- cbb_private_backup.value_add_payload_v4 an.
--
-- BATCH 1, 2 UND 3 WERDEN NICHT ANGEFASST. Die sechs Tabellen
-- value_add_pre_backfill_v1, value_add_payload_v1, value_add_pre_backfill_v2,
-- value_add_payload_v2, value_add_pre_backfill_v3 und value_add_payload_v3
-- werden ausschliesslich per to_regclass auf Existenz geprueft. Kein SELECT auf
-- ihren Inhalt, kein UPDATE, kein DROP.
--
-- RELATIONEN: KEINE. Alle zwoelf Zeilen bekommen alternative_slug,
-- alternative_reason und alternative_kind ausdruecklich NULL. Fuer keines der
-- zwoelf Zielprodukte stuetzt eine Quelle eine Relation auf ein anderes
-- veroeffentlichtes Produkt eindeutig — und eine geratene Relation waere eine
-- Kaufempfehlung ohne Grundlage. Der Guard weiter unten prueft ausdruecklich,
-- dass genau 0 Alternativen, 0 Ergaenzungen und 12 relationslose Zeilen
-- entstehen.
--
-- EDITORIAL_NOTE: alle zwoelf Zeilen bekommen eine editorial_note. Trug eine
-- Zielzeile vorher bereits eine Notiz, wird diese bewusst ueberschrieben. Der
-- Originaltext und der Original-updated_at-Wert liegen im privaten Snapshot
-- cbb_private_backup.value_add_pre_backfill_v4 und werden von
-- 05_restore_value_add_batch4.sql wortgleich zurueckgeholt. Welche Zielzeilen
-- betroffen sind, meldet 02b in der INFO-Zeile
-- snapshot_v4_bestehende_editorial_notes.
--
-- QUELLENBINDUNG: die Payload dieser Datei ist der redaktionell freigegebene
-- Inhalt aus DRAFT_featured_value_add_batch4.sql im selben Verzeichnis, Zeile
-- fuer Zeile wortgleich uebernommen. Die Zuordnung Aussage -> Quelle steht in
-- SOURCES_featured_value_add_batch4.md, die bewusst NICHT uebernommenen
-- Behauptungen im RUNBOOK Abschnitt 5.
--
-- KEINE PREISE: keine Zeile dieser Payload nennt einen Preis, ein Preisband,
-- einen Rabatt oder eine Verfuegbarkeit.
--
-- WIEDERHOLUNGSVERHALTEN: ein zweiter Lauf bricht fail-closed ab — entweder am
-- Drift-Guard (die Zielzeilen weichen vom Snapshot ab) oder daran, dass
-- value_add_payload_v4 bereits existiert. Ueberschrieben wird nie.
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
  snapshot_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
  befuellt_gesamt integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-4-Backfill abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-4-Backfill abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
  from public.products
  where slug in (
    'aarke-wasserkocher-edelstahl-1-2l',
    'anker-nano-powerbank-magsafe-5000mah',
    'dji-osmo-pocket-4-kreativ-combo',
    'dyson-zone-absolute-kopfhoerer',
    'ferrofluid-sound-visualizer-lampe',
    'fontastic-mesu-bluetooth-lautsprecher',
    'khadas-mind-2-mini-pc',
    'lego-pokemon-bisaflor-glurak-turtok-72153',
    'plaud-note-pro-ki-diktiergeraet',
    'teenage-engineering-tp7-audio-recorder',
    'vivo-x300-ultra-smartphone',
    'xgimi-horizon-ultra-4k-projektor'
  ) and is_published is true;
  if target_rows <> 12 then
    raise exception 'Batch-4-Backfill abgebrochen: %/12 Zielprodukte published.', target_rows;
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
    raise exception 'Batch-4-Backfill abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-2-Snapshot v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-2-Payload v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-3-Snapshot v3 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v3') is null then
    raise exception 'Batch-4-Backfill abgebrochen: Batch-3-Payload v3 fehlt.';
  end if;

  -- Reihenfolge ist Absicht: erst der eigene Vorlauf (Snapshot v4 da und
  -- vollstaendig, Payload v4 noch nicht da), dann die globale Zaehlung. Sonst
  -- meldet ein zweiter erfolgreicher Lauf "42 Zeilen tragen Value-Add-Daten"
  -- statt der eigentlichen Ursache "Audit-Payload v4 existiert bereits".
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v4') is null then
    raise exception 'Batch-4-Backfill abgebrochen: privater Snapshot v4 fehlt.';
  end if;
  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v4;
  if snapshot_rows <> 12 then
    raise exception 'Batch-4-Backfill abgebrochen: Snapshot v4 hat %/12 Zeilen.', snapshot_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_payload_v4') is not null then
    raise exception 'Batch-4-Backfill abgebrochen: Audit-Payload v4 existiert bereits.';
  end if;

  select count(*) into befuellt_gesamt
  from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if befuellt_gesamt <> 30 then
    raise exception 'Batch-4-Backfill abgebrochen: % Zeilen tragen Value-Add-Daten (erwartet 30).',
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
  join cbb_private_backup.value_add_pre_backfill_v4 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 12 then
    raise exception 'Batch-4-Backfill abgebrochen: nur %/12 Zielzeilen gesperrt.', locked_rows;
  end if;

  select count(*) into drift_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v4 b
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
    raise exception 'Batch-4-Backfill abgebrochen: % Zielzeilen sind seit dem Snapshot gedriftet.',
      drift_rows;
  end if;
end $$;

create temporary table cbb_value_add_payload_b4 (
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

-- Reihenfolge und Wortlaut identisch zu DRAFT_featured_value_add_batch4.sql.
insert into cbb_value_add_payload_b4 (
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
) values
(
  'aarke-wasserkocher-edelstahl-1-2l',
  'Alle, die einen Wasserkocher wollen, der auf der Küchenzeile auch gut aussieht und bei Tee, Kaffee oder Babymilch die passende Temperatur trifft.',
  'Wer nur schnell Wasser heiß machen will, ohne Temperaturwahl — dafür reicht ein einfacher Wasserkocher.',
  'Edelstahl-Wasserkocher mit mehreren Temperatureinstellungen im Bereich von 40 bis 100 °C, 1,2 Liter, vom schwedischen Designlabel Aarke.',
  array[
    'Temperaturwahl passend für Grüntee (70 °C), Kaffee (94 °C) und Babymilch (37 °C)',
    '360°-Sockel, tropffreier Ausgießer, leiser Kochvorgang',
    'Preisgekröntes skandinavisches Design, in vier Farben erhältlich',
    'Von Aarke — demselben Label wie der bekannte Carbonator'
  ],
  array[
    'Die 1,2-Liter-Größe setzt bei mehreren Tassen hintereinander eine klare Grenze',
    'Mehrere Temperatureinstellungen sind für Nutzer ohne Tee- oder Kaffee-Routine möglicherweise unnötig'
  ],
  null, null, null,
  'Der Aarke-Wasserkocher aus Edelstahl, der Küchen sofort premium aussehen lässt: 1,2 Liter, Temperaturwahl von 40 bis 100 °C, preisgekröntes skandinavisches Design. Für Menschen, deren Küche auch ein Statement ist.'
),
(
  'dji-osmo-pocket-4-kreativ-combo',
  'Alle, die regelmäßig filmen — Reisen, Sport, Content, Familie — und genug von verwackelten Handy-Videos haben.',
  'Wer nur gelegentlich ein Foto macht — dafür reicht das Smartphone.',
  'Kompakt-Kamera mit Einzoll-Sensor, 4K-Video bis 240 Bilder pro Sekunde und 3-Achsen-Gimbal-Stabilisierung; die Kreativ-Combo bringt zusätzlich ein Mic-3-Sender-Empfänger-Set und ein Fülllicht mit.',
  array[
    'Einzoll-Sensor und 4K bei bis zu 240 Bildern pro Sekunde',
    '3-Achsen-Gimbal gleicht Wackler mechanisch aus',
    '107 GB interner Speicher, kein SD-Karten-Zwang',
    'Kreativ-Combo liefert Mikrofon-Set und Fülllicht gleich mit'
  ],
  array[
    '107 GB interner Speicher sind angegeben; eine Erweiterung wird in der Quelle nicht genannt',
    'Zusatzteile der Kreativ-Combo brauchen beim Transport eigenen Stauraum'
  ],
  null, null, null,
  'Die kleinste Profi-Kamera aus dem DJI-Programm, in der Kreativ-Combo direkt mit Mikrofon-Set und Fülllicht. Einzoll-Sensor und 240fps passen locker in die Hosentasche. Für alle, die regelmäßig filmen und verwackelte Handy-Videos hinter sich lassen wollen.'
),
(
  'dyson-zone-absolute-kopfhoerer',
  'Alle, die viel in der Stadt oder im Transit unterwegs sind und schlechte Luft nicht mehr als normal hinnehmen wollen.',
  'Wer schlichte, kompakte Kopfhörer sucht — mit aufgesetztem Luftfilter-Visor ist das Gerät deutlich sperriger als normale Over-Ears.',
  'Over-Ear-Kopfhörer mit aktivem Noise-Cancelling und optionalem Luftfilter-Visor, der PM2.5-Partikel, Pollen, Bakterien und NO2-Gase direkt vor dem Gesicht filtert.',
  array[
    'Filtert PM2.5, Pollen, Bakterien und NO2-Gase in Echtzeit',
    'Aktives Noise-Cancelling auf Flaggschiff-Niveau, 11-Treiber-Audiosystem',
    'Bis zu 50 Stunden Akkulaufzeit',
    'Gereinigte Luft kommt ohne Schlauch oder Maske direkt aus dem Bügel'
  ],
  array[
    'Mit aufgesetztem Visor deutlich sperriger als normale Kopfhörer',
    'Wer nur ANC-Kopfhörer braucht, nutzt die zusätzliche Luftfilter-Funktion möglicherweise nicht'
  ],
  null, null, null,
  'Kopfhörer und Luftreiniger in einem Gehäuse — klingt nach Marketing-Gag, filtert aber tatsächlich PM2.5, Pollen und NO2 direkt vor dem Gesicht. Bis zu 50 Stunden Akku, ANC auf Flaggschiff-Niveau. Absurdes Gerät, aber auf die einzig richtige Art absurd.'
),
(
  'ferrofluid-sound-visualizer-lampe',
  'Alle, die eine Lampe wollen, die nicht einfach nur leuchtet, sondern sichtbar auf Musik reagiert.',
  'Wer eine schlichte, unauffällige Lichtquelle sucht — das Ding ist bewusst ein Blickfang.',
  'Ferrofluid-Lampe, die sich im Takt der Musik bewegt und dabei in bunten Farben leuchtet.',
  array[
    'Reagiert auf Musik und leuchtet dabei in bunten Farben',
    'Ferrofluid formt sich zu tanzenden Mustern im Licht'
  ],
  array[
    'Zu Lautstärke-Empfindlichkeit, Stromversorgung und Maßen liegen uns keine verifizierten Herstellerangaben vor — vor dem Kauf auf der aktuellen Produktseite prüfen'
  ],
  null, null, null,
  'Eine Lampe, die tanzt statt nur zu leuchten — Ferrofluid formt sich im Takt der Musik, dazu wechselnde Farben. Zu technischen Details wie Lautstärke-Empfindlichkeit oder Stromversorgung liegt uns keine verifizierte Herstellerangabe vor.'
),
(
  'lego-pokemon-bisaflor-glurak-turtok-72153',
  '90er-Kinder, die Pokémon erst spielten und dann sammelten — und alle, die die drei Starter der ersten Generation als Deko im Regal wollen.',
  'Wer ein schnelles Bauset für kleine Kinder sucht — das ist ein aufwendiges Set mit vielen Details.',
  'LEGO-Set 72153 mit den drei Starter-Pokémon der ersten Generation — Bisaflor, Glurak und Turtok — als detaillierte Modelle mit Anti-Kipp-Sockeln.',
  array[
    'Alle drei Starter der ersten Pokémon-Generation in einem Set',
    'Detailliert und aufwendig gebaut',
    'Anti-Kipp-Sockel für stabilen Stand im Regal'
  ],
  array[
    'Der Bauaufwand macht es eher etwas für geübte oder ältere LEGO-Bauer als für ganz kleine Kinder',
    'Zu Teilezahl und exakten Maßen liegen uns keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  'Die drei Starter der ersten Pokémon-Generation, als LEGO-Modelle mit Anti-Kipp-Sockel fürs Regal. Aufwendig gebaut, für 90er-Kinder, die Pokémon erst spielten und heute sammeln.'
),
(
  'plaud-note-pro-ki-diktiergeraet',
  'Alle, die viel aufnehmen — Meetings, Interviews, Ideen unterwegs — und die Nachbearbeitung nicht mehr selbst tippen wollen.',
  'Wer nur gelegentlich eine Sprachmemo braucht — dafür reicht die Aufnahme-App im Smartphone.',
  'KI-Diktiergerät mit automatischer Transkription, automatischer Zusammenfassung und einer Aufnahmekapazität von 50 Stunden.',
  array[
    'Transkribiert Aufnahmen automatisch per KI',
    'Erstellt zusätzlich automatische Zusammenfassungen',
    'Bis zu 50 Stunden Aufnahmekapazität'
  ],
  array[
    'Zu Akkulaufzeit, Sprachenumfang und Umgang der KI-Funktionen mit personenbezogenen Aufnahmen liegen uns keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  'Aufnehmen, und die KI macht den Rest: Transkript und Zusammenfassung entstehen automatisch, bis zu 50 Stunden Kapazität. Für alle, die Meetings und Interviews nicht mehr von Hand nachtippen wollen.'
),
(
  'teenage-engineering-tp7-audio-recorder',
  'Sounddesigner, Podcaster und Field-Recording-Enthusiasten, die einen tragbaren Profi-Recorder wollen, der auch als Objekt überzeugt.',
  'Wer nur gelegentlich eine Sprachnotiz aufnehmen will — dafür ist das deutlich zu viel Gerät.',
  'Portabler Profi-Audiorecorder mit drei Line-Ins, USB-C, Bluetooth, Mikrofon und 128 GB internem Speicher, dazu Sofort-Playback direkt am Gerät.',
  array[
    'Drei Line-Ins für professionelle Aufnahmesituationen',
    '128 GB integrierter Speicher laut Produktbeschreibung',
    'Bluetooth und Mikrofon zusätzlich zu den Line-Ins integriert',
    'Sofort-Playback direkt am Gerät ohne Umweg über einen Rechner'
  ],
  array[
    'Für gelegentliche Sprachnotizen ist der Funktionsumfang klar überdimensioniert',
    'Drei Line-Ins und Sofort-Playback richten sich an Nutzer mit konkreten Audio-Workflows'
  ],
  null, null, null,
  'Der Field-Recorder für Sounddesigner, Podcaster und alle, die Aufnahmequalität ernst nehmen. Drei Line-Ins, USB-C, 128 GB Speicher, Sofort-Playback direkt am Gerät. Teenage Engineering baut Geräte, die auch als Objekt überzeugen — TP-7 ist eins davon.'
),
(
  'vivo-x300-ultra-smartphone',
  'Alle, die beim Smartphone-Kauf nicht nach dem Mittelfeld schauen, sondern nach dem technisch maximal Ausgestatteten — vor allem bei der Kamera.',
  'Wer ein kompaktes oder günstiges Smartphone sucht — hier stehen Kamera-Ausstattung und Speicher im Vordergrund, nicht der Preis.',
  'Smartphone mit ZEISS-Triple-Prime-Objektiven, 4K-Video bei bis zu 120 fps, 16 GB RAM, 1 TB Speicher, 2K-ZEISS-Master-Color-Display und 6.600-mAh-Akku.',
  array[
    'ZEISS-Triple-Prime-Objektive für 4K-Video bei bis zu 120 fps',
    '1 TB interner Speicher, 16 GB RAM',
    '2K-ZEISS-Master-Color-Display und 6.600-mAh-Akku',
    'Foto-Kit im Lieferumfang enthalten'
  ],
  array[
    'Der große Speicher und das Foto-Kit richten sich an Nutzer, die den Ausstattungsumfang tatsächlich ausschöpfen',
    'Zu Gewicht und Abmessungen liegen in der Produktquelle keine Angaben vor'
  ],
  null, null, null,
  'Kein Kompromiss-Smartphone, sondern das Maximum: ZEISS-Triple-Kamera, 4K bei 120fps, 1 TB Speicher, 6.600-mAh-Akku. Für alle, die aufgehört haben zu vergleichen und einfach das technisch Beste wollen.'
),
(
  'xgimi-horizon-ultra-4k-projektor',
  'Alle, die ein Heimkino wollen, aber keinen Fernseher — oder einen riesigen Zweitbildschirm fürs Wohnzimmer.',
  'Wer einen klassischen Fernseher ohne Projektor-Aufstellung sucht — Abstand zur Projektionsfläche gehört hier zum Setup.',
  '4K-Projektor mit Dolby Vision, 2.300 ISO Lumen und zwei integrierten 12-Watt-Harman-Kardon-Lautsprechern, Bilddiagonale bis 200 Zoll.',
  array[
    '4K mit Dolby Vision und 2.300 ISO Lumen',
    'Zwei Harman-Kardon-Lautsprecher mit je 12 Watt — kein Soundbar-Zwang',
    'Android TV 11 mit integriertem Netflix, YouTube und Prime Video',
    'Automatischer Fokus und automatische Trapezkorrektur'
  ],
  array[
    'Bis zu 200 Zoll Bilddiagonale brauchen entsprechend Abstand und einen abdunkelbaren Raum',
    'Bei bis zu 200 Zoll Bilddiagonale müssen Abstand und Projektionsfläche zum Raum passen'
  ],
  null, null, null,
  'Ein 4K-Beamer mit Dolby Vision und eingebautem Harman-Kardon-Sound, der ohne Soundbar auskommt. Autofokus, Auto-Trapezkorrektur, bis 200 Zoll Bilddiagonale. Für alle, die ein Heimkino wollen, aber keinen Fernseher.'
),
(
  'khadas-mind-2-mini-pc',
  'Menschen, die einen sehr kompakten Rechner für unterwegs wollen und ihr Setup bei Bedarf über Mind-Family-Module erweitern möchten.',
  'Wer Arbeitsspeicher selbst austauschen oder einen klassischen Desktop mit frei wählbaren Komponenten bauen will.',
  'Khadas Mind 2 als portable Workstation: laut Hersteller 435 g leicht, 2 cm dünn, mit Thunderbolt 4, USB4, HDMI 2.1 und Mind-Link-Schnittstelle für Erweiterungsmodule.',
  array[
    '435 g Gewicht und 2 cm Bauhöhe laut Hersteller',
    'Thunderbolt 4, USB4, HDMI 2.1 und zwei USB-A-3.2-Anschlüsse',
    'Magnetische Abdeckung für den M.2-2230-SSD-Steckplatz',
    'Mind Link verbindet den Rechner mit optionalen Erweiterungsmodulen'
  ],
  array[
    'Der Arbeitsspeicher ist laut Hersteller onboard und nicht austauschbar',
    'Erweiterungen setzen auf separate Mind-Family-Module'
  ],
  null, null, null,
  'Ein Mini-PC, der eher wie ein Baustein für ein modulares Setup gedacht ist: 435 Gramm, zwei Zentimeter dünn, Thunderbolt 4 und Mind Link für Dock, Grafikmodul und weitere Erweiterungen. Für Menschen, die ihren Rechner zwischen Tasche und Schreibtisch bewegen.'
),
(
  'fontastic-mesu-bluetooth-lautsprecher',
  'Alle, die Lautsprecher, Beistelltisch und kabelloses Laden in einem Möbelstück verbinden wollen.',
  'Wer einen kleinen Bluetooth-Lautsprecher für unterwegs sucht — der Mesu ist ein 5,9 kg schwerer Tisch mit 61,5 cm Höhe.',
  'Multifunktionstisch mit TWS-Stereo aus zwei 12-Watt-Lautsprechern, Bluetooth 5, AUX, USB-Wiedergabe, Freisprechfunktion und kabelloser Ladefläche.',
  array[
    'Zwei 12-Watt-Lautsprecher mit TWS-Stereo',
    'Bluetooth 5, AUX-In, USB-Wiedergabe und USB-Ladeanschluss',
    'Kabelloses Laden direkt auf der Tischplatte',
    'Integrierter Akku mit laut Hersteller bis zu 6 Stunden Wiedergabe bei 50 Prozent Lautstärke'
  ],
  array[
    'Mit 61,5 × 39,5 × 38,5 cm und 5,9 kg kein mobiles Lautsprecherformat',
    'Die angegebene Wiedergabezeit von 6 Stunden gilt bei 50 Prozent Lautstärke'
  ],
  null, null, null,
  'Der Mesu ist kein Lautsprecher, den man in den Rucksack steckt, sondern ein Tisch, der Musik, Ladefläche und Ablage zusammenzieht. Zwei 12-Watt-Treiber, TWS und kabelloses Laden — ein Möbelstück für Sofa, Schlafzimmer oder Lounge.'
),
(
  'anker-nano-powerbank-magsafe-5000mah',
  'iPhone-Nutzer mit Qi2- oder MagSafe-kompatiblem Case, die unterwegs ohne Kabel nachladen wollen.',
  'Wer ein nicht-magnetisches oder sehr dickes Case nutzt — dafür ist die magnetische Ausrichtung nicht zuverlässig.',
  'Schlanke magnetische Anker-Powerbank mit 5.000 mAh, Qi2-/MagSafe-kompatibler Wireless-Leistung bis 15 W und USB-C-Ausgang bis 20 W.',
  array[
    '5.000 mAh Kapazität bei etwa 8,6 mm Bauhöhe',
    'Bis zu 15 W kabelloses Laden für kompatible Geräte',
    'USB-C-Ausgang mit bis zu 20 W',
    'Laut Hersteller etwa 102 × 70,6 × 8,6 mm und rund 122 g'
  ],
  array[
    'Magnetische Ausrichtung setzt ein kompatibles Gerät oder Case voraus',
    'Die tatsächliche Ladeleistung hängt laut Hersteller vom Gerät und der Nutzung ab'
  ],
  null, null, null,
  'Die Powerbank für den Moment, in dem das iPhone leer wird, aber das Kabel zu Hause liegt: 5.000 mAh, magnetische Qi2-/MagSafe-Ladung bis 15 Watt und USB-C als Ausweichroute. Schlank genug für die Jackentasche — sofern das Case mitspielt.'
);

-- Persistente Audit-Payload fuer die read-only Inhalts- und Sicherheitspruefung
-- nach dem Commit. Die Tabelle entsteht in derselben Transaktion und bleibt
-- fuer das Beobachtungs- und Rollback-Fenster privat erhalten. 05 verlangt sie
-- ausdruecklich als Voraussetzung fuer einen Rollback.
do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v4') is not null then
    raise exception 'Batch-4-Backfill abgebrochen: Audit-Payload v4 existiert bereits.';
  end if;
end $$;

create table cbb_private_backup.value_add_payload_v4 as
select * from cbb_value_add_payload_b4;

alter table cbb_private_backup.value_add_payload_v4
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v4
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
  from cbb_value_add_payload_b4 v
  where p.slug = v.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 12 then
    raise exception 'Batch-4-Backfill abgebrochen: UPDATE traf %/12 Zeilen.',
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
  batch3_vollstaendig integer;
  pros_in_spanne integer;
  cons_mindestens_eins integer;
begin
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v4;

  select count(*) into payload_mismatches
  from public.products p
  join cbb_value_add_payload_b4 v on v.slug = p.slug
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
    ),
    count(*) filter (
      where p.cons is not null and array_length(p.cons, 1) >= 1
    )
  into alternatives, complements, no_relation, inconsistent_relations,
       pros_in_spanne, cons_mindestens_eins
  from public.products p
  join cbb_value_add_payload_b4 v on v.slug = p.slug;

  -- Batch 4 legt keine Relation an. Dieser Zaehler muss deshalb 0 bleiben und
  -- ist der Beleg, dass keine der zwoelf Zeilen eine Alternative ins Leere
  -- zeigen laesst.
  select count(*) into broken_targets
  from public.products p
  join cbb_value_add_payload_b4 v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  select count(*) into changed_timestamps
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v4 b
    on b.id = p.id and b.slug = p.slug
  where p.updated_at is distinct from b.updated_at;

  -- Batch 1 (10) plus Batch 2 (10) plus Batch 3 (10) plus Batch 4 (12) = 42.
  -- Mehr waere ein Treffer ausserhalb der Zielmenge, weniger ein beschaedigter
  -- Vorgaenger.
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

  select count(*) into batch3_vollstaendig
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
  ) and fuer_wen is not null and nicht_fuer is not null
    and key_fact is not null and pros is not null and cons is not null
    and editorial_note is not null;

  if payload_rows <> 12
     or payload_mismatches <> 0
     or alternatives <> 0
     or complements <> 0
     or no_relation <> 12
     or inconsistent_relations <> 0
     or broken_targets <> 0
     or changed_timestamps <> 12
     or value_add_gesamt <> 42
     or batch1_vollstaendig <> 10
     or batch2_vollstaendig <> 10
     or batch3_vollstaendig <> 10
     or pros_in_spanne <> 12
     or cons_mindestens_eins <> 12 then
    raise exception
      'Batch-4-Backfill inkonsistent: payload %, mismatch %, alt %, comp %, ohne %, inkonsistent %, defekt %, lastmod %, value_add_gesamt %, batch1 %, batch2 %, batch3 %, pros %, cons %.',
      payload_rows, payload_mismatches, alternatives, complements, no_relation,
      inconsistent_relations, broken_targets, changed_timestamps,
      value_add_gesamt, batch1_vollstaendig, batch2_vollstaendig,
      batch3_vollstaendig, pros_in_spanne, cons_mindestens_eins;
  end if;
end $$;

commit;
