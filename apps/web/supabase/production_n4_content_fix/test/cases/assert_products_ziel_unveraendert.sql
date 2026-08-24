-- ============================================================================
-- ASSERT — nach fail-closed Abbruch von 06 bei manipuliertem Backup
-- ============================================================================
-- products muss UNVERAENDERT den korrigierten Stand aus 04 tragen. Das Backup
-- ist in diesem Fall bewusst manipuliert und wird deshalb nicht gegen die
-- Baseline geprueft — wohl aber daraufhin, dass die Manipulation noch drinsteht
-- und 06 sie also weder geschrieben noch stillschweigend "repariert" hat.
--
-- Bewusst getrennt von assert_after_04.sql: dessen Pruefung 7 verlangt ein
-- unversehrtes Backup und wuerde hier zu Recht scheitern.
-- ============================================================================

do $$
declare
  n4_ziel integer;
  geaenderte_zeilen integer;
  fremde_zeilen integer;
  fremde_drift integer;
  manipulation integer;
  fremdtext integer;
begin
  -- 1 — N4 traegt weiterhin exakt die sieben Zieltexte aus 04
  select count(*) into n4_ziel
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and tagline is not distinct from
      '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm'
    and description is not distinct from
      'Der Ariceck N4 ist ein 1,5-Liter-Pflanzenmilchbereiter mit Programmen für Getreide, Nüsse und Bohnen. Das Gerät mixt und erhitzt die Zutaten; ein Reinigungsprogramm unterstützt anschließend beim Saubermachen. Für Menschen, die Hafer-, Mandel- oder Sojamilch selbst zubereiten und die Zutaten kontrollieren wollen.'
    and nicht_fuer is not distinct from
      'Wer nur selten Pflanzenmilch selbst zubereitet oder nach dem Programm keinerlei manuelle Nachreinigung erwartet.'
    and key_fact is not distinct from
      '1,5-Liter-Behälter, 800-W-Motor und Programme für Getreide, Nüsse und Bohnen; das Reinigungsprogramm unterstützt, ersetzt die manuelle Nachreinigung aber nicht immer.'
    and pros is not distinct from array[
      'Programme für Getreide, Nüsse und Bohnen',
      '1,5 Liter Fassungsvermögen',
      '800-W-Motor',
      'Reinigungsprogramm unterstützt beim Saubermachen'
    ]::text[]
    and cons is not distinct from array[
      'Die Laufzeit hängt vom gewählten Programm ab',
      'Manuelle Nachreinigung kann weiterhin nötig sein'
    ]::text[]
    and editorial_note is not distinct from
      'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.';
  if n4_ziel <> 1 then
    raise exception 'nach 06-Abbruch: N4 traegt nicht mehr exakt die Zieltexte aus 04 (%/1).',
      n4_ziel;
  end if;

  -- 2 — kein Zeichen des manipulierten Backups in products
  select count(*) into fremdtext
  from public.products
  where tagline is not distinct from 'CBB-TEST: manipuliertes Backup';
  if fremdtext <> 0 then
    raise exception 'nach 06-Abbruch: % Zeilen tragen den manipulierten Backup-Text — 06 hat geschrieben.',
      fremdtext;
  end if;

  -- 3 — genau eine Zeile weicht von der Baseline ab, die 375 anderen gar nicht
  select count(*) into geaenderte_zeilen
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.tagline is distinct from b.tagline
     or p.description is distinct from b.description
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind
     or p.is_published is distinct from b.is_published
     or p.created_at is distinct from b.created_at;
  if geaenderte_zeilen <> 1 then
    raise exception 'nach 06-Abbruch: % Zeilen weichen von der Baseline ab (erwartet 1).',
      geaenderte_zeilen;
  end if;

  select count(*), count(*) filter (
    where p.updated_at is distinct from b.updated_at
       or p.tagline is distinct from b.tagline
       or p.description is distinct from b.description
       or p.nicht_fuer is distinct from b.nicht_fuer
       or p.key_fact is distinct from b.key_fact
       or p.pros is distinct from b.pros
       or p.cons is distinct from b.cons
       or p.editorial_note is distinct from b.editorial_note
  )
  into fremde_zeilen, fremde_drift
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.slug <> 'n4-nussmilchbereiter-pflanzenmilch';
  if fremde_zeilen <> 375 or fremde_drift <> 0 then
    raise exception 'nach 06-Abbruch: % Nichtzielzeilen geprueft (erwartet 375), davon % gedriftet (erwartet 0).',
      fremde_zeilen, fremde_drift;
  end if;

  -- 4 — die Manipulation steht unveraendert im Backup
  select count(*) into manipulation
  from cbb_private_backup.n4_content_pre_fix_v1
  where tagline is not distinct from 'CBB-TEST: manipuliertes Backup';
  if manipulation <> 1 then
    raise exception 'nach 06-Abbruch: manipulierter Backup-Wert %/1 mal vorhanden — 06 hat am Backup gearbeitet.',
      manipulation;
  end if;

  raise notice 'nach 06-Abbruch OK: products unveraendert im 04-Stand, manipuliertes Backup nicht zurueckgeschrieben.';
end $$;
