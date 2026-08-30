-- ============================================================================
-- Wirksamkeitstest der Rechte — nicht nur Katalogpruefung, sondern echte
-- Zugriffsversuche unter den jeweiligen Rollen.
-- ============================================================================
-- Warum das zusaetzlich zu assert_after_02.sql noetig ist: dort wird der
-- KATALOG gelesen. Hier wird tatsaechlich zugegriffen. Nur so ist belegt, dass
-- RLS ohne Policy und der Rechte-Entzug im Zusammenspiel wirklich greifen —
-- und dass service_role trotz aktiver RLS schreiben kann, weil sie BYPASSRLS
-- traegt.
--
-- Der Rollenwechsel laeuft ueber set_config('role', ..., true) statt ueber
-- SET LOCAL ROLE: set_config ist ein gewoehnlicher Funktionsaufruf und damit in
-- PL/pgSQL uneingeschraenkt verfuegbar. `is_local = true` begrenzt die Wirkung
-- auf die laufende Transaktion, und jeder Zweig setzt die Rolle danach
-- ausdruecklich auf 'none' zurueck.
-- ============================================================================

do $$
declare
  fehler text;
  zeilen bigint;
begin
  -- ---------------------------------------------------------------------
  -- 1. anon darf nicht lesen.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'anon', true);
    perform count(*) from public.click_outs;
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: anon konnte public.click_outs lesen.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'anon: SELECT korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 2. anon darf nicht schreiben.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'anon', true);
    insert into public.click_outs (product_slug, merchant, device_class, consented_session_id)
    values ('valueadd-produkt-01', 'amazon', 'desktop', gen_random_uuid());
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: anon konnte in public.click_outs schreiben.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'anon: INSERT korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 3. service_role DARF schreiben — trotz aktiver RLS ohne Policy.
  -- ---------------------------------------------------------------------
  perform set_config('role', 'service_role', true);
  insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
  values ('valueadd-produkt-01', 'amazon', '/thema/tech', 'mobile',
          '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c');
  perform set_config('role', 'none', true);

  -- ---------------------------------------------------------------------
  -- 4. service_role darf NICHT lesen. Die Anwendung braucht kein SELECT, und
  --    ohne SELECT kann ein kompromittierter Server-Schluessel die bereits
  --    erfassten Ereignisse nicht abziehen.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'service_role', true);
    perform count(*) from public.click_outs;
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: service_role konnte public.click_outs lesen.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'service_role: SELECT korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 5. service_role darf NICHT loeschen. Einziger Loeschpfad ist die
  --    Retention-Funktion.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'service_role', true);
    delete from public.click_outs;
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: service_role konnte aus public.click_outs loeschen.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'service_role: DELETE korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 6. anon darf den Zaehlerstand der Identity-Sequenz nicht lesen. Ohne
  --    Rechte-Entzug gaebe `last_value` die Zahl aller bisher gezaehlten
  --    Klick-outs preis — an der dichten Tabelle vorbei.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'anon', true);
    perform last_value from public.click_outs_id_seq;
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: anon konnte den Sequenz-Zaehlerstand lesen.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'anon: SELECT auf der Sequenz korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 7. Auch service_role darf den Zaehlerstand nicht lesen. Sie schreibt nur.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'service_role', true);
    perform last_value from public.click_outs_id_seq;
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: service_role konnte den Sequenz-Zaehlerstand lesen.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'service_role: SELECT auf der Sequenz korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 8. Und sie darf die Nummernfolge nicht verbiegen: setval braucht UPDATE,
  --    das bewusst nicht vergeben ist. Sonst waeren Primaerschluessel-
  --    Kollisionen beim naechsten Insert erzwingbar.
  -- ---------------------------------------------------------------------
  begin
    perform set_config('role', 'service_role', true);
    perform setval('public.click_outs_id_seq', 1);
    perform set_config('role', 'none', true);
    raise exception 'CBB-TEST-FAIL: service_role konnte setval auf der Sequenz ausfuehren.';
  exception
    when insufficient_privilege then
      perform set_config('role', 'none', true);
      raise notice 'service_role: setval korrekt verweigert.';
    when others then
      get stacked diagnostics fehler = message_text;
      perform set_config('role', 'none', true);
      raise exception '%', fehler;
  end;

  -- ---------------------------------------------------------------------
  -- 9. Der Eigentuemer sieht die eine geschriebene Zeile. Damit ist belegt,
  --    dass Schritt 3 wirklich durchging und nicht still verworfen wurde.
  -- ---------------------------------------------------------------------
  select count(*) into zeilen from public.click_outs;
  if zeilen <> 1 then
    raise exception 'Erwartet genau 1 Zeile nach dem service_role-INSERT, gefunden %.', zeilen;
  end if;

  raise notice 'Rechte wirken: anon blockiert, service_role nur INSERT, Sequenz weder lesbar noch setzbar, Zeile angekommen.';
end $$;
