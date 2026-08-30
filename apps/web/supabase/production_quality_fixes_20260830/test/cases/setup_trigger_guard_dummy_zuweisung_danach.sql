-- ============================================================================
-- SETUP — Guard nur als Dummy, bedingungslose Zuweisung danach mit "="
-- ============================================================================
-- Guard und Zuweisung kommen beide genau einmal vor, sind aber nicht
-- verschachtelt. Ein bloss textueller Existenzcheck wuerde diesen gefaehrlichen
-- Rumpf akzeptieren. Zusaetzlich wird die gueltige PL/pgSQL-Zuweisungsform "="
-- benutzt, damit auch sie vom Zuweisungszaehler erfasst werden muss.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at is not distinct from old.updated_at then
    null;
  end if;

  new.updated_at = now();
  return new;
end
$$;
