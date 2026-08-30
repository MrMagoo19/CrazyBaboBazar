-- ============================================================================
-- SETUP — Triggervertrag verletzt: der Guard ist um ein ODER erweitert
-- ============================================================================
-- Dieser Rumpf haelt ALLE bisherigen Formvorgaben ein:
--   * der Guard steht wortwoertlich da,
--   * die Reihenfolge Guard -> THEN -> Zuweisung -> END IF stimmt,
--   * es gibt genau EINE updated_at-Zuweisung,
--   * es gibt genau EIN END IF,
--   * shop_sub_category kommt nicht vor,
--   * Triggername und Triggerdefinition sind unveraendert.
--
-- Trotzdem ist der Vertrag gebrochen. Die Bedingung lautet jetzt
--   "der Aufrufer hat updated_at nicht selbst geschrieben  ODER  der Name hat
--    sich geaendert"
-- statt "... UND ...". Schreibt 04 bei einer der sechs sichtbaren
-- Produktseiten updated_at ausdruecklich mit und aendert dabei den Namen, ist
-- der zweite Zweig wahr — der Trigger ueberschreibt den bewusst gesetzten
-- Zeitstempel mit now(). Genau die Zusage aus Abschnitt 2.3 des Runbooks faellt
-- damit weg, ohne dass eine der bisher gemessenen Groessen anschlaegt.
--
-- WARUM DER FALL NOETIG IST: die geordnete Regex in 01 liess zwischen dem
-- updated_at-Guard und seinem THEN ".*" zu — also beliebigen Text und damit
-- auch dieses OR. Seit der Haertung wird derselbe Abschnitt eigens
-- ausgeschnitten und darf das WORT "or" nicht enthalten. Die Wortgrenze ist
-- dabei Pflicht: der reale Tupelguard enthaelt "or" als blosse Zeichenfolge
-- mehrfach (editorial_note, shop_main_category, category_id) und muss weiterhin
-- PASS liefern.
--
-- Die Gegenproben unten belegen, dass der Fall ALLEIN an der ODER-Erweiterung
-- scheitert und nicht an einer zweiten Abweichung.
-- ============================================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  if new.updated_at is not distinct from old.updated_at
     or (new.name is distinct from old.name)
  then
    new.updated_at := now();
  end if;

  return new;
end
$$;

-- 1. Genau eine Zuweisung und genau ein END IF — die beiden Zaehlungen sind
-- also NICHT der Grund fuer das erwartete FAIL.
do $$
declare
  zuweisungen    integer;
  end_if_bloecke integer;
begin
  select count(*) into zuweisungen
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'new\.updated_at[[:space:]]*(:=|=)',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if zuweisungen <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 updated_at-Zuweisungen im Rumpf der aktiven Triggerfunktion.', zuweisungen;
  end if;

  select count(*) into end_if_bloecke
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  cross join lateral pg_catalog.regexp_matches(
    regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g'),
    'end[[:space:]]+if;',
    'gi') m
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';
  if end_if_bloecke <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 END IF im Rumpf der aktiven Triggerfunktion.', end_if_bloecke;
  end if;
end $$;

-- 2. Die uebrigen vier Vertragsgroessen sind unveraendert in Ordnung: genau ein
-- aktiver BEFORE UPDATE FOR EACH ROW Trigger mit korrektem Namen, korrekter
-- Funktion, ohne WHEN-Klausel und mit der erwarteten Triggerdefinition; kein
-- shop_sub_category im Rumpf; keine fremde Triggerfunktion, die updated_at
-- anfasst. Auch sie sind damit NICHT der Grund fuer das erwartete FAIL.
do $$
declare
  aktive         integer;
  vertragskonform integer;
  mit_sub_cat    integer;
  fremde         integer;
begin
  select count(*) into aktive
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgenabled in ('O', 'A')
    and (t.tgtype & 1) <> 0
    and (t.tgtype & 2) <> 0
    and (t.tgtype & 16) <> 0;
  if aktive <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 aktive BEFORE UPDATE FOR EACH ROW Trigger auf public.products.', aktive;
  end if;

  select count(*) into vertragskonform
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgenabled in ('O', 'A')
    and t.tgqual is null
    and t.tgname = 'products_set_updated_at'
    and (p.pronamespace::regnamespace)::text || '.' || p.proname::text
        = 'public.products_touch_updated_at'
    and pg_catalog.pg_get_triggerdef(t.oid)
        ~ ('BEFORE UPDATE ON (public\.)?products '
           || 'FOR EACH ROW EXECUTE FUNCTION '
           || '(public\.)?products_touch_updated_at\(\)$');
  if vertragskonform <> 1 then
    raise exception 'Setup fehlgeschlagen: %/1 vertragskonforme Triggerdefinition.', vertragskonform;
  end if;

  select count(*) into mit_sub_cat
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at'
    and pg_catalog.pg_get_functiondef(p.oid) ~* 'shop_sub_category';
  if mit_sub_cat <> 0 then
    raise exception 'Setup fehlgeschlagen: shop_sub_category kommt im Rumpf vor — der Fall haette zwei Gruende zu scheitern.';
  end if;

  select count(*) into fremde
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgenabled in ('O', 'A')
    and t.tgname <> 'products_set_updated_at'
    and pg_catalog.pg_get_functiondef(p.oid) ~* 'updated_at';
  if fremde <> 0 then
    raise exception 'Setup fehlgeschlagen: % fremde Triggerfunktion(en) fassen updated_at an.', fremde;
  end if;
end $$;

-- 3. Der Kern des Falls: die frueher allein massgebliche geordnete Regex mit
-- ".*" zwischen Guard und THEN passt auf diesen Rumpf weiterhin — der Fall
-- waere ohne die Haertung faelschlich als PASS durchgegangen. Und der eigens
-- ausgeschnittene Abschnitt zwischen Guard und THEN enthaelt das WORT "or".
do $$
declare
  bereinigt        text;
  zusatzbedingung  text;
begin
  select regexp_replace(pg_catalog.pg_get_functiondef(p.oid), '\s+', ' ', 'g')
    into bereinigt
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_proc p on p.oid = t.tgfoid
  where t.tgrelid = 'public.products'::regclass
    and t.tgisinternal is false
    and t.tgname = 'products_set_updated_at';

  if bereinigt is null then
    raise exception 'Setup fehlgeschlagen: keine aktive Triggerfunktion products_set_updated_at gefunden.';
  end if;

  if bereinigt !~* ('if new\.updated_at is not distinct from old\.updated_at'
                    || '.*[[:space:]]then[[:space:]]+new\.updated_at[[:space:]]*(:=|=)'
                    || '[[:space:]]*now\(\);[[:space:]]*end[[:space:]]+if;') then
    raise exception 'Setup fehlgeschlagen: die geordnete Regex passt nicht — der Fall wuerde schon an der Reihenfolge scheitern statt am OR.';
  end if;

  zusatzbedingung := substring(
    lower(bereinigt),
    'if new\.updated_at is not distinct from old\.updated_at'
    || '(.*)[[:space:]]then[[:space:]]+new\.updated_at'
    || '[[:space:]]*(?::=|=)[[:space:]]*now\(\);');

  if zusatzbedingung is null then
    raise exception 'Setup fehlgeschlagen: der Abschnitt zwischen Guard und THEN liess sich nicht ausschneiden.';
  end if;
  if zusatzbedingung !~ '\yor\y' then
    raise exception 'Setup fehlgeschlagen: der Abschnitt zwischen Guard und THEN enthaelt kein ODER: <%>', zusatzbedingung;
  end if;
end $$;
