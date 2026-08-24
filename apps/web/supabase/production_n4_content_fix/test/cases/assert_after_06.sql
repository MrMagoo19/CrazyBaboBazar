-- ============================================================================
-- ASSERT — Zustand nach 06_restore_n4_content.sql
-- ============================================================================
-- Beweist den vollstaendigen Round-Trip: ALLE 376 Zeilen sind wieder Bit fuer
-- Bit identisch zur Baseline — inklusive des historischen updated_at der
-- N4-Zeile. Das Backup bleibt als Audit-Artefakt bestehen.
-- ============================================================================

do $$
declare
  produkte bigint;
  geprueft integer;
  drift integer;
  n4_lastmod_exakt integer;
  backup_rows integer;
  ziel_texte_weg integer;
begin
  select count(*) into produkte from public.products;
  if produkte <> 376 then
    raise exception 'nach 06: % Produkte (erwartet 376).', produkte;
  end if;

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
  into geprueft, drift
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id;
  if geprueft <> 376 or drift <> 0 then
    raise exception 'nach 06: % Zeilen geprueft (erwartet 376), davon % gedriftet (erwartet 0).',
      geprueft, drift;
  end if;

  -- Der historische Zeitstempel muss EXAKT stimmen, nicht nur "aelter".
  select count(*) into n4_lastmod_exakt
  from public.products p
  join cbb_test_n4_baseline.products_before b on b.id = p.id
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and p.updated_at = b.updated_at;
  if n4_lastmod_exakt <> 1 then
    raise exception 'nach 06: historisches N4-updated_at wurde nicht exakt zurueckgespielt.';
  end if;

  -- Kein Rest des Zieltexts darf uebrig sein.
  select count(*) into ziel_texte_weg
  from public.products
  where tagline is not distinct from
      '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm'
     or editorial_note is not distinct from
      'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.';
  if ziel_texte_weg <> 0 then
    raise exception 'nach 06: % Zeilen tragen noch Zieltext.', ziel_texte_weg;
  end if;

  -- Das Backup bleibt als Audit-Artefakt bestehen.
  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is null then
    raise exception 'nach 06: das Backup wurde geloescht.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'nach 06: Backup hat %/1 Zeilen.', backup_rows;
  end if;

  raise notice 'nach 06 OK: alle 376 Zeilen identisch zur Baseline, historisches updated_at exakt, Backup bleibt bestehen.';
end $$;
