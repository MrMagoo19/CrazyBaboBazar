-- ============================================================================
-- ASSERT — echter Nebenlaeufigkeitstest fuer 04
-- ============================================================================
-- Ausgangslage: 02 hat sauber gesichert. Danach hielt eine zweite Session einen
-- Row-Lock auf der N4-Zeile, aenderte nicht_fuer und commitete erst, nachdem 04
-- nachweislich auf den Lock wartete. 04 hat den Lock danach erworben.
--
-- nicht_fuer steht bewusst NICHT in der Spaltenliste des Triggers
-- products_set_updated_at. Die konkurrierende Aenderung veraendert updated_at
-- also nicht — 04 kann sie nur ueber die erneute Vorwert-Pruefung nach dem
-- Lock bemerken, nicht ueber einen Zeitstempelvergleich.
--
-- Beweist:
--   1. die konkurrierende nicht_fuer-Aenderung steht unveraendert in products,
--   2. keine Zeile traegt den Zieltext — 04 hat nichts geschrieben,
--   3. das Backup aus 02 ist unangetastet.
-- ============================================================================

do $$
declare
  konkurrenz_treffer integer;
  ziel_treffer integer;
  backup_rows integer;
begin
  select count(*) into konkurrenz_treffer
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and nicht_fuer is not distinct from
      'CBB-TEST: konkurrierende Aenderung an nicht_fuer';
  if konkurrenz_treffer <> 1 then
    raise exception 'Konkurrenztest 04: nicht_fuer traegt die konkurrierende Aenderung %/1 mal — 04 hat fremde Daten ueberschrieben.',
      konkurrenz_treffer;
  end if;

  select count(*) into ziel_treffer
  from public.products
  where tagline is not distinct from
      '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm'
     or editorial_note is not distinct from
      'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.';
  if ziel_treffer <> 0 then
    raise exception 'Konkurrenztest 04: % Zeilen tragen den Zieltext.', ziel_treffer;
  end if;

  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'Konkurrenztest 04: Backup hat %/1 Zeilen.', backup_rows;
  end if;

  raise notice 'OK: konkurrierende nicht_fuer-Aenderung erhalten, kein Zieltext geschrieben.';
end $$;
