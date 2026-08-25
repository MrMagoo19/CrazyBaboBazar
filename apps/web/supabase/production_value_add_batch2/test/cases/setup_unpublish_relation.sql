-- Ein Relationsziel offline nehmen: die Zielseite wuerde ins Leere verlinken.
--
-- BESONDERHEIT VON BATCH 2: beide Relationsziele (gluecksgut-anti-stress-wuerfel
-- und shashibo-formwechsel-box-magnetisch) liegen INNERHALB der Zielmenge. Wird
-- eines unpublished, schlaegt deshalb bereits der frueher stehende Guard
-- "10/10 Zielprodukte published" an — nicht erst der Relationsguard. Das ist
-- die strengere, nicht die schwaechere Bedingung: der Vorgang stoppt frueher.
-- Der Harness erwartet genau diese Meldung.
update public.products
set is_published = false
where slug = 'shashibo-formwechsel-box-magnetisch';

-- is_published steht in der Spaltenliste von products_touch_updated_at(), das
-- Unpublishen hebt updated_at also zu Recht an. Fuer diesen Testfall soll aber
-- ausschliesslich der Published-Guard geprueft werden, nicht das lastmod-
-- Verhalten (dafuer ist case_i_trigger da). Der historische Wert wird deshalb
-- ausdruecklich wieder mitgeschrieben — der Trigger respektiert ein explizit
-- gesetztes updated_at und laesst es stehen. So bleibt die Baseline-Pruefung in
-- assert_no_batch2_artifacts.sql aussagekraeftig.
update public.products p
set updated_at = b.updated_at
from cbb_test_baseline.products_before b
where p.id = b.id
  and p.slug = 'shashibo-formwechsel-box-magnetisch';

do $$
declare
  n integer;
  lastmod_drift integer;
begin
  select count(*) into n from public.products
  where slug = 'shashibo-formwechsel-box-magnetisch' and is_published is true;
  if n <> 0 then
    raise exception 'Setup kaputt: shashibo ist immer noch published.';
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
