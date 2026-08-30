-- ============================================================================
-- SETUP — vertragskonforme Funktion mit reinem shop_sub_category-Kommentar
-- ============================================================================
-- Der Kommentar darf den read-only Vertragscheck nicht sperren. Ausgefuehrter
-- Code nennt shop_sub_category nicht; Guard und Zuweisung bleiben korrekt.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  -- shop_sub_category bleibt bewusst ohne lastmod-Bump.
  if new.updated_at is not distinct from old.updated_at
     and (new.name) is distinct from (old.name)
  then
    new.updated_at := now();
  end if;
  return new;
end
$$;

