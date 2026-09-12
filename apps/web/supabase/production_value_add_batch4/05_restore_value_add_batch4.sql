-- ============================================================================
-- PRODUCTION VALUE-ADD BATCH 4 — 05 DATEN-RESTORE (SCHREIBEND, NUR ROLLBACK)
-- ============================================================================
-- WARNUNG — SCHREIBENDE DATEI, NUR IM ROLLBACK-FALL:
--   Diese Datei veraendert die Datenbank. Sie darf NUR mit einer eigenen,
--   NEUEN, ausdruecklichen Benutzerfreigabe ausgefuehrt werden — die Freigabe
--   fuer 02 oder 03 gilt hier ausdruecklich NICHT. Vor dem Start ist im
--   SQL-Editor SICHTBAR gegenzupruefen, dass exakt dieses Projekt ausgewaehlt
--   ist:
--     project/ydiihvzcxaaoqhmgoqvu
--   Pilot/Staging (nmzuycveumyfvtxdcnuc) ist KEIN Ziel dieses Changesets. Wer
--   die Projektkennung nicht sichtbar geprueft hat, fuehrt diese Datei nicht
--   aus.
--
-- WAS DIESE DATEI TUT: Sie stellt exakt die zwoelf Zeilen aus
-- cbb_private_backup.value_add_pre_backfill_v4 wieder her — editorial_note,
-- updated_at und die acht Value-Add-Felder. Danach sieht Batch 4 aus wie vor
-- Schritt 03.
--
-- WAS SIE NICHT TUT:
--   * Sie loescht den Snapshot v4 NICHT.
--   * Sie loescht die Audit-Payload v4 NICHT. Beide bleiben fuer das
--     Beobachtungsfenster erhalten und sind Voraussetzung fuer einen
--     nachvollziehbaren Befund.
--   * Sie fasst Batch 1, Batch 2 und Batch 3 NICHT an (weder deren private
--     Artefakte noch deren dreissig Produktzeilen).
--   * Es gibt bewusst KEINE Down-Migration in Batch 4. Die acht Spalten und
--     die zwei Constraints tragen Batch 1, 2 und 3 und duerfen nicht entfernt
--     werden.
--
-- REIN ROLLBACK, NICHT IDEMPOTENT — UNTERSCHIED ZU BATCH 3:
--   Diese Datei laeuft ausschliesslich, wenn BEIDES gilt:
--     (a) cbb_private_backup.value_add_payload_v4 existiert und traegt zwoelf
--         Zeilen, und
--     (b) alle zwoelf Zielzeilen in public.products stehen exakt im
--         Zustand NACH dem Backfill, also feldgleich zur Payload v4.
--   Trifft eines von beidem nicht zu, bricht die Datei fail-closed ab und
--   schreibt nichts. Damit ist ausgeschlossen, dass ein Restore einen anderen
--   als den von 03 erzeugten Zustand ueberschreibt.
--
--   Folge: ein ZWEITER Lauf bricht ebenfalls ab — nach dem ersten
--   erfolgreichen Rollback stehen die Zeilen im Snapshot-Zustand und nicht
--   mehr im Payload-Zustand. Das ist Absicht und der bewusste Unterschied zu
--   Batch 3, dessen 05 idempotent war. Dieser Fall wird mit einer eigenen,
--   eindeutigen Meldung gemeldet ("bereits zurueckgespielt"), damit er nicht
--   mit einem echten Fremdzugriff verwechselt wird. Auch dieser Ausgang
--   schreibt nichts.
--
--   updated_at ist bewusst NICHT Teil des Payload-Vergleichs: 03 setzt dort
--   now(), der Wert ist deshalb nicht vorhersagbar. Der historische Zeitstempel
--   kommt beim Zurueckspielen aus dem Snapshot. Der Trigger
--   products_set_updated_at ueberschreibt ein ausdruecklich mitgeschriebenes
--   updated_at nicht — genau darauf stuetzt sich das Zurueckspielen.
--
-- BEWUSSTE GRENZE DER GUARDS (siehe RUNBOOK Abschnitt 8): dieser Rollback
-- prueft ausschliesslich seine eigenen zwoelf Zeilen. Er zaehlt NICHT, wie
-- viele Produkte insgesamt Value-Add-Daten tragen. Grund: eine spaetere Charge
-- 5 wuerde diese Zahl veraendern und wuerde damit einen dringend noetigen
-- Rollback von Batch 4 blockieren. Ein Rollback darf nie an einem Zustand
-- scheitern, den er gar nicht anfasst.
--
-- Aus demselben Grund verlangt der Guard die Artefakte von Batch 1, 2 und 3
-- nur als EXISTENZ und prueft ihren Inhalt nicht: sie sind Beleg dafuer, dass
-- die Umgebung die erwartete ist, und nicht Gegenstand dieses Rollbacks.
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
  backup_rows integer;
  payload_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Batch-4-Restore abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Batch-4-Restore abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Batch-4-Restore abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- Bewusst OHNE is_published: ein Rollback muss auch dann laufen, wenn eine
  -- Zielseite zwischenzeitlich offline genommen wurde.
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
  );
  if target_rows <> 12 then
    raise exception 'Batch-4-Restore abgebrochen: %/12 Zielprodukte vorhanden.', target_rows;
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
    raise exception 'Batch-4-Restore abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v4') is null then
    raise exception 'Batch-4-Restore abgebrochen: privater Snapshot v4 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.value_add_pre_backfill_v4;
  if backup_rows <> 12 then
    raise exception 'Batch-4-Restore abgebrochen: Snapshot v4 hat %/12 Zeilen.', backup_rows;
  end if;

  -- HARTE VORAUSSETZUNG: ohne die Audit-Payload v4 gibt es keinen belegten
  -- Nachzustand, gegen den sich ein Rollback rechtfertigen liesse. Dann bricht
  -- die Datei ab, statt zu raten.
  if to_regclass('cbb_private_backup.value_add_payload_v4') is null then
    raise exception 'Batch-4-Restore abgebrochen: Audit-Payload v4 fehlt — ohne sie ist der Nachzustand nicht belegt und es wird nichts geschrieben.';
  end if;
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v4;
  if payload_rows <> 12 then
    raise exception 'Batch-4-Restore abgebrochen: Audit-Payload v4 hat %/12 Zeilen.', payload_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-1-Snapshot v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-1-Payload v1 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-2-Snapshot v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v2') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-2-Payload v2 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-3-Snapshot v3 fehlt.';
  end if;
  if to_regclass('cbb_private_backup.value_add_payload_v3') is null then
    raise exception 'Batch-4-Restore abgebrochen: Batch-3-Payload v3 fehlt.';
  end if;
