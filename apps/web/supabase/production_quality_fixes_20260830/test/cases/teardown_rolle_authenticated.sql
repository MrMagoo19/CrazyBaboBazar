-- ============================================================================
-- TEARDOWN — die App-Rolle `authenticated` wieder unter ihrem Namen herstellen
-- ============================================================================
-- Rollen sind cluster-weit. Ohne dieses Teardown liefe jeder spaetere Fall
-- gegen einen Cluster ohne `authenticated` — und jeder Lauf von 02, 04 und 06
-- braeche dort an der neuen harten Vorbedingung ab, ohne dass das etwas ueber
-- die geprueften Dateien aussagen wuerde.
--
-- Geprueft wird danach nicht nur der Name, sondern auch, dass die Rechte den
-- Umweg unveraendert ueberstanden haben: ACL-Eintraege haengen an der OID, und
-- die aendert ein RENAME nicht. Bliebe hier etwas offen, waeren alle spaeteren
-- Rechte-Faelle (d4, d5) nicht mehr aussagekraeftig.
-- ============================================================================

alter role cbb_test_authenticated_geparkt rename to authenticated;

do $$
declare
  app_rollen integer;
begin
  if exists (select 1 from pg_roles where rolname = 'cbb_test_authenticated_geparkt') then
    raise exception 'Teardown fehlgeschlagen: die geparkte Rolle existiert noch.';
  end if;

  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 2 then
    raise exception 'Teardown fehlgeschlagen: %/2 App-Rollen vorhanden.', app_rollen;
  end if;

  -- Fixture-Ausgangszustand aus fixture/00_roles.sql und fixture/01_schema.sql:
  -- authenticated ist NOINHERIT und hat volle Rechte auf die App-Tabellen.
  if not has_table_privilege('authenticated', 'public.products', 'SELECT') then
    raise exception 'Teardown fehlgeschlagen: authenticated hat kein SELECT auf public.products mehr.';
  end if;
  if not has_schema_privilege('authenticated', 'public', 'USAGE') then
    raise exception 'Teardown fehlgeschlagen: authenticated hat kein USAGE auf schema public mehr.';
  end if;
  if (select r.rolinherit from pg_roles r where r.rolname = 'authenticated') is not false then
    raise exception 'Teardown fehlgeschlagen: authenticated steht auf INHERIT statt NOINHERIT.';
  end if;

  -- Und das private Backup ist weiterhin dicht — der Fall darf keine Rechte
  -- hinterlassen haben.
  if has_table_privilege('authenticated',
       'cbb_private_backup.quality_fixes_20260830_products_v1', 'SELECT') then
    raise exception 'Teardown fehlgeschlagen: authenticated hat SELECT auf das private Backup.';
  end if;
end $$;
