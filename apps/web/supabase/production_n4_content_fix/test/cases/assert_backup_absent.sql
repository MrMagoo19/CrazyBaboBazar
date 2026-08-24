-- Nach einem fail-closed Abbruch von 02 darf KEIN Backup-Artefakt existieren.
do $$
begin
  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is not null then
    raise exception 'Abbruch von 02 hat trotzdem n4_content_pre_fix_v1 hinterlassen.';
  end if;
  raise notice 'OK: kein Backup-Artefakt nach dem Abbruch.';
end $$;
