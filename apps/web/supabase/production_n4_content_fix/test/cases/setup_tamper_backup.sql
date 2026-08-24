-- Manipuliert das private Backup, ohne products anzufassen.
-- 04 muss daraufhin abbrechen, weil das Backup nicht mehr dem erwarteten
-- Vorzustand entspricht — sonst waere der Rollback-Pfad still kaputt.
do $$
declare
  affected_rows integer;
begin
  update cbb_private_backup.n4_content_pre_fix_v1
  set tagline = 'CBB-TEST: manipuliertes Backup'
  where slug = 'n4-nussmilchbereiter-pflanzenmilch';
  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'Setup: UPDATE traf %/1 Backup-Zeilen.', affected_rows;
  end if;
end $$;
