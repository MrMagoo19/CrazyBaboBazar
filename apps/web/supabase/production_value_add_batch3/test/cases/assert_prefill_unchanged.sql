-- Nach dem Abbruch am vorbefuellten Ziel: der fremde Text steht unveraendert
-- da, es wurde nichts ueberschrieben und kein v3-Artefakt angelegt.
do $$
declare
  fremd_text text;
  befuellt integer;
  value_add_gesamt integer;
begin
  select key_fact into fremd_text from public.products
  where slug = 'rocketbook-wiederverwendbares-notizbuch-a4';
  if fremd_text is distinct from 'FREMD: dieser Text stammt nicht aus Batch 3.' then
    raise exception 'Der fremde Text wurde veraendert: %', coalesce(fremd_text, 'NULL');
  end if;

  select count(*) into befuellt from public.products
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
  ) and (fuer_wen is not null or nicht_fuer is not null or key_fact is not null
      or pros is not null or cons is not null or alternative_slug is not null
      or alternative_reason is not null or alternative_kind is not null);
  if befuellt <> 1 then
    raise exception 'Der abgebrochene Lauf hat weitere Zielzeilen befuellt: % (erwartet 1).',
      befuellt;
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 21 then
    raise exception 'Unerwartete Gesamtbefuellung: % (erwartet 21 = 20 plus die eine Fremdzeile).',
      value_add_gesamt;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
     or to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Der abgebrochene Lauf hat ein v3-Artefakt angelegt.';
  end if;

  raise notice 'Vorbefuellte Zeile unveraendert, keine weiteren Treffer, keine v3-Artefakte.';
end $$;
