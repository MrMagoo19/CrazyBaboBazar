-- Zustand nach 02_create_clickouts.sql. Bricht bei jeder Abweichung hart ab.
do $$
declare
  spalten integer;
  checks integer;
  policies integer;
  rls boolean;
  indizes integer;
  sitzungs_indizes integer;
  app_privs integer;
  service_privs integer;
  service_insert boolean;
  seq_name text;
  seq_app_privs integer;
  seq_service_privs integer;
  seq_service_usage boolean;
  schema_da integer;
  view_da boolean;
  view_optionen text;
  view_sitzung integer;
  funktion integer;
  funktion_secdef boolean;
  funktion_app integer;
  zeilen bigint;
begin
  select count(*) into spalten from pg_attribute
  where attrelid = 'public.click_outs'::regclass and attnum > 0 and not attisdropped;
  if spalten <> 7 then
    raise exception 'Nach 02: % Spalten (erwartet 7).', spalten;
  end if;

  select count(*) into checks from pg_constraint
  where conrelid = 'public.click_outs'::regclass and contype = 'c';
  if checks <> 5 then
    raise exception 'Nach 02: % CHECK-Constraints (erwartet 5).', checks;
  end if;

  select c.relrowsecurity into rls from pg_class c
  where c.oid = 'public.click_outs'::regclass;
  select count(*) into policies from pg_policy
  where polrelid = 'public.click_outs'::regclass;
  if rls is not true or policies <> 0 then
    raise exception 'Nach 02: RLS % / % Policies (erwartet true / 0).', rls, policies;
  end if;

  select count(*) into indizes from pg_index where indrelid = 'public.click_outs'::regclass;
  if indizes <> 3 then
    raise exception 'Nach 02: % Indizes (erwartet 3).', indizes;
  end if;

  -- Ein Index auf der Sitzungskennung waere nur fuer die Rekonstruktion
  -- einzelner Klickfolgen nuetzlich. Er darf nicht existieren.
  select count(*) into sitzungs_indizes
  from pg_index i
  join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey)
  where i.indrelid = 'public.click_outs'::regclass
    and a.attname = 'consented_session_id';
  if sitzungs_indizes <> 0 then
    raise exception 'Nach 02: % Index/Indizes auf consented_session_id (erwartet 0).',
      sitzungs_indizes;
  end if;

  select count(*) into app_privs
  from pg_roles r
  cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                     ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_table_privilege(r.oid, 'public.click_outs'::regclass::oid, p.priv::text);
  if app_privs <> 0 then
    raise exception 'Nach 02: anon/authenticated haben % Recht(e) (erwartet 0).', app_privs;
  end if;

  select count(*) into service_privs
  from (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
               ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
  where has_table_privilege('service_role', 'public.click_outs'::regclass::oid, p.priv::text);
  select has_table_privilege('service_role', 'public.click_outs'::regclass::oid, 'INSERT')
  into service_insert;
  if service_privs <> 1 or not service_insert then
    raise exception 'Nach 02: service_role hat % Recht(e), INSERT = % (erwartet 1 / true).',
      service_privs, service_insert;
  end if;

  -- Die Identity-Sequenz ist ein eigenes Objekt mit eigener ACL. Ohne Entzug
  -- gaebe `last_value` den Klick-Zaehler preis, obwohl die Tabelle dicht ist.
  select pg_get_serial_sequence('public.click_outs', 'id') into seq_name;
  if seq_name is distinct from 'public.click_outs_id_seq' then
    raise exception 'Nach 02: Identity-Sequenz heisst % (erwartet public.click_outs_id_seq).',
      coalesce(seq_name, 'keine');
  end if;

  select count(*) into seq_app_privs
  from pg_roles r
  cross join (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
  where r.rolname in ('anon', 'authenticated')
    and has_sequence_privilege(r.oid, 'public.click_outs_id_seq'::regclass::oid, p.priv::text);
  if seq_app_privs <> 0 then
    raise exception 'Nach 02: anon/authenticated haben % Sequenzrecht(e) (erwartet 0).',
      seq_app_privs;
  end if;

  select count(*) into seq_service_privs
  from (values ('SELECT'), ('UPDATE'), ('USAGE')) as p(priv)
  where has_sequence_privilege('service_role', 'public.click_outs_id_seq'::regclass::oid, p.priv::text);
  select has_sequence_privilege('service_role', 'public.click_outs_id_seq'::regclass::oid, 'USAGE')
  into seq_service_usage;
  if seq_service_privs <> 1 or not seq_service_usage then
    raise exception 'Nach 02: service_role hat % Sequenzrecht(e), USAGE = % (erwartet 1 / true).',
      seq_service_privs, seq_service_usage;
  end if;

  select count(*) into schema_da from pg_namespace where nspname = 'cbb_private_analytics';
  if schema_da <> 1 then
    raise exception 'Nach 02: Auswertungsschema fehlt.';
  end if;

  select to_regclass('cbb_private_analytics.click_outs_daily') is not null into view_da;
  select coalesce(array_to_string(c.reloptions, ','), '') into view_optionen
  from pg_class c where c.oid = to_regclass('cbb_private_analytics.click_outs_daily');
  if not view_da or view_optionen not like '%security_invoker=true%' then
    raise exception 'Nach 02: View % / Optionen % (erwartet true / security_invoker=true).',
      view_da, view_optionen;
  end if;

  select count(*) into view_sitzung from pg_attribute
  where attrelid = to_regclass('cbb_private_analytics.click_outs_daily')
    and attnum > 0 and not attisdropped and attname = 'consented_session_id';
  if view_sitzung <> 0 then
    raise exception 'Nach 02: die View gibt die Sitzungskennung aus.';
  end if;

  select count(*), coalesce(bool_and(p.prosecdef), false) into funktion, funktion_secdef
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs';
  if funktion <> 1 or not funktion_secdef then
    raise exception 'Nach 02: % Retention-Funktion(en), security definer % (erwartet 1 / true).',
      funktion, funktion_secdef;
  end if;

  select count(*) into funktion_app
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  cross join (values ('anon'), ('authenticated')) as r(rolle)
  where n.nspname = 'cbb_private_analytics' and p.proname = 'purge_click_outs'
    and has_function_privilege(r.rolle::text, p.oid, 'EXECUTE');
  if funktion_app <> 0 then
    raise exception 'Nach 02: App-Rollen duerfen die Retention-Funktion ausfuehren.';
  end if;

  select count(*) into zeilen from public.click_outs;
  if zeilen <> 0 then
    raise exception 'Nach 02: % Zeile(n) in click_outs (erwartet 0).', zeilen;
  end if;

  raise notice 'Nach 02 OK: 7 Spalten, 5 CHECKs, RLS ohne Policy, 3 Indizes, service_role nur INSERT, Sequenz nur USAGE.';
end $$;
