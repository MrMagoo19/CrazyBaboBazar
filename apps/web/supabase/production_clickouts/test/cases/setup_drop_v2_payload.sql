-- Negativfall: ein Value-Add-Artefakt fehlt. Der destruktive Rollback darf
-- dann NICHT laufen — wenn fremde Artefakte verschwinden, stimmt etwas
-- anderes nicht, und ein DROP waere fahrlaessig.
drop table cbb_private_backup.value_add_payload_v2;
