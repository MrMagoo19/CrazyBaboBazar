-- ============================================================================
-- SETUP — Drift in einer Spalte, die das Paket gar nicht anfasst
-- ============================================================================
-- Aendert die tagline einer Zielzeile NACH dem Backup. tagline gehoert zu
-- keiner der vier Aenderungsgruppen; die Vorzustandspruefung des Pakets deckt
-- sie deshalb nicht ab.
--
-- Trotzdem muss 04 abbrechen: der vollstaendige Zeilenvergleich gegen das
-- Backup (to_jsonb, jede Spalte) laeuft im Vorzustandspfad zusaetzlich zur
-- Wertepruefung. Ohne ihn wuerde das Backup nach der Korrektur einen Text
-- enthalten, den es in products nie mehr gab — der Rollback-Pfad waere still
-- falsch.
-- ============================================================================

update public.products
set tagline = 'CBB-TEST: Drift in einer nicht betroffenen Spalte'
where slug = 'flauschige-handschuhe-weihnachten';

do $$
declare
  n integer;
begin
  select count(*) into n
  from public.products
  where slug = 'flauschige-handschuhe-weihnachten'
    and tagline = 'CBB-TEST: Drift in einer nicht betroffenen Spalte';
  if n <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 Zeile verstellt.', n;
  end if;
end $$;
