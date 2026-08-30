-- ============================================================================
-- SETUP — updated_at IS NULL in Zielzustand UND Backup
-- ============================================================================
-- Laeuft nach 04. Der fachliche Zielzustand bleibt erhalten; nur der
-- Zeitstempel eines lastmod-Zielprodukts wird in Quelle und Backup auf NULL
-- gesetzt. Damit sind zwei fruehe No-Op-Pfade unter Belastung:
--   * 04 darf den fachlichen Zielzustand nicht ohne lastmod-Beweis akzeptieren.
--   * 06 darf Quelle und Backup nicht allein wegen ihrer Gleichheit akzeptieren.
-- ============================================================================

update public.products
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

update cbb_private_backup.quality_fixes_20260830_products_v1
set updated_at = null
where slug = 'divoom-pixoo-led-panel';

do $$
declare
  quelle integer;
  backup integer;
begin
  select count(*) into quelle
  from public.products
  where slug = 'divoom-pixoo-led-panel'
    and price_cents = 4249
    and updated_at is null;

  select count(*) into backup
  from cbb_private_backup.quality_fixes_20260830_products_v1
  where slug = 'divoom-pixoo-led-panel'
    and price_cents is null
    and updated_at is null;

  if quelle <> 1 or backup <> 1 then
    raise exception 'Setup fehlgeschlagen: Zielquelle %/1, Vorzustandsbackup %/1 mit updated_at IS NULL.',
      quelle, backup;
  end if;
end $$;
