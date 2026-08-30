-- ============================================================================
-- ASSERT — Zustand nach 06_restore_quality_fixes.sql
-- ============================================================================
-- Der Round-Trip muss EXAKT sein: jede Zeile von public.products und
-- public.lists traegt wieder ihren Baseline-Fingerabdruck, updated_at
-- eingeschlossen. Ein Restore, der zwar den Text zurueckspielt, aber ein neues
-- updated_at hinterlaesst, faellt hier durch.
--
-- Zusaetzlich: das Backup existiert weiter (06 loescht es nicht) und ist
-- unveraendert.
-- ============================================================================

do $$
declare
  n integer;
begin
  select count(*) into n
  from cbb_test.baseline_products b
  full join (
    select p.id, md5(to_jsonb(p)::text) as fingerabdruck from public.products p
  ) p on p.id = b.id
  where b.id is null or p.id is null
     or p.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 0 then
    raise exception 'Nach 06: % Produktzeilen weichen von der Baseline ab.', n;
  end if;

  select count(*) into n
  from cbb_test.baseline_lists b
  full join (
    select l.id, md5(to_jsonb(l)::text) as fingerabdruck from public.lists l
  ) l on l.id = b.id
  where b.id is null or l.id is null
     or l.fingerabdruck is distinct from b.fingerabdruck;
  if n <> 0 then
    raise exception 'Nach 06: % Listenzeilen weichen von der Baseline ab.', n;
  end if;

  -- Das Backup ist noch da und deckt sich wieder vollstaendig mit den Quellen.
  select count(*) into n
  from cbb_private_backup.quality_fixes_20260830_products_v1 b
  join public.products p on p.id = b.id and p.slug = b.slug
  where to_jsonb(p) is not distinct from to_jsonb(b);
  if n <> 6 then
    raise exception 'Nach 06: nur %/6 Produktzeilen exakt wie im Backup.', n;
  end if;

  select count(*) into n
  from cbb_private_backup.quality_fixes_20260830_lists_v1 b
  join public.lists l on l.id = b.id and l.slug = b.slug
  where to_jsonb(l) is not distinct from to_jsonb(b);
  if n <> 3 then
    raise exception 'Nach 06: nur %/3 Listenzeilen exakt wie im Backup.', n;
  end if;

  raise notice 'Round-Trip nach 06 exakt bestaetigt.';
end $$;