end $$;

do $$
declare
  locked_rows integer;
  affected_rows integer;
  mismatch_rows integer;
  payload_uebereinstimmung integer;
  bereits_zurueckgespielt integer;
begin
  perform p.id
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v4 b
    on b.id = p.id and b.slug = p.slug
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 12 then
    raise exception 'Batch-4-Restore abgebrochen: nur %/12 Zielzeilen gesperrt.',
      locked_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Der Nachzustand aus 03 muss noch exakt so dastehen. Nur dann ist dieser
  -- Rollback der Rollback von Batch 4 und nicht das Ueberschreiben eines
  -- fremden Zustands. updated_at bleibt bewusst aussen vor (siehe Kopf).
  -- ---------------------------------------------------------------------
  select count(*) into payload_uebereinstimmung
  from public.products p
  join cbb_private_backup.value_add_payload_v4 v on v.slug = p.slug
  where p.fuer_wen is not distinct from v.fuer_wen
    and p.nicht_fuer is not distinct from v.nicht_fuer
    and p.key_fact is not distinct from v.key_fact
    and p.pros is not distinct from v.pros
    and p.cons is not distinct from v.cons
    and p.alternative_slug is not distinct from v.alternative_slug
    and p.alternative_reason is not distinct from v.alternative_reason
    and p.alternative_kind is not distinct from v.alternative_kind
    and p.editorial_note is not distinct from v.editorial_note;

  if payload_uebereinstimmung <> 12 then
    -- Sonderfall mit eigener Meldung: der Rollback lief bereits. Dann stehen
    -- alle zwoelf Zeilen schon feldgleich zum Snapshot. Auch dieser Ausgang
    -- schreibt nichts.
    select count(*) into bereits_zurueckgespielt
    from public.products p
    join cbb_private_backup.value_add_pre_backfill_v4 b
      on b.id = p.id and b.slug = p.slug
    where p.editorial_note is not distinct from b.editorial_note
      and p.updated_at is not distinct from b.updated_at
      and p.fuer_wen is not distinct from b.fuer_wen
      and p.nicht_fuer is not distinct from b.nicht_fuer
      and p.key_fact is not distinct from b.key_fact
      and p.pros is not distinct from b.pros
      and p.cons is not distinct from b.cons
      and p.alternative_slug is not distinct from b.alternative_slug
      and p.alternative_reason is not distinct from b.alternative_reason
      and p.alternative_kind is not distinct from b.alternative_kind;

    if bereits_zurueckgespielt = 12 then
      raise exception 'Batch-4-Restore abgebrochen: bereits zurueckgespielt — alle 12 Zielzeilen stehen schon im Snapshot-Zustand, es gibt nichts zurueckzuholen.';
    end if;

    raise exception 'Batch-4-Restore abgebrochen: nur %/12 Zielzeilen stehen im Zustand nach 03 (davon %/12 bereits im Snapshot-Zustand). Es wurde nichts geschrieben — Ursache klaeren.',
      payload_uebereinstimmung, bereits_zurueckgespielt;
  end if;

  update public.products p set
    editorial_note = b.editorial_note,
    updated_at = b.updated_at,
    fuer_wen = b.fuer_wen,
    nicht_fuer = b.nicht_fuer,
    key_fact = b.key_fact,
    pros = b.pros,
    cons = b.cons,
    alternative_slug = b.alternative_slug,
    alternative_reason = b.alternative_reason,
    alternative_kind = b.alternative_kind
  from cbb_private_backup.value_add_pre_backfill_v4 b
  where p.id = b.id and p.slug = b.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 12 then
    raise exception 'Batch-4-Restore abgebrochen: UPDATE traf %/12 Zeilen.', affected_rows;
  end if;

  select count(*) into mismatch_rows
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
  if mismatch_rows <> 0 then
    raise exception 'Batch-4-Restore inkonsistent: % Snapshot-Abweichungen.', mismatch_rows;
  end if;
