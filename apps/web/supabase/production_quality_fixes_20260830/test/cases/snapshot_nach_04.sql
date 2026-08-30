-- ============================================================================
-- SNAPSHOT — Zustand unmittelbar nach dem ersten erfolgreichen 04
-- ============================================================================
-- Wird gebraucht, um die Idempotenz von 04 scharf zu pruefen: der zweite Lauf
-- muss ein echter No-Op sein. "Kein UPDATE" ist dabei nicht dasselbe wie "kein
-- sichtbarer Unterschied" — ein erneutes updated_at = now() wuerde die
-- Zielwerte unveraendert lassen und trotzdem ein falsches lastmod an Google
-- melden. Deshalb wird hier der VOLLSTAENDIGE Zeilenfingerabdruck festgehalten,
-- updated_at eingeschlossen.
-- ============================================================================

create table cbb_test.nach_04_products as
select p.id, p.slug, md5(to_jsonb(p)::text) as fingerabdruck
from public.products p;

create table cbb_test.nach_04_lists as
select l.id, l.slug, md5(to_jsonb(l)::text) as fingerabdruck
from public.lists l;

alter table cbb_test.nach_04_products add primary key (id);
alter table cbb_test.nach_04_lists    add primary key (id);
