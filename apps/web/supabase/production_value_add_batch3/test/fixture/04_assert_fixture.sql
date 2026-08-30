-- ============================================================================
-- FIXTURE 04 — Selbstpruefung der Fixture
-- ============================================================================
-- Wenn die Fixture nicht dem Zielbild entspricht, sind alle Folgeergebnisse
-- wertlos. Diese Datei bricht deshalb hart ab statt zu warnen.
-- ============================================================================

do $$
declare
  produkte bigint;
  published bigint;
  value_add_gesamt integer;
  b3_zielprodukte integer;
  b3_published integer;
  b3_befuellt integer;
  b3_mit_note integer;
  b3_distinct_updated integer;
  b1_vollstaendig integer;
  b2_vollstaendig integer;
  ueberschneidung integer;
  spalten integer;
  constraints integer;
  defekte_relationen integer;
  app_grants integer;
begin
  select count(*) into produkte from public.products;
  select count(*) into published from public.products where is_published is true;
  if produkte <> 376 or published <> 372 then
    raise exception 'Fixture kaputt: % Produkte (erwartet 376), % published (erwartet 372).',
      produkte, published;
  end if;

  -- --------------------------------------------------------------------
  -- Value-Add-Ausgangszustand: exakt 20 befuellte Zeilen, alle aus B1/B2.
  -- --------------------------------------------------------------------
  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 20 then
    raise exception 'Fixture kaputt: % Zeilen mit Value-Add (erwartet 20).', value_add_gesamt;
  end if;

  select count(*) into b1_vollstaendig from public.products
  where slug in (
    'pinecil-usbc-loetkolben', 'divoom-pixoo-led-panel',
    'sculpfun-s9-laser-engraver', 'arc-reaktor-mk1-schwebend',
    'elektrische-wasserpistole-mit-led', 'hot-wheels-ultimative-garage-3ft',
    'lego-creator-3in1-retro-kamera-31147', 'ninja-staysharp-messerset-6-teilig',
    'n4-nussmilchbereiter-pflanzenmilch', 'welpen-usb-ladekabel-hunde-design'
  ) and fuer_wen is not null and nicht_fuer is not null and key_fact is not null
    and pros is not null and cons is not null and editorial_note is not null;

  select count(*) into b2_vollstaendig from public.products
  where slug in (
    'livondo-terracotta-pflanzenbewaesserung', 'wixies-wichstuecher-scherzartikel',
    'kaffeewaermer-tassenwaermer-elektrisch', 'gluecksgut-anti-stress-wuerfel',
    'infactory-boyfriend-kissen', 'scheisse-quartett-kartenspiel',
    'riesige-aufblasbare-ente-pool', 'shashibo-formwechsel-box-magnetisch',
    'eiswuerfelform-todesstern-star-wars', 'katzenschlafsack-fuer-menschen'
  ) and fuer_wen is not null and nicht_fuer is not null and key_fact is not null
    and pros is not null and cons is not null and editorial_note is not null;

  if b1_vollstaendig <> 10 or b2_vollstaendig <> 10 then
    raise exception 'Fixture kaputt: Batch 1 %/10, Batch 2 %/10 vollstaendig.',
      b1_vollstaendig, b2_vollstaendig;
  end if;

  -- --------------------------------------------------------------------
  -- Batch-3-Zielmenge: 10 published, keine Value-Add-Daten, alle mit
  -- bestehender editorial_note und zehn UNTERSCHIEDLICHEN updated_at-Werten.
  -- Nur so beweist der Restore-Test wirklich, dass er Zeitstempel exakt
  -- zurueckspielt und nicht zufaellig alle auf denselben Wert setzt.
  -- --------------------------------------------------------------------
  select
    count(*),
    count(*) filter (where is_published is true),
    count(*) filter (
      where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
         or pros is not null or cons is not null or alternative_slug is not null
         or alternative_reason is not null or alternative_kind is not null
    ),
    count(*) filter (where editorial_note is not null),
    count(distinct updated_at)
  into b3_zielprodukte, b3_published, b3_befuellt, b3_mit_note, b3_distinct_updated
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
  );

  if b3_zielprodukte <> 10 or b3_published <> 10 then
    raise exception 'Fixture kaputt: Batch-3-Ziele %/10 vorhanden, %/10 published.',
      b3_zielprodukte, b3_published;
  end if;
  if b3_befuellt <> 0 then
    raise exception 'Fixture kaputt: % Batch-3-Ziele tragen bereits Value-Add-Daten.', b3_befuellt;
  end if;
  if b3_mit_note <> 10 then
    raise exception 'Fixture kaputt: nur %/10 Batch-3-Ziele haben eine editorial_note.', b3_mit_note;
  end if;
  if b3_distinct_updated <> 10 then
    raise exception 'Fixture kaputt: nur % unterschiedliche updated_at-Werte in der Zielmenge (erwartet 10).',
      b3_distinct_updated;
  end if;

  -- --------------------------------------------------------------------
  -- Disjunktheit
  -- --------------------------------------------------------------------
  select count(*) into ueberschneidung from public.products
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
  ) and (fuer_wen is not null or editorial_note like 'B1-NOTE%' or editorial_note like 'B2-NOTE%');
  if ueberschneidung <> 0 then
    raise exception 'Fixture kaputt: % Batch-3-Ziele ueberschneiden sich mit einer Vorgaengercharge.',
      ueberschneidung;
  end if;

  -- --------------------------------------------------------------------
  -- Schema und bestehende Relationen
  -- --------------------------------------------------------------------
  select count(*) into spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
                        'alternative_slug', 'alternative_reason', 'alternative_kind');
  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check', 'products_alternative_relation_check');
  if spalten <> 8 or constraints <> 2 then
    raise exception 'Fixture kaputt: %/8 Spalten, %/2 Constraints.', spalten, constraints;
  end if;

  select count(*) into defekte_relationen
  from public.products p
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);
  if defekte_relationen <> 0 then
    raise exception 'Fixture kaputt: % bestehende Relationen zeigen ins Leere.', defekte_relationen;
  end if;

  select count(*) into app_grants
  from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'products'
    and grantee in ('anon', 'authenticated');
  if app_grants <> 14 then
    raise exception 'Fixture kaputt: % App-Grants auf products (erwartet 14).', app_grants;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
     or to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Fixture kaputt: ein v3-Artefakt existiert bereits.';
  end if;

  raise notice 'Fixture OK: 376/372 Produkte, 20 Value-Add (B1 10 + B2 10), Batch 3 10/10 leer mit 10 Notizen und 10 Zeitstempeln.';
end $$;
