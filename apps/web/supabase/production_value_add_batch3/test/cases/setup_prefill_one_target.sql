-- Negativfall: eine Zielzeile traegt bereits Value-Add-Daten. Das kann nur
-- bedeuten, dass jemand anderes an dieser Zeile gearbeitet hat — Batch 3 darf
-- sie dann nicht ueberschreiben.
--
-- Wie in setup_unpublish_relation.sql wird der historische updated_at-Wert
-- ausdruecklich wieder mitgeschrieben, damit die Baseline-Pruefung danach
-- ausschliesslich das Vorbefuellen sieht und nicht zusaetzlich ein
-- Trigger-Artefakt.
update public.products
set key_fact = 'FREMD: dieser Text stammt nicht aus Batch 3.'
where slug = 'rocketbook-wiederverwendbares-notizbuch-a4';

update public.products p
set updated_at = b.updated_at
from cbb_test_baseline.products_before b
where p.id = b.id
  and p.slug = 'rocketbook-wiederverwendbares-notizbuch-a4';

do $$
declare
  befuellt integer;
  lastmod_drift integer;
begin
  select count(*) into befuellt from public.products
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
  ) and (fuer_wen is not null or nicht_fuer is not null or key_fact is not null
      or pros is not null or cons is not null or alternative_slug is not null
      or alternative_reason is not null or alternative_kind is not null);
  if befuellt <> 1 then
    raise exception 'Setup kaputt: % vorbefuellte Zielzeilen (erwartet 1).', befuellt;
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
