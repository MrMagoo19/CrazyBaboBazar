-- Simuliert eine parallele Redaktionsaenderung ZWISCHEN 02 und 03: eine der
-- zehn Zielzeilen bekommt eine neue editorial_note. Der echte
-- seo_updated_at_trigger hebt dabei zusaetzlich updated_at an.
--
-- 03 muss das erkennen und abbrechen, statt die fremde Aenderung kommentarlos
-- zu ueberschreiben — und statt einen Snapshot als Rollback-Grundlage zu
-- verwenden, der den aktuellen Stand nicht mehr abbildet.
update public.products
set editorial_note = 'PARALLELE REDAKTIONSAENDERUNG nach dem Snapshot.'
where slug = 'scheisse-quartett-kartenspiel';

do $$
declare
  drift integer;
begin
  select count(*) into drift
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 b
    on b.id = p.id and b.slug = p.slug
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at;
  if drift <> 1 then
    raise exception 'Setup kaputt: % gedriftete Zeilen, erwartet genau 1.', drift;
  end if;
end $$;
