-- ============================================================================
-- ASSERT — der zweite 04-Lauf war ein echter No-Op
-- ============================================================================
-- Vergleicht gegen snapshot_nach_04.sql: KEINE Zeile darf sich unterscheiden,
-- updated_at eingeschlossen. Ein zweiter Lauf, der die Zielwerte erneut
-- schreibt und dabei ein neues updated_at setzt, faellt hier durch.
-- ============================================================================

do $$
declare
  n integer;
begin
  select count(*) into n
  from cbb_test.nach_04_products s
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck from public.products p
  ) p on p.id = s.id
  where s.id is null or p.id is null
     or p.fingerabdruck is distinct from s.fingerabdruck;
  if n <> 0 then
    raise exception 'Der zweite 04-Lauf hat % Produktzeilen veraendert — kein No-Op.', n;
  end if;

  select count(*) into n
  from cbb_test.nach_04_lists s
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck from public.lists l
  ) l on l.id = s.id
  where s.id is null or l.id is null
     or l.fingerabdruck is distinct from s.fingerabdruck;
  if n <> 0 then
    raise exception 'Der zweite 04-Lauf hat % Listenzeilen veraendert — kein No-Op.', n;
  end if;

  raise notice 'Zweiter 04-Lauf war ein echter No-Op, updated_at eingeschlossen.';
end $$;
