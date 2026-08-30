-- Negativfall: der Bestand faellt unter 300 Produkte. Das ist der Hinweis auf
-- eine falsche oder halb befuellte Umgebung — dort wird nichts angelegt.
-- Genau 299 Zeilen bleiben stehen, damit die Fehlermeldung exakt pruefbar ist.
delete from public.products
where slug in (
  select slug from public.products order by slug limit 77
);

do $$
declare
  verbleibend bigint;
begin
  select count(*) into verbleibend from public.products;
  if verbleibend <> 299 then
    raise exception 'Setup kaputt: % Produkte (erwartet 299).', verbleibend;
  end if;
end $$;
