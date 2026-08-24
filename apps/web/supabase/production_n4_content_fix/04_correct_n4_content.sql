-- ============================================================================
-- PRODUCTION N4-CONTENT-FIX — 04 ATOMARE KORREKTUR (SCHREIBEND)
-- ============================================================================
-- NICHT AUSFUEHREN ohne eigene Benutzerfreigabe und sichtbare Zielpruefung:
--   project/ydiihvzcxaaoqhmgoqvu
--
-- WAS GENAU PASSIERT
--   Genau eine Zeile (slug = 'n4-nussmilchbereiter-pflanzenmilch') und an ihr
--   genau acht Spalten:
--     tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
--     und updated_at = now()
--   Nichts anderes. Keine weitere Zeile, keine weitere Spalte.
--
-- WARUM
--   tagline behauptete "unter 2 Minuten", description gleichzeitig "15 Minuten"
--   und "Amortisiert sich nach 2 Monaten". Der Zieltext nennt keine neue
--   konkrete Laufzeit und keine Amortisation, sondern nur belegbare Merkmale.
--   Quellen stehen in RUNBOOK.md.
--
-- updated_at = now() ist Absicht: tagline, description und editorial_note sind
-- sichtbarer Seiteninhalt, die Korrektur ist damit ein echtes neues lastmod
-- fuer die Sitemap. Der Trigger products_set_updated_at ueberschreibt einen
-- ausdruecklich mitgeschriebenen Wert nicht (siehe seo_updated_at_trigger.sql).
--
-- FAIL CLOSED GEGEN NEBENLAEUFIGKEIT
--   Guard 1 und Guard 2 lesen ohne Sperre und sind nur Vorfilter. Verbindlich
--   ist Guard 3: er sperrt die N4-Produktzeile UND die Backup-Zeile und
--   wiederholt danach alle drei Zustandspruefungen (Product-Vorwerte, Backup
--   gegen den bekannten Vorzustand, Driftfreiheit inklusive id/slug/updated_at).
--   Eine konkurrierende Aenderung, die vor dem Lock committet, wird dadurch
--   erkannt und NICHT ueberschrieben.
-- ============================================================================

begin;

-- Zeitgrenzen gelten ab der ersten Anweisung. Sie stehen bewusst VOR dem
-- Guard-Block: dessen `select count(*) from public.products` fasst die Tabelle
-- bereits an und wuerde sonst mit dem Session-Default lock_timeout = 0
-- unbegrenzt auf einen konkurrierenden AccessExclusiveLock warten.
set local lock_timeout = '5s';
set local statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- Guard 1 — Umgebung, Value-Add-Zustand, Backup-Existenz und Backup-Sicherheit.
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
  backup_rows integer;
  rls_active boolean;
  policy_rows integer;
  grant_rows integer;
