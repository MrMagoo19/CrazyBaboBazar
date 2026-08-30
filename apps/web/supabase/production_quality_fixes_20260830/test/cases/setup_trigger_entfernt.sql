-- ============================================================================
-- SETUP — Triggervertrag fehlt vollstaendig
-- ============================================================================
-- Der Vertrag steht nicht im Paket, sondern auf der Zieldatenbank. Er kann dort
-- also auch fehlen — etwa weil seo_updated_at_trigger.sql nie ausgefuehrt oder
-- spaeter wieder entfernt wurde. Dann gibt es keinen Beleg mehr dafuer, wie
-- sich updated_at bei einem UPDATE verhaelt.
--
-- Die Preflight-Zeile products_updated_at_triggervertrag muss diesen Zustand
-- als FAIL melden, nicht still uebergehen: fail-closed heisst hier, dass ein
-- fehlender Vertrag Schritt 04 sperrt.
--
-- Die Funktion bleibt absichtlich stehen. Geprueft wird der AKTIVE Trigger,
-- nicht die blosse Existenz einer Funktion.
-- ============================================================================

drop trigger products_set_updated_at on public.products;

do $$
declare
  vorhanden integer;
begin
  select count(*) into vorhanden
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if vorhanden <> 0 then
    raise exception 'Setup fehlgeschlagen: der Trigger ist noch vorhanden (%).', vorhanden;
  end if;
end $$;
