-- Oeffnet das private Backup fuer die App-Rolle anon.
-- 04 muss daraufhin abbrechen: ein Backup, das die oeffentliche App lesen kann,
-- ist kein privates Audit-Artefakt mehr.
grant select on cbb_private_backup.n4_content_pre_fix_v1 to anon;

do $$
declare
  acl_rows integer;
begin
  select count(*) into acl_rows
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  join pg_roles r on r.oid = acl.grantee
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
    and r.rolname = 'anon';
  if acl_rows <> 1 then
    raise exception 'Setup: % ACL-Eintraege fuer anon (erwartet 1).', acl_rows;
  end if;
end $$;
