-- ============================================================================
-- FIXTURE 00 — Supabase-aehnliche Rollen (cluster-weit, einmal pro Cluster)
-- ============================================================================
-- 02 und 06 sprechen anon und authenticated in REVOKE-Statements bzw. in
-- harten Rechte-Guards direkt an. Fehlen die Rollen, scheitern die
-- Originaldateien mit "role does not exist" oder ihre Rechtepruefung waere
-- nicht aussagekraeftig — also muessen sie hier existieren, sonst testet der
-- Harness nicht die Realitaet.
--
-- service_role wird angelegt, weil 03 und 05 sie als INFO-Zeile ausgeben, 02
-- sie revoked und 06 sie hart prueft. Auf Supabase traegt sie BYPASSRLS.
--
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
