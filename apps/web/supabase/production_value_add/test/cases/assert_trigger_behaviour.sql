-- Der echte seo_updated_at_trigger.sql ist die Voraussetzung dafuer, dass
-- 04 (updated_at = now()) und 06 (updated_at = Snapshotwert) beide exakt das
-- schreiben, was sie schreiben wollen. Beide Richtungen werden hier belegt.
-- Laeuft auf einem eigenen Testprodukt, nicht auf der Zielmenge.
do $$
declare
  t0 timestamptz;
  t1 timestamptz;
  t2 timestamptz;
  t3 timestamptz;
  historisch constant timestamptz := timestamptz '2019-05-04 12:00:00+00';
begin
  insert into public.products (slug, name, tagline, affiliate_url, is_published,
                               updated_at)
  values ('cbb-test-trigger-probe', 'Trigger-Probe', 'Vorher',
          'https://example.invalid/aff/probe', true,
          timestamptz '2026-01-01 00:00:00+00');

  select updated_at into t0 from public.products
  where slug = 'cbb-test-trigger-probe';

  -- 1) Sichtbare Aenderung ohne eigenes updated_at -> Trigger setzt now().
  update public.products set tagline = 'Nachher'
  where slug = 'cbb-test-trigger-probe';
  select updated_at into t1 from public.products
  where slug = 'cbb-test-trigger-probe';
  if t1 <= t0 then
    raise exception 'Trigger defekt: sichtbare Aenderung hat updated_at nicht angehoben (% -> %).', t0, t1;
  end if;

  -- 2) Nicht indexierungsrelevante Aenderung -> updated_at bleibt stehen.
  update public.products set price_cents = 4242
  where slug = 'cbb-test-trigger-probe';
  select updated_at into t2 from public.products
  where slug = 'cbb-test-trigger-probe';
  if t2 is distinct from t1 then
    raise exception 'Trigger defekt: price_cents hat ein lastmod ausgeloest (% -> %).', t1, t2;
  end if;

  -- 3) Ausdruecklich mitgeschriebenes updated_at hat Vorrang. Genau darauf
  --    verlaesst sich 06_restore_value_add.sql beim Zurueckspielen.
  update public.products
  set tagline = 'Restore-Simulation', updated_at = historisch
  where slug = 'cbb-test-trigger-probe';
  select updated_at into t3 from public.products
  where slug = 'cbb-test-trigger-probe';
  if t3 is distinct from historisch then
    raise exception 'Trigger defekt: bewusst gesetztes updated_at wurde ueberschrieben (% statt %).',
      t3, historisch;
  end if;

  delete from public.products where slug = 'cbb-test-trigger-probe';

  raise notice 'Trigger OK: sichtbare Aenderung hebt lastmod, price_cents nicht, explizites updated_at gewinnt.';
end $$;