begin
  if to_regclass('pilot_meta.environment_guard') is not null
     or to_regclass('pilot_backup.value_add_pre_backfill') is not null
     or to_regclass('public.pilot_value_add_backup_20260823') is not null then
    raise exception 'N4-Korrektur abgebrochen: Pilot-Artefakt gefunden.';
  end if;
  if to_regclass('public.products') is null
     or to_regclass('public.page_content') is null
     or to_regclass('public.discovery_queue') is null
     or to_regclass('public.swipes') is null then
    raise exception 'N4-Korrektur abgebrochen: Production-Fingerprint fehlt.';
  end if;

  select count(*) into product_rows from public.products;
  if product_rows < 300 then
    raise exception 'N4-Korrektur abgebrochen: nur % Produkte (< 300).', product_rows;
  end if;

  select count(*) into n4_rows
  from public.products
  where slug = 'n4-nussmilchbereiter-pflanzenmilch' and is_published is true;
  if n4_rows <> 1 then
    raise exception 'N4-Korrektur abgebrochen: %/1 N4-Zeile published.', n4_rows;
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
    raise exception 'N4-Korrektur abgebrochen: Value-Add-Schema unvollstaendig (% Spalten, % Typen, % Constraints).',
      column_rows, correct_types, constraint_rows;
  end if;

  if to_regclass('cbb_private_backup.value_add_pre_backfill_v1') is null
     or to_regclass('cbb_private_backup.value_add_payload_v1') is null then
    raise exception 'N4-Korrektur abgebrochen: Value-Add-Marker fehlen.';
  end if;
  select count(*) into snapshot_rows
  from cbb_private_backup.value_add_pre_backfill_v1;
  select count(*) into payload_rows
  from cbb_private_backup.value_add_payload_v1;
  if snapshot_rows <> 10 or payload_rows <> 10 then
    raise exception 'N4-Korrektur abgebrochen: Marker haben % Snapshot- und % Payload-Zeilen (erwartet 10/10).',
      snapshot_rows, payload_rows;
  end if;

  if to_regclass('cbb_private_backup.n4_content_pre_fix_v1') is null then
    raise exception 'N4-Korrektur abgebrochen: privates Backup n4_content_pre_fix_v1 fehlt.';
  end if;
  select count(*) into backup_rows
  from cbb_private_backup.n4_content_pre_fix_v1;
  if backup_rows <> 1 then
    raise exception 'N4-Korrektur abgebrochen: Backup hat %/1 Zeilen.', backup_rows;
  end if;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into rls_active, policy_rows
  from pg_class c
  where c.oid = 'cbb_private_backup.n4_content_pre_fix_v1'::regclass;
  if rls_active is not true or policy_rows <> 0 then
    raise exception 'N4-Korrektur abgebrochen: Backup unsicher (RLS=%, Policies=%).',
      rls_active, policy_rows;
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
    raise exception 'N4-Korrektur abgebrochen: Backup unsicher (% Rechte fuer PUBLIC/anon/authenticated/service_role).',
      grant_rows;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Der erwartete Vorzustand — genau einmal als Literal in dieser Datei.
--   tagline      -> supabase/import_products_batch13.sql
--   description  -> supabase/expand_descriptions_batch6.sql
--   nicht_fuer / key_fact / pros / cons / editorial_note
--                -> supabase/production_value_add/04_backfill_value_add.sql
-- Geprueft wird gegen BEIDE Seiten: gegen das Backup und gegen products.
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
-- Guard 2 — Backup und products muessen beide exakt dem erwarteten Vorzustand
-- entsprechen, und beide muessen zueinander driftfrei sein.
--
-- ACHTUNG: Guard 2 liest OHNE Sperre und ist deshalb NICHT der verbindliche
-- Beweis, sondern nur die fruehe, billige Abbruchbedingung. Verbindlich ist
-- Guard 3 weiter unten, der dieselben drei Pruefungen NACH dem Row-Lock
-- wiederholt.
-- ---------------------------------------------------------------------------
do $$
declare
  backup_match integer;
  product_match integer;
  drift_rows integer;
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
    raise exception 'N4-Korrektur abgebrochen: Backup entspricht nicht dem erwarteten Vorzustand.';
  end if;

  select count(*) into product_match
  from public.products p
  join cbb_n4_expected_pre e on e.slug = p.slug
  where p.tagline is not distinct from e.tagline
    and p.description is not distinct from e.description
    and p.nicht_fuer is not distinct from e.nicht_fuer
    and p.key_fact is not distinct from e.key_fact
    and p.pros is not distinct from e.pros
    and p.cons is not distinct from e.cons
    and p.editorial_note is not distinct from e.editorial_note;
  if product_match <> 1 then
    raise exception 'N4-Korrektur abgebrochen: N4-Vorzustand weicht vom erwarteten Stand ab.';
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
    raise exception 'N4-Korrektur abgebrochen: % Abweichungen zwischen Backup und products.',
      drift_rows;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Der Zieltext. Vorsichtig formuliert: keine neue konkrete Laufzeitzusage,
-- keine Amortisationszusage, keine Reinigungs-Vollautomatik.
-- ---------------------------------------------------------------------------
create temporary table cbb_n4_target (
  slug text primary key,
  tagline text not null,
  description text not null,
  nicht_fuer text not null,
  key_fact text not null,
  pros text[] not null,
  cons text[] not null,
  editorial_note text not null
) on commit drop;

