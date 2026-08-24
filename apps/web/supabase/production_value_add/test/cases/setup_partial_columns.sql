-- Teilzustand: 3 der 8 Spalten existieren schon. 02 muss fail-closed abbrechen
-- statt die fehlenden fuenf nachzuruesten.
alter table public.products
  add column fuer_wen   text,
  add column nicht_fuer text,
  add column key_fact   text;
