-- ============================================================================
-- FIXTURE 03 — Baseline-Fingerabdruck des gesamten Vorzustands
-- ============================================================================
-- Legt im Hilfsschema cbb_test je einen md5-Fingerabdruck ueber die
-- VOLLSTAENDIGE Zeile jedes Produkts und jeder Liste ab. Die Assertions in
-- test/cases/ vergleichen spaeter gegen diese Baseline:
--
--   assert_base_state.sql   alles gleich der Baseline
--   assert_after_04.sql     genau zehn Zeilen abweichend, alle anderen gleich
--   assert_after_06.sql     wieder alles gleich der Baseline — der Round-Trip
--                           ist damit exakt, updated_at eingeschlossen
--
-- cbb_test gehoert zum Harness und hat mit dem Paket nichts zu tun. Es steht
-- bewusst NICHT in cbb_private_backup, damit die Rechte- und Formpruefungen
-- von 03 und 05 davon nicht beruehrt werden.
-- ============================================================================

create schema cbb_test;
revoke all on schema cbb_test from public, anon, authenticated, service_role;

create table cbb_test.baseline_products as
select p.id, p.slug, md5(to_jsonb(p)::text) as fingerabdruck
from public.products p;

create table cbb_test.baseline_lists as
select l.id, l.slug, md5(to_jsonb(l)::text) as fingerabdruck
from public.lists l;

alter table cbb_test.baseline_products add primary key (id);
alter table cbb_test.baseline_lists    add primary key (id);

-- Die zehn Zielzeilen namentlich, damit die Assertions "Zielzeile" und
-- "Nichtzielzeile" ohne Wiederholung der Slug-Listen unterscheiden koennen.
create table cbb_test.zielprodukte (slug text primary key);
insert into cbb_test.zielprodukte values
  ('fingerabdruck-vorhaengeschloss-eseesmart'),
  ('flauschige-handschuhe-weihnachten'),
  ('pizza-socks-box-pepperoni'),
  ('divoom-pixoo-led-panel'),
  ('divoom-minitoo-retro-pc-lautsprecher-pixel'),
  ('cream-noise-machine-baby-tragbar'),
  ('plasmakugel-8-zoll-beruehrungsempfindlich');

create table cbb_test.ziellisten (slug text primary key);
insert into cbb_test.ziellisten values
  ('verrueckte-amazon-gadgets'),
  ('witzige-geschenke-maenner'),
  ('geschenke-fuer-gamer');
