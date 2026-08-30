-- Nach dem Abbruch am unvollstaendigen Schema: es wurde weder eine Spalte
-- nachgeruestet noch ein v3-Artefakt angelegt. Der Teilzustand bleibt exakt so,
-- wie das Setup ihn hinterlassen hat.
do $$
declare
  spalten integer;
  constraints integer;
begin
  select count(*) into spalten from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in ('fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind');
  select count(*) into constraints from pg_constraint
  where conrelid = 'public.products'::regclass and contype = 'c'
    and conname in ('products_alternative_kind_check',
                    'products_alternative_relation_check');

  if spalten <> 7 then
    raise exception 'Der abgebrochene Lauf hat das Schema veraendert: % Spalten (erwartet unveraendert 7).',
      spalten;
  end if;
  if constraints <> 2 then
    raise exception 'Der abgebrochene Lauf hat die Constraints veraendert: % (erwartet 2).',
      constraints;
  end if;
  if to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null
     or to_regclass('cbb_private_backup.value_add_payload_v3') is not null then
    raise exception 'Der abgebrochene Lauf hat ein v3-Artefakt angelegt.';
  end if;

  raise notice 'Schema-Teilzustand unveraendert: 7 Spalten, 2 Constraints, keine v3-Artefakte.';
end $$;
