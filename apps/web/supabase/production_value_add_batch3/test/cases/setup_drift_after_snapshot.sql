-- Negativfall: eine Zielzeile aendert sich NACH dem Snapshot. 03 muss den
-- Drift erkennen und abbrechen, statt eine fremde Aenderung zu ueberschreiben.
--
-- Geaendert wird bewusst die editorial_note, weil genau dieses Feld der
-- Backfill spaeter selbst ueberschreibt. Wuerde der Drift-Guard fehlen, ginge
-- die fremde Aenderung still verloren.
update public.products
set editorial_note = 'DRIFT: jemand anderes hat diese Notiz nach dem Snapshot geaendert.'
where slug = 'ticktime-tk3-wuerfel-timer-countdown';

do $$
declare
  drift integer;
begin
  select count(*) into drift
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v3 b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at;
  -- Erwartet ist genau EINE gedriftete Zeile. Der Trigger hebt zusaetzlich
  -- updated_at an, das bleibt aber dieselbe Zeile.
  if drift <> 1 then
    raise exception 'Setup kaputt: % gedriftete Zeilen (erwartet 1).', drift;
  end if;
end $$;
