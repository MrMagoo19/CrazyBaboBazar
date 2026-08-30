-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 04 RETENTION (SCHREIBEND, LOESCHEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene, ausdrueckliche Benutzerfreigabe und sichtbare
-- Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WAS DIESE DATEI TUT: sie loescht Klick-out-Ereignisse, die aelter als das
-- eingestellte Fenster sind. Standard sind 12 Monate — genau die Frist, die die
-- Datenschutzerklaerung unter Abschnitt 6 zusagt (apps/web/app/datenschutz).
-- Wird die Frist hier geaendert, MUSS die Datenschutzerklaerung im selben
-- Schritt mitgeaendert werden.
--
-- WAS SIE NICHT TUT: sie loescht keine Struktur, kein Schema, keine Funktion
-- und keine Zeile innerhalb des Fensters. Sie fasst weder Produktdaten noch
-- die Value-Add-Artefakte v1/v2 an.
--
-- WIEDERHOLUNGSVERHALTEN: idempotent. Ein zweiter Lauf direkt danach loescht 0
-- Zeilen.
--
-- AUTOMATISIERUNG: bewusst NICHT Teil dieser Datei. Diese Datei ist und bleibt
-- der MANUELLE, einzeln freizugebende Loeschlauf. Die planmaessige Variante
-- liegt getrennt daneben und braucht eine eigene Freigabe:
--   04a_schedule_retention.sql   traegt den wiederkehrenden Job ein
--   04b_verify_retention_schedule_read_only.sql   prueft ihn read-only nach
-- Beide gehen durch dieselbe Funktion wie diese Datei. Es gibt weiterhin genau
-- einen Loeschpfad, nur zwei Ausloeser.
--
-- PRE-ENABLE-GATE (RUNBOOK Abschnitt 7): Die Messung darf ueberhaupt erst
-- scharf geschaltet werden — also `SUPABASE_SERVICE_ROLE_KEY` in Vercel gesetzt
-- werden —, wenn entweder ein Scheduler eingerichtet ist ODER ein verbindlich
-- dokumentierter, ueberwachter wiederkehrender 12-Monats-Loeschlauf existiert.
-- Ohne eines von beidem entstuenden Daten, fuer die zwar eine Frist zugesagt
-- ist, aber kein Mechanismus sie durchsetzt.
--
-- „Eingerichtet" heisst dabei ausgefuehrt, nicht vorbereitet: dass
-- 04a_schedule_retention.sql im Repository liegt, erfuellt das Gate nicht.
-- Erst der Lauf auf Production, ein FAIL-freies 04b und eine protokollierte
-- Kontrolle der Job-History erfuellen es.
--
-- Diese Datei bleibt in jedem Fall der freigabepflichtige manuelle Loeschpfad:
-- jeder einzelne Lauf braucht eine eigene Freigabe.
-- ============================================================================

begin;

set local lock_timeout = '5s';
set local statement_timeout = '120s';

do $$
declare
  faellig bigint;
  vorher bigint;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung und Objekte
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Retention abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Retention abgebrochen: Production-Fingerprint fehlt.';
  end if;
  if to_regclass('public.click_outs') is null then
    raise exception 'Retention abgebrochen: public.click_outs fehlt.';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
  ) then
    raise exception 'Retention abgebrochen: cbb_private_analytics.purge_click_outs fehlt.';
  end if;

  select count(*) into vorher from public.click_outs;
  select count(*) into faellig
  from public.click_outs
  where created_at < now() - interval '12 months';

  raise notice 'Retention: % Zeile(n) gesamt, davon % aelter als 12 Monate.', vorher, faellig;
end $$;

-- Der einzige Loeschpfad. Die Funktion prueft ihr Argument selbst und
-- akzeptiert nur 1 bis 24 Monate.
do $$
declare
  geloescht integer;
  verbleibend bigint;
  rest_ueberfaellig bigint;
begin
  select cbb_private_analytics.purge_click_outs(12) into geloescht;

  select count(*) into verbleibend from public.click_outs;
  select count(*) into rest_ueberfaellig
  from public.click_outs
  where created_at < now() - interval '12 months';

  if rest_ueberfaellig <> 0 then
    raise exception 'Retention inkonsistent: nach dem Lauf sind noch % Zeile(n) ueberfaellig.',
      rest_ueberfaellig;
  end if;

  raise notice 'Retention abgeschlossen: % Zeile(n) geloescht, % Zeile(n) verbleiben.',
    geloescht, verbleibend;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit.
select
  count(*) as verbleibende_ereignisse,
  count(*) filter (where created_at < now() - interval '12 months') as noch_ueberfaellig
from public.click_outs;
