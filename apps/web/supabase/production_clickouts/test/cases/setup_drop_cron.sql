-- Entfernt die pg_cron-Nachbildung vollstaendig. Bildet den Zustand nach, in
-- dem pg_cron auf dem Ziel gar nicht verfuegbar ist.
--
-- Erwartete Folgen:
--   04a  bricht fail-closed ab ("pg_cron ist nicht nutzbar")
--   04b  scheitert hart beim Planen des Statements (schema "cron" does not exist)
--   05   laeuft unveraendert durch und vermerkt nur eine NOTICE
drop schema cron cascade;

do $$
begin
  if to_regclass('cron.job') is not null then
    raise exception 'Setup kaputt: cron.job existiert weiterhin.';
  end if;
end $$;
