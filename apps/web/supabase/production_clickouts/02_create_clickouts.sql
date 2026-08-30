-- ============================================================================
-- PRODUCTION KLICK-OUT-MESSUNG — 02 ANLAGE (SCHREIBEND, DDL)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene, ausdrueckliche Benutzerfreigabe und sichtbare
-- Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Erst nach einem FAIL-freien 01_preflight_read_only.sql ausfuehren.
--
-- WAS DIESE DATEI ANLEGT:
--   public.click_outs                              — Zieltabelle des Inserts
--   cbb_private_analytics                          — privates Auswertungsschema
--   cbb_private_analytics.click_outs_daily         — datensparsame Auswertung
--   cbb_private_analytics.purge_click_outs(int)    — Loeschfunktion (Retention)
--
-- WAS SIE NICHT TUT: sie fasst keine bestehende Tabelle an, veraendert keine
-- Produktdaten und keines der Value-Add-Artefakte v1/v2. Sie legt ausschliesslich
-- neue Objekte an.
--
-- WARUM DIE TABELLE IN `public` LIEGT — und warum das trotzdem sicher ist:
--   Die Anwendung schreibt ueber PostgREST (`/rest/v1/click_outs`). PostgREST
--   sieht nur die konfigurierten Schemata; auf Supabase ist das per Default
--   `public`. Eine Tabelle in einem privaten Schema waere ueber diesen Weg gar
--   nicht erreichbar und haette eine Aenderung der Projektkonfiguration
--   erzwungen — eine zusaetzliche, schwerer auditierbare externe Aktion.
--   Die Absicherung passiert deshalb ueber Rechte statt ueber Verstecken:
--     * RLS ist an und es gibt KEINE EINZIGE Policy. Fuer anon und
--       authenticated ist die Tabelle damit auch dann leer und unschreibbar,
--       wenn ihnen jemals wieder ein Grant zugewiesen wuerde.
--     * Alle Rechte von PUBLIC, anon und authenticated werden ausdruecklich
--       entzogen. Supabase vergibt sie bei neuen Tabellen in `public` sonst per
--       Default-Privileg automatisch.
--     * Nur service_role behaelt INSERT. service_role ist BYPASSRLS und ist
--       genau die Rolle, unter der der Route-Handler schreibt.
--     * Dasselbe gilt fuer die Identity-Sequenz public.click_outs_id_seq: sie
--       wird ebenfalls vollstaendig entzogen, service_role bekommt nur USAGE.
--       Ohne das gaebe `select last_value` den Klick-Zaehler preis und `setval`
--       liesse die Nummernfolge verbiegen — an der dichten Tabelle vorbei.
--   Die AUSWERTUNG liegt bewusst NICHT in `public`, sondern im privaten Schema
--   cbb_private_analytics — sie ist damit ueber PostgREST grundsaetzlich nicht
--   erreichbar.
--
-- WIEDERHOLUNGSVERHALTEN: existiert public.click_outs bereits, bricht die Datei
-- fail-closed ab. Sie ueberschreibt und ersetzt niemals.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$
declare
  product_rows bigint;
  app_roles integer;
  service_roles integer;
