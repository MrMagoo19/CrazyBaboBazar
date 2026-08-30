-- Zustand nach 05_restore_value_add_batch3.sql: die zehn Zielzeilen sehen
-- wieder exakt aus wie in der Baseline — inklusive der zehn Originalnotizen
-- und der zehn historischen Zeitstempel. Snapshot und Payload leben weiter.
do $$
declare
  ziel_drift integer;
  value_add_gesamt integer;
  notes integer;
  distinct_updated integer;
  snapshot_da boolean;
  payload_da boolean;
  gesamt_drift integer;
begin
  select count(*) into ziel_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug in (
      'bartesian-cocktailmaschine-mit-kapseln',
      'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
      'laptop-staender-hoehenverstellbar-360-drehbar',
      'tecknet-ergonomische-kabellose-maus-bluetooth',
      'rocketbook-wiederverwendbares-notizbuch-a4',
      'ticktime-tk3-wuerfel-timer-countdown',
      'kabeltasche-edc-elektronik-organizer-reise',
      'silikon-magnete-airfryer-backpapier-4er-set',
      'tre-feuerstahl-xxl',
      'bbq-wuerstchenhalter-maennchen-3er-set')
    and (p.editorial_note is distinct from b.editorial_note
      or p.updated_at is distinct from b.updated_at
      or p.fuer_wen is distinct from b.fuer_wen
      or p.nicht_fuer is distinct from b.nicht_fuer
      or p.key_fact is distinct from b.key_fact
      or p.pros is distinct from b.pros
      or p.cons is distinct from b.cons
      or p.alternative_slug is distinct from b.alternative_slug
      or p.alternative_reason is distinct from b.alternative_reason
      or p.alternative_kind is distinct from b.alternative_kind);
  if ziel_drift <> 0 then
    raise exception 'Nach 05: % Zielzeilen weichen von der Baseline ab.', ziel_drift;
  end if;

  -- Nach dem Rollback ist der Ausgangszustand wieder da: 20 befuellte Zeilen.
  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 20 then
    raise exception 'Nach 05: % Zeilen mit Value-Add (erwartet 20).', value_add_gesamt;
  end if;

  select count(*) filter (where editorial_note is not null), count(distinct updated_at)
  into notes, distinct_updated
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
    'bbq-wuerstchenhalter-maennchen-3er-set');
  -- Zehn unterschiedliche Zeitstempel beweisen, dass 05 die historischen Werte
  -- zurueckgespielt hat und nicht alle auf now() gesetzt wurden.
  if notes <> 10 or distinct_updated <> 10 then
    raise exception 'Nach 05: % Notizen, % unterschiedliche Zeitstempel (erwartet je 10).',
      notes, distinct_updated;
  end if;

  select to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null,
         to_regclass('cbb_private_backup.value_add_payload_v3') is not null
  into snapshot_da, payload_da;
  if not snapshot_da then
    raise exception 'Nach 05: der Snapshot v3 wurde geloescht — 05 darf ihn nicht anfassen.';
  end if;
  if not payload_da then
    raise exception 'Nach 05: die Payload v3 wurde geloescht — 05 darf sie nicht anfassen.';
  end if;

  -- Der gesamte Bestand entspricht wieder der Baseline, nicht nur die zehn.
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
  if gesamt_drift <> 0 then
    raise exception 'Nach 05: % Zeilen im Gesamtbestand weichen von der Baseline ab.',
      gesamt_drift;
  end if;

  raise notice 'Nach 05 OK: Bestand identisch zur Baseline, Snapshot und Payload v3 erhalten.';
end $$;
