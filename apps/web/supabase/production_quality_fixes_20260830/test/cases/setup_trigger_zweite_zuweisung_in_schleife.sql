-- ============================================================================
-- SETUP — Triggervertrag verletzt: korrekter Guard, danach eine zweite,
--          bedingungslose Zuweisung IN EINER LOOP
-- ============================================================================
-- Dieser Rumpf ist der gefaehrlichste der Reihe, weil er auf den ersten Blick
-- vertragskonform aussieht:
--   * der Guard steht da, wortwoertlich wie im deployten Trigger,
--   * die Zuweisung steht zwischen THEN und END IF,
--   * die geordnete Regex des Preflight passt,
--   * END IF kommt genau einmal vor (die Schleife endet mit END LOOP).
--
-- Trotzdem ist der Vertrag gebrochen: die zweite Zuweisung in der Schleife
-- laeuft bedingungslos und ueberschreibt jedes vom Aufrufer ausdruecklich
-- gesetzte updated_at mit now(). Genau das darf nicht passieren — 04 schreibt
-- bei den sechs sichtbaren Produktseiten einen bestimmten Zeitstempel mit, und
-- die A4-Unterkategorie soll gar kein neues lastmod bekommen.
--
-- WARUM DIE LOOP: eine Zaehlung, die nur Zuweisungen an bestimmten
-- Statementpositionen erkennt (etwa nach begin, then oder einem Semikolon),
-- sieht die Zuweisung hinter "loop" nicht und kaeme auf genau eine Zuweisung —
-- der Preflight meldete faelschlich PASS. Die Zaehlung in 01 ist deshalb
-- positionsunabhaengig: sie zaehlt JEDES new.updated_at := / = im
-- kommentarbereinigten Rumpf. Hier sind es zwei, und 01 muss die Zeile
-- products_updated_at_triggervertrag als FAIL melden.
--
-- Die zweite Zuweisung benutzt bewusst die Form "=" statt ":=", damit auch
-- diese gueltige PL/pgSQL-Schreibweise von der Zaehlung erfasst werden muss.
-- shop_sub_category kommt im Rumpf nicht vor: der Fall soll genau an der
-- zweiten Zuweisung scheitern, nicht an einer zweiten Abweichung.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at is not distinct from old.updated_at
     and (new.name) is distinct from (old.name)
  then
    new.updated_at := now();
  end if;

  for durchlauf in 1..1 loop
    new.updated_at = now();
  end loop;

  return new;
end
$$;

do $$
declare
  zuweisungen integer;
begin
  select count(*) into zuweisungen
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'new\.updated_at[[:space:]]*(:=|=)',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if zuweisungen <> 2 then
    raise exception 'Setup fehlgeschlagen: %/2 updated_at-Zuweisungen im Rumpf der aktiven Triggerfunktion.', zuweisungen;
  end if;
end $$;

-- Gegenprobe: END IF steht weiterhin genau einmal da. Sonst wuerde dieser Fall
-- schon an der END-IF-Zaehlung scheitern und nicht an der zweiten Zuweisung.
do $$
declare
  end_if_bloecke integer;
begin
  select count(*) into end_if_bloecke
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'end[[:space:]]+if;',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if end_if_bloecke <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 END IF im Rumpf der aktiven Triggerfunktion.', end_if_bloecke;
  end if;
end $$;
