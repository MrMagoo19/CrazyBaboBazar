-- ============================================================================
-- FIXTURE 05 — Baseline des gesamten Bestands und beider Vorgaenger-Artefakte
-- ============================================================================
-- Die Baseline haelt fuer JEDE der 376 Produktzeilen die Felder fest, die ein
-- Value-Add-Lauf ueberhaupt anfassen koennte, sowie den vollstaendigen Inhalt
-- der vier privaten v1-/v2-Tabellen. Damit kann jeder spaetere Fall nicht nur
-- pruefen "meine zehn Zeilen stimmen", sondern die viel schaerfere Frage
-- beantworten: "hat sich AUSSERHALB der Zielmenge irgendetwas bewegt?"
--
-- Die Baseline gehoert zum Testaufbau und ist bewusst KEIN Artefakt des
-- Rollouts. Sie liegt deshalb in einem eigenen Schema, das auf Production
-- nicht existiert und von keiner Originaldatei referenziert wird.
--
-- Diese Datei laeuft erst NACH fixture/03_v1_v2_artifacts.sql — vorher gaebe
-- es die Vorgaenger-Tabellen nicht.
-- ============================================================================

create schema cbb_test_baseline;

create table cbb_test_baseline.products_before as
select
  id, slug, editorial_note, updated_at,
  fuer_wen, nicht_fuer, key_fact, pros, cons,
  alternative_slug, alternative_reason, alternative_kind,
  is_published
from public.products;

alter table cbb_test_baseline.products_before add primary key (id);

create table cbb_test_baseline.v1_snapshot_before as
select * from cbb_private_backup.value_add_pre_backfill_v1;

create table cbb_test_baseline.v1_payload_before as
select * from cbb_private_backup.value_add_payload_v1;

create table cbb_test_baseline.v2_snapshot_before as
select * from cbb_private_backup.value_add_pre_backfill_v2;

create table cbb_test_baseline.v2_payload_before as
select * from cbb_private_backup.value_add_payload_v2;

do $$
declare
  produkte bigint;
  v1s bigint;
  v1p bigint;
  v2s bigint;
  v2p bigint;
begin
  select count(*) into produkte from cbb_test_baseline.products_before;
  select count(*) into v1s from cbb_test_baseline.v1_snapshot_before;
  select count(*) into v1p from cbb_test_baseline.v1_payload_before;
  select count(*) into v2s from cbb_test_baseline.v2_snapshot_before;
  select count(*) into v2p from cbb_test_baseline.v2_payload_before;

  if produkte <> 376 then
    raise exception 'Baseline kaputt: % Produktzeilen (erwartet 376).', produkte;
  end if;
  if v1s <> 10 or v1p <> 10 or v2s <> 10 or v2p <> 10 then
    raise exception 'Baseline kaputt: Vorgaenger % / % / % / % (erwartet je 10).',
      v1s, v1p, v2s, v2p;
  end if;

  raise notice 'Baseline OK: 376 Produktzeilen und vier Vorgaenger-Tabellen mit je 10 Zeilen gesichert.';
end $$;
