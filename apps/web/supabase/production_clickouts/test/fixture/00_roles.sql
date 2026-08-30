-- ============================================================================
-- FIXTURE 00 — Supabase-aehnliche Rollen (Cluster-weit, einmal pro Cluster)
-- ============================================================================
-- 02 und 05 sprechen anon, authenticated und service_role in REVOKE/GRANT
-- direkt an. Fehlen die Rollen, scheitern die Originaldateien mit
-- "role does not exist" — also muessen sie hier existieren, sonst testet der
-- Harness nicht die Realitaet.
--
-- service_role traegt BYPASSRLS wie auf Supabase. Genau darauf stuetzt sich der
-- Schreibpfad: RLS ist an, es gibt keine Policy, und trotzdem muss der INSERT
-- der Anwendung durchgehen.
--
-- NOLOGIN, weil der Test nie ueber das Netz als App-Rolle verbindet; die
-- Rollenwechsel passieren mit SET ROLE innerhalb derselben Sitzung.
-- ============================================================================

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end $$;
