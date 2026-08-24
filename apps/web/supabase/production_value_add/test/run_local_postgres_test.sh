#!/usr/bin/env bash
# =============================================================================
# LOKALER POSTGRESQL-HARNESS FUER DEN VALUE-ADD-ROLLOUT
# =============================================================================
# Testet die ORIGINALDATEIEN 01_preflight_read_only.sql bis 07_down_migration.sql
# gegen eine echte PostgreSQL-16-Instanz mit einer production-aehnlichen Fixture.
#
# Der Harness fasst KEINE Production- und KEINE Pilot-Datenbank an. Er startet
# einen eigenen Cluster in einem temporaeren Verzeichnis, der ausschliesslich
# ueber einen Unix-Socket erreichbar ist (listen_addresses='') und den er am
# Ende wieder stoppt. Keine der Dateien 01-07 wird veraendert.
#
# Schaerfe der Erwartungen (Stand nach dem Codex-Review):
#   * Ein erwarteter Abbruch gilt NUR dann als PASS, wenn psql mit Exit 3
#     zurueckkommt UND die konkrete erwartete Servermeldung im Output steht.
#     Ein anderer Fehler ist FAIL, kein PASS.
#   * report_table verlangt fuer 01 exakt 9 PASS/0 FAIL und fuer 05 exakt
#     14 PASS/0 FAIL. "mehr als 0 PASS" reicht nicht.
#   * Der Lock-Test verlangt Exit 3, die Meldung
#     "canceling statement due to lock timeout" und eine Laufzeit um 5 s.
#     Exit 124 (Client-Timeout), ein anderer Text oder ein Erfolg sind FAIL.
#     Es gibt kein "BEFUND"-Ergebnis mehr, das trotzdem Gesamt-PASS ergibt.
#   * Zusaetzlich wird statisch geprueft, dass in 02, 03, 04, 06 und 07 beide
#     SET-LOCAL-Zeilen direkt hinter "begin;" und vor dem ersten DO-Block
#     stehen (nur Kommentare/Leerzeilen dazwischen) und dass es keine
#     spaeteren Duplikate gibt.
#
# Aufruf:
#   ./run_local_postgres_test.sh                # alles, Cluster danach entfernt
#   CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh   # Datenverzeichnis behalten
#   CBB_PG_BIN=/pfad/zu/postgresql/16 ./run_local_postgres_test.sh
#   CBB_PG_BIN=/pfad/zu/postgresql/16/bin ./run_local_postgres_test.sh
#     Beide Formen sind erlaubt: ein PostgreSQL-Prefix, das ein bin/ enthaelt,
#     oder direkt das bin-Verzeichnis. Ohne den Override loest der Harness die
#     Binaries selbst auf (pg_config, dann initdb im PATH, dann der uebliche
#     Distributionspfad, falls er existiert).
#
# Exit-Code 0 = alle Erwartungen erfuellt, 1 = mindestens eine Abweichung,
# 2 = Umgebungsproblem (Binaries, initdb, Serverstart, createdb).
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$(cd "$HERE/.." && pwd)"          # production_value_add/
REPO_SUPABASE="$(cd "$SQL_DIR/.." && pwd)" # apps/web/supabase/

# -----------------------------------------------------------------------------
# Aufloesung der PostgreSQL-Binaries
# -----------------------------------------------------------------------------
# Ergebnis ist immer PG_BINDIR — das Verzeichnis, in dem initdb, pg_ctl, psql,
# createdb und postgres liegen. Reihenfolge:
#   1. CBB_PG_BIN, der explizite Override. Aus Rueckwaertskompatibilitaet darf
#      er auf ein Prefix mit bin/ ODER direkt auf das bin-Verzeichnis zeigen.
#   2. pg_config --bindir, falls pg_config im PATH liegt.
#   3. Das Verzeichnis von initdb, falls initdb im PATH liegt.
#   4. Der uebliche Distributionspfad /usr/lib/postgresql/16/bin — aber nur,
#      wenn er wirklich existiert. Es gibt bewusst keinen fest verdrahteten
#      /tmp-Default mehr; ein solcher Pfad ist nach einem Reboot tot.
PG_BINDIR=""
if [[ -n "${CBB_PG_BIN:-}" ]]; then
  if [[ -x "${CBB_PG_BIN%/}/bin/initdb" ]]; then
    PG_BINDIR="${CBB_PG_BIN%/}/bin"
  else
    PG_BINDIR="${CBB_PG_BIN%/}"
  fi
elif command -v pg_config >/dev/null 2>&1; then
  PG_BINDIR="$(pg_config --bindir 2>/dev/null)"
elif command -v initdb >/dev/null 2>&1; then
  PG_BINDIR="$(cd "$(dirname "$(command -v initdb)")" && pwd)"
elif [[ -x /usr/lib/postgresql/16/bin/initdb ]]; then
  PG_BINDIR="/usr/lib/postgresql/16/bin"
fi

