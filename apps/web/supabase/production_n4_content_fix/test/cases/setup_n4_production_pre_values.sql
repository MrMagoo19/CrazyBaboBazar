-- ============================================================================
-- SETUP — N4-Vorwerte exakt auf den bekannten Production-Stand setzen
-- ============================================================================
-- Die Fixture aus production_value_add/test/fixture traegt fuer die N4-Zeile
-- bewusst erfundene Testtexte ("Pflanzenmilch in 20 Minuten."). Fuer dieses
-- Paket muss die Zeile aber exakt den Stand haben, den 01/02/04 als Vorzustand
-- erwarten. Genau das stellt diese Datei her.
--
--   tagline     -> supabase/import_products_batch13.sql
--   description -> supabase/expand_descriptions_batch6.sql
--
-- Die fuenf Value-Add-/Editorial-Felder kommen bereits aus dem unveraenderten
-- Original production_value_add/04_backfill_value_add.sql und werden hier
-- NICHT angefasst.
--
-- updated_at wird bewusst nicht mitgeschrieben: der echte Trigger
-- products_set_updated_at soll ihn setzen, so wie er es in Production auch
-- taete.
-- ============================================================================

do $$
declare
  affected_rows integer;
begin
  update public.products set
    tagline = '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten',
    description = 'N4 Nussmilchbereiter für frische Pflanzenmilch. Hafer-, Mandel-, Soja-, Reis- oder Cashew-Milch in 15 Minuten. Mixt, kocht, filtert automatisch. Für Menschen, die Bio-Milch-Preise satt haben und ihre Zutaten selbst kontrollieren wollen. Amortisiert sich nach 2 Monaten täglichem Frühstück.'
  where slug = 'n4-nussmilchbereiter-pflanzenmilch';

  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'Setup: UPDATE traf %/1 Zeilen.', affected_rows;
  end if;
end $$;
