-- Negativfall: ein Pilot-Marker liegt in der Datenbank. Jeder schreibende
-- Schritt muss dann fail-closed abbrechen, bevor er irgendetwas anlegt.
create schema if not exists pilot_meta;
create table if not exists pilot_meta.environment_guard (id integer primary key);
