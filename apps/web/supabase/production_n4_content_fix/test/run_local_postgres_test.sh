#!/usr/bin/env bash
# =============================================================================
# LOKALER POSTGRESQL-HARNESS FUER DAS N4-CONTENT-KORREKTURPAKET
# =============================================================================
# Testet die ORIGINALDATEIEN
#   supabase/production_n4_content_fix/01_preflight_read_only.sql
#   ... bis 06_restore_n4_content.sql
# unveraendert gegen eine echte PostgreSQL-16-Instanz.
#
# Der Harness fasst KEINE Production- und KEINE Pilot-Datenbank an. Er startet
# einen eigenen Cluster in einem mktemp-Verzeichnis, der ausschliesslich ueber
# einen Unix-Socket erreichbar ist (listen_addresses='') und den er am Ende per
# trap wieder stoppt.
#
# AUSGANGSZUSTAND
#   Die Vorlage-Datenbank cbb_fixture bildet den bereits erfolgreich getesteten
#   Value-Add-Production-Zustand nach. Sie entsteht aus
#     * der vorhandenen Fixture production_value_add/test/fixture/00..04,
#     * dem echten Trigger supabase/seo_updated_at_trigger.sql,
#     * den UNVERAENDERTEN Originaldateien
#       production_value_add/02_migrate_value_add.sql,
#       production_value_add/03_backup_value_add.sql,
#       production_value_add/04_backfill_value_add.sql,
#     * der Gegenprobe production_value_add/test/cases/assert_after_04.sql,
#     * und erst danach cases/setup_n4_production_pre_values.sql, das die
#       N4-Vorwerte exakt auf den bekannten Production-Stand setzt.
#   Keine Datei in production_value_add/ wird dabei veraendert.
#
# SCHAERFE DER ERWARTUNGEN
#   * Ein erwarteter Abbruch gilt NUR dann als PASS, wenn psql mit Exit 3
#     zurueckkommt UND die konkrete erwartete Servermeldung im Output steht.
#     Ein anderer Fehler ist FAIL, kein PASS.
#   * report_table verlangt EXAKTE PASS-Zahlen: 01 -> 18, 03 -> 10, 05 -> 18,
#     jeweils bei 0 FAIL-Zeilen.
#   * report_table_expect_fail verlangt umgekehrt eine benannte FAIL-Zeile.
#   * Der Lock-Test verlangt Exit 3, die Meldung
#     "canceling statement due to lock timeout" und eine Laufzeit um 5 s.
#     Exit 124 (Client-Timeout), ein anderer Text oder ein Erfolg sind FAIL.
#   * Die beiden Konkurrenztests (case_g, case_h) sind echt, nicht simuliert:
#     eine zweite Session haelt den Row-Lock und aendert ein Feld, der
#     Paketlauf wird nachweislich beim Warten auf den Lock beobachtet
#     (pg_stat_activity.wait_event_type = 'Lock'), erst danach commitet die
#     Konkurrenz. PASS nur bei Exit 3 mit der Recheck-Meldung. Ein Durchlauf,
#     ein Lock-Timeout oder ein fehlender Wartepunkt-Nachweis sind FAIL.
#   * Statisch wird geprueft, dass in 02, 04 und 06 beide SET-LOCAL-Zeilen
#     direkt hinter "begin;" und vor dem ersten DO-Block stehen (nur
#     Kommentar-/Leerzeilen dazwischen, keine spaeteren Duplikate) und dass
#     01, 03 und 05 kein einziges schreibendes Statement enthalten.
#   * Ebenfalls statisch: jeder im Lauf gesetzte application_name bleibt unter
#     der PostgreSQL-Grenze NAMEDATALEN-1 = 63 Byte. Ein gekuerzter Name macht
#     die exakte Wartepunkt-Suche in pg_stat_activity unbrauchbar.
#
# HARNESS-INTERNA
#   Die zweite Session der Konkurrenztests wird ueber eine FIFO gefuettert.
#   Der Leser (psql) startet ZUERST, erst danach oeffnet der Parent fd 8 als
#   reines Schreibende — sonst erbt das Kind einen eigenen Writer und sieht nie
#   EOF. Details in der Kopfnotiz von konkurrenz_lauf.
#
# Aufruf:
#   ./run_local_postgres_test.sh                      # Cluster danach entfernt
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
SQL_DIR="$(cd "$HERE/.." && pwd)"           # production_n4_content_fix/
REPO_SUPABASE="$(cd "$SQL_DIR/.." && pwd)"  # apps/web/supabase/
VA_DIR="$REPO_SUPABASE/production_value_add"
VA_TEST="$VA_DIR/test"

for d in "$VA_DIR" "$VA_TEST/fixture" "$VA_TEST/cases"; do
  if [[ ! -d "$d" ]]; then
    echo "FEHLT: $d" >&2
    echo "Das N4-Paket setzt das unveraenderte Value-Add-Paket voraus." >&2
    exit 2
  fi
done

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

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cbb-n4test.XXXXXXXX")"
PGDATA="$WORKDIR/data"
SOCKDIR="$WORKDIR/sock"
LOGDIR="$WORKDIR/logs"
SERVERLOG="$WORKDIR/postgres.log"
RESULTS="$WORKDIR/results.tsv"
mkdir -p "$SOCKDIR" "$LOGDIR"

# Eindeutiger application_name fuer den Lock-Halter. Ueber ihn wird der
# Backend-Prozess spaeter per pg_terminate_backend zuverlaessig beendet — ein
# kill des psql-Clients wuerde das Server-Backend nicht garantiert loesen.
#
# LAENGE: PostgreSQL kuerzt application_name hart auf NAMEDATALEN-1 = 63 Byte.
# Der frueher benutzte Praefix "cbb_n4_lock_holder_$(basename "$WORKDIR")" war
# allein schon 38 Zeichen lang; zusammen mit "_hold_<label>" lag der Name im
# ersten echten Lauf ueber der Grenze und wurde serverseitig abgeschnitten
# ("cbb_n4_lock_holder_cbb-n4test..._hold_g_02_unter_konkurre"). Exakte
# Vergleiche gegen pg_stat_activity.application_name sind damit unzuverlaessig.
# Deshalb: kurzer, deterministischer Praefix aus dem 8-stelligen mktemp-Suffix.
PG_APPNAME_MAX=63
WORK_ID="$(basename "$WORKDIR")"
WORK_ID="${WORK_ID##*.}"                # die 8 Zufallszeichen aus mktemp
LOCK_APP="cbb_n4_${WORK_ID}"            # 15 Zeichen, z. B. cbb_n4_a1b2c3d4

