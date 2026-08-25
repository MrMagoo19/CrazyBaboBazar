-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 2 — 03 ATOMARER BACKFILL (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Voraussetzung: 01 FAIL-frei, 02 mit backup_rows = 10, 02b FAIL-frei.
--
-- KEINE SCHEMA-MIGRATION. Diese Datei schreibt ausschliesslich Daten in exakt
-- zehn Zeilen von public.products und legt die private Audit-Payload
-- cbb_private_backup.value_add_payload_v2 an.
--
-- BATCH 1 WIRD NICHT ANGEFASST. Die Tabellen value_add_pre_backfill_v1 und
-- value_add_payload_v1 werden ausschliesslich per to_regclass auf Existenz
-- geprueft. Kein SELECT auf ihren Inhalt, kein UPDATE, kein DROP.
--
-- RELATIONEN: genau zwei strukturierte Triplets, beide innerhalb von Batch 2.
--   kaffeewaermer-tassenwaermer-elektrisch -> gluecksgut-anti-stress-wuerfel
--     kind = complement
--   gluecksgut-anti-stress-wuerfel -> shashibo-formwechsel-box-magnetisch
--     kind = alternative
--   Die anderen acht Zeilen bekommen alternative_slug, alternative_reason und
--   alternative_kind ausdruecklich NULL.
--
-- BEWUSST OHNE STRUKTURIERTE RELATION: infactory-boyfriend-kissen. Der
-- bestehende Beschreibungstext enthaelt bereits einen manuellen Querverweis auf
-- vachichi-boyfriend-kissen-muskuloeser-arm. Ein zweiter, strukturierter
-- Verweis wuerde denselben Hinweis doppelt rendern. Der Guard weiter unten
-- prueft ausdruecklich, dass diese Zeile relationslos bleibt.
--
-- EDITORIAL_NOTE: alle zehn Zeilen bekommen eine editorial_note. Trug eine
-- Zielzeile vorher bereits eine Notiz, wird diese bewusst ueberschrieben. Der
-- Originaltext und der Original-updated_at-Wert liegen im privaten Snapshot
-- cbb_private_backup.value_add_pre_backfill_v2 und werden von
-- 05_restore_value_add_batch2.sql wortgleich zurueckgeholt. Welche Zielzeilen
-- betroffen sind, meldet 02b in der INFO-Zeile
-- snapshot_v2_bestehende_editorial_notes.
--
-- WIEDERHOLUNGSVERHALTEN: ein zweiter Lauf bricht fail-closed ab — entweder am
-- Drift-Guard (die Zielzeilen weichen vom Snapshot ab) oder daran, dass
-- value_add_payload_v2 bereits existiert. Ueberschrieben wird nie.
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
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-2-Backfill abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-2-Backfill abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-2-Backfill abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into target_rows
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
  ) and is_published is true;
  if target_rows <> 10 then
    raise exception 'Batch-2-Backfill abgebrochen: %/10 Zielprodukte published.', target_rows;
  end if;

  select count(*) into relation_rows
  from public.products
  where slug in (
    'gluecksgut-anti-stress-wuerfel',
    'shashibo-formwechsel-box-magnetisch'
  ) and is_published is true;
  if relation_rows <> 2 then
    raise exception 'Batch-2-Backfill abgebrochen: %/2 Relationsziele published.', relation_rows;
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
    raise exception 'Batch-2-Backfill abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-2-Backfill abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-2-Backfill abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-2-Backfill abgebrochen: privater Snapshot v2 fehlt.';
  end if;
  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v2;
  if snapshot_rows <> 10 then
    raise exception 'Batch-2-Backfill abgebrochen: Snapshot v2 hat %/10 Zeilen.', snapshot_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_payload_v2') is not null then
    raise exception 'Batch-2-Backfill abgebrochen: Audit-Payload v2 existiert bereits.';
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
  join cbb_private_backup.value_add_pre_backfill_v2 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 10 then
    raise exception 'Batch-2-Backfill abgebrochen: nur %/10 Zielzeilen gesperrt.', locked_rows;
  end if;

  select count(*) into drift_rows
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 b
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
    raise exception 'Batch-2-Backfill abgebrochen: % Zielzeilen sind seit dem Snapshot gedriftet.',
      drift_rows;
  end if;
end $$;