insert into cbb_n4_target (
  slug, tagline, description, nicht_fuer, key_fact, pros, cons, editorial_note
) values (
  'n4-nussmilchbereiter-pflanzenmilch',
  '1,5-Liter-Pflanzenmilchbereiter mit 800-W-Motor und Reinigungsprogramm',
  'Der Ariceck N4 ist ein 1,5-Liter-Pflanzenmilchbereiter mit Programmen für Getreide, Nüsse und Bohnen. Das Gerät mixt und erhitzt die Zutaten; ein Reinigungsprogramm unterstützt anschließend beim Saubermachen. Für Menschen, die Hafer-, Mandel- oder Sojamilch selbst zubereiten und die Zutaten kontrollieren wollen.',
  'Wer nur selten Pflanzenmilch selbst zubereitet oder nach dem Programm keinerlei manuelle Nachreinigung erwartet.',
  '1,5-Liter-Behälter, 800-W-Motor und Programme für Getreide, Nüsse und Bohnen; das Reinigungsprogramm unterstützt, ersetzt die manuelle Nachreinigung aber nicht immer.',
  array[
    'Programme für Getreide, Nüsse und Bohnen',
    '1,5 Liter Fassungsvermögen',
    '800-W-Motor',
    'Reinigungsprogramm unterstützt beim Saubermachen'
  ],
  array[
    'Die Laufzeit hängt vom gewählten Programm ab',
    'Manuelle Nachreinigung kann weiterhin nötig sein'
  ],
  'Bereitet Pflanzenmilch aus Getreide, Nüssen oder Bohnen zu und unterstützt danach mit einem Reinigungsprogramm. Für alle, die Zutaten selbst bestimmen wollen und mit programmbedingten Laufzeiten sowie manueller Nachreinigung rechnen.'
);

-- ---------------------------------------------------------------------------
-- Guard 3 + UPDATE — sperren, NACH dem Lock erneut vollstaendig pruefen,
-- erst dann aendern, danach nachweisen.
--
-- WARUM DIE PRUEFUNGEN HIER NOCH EINMAL STEHEN
--   Guard 2 liest ohne Sperre. Zwischen Guard 2 und dem Row-Lock darf eine
--   konkurrierende Transaktion jederzeit committen — ihre Aenderung wuerde vom
--   UPDATE sonst kommentarlos ueberschrieben und waere verloren. Deshalb:
--     1. BEIDE Zeilen sperren — die Produktzeile UND die Backup-Zeile.
--     2. Nach erfolgreichem Lock erneut pruefen:
--        (a) alle sieben Product-Vorwerte exakt (plus is_published),
--        (b) das Backup ist exakt der bekannte Vorzustand,
--        (c) products und Backup sind driftfrei, id, slug und updated_at
--            eingeschlossen.
--     3. Erst danach UPDATE.
--   Der Lock haelt bis zum COMMIT; ab Schritt 2 ist der Stand festgeschrieben.
-- ---------------------------------------------------------------------------
do $$
declare
  locked_rows integer;
  product_match integer;
  backup_match integer;
  drift_rows integer;
  affected_rows integer;
  ziel_abweichungen integer;
  fremde_treffer integer;
  n4_unveraenderte_felder integer;
  andere_payload_drift integer;
  lastmod_neu integer;
  backup_unveraendert integer;