begin
  -- ---------------------------------------------------------------------
  -- Umgebung: Production-Fingerprint, keine Pilot-Artefakte
  -- ---------------------------------------------------------------------
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'Klick-out-Anlage abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'Klick-out-Anlage abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'Klick-out-Anlage abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  -- ---------------------------------------------------------------------
  -- Rollen. Ohne sie liefe das REVOKE weiter unten ins Leere bzw. scheiterte
  -- mit "role does not exist" — beides waere ein stiller Sicherheitsverlust.
  -- ---------------------------------------------------------------------
  select count(*) into app_roles from pg_roles where rolname in ('anon', 'authenticated');
  if app_roles <> 2 then
    raise exception 'Klick-out-Anlage abgebrochen: %/2 App-Rollen vorhanden.', app_roles;
  end if;
  select count(*) into service_roles from pg_roles where rolname = 'service_role';
  if service_roles <> 1 then
    raise exception 'Klick-out-Anlage abgebrochen: service_role fehlt.';
  end if;

  -- ---------------------------------------------------------------------
  -- Nichts ueberschreiben.
  -- ---------------------------------------------------------------------
  if to_regclass('public.click_outs') is not null then
    raise exception 'Klick-out-Anlage abgebrochen: public.click_outs existiert bereits.';
  end if;
  -- Der Name der Identity-Sequenz ist nicht frei waehlbar: PostgreSQL leitet
  -- ihn aus Tabelle und Spalte ab. Existiert public.click_outs_id_seq schon
  -- (Rest eines frueheren Laufs), bekaeme die neue Sequenz den Namen
  -- click_outs_id_seq1 — und der Rechte-Entzug weiter unten traefe die falsche
  -- Sequenz, ohne dass irgendetwas scheitern wuerde. Genau dieser stille
  -- Fehlschlag wird hier fail-closed ausgeschlossen.
  if to_regclass('public.click_outs_id_seq') is not null then
    raise exception 'Klick-out-Anlage abgebrochen: public.click_outs_id_seq existiert bereits.';
  end if;
  if to_regclass('cbb_private_analytics.click_outs_daily') is not null then
    raise exception 'Klick-out-Anlage abgebrochen: Auswertungs-View existiert bereits.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Zieltabelle
-- ---------------------------------------------------------------------------
-- Die CHECK-Constraints sind die datenbankseitige Kopie der Regeln aus
-- apps/web/lib/affiliate.ts. Sie sind kein Ersatz fuer die Pruefung in der
-- Anwendung, sondern die zweite Verteidigungslinie: selbst wenn der
-- Route-Handler eines Tages nachlaesst, kann kein Querystring, kein fremder
-- Host und kein frei gewaehlter Identifikator in die Tabelle gelangen.
create table public.click_outs (
  id                   bigint generated always as identity primary key,
  product_slug         text        not null,
  merchant             text        not null,
  source_path          text,
  device_class         text        not null,
  -- uuid statt text: eine frei gewaehlte Kennung (E-Mail, Nutzer-ID, Cookie-Wert)
  -- laesst sich hier gar nicht erst speichern.
  consented_session_id uuid        not null,
  created_at           timestamptz not null default now(),

  constraint click_outs_product_slug_format check (
    product_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(product_slug) <= 120
  ),
  constraint click_outs_merchant_allowed check (
    merchant in ('amazon')
  ),
  constraint click_outs_device_class_allowed check (
    device_class in ('mobile', 'tablet', 'desktop', 'unknown')
  ),
  -- Nur ein interner Pfad: beginnt mit genau einem Slash, hoechstens 128
  -- Zeichen, ohne Query und ohne Fragment. Damit ist ein Suchbegriff oder eine
  -- fremde Domain in dieser Spalte strukturell ausgeschlossen.
  constraint click_outs_source_path_format check (
    source_path is null or (
      source_path ~ '^/[^/]' or source_path = '/'
    )
  ),
  constraint click_outs_source_path_clean check (
    source_path is null or (
      length(source_path) <= 128
      and strpos(source_path, '?') = 0
      and strpos(source_path, '#') = 0
      and source_path !~ '[[:cntrl:]]'
    )
  )
  -- BEWUSST KEIN CHECK auf created_at gegen now(): ein CHECK mit einer nicht
  -- immutablen Funktion ist ein Restore-Risiko — beim Wiedereinspielen eines
  -- Dumps wird jede Zeile erneut geprueft, und alte Zeilen koennen dann
  -- scheitern. Der Schutz kommt statt dessen aus dem Zugriffsmodell: nur
  -- service_role darf INSERT, und der Route-Handler sendet die Spalte gar
  -- nicht mit, sodass immer der Default now() greift.
);

