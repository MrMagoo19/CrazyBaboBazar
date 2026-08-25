-- Unvollstaendiges Value-Add-Schema: eine der acht Spalten fehlt.
-- Batch 2 migriert nicht und muss fail-closed abbrechen, statt die fehlende
-- Spalte nachzuruesten. key_fact ist bewusst gewaehlt, weil sie in keinem der
-- beiden CHECK-Constraints vorkommt — die Constraint-Zahl bleibt damit 2 und
-- der Guard muss allein an der Spaltenzahl scheitern.
alter table public.products drop column key_fact;

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
  if spalten <> 7 or constraints <> 2 then
    raise exception 'Setup kaputt: % Spalten (erwartet 7), % Constraints (erwartet 2).',
      spalten, constraints;
  end if;
end $$;
