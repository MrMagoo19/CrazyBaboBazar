-- Belegt, dass ein fail-closed abgebrochener Lauf NICHTS hinterlassen hat:
-- der Jobkatalog ist genauso leer wie vorher.
do $$
declare
  jobs bigint;
begin
  select count(*) into jobs from cron.job;
  if jobs <> 0 then
    raise exception 'Nach dem Abbruch: % Job(s) im Katalog (erwartet 0).', jobs;
  end if;
  raise notice 'Nach dem Abbruch OK: Jobkatalog leer, nichts wurde angelegt.';
end $$;