end $$;

-- Letzter Beleg innerhalb derselben Transaktion: Snapshot und Payload leben
-- weiter, Batch 1, 2 und 3 sind unangetastet.
do $$
declare
  snapshot_da boolean;
  payload_da boolean;
  v1_snapshot_da boolean;
  v1_payload_da boolean;
  v2_snapshot_da boolean;
  v2_payload_da boolean;
  v3_snapshot_da boolean;
  v3_payload_da boolean;
begin
  select to_regclass('cbb_private_backup.value_add_pre_backfill_v4') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v4') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v3') is not null
  into snapshot_da, payload_da, v1_snapshot_da, v1_payload_da,
       v2_snapshot_da, v2_payload_da, v3_snapshot_da, v3_payload_da;

  if not snapshot_da then
    raise exception 'Batch-4-Restore abgebrochen: Snapshot v4 waehrend des Laufs verschwunden.';
  end if;
  -- Anders als in Batch 3 ist die Payload hier KEINE blosse Protokollnotiz,
  -- sondern harte Voraussetzung. Ihr Verschwinden waehrend des Laufs ist
  -- deshalb ein Abbruchgrund.
  if not payload_da then
    raise exception 'Batch-4-Restore abgebrochen: Audit-Payload v4 waehrend des Laufs verschwunden.';
  end if;
  if not v1_snapshot_da or not v1_payload_da
     or not v2_snapshot_da or not v2_payload_da
     or not v3_snapshot_da or not v3_payload_da then
    raise exception 'Batch-4-Restore abgebrochen: Vorgaenger-Artefakt waehrend des Laufs verschwunden (v1 %/%, v2 %/%, v3 %/%).',
      v1_snapshot_da, v1_payload_da, v2_snapshot_da, v2_payload_da,
      v3_snapshot_da, v3_payload_da;
  end if;
  raise notice 'Batch-4-Restore: 12 Zeilen zurueckgespielt. Snapshot v4 und Payload v4 erhalten, Batch 1, 2 und 3 unangetastet. Ein zweiter Lauf bricht ab.';
end $$;

commit;
