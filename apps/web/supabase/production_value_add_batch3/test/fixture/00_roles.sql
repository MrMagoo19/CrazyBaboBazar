-- ============================================================================
-- FIXTURE 00 — Supabase-aehnliche Rollen (Cluster-weit, einmal pro Cluster)
-- ============================================================================
-- 02, 03 und 05 sprechen anon und authenticated in REVOKE-Statements direkt an.
-- Fehlen die Rollen, scheitern die Originaldateien mit "role does not exist" —
-- also muessen sie hier existieren, sonst testet der Harness nicht die Realitaet.
-- service_role wird angelegt, weil 04b sie als INFO-Zeile ausgibt und weil sie
-- auf Supabase BYPASSRLS traegt.
-- NOLOGIN, weil der Test nie als App-Rolle verbindet.
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
