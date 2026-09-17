-- ============================================================================
-- Nachkorrektur W1b — 2026-09-18
-- Ziel-Projekt: ydiihvzcxaaoqhmgoqvu (vor Ausführung per get_project_url prüfen)
--
-- STATUS: AM 2026-09-18 MIT BENUTZERFREIGABE GEGEN PRODUCTION AUSGEFÜHRT.
--
-- ANLASS
--   `fix_werbeaussagen_20260917.sql` hat die beanstandeten Aussagen nur in
--   `description` und `tagline` entfernt. Die Selbstprüfung dort hat ebenfalls
--   nur diese beiden Felder abgefragt und war deshalb grün, obwohl dieselben
--   Behauptungen in weiteren Feldern standen und live weiter ausgeliefert
--   wurden:
--
--     aarke-wasserkocher-edelstahl-1-2l   editorial_note  "preisgekröntes …"
--     aarke-wasserkocher-edelstahl-1-2l   pros[]          "Preisgekröntes …"
--     4x uglydolls-*                      cons[]          "nur noch N Exemplare
--                                                          laut Bestandsanzeige"
--
--   LEHRE: Eine Produktseite rendert neun Textfelder. Eine Prüfung, die zwei
--   davon abfragt, beweist nichts. Der Prüfblock unten geht über alle neun.
--
-- Reversibel: Snapshot public.products_w1b_backup_20260918 (5 Zeilen,
-- editorial_note/pros/cons). Rollback am Dateiende. Keine Zeile wird gelöscht.
-- ============================================================================

begin;

set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';

-- ---------------------------------------------------------------------------
-- 0 · Snapshot der Felder, die das Vorgängerskript nicht gesichert hat
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.products_w1b_backup_20260918') is not null then
    raise exception 'Snapshot-Tabelle existiert bereits — bitte vorher prüfen.';
  end if;
end $$;

create table public.products_w1b_backup_20260918 as
select id, slug, editorial_note, pros, cons, now() as gesichert_am
from public.products
where slug in (
  'aarke-wasserkocher-edelstahl-1-2l',
  'uglydolls-babo-briefkumpel-plueschfigur-22cm',
  'uglydolls-jeero-pfannkuchenheld',
  'uglydolls-moxy-sound-plueschfigur-29cm',
  'uglydolls-ox-schmuse-pluesch-45cm'
);

do $$
declare n int;
begin
  select count(*) into n from public.products_w1b_backup_20260918;
  if n <> 5 then raise exception 'Snapshot unvollständig: % von 5 Zeilen.', n; end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1 · aarke — unbelegte Auszeichnung in editorial_note und pros
-- ---------------------------------------------------------------------------
update public.products
set editorial_note = replace(editorial_note,
      'preisgekröntes skandinavisches Design', 'skandinavisches Design'),
    pros = array_replace(pros,
      'Preisgekröntes skandinavisches Design, in vier Farben erhältlich',
      'Skandinavisches Design, in vier Farben erhältlich'),
    updated_at = now()
where slug = 'aarke-wasserkocher-edelstahl-1-2l';

-- ---------------------------------------------------------------------------
-- 2 · UglyDolls — Knappheitsangabe als eigenes cons-Element entfernen
--     array_remove trifft nur exakte Elemente; die übrigen Contra-Punkte
--     ("Marketplace-Angebot", "Restbestand der 2019er-Welle") bleiben stehen.
-- ---------------------------------------------------------------------------
update public.products
set cons = array_remove(
             array_remove(cons, 'nur noch 10 Exemplare laut Bestandsanzeige'),
             'nur noch 2 Exemplare laut Bestandsanzeige'),
    updated_at = now()
where slug in (
  'uglydolls-babo-briefkumpel-plueschfigur-22cm',
  'uglydolls-jeero-pfannkuchenheld',
  'uglydolls-moxy-sound-plueschfigur-29cm',
  'uglydolls-ox-schmuse-pluesch-45cm'
);

-- ---------------------------------------------------------------------------
-- 3 · Selbstprüfung über ALLE neun Textfelder der Produktseite
-- ---------------------------------------------------------------------------
do $$
declare treffer int; wo text;
begin
  with alle as (
     select slug,'description' f, description t from public.products where is_published
     union all select slug,'tagline',            tagline            from public.products where is_published
     union all select slug,'editorial_note',     editorial_note     from public.products where is_published
     union all select slug,'key_fact',           key_fact           from public.products where is_published
     union all select slug,'fuer_wen',           fuer_wen           from public.products where is_published
     union all select slug,'nicht_fuer',         nicht_fuer         from public.products where is_published
     union all select slug,'alternative_reason', alternative_reason from public.products where is_published
     union all select slug,'pros',  array_to_string(pros,' ~ ')     from public.products where is_published
     union all select slug,'cons',  array_to_string(cons,' ~ ')     from public.products where is_published)
  select count(*), string_agg(distinct slug||'/'||f, ', ')
    into treffer, wo
  from alle
  where t ~* '(Bestandsanzeige|preisgekrönt|Venus-Award|Bestseller auf Amazon|Friseure empfehlen|nur noch [0-9]+ Exemplare)';

  if treffer <> 0 then
    raise exception 'Prüfung fehlgeschlagen: % Treffer in %', treffer, wo;
  end if;
  raise notice 'Prüfung bestanden: 0 Treffer über alle neun Textfelder.';
end $$;

commit;

-- ---------------------------------------------------------------------------
-- Ergebnisabfrage (nach COMMIT)
-- ---------------------------------------------------------------------------
select p.slug,
       array_length(p.cons,1) as cons_neu,
       array_length(b.cons,1) as cons_vorher,
       (p.editorial_note is distinct from b.editorial_note) as note_geaendert,
       (p.pros           is distinct from b.pros)           as pros_geaendert
from public.products p
join public.products_w1b_backup_20260918 b on b.id = p.id
order by p.slug;


-- ===========================================================================
-- ROLLBACK — nur bei Bedarf, als eigener Lauf
-- ===========================================================================
-- begin;
--   update public.products p
--      set editorial_note = b.editorial_note, pros = b.pros, cons = b.cons,
--          updated_at = now()
--     from public.products_w1b_backup_20260918 b
--    where p.id = b.id;
-- commit;
