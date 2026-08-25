-- Nach 05_restore_value_add_batch2.sql: Round-Trip auf ALLE 376 Zeilen geprueft.
do $$
declare
  produkte bigint;
  gesamt_drift integer;
  notes_zurueck integer;
  ziel_ohne_note integer;
  value_add_gesamt integer;
  snapshot_da boolean;
  payload_da boolean;
begin
  select count(*) into produkte from public.products;

  -- editorial_note, updated_at UND die acht Value-Add-Felder muessen fuer jede
  -- einzelne der 376 Zeilen wieder exakt der Baseline entsprechen. Das schliesst
  -- den Trigger mit ein: schriebe products_touch_updated_at() hier now(), waere
  -- dieser Wert <> 0.
  select count(*) into gesamt_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
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

  -- Die zwei Batch-2-Originalnotizen sind wortgleich zurueck.
  select count(*) into notes_zurueck
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug in ('infactory-boyfriend-kissen',
                   'eiswuerfelform-todesstern-star-wars')
    and p.editorial_note = b.editorial_note
    and p.editorial_note like 'ALT-NOTE%';

  -- Die anderen acht Batch-2-Zeilen haben wieder gar keine Notiz.
  select count(*) into ziel_ohne_note
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 s on s.id = p.id
  where p.editorial_note is null;

  -- Nur noch Batch 1 traegt Value-Add-Daten.
  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select to_regclass('cbb_private_backup.value_add_pre_backfill_v2') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v2') is not null
  into snapshot_da, payload_da;

  if produkte <> 376 then
    raise exception 'nach 05: % Produkte (erwartet 376).', produkte;
  end if;
  if gesamt_drift <> 0 then
    raise exception 'nach 05: % von 376 Zeilen weichen von der Baseline ab.', gesamt_drift;
  end if;
  if notes_zurueck <> 2 then
    raise exception 'nach 05: nur %/2 Original-editorial_note wiederhergestellt.', notes_zurueck;
  end if;
  if ziel_ohne_note <> 8 then
    raise exception 'nach 05: % statt 8 Batch-2-Zeilen ohne editorial_note.', ziel_ohne_note;
  end if;
  if value_add_gesamt <> 10 then
    raise exception 'nach 05: % Zeilen tragen Value-Add-Daten (erwartet 10, nur Batch 1).',
      value_add_gesamt;
  end if;
  if not snapshot_da then
    raise exception 'nach 05: Snapshot v2 wurde geloescht — laut Runbook bleibt er bestehen.';
  end if;
  if not payload_da then
    raise exception 'nach 05: Audit-Payload v2 wurde geloescht — laut Runbook bleibt sie bestehen.';
  end if;

  raise notice 'nach 05 OK: 0 Drift auf 376 Zeilen, 2/2 Original-Notizen zurueck, 8 wieder ohne Notiz, nur noch Batch 1 befuellt, Snapshot v2 und Payload v2 erhalten.';
end $$;
