-- Zustand nach 02_backup_value_add_batch3.sql.
-- Bricht bei jeder Abweichung hart ab.
do $$
declare
  zeilen integer;
  spalten integer;
  spalten_erwartet integer;
  slugs_fehlend integer;
  slugs_zusaetzlich integer;
  value_add integer;
  notes integer;
  distinct_updated integer;
  rls boolean;
  policies integer;
  pk integer;
  uniq integer;
  app_privs integer;
  drift integer;
  payload_v3 boolean;
  ausserhalb_drift integer;
begin
  select count(*) into zeilen from cbb_private_backup.value_add_pre_backfill_v3;
  if zeilen <> 10 then
    raise exception 'Nach 02: %/10 Snapshot-Zeilen.', zeilen;
  end if;

  select count(*),
         count(*) filter (where attname in (
           'id', 'slug', 'editorial_note', 'updated_at', 'fuer_wen', 'nicht_fuer',
           'key_fact', 'pros', 'cons', 'alternative_slug', 'alternative_reason',
           'alternative_kind'))
  into spalten, spalten_erwartet
  from pg_attribute
  where attrelid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass
    and attnum > 0 and not attisdropped;
  if spalten <> 12 or spalten_erwartet <> 12 then
    raise exception 'Nach 02: % Spalten, davon % erwartet (jeweils 12 verlangt).',
      spalten, spalten_erwartet;
  end if;

  select
    (select count(*) from (values
      ('bartesian-cocktailmaschine-mit-kapseln'),
      ('dicmky-hoehenverstellbarer-schreibtisch-aufsatz'),
      ('laptop-staender-hoehenverstellbar-360-drehbar'),
      ('tecknet-ergonomische-kabellose-maus-bluetooth'),
      ('rocketbook-wiederverwendbares-notizbuch-a4'),
      ('ticktime-tk3-wuerfel-timer-countdown'),
      ('kabeltasche-edc-elektronik-organizer-reise'),
      ('silikon-magnete-airfryer-backpapier-4er-set'),
      ('tre-feuerstahl-xxl'),
      ('bbq-wuerstchenhalter-maennchen-3er-set')
    ) as t(slug)
    where not exists (
      select 1 from cbb_private_backup.value_add_pre_backfill_v3 b where b.slug = t.slug
    )),
    (select count(*) from cbb_private_backup.value_add_pre_backfill_v3 b
     where b.slug not in (
      'bartesian-cocktailmaschine-mit-kapseln',
      'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
      'laptop-staender-hoehenverstellbar-360-drehbar',
      'tecknet-ergonomische-kabellose-maus-bluetooth',
      'rocketbook-wiederverwendbares-notizbuch-a4',
      'ticktime-tk3-wuerfel-timer-countdown',
      'kabeltasche-edc-elektronik-organizer-reise',
      'silikon-magnete-airfryer-backpapier-4er-set',
      'tre-feuerstahl-xxl',
      'bbq-wuerstchenhalter-maennchen-3er-set'
    ))
  into slugs_fehlend, slugs_zusaetzlich;
  if slugs_fehlend <> 0 or slugs_zusaetzlich <> 0 then
    raise exception 'Nach 02: % Slug(s) fehlen, % zusaetzlich.',
      slugs_fehlend, slugs_zusaetzlich;
  end if;

  select
    count(*) filter (
      where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
         or pros is not null or cons is not null or alternative_slug is not null
         or alternative_reason is not null or alternative_kind is not null),
    count(*) filter (where editorial_note is not null),
    count(distinct updated_at)
  into value_add, notes, distinct_updated
  from cbb_private_backup.value_add_pre_backfill_v3;
  if value_add <> 0 then
    raise exception 'Nach 02: % Snapshot-Zeilen tragen bereits Value-Add-Daten.', value_add;
  end if;
  -- Der Snapshot muss die ZEHN unterschiedlichen Originalzeitstempel und alle
  -- zehn Originalnotizen tragen — sonst kann 05 sie nicht exakt zurueckspielen.
  if notes <> 10 or distinct_updated <> 10 then
    raise exception 'Nach 02: % Notizen und % unterschiedliche Zeitstempel (erwartet je 10).',
      notes, distinct_updated;
  end if;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid),
         (select count(*) from pg_constraint con
           where con.conrelid = c.oid and con.contype = 'p'),
         (select count(*) from pg_constraint con
           where con.conrelid = c.oid and con.contype = 'u')
  into rls, policies, pk, uniq
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_pre_backfill_v3'::regclass;
  if rls is not true or policies <> 0 or pk <> 1 or uniq <> 1 then
    raise exception 'Nach 02: RLS %, % Policies, % PK, % UNIQUE (erwartet true/0/1/1).',
      rls, policies, pk, uniq;
  end if;

  select count(*) into app_privs
  from pg_roles r
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                     ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid,
      'cbb_private_backup.value_add_pre_backfill_v3'::regclass::oid, p.priv::text);
  if app_privs <> 0 then
    raise exception 'Nach 02: anon/authenticated haben % Recht(e) auf dem Snapshot.', app_privs;
  end if;

  select count(*) into drift
  from cbb_private_backup.value_add_pre_backfill_v3 b
  left join public.products p on p.id = b.id
  where p.id is null
     or p.slug is distinct from b.slug
     or p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at;
  if drift <> 0 then
    raise exception 'Nach 02: % Snapshot-Zeilen weichen vom Bestand ab.', drift;
  end if;

  select to_regclass('cbb_private_backup.value_add_payload_v3') is not null into payload_v3;
  if payload_v3 then
    raise exception 'Nach 02: die Audit-Payload v3 existiert bereits — 02 darf sie nicht anlegen.';
  end if;

  -- Nichts ausserhalb der Zielmenge darf sich bewegt haben.
  select count(*) into ausserhalb_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug not in (
      'bartesian-cocktailmaschine-mit-kapseln',
      'dicmky-hoehenverstellbarer-schreibtisch-aufsatz',
      'laptop-staender-hoehenverstellbar-360-drehbar',
      'tecknet-ergonomische-kabellose-maus-bluetooth',
      'rocketbook-wiederverwendbares-notizbuch-a4',
      'ticktime-tk3-wuerfel-timer-countdown',
      'kabeltasche-edc-elektronik-organizer-reise',
      'silikon-magnete-airfryer-backpapier-4er-set',
      'tre-feuerstahl-xxl',
      'bbq-wuerstchenhalter-maennchen-3er-set')
    and (p.editorial_note is distinct from b.editorial_note
      or p.updated_at is distinct from b.updated_at
      or p.fuer_wen is distinct from b.fuer_wen
      or p.pros is distinct from b.pros
      or p.alternative_slug is distinct from b.alternative_slug);
  if ausserhalb_drift <> 0 then
    raise exception 'Nach 02: % Zeilen ausserhalb der Zielmenge haben sich veraendert.',
      ausserhalb_drift;
  end if;

  raise notice 'Nach 02 OK: Snapshot 10/12, 10 Notizen, 10 Zeitstempel, RLS an, keine App-Rechte, 0 Drift.';
end $$;
