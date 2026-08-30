-- Zustand nach 04_retention.sql: exakt die fuenf alten Ereignisse sind weg,
-- die fuenf frischen stehen unveraendert.
do $$
declare
  gesamt bigint;
  alt bigint;
  aeltestes timestamptz;
begin
  select count(*) into gesamt from public.click_outs;
  select count(*) into alt from public.click_outs
  where created_at < now() - interval '12 months';
  select min(created_at) into aeltestes from public.click_outs;

  if gesamt <> 5 then
    raise exception 'Nach 04: % Ereignis(se) (erwartet 5).', gesamt;
  end if;
  if alt <> 0 then
    raise exception 'Nach 04: % ueberfaellige Ereignis(se) (erwartet 0).', alt;
  end if;
  if aeltestes < now() - interval '12 months' then
    raise exception 'Nach 04: aeltestes Ereignis % liegt ausserhalb des Fensters.', aeltestes;
  end if;

  -- Struktur bleibt vollstaendig. Retention loescht Zeilen, nichts anderes.
  if to_regclass('public.click_outs') is null
     or to_regclass('cbb_private_analytics.click_outs_daily') is null then
    raise exception 'Nach 04: Retention hat Struktur entfernt.';
  end if;

  raise notice 'Nach 04 OK: 5 Ereignisse verbleiben, 0 ueberfaellig, Struktur unveraendert.';
end $$;