comment on table public.click_outs is
  'Consent-gebundene Klick-out-Zaehlung. Enthaelt bewusst keine IP-Adresse, keinen IP-Hashwert, keine vollstaendige Browserkennung, keine vollstaendige Herkunfts-URL und keine Adressparameter. Schreibzugriff ausschliesslich ueber service_role. Retention 12 Monate, siehe 04_retention.sql.';
comment on column public.click_outs.source_path is
  'Nur der interne Pfad der Herkunftsseite, ohne Query und Fragment. NULL bedeutet: keine verwertbare Herkunft, es wurde nichts geraten.';
comment on column public.click_outs.consented_session_id is
  'Zufaellige UUID aus dem sessionStorage des Browsers. Entsteht erst nach ausdruecklicher Einwilligung, endet mit dem Tab, ist kein Cookie und kein geraetedauerhafter Identifikator.';
comment on column public.click_outs.device_class is
  'Grobe Geraeteklasse aus vier Werten. Abgeleitet aus der Browserkennung, die selbst nicht gespeichert wird.';

-- ---------------------------------------------------------------------------
-- Indizes
-- ---------------------------------------------------------------------------
-- Bewusst NUR diese zwei. Es gibt ausdruecklich KEINEN Index auf
-- consented_session_id: ein solcher Index waere ausschliesslich dafuer
-- nuetzlich, die Klickfolge einer einzelnen Sitzung schnell zu rekonstruieren
-- — also fuer genau die Profilbildung, die dieses Changeset nicht will.
create index click_outs_created_at_idx
  on public.click_outs (created_at desc);
create index click_outs_product_created_idx
  on public.click_outs (product_slug, created_at desc);

-- ---------------------------------------------------------------------------
-- Absicherung
-- ---------------------------------------------------------------------------
alter table public.click_outs enable row level security;

-- BEWUSST OHNE `force row level security`: FORCE unterwirft auch den
-- Tabelleneigentuemer der RLS. Da es hier absichtlich KEINE Policy gibt, wuerde
-- FORCE dem Eigentuemer jeden Zugriff nehmen — die Retention-Funktion aus
-- 04_retention.sql koennte dann nichts mehr loeschen, und die read-only
-- Nachpruefung 03 saehe eine kuenstlich leere Tabelle. Der Schutz gegen die
-- App-Rollen kommt aus RLS ohne Policy PLUS dem vollstaendigen Rechte-Entzug
-- weiter unten, nicht aus FORCE.

-- Keine einzige Policy. Das ist Absicht und wird von 03 hart geprueft.

revoke all on public.click_outs from public, anon, authenticated;
-- Supabase vergibt bei neuen Tabellen in `public` per Default-Privileg alle
-- Rechte an anon/authenticated/service_role. Der Entzug oben nimmt sie den
-- beiden App-Rollen wieder; hier bekommt service_role genau das eine Recht
-- zurueck, das der Route-Handler braucht. Kein SELECT, kein UPDATE, kein
-- DELETE — geloescht wird ausschliesslich ueber die Retention-Funktion.
revoke all on public.click_outs from service_role;
grant insert on public.click_outs to service_role;

-- ---------------------------------------------------------------------------
-- Die Identity-Sequenz gehoert mit abgesichert
-- ---------------------------------------------------------------------------
-- `bigint generated always as identity` legt public.click_outs_id_seq mit an.
-- Supabase vergibt auf neue Sequenzen in `public` per Default-Privileg
-- ebenfalls alle Rechte an anon, authenticated und service_role. Das ist hier
-- kein Schoenheitsfehler, sondern ein echtes Leck neben der Tabelle:
--   * SELECT auf der Sequenz gibt `last_value` preis — also die laufende Zahl
--     aller bisher gezaehlten Klick-outs. Die Tabelle selbst ist fuer anon
--     dicht, dieser Zaehler waere es ohne Entzug nicht.
--   * UPDATE erlaubt `setval` und damit das Verbiegen der Nummernfolge bis hin
--     zu Primaerschluessel-Kollisionen beim naechsten Insert.
-- Beides braucht die Anwendung nie.
revoke all on sequence public.click_outs_id_seq
  from public, anon, authenticated, service_role;
