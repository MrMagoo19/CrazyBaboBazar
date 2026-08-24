-- Teilzustands-Fall (case_g): setup_partial_columns.sql hat VOR 02 genau die
-- drei Spalten fuer_wen, nicht_fuer und key_fact angelegt. Nach dem
-- Guard-Abbruch muessen exakt diese drei uebrig sein — keine mehr (02 haette
-- nachgeruestet) und keine weniger (02 haette aufgeraeumt) — und 0 Constraints.
do $$
declare
  spalten integer;
  erwartete_spalten integer;
  constraints integer;
  produkte bigint;
  spaltenliste text;
begin
  select count(*), coalesce(string_agg(column_name, ', ' order by column_name), 'KEINE')
    into spalten, spaltenliste
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');

  select count(*) into erwartete_spalten
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact')
    and data_type = 'text' and udt_name = 'text';

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

  select count(*) into produkte from public.products;

  if spalten <> 3 or erwartete_spalten <> 3 then
    raise exception
      'Teilzustand veraendert: % Value-Add-Spalten (erwartet exakt 3: fuer_wen, key_fact, nicht_fuer), gefunden: %.',
      spalten, spaltenliste;
  end if;
  if constraints <> 0 then
    raise exception 'Abbruch wirkungslos: % Value-Add-Constraints angelegt (erwartet 0).',
      constraints;
  end if;

  raise notice 'Teilzustand unveraendert: exakt 3 Spalten (%), 0 Constraints, % Produkte.',
    spaltenliste, produkte;
end $$;
