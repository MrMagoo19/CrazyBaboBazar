-- ============================================================================
-- Korrektur werblicher Aussagen — Befund W1 vom 2026-09-17
-- Ziel-Projekt: ydiihvzcxaaoqhmgoqvu (vor Ausführung per get_project_url prüfen)
--
-- STATUS: AM 2026-09-17 MIT BENUTZERFREIGABE GEGEN PRODUCTION AUSGEFÜHRT.
--   Ziel vorher per get_project_url geprüft: https://ydiihvzcxaaoqhmgoqvu.supabase.co
--   Selbstprüfung ohne Abweichung: A=0 noch publiziert, B=0 Knappheitsangaben,
--   C=0 verbliebene Behauptungen.
--   Ergebnis: 2 Produkte depubliziert, 4 Knappheitsangaben entfernt,
--   4 Texte entschärft (wixies 942→406, hyako 939→498, bedsure 572→446,
--   aarke 296→281 Zeichen).
--   Snapshot public.products_w1_backup_20260917 (10 Zeilen) besteht weiter.
--   Live-Nachlauf: Produktseiten mit revalidate=3600; die beiden depublizierten
--   Ziele lieferten unmittelbar danach HTTP 404, die Texte folgten mit der
--   nächsten Regenerierung.
--   Dokumentation: Money Wiki, "Recht und Compliance" — Abschnitt
--   "Ausführung W1 am 2026-09-17".
--
--   Ein erneuter Lauf bricht bewusst ab, weil die Snapshot-Tabelle bereits
--   existiert. Für eine Wiederholung zuerst den Snapshot sichern und umbenennen.
--
-- Umfang:
--   A) 2 Produkte depublizieren (Arzneimittel-/Wirkstoffwerbung, HWG-Bereich)
--   B) 4 Knappheitsangaben entfernen (veraltet, nicht überprüfbar)
--   C) 4 Texte entschärfen (Auszeichnung, Empfehlung, Wirkversprechen)
--
-- Reversibel: Snapshot in products_w1_backup_20260917, Rollback unten als
-- eigener Block. Es wird keine Zeile gelöscht.
-- ============================================================================

begin;

set local statement_timeout = '60s';
set local idle_in_transaction_session_timeout = '60s';

-- ---------------------------------------------------------------------------
-- 0 · Snapshot
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.products_w1_backup_20260917') is not null then
    raise exception 'Snapshot-Tabelle existiert bereits — bitte vorher prüfen.';
  end if;
end $$;

create table public.products_w1_backup_20260917 as
select id, slug, name, tagline, description, is_published, now() as gesichert_am
from public.products
where slug in (
  'regaine-maenner-minoxidil-3-monatspackung',
  'delay-spray-maenner-mega-xxl',
  'uglydolls-babo-briefkumpel-plueschfigur-22cm',
  'uglydolls-moxy-sound-plueschfigur-29cm',
  'uglydolls-ox-schmuse-pluesch-45cm',
  'uglydolls-jeero-pfannkuchenheld',
  'wixies-wichstuecher-scherzartikel',
  'aarke-wasserkocher-edelstahl-1-2l',
  'bedsure-satin-kissenbezug-doppelpack',
  'hyako-massagepistole-triggerpunkt'
);

do $$
declare n int;
begin
  select count(*) into n from public.products_w1_backup_20260917;
  if n <> 10 then
    raise exception 'Snapshot unvollständig: % von 10 Zeilen gesichert.', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- A · Depublizieren — Werbung im Anwendungsbereich des Heilmittelwerbegesetzes
--     Kein Löschen. Die Datensätze bleiben vollständig erhalten.
-- ---------------------------------------------------------------------------
update public.products
set is_published = false, updated_at = now()
where slug in (
  'regaine-maenner-minoxidil-3-monatspackung',  -- Minoxidil 5 %, apothekenpflichtig
  'delay-spray-maenner-mega-xxl'                -- Lidocain, Indikationsaussage
)
and is_published = true;

-- ---------------------------------------------------------------------------
-- B · Knappheitsangaben entfernen
--     "laut Bestandsanzeige nur noch N Exemplare" ist eine Momentaufnahme,
--     die auf einer dauerhaft erreichbaren Seite nicht überprüfbar bleibt.
-- ---------------------------------------------------------------------------
update public.products
set description = regexp_replace(
      description,
      ',?\s*laut Bestandsanzeige (zuletzt )?nur noch \d+ Exemplare',
      '', 'g'),
    updated_at = now()
where slug in (
  'uglydolls-babo-briefkumpel-plueschfigur-22cm',
  'uglydolls-moxy-sound-plueschfigur-29cm',
  'uglydolls-ox-schmuse-pluesch-45cm',
  'uglydolls-jeero-pfannkuchenheld'
)
and description ilike '%Bestandsanzeige%';

-- ---------------------------------------------------------------------------
-- C · Texte entschärfen
-- ---------------------------------------------------------------------------

