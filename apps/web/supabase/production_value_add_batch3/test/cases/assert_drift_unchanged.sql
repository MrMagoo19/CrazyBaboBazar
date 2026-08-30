-- Nach dem Drift-Abbruch: die fremde Aenderung steht unveraendert da, es wurde
-- keine Zielzeile befuellt und keine Payload angelegt.
do $$
declare
  fremde_notiz text;
  befuellt integer;
  payload_da boolean;
  snapshot_da boolean;
begin
  select editorial_note into fremde_notiz from public.products
  where slug = 'ticktime-tk3-wuerfel-timer-countdown';
  if fremde_notiz is distinct from
     'DRIFT: jemand anderes hat diese Notiz nach dem Snapshot geaendert.' then
    raise exception 'Die fremde Aenderung wurde ueberschrieben: %',
      coalesce(fremde_notiz, 'NULL');
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
  if befuellt <> 0 then
    raise exception 'Trotz Drift-Abbruch wurden % Zielzeilen befuellt.', befuellt;
  end if;

  select to_regclass('cbb_private_backup.value_add_payload_v3') is not null,
         to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
  into payload_da, snapshot_da;
  if payload_da then
    raise exception 'Trotz Drift-Abbruch existiert die Payload v3.';
  end if;
  if not snapshot_da then
    raise exception 'Der Drift-Abbruch hat den Snapshot v3 entfernt.';
  end if;

  raise notice 'Drift-Abbruch OK: fremde Notiz erhalten, 0 befuellte Zielzeilen, keine Payload.';
end $$;
