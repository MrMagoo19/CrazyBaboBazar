-- Zustand nach 03_backfill_value_add_batch3.sql.
-- Bricht bei jeder Abweichung hart ab.
do $$
declare
  vollstaendig integer;
  pros_spanne integer;
  cons_min integer;
  alternativen integer;
  ergaenzungen integer;
  ohne_relation integer;
  inkonsistent integer;
  defekte_ziele integer;
  ziele_relationslos integer;
  value_add_gesamt integer;
  payload_zeilen integer;
  payload_abweichungen integer;
  payload_rls boolean;
  payload_policies integer;
  payload_app_privs integer;
  lastmod_geaendert integer;
  ausserhalb_drift integer;
  relationsliste text;
begin
  select
    count(*) filter (
      where fuer_wen is not null and nicht_fuer is not null and key_fact is not null
        and pros is not null and cons is not null and editorial_note is not null),
    count(*) filter (where pros is not null and array_length(pros, 1) between 2 and 4),
    count(*) filter (where cons is not null and array_length(cons, 1) >= 1),
    count(*) filter (where alternative_kind = 'alternative'),
    count(*) filter (where alternative_kind = 'complement'),
    count(*) filter (
      where alternative_kind is null and alternative_slug is null
        and alternative_reason is null),
    count(*) filter (
      where not (
        (alternative_kind is null and alternative_slug is null and alternative_reason is null)
        or (alternative_kind in ('alternative', 'complement')
            and alternative_slug is not null and alternative_reason is not null))),
    coalesce(string_agg(
      slug || ' -> ' || alternative_slug || ' (' || alternative_kind || ')', ' | '
      order by slug) filter (where alternative_slug is not null), 'KEINE')
  into vollstaendig, pros_spanne, cons_min, alternativen, ergaenzungen,
       ohne_relation, inkonsistent, relationsliste
  from public.products
  where slug in (
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
  );

  if vollstaendig <> 10 or pros_spanne <> 10 or cons_min <> 10 then
    raise exception 'Nach 03: % vollstaendig, % mit 2-4 pros, % mit >= 1 cons (erwartet je 10).',
      vollstaendig, pros_spanne, cons_min;
  end if;
  if alternativen <> 1 or ergaenzungen <> 1 or ohne_relation <> 8 or inkonsistent <> 0 then
    raise exception 'Nach 03: % alternative, % complement, % ohne Relation, % inkonsistent (erwartet 1/1/8/0). Liste: %',
      alternativen, ergaenzungen, ohne_relation, inkonsistent, relationsliste;
  end if;

  select count(*) into defekte_ziele
  from public.products p
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);
  if defekte_ziele <> 0 then
    raise exception 'Nach 03: % Relation(en) zeigen ins Leere.', defekte_ziele;
  end if;

  -- Die Relationen bilden eine Kette: dicmky -> laptop-staender -> tecknet.
  -- Nur ihr ENDE bleibt selbst relationslos — sonst entstuende ein Kreis, den
  -- die Produktseite als endloses Hin und Her rendert. laptop-staender ist
  -- Ziel UND Quelle, das ist gewollt und kein Kreis.
  select count(*) into ziele_relationslos
  from public.products
  where slug in ('tecknet-ergonomische-kabellose-maus-bluetooth')
    and alternative_slug is null and alternative_reason is null
    and alternative_kind is null;
  if ziele_relationslos <> 1 then
    raise exception 'Nach 03: das Kettenende ist nicht relationslos geblieben (%/1).',
      ziele_relationslos;
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 30 then
    raise exception 'Nach 03: % Zeilen mit Value-Add (erwartet 30).', value_add_gesamt;
  end if;

  select count(*),
         count(*) filter (
           where p.slug is null
              or p.fuer_wen is distinct from v.fuer_wen
              or p.nicht_fuer is distinct from v.nicht_fuer
              or p.key_fact is distinct from v.key_fact
              or p.pros is distinct from v.pros
              or p.cons is distinct from v.cons
              or p.alternative_slug is distinct from v.alternative_slug
              or p.alternative_reason is distinct from v.alternative_reason
              or p.alternative_kind is distinct from v.alternative_kind
              or p.editorial_note is distinct from v.editorial_note)
  into payload_zeilen, payload_abweichungen
  from cbb_private_backup.value_add_payload_v3 v
  left join public.products p on p.slug = v.slug;
  if payload_zeilen <> 10 or payload_abweichungen <> 0 then
    raise exception 'Nach 03: Payload % Zeilen, % Abweichungen (erwartet 10/0).',
      payload_zeilen, payload_abweichungen;
  end if;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid)
  into payload_rls, payload_policies
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_payload_v3'::regclass;
  if payload_rls is not true or payload_policies <> 0 then
    raise exception 'Nach 03: Payload RLS %, % Policies (erwartet true/0).',
      payload_rls, payload_policies;
  end if;

  select count(*) into payload_app_privs
  from pg_roles r
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                     ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid,
      'cbb_private_backup.value_add_payload_v3'::regclass::oid, p.priv::text);
  if payload_app_privs <> 0 then
    raise exception 'Nach 03: anon/authenticated haben % Recht(e) auf der Payload.',
      payload_app_privs;
  end if;

  -- Alle zehn Zielzeilen haben einen NEUEN Zeitstempel bekommen.
  select count(*) into lastmod_geaendert
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v3 b on b.id = p.id
  where p.updated_at is distinct from b.updated_at;
  if lastmod_geaendert <> 10 then
    raise exception 'Nach 03: nur %/10 Zielzeilen haben ein neues updated_at.',
      lastmod_geaendert;
  end if;

  -- Ausserhalb der Zielmenge darf sich nichts bewegt haben — auch keine der
  -- 170 bestehenden Fuellprodukt-Notizen.
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
      or p.nicht_fuer is distinct from b.nicht_fuer
      or p.key_fact is distinct from b.key_fact
      or p.pros is distinct from b.pros
      or p.cons is distinct from b.cons
      or p.alternative_slug is distinct from b.alternative_slug
      or p.alternative_reason is distinct from b.alternative_reason
      or p.alternative_kind is distinct from b.alternative_kind);
  if ausserhalb_drift <> 0 then
    raise exception 'Nach 03: % Zeilen ausserhalb der Zielmenge haben sich veraendert.',
      ausserhalb_drift;
  end if;

  raise notice 'Nach 03 OK: 10 vollstaendig, 1 alternative, 1 complement, 8 ohne Relation, 30 gesamt. Relationen: %',
    relationsliste;
end $$;
