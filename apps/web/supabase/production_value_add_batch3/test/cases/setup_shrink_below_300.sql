-- Negativfall: der Bestand faellt unter 300 Produkte. Das ist der Hinweis auf
-- eine falsche oder halb befuellte Umgebung — dort wird nichts geschrieben.
-- Es werden ausschliesslich Fuellprodukte entfernt, damit die drei Zielmengen
-- vollstaendig bleiben und der Guard wirklich nur an der Zahl scheitert.
-- Genau 299 Zeilen bleiben stehen, damit die Fehlermeldung exakt pruefbar ist.
delete from public.products
where slug in (
  select slug from public.products
  where slug like 'fuellprodukt-%'
  order by slug
  limit 77
);

do $$
declare
  verbleibend bigint;
  value_add bigint;
begin
  select count(*) into verbleibend from public.products;
  select count(*) into value_add from public.products
  where fuer_wen is not null or pros is not null;
  if verbleibend <> 299 then
    raise exception 'Setup kaputt: % Produkte (erwartet 299).', verbleibend;
  end if;
  if value_add <> 20 then
    raise exception 'Setup kaputt: % Zeilen mit Value-Add (erwartet 20).', value_add;
  end if;
end $$;