begin
  -- 1 — beide Zeilen in EINER Anweisung sperren. FOR UPDATE OF p, b sperrt die
  -- Produktzeile und die zugehoerige Backup-Zeile. Faellt eine von beiden weg
  -- oder passt das Paar nicht mehr zusammen, kommen 0 Zeilen zurueck.
  perform p.id
  from public.products p
  join cbb_private_backup.n4_content_pre_fix_v1 b
    on b.id = p.id and b.slug = p.slug
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
  for update of p, b;
  get diagnostics locked_rows = row_count;
  if locked_rows <> 1 then
    raise exception 'N4-Korrektur abgebrochen: %/1 Zeilenpaar aus products und Backup gesperrt.',
      locked_rows;
  end if;

  -- 2a — alle sieben Vorwerte in products, erneut und unter dem Lock.
  select count(*) into product_match
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
  if product_match <> 1 then
    raise exception 'N4-Korrektur abgebrochen: N4-Zeile wurde zwischen Vorpruefung und Sperre veraendert.';
  end if;

  -- 2b — das Backup ist erneut und unter dem Lock exakt der bekannte Vorzustand.
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
    raise exception 'N4-Korrektur abgebrochen: Backup wurde zwischen Vorpruefung und Sperre veraendert.';
  end if;

  -- 2c — products und Backup driftfrei, id, slug und updated_at eingeschlossen.
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
    raise exception 'N4-Korrektur abgebrochen: % Abweichungen zwischen Backup und products nach dem Lock.',
      drift_rows;
  end if;

  -- 3 — jetzt erst schreiben.
  update public.products p set
    tagline = t.tagline,
    description = t.description,
    nicht_fuer = t.nicht_fuer,
    key_fact = t.key_fact,
    pros = t.pros,
    cons = t.cons,
    editorial_note = t.editorial_note,
    updated_at = now()
  from cbb_n4_target t
  where p.slug = t.slug;

  get diagnostics affected_rows = row_count;
  if affected_rows <> 1 then
    raise exception 'N4-Korrektur abgebrochen: UPDATE traf %/1 Zeilen.', affected_rows;
  end if;

  -- Nachbedingung 1 — die Zielzeile traegt exakt den Zieltext.
  select count(*) into ziel_abweichungen
  from cbb_n4_target t
  left join public.products p on p.slug = t.slug
  where p.slug is null
     or p.tagline is distinct from t.tagline
     or p.description is distinct from t.description
     or p.nicht_fuer is distinct from t.nicht_fuer
     or p.key_fact is distinct from t.key_fact
     or p.pros is distinct from t.pros
     or p.cons is distinct from t.cons
     or p.editorial_note is distinct from t.editorial_note;
  if ziel_abweichungen <> 0 then
    raise exception 'N4-Korrektur inkonsistent: % Abweichungen zum Zieltext.',
      ziel_abweichungen;
  end if;

  -- Nachbedingung 2 — der Zieltext steht in genau einer Zeile der Tabelle.
  select count(*) into fremde_treffer
  from public.products p
  join cbb_n4_target t
    on p.tagline is not distinct from t.tagline
    or p.editorial_note is not distinct from t.editorial_note;
  if fremde_treffer <> 1 then
    raise exception 'N4-Korrektur inkonsistent: Zieltext steht in % Zeilen (erwartet 1).',
      fremde_treffer;
  end if;

  -- Nachbedingung 3 — die vier NICHT geaenderten Value-Add-Felder der N4-Zeile
  -- entsprechen weiterhin exakt der Audit-Payload aus dem Value-Add-Rollout.
  select count(*) into n4_unveraenderte_felder
  from public.products p
  join cbb_private_backup.value_add_payload_v1 v on v.slug = p.slug
  where p.slug = 'n4-nussmilchbereiter-pflanzenmilch'
    and p.fuer_wen is not distinct from v.fuer_wen
    and p.alternative_slug is not distinct from v.alternative_slug
    and p.alternative_reason is not distinct from v.alternative_reason
    and p.alternative_kind is not distinct from v.alternative_kind;
  if n4_unveraenderte_felder <> 1 then
    raise exception 'N4-Korrektur inkonsistent: unveraenderte N4-Felder weichen von der Audit-Payload ab.';
  end if;

  -- Nachbedingung 4 — die uebrigen neun Pilotzeilen sind unberuehrt.
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
    raise exception 'N4-Korrektur inkonsistent: % der neun uebrigen Pilotzeilen gedriftet.',
      andere_payload_drift;
  end if;

  -- Nachbedingung 5 — neues lastmod fuer genau diese Seite.
  select count(*) into lastmod_neu
  from public.products p
  join cbb_private_backup.n4_content_pre_fix_v1 b on b.id = p.id
  where p.updated_at > b.updated_at;
  if lastmod_neu <> 1 then
    raise exception 'N4-Korrektur inkonsistent: updated_at wurde nicht neu gesetzt.';
  end if;

  -- Nachbedingung 6 — das Backup ist unangetastet geblieben.
  select count(*) into backup_unveraendert
  from cbb_private_backup.n4_content_pre_fix_v1 b
  join cbb_n4_expected_pre e on e.slug = b.slug
  where b.tagline is not distinct from e.tagline
    and b.description is not distinct from e.description
    and b.nicht_fuer is not distinct from e.nicht_fuer
    and b.key_fact is not distinct from e.key_fact
    and b.pros is not distinct from e.pros
    and b.cons is not distinct from e.cons
    and b.editorial_note is not distinct from e.editorial_note;
  if backup_unveraendert <> 1 then
    raise exception 'N4-Korrektur inkonsistent: das Backup wurde veraendert.';
  end if;
end $$;

commit;
