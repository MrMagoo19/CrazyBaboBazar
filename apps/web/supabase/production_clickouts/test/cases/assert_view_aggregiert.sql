-- Die Auswertungs-View darf ausschliesslich Aggregate liefern. Dieser Fall
-- belegt das inhaltlich, nicht nur ueber den Katalog.
do $$
declare
  view_spalten text;
  zeilen bigint;
  klicks bigint;
  sitzungen bigint;
  ereignisse bigint;
begin
  select string_agg(a.attname, ', ' order by a.attnum) into view_spalten
  from pg_attribute a
  where a.attrelid = 'cbb_private_analytics.click_outs_daily'::regclass
    and a.attnum > 0 and not a.attisdropped;

  if view_spalten <> 'tag, product_slug, merchant, device_class, herkunftspfad, klicks, sitzungen' then
    raise exception 'View-Spalten unerwartet: %', view_spalten;
  end if;

  select count(*), coalesce(sum(v.klicks), 0), coalesce(sum(v.sitzungen), 0)
  into zeilen, klicks, sitzungen
  from cbb_private_analytics.click_outs_daily v;

  select count(*) into ereignisse from public.click_outs;

  -- Die Summe der Aggregate muss die Grundmenge exakt abbilden. Ein Filter in
  -- der View waere sonst still und wuerde Zahlen verfaelschen.
  if klicks <> ereignisse then
    raise exception 'View zaehlt % Klicks, die Tabelle hat % Zeilen.', klicks, ereignisse;
  end if;
  if zeilen = 0 then
    raise exception 'View liefert keine Zeilen, obwohl % Ereignisse vorliegen.', ereignisse;
  end if;
  if sitzungen > klicks then
    raise exception 'View meldet mehr Sitzungen (%) als Klicks (%).', sitzungen, klicks;
  end if;

  raise notice 'View OK: % Aggregatzeile(n), % Klicks, % Sitzungen, keine Einzelkennung.',
    zeilen, klicks, sitzungen;
end $$;
