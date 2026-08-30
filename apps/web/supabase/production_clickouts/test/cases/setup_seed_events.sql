-- Setzt einen Bestand mit klarer Altersgrenze auf: fuenf Ereignisse aelter als
-- 12 Monate und fuenf innerhalb des Fensters. Die Retention muss danach exakt
-- die fuenf alten treffen und keines der fuenf frischen.
--
-- Der explizite created_at-Wert ist hier zulaessig, weil der Harness als
-- Eigentuemer laeuft. Die Anwendung sendet die Spalte nie mit — dort greift
-- immer der Default now().
insert into public.click_outs
  (product_slug, merchant, source_path, device_class, consented_session_id, created_at)
select
  'valueadd-produkt-' || to_char(g, 'FM00'),
  'amazon',
  '/thema/tech',
  (array['mobile', 'tablet', 'desktop', 'unknown'])[1 + (g % 4)],
  gen_random_uuid(),
  now() - interval '14 months' + (g || ' days')::interval
from generate_series(1, 5) as g;

insert into public.click_outs
  (product_slug, merchant, source_path, device_class, consented_session_id, created_at)
select
  'valueadd-produkt-' || to_char(g + 5, 'FM00'),
  'amazon',
  '/thema/outdoor',
  'mobile',
  gen_random_uuid(),
  now() - interval '3 days' + (g || ' hours')::interval
from generate_series(1, 5) as g;

do $$
declare
  gesamt bigint;
  alt bigint;
begin
  select count(*) into gesamt from public.click_outs;
  select count(*) into alt from public.click_outs
  where created_at < now() - interval '12 months';
  if gesamt <> 10 or alt <> 5 then
    raise exception 'Setup kaputt: % Ereignisse (erwartet 10), davon % alt (erwartet 5).',
      gesamt, alt;
  end if;
end $$;
