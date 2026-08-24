-- Ein Relationsziel offline nehmen: die Zielseite wuerde ins Leere verlinken.
update public.products
set is_published = false
where slug = 'aeropress-go-tragbare-kaffeemaschine';
