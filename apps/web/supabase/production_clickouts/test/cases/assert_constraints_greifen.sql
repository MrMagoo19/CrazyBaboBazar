-- ============================================================================
-- Die CHECK-Constraints sind die datenbankseitige Kopie der Regeln aus
-- apps/web/lib/affiliate.ts. Dieser Fall belegt, dass sie wirklich greifen —
-- selbst wenn der Route-Handler eines Tages nachlaesst.
-- ============================================================================

do $$
declare
  fehler text;
  i integer;
  abgelehnt integer := 0;
  faelle text[] := array[
    'Querystring im Herkunftspfad',
    'Fragment im Herkunftspfad',
    'protokollrelative Herkunft',
    'absolute fremde Herkunft',
    'Herkunftspfad zu lang',
    'Steuerzeichen im Herkunftspfad',
    'unbekannter Merchant',
    'freie Geraeteklasse',
    'Slug mit Pfadwechsel',
    'Slug in Grossbuchstaben'
  ];
begin
  for i in 1 .. array_length(faelle, 1) loop
    begin
      case i
        when 1 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', '/suche?q=geschenk', 'desktop', gen_random_uuid());
        when 2 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', '/listen/geeklist#pos3', 'desktop', gen_random_uuid());
        when 3 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', '//evil.example/x', 'desktop', gen_random_uuid());
        when 4 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', 'https://evil.example/x', 'desktop', gen_random_uuid());
        when 5 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', '/' || repeat('a', 200), 'desktop', gen_random_uuid());
        when 6 then
          insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', '/thema/tech' || chr(10) || 'X', 'desktop', gen_random_uuid());
        when 7 then
          insert into public.click_outs (product_slug, merchant, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'ebay', 'desktop', gen_random_uuid());
        when 8 then
          insert into public.click_outs (product_slug, merchant, device_class, consented_session_id)
          values ('valueadd-produkt-01', 'amazon', 'iphone-15-pro-safari', gen_random_uuid());
        when 9 then
          insert into public.click_outs (product_slug, merchant, device_class, consented_session_id)
          values ('../../etc/passwd', 'amazon', 'desktop', gen_random_uuid());
        when 10 then
          insert into public.click_outs (product_slug, merchant, device_class, consented_session_id)
          values ('Valueadd-Produkt-01', 'amazon', 'desktop', gen_random_uuid());
      end case;
      raise exception 'CBB-TEST-FAIL: "%" wurde akzeptiert.', faelle[i];
    exception
      when check_violation then
        abgelehnt := abgelehnt + 1;
      when others then
        get stacked diagnostics fehler = message_text;
        raise exception '%', fehler;
    end;
  end loop;

  if abgelehnt <> array_length(faelle, 1) then
    raise exception 'Nur %/% Faelle wurden abgelehnt.', abgelehnt, array_length(faelle, 1);
  end if;

  -- Gegenprobe: ein sauberer Datensatz muss durchgehen, sonst waeren die
  -- Constraints schlicht zu streng und die Messung tot.
  insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
  values ('valueadd-produkt-02', 'amazon', '/thema/outdoor', 'tablet', gen_random_uuid());

  -- Auch der Grenzfall "Startseite" und "keine Herkunft" muessen zulaessig sein.
  insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
  values ('valueadd-produkt-03', 'amazon', '/', 'desktop', gen_random_uuid());
  insert into public.click_outs (product_slug, merchant, source_path, device_class, consented_session_id)
  values ('valueadd-produkt-04', 'amazon', null, 'unknown', gen_random_uuid());

  raise notice 'Constraints greifen: %/% Faelle abgelehnt, drei zulaessige Datensaetze akzeptiert.',
    abgelehnt, array_length(faelle, 1);
end $$;
