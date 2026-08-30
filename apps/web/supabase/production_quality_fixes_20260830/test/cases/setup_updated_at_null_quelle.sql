-- ============================================================================
-- SETUP — eine Zielzeile hat updated_at IS NULL (vor 02)
-- ============================================================================
-- Der Fall ist nicht konstruiert: schema.sql definiert updated_at nur als
-- DEFAULT now(), nicht als NOT NULL. Ein Import oder ein Skript, das die Spalte
-- ausdruecklich mit NULL beschreibt, erzeugt genau diesen Zustand.
--
-- Warum das gefaehrlich ist: 04 und 05 belegen das neue lastmod ueber
-- "p.updated_at > b.updated_at". Ist der alte Wert NULL, ergibt der Vergleich
-- NULL — die Zeile zaehlt weder als "neu" noch als "nicht neu". 06 wiederum
-- haette keinen historischen Zeitstempel zurueckzuspielen. Der Snapshot aus 02
-- waere als Rollback-Quelle wertlos, ohne dass irgendetwas auffiele.
--
-- Bewusst wird divoom-pixoo-led-panel verstellt: die uebrigen
-- Vorzustandsmerkmale dieser Zeile (price_cents IS NULL, is_published) bleiben
-- erfuellt, 02 kommt also bis zum Vorzustandsbeweis und bricht danach genau am
-- neuen updated_at-Guard ab — nicht schon vorher aus einem anderen Grund.
--
-- Der Trigger products_set_updated_at greift hier NICHT: er ueberschreibt nur,
-- wenn der Aufrufer updated_at nicht selbst mitschreibt. Hier tut er es.
-- ============================================================================

update public.products
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel' and updated_at is null;
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Zeile mit updated_at IS NULL.', n;
  end if;

  -- Die uebrigen Vorzustandsmerkmale muessen erhalten sein, sonst traefe 02
  -- eine andere Abbruchbedingung und der Fall belegte nichts.
  select count(*) into n
  from public.products
  where slug = 'divoom-pixoo-led-panel'
    and price_cents is null
    and is_published is true;
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: der uebrige Vorzustand der Zeile stimmt nicht mehr.';
  end if;
end $$;