# Liegen die Binaries in einem entpackten Paketbaum statt in einer echten
# Systeminstallation, dann steht libpq.so.5 irgendwo im selben Baum und wird
# ohne LD_LIBRARY_PATH nicht gefunden (initdb bricht sonst mit Exit 127 ab).
# Ein Paketbaum ist daran erkennbar, dass dem Distributionspfad noch ein
# Wurzelpraefix vorangestellt ist; bei einer Systeminstallation bleibt der
# abgeschnittene Rest leer und die Suche entfaellt.
PG_TREE_ROOT=""
case "${PG_BINDIR:-}" in
  */usr/lib/postgresql/*/bin) PG_TREE_ROOT="${PG_BINDIR%/usr/lib/postgresql/*/bin}" ;;
  */usr/bin)                  PG_TREE_ROOT="${PG_BINDIR%/usr/bin}" ;;
  */usr/local/pgsql/bin)      PG_TREE_ROOT="${PG_BINDIR%/usr/local/pgsql/bin}" ;;
esac
if [[ -n "$PG_TREE_ROOT" && "$PG_TREE_ROOT" != "/" && -d "$PG_TREE_ROOT" ]]; then
  PG_LIBPQ="$(find "$PG_TREE_ROOT" -name 'libpq.so.5' -print -quit 2>/dev/null)"
  if [[ -n "$PG_LIBPQ" ]]; then
    PG_LIBDIR="$(dirname "$PG_LIBPQ")"
    export LD_LIBRARY_PATH="$PG_LIBDIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi
fi

if [[ -z "$PG_BINDIR" ]]; then
  echo "PostgreSQL-Binaries nicht gefunden." >&2
  echo "CBB_PG_BIN ist nicht gesetzt und weder pg_config noch initdb liegen im PATH." >&2
  echo "Beispiel: CBB_PG_BIN=/usr/lib/postgresql/16 $0" >&2
  echo "  oder:   CBB_PG_BIN=/usr/lib/postgresql/16/bin $0" >&2
  exit 2
fi

INITDB="$PG_BINDIR/initdb"
PG_CTL="$PG_BINDIR/pg_ctl"
PSQL="$PG_BINDIR/psql"
CREATEDB="$PG_BINDIR/createdb"
POSTGRES="$PG_BINDIR/postgres"

for exe in "$INITDB" "$PG_CTL" "$PSQL" "$CREATEDB" "$POSTGRES"; do
  if [[ ! -x "$exe" ]]; then
    echo "FEHLT: $exe" >&2
    echo "In $PG_BINDIR liegt keine vollstaendige PostgreSQL-Installation." >&2
    echo "Beispiel: CBB_PG_BIN=/usr/lib/postgresql/16 $0" >&2
    echo "  oder:   CBB_PG_BIN=/usr/lib/postgresql/16/bin $0" >&2
    exit 2
  fi
done

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cbb-pgtest.XXXXXXXX")"
PGDATA="$WORKDIR/data"
SOCKDIR="$WORKDIR/sock"
LOGDIR="$WORKDIR/logs"
SERVERLOG="$WORKDIR/postgres.log"
RESULTS="$WORKDIR/results.tsv"
mkdir -p "$SOCKDIR" "$LOGDIR"

# Eindeutiger application_name fuer den Lock-Halter in CASE J. Ueber ihn wird
# der Backend-Prozess spaeter per pg_terminate_backend zuverlaessig beendet —
# ein kill des psql-Clients wuerde den Server-Backend nicht garantiert loesen.
LOCK_APP="cbb_lock_holder_$(basename "$WORKDIR")"

# Englische Servermeldungen, damit die Erwartungs-Pattern stabil bleiben.
export LC_MESSAGES=C
export PGHOST="$SOCKDIR"
export PGUSER=postgres
export PGDATABASE=postgres

STEP=0
FAILURES=0
CURRENT_CASE="-"

printf 'case\tstep\tlabel\tfile\texpect\texit\tverdict\tdetail\n' > "$RESULTS"

log()  { printf '%s\n' "$*"; }
head1() { printf '\n=== %s ===\n' "$*"; }

fail_setup() {
  log ""
  log "SETUP-ABBRUCH: $*"
  exit 2
}

cleanup() {
  # Falls der Lock-Halter aus CASE J noch lebt, zuerst sein Backend beenden.
  if "$PG_CTL" -D "$PGDATA" status >/dev/null 2>&1; then
    "$PSQL" -X -q -A -t -d postgres -c \
      "select pg_terminate_backend(pid) from pg_stat_activity
       where application_name = '$LOCK_APP'" >/dev/null 2>&1
    log ""
    log "-> PostgreSQL wird gestoppt (pg_ctl stop -m fast)"
    "$PG_CTL" -D "$PGDATA" -m fast stop >/dev/null 2>&1
    log "   pg_ctl stop exit=$?"
  fi
  if [[ "${CBB_KEEP_CLUSTER:-0}" == "1" ]]; then
    log "   Cluster behalten: $WORKDIR"
  else
    cp "$RESULTS" "$WORKDIR.results.tsv" 2>/dev/null || true
    rm -rf "$PGDATA" "$SOCKDIR"
    log "   PGDATA und Socketverzeichnis entfernt, Logs bleiben unter: $WORKDIR"
    if [[ -e "$PGDATA" || -e "$SOCKDIR" ]]; then
      log "   WARNUNG: PGDATA oder Socketverzeichnis liess sich nicht entfernen."
    fi
  fi
}
trap cleanup EXIT

