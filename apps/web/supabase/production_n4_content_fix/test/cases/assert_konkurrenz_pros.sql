-- ============================================================================
-- ASSERT — echter Nebenlaeufigkeitstest fuer 02
-- ============================================================================
-- Ausgangslage: eine zweite Session hielt einen Row-Lock auf der N4-Zeile,
-- aenderte pros und commitete erst, nachdem 02 nachweislich auf den Lock
-- wartete. 02 hat den Lock danach erworben.
--
-- Beweist:
--   1. die konkurrierende pros-Aenderung steht unveraendert in products —
--      02 hat sie also nicht ueberschrieben,
--   2. es existiert KEIN Backup-Artefakt — 02 hat nach dem Lock erneut alle
--      sieben Vorwerte geprueft und abgebrochen, statt einen abweichenden
--      Stand zu sichern,
--   3. kein Zieltext ist in der Datenbank gelandet.
-- ============================================================================

do $$
declare
  konkurrenz_treffer integer;
  ziel_treffer integer;
begin
  select count(*) into konkurrenz_treffer
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and pros is not distinct from
      array['CBB-TEST: konkurrierende Aenderung an pros']::text[];
  if konkurrenz_treffer <> 1 then
    raise exception 'Konkurrenztest 02: pros traegt die konkurrierende Aenderung %/1 mal — 02 hat fremde Daten ueberschrieben.',
      konkurrenz_treffer;
  end if;

  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is not null then
    raise exception 'Konkurrenztest 02: 02 hat trotz Abbruch ein Backup-Artefakt hinterlassen.';
  end if;

  select count(*) into ziel_treffer
  from public.products
  where tagline is not distinct from
    '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm';
  if ziel_treffer <> 0 then
    raise exception 'Konkurrenztest 02: % Zeilen tragen den Zieltext.', ziel_treffer;
  end if;

  raise notice 'OK: konkurrierende pros-Aenderung erhalten, kein Backup entstanden.';
end $$;