-- USAGE und ausschliesslich USAGE fuer service_role: fuer eine IDENTITY-Spalte
-- verlangt PostgreSQL zwar kein Sequenzrecht des Schreibenden, aber USAGE ist
-- der schmalste Rueckfallpfad, falls die Spalte je auf `serial`-Semantik
-- umgestellt wuerde. USAGE erlaubt nur nextval und currval — nicht das Lesen
-- des Zaehlerstands (SELECT) und nicht setval (UPDATE).
grant usage on sequence public.click_outs_id_seq to service_role;

-- ---------------------------------------------------------------------------
-- Privates Auswertungsschema
-- ---------------------------------------------------------------------------
-- Nicht in `public`: was hier liegt, ist ueber PostgREST grundsaetzlich nicht
-- erreichbar, unabhaengig von Grants.
create schema cbb_private_analytics;
revoke all on schema cbb_private_analytics from public, anon, authenticated;

comment on schema cbb_private_analytics is
  'Privates Auswertungsschema der Klick-out-Messung. Nicht ueber PostgREST exponiert, keine Rechte fuer PUBLIC, anon oder authenticated.';

-- ---------------------------------------------------------------------------
-- Datensparsame Auswertung
-- ---------------------------------------------------------------------------
-- Die View gibt AUSSCHLIESSLICH Aggregate zurueck. consented_session_id
-- erscheint nie als Wert, sondern nur als count(distinct ...) — daraus laesst
-- sich keine einzelne Sitzung rekonstruieren. `security_invoker` sorgt dafuer,
-- dass die View die Rechte des Aufrufers benutzt und nicht die des Erstellers;
-- ohne das waere sie ein Umweg an den Tabellenrechten vorbei.
create view cbb_private_analytics.click_outs_daily
  with (security_invoker = true)
as
select
  (created_at at time zone 'Europe/Berlin')::date as tag,
  product_slug,
  merchant,
  device_class,
  coalesce(source_path, '(ohne Herkunft)') as herkunftspfad,
  count(*)::bigint as klicks,
  count(distinct consented_session_id)::bigint as sitzungen
from public.click_outs
group by 1, 2, 3, 4, 5;

comment on view cbb_private_analytics.click_outs_daily is
  'Tagesaggregat der Klick-outs. Gibt keine Einzelereignisse und keine Sitzungskennung aus, nur Zaehlungen. security_invoker ist an.';

revoke all on cbb_private_analytics.click_outs_daily
  from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Retention als Funktion — die Ausfuehrung passiert in 04, nie hier
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER, weil service_role zwar BYPASSRLS traegt, aber bewusst KEIN
-- DELETE-Recht auf der Tabelle hat. Der einzige Loeschpfad ist damit genau
-- diese Funktion mit ihrem festen, nach Alter gefilterten DELETE. `search_path`
-- ist fest verdrahtet — ohne das koennte ein Aufrufer die Funktion auf eine
-- untergeschobene gleichnamige Tabelle zeigen lassen.
create function cbb_private_analytics.purge_click_outs(retention_months integer default 12)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  removed integer;
begin
  if retention_months is null or retention_months < 1 or retention_months > 24 then
    raise exception 'purge_click_outs abgebrochen: retention_months % liegt ausserhalb von 1 bis 24.',
      retention_months;
  end if;

  delete from public.click_outs
  where created_at < now() - make_interval(months => retention_months);

  get diagnostics removed = row_count;
  return removed;
end $$;

comment on function cbb_private_analytics.purge_click_outs(integer) is
  'Loescht Klick-out-Ereignisse, die aelter als retention_months sind (Default 12, entspricht der Zusage in der Datenschutzerklaerung). Einziger Loeschpfad der Tabelle.';

