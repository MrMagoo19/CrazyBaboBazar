-- ============================================================================
-- SETUP — Backup NUR ueber Rollenmitgliedschaft fuer anon lesbar
-- ============================================================================
-- Kein direkter GRANT an anon: das SELECT liegt bei einer Hilfsrolle, anon ist
-- Mitglied. In den direkten ACL-Eintraegen ist anon damit unsichtbar — nur
-- has_table_privilege sieht das Recht.
--
-- Genau dieser Fall belegt, dass die effektive Rechtepruefung in 04 und 06
-- nicht Zierde ist: eine Pruefung, die nur aclexplode auswertet, wuerde hier
-- fail-open durchlaufen.
--
-- WARUM HIER "ALTER ROLE anon INHERIT" STEHT
--   fixture/00_roles.sql legt anon wie auf Supabase als NOINHERIT an. Eine
--   NOINHERIT-Rolle bekommt ueber blosse Mitgliedschaft KEIN effektives Recht:
--   has_table_privilege folgt nur inheritable Mitgliedschaften. Ohne diesen
--   Schalter erzeugt der Fall also gar kein geerbtes Recht und wuerde nichts
--   pruefen — er waere ein stiller Blindgaenger.
--
--   Der Schalter ist bewusst auf diesen einen Negativfall begrenzt und wird in
--   teardown_hilfsrolle.sql auf NOINHERIT zurueckgestellt. Er beruehrt KEINE
--   der sechs Originaldateien: deren Rechte-Guards bleiben unveraendert scharf,
--   sie sehen lediglich einen Zustand, den es ohne den Schalter nicht gaebe.
--
--   Der gepruefte Zustand — direkte ACL 0, effektives Recht 1 — ist auch mit
--   Supabase-Defaults erreichbar: ab PostgreSQL 16 genuegt dafuer ein
--   "GRANT <rolle> TO anon WITH INHERIT TRUE", ohne anon anzufassen. Der Guard
--   verteidigt also keinen Fantasiezustand. Hier steht trotzdem der
--   ALTER-Weg, weil er auf jeder PostgreSQL-Version dasselbe bedeutet.
--
-- REIHENFOLGE IST PFLICHT: ALTER vor GRANT.
--   Ab PostgreSQL 16 haelt jede Mitgliedschaft ihre eigene INHERIT-Option fest;
--   ihr Default wird beim GRANT aus rolinherit des Mitglieds uebernommen. Ein
--   GRANT vor dem ALTER waere dauerhaft nicht-vererbend — und der Fall waere
--   trotz gesetztem INHERIT-Flag wieder wirkungslos.
--
-- Rollen und Rollenattribute sind cluster-weit. teardown_hilfsrolle.sql muss im
-- selben Fall laufen, sonst verfaelschen Hilfsrolle und INHERIT-Flag jeden
-- spaeteren Fall.
-- ============================================================================

alter role anon inherit;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'cbb_test_hilfsrolle') then
    create role cbb_test_hilfsrolle nologin noinherit;
  end if;

  -- Eine bereits bestehende Mitgliedschaft koennte aus einer Zeit stammen, in
  -- der anon noch NOINHERIT war — sie truege dann inherit_option = false und
  -- bliebe wirkungslos. Deshalb erst loesen, dann unter INHERIT neu setzen.
  if exists (
    select 1
    from pg_auth_members m
    join pg_roles gruppe on gruppe.oid = m.roleid
    join pg_roles mitglied on mitglied.oid = m.member
    where gruppe.rolname = 'cbb_test_hilfsrolle'
      and mitglied.rolname = 'anon'
  ) then
    revoke cbb_test_hilfsrolle from anon;
  end if;
end $$;

grant cbb_test_hilfsrolle to anon;
grant select on cbb_private_backup.quality_fixes_20260830_products_v1
  to cbb_test_hilfsrolle;

-- ---------------------------------------------------------------------------
-- Gegenprobe: der Fall misst wirklich das, was er behauptet.
-- Beide Zaehler sind exakt so gebaut wie die Guards in 04 und 06 — dieselben
-- Rollen, dieselbe Privilegienliste. Erwartet wird genau die Kombination, auf
-- die der Harness als Fehlermeldung wartet: direkt 0, effektiv 1.
-- ---------------------------------------------------------------------------
do $$
declare
  direkt integer;
  effektiv integer;
  erbt boolean;
  tabelle_oid oid := 'cbb_private_backup.quality_fixes_20260830_products_v1'::regclass;
begin
  select r.rolinherit into erbt from pg_roles r where r.rolname = 'anon';
  if erbt is not true then
    raise exception 'Setup fehlgeschlagen: anon ist NOINHERIT, ein geerbtes Recht kann gar nicht entstehen.';
  end if;

  if not has_table_privilege('anon',
        'cbb_private_backup.quality_fixes_20260830_products_v1', 'SELECT') then
    raise exception 'Setup fehlgeschlagen: anon erbt kein SELECT.';
  end if;

  -- (a) DIREKTE ACL-Eintraege: anon darf hier nicht auftauchen. Sonst wuerde
  -- der Fall nichts ueber die effektive Pruefung aussagen, sondern nur case_d4
  -- wiederholen.
  select count(*) into direkt
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where c.oid = tabelle_oid
    and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated', 'service_role'));
  if direkt <> 0 then
    raise exception 'Setup fehlgeschlagen: % direkte ACL-Eintraege, erwartet 0.', direkt;
  end if;

  -- (b) EFFEKTIVE Rechte: genau eines — anon/SELECT, rein geerbt.
  select count(*) into effektiv
  from pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated', 'service_role')
    and has_table_privilege(r.oid, tabelle_oid, p.priv::text);
  if effektiv <> 1 then
    raise exception 'Setup fehlgeschlagen: % effektive Rechte, erwartet genau 1 (anon/SELECT).', effektiv;
  end if;
end $$;
