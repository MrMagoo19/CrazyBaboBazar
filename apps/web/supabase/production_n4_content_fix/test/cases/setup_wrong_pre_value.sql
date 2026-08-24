-- Setzt die N4-tagline auf einen Wert, den weder 02 noch 04 erwarten.
-- Beide muessen daraufhin fail closed abbrechen.
do $$
declare
  affected_rows integer;
begin
  update public.products
  set tagline = 'CBB-TEST: abweichender Vorwert'
  where slug = 'n4-nussmilchbereiter-pflanzenmilch';
  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'Setup: UPDATE traf %/1 Zeilen.', affected_rows;
  end if;
end $$;
