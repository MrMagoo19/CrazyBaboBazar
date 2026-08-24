-- Nach 06_restore_value_add.sql: Round-Trip auf ALLE 376 Zeilen geprueft.
do $$
declare
  gesamt_drift integer;
  notes_zurueck integer;
  ziel_leer integer;
  value_add_gesamt integer;
  snapshot_da boolean;
  payload_da boolean;
  produkte bigint;
begin
  select count(*) into produkte from public.products;

  -- editorial_note UND updated_at muessen fuer jede einzelne der 376 Zeilen
  -- wieder exakt der Baseline entsprechen. Das schliesst den Trigger mit ein:
  -- schriebe products_touch_updated_at() hier now(), waere dieser Wert <> 0.
  select count(*) into gesamt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at;

  select count(*) into notes_zurueck
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug in ('ninja-staysharp-messerset-6-teilig',
                   'n4-nussmilchbereiter-pflanzenmilch',
                   'welpen-usb-ladekabel-hunde-design')
    and p.editorial_note = b.editorial_note
    and p.editorial_note like 'ALT-NOTE%';

  select count(*) into ziel_leer
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v1 s on s.id = p.id
  where p.editorial_note is null;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v1') is not null
  into snapshot_da, payload_da;

  if produkte <> 376 then
    raise exception 'nach 06: % Produkte (erwartet 376).', produkte;
  end if;
  if gesamt_drift <> 0 then
    raise exception 'nach 06: % von 376 Zeilen weichen in editorial_note/updated_at von der Baseline ab.',
      gesamt_drift;
  end if;
  if notes_zurueck <> 3 then
    raise exception 'nach 06: nur %/3 Original-editorial_note wiederhergestellt.', notes_zurueck;
  end if;
  if ziel_leer <> 7 then
    raise exception 'nach 06: % statt 7 Zielprodukte ohne editorial_note.', ziel_leer;
  end if;
  if value_add_gesamt <> 0 then
    raise exception 'nach 06: % Zeilen tragen noch Value-Add-Daten (erwartet 0).',
      value_add_gesamt;
  end if;
  if not snapshot_da then
    raise exception 'nach 06: Snapshot wurde geloescht — laut Runbook bleibt er bestehen.';
  end if;
  if not payload_da then
    raise exception 'nach 06: Audit-Payload wurde geloescht — laut Runbook bleibt sie bestehen.';
  end if;

  raise notice 'nach 06 OK: 0 Drift auf 376 Zeilen, 3/3 Original-Notizen zurueck, 7 wieder ohne Notiz, 0 Value-Add-Daten, Snapshot und Payload erhalten.';
end $$;