-- C1 · wixies — unbelegte Auszeichnung, "Jetzt bestellen", Erfolgsversprechen
update public.products
set tagline = 'Sieben Servietten, die den Männerabend kippen lassen.',
    description = 'Sieben Scherzservietten, 33 × 33 cm, mit frechen Motiven. Gedacht für den Moment, in dem jemand sie zum ersten Mal auseinanderfaltet und kurz nicht weiß, wohin schauen.

Kein Papiertuch für den Alltag, sondern ein Gag-Geschenk für den besten Kumpel, den Grillabend oder den JGA. Die Packung ist handlich genug für den Rucksack.

Wer Humor unterhalb der Gürtellinie nicht mag, lässt besser die Finger davon.',
    updated_at = now()
where slug = 'wixies-wichstuecher-scherzartikel';

-- C2 · aarke — "Preisgekrönt" ohne nennbare Auszeichnung
update public.products
set description = replace(description,
      'Preisgekröntes skandinavisches Design, in vier Farben.',
      'Skandinavisches Design, in vier Farben.'),
    updated_at = now()
where slug = 'aarke-wasserkocher-edelstahl-1-2l';

-- C3 · bedsure — Berufsgruppen-Empfehlung, Bestseller-Behauptung, Wirkversprechen
update public.products
set tagline = 'Satin gleitet, Baumwolle zieht — der Unterschied zeigt sich morgens.',
    description = 'Wer einmal auf Satin geschlafen hat, versteht den Hype. Baumwolle zieht an Haaren und Haut, Satin gleitet. Deshalb greifen viele Menschen mit langen, lockigen oder gefärbten Haaren dazu.

Das Bedsure 2er-Set besteht aus Satin, nicht aus Seide. 40 × 80 cm, Umschlagverschluss zum einfachen Aufziehen, maschinenwaschbar bei 30 °C, in mehr als zehn Farben erhältlich.

Kleines Investment, und du merkst ziemlich schnell, ob es für dich etwas ändert.',
    updated_at = now()
where slug = 'bedsure-satin-kissenbezug-doppelpack';

-- C4 · hyako — Behandlungsversprechen und "professionelle Massage"
update public.products
set description = 'Dein Rücken meldet sich, deine Waden rächen sich nach dem Joggen, und der Termin beim Physiotherapeuten ist Wochen entfernt. Die HYAKO Massagepistole überbrückt genau diese Lücke.

Bis zu 3200 Umdrehungen pro Minute, dabei so leise, dass nebenher ein Podcast läuft. Sechs Aufsätze für unterschiedliche Muskelgruppen, von der Wade bis zur Schulter.

Für Sportler nach dem Training, für alle mit langen Bürotagen — und ausdrücklich kein Ersatz für eine ärztliche oder physiotherapeutische Behandlung.',
    updated_at = now()
where slug = 'hyako-massagepistole-triggerpunkt';

-- ---------------------------------------------------------------------------
-- Selbstprüfung vor COMMIT
-- ---------------------------------------------------------------------------
-- KORRIGIERT 2026-09-18. Die ursprüngliche Fassung fragte nur `description`
-- und `tagline` ab und meldete deshalb "bestanden", obwohl dieselben Aussagen
-- in `editorial_note`, `pros` und `cons` standen und live ausgeliefert wurden.
-- Eine Produktseite rendert neun Textfelder; eine Prüfung über zwei davon
-- beweist nichts. Die Nacharbeit steht in `fix_werbeaussagen_w1b_20260918.sql`.
do $$
declare
  noch_publiziert int;
  treffer         int;
  wo              text;
begin
  select count(*) into noch_publiziert from public.products
   where slug in ('regaine-maenner-minoxidil-3-monatspackung','delay-spray-maenner-mega-xxl')
     and is_published = true;
  if noch_publiziert <> 0 then
    raise exception 'A fehlgeschlagen: % noch publiziert', noch_publiziert;
  end if;

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
    raise exception 'B/C fehlgeschlagen: % Treffer in %', treffer, wo;
  end if;

  raise notice 'Selbstprüfung bestanden: depubliziert=0, Textfeld-Treffer=0';
end $$;

commit;

-- ---------------------------------------------------------------------------
-- Ergebnisabfrage (nach COMMIT ausführen)
-- ---------------------------------------------------------------------------
select slug, is_published, left(coalesce(tagline,''),60) as tagline, length(description) as desc_laenge
from public.products
where slug in (select slug from public.products_w1_backup_20260917)
order by is_published desc, slug;


-- ===========================================================================
-- ROLLBACK — nur bei Bedarf, als eigener Lauf
-- ===========================================================================
-- begin;
--   update public.products p
--      set name = b.name, tagline = b.tagline, description = b.description,
--          is_published = b.is_published, updated_at = now()
--     from public.products_w1_backup_20260917 b
--    where p.id = b.id;
--   -- Snapshot bewusst NICHT löschen, bis die Rückabwicklung geprüft ist.
-- commit;