# Die Labels der beiden Konkurrenzfaelle stehen hier zentral, damit die
# statische Laengenpruefung genau die Namen sieht, die spaeter wirklich
# gesetzt werden.
LABEL_G=g_02_unter_konkurrenz
LABEL_H=h_04_unter_konkurrenz

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
  # Falls noch ein Lock-Halter lebt, zuerst sein Backend beenden. LIKE statt
  # Gleichheit: die Konkurrenztests haengen an denselben Praefix noch ein
  # Suffix pro Fall an.
  if "$PG_CTL" -D "$PGDATA" status >/dev/null 2>&1; then
    "$PSQL" -X -q -A -t -d postgres -c \
      "select pg_terminate_backend(pid) from pg_stat_activity
       where application_name like '$LOCK_APP%'" >/dev/null 2>&1
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
  printf '  [%s] %-46s expect=%-9s exit=%-3s %s\n' "$5" "$1" "$3" "$4" "$2"
  [[ -n "$6" ]] && printf '           %s\n' "$6"
}

mark_fail() { FAILURES=$((FAILURES + 1)); }

# ---------------------------------------------------------------------------
# appname <rolle> <label>
#   Baut den application_name einer Konkurrenz-Session und gibt ihn aus. Exit 1
#   (bei trotzdem ausgegebenem Namen), wenn er die PostgreSQL-Grenze von
#   NAMEDATALEN-1 = 63 Byte reissen wuerde — der Server wuerde ihn dann
#   abschneiden und jede exakte Suche in pg_stat_activity ginge ins Leere.
#   Alle Bestandteile sind reines ASCII, Zeichen- und Bytelaenge sind identisch.
# ---------------------------------------------------------------------------
appname() {
  local name="${LOCK_APP}_$1_$2"
  printf '%s' "$name"
  [[ ${#name} -le $PG_APPNAME_MAX ]]
}

# ---------------------------------------------------------------------------
# step <db> <expect: ok|fail> <label> <sql-datei> [erwartetes-fehler-literal]
#
#   expect=ok    -> psql muss mit Exit 0 zurueckkommen.
#   expect=fail  -> psql muss mit Exit 3 zurueckkommen (Server-Exception bei
#                   ON_ERROR_STOP=1) UND das uebergebene Literal muss im Output
#                   stehen. Das Literal ist PFLICHT: fehlt es, ist der Schritt
#                   FAIL. Ein anderer Fehler als der erwartete ist ebenfalls
#                   FAIL — "irgendein Exit != 0" reicht nicht.
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
#   01, 03 und 05 sind read-only und melden Probleme NICHT ueber den Exit-Code,
#   sondern als Zeile mit status = FAIL. Verlangt wird die EXAKTE Zahl an
#   PASS-Zeilen und 0 FAIL-Zeilen. Eine geschrumpfte Pruefliste faellt damit
#   auf, statt als PASS durchzugehen.
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
# report_table_expect_fail <db> <label> <sql-datei> <pruefungsname>
#   Die Umkehrung: der Bericht MUSS laufen (Exit 0) und MUSS fuer die genannte
#   Pruefung eine FAIL-Zeile liefern. Damit ist belegt, dass 01 nach der
#   Korrektur nicht still weiter PASS meldet.
# ---------------------------------------------------------------------------
report_table_expect_fail() {
  local db="$1" label="$2" file="$3" want_check="$4"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local rc=0

  "$PSQL" -X -q -A -F '|' -t -v ON_ERROR_STOP=1 -d "$db" -f "$file" \
    > "$base.psv" 2>&1 || rc=$?

  local verdict detail failrows=0
  if [[ $rc -ne 0 ]]; then
    verdict=FAIL
    mark_fail
    detail="Bericht selbst brach ab (exit=$rc) -> $base.psv"
  else
    failrows="$(grep -c '|FAIL$' "$base.psv" || true)"
    if grep -q "^${want_check}|.*|FAIL$" "$base.psv"; then
      verdict=PASS
      detail="$failrows FAIL-Zeilen, darunter '$want_check' -> $base.psv"
    else
      verdict=FAIL
      mark_fail
      detail="'$want_check' meldet kein FAIL ($failrows FAIL-Zeilen gesamt) -> $base.psv"
    fi
  fi

  record "$label" "$(basename "$file")" "FAIL:$want_check" "$rc" "$verdict" "$detail"
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
  local label="static_setlocal_$(basename "$file" .sql)"
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

# ---------------------------------------------------------------------------
# static_read_only <sql-datei>
#   Statischer Beweis, dass eine als read-only deklarierte Datei kein
#   schreibendes Statement enthaelt. Geprueft werden ausschliesslich Zeilen,
#   die NICHT mit "--" beginnen; das erste Wort der Zeile darf keines der
#   schreibenden Schluesselwoerter sein. Die Datei muss ausserdem mit "with"
#   beginnen (erste Nicht-Kommentarzeile).
# ---------------------------------------------------------------------------
static_read_only() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="static_readonly_$(basename "$file" .sql)"
  local res
  # tolower() statt IGNORECASE: IGNORECASE ist eine gawk-Erweiterung und wird
  # von mawk stillschweigend ignoriert — die Pruefung waere dort wirkungslos.
  res="$(awk '
    BEGIN { first = "" }
    {
      l = $0
      gsub(/^[ \t]+/, "", l); gsub(/[ \t]+$/, "", l)
      if (l == "" || substr(l, 1, 2) == "--") next
      lo = tolower(l)
      if (first == "") { first = lo; first_l = NR }
      if (lo ~ /^(insert|update|delete|merge|create|alter|drop|truncate|grant|revoke|begin|commit|rollback|do|call|copy|set|lock|vacuum|analyze|refresh|comment|reindex)([ \t;(]|$)/) {
        bad_n++
        if (bad == "") bad = sprintf("Z%d: %s", NR, substr(l, 1, 60))
      }
    }
    END {
      p = ""
      if (first !~ /^with([ \t(]|$)/)
        p = p sprintf("erste Anweisung ist kein WITH (Z%d: %s); ", first_l, substr(first, 1, 40))
      if (bad_n > 0)
        p = p sprintf("%d schreibende Zeile(n), erste %s; ", bad_n, bad)
      if (p == "")
        printf "OK|beginnt mit WITH in Z%d, 0 schreibende Statements\n", first_l
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
  record "$label" "$(basename "$file")" "read-only" "-" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# static_appnamen
#   Statischer Beweis, dass KEIN im Lauf gesetzter application_name die
#   PostgreSQL-Grenze NAMEDATALEN-1 = 63 Byte reisst. Wird der Name
#   serverseitig gekuerzt, findet die exakte Suche in pg_stat_activity den
#   Wartepunkt nicht mehr — genau das ist im ersten echten Lauf passiert.
#   Die Pruefung laeuft VOR dem Cluster; ein Treffer bricht den Lauf ab.
# ---------------------------------------------------------------------------
static_appnamen() {
  STEP=$((STEP + 1))
  local namen=("$LOCK_APP")
  local label rolle name laengste=0 laengster="" zu_lang=""
  for label in "$LABEL_G" "$LABEL_H"; do
    for rolle in hold ziel; do
      namen+=("${LOCK_APP}_${rolle}_${label}")
    done
  done
  for name in "${namen[@]}"; do
    if [[ ${#name} -gt $laengste ]]; then laengste=${#name}; laengster="$name"; fi
    if [[ ${#name} -gt $PG_APPNAME_MAX ]]; then
      zu_lang="${zu_lang}${name} (${#name}); "
    fi
  done

  local verdict detail
  if [[ -z "$zu_lang" ]]; then
    verdict=PASS
    detail="${#namen[@]} Namen, laengster $laengste Zeichen: $laengster"
  else
    verdict=FAIL
    mark_fail
    detail="ueber $PG_APPNAME_MAX Zeichen, wuerde serverseitig gekuerzt: $zu_lang"
  fi
  record static_appname_laenge "-" "<=${PG_APPNAME_MAX} Zeichen" "-" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# Serverseitige Wartehilfen.
#
# Warum nicht aus der Shell pollen: jede psql-Runde kostet Verbindungsaufbau.
# Beim Nebenlaeufigkeitstest laeuft parallel der lock_timeout = 5s des
# Ziellaufs — wer zu langsam erkennt, dass der Ziellauf wartet, commitet zu
# spaet und misst dann den Lock-Timeout statt den Recheck nach dem Lock.
# Deshalb wartet EINE Verbindung serverseitig in einer Schleife.
# ---------------------------------------------------------------------------
warte_auf_offene_transaktion() {   # <application_name> <marker im query-Text>
  # ON_ERROR_STOP=1 ist Pflicht: ohne es meldet psql den RAISE EXCEPTION nicht
  # ueber den Exit-Code, und ein nicht erkannter Wartepunkt ginge still als
  # Erfolg durch.
  "$PSQL" -X -q -A -t -v ON_ERROR_STOP=1 -d postgres -c "
    do \$do\$
    declare i integer;
    begin
      for i in 1..200 loop
        if exists (
          select 1 from pg_stat_activity
          where application_name = '$1'
            and state = 'idle in transaction'
            and position('$2' in query) > 0
        ) then
          raise notice 'offene Transaktion mit Marker nach % ms', i * 50;
          return;
        end if;
        perform pg_sleep(0.05);
      end loop;
      raise exception 'keine offene Transaktion mit Marker fuer %', '$1';
    end
    \$do\$;" 2>&1
}

warte_auf_wartepunkt() {           # <application_name>
  # ON_ERROR_STOP=1 ist Pflicht: ohne es meldet psql den RAISE EXCEPTION nicht
  # ueber den Exit-Code, und ein nicht erkannter Wartepunkt ginge still als
  # Erfolg durch.
  "$PSQL" -X -q -A -t -v ON_ERROR_STOP=1 -d postgres -c "
    do \$do\$
    declare i integer;
    begin
      for i in 1..400 loop
        if exists (
          select 1 from pg_stat_activity
          where application_name = '$1' and wait_event_type = 'Lock'
        ) then
          raise notice 'Wartepunkt nach % ms erkannt', i * 50;
          return;
        end if;
        perform pg_sleep(0.05);
      end loop;
      raise exception 'kein Wartepunkt fuer % erkannt', '$1';
    end
    \$do\$;" 2>&1
}

# ---------------------------------------------------------------------------
# FIFO-Hilfen fuer den Konkurrenztest.
#
# leser_lebt <pid>
#   "kill -0" allein genuegt nicht: ein beendetes, aber noch nicht per wait
#   abgeholtes Kind bleibt als Zombie signalisierbar und wuerde faelschlich als
#   lebend gelten. Deshalb zusaetzlich der Prozesszustand aus /proc.
#
# warte_auf_leser <pid>
#   Wartet auf das Ende des FIFO-Lesers. Mit der korrigierten fd-Reihenfolge
#   (siehe konkurrenz_lauf) MUSS psql nach "exec 8>&-" EOF sehen und beenden;
#   der Reaper ist nur die Notbremse, damit ein kuenftiger Harness-Fehler den
#   Lauf nicht erneut unbegrenzt haengen laesst. Er startet mit geschlossenem
#   fd 8, damit er das EOF nicht selbst verhindert.
# ---------------------------------------------------------------------------
leser_lebt() {
  local pid="$1" st
  kill -0 "$pid" 2>/dev/null || return 1
  if [[ -r "/proc/$pid/stat" ]]; then
    st="$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null)"
    [[ "$st" == "Z" ]] && return 1
  fi
  return 0
}

warte_auf_leser() {
  local pid="$1" reaper
  ( sleep 30; kill -TERM "$pid" 2>/dev/null ) 8>&- &
  reaper=$!
  wait "$pid" 2>/dev/null
  kill -TERM "$reaper" 2>/dev/null
  wait "$reaper" 2>/dev/null
  return 0
}

# ---------------------------------------------------------------------------
# konkurrenz_lauf <db> <label> <paketdatei> <konkurrenz-sql> <erwartete-meldung>
#
# ECHTER Nebenlaeufigkeitstest, keine Simulation:
#   1. Eine zweite Session oeffnet eine Transaktion, sperrt die N4-Zeile per
#      SELECT ... FOR UPDATE und aendert ein Feld. Sie commitet noch NICHT.
#   2. Die Paketdatei wird gestartet. Ihre sperrfreien Vorpruefungen sehen den
#      alten, committeten Stand und laufen durch; an ihrem eigenen FOR UPDATE
#      bleibt sie stehen. Dass sie WIRKLICH wartet, wird ueber pg_stat_activity
#      belegt (wait_event_type = 'Lock') und protokolliert. Ohne diesen
#      Nachweis ist der Fall FAIL, nicht PASS.
#   3. Erst dann commitet die Konkurrenz. Die Paketdatei erhaelt den Lock,
#      sieht den neuen Stand und MUSS wegen der erneuten Vorzustandspruefung
#      NACH dem Lock abbrechen.
#
# PASS nur bei Exit 3 mit der erwarteten Meldung.
#   * Exit 0 = fremde Daten wurden ueberschrieben -> FAIL.
#   * "canceling statement due to lock timeout" = zu spaet commitet, der
#     Recheck nach dem Lock ist damit nicht bewiesen -> FAIL.
#   * jeder andere Fehler -> FAIL.
#
# Die zweite Session wird ueber eine FIFO gefuettert. Nur so laesst sich der
# COMMIT-Zeitpunkt genau zwischen Schritt 2 und 3 legen; eine SQL-Datei mit
# festem pg_sleep waere ein Zeitraten, kein Beweis.
#
# FD-REIHENFOLGE (der Fehler aus dem ersten echten Lauf):
#   Frueher wurde die FIFO mit "exec 8<>fifo" VOR dem psql-Start geoeffnet.
#   Der psql-Kindprozess erbte fd 8 damit als eigenes SCHREIBENDE. Nach
#   "commit;"/"rollback;" und "exec 8>&-" im Parent gab es also weiterhin einen
#   offenen Writer — psql sah nie EOF, blieb idle/ClientRead auf dem letzten
#   Statement stehen und "wait" haengte unbegrenzt (beobachtet in case_g:
#   pg_stat_activity zeigte den Halter idle bei query = 'rollback;').
#   Richtig ist die umgekehrte Reihenfolge: erst den Leser starten, dann fd 8
#   als REINES Schreibende oeffnen. Was der Parent danach oeffnet, kann das
#   Kind nicht mehr erben. Aus demselben Grund starten alle spaeteren
#   Hintergrundprozesse mit "8>&-".
# ---------------------------------------------------------------------------
konkurrenz_lauf() {
  local db="$1" label="$2" file="$3" konkurrenz_sql="$4" want="$5"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local fifo="$WORKDIR/${label}.fifo"
  local marker='CBB-TEST: konkurrierende Aenderung'

  # Namen VOR der Benutzung gegen die 63-Byte-Grenze pruefen. static_appnamen
  # hat das bereits fuer den ganzen Lauf getan; hier steht die Notbremse fuer
  # den Fall, dass jemand ein Label aendert, ohne die Liste nachzuziehen.
  local app_hold app_target laenge_ok=1
  app_hold="$(appname hold "$label")"   || laenge_ok=0
  app_target="$(appname ziel "$label")" || laenge_ok=0
  if [[ $laenge_ok -ne 1 ]]; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "-" FAIL \
      "application_name zu lang (${#app_hold}/${#app_target} Zeichen, Grenze $PG_APPNAME_MAX) — PostgreSQL wuerde kuerzen, der Wartepunkt waere nicht mehr exakt auffindbar"
    return 0
  fi

  rm -f "$fifo"
  if ! mkfifo "$fifo" 2>/dev/null; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "-" FAIL "mkfifo $fifo fehlgeschlagen"
    return 0
  fi

  # Stirbt die zweite Session unerwartet, wuerde ein Schreiben auf fd 8 den
  # Harness per SIGPIPE hart beenden. Innerhalb dieser Funktion wird SIGPIPE
  # deshalb ignoriert; der tote Leser wird stattdessen erkannt und als FAIL
  # protokolliert. Vor jedem return wird der Default wiederhergestellt.
  trap '' PIPE

  # SCHRITT 1: der LESER zuerst. psql oeffnet die FIFO damit zum Lesen, bevor
  # es im Parent ueberhaupt ein fd 8 gibt — es kann das Schreibende also nicht
  # erben. Genau hier lag der Deadlock des ersten echten Laufs.
  PGAPPNAME="$app_hold" "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$fifo" \
    > "$base.konkurrenz.log" 2>&1 &
  local holder_pid=$!

  # SCHRITT 2: erst jetzt das reine Schreibende. "exec 8>fifo" blockiert, bis
  # ein Leser die FIFO geoeffnet hat — psql oeffnet die -f-Datei aber erst nach
  # erfolgreichem Verbindungsaufbau. Stirbt es vorher, gaebe es nie einen Leser
  # und der Harness haengte an dieser Zeile. Ein Wachhund oeffnet die Leseseite
  # deshalb notfalls selbst (und schliesst sie sofort wieder), damit der Parent
  # weiterlaeuft und den toten Leser sauber als FAIL melden kann.
  local bereit="$WORKDIR/${label}.leser_bereit"
  rm -f "$bereit"
  (
    for _ in $(seq 1 600); do
      [[ -e "$bereit" ]] && exit 0
      leser_lebt "$holder_pid" || break
      sleep 0.1
    done
    exec 9<>"$fifo"
  ) &
  local wachhund_pid=$!
  exec 8>"$fifo"
  : > "$bereit"
  wait "$wachhund_pid" 2>/dev/null
  rm -f "$bereit"

  if ! leser_lebt "$holder_pid"; then
    exec 8>&-
    warte_auf_leser "$holder_pid"
    rm -f "$fifo"
    mark_fail
    trap - PIPE
    record "$label" "$(basename "$file")" "fail/3" "-" FAIL \
      "zweite Session ist gar nicht erst gestartet: $(tail -n 3 "$base.konkurrenz.log" 2>/dev/null | tr '\n' ' ' | cut -c1-140)"
    return 0
  fi

  printf '%s\n' \
    'begin;' \
    "select id from public.products where slug = 'n4-nussmilchbereiter-pflanzenmilch' for update;" \
    "$konkurrenz_sql" >&8

  local hold_rc=0 hold_out
  hold_out="$(warte_auf_offene_transaktion "$app_hold" "$marker")" || hold_rc=$?
  if [[ $hold_rc -ne 0 ]]; then
    printf 'rollback;\n' >&8
    exec 8>&-
    warte_auf_leser "$holder_pid"
    rm -f "$fifo"
    mark_fail
    trap - PIPE
    record "$label" "$(basename "$file")" "fail/3" "-" FAIL \
      "zweite Session hat Lock/Aenderung nicht aufgebaut: $(printf '%s' "$hold_out" | tr '\n' ' ' | cut -c1-140)"
    return 0
  fi

  # 8>&- : der Ziellauf darf das Schreibende NICHT erben, sonst sieht der Leser
  # nach "exec 8>&-" im Parent weiterhin kein EOF.
  local start=$SECONDS rc=0
  PGAPPNAME="$app_target" timeout 60 "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" \
    -f "$file" > "$base.log" 2>&1 8>&- &
  local target_pid=$!

  local warte_rc=0 warte_out
  warte_out="$(warte_auf_wartepunkt "$app_target")" || warte_rc=$?

  "$PSQL" -X -q -d postgres -c "
    select a.application_name, a.state, a.wait_event_type, a.wait_event,
           left(regexp_replace(a.query, '\s+', ' ', 'g'), 90) as statement
    from pg_stat_activity a
    where a.application_name in ('$app_hold', '$app_target')" \
    > "$base.wartepunkt.log" 2>&1
  cat "$base.wartepunkt.log"

  # Jetzt erst commitet die Konkurrenz — die Paketdatei bekommt den Lock.
  # Nach dem Schliessen von fd 8 ist der Parent der letzte Writer gewesen: der
  # Leser bekommt EOF und beendet sich, "warte_auf_leser" terminiert.
  printf 'commit;\n' >&8
  exec 8>&-
  warte_auf_leser "$holder_pid"
  wait "$target_pid" || rc=$?
  local elapsed=$((SECONDS - start))
  rm -f "$fifo"
  trap - PIPE

  local msg
  msg="$(grep -m1 -E '^(psql:.*(ERROR|FATAL)|ERROR)' "$base.log" | cut -c1-200)"

  if [[ $warte_rc -ne 0 ]]; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "$rc" FAIL \
      "kein belegter Wartepunkt — die Datei ist nie in den Lock gelaufen: $(printf '%s' "$warte_out" | tr '\n' ' ' | cut -c1-120)"
  elif [[ $rc -eq 0 ]]; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "$rc" FAIL \
      "lief nach ${elapsed}s durch und hat die konkurrierende Aenderung ueberschrieben"
  elif grep -Fq -- 'canceling statement due to lock timeout' "$base.log"; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "$rc" FAIL \
      "Lock-Timeout nach ${elapsed}s statt Recheck-Abbruch — zu spaet commitet, Fall nicht bewertbar"
  elif [[ $rc -ne 3 ]]; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "$rc" FAIL \
      "Exit $rc statt 3 nach ${elapsed}s — $msg"
  elif ! grep -Fq -- "$want" "$base.log"; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "$rc" FAIL \
      "falscher Fehler. erwartet: <$want> | tatsaechlich: $msg"
  else
    record "$label" "$(basename "$file")" "fail/3" "$rc" PASS \
      "wartete auf den Lock, brach nach ${elapsed}s ab: $want"
  fi
  return 0
}

new_case() {
  CURRENT_CASE="$1"
  head1 "$1 — $2"
  "$CREATEDB" -T cbb_fixture "$1" \
    || fail_setup "createdb -T cbb_fixture $1 fehlgeschlagen — Folgeergebnisse waeren wertlos."
}

# ===========================================================================
# CASE 0 — Statische Pruefungen (ohne Cluster)
# ===========================================================================
head1 "case_0_statisch — SET LOCAL direkt hinter begin;, read-only wirklich read-only"
CURRENT_CASE=case_0_statisch
static_appnamen
static_set_local "$SQL_DIR/02_backup_n4_content.sql"
static_set_local "$SQL_DIR/04_correct_n4_content.sql"
static_set_local "$SQL_DIR/06_restore_n4_content.sql"
static_read_only "$SQL_DIR/01_preflight_read_only.sql"
static_read_only "$SQL_DIR/03_verify_backup_read_only.sql"
static_read_only "$SQL_DIR/05_verify_read_only.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: statische Form stimmt nicht — der Lock-Test waere nicht aussagekraeftig."
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
# 2) Vorlage-Datenbank: Value-Add-Production-Zustand + N4-Vorwerte
# ===========================================================================
head1 "Fixture — Value-Add-Zustand aus den Originaldateien 02 bis 04"
CURRENT_CASE=fixture
CREATEDB_RC=0
"$CREATEDB" cbb_fixture || CREATEDB_RC=$?
log "createdb cbb_fixture exit=$CREATEDB_RC"
if [[ $CREATEDB_RC -ne 0 ]]; then
  fail_setup "createdb cbb_fixture fehlgeschlagen (exit=$CREATEDB_RC)."
fi

step cbb_fixture ok fx_roles         "$VA_TEST/fixture/00_roles.sql"
step cbb_fixture ok fx_schema        "$VA_TEST/fixture/01_schema.sql"
step cbb_fixture ok fx_seed          "$VA_TEST/fixture/02_seed.sql"
step cbb_fixture ok fx_real_trigger  "$REPO_SUPABASE/seo_updated_at_trigger.sql"
step cbb_fixture ok fx_assert        "$VA_TEST/fixture/03_assert_fixture.sql"
step cbb_fixture ok fx_baseline      "$VA_TEST/fixture/04_baseline.sql"
step cbb_fixture ok va_02_migrate    "$VA_DIR/02_migrate_value_add.sql"
step cbb_fixture ok va_03_backup     "$VA_DIR/03_backup_value_add.sql"
step cbb_fixture ok va_04_backfill   "$VA_DIR/04_backfill_value_add.sql"
step cbb_fixture ok va_04_assert     "$VA_TEST/cases/assert_after_04.sql"
step cbb_fixture ok n4_pre_values    "$HERE/cases/setup_n4_production_pre_values.sql"
step cbb_fixture ok n4_base_assert   "$HERE/cases/assert_base_state.sql"
step cbb_fixture ok n4_baseline      "$HERE/cases/baseline_n4.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: Vorlage-Datenbank ist nicht sauber, weitere Ergebnisse waeren wertlos."
  exit 1
fi

# ===========================================================================
# CASE A — Happy Path 01 -> 05 in der vorgesehenen Reihenfolge
# ===========================================================================
new_case case_a_happy_path "01 bis 05 in Reihenfolge"
report_table case_a_happy_path a_01_preflight "$SQL_DIR/01_preflight_read_only.sql" 18
step         case_a_happy_path ok a_02_backup "$SQL_DIR/02_backup_n4_content.sql"
report_table case_a_happy_path a_03_verify_backup "$SQL_DIR/03_verify_backup_read_only.sql" 10
step         case_a_happy_path ok a_04_correct "$SQL_DIR/04_correct_n4_content.sql"
report_table case_a_happy_path a_05_verify "$SQL_DIR/05_verify_read_only.sql" 18
step         case_a_happy_path ok a_04_assert "$HERE/cases/assert_after_04.sql"
# Nach der Korrektur darf 01 nicht mehr still PASS melden.
report_table_expect_fail case_a_happy_path a_01_nach_fix \
  "$SQL_DIR/01_preflight_read_only.sql" n4_vorzustand_vollstaendig

# ===========================================================================
# CASE B — Fail-closed-Wiederholungen und Reihenfolge-Verstoesse
# ===========================================================================
new_case case_b_wiederholungen "Doppelausfuehrung und falsche Reihenfolge"
step case_b_wiederholungen fail b_03_vor_02 \
  "$SQL_DIR/03_verify_backup_read_only.sql" \
  'relation "cbb_private_backup.n4_content_pre_fix_v1" does not exist'
step case_b_wiederholungen fail b_05_vor_02 \
  "$SQL_DIR/05_verify_read_only.sql" \
  'relation "cbb_private_backup.n4_content_pre_fix_v1" does not exist'
step case_b_wiederholungen fail b_04_ohne_backup \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: privates Backup n4_content_pre_fix_v1 fehlt.'
step case_b_wiederholungen fail b_06_ohne_backup \
  "$SQL_DIR/06_restore_n4_content.sql" \
  'N4-Restore abgebrochen: privates Backup n4_content_pre_fix_v1 fehlt.'
step case_b_wiederholungen ok   b_backup_absent "$HERE/cases/assert_backup_absent.sql"
step case_b_wiederholungen ok   b_02_backup     "$SQL_DIR/02_backup_n4_content.sql"
step case_b_wiederholungen fail b_02_wiederholung \
  "$SQL_DIR/02_backup_n4_content.sql" \
  'N4-Backup abgebrochen: n4_content_pre_fix_v1 existiert bereits.'
step case_b_wiederholungen ok   b_04_correct    "$SQL_DIR/04_correct_n4_content.sql"
step case_b_wiederholungen fail b_04_wiederholung \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: N4-Vorzustand weicht vom erwarteten Stand ab.'
step case_b_wiederholungen ok   b_04_unveraendert "$HERE/cases/assert_after_04.sql"

# ===========================================================================
# CASE C — Falscher Vorwert in products
# ===========================================================================
new_case case_c_falscher_vorwert "products weicht vom erwarteten Vorzustand ab"
step case_c_falscher_vorwert ok   c_setup "$HERE/cases/setup_wrong_pre_value.sql"
step case_c_falscher_vorwert fail c_02_abbruch \
  "$SQL_DIR/02_backup_n4_content.sql" \
  'N4-Backup abgebrochen: N4-Vorzustand weicht vom erwarteten Stand ab.'
step case_c_falscher_vorwert ok   c_backup_absent "$HERE/cases/assert_backup_absent.sql"
step case_c_falscher_vorwert ok   c_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"

new_case case_c2_drift_nach_backup "products driftet zwischen 02 und 04"
step case_c2_drift_nach_backup ok   c2_02_backup "$SQL_DIR/02_backup_n4_content.sql"
step case_c2_drift_nach_backup ok   c2_drift     "$HERE/cases/setup_wrong_pre_value.sql"
step case_c2_drift_nach_backup fail c2_04_abbruch \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: N4-Vorzustand weicht vom erwarteten Stand ab.'
step case_c2_drift_nach_backup ok   c2_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"

# ===========================================================================
# CASE D — Manipuliertes, geleertes und geoeffnetes Backup
# ===========================================================================
new_case case_d_backup_manipuliert "Backup-Inhalt veraendert"
step case_d_backup_manipuliert ok   d_02_backup "$SQL_DIR/02_backup_n4_content.sql"
step case_d_backup_manipuliert ok   d_tamper    "$HERE/cases/setup_tamper_backup.sql"
step case_d_backup_manipuliert fail d_04_abbruch \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: Backup entspricht nicht dem erwarteten Vorzustand.'
step case_d_backup_manipuliert ok   d_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"

new_case case_d2_backup_leer "Backup-Tabelle existiert, ist aber leer"
step case_d2_backup_leer ok   d2_02_backup "$SQL_DIR/02_backup_n4_content.sql"
step case_d2_backup_leer ok   d2_leeren    "$HERE/cases/setup_empty_backup.sql"
step case_d2_backup_leer fail d2_04_abbruch \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: Backup hat 0/1 Zeilen.'
step case_d2_backup_leer fail d2_06_abbruch \
  "$SQL_DIR/06_restore_n4_content.sql" \
  'N4-Restore abgebrochen: Backup hat 0/1 Zeilen.'
step case_d2_backup_leer ok   d2_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"

new_case case_d3_backup_offen "Backup fuer anon lesbar gemacht"
step case_d3_backup_offen ok   d3_02_backup "$SQL_DIR/02_backup_n4_content.sql"
step case_d3_backup_offen ok   d3_grant     "$HERE/cases/setup_grant_backup_to_anon.sql"
step case_d3_backup_offen fail d3_04_abbruch \
  "$SQL_DIR/04_correct_n4_content.sql" \
  'N4-Korrektur abgebrochen: Backup unsicher (1 Rechte fuer PUBLIC/anon/authenticated/service_role).'
# 06 schreibt AUS dem Backup und muss denselben Befund ebenfalls hart nehmen.
# Erwartet wird die exakte Zaehlerkombination: direkter GRANT an anon ist
# gleichzeitig ein direkter und ein effektiver Treffer auf der Tabelle.
step case_d3_backup_offen fail d3_06_abbruch \
  "$SQL_DIR/06_restore_n4_content.sql" \
  'N4-Restore abgebrochen: Backup unsicher (fuer PUBLIC/anon/authenticated: direkt Tabelle 1, direkt Schema 0, effektiv Tabelle 1, effektiv Schema 0).'
step case_d3_backup_offen ok   d3_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"
# 03 muss denselben Befund als FAIL-Zeile melden, nicht still als PASS.
report_table_expect_fail case_d3_backup_offen d3_03_meldet_fail \
  "$SQL_DIR/03_verify_backup_read_only.sql" backup_tabellenrechte_app_rollen

# ---------------------------------------------------------------------------
# CASE D4 — geerbte, NUR EFFEKTIVE Rechte fuer anon
#   Kein direkter GRANT an anon: das SELECT liegt bei einer Hilfsrolle, anon ist
#   Mitglied. In den direkten ACLs ist anon unsichtbar — nur
#   has_table_privilege sieht das Recht. Genau dieser Fall belegt, dass die
#   effektive Rechtepruefung in 06 nicht nur Zierde ist.
# ---------------------------------------------------------------------------
new_case case_d4_rechte_geerbt "Backup nur ueber Rollenmitgliedschaft fuer anon lesbar"
step case_d4_rechte_geerbt ok   d4_02_backup "$SQL_DIR/02_backup_n4_content.sql"
step case_d4_rechte_geerbt ok   d4_hilfsrolle \
  "$HERE/cases/setup_grant_backup_via_hilfsrolle.sql"
step case_d4_rechte_geerbt fail d4_06_abbruch \
  "$SQL_DIR/06_restore_n4_content.sql" \
  'N4-Restore abgebrochen: Backup unsicher (fuer PUBLIC/anon/authenticated: direkt Tabelle 0, direkt Schema 0, effektiv Tabelle 1, effektiv Schema 0).'
step case_d4_rechte_geerbt ok   d4_kein_zieltext "$HERE/cases/assert_kein_zieltext.sql"
# Rollen sind clusterweit: ohne Teardown verfaelscht der Fall alle spaeteren.
step case_d4_rechte_geerbt ok   d4_teardown "$HERE/cases/teardown_hilfsrolle.sql"

# ---------------------------------------------------------------------------
# CASE D5 — manipuliertes Backup gegen 06
#   Das Backup ist hier die DATENQUELLE des Schreibvorgangs. 06 muss den
#   Inhalt gegen den bekannten Vorzustand pruefen und darf fremden Text nicht
#   nach public.products schreiben.
# ---------------------------------------------------------------------------
new_case case_d5_manipuliertes_backup_restore "manipuliertes Backup darf nicht zurueckgeschrieben werden"
step case_d5_manipuliertes_backup_restore ok   d5_02_backup  "$SQL_DIR/02_backup_n4_content.sql"
step case_d5_manipuliertes_backup_restore ok   d5_04_correct "$SQL_DIR/04_correct_n4_content.sql"
step case_d5_manipuliertes_backup_restore ok   d5_04_assert  "$HERE/cases/assert_after_04.sql"
step case_d5_manipuliertes_backup_restore ok   d5_tamper     "$HERE/cases/setup_tamper_backup.sql"
step case_d5_manipuliertes_backup_restore fail d5_06_abbruch \
  "$SQL_DIR/06_restore_n4_content.sql" \
  'N4-Restore abgebrochen: Backup entspricht nicht dem bekannten Vorzustand.'
step case_d5_manipuliertes_backup_restore ok   d5_products_unveraendert \
  "$HERE/cases/assert_products_ziel_unveraendert.sql"

# ===========================================================================
# CASE E — Restore und Round-Trip
# ===========================================================================
new_case case_e_restore "02 -> 04 -> 06 mit exaktem Round-Trip"
step case_e_restore ok e_02_backup     "$SQL_DIR/02_backup_n4_content.sql"
step case_e_restore ok e_04_correct    "$SQL_DIR/04_correct_n4_content.sql"
step case_e_restore ok e_04_assert     "$HERE/cases/assert_after_04.sql"
step case_e_restore ok e_06_restore    "$SQL_DIR/06_restore_n4_content.sql"
step case_e_restore ok e_06_assert     "$HERE/cases/assert_after_06.sql"
step case_e_restore ok e_06_wiederholung "$SQL_DIR/06_restore_n4_content.sql"
step case_e_restore ok e_06_assert_2   "$HERE/cases/assert_after_06.sql"
# Nach dem Restore ist der Vorzustand wieder da: 04 darf erneut laufen.
step case_e_restore ok e_04_erneut     "$SQL_DIR/04_correct_n4_content.sql"
step case_e_restore ok e_04_assert_2   "$HERE/cases/assert_after_04.sql"
report_table case_e_restore e_05_verify "$SQL_DIR/05_verify_read_only.sql" 18

# ===========================================================================
# CASE G — echter Konkurrenztest fuer 02
# ===========================================================================
# Die zweite Session aendert pros — ein Feld, das die frueher zu kurz greifende
# Nachpruefung von 02 NICHT abgedeckt hat. pros steht ausserdem nicht in der
# Spaltenliste des Triggers products_set_updated_at, updated_at bleibt also
# gleich. 02 kann die Aenderung damit nur ueber die vollstaendige
# Vorzustandspruefung nach dem Lock bemerken — nicht ueber einen
# Zeitstempelvergleich.
new_case case_g_konkurrenz_02 "zweite Session aendert pros, waehrend 02 auf den Lock wartet"
step case_g_konkurrenz_02 ok g_backup_absent "$HERE/cases/assert_backup_absent.sql"
konkurrenz_lauf case_g_konkurrenz_02 "$LABEL_G" \
  "$SQL_DIR/02_backup_n4_content.sql" \
  "update public.products set pros = array['CBB-TEST: konkurrierende Aenderung an pros']::text[] where slug = 'n4-nussmilchbereiter-pflanzenmilch';" \
  'N4-Backup abgebrochen: N4-Zeile wurde zwischen Vorpruefung und Sperre veraendert.'
step case_g_konkurrenz_02 ok g_assert "$HERE/cases/assert_konkurrenz_pros.sql"
step case_g_konkurrenz_02 ok g_backup_absent_2 "$HERE/cases/assert_backup_absent.sql"

# ===========================================================================
# CASE H — echter Konkurrenztest fuer 04
# ===========================================================================
# Erst ein sauberes Backup aus 02. Danach aendert die zweite Session nicht_fuer
# — ein Feld ausserhalb der Spaltenliste des Triggers products_set_updated_at,
# updated_at bleibt also unveraendert. Ein reiner ZEITSTEMPELvergleich wuerde
# die Aenderung deshalb nicht bemerken.
#
# Der vollstaendige Driftvergleich gegen das Backup erfasst nicht_fuer dagegen
# sehr wohl — die Spalte ist Teil des verglichenen Vorzustands. Bewiesen wird
# hier also NICHT, dass die Aenderung anders unsichtbar bliebe, sondern der
# Zeitpunkt: 04 hat seine sperrfreie Vorpruefung bereits bestanden, als die
# Konkurrenz noch nicht committet war. Nur die ERNEUTE Vorzustandspruefung nach
# dem erworbenen Lock sieht den neuen Stand — und genau die muss 04 abbrechen
# lassen, statt den Zieltext darueberzuschreiben.
new_case case_h_konkurrenz_04 "zweite Session aendert nicht_fuer, waehrend 04 auf den Lock wartet"
step case_h_konkurrenz_04 ok h_02_backup "$SQL_DIR/02_backup_n4_content.sql"
konkurrenz_lauf case_h_konkurrenz_04 "$LABEL_H" \
  "$SQL_DIR/04_correct_n4_content.sql" \
  "update public.products set nicht_fuer = 'CBB-TEST: konkurrierende Aenderung an nicht_fuer' where slug = 'n4-nussmilchbereiter-pflanzenmilch';" \
  'N4-Korrektur abgebrochen: N4-Zeile wurde zwischen Vorpruefung und Sperre veraendert.'
step case_h_konkurrenz_04 ok h_assert "$HERE/cases/assert_konkurrenz_nicht_fuer.sql"

# ===========================================================================
# CASE F — Lock-Timeout: 02 muss unter Sperrkonflikt nach ~5 s abbrechen
# ===========================================================================
new_case case_f_lock_timeout "AccessExclusiveLock blockiert 02"
step case_f_lock_timeout ok f_vorbereitung "$HERE/cases/assert_backup_absent.sql"

F_ERWARTET='canceling statement due to lock timeout'

# Der Lock-Halter braucht keine eigene Datei: psql -c schickt die ganze
# Zeichenkette als EINEN Query-String, der serverseitig in genau einer
# impliziten Transaktion laeuft. Die Sperre steht damit ab dem LOCK TABLE und
# haelt bis zum ROLLBACK bzw. bis pg_terminate_backend.
PGAPPNAME="$LOCK_APP" "$PSQL" -X -q -d case_f_lock_timeout -c \
  "begin; lock table public.products in access exclusive mode; select pg_sleep(90); rollback;" \
  > "$LOGDIR/900_locker.log" 2>&1 &
LOCKER_PID=$!

# pg_locks ist clusterweit, pg_class aber datenbanklokal. Die Abfrage laeuft
# deshalb IN case_f_lock_timeout und filtert zusaetzlich auf dessen OID.
lock_held_count() {
  "$PSQL" -X -q -A -t -d case_f_lock_timeout -c \
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
# F.1 — 02 unter der Sperre. Erwartet: Exit 3 mit der Lock-Timeout-Meldung nach
# rund 5 Sekunden. Exit 124 (Client-Timeout), ein anderer Fehler oder ein
# Erfolg sind FAIL.
# ---------------------------------------------------------------------------
STEP=$((STEP + 1))
F_OUT="$LOGDIR/$(printf '%03d' "$STEP")_f_02_unter_sperre.log"
F_DIAG="$LOGDIR/$(printf '%03d' "$STEP")_f_02_wartet_auf.log"
F_RC=0
F_ELAPSED=-1

if [[ $LOCK_HELD -ne 1 ]]; then
  mark_fail
  record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "-" FAIL \
    "Sperre konnte nicht aufgebaut werden — Fall nicht bewertbar"
else
  F_START=$SECONDS
  timeout 30 "$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_f_lock_timeout \
    -f "$SQL_DIR/02_backup_n4_content.sql" > "$F_OUT" 2>&1 &
  F_PSQL_PID=$!

  # Belegen, WO 02 haengt. Der Wartepunkt muss bereits unter dem gesetzten
  # lock_timeout liegen.
  for _ in $(seq 1 10); do
    "$PSQL" -X -q -d postgres -c "
      select a.pid, a.state, a.wait_event_type, a.wait_event,
             left(regexp_replace(a.query, '\s+', ' ', 'g'), 80) as blockiertes_statement
      from pg_stat_activity a
      where a.datname = 'case_f_lock_timeout'
        and a.wait_event_type = 'Lock'" > "$F_DIAG" 2>&1
    grep -q 'Lock' "$F_DIAG" && break
    "$PSQL" -X -q -A -t -d postgres -c "select pg_sleep(0.5)" >/dev/null 2>&1
  done
  cat "$F_DIAG"

  wait "$F_PSQL_PID" || F_RC=$?
  F_ELAPSED=$((SECONDS - F_START))

  F_MSG="$(grep -m1 -E 'ERROR' "$F_OUT" | cut -c1-200)"
  if [[ $F_RC -eq 124 ]]; then
    mark_fail
    record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "$F_RC" FAIL \
      "Client-Timeout nach 30s: lock_timeout greift in der Guard-Phase nicht"
  elif [[ $F_RC -ne 3 ]]; then
    mark_fail
    record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "$F_RC" FAIL \
      "Exit $F_RC statt 3 nach ${F_ELAPSED}s — $F_MSG"
  elif ! grep -Fq -- "$F_ERWARTET" "$F_OUT"; then
    mark_fail
    record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "$F_RC" FAIL \
      "falscher Fehler. erwartet: <$F_ERWARTET> | tatsaechlich: $F_MSG"
  elif [[ $F_ELAPSED -lt 3 || $F_ELAPSED -gt 15 ]]; then
    mark_fail
    record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "$F_RC" FAIL \
      "richtige Meldung, aber Laufzeit ${F_ELAPSED}s ausserhalb 3-15s (lock_timeout='5s')"
  else
    record f_02_unter_sperre "02_backup_n4_content.sql" "fail/3" "$F_RC" PASS \
      "lock timeout nach ${F_ELAPSED}s: $F_ERWARTET"
  fi
fi

# ---------------------------------------------------------------------------
# F.2 — Lock-Halter zuverlaessig beenden (pg_terminate_backend ueber den
# eindeutigen application_name, nicht per kill des psql-Clients).
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
  record f_locker_terminiert "pg_terminate_backend" "lock frei" "-" PASS \
    "$TERMINATED Backend(s) via application_name=$LOCK_APP beendet, Sperre nach ${T_ELAPSED}s frei"
else
  mark_fail
  record f_locker_terminiert "pg_terminate_backend" "lock frei" "-" FAIL \
    "terminate-Ergebnis=<$TERMINATED>, Sperre nach ${T_ELAPSED}s frei=$LOCK_GONE"
fi

step case_f_lock_timeout ok f_backup_absent "$HERE/cases/assert_backup_absent.sql"

# Der Nachtest darf nicht auf das Ende von pg_sleep(90) warten.
N_START=$SECONDS
step case_f_lock_timeout ok f_02_danach "$SQL_DIR/02_backup_n4_content.sql"
N_ELAPSED=$((SECONDS - N_START))
log "  f_02_danach Laufzeit: ${N_ELAPSED}s (muss deutlich unter pg_sleep(90) liegen)"
if [[ $N_ELAPSED -gt 30 ]]; then
  mark_fail
  log "  [FAIL] f_02_danach brauchte ${N_ELAPSED}s — die Sperre wurde nicht wirklich geloest."
fi
report_table case_f_lock_timeout f_03_verify_backup \
  "$SQL_DIR/03_verify_backup_read_only.sql" 10

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
