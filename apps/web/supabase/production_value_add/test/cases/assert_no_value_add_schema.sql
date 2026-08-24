-- Nach einem normalen Guard-Abbruch von 02: das Schema muss EXAKT unberuehrt
-- sein — 0 Value-Add-Spalten und 0 Value-Add-Constraints. Frueher wurde hier
-- jede Spaltenzahl ausser 8 akzeptiert; das haette einen Teilzustand nach dem
-- Abbruch (z. B. 5 von 8 Spalten) durchgewunken.
--
-- Fuer den Teilzustands-Fall (3 Spalten waren vor 02 schon da) ist
-- assert_partial_state_unchanged.sql zustaendig.
do $$
declare
  spalten integer;
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

  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

  select count(*) into produkte from public.products;

  if spalten <> 0 then
    raise exception
      'Abbruch wirkungslos: % Value-Add-Spalten vorhanden (erwartet 0): %.',
      spalten, spaltenliste;
  end if;
  if constraints <> 0 then
    raise exception 'Abbruch wirkungslos: % Value-Add-Constraints angelegt (erwartet 0).',
      constraints;
  end if;

  raise notice 'Rollback OK: exakt 0 Value-Add-Spalten, 0 Constraints, % Produkte.',
    produkte;
end $$;
