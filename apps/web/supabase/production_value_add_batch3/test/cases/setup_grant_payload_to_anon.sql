-- Reisst absichtlich ein Rechte-Loch auf: anon bekommt SELECT auf die private
-- Audit-Payload v3, und dazu die noetige USAGE auf dem Schema. 04b MUSS das als
-- FAIL-Zeile melden — ein PASS waere hier der eigentliche Befund.
grant usage on schema cbb_private_backup to anon;
grant select on cbb_private_backup.value_add_payload_v3 to anon;

do $$
declare
  rechte integer;
begin
  select count(*) into rechte
  from pg_roles r
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                     ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
  where r.rolname = 'anon'
    and has_table_privilege(r.oid,
      'cbb_private_backup.value_add_payload_v3'::regclass::oid, p.priv::text);
  if rechte <> 1 then
    raise exception 'Setup kaputt: anon hat % Recht(e) auf der Payload (erwartet 1).', rechte;
  end if;
end $$;
