-- Bestand unter die 300er-Schwelle druecken: jeder Guard muss abbrechen.
-- 376 - 77 = 299.
delete from public.products
where slug in (
  select slug from public.products
  where slug like 'fuellprodukt-%'
  order by slug
  limit 77
);

do $$
declare n bigint;
begin
  select count(*) into n from public.products;
  if n <> 299 then
    raise exception 'Setup kaputt: % Produkte, erwartet 299.', n;
  end if;
end $$;
