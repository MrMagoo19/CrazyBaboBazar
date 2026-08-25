-- Eine Batch-2-Zielzeile traegt bereits Value-Add-Daten. 02 muss abbrechen,
-- statt eine fremde Befuellung stillschweigend in den Snapshot zu uebernehmen
-- und spaeter zu ueberschreiben.
--
-- Es wird bewusst nur key_fact gesetzt: das Relationstriplet bleibt komplett
-- NULL, der CHECK-Constraint products_alternative_relation_check also erfuellt.
-- Der Guard darf nicht davon abhaengen, dass die fremde Befuellung vollstaendig
-- ist.
update public.products
set key_fact = 'FREMDBEFUELLUNG aus einem anderen Vorgang.'
where slug = 'katzenschlafsack-fuer-menschen';

do $$
declare n integer;
begin
  select count(*) into n from public.products
  where slug = 'katzenschlafsack-fuer-menschen' and key_fact is not null;
  if n <> 1 then
    raise exception 'Setup kaputt: key_fact wurde nicht gesetzt.';
  end if;
end $$;
