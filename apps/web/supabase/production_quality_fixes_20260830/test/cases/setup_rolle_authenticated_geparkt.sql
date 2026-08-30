-- ============================================================================
-- SETUP — eine der beiden App-Rollen ist nicht mehr unter ihrem Namen da
-- ============================================================================
-- Alle Rechte-Zaehler in 02, 04 und 06 laufen ueber
--   pg_roles ... where rolname in ('anon', 'authenticated', 'service_role')
-- Fehlt eine der beiden App-Rollen, faellt sie aus dem Join heraus und der
-- Zaehler meldet still 0. Das ist KEIN Beleg fuer "keine Rechte", sondern nur
-- einer fuer "keine Rolle" — ohne harte Vorbedingung waere die Pruefung damit
-- fail-open.
--
-- WARUM UMBENENNEN STATT LOESCHEN
--   Rollen sind cluster-weit, ihre ACL-Eintraege haengen an der OID. `anon` und
--   `authenticated` haben in JEDER Fall-Datenbank Rechte auf die public-Tabellen
--   (fixture/01_schema.sql bildet den Supabase-Default nach). Ein DROP ROLE
--   scheiterte deshalb an genau diesen Abhaengigkeiten — und zwar auch an denen
--   in den bereits angelegten Datenbanken anderer Faelle.
--
--   ALTER ROLE ... RENAME laesst alle ACL-Eintraege unangetastet, weil sie die
--   OID referenzieren, nicht den Namen. Aus Sicht der Guards ist die Rolle
--   `authenticated` danach exakt so weg, wie sie es nach einem DROP waere:
--   pg_roles kennt den Namen nicht mehr. teardown_rolle_authenticated.sql
--   benennt zurueck und weist nach, dass die Rechte den Umweg unveraendert
--   ueberstanden haben.
--
--   NOLOGIN und kein Passwort — ein Rename kann hier also auch keine
--   MD5-Passworthuelle entwerten.
-- ============================================================================

alter role authenticated rename to cbb_test_authenticated_geparkt;

do $$
declare
  app_rollen integer;
begin
  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 1 then
    raise exception 'Setup fehlgeschlagen: %/2 App-Rollen sichtbar, erwartet genau 1 (nur anon).',
      app_rollen;
  end if;

  if not exists (select 1 from pg_roles where rolname = 'cbb_test_authenticated_geparkt') then
    raise exception 'Setup fehlgeschlagen: die geparkte Rolle existiert nicht.';
  end if;

  if not exists (select 1 from pg_roles where rolname = 'anon') then
    raise exception 'Setup fehlgeschlagen: anon fehlt ebenfalls — der Fall waere nicht mehr trennscharf.';
  end if;

  -- Gegenprobe, dass wirklich nur der NAME weg ist: die Rechte der Rolle auf
  -- die App-Tabellen bestehen unveraendert weiter. Genau deshalb ist der
  -- stille 0-Zaehler ohne Guard so gefaehrlich.
  if not has_table_privilege('cbb_test_authenticated_geparkt', 'public.products', 'SELECT') then
    raise exception 'Setup fehlgeschlagen: die geparkte Rolle hat ihre Rechte verloren — das Szenario waere unrealistisch.';
  end if;
end $$;
