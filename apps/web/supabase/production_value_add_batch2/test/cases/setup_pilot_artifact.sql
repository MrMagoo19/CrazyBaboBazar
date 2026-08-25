-- Simuliert eine Pilot-DB: der negative Guard in 02, 03 und 05 muss anschlagen.
create schema if not exists pilot_meta;
create table if not exists pilot_meta.environment_guard (
  project_ref text primary key,
  created_at timestamptz not null default now()
);
insert into pilot_meta.environment_guard (project_ref)
values ('nmzuycveumyfvtxdcnuc')
on conflict do nothing;
