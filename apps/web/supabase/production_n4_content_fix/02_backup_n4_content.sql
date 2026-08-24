-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 02 PRIVATES BACKUP (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- Diese Datei fasst public.products NUR LESEND an. Sie legt ausschliesslich
-- cbb_private_backup.n4_content_pre_fix_v1 an: genau eine Zeile mit genau den
-- Feldern, die Schritt 04 spaeter aendert, plus id, slug und updated_at.
--
-- Das Backup bleibt nach einem Restore als Audit-Artefakt bestehen. Es wird von
-- keiner Datei dieses Pakets automatisch geloescht.
--
-- FAIL CLOSED: existiert cbb_private_backup.n4_content_pre_fix_v1 bereits,
-- bricht die Transaktion ab, statt ein zweites Mal ueber einen bereits
-- korrigierten Stand zu sichern.
--
-- FAIL CLOSED GEGEN NEBENLAEUFIGKEIT: der verbindliche Vorzustandsbeweis steht
-- in Guard 2, also NACH dem Row-Lock, und umfasst ALLE sieben Inhaltsfelder
-- plus id, slug und is_published. Eine Aenderung, die zwischen der sperrfreien
-- Vorpruefung (Guard 1b) und dem Lock committet, fuehrt damit zum Abbruch,
-- statt in den Snapshot zu geraten.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung und Value-Add-Zustand.
-- Dieselben Pruefungen wie in 01_preflight_read_only.sql, hier als harte
-- Abbruchbedingungen statt als Bericht. Der inhaltliche N4-Vorzustand wird
-- bewusst erst in Guard 1b geprueft: die erwarteten Werte stehen ab dort als
-- Tabelle cbb_n4_expected_pre nur EINMAL in dieser Datei und werden von
-- Guard 1b und Guard 2 gemeinsam benutzt.
-- ---------------------------------------------------------------------------
do $$
declare
  product_rows bigint;
  n4_rows integer;
  column_rows integer;
  correct_types integer;
  constraint_rows integer;
  snapshot_rows integer;
  payload_rows integer;
  payload_n4 integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'N4-Backup abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'N4-Backup abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'N4-Backup abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into n4_rows
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch' and is_published is true;
  if n4_rows <> 1 then
    raise exception 'N4-Backup abgebrochen: %/1 N4-Zeile published.', n4_rows;
  end if;

  select count(*) into column_rows
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and column_name in (
      'fuer_wen', 'nicht_fuer', 'key_fact', 'pros', 'cons',
      'alternative_slug', 'alternative_reason', 'alternative_kind'
    );
  select count(*) into correct_types
  from information_schema.columns
  where table_schema = 'public' and table_name = 'products'
    and (
      (column_name in (
        'fuer_wen', 'nicht_fuer', 'key_fact', 'alternative_slug',
        'alternative_reason', 'alternative_kind'
      ) and data_type = 'text' and udt_name = 'text')
      or
      (column_name in ('pros', 'cons')
        and data_type = 'ARRAY' and udt_name = '_text')
    );
  select count(*) into constraint_rows
  from pg_constraint
  where conrelid = 'public.products'::regclass
    and contype = 'c'
    and conname in (
      'products_alternative_kind_check',
      'products_alternative_relation_check'
    );
  if column_rows <> 8 or correct_types <> 8 or constraint_rows <> 2 then
    raise exception 'N4-Backup abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'N4-Backup abgebrochen: Value-Add-Marker fehlen.';
  end if;
  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v1;
  if snapshot_rows <> 10 or payload_rows <> 10 then
    raise exception 'N4-Backup abgebrochen: Marker haben % Snapshot- und % Payload-Zeilen (erwartet 10/10).',
      snapshot_rows, payload_rows;
  end if;

  select count(*) into payload_n4
  from cbb_private_backup.value_add_payload_v1
  where slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and fuer_wen is not null and nicht_fuer is not null
    and key_fact is not null and pros is not null and cons is not null
    and editorial_note is not null;
  if payload_n4 <> 1 then
    raise exception 'N4-Backup abgebrochen: Audit-Payload enthaelt keine befuellte N4-Zeile.';
  end if;

  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is not null then
    raise exception 'N4-Backup abgebrochen: n4_content_pre_fix_v1 existiert bereits.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Der erwartete Vorzustand — genau einmal als Literal in dieser Datei.
--   tagline      -> supabase/import_products_batch13.sql
--   description  -> supabase/expand_descriptions_batch6.sql
--   nicht_fuer / key_fact / pros / cons / editorial_note
--                -> supabase/production_value_add/04_backfill_value_add.sql
-- Guard 1b prueft dagegen VOR dem Lock, Guard 2 erneut NACH dem Lock.
-- ---------------------------------------------------------------------------
create temporary table cbb_n4_expected_pre (
  slug text primary key,
  tagline text not null,
  description text not null,
  nicht_fuer text not null,
  key_fact text not null,
  pros text[] not null,
  cons text[] not null,
  editorial_note text not null
) on commit drop;

insert into cbb_n4_expected_pre (
  slug, tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
) values (
  'n4-nussmilchbereiter-pflanzenmilch',
  '800W Pflanzenmilch-Maker mit Selbstreinigung — Hafermilch in unter 2 Minuten',
  'N4 Nussmilchbereiter für frische Pflanzenmilch. Hafer-, Mandel-, Soja-, Reis- oder Cashew-Milch in 15 Minuten. Mixt, kocht, filtert automatisch. Für Menschen, die Bio-Milch-Preise satt haben und ihre Zutaten selbst kontrollieren wollen. Amortisiert sich nach 2 Monaten täglichem Frühstück.',
  'Wer nur selten mal Hafermilch trinkt — die Anschaffung amortisiert sich dann kaum.',
  '800-W-Bereiter mit Selbstreinigung für Hafer-, Mandel-, Soja-, Reis- und Cashew-Milch.',
  array[
    'Mixt, kocht und filtert automatisch',
    'Selbstreinigung',
    'Fünf Milchsorten',
    '800 W'
  ],
  array[
    'Lohnt sich nur bei regelmäßigem Konsum',
    'Ein weiteres Küchengerät, das gereinigt werden will'
  ],
  'Macht frische Pflanzenmilch auf Knopfdruck und reinigt sich selbst. Für Menschen, die Milch-Alternativen ernst nehmen und die Bio-Laden-Preise satt haben. Lohnt sich, wenn täglich getrunken — sonst steht er nur rum.'
);

-- ---------------------------------------------------------------------------
-- Guard 1b — N4-Vorzustand VOR dem Lock. Fruehe, billige Abbruchbedingung;
-- verbindlich ist erst Guard 2 nach dem Lock.
-- ---------------------------------------------------------------------------
do $$
declare
  pre_state integer;
begin
  select count(*) into pre_state
  from public.products p
  join cbb_n4_expected_pre e on e.slug = p.slug
  where p.is_published is true
    and p.tagline is not distinct from e.tagline
    and p.description is not distinct from e.description
    and p.nicht_fuer is not distinct from e.nicht_fuer
    and p.key_fact is not distinct from e.key_fact
    and p.pros is not distinct from e.pros
    and p.cons is not distinct from e.cons
    and p.editorial_note is not distinct from e.editorial_note;
  if pre_state <> 1 then
    raise exception 'N4-Backup abgebrochen: N4-Vorzustand weicht vom erwarteten Stand ab.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Identitaetsanker. Guard 1b und Guard 2 sind getrennte DO-Bloecke und teilen
-- keine Variablen. Damit Guard 2 nach dem Row-Lock nicht nur "irgendeine Zeile
-- mit diesem slug", sondern nachweislich DIESELBE Zeile wiederfindet, wird ihre
-- id hier festgehalten.
-- ---------------------------------------------------------------------------
create temporary table cbb_n4_identity on commit drop as
select p.id, p.slug
from public.products p
where p.slug = 'n4-nussmilchbereiter-pflanzenmilch';

-- ---------------------------------------------------------------------------
-- Guard 2 — der einzige verbindliche Zustandsbeweis.
--
-- WARUM HIER ALLE SIEBEN FELDER STEHEN
--   Guard 1b liest OHNE Sperre. Zwischen Guard 1b und dem Row-Lock darf eine
--   konkurrierende Transaktion jederzeit committen. Prueft Guard 2 danach nur
--   einen Teil der Felder, gelangt eine Aenderung an den uebrigen Feldern
--   (nicht_fuer, key_fact, pros, cons, editorial_note) unbemerkt in den
--   Snapshot — das Backup waere dann kein Abbild des bekannten Vorzustands
--   mehr, und der Rollback-Pfad still falsch.
--   Deshalb: erst FOR UPDATE, dann ALLE sieben Inhaltsfelder plus Identitaet
--   (id, slug) und is_published erneut per IS NOT DISTINCT FROM pruefen.
--   Erst danach entsteht die Backup-Tabelle.
--
--   Der Lock haelt bis zum COMMIT. Ab dem erfolgreichen Recheck ist der Stand
--   also festgeschrieben, und der Snapshot weiter unten kann nicht mehr von
--   einem abweichenden Stand stammen.
-- ---------------------------------------------------------------------------
do $$
declare
  identity_rows integer;
  locked_rows integer;
  pre_state integer;
begin
  select count(*) into identity_rows from cbb_n4_identity;
  if identity_rows <> 1 then
    raise exception 'N4-Backup abgebrochen: %/1 Identitaetsanker gefunden.', identity_rows;
  end if;

  -- READ COMMITTED: blockiert FOR UPDATE, wird nach dem fremden COMMIT auf der
  -- NEUEN Zeilenversion neu ausgewertet. Passt id/slug dann nicht mehr oder ist
  -- die Zeile geloescht, kommen hier 0 Zeilen zurueck.
  perform p.id
  from public.products p
  join cbb_n4_identity i on i.id = p.id and i.slug = p.slug
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
  for update of p;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 1 then
    raise exception 'N4-Backup abgebrochen: %/1 Zielzeile gesperrt (Identitaet passt nicht mehr).',
      locked_rows;
  end if;

  -- Neues Statement, neuer Snapshot: sieht jetzt garantiert den Stand, der
  -- unter dem Lock steht.
  select count(*) into pre_state
  from public.products p
  join cbb_n4_identity i on i.id = p.id and i.slug = p.slug
  join cbb_n4_expected_pre e on e.slug = p.slug
  where p.is_published is true
    and p.tagline is not distinct from e.tagline
    and p.description is not distinct from e.description
    and p.nicht_fuer is not distinct from e.nicht_fuer
    and p.key_fact is not distinct from e.key_fact
    and p.pros is not distinct from e.pros
    and p.cons is not distinct from e.cons
    and p.editorial_note is not distinct from e.editorial_note;
  if pre_state <> 1 then
    raise exception 'N4-Backup abgebrochen: N4-Zeile wurde zwischen Vorpruefung und Sperre veraendert.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Privates Backup-Schema. Das Schema stammt aus dem Value-Add-Rollout und
-- existiert bereits; die beiden Anweisungen sind idempotent und stellen die
-- Absicherung auch dann her, wenn das Schema hier neu entsteht.
-- ---------------------------------------------------------------------------
create schema if not exists cbb_private_backup;
revoke all on schema cbb_private_backup from public, anon, authenticated;

create table cbb_private_backup.n4_content_pre_fix_v1 as
select
  id,
  slug,
  updated_at,
  tagline,
  description,
  nicht_fuer,
  key_fact,
  pros,
  cons,
  editorial_note
from public.products
where slug = 'n4-nussmilchbereiter-pflanzenmilch';

alter table cbb_private_backup.n4_content_pre_fix_v1
  add primary key (id),
  add unique (slug),
  enable row level security;

revoke all on cbb_private_backup.n4_content_pre_fix_v1
  from public, anon, authenticated;

-- service_role wird nur angesprochen, wenn die Rolle existiert. Auf einem
-- Cluster ohne Supabase-Rollen wuerde ein statisches REVOKE mit
-- "role does not exist" abbrechen.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'revoke all on schema cbb_private_backup from service_role';
    execute 'revoke all on cbb_private_backup.n4_content_pre_fix_v1 from service_role';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Nachbedingungen: genau eine Zeile, inhaltsgleich mit products, RLS aktiv,
-- keine Policies, keine App-Rechte.
-- ---------------------------------------------------------------------------
do $$
declare
  backup_rows integer;
  drift_rows integer;
  rls_active boolean;
  policy_rows integer;
  grant_rows integer;
begin
  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'N4-Backup unvollstaendig: %/1 Zeilen.', backup_rows;
  end if;

  -- Der FULL JOIN laeuft bewusst gegen die auf die N4-Zeile eingegrenzte
  -- Menge, nicht gegen public.products insgesamt: sonst zaehlte jede der 375
  -- Nichtzielzeilen als "Backup-Zeile fehlt" und der Guard waere sinnlos.
  select count(*) into drift_rows
  from cbb_private_backup.n4_content_pre_fix_v1 b
  full join (
    select *
    from public.products
    where slug = 'n4-nussmilchbereiter-pflanzenmilch'
  ) p on p.id = b.id and p.slug = b.slug
  where b.id is null
     or p.id is null
     or p.updated_at is distinct from b.updated_at
     or p.tagline is distinct from b.tagline
     or p.description is distinct from b.description
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.editorial_note is distinct from b.editorial_note;
  if drift_rows <> 0 then
    raise exception 'N4-Backup inkonsistent: % Abweichungen gegen products.', drift_rows;
  end if;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into rls_active, policy_rows
  from pg_class c
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass;
  if rls_active is not true or policy_rows <> 0 then
    raise exception 'N4-Backup unsicher: RLS=%, Policies=%.', rls_active, policy_rows;
  end if;

  select count(*) into grant_rows
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass
    and (acl.grantee = 0
         or r.rolname in ('anon', 'authenticated', 'service_role'));
  if grant_rows <> 0 then
    raise exception 'N4-Backup unsicher: % Rechte fuer PUBLIC/anon/authenticated/service_role.',
      grant_rows;
  end if;
end $$;

commit;

-- Read-only-Ergebnis nach erfolgreichem Commit: exakt 1.
select count(*) as n4_backup_rows
from cbb_private_backup.n4_content_pre_fix_v1;
