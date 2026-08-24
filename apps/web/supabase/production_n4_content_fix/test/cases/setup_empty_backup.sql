-- Leert das private Backup, ohne die Tabelle zu entfernen.
-- 04 und 06 muessen daraufhin abbrechen: eine leere Backup-Tabelle ist kein
-- Rollback-Pfad, sondern nur die Illusion eines solchen.
do $$
declare
  affected_rows integer;
begin
  delete from cbb_private_backup.n4_content_pre_fix_v1;
  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'Setup: DELETE traf %/1 Backup-Zeilen.', affected_rows;
  end if;
end $$;
