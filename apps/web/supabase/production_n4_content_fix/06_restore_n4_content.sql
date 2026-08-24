-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 06 RESTORE (SCHREIBEND, ROLLBACK)
-- ============================================================================
-- Nur mit neuer ausdruecklicher Benutzerfreigabe ausfuehren.
-- Sichtbares Ziel: project/ydiihvzcxaaoqhmgoqvu
--
-- Stellt exakt die in 02 gesicherten Felder der einen N4-Zeile wieder her —
-- einschliesslich des historischen updated_at. Danach ist der Stand vor der
-- Korrektur wiederhergestellt, inklusive des alten lastmod-Werts fuer die
-- Sitemap.
--
-- Das Backup cbb_private_backup.n4_content_pre_fix_v1 bleibt als Audit-Artefakt
-- bestehen. Diese Datei loescht es NICHT. Sie ist damit wiederholbar.
--
-- DAS BACKUP IST HIER DIE DATENQUELLE — ALSO WIRD ES GEPRUEFT, NICHT GEGLAUBT
--   Ein Restore schreibt Backup-Inhalt nach public.products. Ein manipuliertes
--   Backup wuerde dabei ungeprueft zu Seiteninhalt. Deshalb gilt vor jedem
--   Schreibvorgang:
--     1. Der Backup-Inhalt muss exakt dem bekannten Vorzustand entsprechen
--        (cbb_n4_expected_pre, dieselben sieben Literale wie in 02 und 04).
--        Weicht auch nur ein Feld ab, wird nichts geschrieben.
--     2. Das Backup muss weiterhin ein privates Artefakt sein: RLS aktiv,
--        0 Policies, und fuer PUBLIC/anon/authenticated weder direkte
--        ACL-Eintraege noch effektive Rechte auf Tabelle oder Schema. Effektiv
--        heisst: has_table_privilege/has_schema_privilege, also inklusive
--        Rollenmitgliedschaft und geerbter PUBLIC-Rechte — ein nur geerbtes
--        Recht ist in den direkten ACLs unsichtbar. Existiert service_role,
--        gilt dieselbe Null-Forderung fuer sie.
--     3. Erst sperren, dann die Backup- und Identitaetspruefung NACH dem Lock
--        wiederholen, erst danach UPDATE.
--   Anders als in 03/05, wo service_role nur als INFO-Zeile berichtet wird,
--   ist sie hier eine harte Abbruchbedingung: 03/05 berichten, diese Datei
--   schreibt.
--
-- ZUM TRIGGER products_set_updated_at:
--   Der Trigger ueberschreibt updated_at nur, wenn der Aufrufer die Spalte
--   NICHT selbst mitschreibt. Hier wird sie ausdruecklich mitgeschrieben, der
--   historische Wert bleibt also stehen. Sollte in einem kaputten Zwischenstand
--   products.updated_at zufaellig schon dem Backup-Wert entsprechen, waehrend
--   der Inhalt abweicht, greift der Trigger doch und setzt now(). Genau das
--   faengt die Gleichheitspruefung unten ab: die Transaktion bricht dann ab,
--   statt einen falschen Zeitstempel zu hinterlassen.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung, Zielzeile, Backup-Existenz und Backup-Sicherheit.
-- ---------------------------------------------------------------------------
do $$
declare
  product_rows bigint;
  n4_rows integer;
  backup_rows integer;
  paar_rows integer;
  rls_active boolean;
  policy_rows integer;
  backup_oid oid;
  backup_nsp oid;
  app_rollen integer;
  direkt_tabelle integer;
  direkt_schema integer;
  effektiv_tabelle integer;
  effektiv_schema integer;
  sr_direkt_tabelle integer;
  sr_direkt_schema integer;
  sr_effektiv_tabelle integer;
  sr_effektiv_schema integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'N4-Restore abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'N4-Restore abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'N4-Restore abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into n4_rows
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch';
  if n4_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: %/1 N4-Zeile vorhanden.', n4_rows;
  end if;

  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is null then
    raise exception 'N4-Restore abgebrochen: privates Backup n4_content_pre_fix_v1 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: Backup hat %/1 Zeilen.', backup_rows;
  end if;

  -- Backup und Zielzeile muessen dieselbe Identitaet haben.
  select count(*) into paar_rows
  from cbb_private_backup.n4_content_pre_fix_v1 b
  join public.products p on p.id = b.id and p.slug = b.slug
  where b.slug = 'n4-nussmilchbereiter-pflanzenmilch';
  if paar_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: Backup passt zu %/1 Produktzeilen.',
      paar_rows;
  end if;

  backup_oid := 'cbb_private_backup.n4_content_pre_fix_v1'::regclass;
  select c.relnamespace into backup_nsp
  from pg_class c where c.oid = backup_oid;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into rls_active, policy_rows
  from pg_class c
  where c.oid = backup_oid;
  if rls_active is not true or policy_rows <> 0 then
    raise exception 'N4-Restore abgebrochen: Backup unsicher (RLS=%, Policies=%).',
      rls_active, policy_rows;
  end if;

  -- -------------------------------------------------------------------------
  -- Harte Vorbedingung der Rechtepruefung: fehlt eine der App-Rollen, liefern
  -- beide Zaehler still 0 — das waere kein Beleg fuer "keine Rechte", sondern
  -- nur einer fuer "keine Rolle". Ein schreibender Sicherheitsguard darf sich
  -- darauf nicht stuetzen.
  -- -------------------------------------------------------------------------
  select count(*) into app_rollen
  from pg_roles r where r.rolname in ('anon', 'authenticated');
  if app_rollen <> 2 then
    raise exception 'N4-Restore abgebrochen: %/2 App-Rollen (anon, authenticated) vorhanden — Rechtepruefung nicht aussagekraeftig.',
      app_rollen;
  end if;

  -- (a) direkte ACL-Eintraege. Bewusst nicht ueber information_schema: dort
  -- fehlen Default-ACLs (acl is null) und PUBLIC-Eintraege. grantee = 0 ist
  -- PUBLIC.
  select count(*) into direkt_tabelle
  from pg_class c
  cross join lateral aclexplode(
    coalesce(c.relacl, acldefault('r'::"char", c.relowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where c.oid = backup_oid
    and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated'));

  select count(*) into direkt_schema
  from pg_namespace n
  cross join lateral aclexplode(
    coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
  ) as acl
  left join pg_roles r on r.oid = acl.grantee
  where n.oid = backup_nsp
    and (acl.grantee = 0 or r.rolname in ('anon', 'authenticated'));

  -- (b) effektive Rechte. Loesen Rollenmitgliedschaft und PUBLIC-Rechte mit
  -- auf. Genau hier faellt ein Recht auf, das nur ueber eine Hilfsrolle geerbt
  -- ist und in (a) unsichtbar bleibt.
  select count(*) into effektiv_tabelle
  from pg_roles r
  cross join (values
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
    ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
  ) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid, backup_oid, p.priv::text);

  select count(*) into effektiv_schema
  from pg_roles r
  cross join (values ('USAGE'), ('CREATE')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

  if direkt_tabelle <> 0 or direkt_schema <> 0
     or effektiv_tabelle <> 0 or effektiv_schema <> 0 then
    raise exception 'N4-Restore abgebrochen: Backup unsicher (fuer PUBLIC/anon/authenticated: direkt Tabelle %, direkt Schema %, effektiv Tabelle %, effektiv Schema %).',
      direkt_tabelle, direkt_schema, effektiv_tabelle, effektiv_schema;
  end if;

  -- service_role, falls die Rolle existiert. In 03 und 05 ist sie nur INFO,
  -- weil die dort berichten. Diese Datei schreibt — hier ist sie hart.
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    select count(*) into sr_direkt_tabelle
    from pg_class c
    cross join lateral aclexplode(
      coalesce(c.relacl, acldefault('r'::"char", c.relowner))
    ) as acl
    join pg_roles r on r.oid = acl.grantee
    where c.oid = backup_oid and r.rolname = 'service_role';

    select count(*) into sr_direkt_schema
    from pg_namespace n
    cross join lateral aclexplode(
      coalesce(n.nspacl, acldefault('n'::"char", n.nspowner))
    ) as acl
    join pg_roles r on r.oid = acl.grantee
    where n.oid = backup_nsp and r.rolname = 'service_role';

    select count(*) into sr_effektiv_tabelle
    from pg_roles r
    cross join (values
      ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
      ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
    ) as p(priv)
    where r.rolname = 'service_role'
      and has_table_privilege(r.oid, backup_oid, p.priv::text);

    select count(*) into sr_effektiv_schema
    from pg_roles r
    cross join (values ('USAGE'), ('CREATE')) as p(priv)
    where r.rolname = 'service_role'
      and has_schema_privilege(r.oid, backup_nsp, p.priv::text);

    if sr_direkt_tabelle <> 0 or sr_direkt_schema <> 0
       or sr_effektiv_tabelle <> 0 or sr_effektiv_schema <> 0 then
      raise exception 'N4-Restore abgebrochen: Backup unsicher (fuer service_role: direkt Tabelle %, direkt Schema %, effektiv Tabelle %, effektiv Schema %).',
        sr_direkt_tabelle, sr_direkt_schema, sr_effektiv_tabelle, sr_effektiv_schema;
    end if;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Der bekannte Vorzustand — dieselben sieben Literale wie in 02 und 04, hier
-- als Pruefmassstab fuer den Backup-INHALT.
--   tagline      -> supabase/import_products_batch13.sql
--   description  -> supabase/expand_descriptions_batch6.sql
--   nicht_fuer / key_fact / pros / cons / editorial_note
--                -> supabase/production_value_add/04_backfill_value_add.sql
--
-- products wird hier bewusst NICHT gegen diese Werte geprueft: der Restore soll
-- ja gerade aus dem korrigierten Stand zurueckfuehren. Geprueft wird nur, dass
-- die Datenquelle des Schreibvorgangs — das Backup — unveraendert ist.
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
-- Guard 2 — Backup-Inhalt gegen den bekannten Vorzustand, VOR dem Lock.
-- Fruehe, billige Abbruchbedingung; verbindlich ist Guard 3.
-- ---------------------------------------------------------------------------
do $$
declare
  backup_match integer;
begin
  select count(*) into backup_match
  from cbb_private_backup.n4_content_pre_fix_v1 b
  join cbb_n4_expected_pre e on e.slug = b.slug
  where b.tagline is not distinct from e.tagline
    and b.description is not distinct from e.description
    and b.nicht_fuer is not distinct from e.nicht_fuer
    and b.key_fact is not distinct from e.key_fact
    and b.pros is not distinct from e.pros
    and b.cons is not distinct from e.cons
    and b.editorial_note is not distinct from e.editorial_note;
  if backup_match <> 1 then
    raise exception 'N4-Restore abgebrochen: Backup entspricht nicht dem bekannten Vorzustand.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Guard 3 + UPDATE — sperren, NACH dem Lock erneut pruefen, erst dann
-- zurueckspielen, danach nachweisen.
--
-- Gesperrt werden BEIDE Zeilen: die Produktzeile und die Backup-Zeile. Erst
-- danach sind Backup-Inhalt und Identitaet stabil; ohne diesen zweiten Beweis
-- koennte eine konkurrierende Transaktion das Backup zwischen Guard 2 und dem
-- UPDATE noch veraendern und der Restore wuerde fremden Text als Seiteninhalt
-- schreiben.
-- ---------------------------------------------------------------------------
do $$
declare
  locked_rows integer;
  backup_match integer;
  paar_rows integer;
  affected_rows integer;
  mismatch_rows integer;
begin
  perform p.id
  from public.products p
  join cbb_private_backup.n4_content_pre_fix_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
  for update of p, b;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: %/1 Zeilenpaar aus products und Backup gesperrt.',
      locked_rows;
  end if;

  -- Neues Statement, neuer Snapshot: der Backup-Inhalt steht jetzt unter dem
  -- Lock fest.
  select count(*) into backup_match
  from cbb_private_backup.n4_content_pre_fix_v1 b
  join cbb_n4_expected_pre e on e.slug = b.slug
  where b.tagline is not distinct from e.tagline
    and b.description is not distinct from e.description
    and b.nicht_fuer is not distinct from e.nicht_fuer
    and b.key_fact is not distinct from e.key_fact
    and b.pros is not distinct from e.pros
    and b.cons is not distinct from e.cons
    and b.editorial_note is not distinct from e.editorial_note;
  if backup_match <> 1 then
    raise exception 'N4-Restore abgebrochen: Backup wurde zwischen Vorpruefung und Sperre veraendert.';
  end if;

  select count(*) into paar_rows
  from cbb_private_backup.n4_content_pre_fix_v1 b
  join public.products p on p.id = b.id and p.slug = b.slug
  where b.slug = 'n4-nussmilchbereiter-pflanzenmilch';
  if paar_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: Backup passt nach der Sperre zu %/1 Produktzeilen.',
      paar_rows;
  end if;

  update public.products p set
    tagline = b.tagline,
    description = b.description,
    nicht_fuer = b.nicht_fuer,
    key_fact = b.key_fact,
    pros = b.pros,
    cons = b.cons,
    editorial_note = b.editorial_note,
    updated_at = b.updated_at
  from cbb_private_backup.n4_content_pre_fix_v1 b
  where p.id = b.id and p.slug = b.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'N4-Restore abgebrochen: UPDATE traf %/1 Zeilen.', affected_rows;
  end if;

  select count(*) into mismatch_rows
  from public.products p
  join cbb_private_backup.n4_content_pre_fix_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.updated_at is distinct from b.updated_at
     or p.tagline is distinct from b.tagline
     or p.description is distinct from b.description
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.editorial_note is distinct from b.editorial_note;
  if mismatch_rows <> 0 then
    raise exception 'N4-Restore inkonsistent: % Abweichungen zum Backup.',
      mismatch_rows;
  end if;
end $$;

commit;
