-- ============================================================================
-- ASSERT — die konkurrierende Listenaenderung hat ueberlebt
-- ============================================================================
-- Nach dem Nebenlaeufigkeitstest gegen 04: die zweite Session hat
-- product_slugs von geschenke-fuer-gamer gesetzt und committet. 04 hatte seine
-- sperrfreie Vorpruefung bereits bestanden, als die Konkurrenz noch nicht
-- committet war. Nur die erneute Klassifizierung NACH dem erworbenen Lock
-- sieht den neuen Stand — und genau die muss 04 abbrechen lassen, statt den
-- Zielzustand darueberzuschreiben.
--
-- public.lists hat keine Spalte updated_at. Ein Zeitstempelvergleich waere
-- hier also gar nicht moeglich; nur der Wertevergleich kann die Aenderung
-- ueberhaupt finden.
-- ============================================================================

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.lists
  where slug = 'geschenke-fuer-gamer'
    and product_slugs = array['CBB-TEST: konkurrierende Aenderung an product_slugs'];
  if n <> 1 then
    raise exception 'Die konkurrierende Aenderung an product_slugs fehlt (%/1).', n;
  end if;

  -- Die uebrigen acht Zielzeilen stehen weiterhin im Vorzustand: 04 hat
  -- nichts teilweise geschrieben.
  select count(*) into n
  from public.products p
  join cbb_private_backup.quality_fixes_20260830_products_v1 b
    on b.id = p.id and b.slug = p.slug
  where to_jsonb(p) is not distinct from to_jsonb(b);
  if n <> 6 then
    raise exception 'Nur %/6 Produktzeilen sind unveraendert — 04 hat teilweise geschrieben.', n;
  end if;

  select count(*) into n
  from public.lists
  where slug in ('verrueckte-amazon-gadgets', 'witzige-geschenke-maenner')
    and (product_slugs[4] = 'plasmakugel-8-zoll-beruehlungsempfindlich'
      or product_slugs[2] = 'bug-a-salt-3-0-fliegenjager-salzgewehr');
  if n <> 2 then
    raise exception 'Nur %/2 A4-Listen sind unveraendert — 04 hat teilweise geschrieben.', n;
  end if;
end $$;
