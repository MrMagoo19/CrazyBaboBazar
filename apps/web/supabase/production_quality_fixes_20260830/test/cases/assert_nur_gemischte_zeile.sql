-- ============================================================================
-- ASSERT — nach dem Abbruch im gemischten Zustand
-- ============================================================================
-- Genau EINE Produktzeile weicht von der Baseline ab: die, die das Setup von
-- Hand auf den Zielwert gesetzt hat. Keine Listenzeile weicht ab. 04 hat also
-- nichts geschrieben, sondern den gemischten Zustand nur erkannt.
-- ============================================================================

do $$
declare
  n integer;
begin
  select count(*) into n
  from cbb_test.baseline_products b
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck from public.products p
  ) p on p.id = b.id
  where b.id is null or p.id is null
     or p.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 1 then
    raise exception 'Nach dem Abbruch weichen % Produktzeilen ab, erwartet war genau 1.', n;
  end if;

  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and price_cents = 4249;
  if n <> 1 then
    raise exception 'Die abweichende Zeile ist nicht die vom Setup gesetzte.';
  end if;

  select count(*) into n
  from cbb_test.baseline_lists b
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck from public.lists l
  ) l on l.id = b.id
  where b.id is null or l.id is null
     or l.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 0 then
    raise exception 'Nach dem Abbruch weichen % Listenzeilen ab, erwartet waren 0.', n;
  end if;
end $$;
