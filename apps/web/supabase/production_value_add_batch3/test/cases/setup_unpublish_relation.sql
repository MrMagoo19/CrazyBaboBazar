-- Negativfall: ein Relationsziel geht offline.
--
-- tecknet-ergonomische-kabellose-maus-bluetooth ist gleichzeitig Zielprodukt
-- UND Ziel der complement-Relation von laptop-staender. Wird es unpublished,
-- muessen die Guards schon an der Zielmenge scheitern (9/10 published) — lange
-- bevor eine Relation ins Leere zeigen koennte.
update public.products
set is_published = false
where slug = 'tecknet-ergonomische-kabellose-maus-bluetooth';

-- is_published steht in der Spaltenliste von products_touch_updated_at(), das
-- Unpublishen hebt updated_at also zu Recht an. Fuer diesen Testfall soll aber
-- ausschliesslich der Published-Guard geprueft werden, nicht das lastmod-
-- Verhalten (dafuer ist der Trigger-Fall da). Der historische Wert wird deshalb
-- ausdruecklich wieder mitgeschrieben — der Trigger respektiert ein explizit
-- gesetztes updated_at und laesst es stehen. So bleibt die Baseline-Pruefung in
-- assert_no_batch3_artifacts.sql aussagekraeftig.
update public.products p
set updated_at = b.updated_at
from cbb_test_baseline.products_before b
where p.id = b.id
  and p.slug = 'tecknet-ergonomische-kabellose-maus-bluetooth';

do $$
declare
  ziele_published integer;
  relationsziele_published integer;
  lastmod_drift integer;
begin
  select count(*) into ziele_published
  from public.products
  where slug in (
    'bartesian-cocktailmaschine-mit-kapseln',
    'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
    'laptop-staender-hoehenverstellbar-360-drehbar',
    'tecknet-ergonomische-kabellose-maus-bluetooth',
    'rocketbook-wiederverwendbares-notizbuch-a4',
    'ticktime-tk3-wuerfel-timer-countdown',
    'kabeltasche-edc-elektronik-organizer-reise',
    'silikon-magnete-airfryer-backpapier-4er-set',
    'tre-feuerstahl-xxl',
    'bbq-wuerstchenhalter-maennchen-3er-set'
  ) and is_published is true;

  select count(*) into relationsziele_published
  from public.products
  where slug in ('laptop-staender-hoehenverstellbar-360-drehbar',
                 'tecknet-ergonomische-kabellose-maus-bluetooth')
    and is_published is true;

  if ziele_published <> 9 or relationsziele_published <> 1 then
    raise exception 'Setup kaputt: %/10 Ziele und %/2 Relationsziele published (erwartet 9 und 1).',
      ziele_published, relationsziele_published;
  end if;

  select count(*) into lastmod_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.updated_at is distinct from b.updated_at;
  if lastmod_drift <> 0 then
    raise exception 'Setup kaputt: % Zeilen mit veraendertem updated_at, erwartet 0.',
      lastmod_drift;
  end if;
end $$;