record() {
  # record <label> <file> <expect> <exit> <verdict> <detail>
  printf '%s\t%03d\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$CURRENT_CASE" "$STEP" "$1" "$2" "$3" "$4" "$5" \
    "$(printf '%s' "$6" | tr '\t\n' '  ' | cut -c1-220)" >> "$RESULTS"
  printf '  [%s] %-42s expect=%-9s exit=%-3s %s\n' "$5" "$1" "$3" "$4" "$2"
  [[ -n "$6" ]] && printf '           %s\n' "$6"
}

mark_fail() { FAILURES=$((FAILURES + 1)); }

# ---------------------------------------------------------------------------
# step <db> <expect: ok|fail> <label> <sql-datei> [erwartetes-fehler-literal]
#
#   expect=ok    -> psql muss mit Exit 0 zurueckkommen.
#   expect=fail  -> psql muss mit Exit 3 zurueckkommen (Server-Exception bei
#                   ON_ERROR_STOP=1) UND das uebergebene Literal muss im
#                   Output stehen. Das Literal ist PFLICHT: fehlt es, ist der
#                   Schritt FAIL. Ein anderer Fehler als der erwartete ist
#                   ebenfalls FAIL — "irgendein Exit != 0" reicht nicht mehr.
# ---------------------------------------------------------------------------
step() {
  local db="$1" expect="$2" label="$3" file="$4" want="${5:-}"
  STEP=$((STEP + 1))
  local out="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}.log"
  local rc=0

  "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$file" > "$out" 2>&1 || rc=$?

  local server_msg
  server_msg="$(grep -m1 -E '^(psql:.*(ERROR|FATAL)|ERROR|NOTICE)' "$out" | cut -c1-200)"
  [[ -z "$server_msg" ]] && server_msg="$(tail -n 1 "$out" | cut -c1-200)"

  local verdict detail expect_label
  if [[ "$expect" == "ok" ]]; then
    expect_label="ok/0"
    if [[ $rc -eq 0 ]]; then
      verdict=PASS
      detail="$server_msg"
    else
      verdict=FAIL
      mark_fail
      detail="unerwarteter Abbruch (exit=$rc): $server_msg"
    fi
  else
    expect_label="fail/3"
    if [[ -z "$want" ]]; then
      verdict=FAIL
      mark_fail
      detail="HARNESS-FEHLER: kein erwartetes Fehler-Literal angegeben (exit=$rc)"
    elif [[ $rc -ne 3 ]]; then
      verdict=FAIL
      mark_fail
      if [[ $rc -eq 0 ]]; then
        detail="lief durch, erwartet war Exit 3 mit: $want"
      else
        detail="Exit $rc statt 3 (erwartet: $want) — $server_msg"
      fi
    elif ! grep -Fq -- "$want" "$out"; then
      verdict=FAIL
      mark_fail
      detail="falscher Fehler. erwartet: <$want> | tatsaechlich: $server_msg"
    else
      verdict=PASS
      detail="erwarteter Abbruch: $want"
    fi
  fi

  record "$label" "$(basename "$file")" "$expect_label" "$rc" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# report_table <db> <label> <sql-datei> <erwartete-PASS-zeilen>
#   Fuer 01 und 05: beide sind read-only und melden Probleme NICHT ueber den
#   Exit-Code, sondern als Zeile mit status = FAIL. Verlangt wird jetzt die
#   EXAKTE Zahl an PASS-Zeilen (01: 9, 05: 14) und 0 FAIL-Zeilen. Eine
#   geschrumpfte Pruefliste faellt damit auf, statt als PASS durchzugehen.
# ---------------------------------------------------------------------------
report_table() {
  local db="$1" label="$2" file="$3" want_pass="$4"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local rc=0

  "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$file" > "$base.txt" 2>&1 || rc=$?
  "$PSQL" -X -q -A -F '|' -t -v ON_ERROR_STOP=1 -d "$db" -f "$file" \
    > "$base.psv" 2>&1 || true

  local failrows=0 passrows=0
  if [[ $rc -eq 0 ]]; then
    failrows="$(grep -c '|FAIL$' "$base.psv" || true)"
    passrows="$(grep -c '|PASS$' "$base.psv" || true)"
  fi

  local verdict detail
  if [[ $rc -eq 0 && "$failrows" -eq 0 && "$passrows" -eq "$want_pass" ]]; then
    verdict=PASS
    detail="exakt $passrows PASS-Zeilen, 0 FAIL-Zeilen -> $base.txt"
  else
    verdict=FAIL
    mark_fail
    detail="exit=$rc, $passrows PASS (erwartet $want_pass), $failrows FAIL (erwartet 0) -> $base.txt"
  fi

  record "$label" "$(basename "$file")" "${want_pass}xPASS/0xFAIL" "$rc" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# static_set_local <sql-datei>
#   Statischer Beweis, dass "set local lock_timeout" und
#   "set local statement_timeout" genau einmal vorkommen, direkt hinter
#   "begin;" stehen (nur Kommentar-/Leerzeilen dazwischen, keine Anweisung)
#   und vor dem ersten DO-Block liegen.
# ---------------------------------------------------------------------------
static_set_local() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="static_$(basename "$file" .sql)"
  local res
  res="$(awk '
    { a[NR] = $0 }
    /^begin;[ \t]*$/                                 { begin_n++; if (begin_l == 0) begin_l = NR }
    /^[ \t]*set[ \t]+local[ \t]/                     { setlocal_n++ }
    /^set local lock_timeout = .5s.;[ \t]*$/         { lock_n++; if (lock_l == 0) lock_l = NR }
    /^set local statement_timeout = .60s.;[ \t]*$/   { stmt_n++; if (stmt_l == 0) stmt_l = NR }
    /^[ \t]*do[ \t]*\$\$/                            { if (do_l == 0) do_l = NR }
    END {
      p = ""
      if (begin_n != 1)    p = p sprintf("begin;-Zeilen=%d (erwartet 1); ", begin_n)
      if (lock_n != 1)     p = p sprintf("lock_timeout-Zeilen=%d (erwartet 1); ", lock_n)
      if (stmt_n != 1)     p = p sprintf("statement_timeout-Zeilen=%d (erwartet 1); ", stmt_n)
      if (setlocal_n != 2) p = p sprintf("SET-LOCAL-Zeilen gesamt=%d (erwartet 2, keine Duplikate); ", setlocal_n)
      if (do_l == 0)       p = p "kein DO-Block gefunden; "
      if (begin_l == 0 || lock_l == 0 || stmt_l == 0) {
        p = p "Pflichtzeile fehlt; "
      } else {
        if (lock_l <= begin_l)
          p = p sprintf("lock_timeout (Z%d) nicht hinter begin; (Z%d); ", lock_l, begin_l)
        if (stmt_l != lock_l + 1)
          p = p sprintf("statement_timeout (Z%d) nicht direkt hinter lock_timeout (Z%d); ", stmt_l, lock_l)
        if (do_l > 0 && do_l <= stmt_l)
          p = p sprintf("erster DO-Block (Z%d) liegt vor den SET LOCAL (Z%d); ", do_l, stmt_l)
        for (i = begin_l + 1; i < lock_l; i++) {
          l = a[i]
          gsub(/^[ \t]+/, "", l); gsub(/[ \t]+$/, "", l)
          if (l != "" && substr(l, 1, 2) != "--") {
            p = p sprintf("Anweisung in Z%d zwischen begin; und SET LOCAL; ", i)
            break
          }
        }
      }
      if (p == "")
        printf "OK|begin;=Z%d, set local=Z%d+Z%d, erster DO-Block=Z%d\n", begin_l, lock_l, stmt_l, do_l
      else
        printf "PROBLEM|%s\n", p
    }
  ' "$file")"

  local verdict detail
  if [[ "$res" == OK\|* ]]; then
    verdict=PASS
    detail="${res#OK|}"
  else
    verdict=FAIL
    mark_fail
    detail="${res#PROBLEM|}"
  fi
  record "$label" "$(basename "$file")" "SET-LOCAL-Position" "-" "$verdict" "$detail"
  return 0
}

new_case() {
  CURRENT_CASE="$1"
  head1 "$1 — $2"
  "$CREATEDB" -T cbb_fixture "$1" \
    || fail_setup "createdb -T cbb_fixture $1 fehlgeschlagen — Folgeergebnisse waeren wertlos."
}

# ===========================================================================
# CASE 0 — Statische Pruefung der SET-LOCAL-Position (ohne Cluster)
# ===========================================================================
head1 "case_0_statisch — SET LOCAL direkt hinter begin;, vor dem ersten DO-Block"
CURRENT_CASE=case_0_statisch
static_set_local "$SQL_DIR/02_migrate_value_add.sql"
static_set_local "$SQL_DIR/03_backup_value_add.sql"
static_set_local "$SQL_DIR/04_backfill_value_add.sql"
static_set_local "$SQL_DIR/06_restore_value_add.sql"
static_set_local "$SQL_DIR/07_down_migration.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: SET-LOCAL-Position stimmt nicht — der Lock-Test waere nicht aussagekraeftig."
  exit 1
fi

# ===========================================================================
# 1) Cluster aufsetzen — fail closed
# ===========================================================================
head1 "Cluster"
log "PostgreSQL: $("$POSTGRES" --version)"
log "Workdir:    $WORKDIR"

INITDB_RC=0
"$INITDB" -D "$PGDATA" -U postgres --auth=trust --encoding=UTF8 \
  --locale=C.UTF-8 > "$WORKDIR/initdb.log" 2>&1 || INITDB_RC=$?
log "initdb exit=$INITDB_RC"
if [[ $INITDB_RC -ne 0 ]]; then
  cat "$WORKDIR/initdb.log" >&2
  fail_setup "initdb fehlgeschlagen (exit=$INITDB_RC)."
fi

PGCTL_RC=0
"$PG_CTL" -D "$PGDATA" -l "$SERVERLOG" -w \
  -o "-k $SOCKDIR -c listen_addresses='' -c lc_messages=C -c log_min_messages=warning" \
  start > "$WORKDIR/pgctl_start.log" 2>&1 || PGCTL_RC=$?
log "pg_ctl start exit=$PGCTL_RC (Unix-Socket $SOCKDIR, kein TCP)"
if [[ $PGCTL_RC -ne 0 ]]; then
  cat "$WORKDIR/pgctl_start.log" >&2
  cat "$SERVERLOG" >&2
  fail_setup "pg_ctl start fehlgeschlagen (exit=$PGCTL_RC)."
fi

# ===========================================================================
# 2) Fixture-Datenbank bauen
# ===========================================================================
head1 "Fixture"
CURRENT_CASE=fixture
CREATEDB_RC=0
"$CREATEDB" cbb_fixture || CREATEDB_RC=$?
log "createdb cbb_fixture exit=$CREATEDB_RC"
if [[ $CREATEDB_RC -ne 0 ]]; then
  fail_setup "createdb cbb_fixture fehlgeschlagen (exit=$CREATEDB_RC)."
fi

step cbb_fixture ok fixture_roles        "$HERE/fixture/00_roles.sql"
step cbb_fixture ok fixture_schema       "$HERE/fixture/01_schema.sql"
step cbb_fixture ok fixture_seed         "$HERE/fixture/02_seed.sql"
step cbb_fixture ok fixture_real_trigger "$REPO_SUPABASE/seo_updated_at_trigger.sql"
step cbb_fixture ok fixture_assert       "$HERE/fixture/03_assert_fixture.sql"
step cbb_fixture ok fixture_baseline     "$HERE/fixture/04_baseline.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: Fixture ist nicht sauber, weitere Ergebnisse waeren wertlos."
  exit 1
fi

# ===========================================================================
# CASE A — Happy Path 01 -> 05 in der vorgesehenen Reihenfolge
# ===========================================================================
new_case case_a_happy_path "01 bis 05 in Reihenfolge"
report_table case_a_happy_path a_01_preflight_vor_migration "$SQL_DIR/01_preflight_read_only.sql" 9
step case_a_happy_path ok  a_02_migrate       "$SQL_DIR/02_migrate_value_add.sql"
step case_a_happy_path ok  a_02_assert        "$HERE/cases/assert_after_02.sql"
step case_a_happy_path ok  a_03_backup        "$SQL_DIR/03_backup_value_add.sql"
step case_a_happy_path ok  a_03_assert        "$HERE/cases/assert_after_03.sql"
step case_a_happy_path ok  a_04_backfill      "$SQL_DIR/04_backfill_value_add.sql"
step case_a_happy_path ok  a_04_assert        "$HERE/cases/assert_after_04.sql"
report_table case_a_happy_path a_05_verify_nach_backfill "$SQL_DIR/05_verify_read_only.sql" 14

# ===========================================================================
# CASE B — Fail-closed-Wiederholungen auf dem fertigen Zustand
# ===========================================================================
new_case case_b_wiederholungen "Doppelausfuehrung jeder schreibenden Datei"
step case_b_wiederholungen ok   b_02_migrate       "$SQL_DIR/02_migrate_value_add.sql"
step case_b_wiederholungen fail b_02_wiederholung  "$SQL_DIR/02_migrate_value_add.sql" \
  'Production-Migration abgebrochen: Migration ist bereits vollstaendig vorhanden.'
step case_b_wiederholungen ok   b_02_nach_abbruch  "$HERE/cases/assert_after_02.sql"
step case_b_wiederholungen ok   b_03_backup        "$SQL_DIR/03_backup_value_add.sql"
step case_b_wiederholungen fail b_03_wiederholung  "$SQL_DIR/03_backup_value_add.sql" \
  'Production-Backup abgebrochen: Snapshot v1 existiert bereits.'
step case_b_wiederholungen ok   b_03_nach_abbruch  "$HERE/cases/assert_after_03.sql"
step case_b_wiederholungen fail b_05_vor_backfill  "$SQL_DIR/05_verify_read_only.sql" \
  'relation "cbb_private_backup.value_add_payload_v1" does not exist'
step case_b_wiederholungen ok   b_04_backfill      "$SQL_DIR/04_backfill_value_add.sql"
step case_b_wiederholungen fail b_04_wiederholung  "$SQL_DIR/04_backfill_value_add.sql" \
  'Production-Backfill abgebrochen: 10 Zielzeilen sind seit dem Snapshot gedriftet.'
step case_b_wiederholungen ok   b_04_nach_abbruch  "$HERE/cases/assert_after_04.sql"
step case_b_wiederholungen fail b_07_vor_restore   "$SQL_DIR/07_down_migration.sql" \
  'Production-Down abgebrochen: Restore nicht exakt (10 Abweichungen).'
step case_b_wiederholungen ok   b_04_unveraendert  "$HERE/cases/assert_after_04.sql"

# ===========================================================================
# CASE C — Transaktions-Rollback mitten in 04
# ===========================================================================
new_case case_c_rollback "Abbruch nach dem Payload-DDL in 04"
step case_c_rollback ok   c_02_migrate      "$SQL_DIR/02_migrate_value_add.sql"
step case_c_rollback ok   c_03_backup       "$SQL_DIR/03_backup_value_add.sql"
step case_c_rollback ok   c_block_installieren "$HERE/cases/setup_block_updates.sql"
step case_c_rollback fail c_04_bricht_ab    "$SQL_DIR/04_backfill_value_add.sql" \
  'CBB-TEST: UPDATE auf products absichtlich blockiert.'
step case_c_rollback ok   c_rollback_assert "$HERE/cases/assert_04_rolled_back.sql"
step case_c_rollback ok   c_block_entfernen "$HERE/cases/teardown_block_updates.sql"
step case_c_rollback ok   c_04_danach_ok    "$SQL_DIR/04_backfill_value_add.sql"
step case_c_rollback ok   c_04_assert       "$HERE/cases/assert_after_04.sql"

# ===========================================================================
# CASE D — Restore und Down-Migration
# ===========================================================================
new_case case_d_rollback_pfad "04 -> 06 -> 07 mit Round-Trip-Beweis"
step case_d_rollback_pfad ok   d_02_migrate      "$SQL_DIR/02_migrate_value_add.sql"
step case_d_rollback_pfad ok   d_03_backup       "$SQL_DIR/03_backup_value_add.sql"
step case_d_rollback_pfad ok   d_04_backfill     "$SQL_DIR/04_backfill_value_add.sql"
step case_d_rollback_pfad ok   d_06_restore      "$SQL_DIR/06_restore_value_add.sql"
step case_d_rollback_pfad ok   d_06_assert       "$HERE/cases/assert_after_06.sql"
step case_d_rollback_pfad ok   d_06_wiederholung "$SQL_DIR/06_restore_value_add.sql"
step case_d_rollback_pfad ok   d_06_assert_2     "$HERE/cases/assert_after_06.sql"
step case_d_rollback_pfad fail d_04_nach_restore "$SQL_DIR/04_backfill_value_add.sql" \
  'Production-Backfill abgebrochen: Audit-Payload v1 existiert bereits.'
step case_d_rollback_pfad ok   d_06_assert_3     "$HERE/cases/assert_after_06.sql"
step case_d_rollback_pfad ok   d_07_down         "$SQL_DIR/07_down_migration.sql"
step case_d_rollback_pfad ok   d_07_assert       "$HERE/cases/assert_after_07.sql"
step case_d_rollback_pfad fail d_07_wiederholung "$SQL_DIR/07_down_migration.sql" \
  'Production-Down abgebrochen: Migration unvollstaendig (0 Spalten, 0 Typen, 0 Constraints).'
step case_d_rollback_pfad ok   d_07_assert_2     "$HERE/cases/assert_after_07.sql"
step case_d_rollback_pfad ok   d_02_erneut       "$SQL_DIR/02_migrate_value_add.sql"
step case_d_rollback_pfad ok   d_02_assert       "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE E-H — Negative Umgebungs-Guards
# Nach jedem Abbruch: EXAKT 0 Value-Add-Spalten und 0 Constraints
# (im Teilzustands-Fall exakt die 3 vorher vorhandenen Spalten, 0 Constraints).
# ===========================================================================
new_case case_e_pilot_artefakt "Pilot-Marker vorhanden"
step case_e_pilot_artefakt ok   e_setup       "$HERE/cases/setup_pilot_artifact.sql"
step case_e_pilot_artefakt fail e_02_abbruch  "$SQL_DIR/02_migrate_value_add.sql" \
  'Production-Migration abgebrochen: Pilot-Artefakt gefunden.'
step case_e_pilot_artefakt ok   e_exakt_0_spalten "$HERE/cases/assert_no_value_add_schema.sql"

new_case case_f_zu_wenig_produkte "Bestand unter 300"
step case_f_zu_wenig_produkte ok   f_setup       "$HERE/cases/setup_shrink_below_300.sql"
step case_f_zu_wenig_produkte fail f_02_abbruch  "$SQL_DIR/02_migrate_value_add.sql" \
  'Production-Migration abgebrochen: nur 299 Produkte (< 300).'
step case_f_zu_wenig_produkte ok   f_exakt_0_spalten "$HERE/cases/assert_no_value_add_schema.sql"

new_case case_g_teilzustand "3 von 8 Spalten existieren bereits"
step case_g_teilzustand ok   g_setup       "$HERE/cases/setup_partial_columns.sql"
step case_g_teilzustand fail g_02_abbruch  "$SQL_DIR/02_migrate_value_add.sql" \
  'Production-Migration abgebrochen: Teilzustand (3 Spalten, 3 Typen, 0 Constraints).'
step case_g_teilzustand ok   g_exakt_3_spalten "$HERE/cases/assert_partial_state_unchanged.sql"

new_case case_h_relationsziel_offline "Ein Relationsziel unpublished"
step case_h_relationsziel_offline ok   h_setup      "$HERE/cases/setup_unpublish_relation.sql"
step case_h_relationsziel_offline fail h_02_abbruch "$SQL_DIR/02_migrate_value_add.sql" \
  'Production-Migration abgebrochen: 4/5 Relationsziele published.'
step case_h_relationsziel_offline ok   h_exakt_0_spalten "$HERE/cases/assert_no_value_add_schema.sql"

# ===========================================================================
# CASE I — Trigger-Verhalten (Voraussetzung fuer 04 und 06)
# ===========================================================================
new_case case_i_trigger "seo_updated_at_trigger im Zusammenspiel"
step case_i_trigger ok i_trigger "$HERE/cases/assert_trigger_behaviour.sql"

# ===========================================================================
# CASE J — Lock-Timeout: 02 muss unter Sperrkonflikt nach ~5 s abbrechen
# ===========================================================================
new_case case_j_lock_timeout "AccessExclusiveLock blockiert 02"
step case_j_lock_timeout ok j_vorbereitung "$HERE/cases/assert_no_value_add_schema.sql"

J_ERWARTET='canceling statement due to lock timeout'
LOCKER_SQL="$WORKDIR/locker.sql"
cat > "$LOCKER_SQL" <<'LOCKEOF'
begin;
lock table public.products in access exclusive mode;
select pg_sleep(90);
rollback;
LOCKEOF

# Der Lock-Halter bekommt einen eindeutigen application_name. Ueber ihn wird er
# spaeter per pg_terminate_backend beendet — nicht per kill des psql-Clients.
PGAPPNAME="$LOCK_APP" "$PSQL" -X -q -d case_j_lock_timeout -f "$LOCKER_SQL" \
  > "$LOGDIR/900_locker.log" 2>&1 &
LOCKER_PID=$!

# pg_locks ist clusterweit, pg_class aber datenbanklokal. Die Abfrage laeuft
# deshalb IN case_j_lock_timeout und filtert zusaetzlich auf dessen OID —
# sonst wuerde l.relation gegen einen fremden pg_class-Katalog aufgeloest.
lock_held_count() {
  "$PSQL" -X -q -A -t -d case_j_lock_timeout -c \
    "select count(*) from pg_locks l
       join pg_class c on c.oid = l.relation
      where c.relname = 'products'
        and l.mode = 'AccessExclusiveLock'
        and l.granted
        and l.database = (select oid from pg_database
                          where datname = current_database())" 2>/dev/null
}

LOCK_HELD=0
for _ in $(seq 1 20); do
  HELD="$(lock_held_count)"
  if [[ "${HELD:-0}" -ge 1 ]]; then LOCK_HELD=1; break; fi
  "$PSQL" -X -q -A -t -d postgres -c "select pg_sleep(0.3)" >/dev/null 2>&1
done
log "  Sperre aktiv: $LOCK_HELD (application_name=$LOCK_APP, Client-PID $LOCKER_PID)"

# ---------------------------------------------------------------------------
# J.1 — 02 unter der Sperre.
# Erwartet: Exit 3 mit "canceling statement due to lock timeout" nach rund
# 5 Sekunden. Exit 124 (Client-Timeout aus `timeout 30`), ein anderer Fehler
# oder ein Erfolg sind FAIL.
# ---------------------------------------------------------------------------
STEP=$((STEP + 1))
J_OUT="$LOGDIR/$(printf '%03d' "$STEP")_j_02_unter_sperre.log"
J_DIAG="$LOGDIR/$(printf '%03d' "$STEP")_j_02_wartet_auf.log"
J_RC=0
J_ELAPSED=-1

if [[ $LOCK_HELD -ne 1 ]]; then
  mark_fail
  record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "-" FAIL \
    "Sperre konnte nicht aufgebaut werden — Fall nicht bewertbar"
else
  J_START=$SECONDS
  timeout 30 "$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_j_lock_timeout \
    -f "$SQL_DIR/02_migrate_value_add.sql" > "$J_OUT" 2>&1 &
  J_PSQL_PID=$!

  # Belegen, WO 02 haengt. Nach der Korrektur muss der Wartepunkt bereits unter
  # dem gesetzten lock_timeout liegen.
  for _ in $(seq 1 10); do
    "$PSQL" -X -q -d postgres -c "
      select a.pid, a.state, a.wait_event_type, a.wait_event,
             left(regexp_replace(a.query, '\s+', ' ', 'g'), 80) as blockiertes_statement
      from pg_stat_activity a
      where a.datname = 'case_j_lock_timeout'
        and a.wait_event_type = 'Lock'" > "$J_DIAG" 2>&1
    grep -q 'Lock' "$J_DIAG" && break
    "$PSQL" -X -q -A -t -d postgres -c "select pg_sleep(0.5)" >/dev/null 2>&1
  done
  cat "$J_DIAG"

  wait "$J_PSQL_PID" || J_RC=$?
  J_ELAPSED=$((SECONDS - J_START))

  J_MSG="$(grep -m1 -E 'ERROR' "$J_OUT" | cut -c1-200)"
  if [[ $J_RC -eq 124 ]]; then
    mark_fail
    record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "$J_RC" FAIL \
      "Client-Timeout nach 30s: lock_timeout greift in der Guard-Phase nicht"
  elif [[ $J_RC -ne 3 ]]; then
    mark_fail
    record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "$J_RC" FAIL \
      "Exit $J_RC statt 3 nach ${J_ELAPSED}s — $J_MSG"
  elif ! grep -Fq -- "$J_ERWARTET" "$J_OUT"; then
    mark_fail
    record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "$J_RC" FAIL \
      "falscher Fehler. erwartet: <$J_ERWARTET> | tatsaechlich: $J_MSG"
  elif [[ $J_ELAPSED -lt 3 || $J_ELAPSED -gt 15 ]]; then
    mark_fail
    record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "$J_RC" FAIL \
      "richtige Meldung, aber Laufzeit ${J_ELAPSED}s ausserhalb 3-15s (lock_timeout='5s')"
  else
    record j_02_unter_sperre "02_migrate_value_add.sql" "fail/3" "$J_RC" PASS \
      "lock timeout nach ${J_ELAPSED}s: $J_ERWARTET"
  fi
fi

# ---------------------------------------------------------------------------
# J.2 — Lock-Halter zuverlaessig beenden.
# pg_terminate_backend ueber den eindeutigen application_name. Ein blosser kill
# des psql-Clients wuerde das Server-Backend nicht garantiert beenden; der
# Nachtest wuerde dann bis zum Ende von pg_sleep(90) haengen.
# ---------------------------------------------------------------------------
STEP=$((STEP + 1))
T_START=$SECONDS
TERMINATED="$("$PSQL" -X -q -A -t -d postgres -c \
  "select count(*) from (
     select pg_terminate_backend(pid) from pg_stat_activity
     where application_name = '$LOCK_APP' and pid <> pg_backend_pid()
   ) t" 2>&1)"

LOCK_GONE=0
for _ in $(seq 1 20); do
  HELD="$(lock_held_count)"
  if [[ "${HELD:-1}" -eq 0 ]]; then LOCK_GONE=1; break; fi
  "$PSQL" -X -q -A -t -d postgres -c "select pg_sleep(0.5)" >/dev/null 2>&1
done
wait "$LOCKER_PID" 2>/dev/null
T_ELAPSED=$((SECONDS - T_START))

if [[ $LOCK_GONE -eq 1 && "${TERMINATED:-0}" =~ ^[0-9]+$ && "${TERMINATED}" -ge 1 ]]; then
  record j_locker_terminiert "pg_terminate_backend" "lock frei" "-" PASS \
    "$TERMINATED Backend(s) via application_name=$LOCK_APP beendet, Sperre nach ${T_ELAPSED}s frei"
else
  mark_fail
  record j_locker_terminiert "pg_terminate_backend" "lock frei" "-" FAIL \
    "terminate-Ergebnis=<$TERMINATED>, Sperre nach ${T_ELAPSED}s frei=$LOCK_GONE"
fi

step case_j_lock_timeout ok j_exakt_0_spalten "$HERE/cases/assert_no_value_add_schema.sql"

# Der Nachtest darf nicht auf das Ende von pg_sleep(90) warten.
N_START=$SECONDS
step case_j_lock_timeout ok j_02_danach   "$SQL_DIR/02_migrate_value_add.sql"
N_ELAPSED=$((SECONDS - N_START))
log "  j_02_danach Laufzeit: ${N_ELAPSED}s (muss deutlich unter pg_sleep(90) liegen)"
if [[ $N_ELAPSED -gt 30 ]]; then
  mark_fail
  log "  [FAIL] j_02_danach brauchte ${N_ELAPSED}s — die Sperre wurde nicht wirklich geloest."
fi
step case_j_lock_timeout ok j_02_assert   "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# Zusammenfassung
# ===========================================================================
head1 "Zusammenfassung"
column -t -s $'\t' "$RESULTS" 2>/dev/null || cat "$RESULTS"
log ""
log "Schritte gesamt: $STEP"
log "Abweichungen:    $FAILURES"
log "Ergebnisdatei:   $RESULTS"
log "Logverzeichnis:  $LOGDIR"

if [[ $FAILURES -eq 0 ]]; then
  log "GESAMT: PASS"
  exit 0
fi
log "GESAMT: FAIL"
exit 1
