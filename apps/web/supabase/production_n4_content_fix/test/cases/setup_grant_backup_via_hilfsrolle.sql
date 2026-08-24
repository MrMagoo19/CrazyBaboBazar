-- ============================================================================
-- SETUP — effektives, NUR GEERBTES Recht fuer anon auf das private Backup
-- ============================================================================
-- Bewusst KEIN direkter GRANT an anon. Das SELECT liegt bei einer Hilfsrolle,
-- und anon ist Mitglied dieser Hilfsrolle. In den direkten ACL-Eintraegen der
-- Backup-Tabelle taucht anon damit NICHT auf — eine Pruefung, die nur
-- aclexplode auswertet, sieht hier nichts. Sichtbar wird das Recht erst ueber
-- has_table_privilege, das Rollenmitgliedschaft aufloest.
--
-- 06 muss deshalb ueber die EFFEKTIVE Rechtepruefung fail closed abbrechen.
--
-- anon ist in der Fixture NOINHERIT. Ohne das ausdrueckliche WITH INHERIT TRUE
-- (PostgreSQL 16) wuerde das Recht gar nicht vererbt und der Fall waere
-- wirkungslos — deshalb steht es hier und wird unten nachgewiesen.
--
-- Rollen und Rollenmitgliedschaften sind CLUSTERWEIT. Aufgeraeumt wird in
-- teardown_hilfsrolle.sql; ohne das wuerde der Fall in spaetere Testdatenbanken
-- hineinwirken.
-- ============================================================================

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'cbb_test_backup_reader') then
    create role cbb_test_backup_reader nologin noinherit;
  end if;
end $$;

grant select on cbb_private_backup.n4_content_pre_fix_v1 to cbb_test_backup_reader;
grant cbb_test_backup_reader to anon with inherit true;

do $$
declare
  direkt_anon integer;
  effektiv_anon boolean;
begin
  select count(*) into direkt_anon
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  join pg_roles r on r.oid = acl.grantee
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
    and r.rolname = 'anon';
  if direkt_anon <> 0 then
    raise exception 'Setup: anon hat % direkte ACL-Eintraege (erwartet 0) — der Fall wuerde schon von der direkten Pruefung gefangen und belegt nichts ueber die effektive.',
      direkt_anon;
  end if;

  select has_table_privilege(
           'anon', 'cbb_private_backup.n4_content_pre_fix_v1', 'SELECT')
  into effektiv_anon;
  if effektiv_anon is not true then
    raise exception 'Setup: anon hat kein effektives SELECT geerbt — der Fall waere wirkungslos.';
  end if;

  raise notice 'OK: anon hat 0 direkte, aber geerbte effektive Rechte auf das Backup.';
end $$;