revoke all on function cbb_private_analytics.purge_click_outs(integer)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Abschliessende Selbstpruefung innerhalb derselben Transaktion
-- ---------------------------------------------------------------------------
do $$
declare
  policies integer;
  rls boolean;
  app_privs integer;
  service_privs integer;
  indexes integer;
  constraints integer;
  seq_name text;
  seq_app_privs integer;
  seq_service_privs integer;
begin
  select c.relrowsecurity into rls
  from pg_class c where c.oid = 'public.click_outs'::regclass;
  if rls is not true then
    raise exception 'Klick-out-Anlage inkonsistent: RLS ist nicht aktiv.';
  end if;

  select count(*) into policies
  from pg_policy where polrelid = 'public.click_outs'::regclass;
  if policies <> 0 then
    raise exception 'Klick-out-Anlage inkonsistent: % Policy(s) vorhanden, erwartet 0.', policies;
  end if;

  -- Effektive Rechte, nicht nur direkte ACL-Eintraege: has_table_privilege
  -- loest Rollenmitgliedschaft und PUBLIC-Rechte mit auf.
  select count(*) into app_privs
  from pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid, 'public.click_outs'::regclass::oid, p.priv::text);
  if app_privs <> 0 then
    raise exception 'Klick-out-Anlage inkonsistent: anon/authenticated haben % Recht(e) auf click_outs.',
      app_privs;
  end if;

  select count(*) into service_privs
  from (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where has_table_privilege('service_role', 'public.click_outs'::regclass::oid, p.priv::text);
  if service_privs <> 1
     or not has_table_privilege('service_role', 'public.click_outs'::regclass::oid, 'INSERT') then
    raise exception 'Klick-out-Anlage inkonsistent: service_role hat % Recht(e), erwartet genau INSERT.',
      service_privs;
  end if;

  -- Die Sequenz, die der Rechte-Entzug oben getroffen hat, MUSS die Sequenz
  -- der Identity-Spalte sein. Ohne diesen Abgleich koennte der Entzug an einer
  -- gleichnamigen Fremdsequenz haengen bleiben und die echte offen lassen.
  select pg_get_serial_sequence('public.click_outs', 'id') into seq_name;
  if seq_name is distinct from 'public.click_outs_id_seq' then
    raise exception 'Klick-out-Anlage inkonsistent: Identity-Sequenz heisst %, erwartet public.click_outs_id_seq.',
      coalesce(seq_name, 'keine');
  end if;

  select count(*) into seq_app_privs
  from pg_roles r
  cross join (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_sequence_privilege(r.oid, 'public.click_outs_id_seq'::regclass::oid, p.priv::text);
  if seq_app_privs <> 0 then
    raise exception 'Klick-out-Anlage inkonsistent: anon/authenticated haben % Recht(e) auf der Identity-Sequenz.',
      seq_app_privs;
  end if;

  select count(*) into seq_service_privs
  from (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
  where has_sequence_privilege('service_role', 'public.click_outs_id_seq'::regclass::oid, p.priv::text);
  if seq_service_privs <> 1
     or not has_sequence_privilege('service_role', 'public.click_outs_id_seq'::regclass::oid, 'USAGE') then
    raise exception 'Klick-out-Anlage inkonsistent: service_role hat % Sequenzrecht(e), erwartet genau USAGE.',
      seq_service_privs;
  end if;

  select count(*) into indexes
  from pg_index where indrelid = 'public.click_outs'::regclass;
  -- 2 eigene Indizes plus der implizite Primaerschluessel-Index.
  if indexes <> 3 then
    raise exception 'Klick-out-Anlage inkonsistent: % Indizes, erwartet 3.', indexes;
  end if;

  select count(*) into constraints
  from pg_constraint
  where conrelid = 'public.click_outs'::regclass and contype = 'c';
  if constraints <> 5 then
    raise exception 'Klick-out-Anlage inkonsistent: % CHECK-Constraints, erwartet 5.', constraints;
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: die Tabelle ist leer.
select count(*) as click_out_rows from public.click_outs;
