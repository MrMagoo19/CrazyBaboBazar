-- ============================================================================
-- ASSERT — Ausgangszustand vor dem N4-Korrekturpaket
-- ============================================================================
-- Beweist, dass die Vorlage-Datenbank exakt den Zustand hat, den 01/02/04 als
-- Vorzustand voraussetzen: abgeschlossener Value-Add-Rollout (Snapshot und
-- Audit-Payload je 10 Zeilen), 376 Produkte, N4 published und mit exakt den
-- sieben erwarteten Feldwerten. Noch kein N4-Backup.
-- ============================================================================

do $$
declare
  produkte bigint;
  snapshot_rows integer;
  payload_rows integer;
  n4_published integer;
  n4_vorzustand integer;
begin
  select count(*) into produkte from public.products;
  if produkte <> 376 then
    raise exception 'Basiszustand: % Produkte (erwartet 376).', produkte;
  end if;

  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v1;
  if snapshot_rows <> 10 or payload_rows <> 10 then
    raise exception 'Basiszustand: Snapshot %, Payload % (erwartet 10/10).',
      snapshot_rows, payload_rows;
  end if;

  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is not null then
    raise exception 'Basiszustand: n4_content_pre_fix_v1 existiert bereits.';
  end if;

  select count(*) into n4_published
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch' and is_published is true;
  if n4_published <> 1 then
    raise exception 'Basiszustand: %/1 N4-Zeile published.', n4_published;
  end if;

  select count(*) into n4_vorzustand
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and tagline is not distinct from
      '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten'
    and description is not distinct from
      'N4 Nussmilchbereiter für frische Pflanzenmilch. Hafer-, Mandel-, Soja-, Reis- oder Cashew-Milch in 15 Minuten. Mixt, kocht, filtert automatisch. Für Menschen, die Bio-Milch-Preise satt haben und ihre Zutaten selbst kontrollieren wollen. Amortisiert sich nach 2 Monaten täglichem Frühstück.'
    and nicht_fuer is not distinct from
      'Wer nur selten mal Hafermilch trinkt — die Anschaffung amortisiert sich dann kaum.'
    and key_fact is not distinct from
      '800-W-Bereiter mit Selbstreinigung für Hafer-, Mandel-, Soja-, Reis- und Cashew-Milch.'
    and pros is not distinct from array[
      'Mixt, kocht und filtert automatisch',
      'Selbstreinigung',
      'Fünf Milchsorten',
      '800 W'
    ]::text[]
    and cons is not distinct from array[
      'Lohnt sich nur bei regelmäßigem Konsum',
      'Ein weiteres Küchengerät, das gereinigt werden will'
    ]::text[]
    and editorial_note is not distinct from
      'Macht frische Pflanzenmilch auf Knopfdruck und reinigt sich selbst. Für Menschen, die Milch-Alternativen ernst nehmen und die Bio-Laden-Preise satt haben. Lohnt sich, wenn täglich getrunken — sonst steht er nur rum.';
  if n4_vorzustand <> 1 then
    raise exception 'Basiszustand: N4-Vorzustand weicht ab (%/1 Treffer).',
      n4_vorzustand;
  end if;

  raise notice 'Basiszustand OK: 376 Produkte, Value-Add 10/10, N4 exakt im erwarteten Vorzustand, kein N4-Backup.';
end $$;
