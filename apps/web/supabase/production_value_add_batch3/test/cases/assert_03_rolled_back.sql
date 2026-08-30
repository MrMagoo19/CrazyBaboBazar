-- Bricht 03 mitten in der Transaktion ab, muss ALLES zurueckgerollt sein:
-- kein Payload-DDL, keine geschriebene Zeile. Der Snapshot v3 aus 02 bleibt
-- dagegen bestehen — er wurde in einer eigenen, bereits committeten
-- Transaktion angelegt.
do $$
declare
  payload_da boolean;
  snapshot_da boolean;
  ziel_drift integer;
  value_add_gesamt integer;
begin
  select to_regclass('cbb_private_backup.value_add_payload_v3') is not null into payload_da;
  if payload_da then
    raise exception 'Rollback unvollstaendig: die Payload v3 existiert nach dem Abbruch.';
  end if;

  select to_regclass('cbb_private_backup.value_add_pre_backfill_v3') is not null into snapshot_da;
  if not snapshot_da then
    raise exception 'Rollback zu weit: der Snapshot v3 aus dem committeten Schritt 02 fehlt.';
  end if;

  select count(*) into ziel_drift
  from public.products p
  join cbb_private_backup.value_add_pre_backfill_v3 b on b.id = p.id
  where p.editorial_note is distinct from b.editorial_note
     or p.updated_at is distinct from b.updated_at
     or p.fuer_wen is distinct from b.fuer_wen
     or p.nicht_fuer is distinct from b.nicht_fuer
     or p.key_fact is distinct from b.key_fact
     or p.pros is distinct from b.pros
     or p.cons is distinct from b.cons
     or p.alternative_slug is distinct from b.alternative_slug
     or p.alternative_reason is distinct from b.alternative_reason
     or p.alternative_kind is distinct from b.alternative_kind;
  if ziel_drift <> 0 then
    raise exception 'Rollback unvollstaendig: % Zielzeilen weichen vom Snapshot ab.', ziel_drift;
  end if;

  select count(*) into value_add_gesamt from public.products
  where fuer_wen is not null or nicht_fuer is not null or key_fact is not null
     or pros is not null or cons is not null or alternative_slug is not null
     or alternative_reason is not null or alternative_kind is not null;
  if value_add_gesamt <> 20 then
    raise exception 'Rollback unvollstaendig: % Zeilen mit Value-Add (erwartet 20).',
      value_add_gesamt;
  end if;

  raise notice 'Rollback vollstaendig: keine Payload v3, Snapshot erhalten, 20 befuellte Zeilen.';
end $$;