create temporary table cbb_value_add_payload_b2 (
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

insert into cbb_value_add_payload_b2 (
  slug, fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind, editorial_note
) values
(
  'livondo-terracotta-pflanzenbewaesserung',
  'Zimmerpflanzen-Besitzer, die im Urlaub oder bei unregelmäßigem Gießen eine stromlose Lösung suchen.',
  'Wer eine steuerbare Bewässerung mit Timer und definierter Wassermenge braucht.',
  'Terracotta-Spikes nach dem Ollas-Prinzip: befüllen, in die Erde setzen, das Wasser tritt langsam durch den Ton aus.',
  array[
    'Kommt ohne Strom und Timer aus',
    'Wird befüllt und einfach in die Erde gesetzt',
    'Gibt das Wasser langsam über den Ton ab'
  ],
  array[
    'Wie lange eine Füllung reicht, hängt von Topfgröße, Erde und Standort ab — feste Werte gibt der Hersteller nicht an',
    'Muss von Hand nachgefüllt werden'
  ],
  null, null, null,
  'Das Ollas-Prinzip in klein: befüllen, in die Erde setzen, der Ton gibt das Wasser langsam ab. Ohne Strom, ohne Timer. Wie weit eine Füllung trägt, hängt an Topf, Erde und Standort — feste Werte nennt der Hersteller nicht, ein Testlauf zu Hause klärt das vor der ersten längeren Reise.'
),
(
  'wixies-wichstuecher-scherzartikel',
  'Wer ein derbes Gag-Geschenk sucht und weiß, dass die Runde solchen Humor mitmacht.',
  'Jede Runde, in der derber Humor nicht ankommt — und jeden, der ein ernst gemeintes Geschenk erwartet.',
  '7 bedruckte Servietten, reiner Scherzartikel.',
  array[
    '7 bedruckte Servietten',
    'Der Witz steckt im Aufdruck, nicht in einer Anleitung'
  ],
  array[
    'Der Humor ist bewusst derb und trifft nicht jede Runde',
    'Reiner Scherzartikel ohne praktischen Nutzen'
  ],
  null, null, null,
  'Sieben bedruckte Servietten, ein Witz, fertig. Das Ding lebt komplett von der Reaktion beim Auspacken — Nutzwert gibt es keinen, und das ist auch nicht der Anspruch. Vorher kurz überlegen, ob die Runde diese Sorte Humor mag.'
),
(
  'kaffeewaermer-tassenwaermer-elektrisch',
  'Alle, die am Schreibtisch arbeiten und deren Tasse regelmäßig kalt wird.',
  'Wer unterwegs oder ohne Steckdose warmhalten will — dafür ist ein Thermobecher der richtige Weg.',
  'Hält die Tasse bei 55–65 °C, läuft am Netz und schaltet nach 8 Stunden automatisch ab.',
  array[
    'Temperaturbereich 55–65 °C',
    'Automatische Abschaltung nach 8 Stunden'
  ],
  array[
    'Braucht eine feste Steckdose — nichts für unterwegs',
    'Die automatische Abschaltung greift nach 8 Stunden — danach hält die Platte nicht weiter warm'
  ],
  'gluecksgut-anti-stress-wuerfel',
  'Beides gehört auf denselben Schreibtisch: Der Wärmer hält das Getränk auf Temperatur, der Würfel beschäftigt die Hände nebenher.',
  'complement',
  'Löst genau ein Problem: Der Kaffee bleibt zwischen 55 und 65 Grad, statt in der dritten Meeting-Stunde kalt zu werden. Nach acht Stunden schaltet die Platte von selbst ab. Netzbetrieb heißt aber auch: Der Platz ist da, wo die Steckdose ist.'
),
(
  'gluecksgut-anti-stress-wuerfel',
  'Menschen, die beim Telefonieren, Lesen oder Nachdenken etwas in der Hand brauchen.',
  'Wer ein Spielzeug mit Ziel, Level oder Fortschritt sucht — hier gibt es keinen Spielstand.',
  'Sechs Fidget-Seiten mit Drücken, Drehen, Schieben und Klicken.',
  array[
    'Sechs Seiten mit Drücken, Drehen, Schieben und Klicken',
    'Mehrere Bedienoptionen lassen sich ruhig nutzen',
    'Gedacht für Schreibtisch, Meeting und Fokus-Phasen'
  ],
  array[
    'Nicht alle sechs Seiten lassen sich gleich ruhig bedienen',
    'Reine Handbeschäftigung ohne weiteren Funktionsumfang'
  ],
  'shashibo-formwechsel-box-magnetisch',
  'Ebenfalls eine reine Handbeschäftigung, aber deutlich komplexer: Die magnetische Box lässt sich immer wieder in neue Formen falten, statt nur gedrückt und geschoben zu werden.',
  'alternative',
  'Sechs Seiten, vier Bewegungen: drücken, drehen, schieben, klicken. Für Hände, die beim Denken nicht stillhalten — am Schreibtisch, im Meeting, in der Fokus-Stunde. Wer es ruhig braucht, bleibt bei den entsprechenden Bedienoptionen.'
),
(
  'infactory-boyfriend-kissen',
  'Alle, die den Gag mögen: ein Kissen, das wie ein Pyjama-Oberteil samt Arm aussieht.',
  'Wer ein unauffälliges Kissen sucht — die Pyjama-Form mit Arm bleibt sichtbar.',
  'Kissen in Form eines Pyjama-Oberteils mit Arm, ca. 54 × 50 cm, bei 30 °C waschbar.',
  array[
    'Bei 30 °C waschbar',
    'Realistisch wirkendes Pyjama-Oberteil mit Arm statt reiner Kissenform',
    'Maße von etwa 54 × 50 cm'
  ],
  array[
    'Die Optik ist Geschmackssache und als Geschenk nicht immer sicher',
    'Waschbar nur bei 30 °C — mehr gibt der Hersteller nicht an'
  ],
  null, null, null,
  'Ein Kissen, das aussieht wie ein Pyjama-Oberteil samt Arm — halb Gag, halb Kuschelobjekt. Rund 54 × 50 cm, bei 30 Grad waschbar. Als Geschenk gilt: Es kommt entweder sehr gut an oder gar nicht.'
),
(
  'scheisse-quartett-kartenspiel',
  'Runden, die ein Kartenspiel mit derbem Thema mögen — zu Hause oder unterwegs.',
  'Wer das Thema nicht witzig findet — es zieht sich durch alle 32 Figuren.',
  'Klassisches Quartett mit 32 Figuren im Reiseformat.',
  array[
    'Klassisches Quartettprinzip, wie man es kennt',
    '32 Figuren im Set',
    'Reiseformat'
  ],
  array[
    'Das Thema ist bewusst derb und nicht für jede Runde',
    'Am klassischen Quartettprinzip ändert das Spiel nichts'
  ],
  null, null, null,
  'Quartett, wie man es kennt, nur mit 32 Figuren, über die man sonst nicht spricht. Das Reiseformat nimmt man mit, das Prinzip kennt am Tisch ohnehin jeder. Ob es lustig ist, entscheidet die Runde — nicht die Anleitung.'
),
(
  'riesige-aufblasbare-ente-pool',
  'Pool- und Badesee-Besitzer, die ein großes Deko- und Fotoobjekt wollen.',
  'Kleine Pools und enge Balkone — 1,2 m brauchen Platz im Wasser und beim Verstauen.',
  '1,2 m große aufblasbare Ente aus PVC mit Schnellventil.',
  array[
    '1,2 m Größe, entsprechend sichtbar',
    'Schnellventil zum zügigen Auf- und Ablassen',
    'PVC, lässt sich luftleer zusammenlegen'
  ],
  array[
    'Braucht einen entsprechend großen Pool oder See',
    'Zu Alter, Sicherheit und Belastbarkeit liegen keine verifizierten Herstellerangaben vor'
  ],
  null, null, null,
  '1,2 Meter Ente aus PVC — eine Ansage im Wasser. Das Schnellventil macht Auf- und Abbau erträglich, danach passt sie zusammengelegt in den Schrank. Wichtig: Zu Altersfreigabe, Sicherheit und Belastbarkeit liegen uns keine verifizierten Angaben vor.'
),
(
  'shashibo-formwechsel-box-magnetisch',
  'Bastelnde Hände ab 6 Jahren und Erwachsene, die eine Handbeschäftigung mit etwas Anspruch suchen.',
  'Kinder unter 6 Jahren — der Hersteller gibt die Box ab 6 frei.',
  'Magnetische Box, laut Produktdaten über 70 Formen, ohne Batterie und App, ab 6 Jahren.',
  array[
    'Laut Produktdaten über 70 Formen aus einem Objekt',
    'Kommt ohne Batterie und App aus',
    'Magnetisch aufgebaut'
  ],
  array[
    'Erst ab 6 Jahren freigegeben',
    'Die Zahl von über 70 Formen stammt aus den Produktdaten, nicht aus einem eigenen Test'
  ],
  null, null, null,
  'Eine magnetische Box, die sich immer wieder neu falten lässt — laut Produktdaten in über 70 Formen. Ohne Batterie, ohne App. Für Hände, denen ein Fidget-Würfel zu schnell langweilig wird. Freigegeben ab 6 Jahren.'
),
(
  'eiswuerfelform-todesstern-star-wars',
  'Star-Wars-Fans, die ihre Getränke thematisch aufwerten wollen.',
  'Wer viel Eis auf einmal braucht — die Form macht drei Kugeln pro Durchgang.',
  'Form aus lebensmittelechtem Silikon für drei Star-Wars-Eiskugeln im Todesstern-Design.',
  array[
    'Lebensmittelechtes Silikon',
    'Drei Eiskugeln pro Durchgang',
    'Todesstern-Design statt Standardwürfel'
  ],
  array[
    'Nur drei Kugeln pro Füllung',
    'Zu Handhabung und Gefrierdauer macht der Hersteller keine Angaben'
  ],
  null, null, null,
  'Drei Todesstern-Kugeln pro Durchgang, aus lebensmittelechtem Silikon. Für Fans ein naheliegendes Mitbringsel, für eine größere Runde eher knapp bemessen — wer mehr braucht, braucht mehrere Formen.'
),
(
  'katzenschlafsack-fuer-menschen',
  'Alle, die auf dem Sofa im Ganzen eingepackt sein wollen und trotzdem die Hände frei brauchen.',
  'Wer ein unauffälliges Sofa-Accessoire sucht — die Kapuze mit Katzenohren ist hier gesetzt.',
  'Schlafsack mit Katzenohren-Kapuze, Armlöchern, weichem Innenfutter und Reißverschluss, Größen S bis XL.',
  array[
    'Armlöcher lassen die Hände frei',
    'Kapuze mit Katzenohren',
    'Weiches Innenfutter',
    'Reißverschluss zum schnellen Rein und Raus'
  ],
  array[
    'Die Optik ist Geschmackssache',
    'Vier Größen von S bis XL — vor dem Kauf die Maßtabelle prüfen'
  ],
  null, null, null,
  'Ein Schlafsack für Menschen, die auf dem Sofa gern vollständig verschwinden. Die Armlöcher sind der eigentliche Trick: Die Hände bleiben frei für Buch, Tasse oder Fernbedienung. Kapuze mit Ohren gehört dazu. Vier Größen von S bis XL, also vorher die Maße vergleichen.'
);

-- Persistente Audit-Payload fuer die read-only Inhalts- und Sicherheitspruefung
-- nach dem Commit. Die Tabelle entsteht in derselben Transaktion und bleibt
-- fuer das Beobachtungs- und Rollback-Fenster privat erhalten.
do $$
begin
  if to_regclass('cbb_private_backup.value_add_payload_v2') is not null then
    raise exception 'Batch-2-Backfill abgebrochen: Audit-Payload v2 existiert bereits.';
  end if;
end $$;

create table cbb_private_backup.value_add_payload_v2 as
select * from cbb_value_add_payload_b2;

alter table cbb_private_backup.value_add_payload_v2
  add primary key (slug),
  enable row level security;

revoke all on cbb_private_backup.value_add_payload_v2
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
  from cbb_value_add_payload_b2 v
  where p.slug = v.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 10 then
    raise exception 'Batch-2-Backfill abgebrochen: UPDATE traf %/10 Zeilen.',
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
  infactory_relationslos integer;
begin
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v2;

  select count(*) into payload_mismatches
  from public.products p
  join cbb_value_add_payload_b2 v on v.slug = p.slug
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
  join cbb_value_add_payload_b2 v on v.slug = p.slug;

  select count(*) into broken_targets
  from public.products p
  join cbb_value_add_payload_b2 v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  select count(*) into changed_timestamps
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 b
    on b.id = p.id and b.slug = p.slug
  where p.updated_at is distinct from b.updated_at;

  -- Batch 1 (10 Zeilen) plus Batch 2 (10 Zeilen) = 20. Mehr waere ein Treffer
  -- ausserhalb der Zielmenge, weniger ein beschaedigter Batch 1.
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

  -- Die bewusste Ausnahme: infactory bleibt strukturell relationslos.
  select count(*) into infactory_relationslos
  from public.products
  where slug = 'infactory-boyfriend-kissen'
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
     or value_add_gesamt <> 20
     or batch1_vollstaendig <> 10
     or infactory_relationslos <> 1 then
    raise exception
      'Batch-2-Backfill inkonsistent: payload %, mismatch %, alt %, comp %, ohne %, inkonsistent %, defekt %, lastmod %, value_add_gesamt %, batch1 %, infactory %.',
      payload_rows, payload_mismatches, alternatives, complements, no_relation,
      inconsistent_relations, broken_targets, changed_timestamps,
      value_add_gesamt, batch1_vollstaendig, infactory_relationslos;
  end if;
end $$;

commit;
