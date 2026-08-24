-- Nach einem fail-closed Abbruch von 04 darf KEINE Zeile den Zieltext tragen —
-- die Transaktion muss vollstaendig zurueckgerollt sein.
do $$
declare
  treffer integer;
  produkte bigint;
begin
  select count(*) into produkte from public.products;
  if produkte <> 376 then
    raise exception 'nach Abbruch: % Produkte (erwartet 376).', produkte;
  end if;

  select count(*) into treffer
  from public.products
  where tagline is not distinct from
      '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm'
     or key_fact is not distinct from
      '1,5-Liter-Behälter, 800-W-Motor und Programme für Getreide, Nüsse und Bohnen; das Reinigungsprogramm unterstützt, ersetzt die manuelle Nachreinigung aber nicht immer.'
     or editorial_note is not distinct from
      'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.';
  if treffer <> 0 then
    raise exception 'nach Abbruch: % Zeilen tragen bereits Zieltext.', treffer;
  end if;

  raise notice 'OK: kein Zieltext in der Datenbank, Abbruch war vollstaendig.';
end $$;
