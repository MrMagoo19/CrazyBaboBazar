-- Nach 03_backfill_value_add_batch2.sql: exakt 10 zusaetzliche Zeilen befuellt,
-- sonst nichts. Batch 1 bleibt unangetastet (dafuer zusaetzlich
-- assert_v1_untouched.sql), und ausserhalb der Zielmenge gibt es keinen
-- Kollateralschaden an editorial_note oder updated_at.
do $$
declare
  produkte bigint;
  befuellt_gesamt integer;
  ziel_vollstaendig integer;
  pros_in_spanne integer;
  cons_mindestens_eins integer;
  payload_zeilen integer;
  payload_drift integer;
  alternativen integer;
  ergaenzungen integer;
  ohne_relation integer;
  inkonsistent integer;
  defekte_ziele integer;
  ziel_lastmod_neu integer;
  fremd_drift integer;
  ueberschrieben integer;
  infactory_relationslos integer;
  payload_rls boolean;
  payload_policies integer;
  payload_pk integer;
  payload_spalten integer;
  payload_grants integer;
begin
  select count(*) into produkte from public.products;

  select count(*) into befuellt_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;

  select
    count(*) filter (
      where p.fuer_wen is not null and p.nicht_fuer is not null
        and p.key_fact is not null and p.pros is not null and p.cons is not null
        and p.editorial_note is not null),
    count(*) filter (where array_length(p.pros, 1) between 2 and 4),
    count(*) filter (where array_length(p.cons, 1) >= 1),
    count(*) filter (where p.alternative_kind = 'alternative'),
    count(*) filter (where p.alternative_kind = 'complement'),
    count(*) filter (where p.alternative_kind is null
                       and p.alternative_slug is null
                       and p.alternative_reason is null),
    count(*) filter (
      where not (
        (p.alternative_kind is null and p.alternative_slug is null
          and p.alternative_reason is null)
        or
        (p.alternative_kind in ('alternative', 'complement')
          and p.alternative_slug is not null
          and p.alternative_reason is not null)))
  into ziel_vollstaendig, pros_in_spanne, cons_mindestens_eins,
       alternativen, ergaenzungen, ohne_relation, inkonsistent
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v2 s on s.id = p.id;

  select count(*) into payload_zeilen
  from cbb_private_backup.value_add_payload_v2;

  select count(*) into payload_drift
  from cbb_private_backup.value_add_payload_v2 v
  left join public.products p on p.slug = v.slug
  where p.slug is null
     or p.fuer_wen is distinct from v.fuer_wen
     or p.nicht_fuer is distinct from v.nicht_fuer
     or p.key_fact is distinct from v.key_fact
     or p.pros is distinct from v.pros
     or p.cons is distinct from v.cons
     or p.alternative_slug is distinct from v.alternative_slug
     or p.alternative_reason is distinct from v.alternative_reason
     or p.alternative_kind is distinct from v.alternative_kind
     or p.editorial_note is distinct from v.editorial_note;

  select count(*) into defekte_ziele
  from public.products p
  join cbb_private_backup.value_add_payload_v2 v on v.slug = p.slug
  left join public.products z on z.slug = p.alternative_slug
  where p.alternative_slug is not null
    and (z.slug is null or z.is_published is not true);

  -- Genau die zehn Zielseiten bekommen ein neues lastmod ...
  select count(*) into ziel_lastmod_neu
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  join cbb_private_backup.value_add_payload_v2 v on v.slug = p.slug
  where p.updated_at > b.updated_at;

  -- ... und die 366 anderen Zeilen keines, in keinem der geprueften Felder.
  -- Sonst meldet die Sitemap Google Aenderungen, die es nicht gab.
  select count(*) into fremd_drift
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where p.slug not in (select slug from cbb_private_backup.value_add_payload_v2)
    and (p.updated_at is distinct from b.updated_at
      or p.editorial_note is distinct from b.editorial_note
      or p.fuer_wen is distinct from b.fuer_wen
      or p.nicht_fuer is distinct from b.nicht_fuer
      or p.key_fact is distinct from b.key_fact
      or p.pros is distinct from b.pros
      or p.cons is distinct from b.cons
      or p.alternative_slug is distinct from b.alternative_slug
      or p.alternative_reason is distinct from b.alternative_reason
      or p.alternative_kind is distinct from b.alternative_kind);

  -- Die zwei bewussten Overwrites muessen tatsaechlich stattgefunden haben.
  select count(*) into ueberschrieben
  from public.products p
  join cbb_test_baseline.products_before b on b.id = p.id
  where b.editorial_note is not null
    and p.editorial_note is distinct from b.editorial_note
    and p.slug in ('infactory-boyfriend-kissen',
                   'eiswuerfelform-todesstern-star-wars');

  -- Die bewusste Ausnahme: infactory bleibt strukturell relationslos, weil der
  -- Querverweis bereits im Beschreibungstext steht.
  select count(*) into infactory_relationslos
  from public.products
  where slug = 'infactory-boyfriend-kissen'
    and alternative_slug is null
    and alternative_reason is null
    and alternative_kind is null;

  select c.relrowsecurity,
         (select count(*) from pg_policy pol where pol.polrelid = c.oid),
         (select count(*) from pg_constraint con
            where con.conrelid = c.oid and con.contype = 'p'),
         (select count(*) from pg_attribute a
            where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped)
  into payload_rls, payload_policies, payload_pk, payload_spalten
  from pg_class c
  where c.oid = 'cbb_private_backup.value_add_payload_v2'::regclass;

  select count(*) into payload_grants
  from information_schema.role_table_grants
  where table_schema = 'cbb_private_backup' and table_name = 'value_add_payload_v2'
    and grantee in ('anon', 'authenticated', 'PUBLIC');

  if produkte <> 376 then
    raise exception 'nach 03: % Produkte (erwartet 376).', produkte;
  end if;
  if befuellt_gesamt <> 20 then
    raise exception 'nach 03: % Zeilen mit Value-Add gesamt (erwartet 20 = 10 Batch 1 + 10 Batch 2).',
      befuellt_gesamt;
  end if;
  if ziel_vollstaendig <> 10 then
    raise exception 'nach 03: nur %/10 Batch-2-Zeilen vollstaendig befuellt.', ziel_vollstaendig;
  end if;
  if pros_in_spanne <> 10 or cons_mindestens_eins <> 10 then
    raise exception 'nach 03: % Zeilen mit 2-4 pros, % Zeilen mit >= 1 cons (erwartet 10/10).',
      pros_in_spanne, cons_mindestens_eins;
  end if;
  if payload_zeilen <> 10 or payload_drift <> 0 then
    raise exception 'nach 03: Audit-Payload % Zeilen, % Abweichungen (erwartet 10/0).',
      payload_zeilen, payload_drift;
  end if;
  if alternativen <> 1 or ergaenzungen <> 1 or ohne_relation <> 8 then
    raise exception 'nach 03: Verteilung %/%/% (erwartet 1/1/8).',
      alternativen, ergaenzungen, ohne_relation;
  end if;
  if inkonsistent <> 0 then
    raise exception 'nach 03: % inkonsistente Relationstriplets.', inkonsistent;
  end if;
  if defekte_ziele <> 0 then
    raise exception 'nach 03: % defekte Relationsziele.', defekte_ziele;
  end if;
  if ziel_lastmod_neu <> 10 then
    raise exception 'nach 03: nur %/10 Zielseiten haben ein neueres updated_at.',
      ziel_lastmod_neu;
  end if;
  if fremd_drift <> 0 then
    raise exception 'nach 03: Kollateralschaden in % Zeilen ausserhalb der Zielmenge.',
      fremd_drift;
  end if;
  if ueberschrieben <> 2 then
    raise exception 'nach 03: nur % der 2 bewussten editorial_note-Overwrites erfolgt.',
      ueberschrieben;
  end if;
  if infactory_relationslos <> 1 then
    raise exception 'nach 03: infactory-boyfriend-kissen traegt eine strukturierte Relation — bewusst ausgeschlossen.';
  end if;
  if payload_spalten <> 10 then
    raise exception 'nach 03: value_add_payload_v2 hat % Spalten, erwartet 10.', payload_spalten;
  end if;
  if payload_rls is not true then
    raise exception 'nach 03: RLS auf value_add_payload_v2 ist nicht aktiv.';
  end if;
  if payload_policies <> 0 then
    raise exception 'nach 03: % Policies auf value_add_payload_v2 (erwartet 0).', payload_policies;
  end if;
  if payload_pk <> 1 then
    raise exception 'nach 03: % Primaerschluessel auf value_add_payload_v2 (erwartet 1).', payload_pk;
  end if;
  if payload_grants <> 0 then
    raise exception 'nach 03: % App-Grants auf value_add_payload_v2 (erwartet 0).', payload_grants;
  end if;

  raise notice 'nach 03 OK: 20 befuellt gesamt, Batch 2 10/10 vollstaendig, Payload 10/0, Verteilung 1/1/8, 10 neue lastmods, 0 Kollateralschaden, 2 bewusste Overwrites, infactory relationslos.';
end $$;
