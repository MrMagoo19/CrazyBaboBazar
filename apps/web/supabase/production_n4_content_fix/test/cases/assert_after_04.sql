-- ============================================================================
-- ASSERT — Zustand nach 04_correct_n4_content.sql
-- ============================================================================
-- Beweist:
--   1. 376 Produkte, N4 genau einmal und weiterhin published
--   2. N4 traegt exakt die sieben Zieltexte
--   3. GENAU EINE Zeile weicht von der Baseline ab
--   4. die anderen 375 Zeilen sind Bit fuer Bit unveraendert, updated_at
--      eingeschlossen
--   5. N4 hat ein NEUERES updated_at als vorher
--   6. die vier nicht angefassten Value-Add-Felder der N4-Zeile sind identisch
--      zur Baseline und zur Audit-Payload
--   7. das private Backup existiert weiterhin mit genau einer Zeile und
--      enthaelt weiterhin den Vorzustand
-- ============================================================================

do $$
declare
  produkte bigint;
  n4_published integer;
  n4_ziel integer;
  geaenderte_zeilen integer;
  fremde_drift integer;
  fremde_zeilen integer;
  n4_lastmod_neu integer;
  n4_unveraendert integer;
  n4_payload_felder integer;
  andere_payload_drift integer;
  backup_rows integer;
  backup_vorzustand integer;
begin
  select count(*) into produkte from public.products;
  if produkte <> 376 then
    raise exception 'nach 04: % Produkte (erwartet 376).', produkte;
  end if;

  select count(*) into n4_published
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch' and is_published is true;
  if n4_published <> 1 then
    raise exception 'nach 04: %/1 N4-Zeile published.', n4_published;
  end if;

  -- 2 — exakte Zieltexte
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
    raise exception 'nach 04: N4 traegt nicht exakt die Zieltexte (%/1 Treffer).',
      n4_ziel;
  end if;

  -- 3 — genau eine Zeile weicht ab
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
    raise exception 'nach 04: % Zeilen weichen von der Baseline ab (erwartet 1).',
      geaenderte_zeilen;
  end if;

  -- 4 — die 375 Nichtzielzeilen sind unveraendert
  select count(*), count(*) filter (
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
       or p.created_at is distinct from b.created_at
  )
  into fremde_zeilen, fremde_drift
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.slug <> 'n4-nussmilchbereiter-pflanzenmilch';
  if fremde_zeilen <> 375 or fremde_drift <> 0 then
    raise exception 'nach 04: % Nichtzielzeilen geprueft (erwartet 375), davon % gedriftet (erwartet 0).',
      fremde_zeilen, fremde_drift;
  end if;

  -- 5 — neues lastmod genau fuer die N4-Seite
  select count(*) into n4_lastmod_neu
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and p.updated_at > b.updated_at;
  if n4_lastmod_neu <> 1 then
    raise exception 'nach 04: N4-updated_at wurde nicht neu gesetzt.';
  end if;

  -- 6 — die vier nicht angefassten Value-Add-Felder
  select count(*) into n4_unveraendert
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and p.fuer_wen is not distinct from b.fuer_wen
    and p.alternative_slug is not distinct from b.alternative_slug
    and p.alternative_reason is not distinct from b.alternative_reason
    and p.alternative_kind is not distinct from b.alternative_kind;
  if n4_unveraendert <> 1 then
    raise exception 'nach 04: unveraenderte N4-Felder weichen von der Baseline ab.';
  end if;

  select count(*) into n4_payload_felder
  from public.products p
  join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and p.fuer_wen is not distinct from v.fuer_wen
    and p.alternative_slug is not distinct from v.alternative_slug
    and p.alternative_reason is not distinct from v.alternative_reason
    and p.alternative_kind is not distinct from v.alternative_kind;
  if n4_payload_felder <> 1 then
    raise exception 'nach 04: unveraenderte N4-Felder weichen von der Audit-Payload ab.';
  end if;

  select count(*) into andere_payload_drift
  from cbb_private_backup.value_add_payload_v1 v
  left join public.products p on p.slug = v.slug
  where v.slug <> 'n4-nussmilchbereiter-pflanzenmilch'
    and (
      p.slug is null
      or p.fuer_wen is distinct from v.fuer_wen
      or p.nicht_fuer is distinct from v.nicht_fuer
      or p.key_fact is distinct from v.key_fact
      or p.pros is distinct from v.pros
      or p.cons is distinct from v.cons
      or p.alternative_slug is distinct from v.alternative_slug
      or p.alternative_reason is distinct from v.alternative_reason
      or p.alternative_kind is distinct from v.alternative_kind
      or p.editorial_note is distinct from v.editorial_note
    );
  if andere_payload_drift <> 0 then
    raise exception 'nach 04: % der neun uebrigen Pilotzeilen gedriftet.',
      andere_payload_drift;
  end if;

  -- 7 — Backup unangetastet
  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'nach 04: Backup hat %/1 Zeilen.', backup_rows;
  end if;

  select count(*) into backup_vorzustand
  from cbb_private_backup.n4_content_pre_fix_v1 x
  join cbb_test_n4_baseline.products_before b on b.id = x.id
  where x.slug = b.slug
    and x.tagline is not distinct from b.tagline
    and x.description is not distinct from b.description
    and x.nicht_fuer is not distinct from b.nicht_fuer
    and x.key_fact is not distinct from b.key_fact
    and x.pros is not distinct from b.pros
    and x.cons is not distinct from b.cons
    and x.editorial_note is not distinct from b.editorial_note
    and x.updated_at is not distinct from b.updated_at;
  if backup_vorzustand <> 1 then
    raise exception 'nach 04: Backup entspricht nicht mehr der Baseline.';
  end if;

  raise notice 'nach 04 OK: 1 geaenderte Zeile, 375 Nichtzielzeilen ohne Drift, neues lastmod nur fuer N4, Payload und Backup unangetastet.';
end $$;
