-- ============================================================================
-- TEARDOWN — Hilfsrolle entfernen UND anon wieder auf NOINHERIT stellen
-- ============================================================================
-- Rollen und Rollenattribute sind cluster-weit. Zurueckzusetzen ist deshalb
-- beides, was setup_grant_backup_via_hilfsrolle.sql angefasst hat:
--
--   1. cbb_test_hilfsrolle. Bliebe sie bestehen, haette anon in allen spaeteren
--      Fall-Datenbanken weiterhin ein geerbtes Recht auf das Backup.
--   2. Das INHERIT-Flag auf anon. Bliebe es stehen, wiche der Cluster vom
--      Fixture-Ausgangszustand (fixture/00_roles.sql: anon NOINHERIT, wie auf
--      Supabase) ab — und jeder spaetere Fall liefe gegen eine andere Realitaet
--      als die, die er zu testen behauptet.
--
-- REIHENFOLGE: erst das Tabellenrecht, dann die Mitgliedschaft, dann die Rolle,
-- zuletzt das Flag. REASSIGN/DROP OWNED ist nicht noetig, weil die Hilfsrolle
-- nichts besitzt — sie hat nur ein Recht bekommen. Das Recht verschwindet mit
-- der Rolle.
-- ============================================================================

revoke select on cbb_private_backup.quality_fixes_20260830_products_v1
  from cbb_test_hilfsrolle;
revoke cbb_test_hilfsrolle from anon;
drop role cbb_test_hilfsrolle;

alter role anon noinherit;

do $$
declare
  erbt boolean;
  mitgliedschaften integer;
begin
  if exists (select 1 from pg_roles where rolname = 'cbb_test_hilfsrolle') then
    raise exception 'Teardown fehlgeschlagen: Hilfsrolle existiert noch.';
  end if;

  if has_table_privilege('anon',
       'cbb_private_backup.quality_fixes_20260830_products_v1', 'SELECT') then
    raise exception 'Teardown fehlgeschlagen: anon hat weiterhin SELECT.';
  end if;

  -- Der Ausgangszustand aus fixture/00_roles.sql: anon ist NOINHERIT und
  -- Mitglied in keiner Rolle. Beides wird hier hart nachgewiesen, sonst
  -- verschleppt der Fall stillschweigend einen veraenderten Cluster.
  select r.rolinherit into erbt from pg_roles r where r.rolname = 'anon';
  if erbt is not false then
    raise exception 'Teardown fehlgeschlagen: anon steht auf INHERIT statt NOINHERIT (Fixture-Ausgangszustand).';
  end if;

  select count(*) into mitgliedschaften
  from pg_auth_members m
  join pg_roles mitglied on mitglied.oid = m.member
  where mitglied.rolname = 'anon';
  if mitgliedschaften <> 0 then
    raise exception 'Teardown fehlgeschlagen: anon hat noch % Rollenmitgliedschaft(en), erwartet 0.',
      mitgliedschaften;
  end if;
end $$;
