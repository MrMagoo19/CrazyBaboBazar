#!/usr/bin/env bash
# =============================================================================
# LOKALER POSTGRESQL-HARNESS FUER DAS QUALITY-FIXES-PAKET 2026-08-30
# =============================================================================
# Testet die ORIGINALDATEIEN
#   supabase/production_quality_fixes_20260830/01_preflight_read_only.sql
#   ... bis 06_restore_quality_fixes.sql
# UNVERAENDERT gegen eine echte PostgreSQL-16-Instanz. Der Harness kopiert,
# patcht oder generiert keine SQL des Pakets — er fuehrt genau die Dateien aus,
# die spaeter auf Production laufen wuerden.
#
# Der Harness fasst KEINE Production- und KEINE Pilot-Datenbank an. Er kennt
# weder Host noch Projekt-Ref von ydiihvzcxaaoqhmgoqvu (Production) oder
# nmzuycveumyfvtxdcnuc (Pilot). Er startet einen eigenen Cluster in einem
# mktemp-Verzeichnis, der ausschliesslich ueber einen Unix-Socket erreichbar
# ist (listen_addresses=''), und stoppt ihn am Ende per trap.
#
# AUSGANGSZUSTAND
#   Die Vorlage-Datenbank cbb_fixture bildet den Production-Vorzustand vom
#   2026-08-30 nach. Sie entsteht aus
#     * test/fixture/00_roles.sql   Supabase-aehnliche Rollen
#     * test/fixture/01_schema.sql  Production-aehnliches Schema
#     * test/fixture/02_seed.sql    sieben Zielprodukte, drei Ziellisten,
#                                   beide A4-Zielprodukte, >= 300 Produkte
#     * supabase/seo_updated_at_trigger.sql   der ECHTE Trigger, unveraendert
#     * test/fixture/03_baseline.sql          Fingerabdruck des Vorzustands
#     * test/cases/assert_base_state.sql      Gegenprobe
#
# SCHAERFE DER ERWARTUNGEN
#   * Ein erwarteter Abbruch gilt NUR dann als PASS, wenn psql mit Exit 3
#     zurueckkommt UND die konkrete erwartete Servermeldung im Output steht.
#     Ein anderer Fehler ist FAIL, kein PASS. "Irgendein Exit != 0" reicht nie.
#   * report_table verlangt EXAKTE PASS-Zahlen: 01 -> 22, 03 -> 16, 05 -> 23,
#     jeweils bei 0 FAIL-Zeilen. Eine geschrumpfte Pruefliste faellt damit auf.
#   * report_table_expect_fail verlangt umgekehrt eine benannte FAIL-Zeile.
#   * Der Lock-Test verlangt Exit 3, die Meldung
#     "canceling statement due to lock timeout" und eine Laufzeit um 5 s.
#     Exit 124 (Client-Timeout), ein anderer Text oder ein Erfolg sind FAIL.
#   * Die beiden Konkurrenztests sind echt, nicht simuliert: eine zweite
#     Session haelt den Row-Lock und aendert ein Feld, der Paketlauf wird
#     nachweislich beim Warten auf den Lock beobachtet
#     (pg_stat_activity.wait_event_type = 'Lock'), erst danach commitet die
#     Konkurrenz. PASS nur bei Exit 3 mit der Recheck-Meldung. Ein Durchlauf,
#     ein Lock-Timeout oder ein fehlender Wartepunkt-Nachweis sind FAIL.
#   * Statisch wird geprueft, dass in 02, 04 und 06 beide SET-LOCAL-Zeilen
#     direkt hinter "begin;" und vor dem ersten DO-Block stehen, dass 01, 03
#     und 05 kein einziges schreibendes Statement enthalten, und dass KEINE der
#     sechs Dateien ein DROP, DELETE oder TRUNCATE enthaelt.
#   * Ebenfalls statisch: jeder im Lauf gesetzte application_name bleibt unter
#     der PostgreSQL-Grenze NAMEDATALEN-1 = 63 Byte. Ein gekuerzter Name macht
#     die exakte Wartepunkt-Suche in pg_stat_activity unbrauchbar.
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
SQL_DIR="$(cd "$HERE/.." && pwd)"           # production_quality_fixes_20260830/
REPO_SUPABASE="$(cd "$SQL_DIR/.." && pwd)"  # apps/web/supabase/
TRIGGER_SQL="$REPO_SUPABASE/seo_updated_at_trigger.sql"

for f in \
  "$SQL_DIR/01_preflight_read_only.sql" \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  "$SQL_DIR/03_verify_backup_read_only.sql" \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  "$SQL_DIR/05_verify_read_only.sql" \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  "$TRIGGER_SQL"
do
  if [[ ! -f "$f" ]]; then
    echo "FEHLT: $f" >&2
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
#      /tmp-Default; ein solcher Pfad ist nach einem Reboot tot.
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

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cbb-qftest.XXXXXXXX")"
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
# Deshalb ein kurzer, deterministischer Praefix aus dem mktemp-Suffix.
PG_APPNAME_MAX=63
WORK_ID="$(basename "$WORKDIR")"
WORK_ID="${WORK_ID##*.}"                # die 8 Zufallszeichen aus mktemp
LOCK_APP="cbb_qf_${WORK_ID}"            # 15 Zeichen, z. B. cbb_qf_a1b2c3d4

# Die Labels der beiden Konkurrenzfaelle stehen hier zentral, damit die
# statische Laengenpruefung genau die Namen sieht, die spaeter wirklich
# gesetzt werden.
LABEL_G=g_02_konkurrenz
LABEL_H=h_04_konkurrenz

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
#                   FAIL.
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
#   PASS-Zeilen und 0 FAIL-Zeilen.
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
#   Pruefung eine FAIL-Zeile liefern.
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
# static_kein_drop_delete <sql-datei>
#   Das Paket sichert Zeilen und stellt sie wieder her. Es loescht nichts —
#   weder eine Zeile noch eine Tabelle. Geprueft wird das statisch ueber alle
#   sechs Dateien, damit die Zusage nicht nur im Runbook steht.
#   Kommentarzeilen werden uebersprungen. Zwei Wendungen sind ausdruecklich
#   erlaubt und werden vorher herausgeschnitten:
#     * "on commit drop"  — die Lebensdauer einer TEMPORARY-Tabelle. Sie loescht
#       nichts an den Nutzdaten, sondern raeumt nur die Transaktion auf.
#     * "'DELETE'" / "'TRUNCATE'" in Privilegienlisten — dort sind es Namen von
#       Rechten, keine Anweisungen. Sie stehen in Anfuehrungszeichen und werden
#       von der Wortgrenze ohnehin nicht getroffen.
#   "deleted", "dropped" oder "attisdropped" duerfen nicht anschlagen.
# ---------------------------------------------------------------------------
static_kein_drop_delete() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="static_kein_drop_$(basename "$file" .sql)"
  local res
  res="$(awk '
    {
      l = $0
      gsub(/^[ \t]+/, "", l)
      if (substr(l, 1, 2) == "--") next
      lo = tolower(l)
      gsub(/on commit drop/, " ", lo)
      if (lo ~ /(^|[ \t;(])(drop|delete|truncate)([ \t;(]|$)/) {
        n++
        if (erste == "") erste = sprintf("Z%d: %s", NR, substr($0, 1, 70))
      }
    }
    END {
      if (n > 0) printf "PROBLEM|%d Treffer, erster %s\n", n, erste
      else       printf "OK|kein DROP, DELETE oder TRUNCATE ausserhalb von Kommentaren\n"
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
  record "$label" "$(basename "$file")" "kein DROP/DELETE" "-" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# static_appnamen
#   Statischer Beweis, dass KEIN im Lauf gesetzter application_name die
#   PostgreSQL-Grenze NAMEDATALEN-1 = 63 Byte reisst.
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
# konkurrenz_lauf <db> <label> <paketdatei> <lock-sql> <konkurrenz-sql> <meldung>
#
# ECHTER Nebenlaeufigkeitstest, keine Simulation:
#   1. Eine zweite Session oeffnet eine Transaktion, sperrt die Zielzeile per
#      SELECT ... FOR UPDATE und aendert ein Feld. Sie commitet noch NICHT.
#   2. Die Paketdatei wird gestartet. Ihre sperrfreien Vorpruefungen sehen den
#      alten, committeten Stand und laufen durch; an ihrem eigenen FOR UPDATE
#      bleibt sie stehen. Dass sie WIRKLICH wartet, wird ueber pg_stat_activity
#      belegt (wait_event_type = 'Lock') und protokolliert. Ohne diesen
#      Nachweis ist der Fall FAIL, nicht PASS.
#   3. Erst dann commitet die Konkurrenz. Die Paketdatei erhaelt den Lock,
#      sieht den neuen Stand und MUSS wegen der erneuten Pruefung NACH dem Lock
#      abbrechen.
#
# PASS nur bei Exit 3 mit der erwarteten Meldung.
#   * Exit 0 = fremde Daten wurden ueberschrieben -> FAIL.
#   * "canceling statement due to lock timeout" = zu spaet commitet, der
#     Recheck nach dem Lock ist damit nicht bewiesen -> FAIL.
#   * jeder andere Fehler -> FAIL.
#
# FD-REIHENFOLGE: erst den FIFO-LESER starten, dann fd 8 als REINES
# Schreibende oeffnen. Wuerde fd 8 vorher geoeffnet, erbte der psql-Kindprozess
# ein eigenes Schreibende, saehe nach "exec 8>&-" nie EOF und "wait" haengte
# unbegrenzt. Aus demselben Grund starten alle Hintergrundprozesse mit "8>&-".
# ---------------------------------------------------------------------------
konkurrenz_lauf() {
  local db="$1" label="$2" file="$3" lock_sql="$4" konkurrenz_sql="$5" want="$6"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local fifo="$WORKDIR/${label}.fifo"
  local marker='CBB-TEST: konkurrierende Aenderung'

  local app_hold app_target laenge_ok=1
  app_hold="$(appname hold "$label")"   || laenge_ok=0
  app_target="$(appname ziel "$label")" || laenge_ok=0
  if [[ $laenge_ok -ne 1 ]]; then
    mark_fail
    record "$label" "$(basename "$file")" "fail/3" "-" FAIL \
      "application_name zu lang (${#app_hold}/${#app_target} Zeichen, Grenze $PG_APPNAME_MAX)"
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
  # deshalb ignoriert; der tote Leser wird als FAIL protokolliert.
  trap '' PIPE

  PGAPPNAME="$app_hold" "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$fifo" \
    > "$base.konkurrenz.log" 2>&1 &
  local holder_pid=$!

  # "exec 8>fifo" blockiert, bis ein Leser die FIFO geoeffnet hat — psql
  # oeffnet die -f-Datei aber erst nach erfolgreichem Verbindungsaufbau.
  # Stirbt es vorher, gaebe es nie einen Leser und der Harness haengte hier.
  # Ein Wachhund oeffnet die Leseseite deshalb notfalls selbst.
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

  printf '%s\n' 'begin;' "$lock_sql" "$konkurrenz_sql" >&8

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

  # 8>&- : der Ziellauf darf das Schreibende NICHT erben.
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
head1 "case_0_statisch — Form der sechs Originaldateien"
CURRENT_CASE=case_0_statisch
static_appnamen
static_set_local "$SQL_DIR/02_backup_quality_fixes.sql"
static_set_local "$SQL_DIR/04_apply_quality_fixes.sql"
static_set_local "$SQL_DIR/06_restore_quality_fixes.sql"
static_read_only "$SQL_DIR/01_preflight_read_only.sql"
static_read_only "$SQL_DIR/03_verify_backup_read_only.sql"
static_read_only "$SQL_DIR/05_verify_read_only.sql"
static_kein_drop_delete "$SQL_DIR/01_preflight_read_only.sql"
static_kein_drop_delete "$SQL_DIR/02_backup_quality_fixes.sql"
static_kein_drop_delete "$SQL_DIR/03_verify_backup_read_only.sql"
static_kein_drop_delete "$SQL_DIR/04_apply_quality_fixes.sql"
static_kein_drop_delete "$SQL_DIR/05_verify_read_only.sql"
static_kein_drop_delete "$SQL_DIR/06_restore_quality_fixes.sql"

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
# 2) Vorlage-Datenbank
# ===========================================================================
head1 "Fixture — Production-Vorzustand vom 2026-08-30"
CURRENT_CASE=fixture
CREATEDB_RC=0
"$CREATEDB" cbb_fixture || CREATEDB_RC=$?
log "createdb cbb_fixture exit=$CREATEDB_RC"
if [[ $CREATEDB_RC -ne 0 ]]; then
  fail_setup "createdb cbb_fixture fehlgeschlagen (exit=$CREATEDB_RC)."
fi

step cbb_fixture ok fx_roles        "$HERE/fixture/00_roles.sql"
step cbb_fixture ok fx_schema       "$HERE/fixture/01_schema.sql"
step cbb_fixture ok fx_seed         "$HERE/fixture/02_seed.sql"
step cbb_fixture ok fx_real_trigger "$TRIGGER_SQL"
step cbb_fixture ok fx_baseline     "$HERE/fixture/03_baseline.sql"
step cbb_fixture ok fx_assert       "$HERE/cases/assert_base_state.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: Vorlage-Datenbank ist nicht sauber, weitere Ergebnisse waeren wertlos."
  exit 1
fi

# ===========================================================================
# CASE A — Happy Path 01 -> 05 in der vorgesehenen Reihenfolge, plus Idempotenz
# ===========================================================================
new_case case_a_happy_path "01 bis 05 in Reihenfolge, danach 02 und 04 wiederholt"
report_table case_a_happy_path a_01_preflight "$SQL_DIR/01_preflight_read_only.sql" 22
step         case_a_happy_path ok a_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
report_table case_a_happy_path a_03_verify_backup "$SQL_DIR/03_verify_backup_read_only.sql" 16
# 02 ein zweites Mal: identischer Snapshot -> No-Op, kein Abbruch.
step         case_a_happy_path ok a_02_wiederholung "$SQL_DIR/02_backup_quality_fixes.sql"
report_table case_a_happy_path a_03_nach_wiederholung "$SQL_DIR/03_verify_backup_read_only.sql" 16
step         case_a_happy_path ok a_base_noch_da "$HERE/cases/assert_base_state.sql"
step         case_a_happy_path ok a_04_apply "$SQL_DIR/04_apply_quality_fixes.sql"
report_table case_a_happy_path a_05_verify "$SQL_DIR/05_verify_read_only.sql" 23
step         case_a_happy_path ok a_04_assert "$HERE/cases/assert_after_04.sql"
# Nach der Korrektur darf 01 nicht mehr still PASS melden.
report_table_expect_fail case_a_happy_path a_01_nach_fix \
  "$SQL_DIR/01_preflight_read_only.sql" noch_keine_zeile_im_zielzustand
# 04 ein zweites Mal: exakter Zielzustand -> No-Op, kein neues updated_at.
step case_a_happy_path ok a_snapshot        "$HERE/cases/snapshot_nach_04.sql"
step case_a_happy_path ok a_04_wiederholung "$SQL_DIR/04_apply_quality_fixes.sql"
step case_a_happy_path ok a_04_noop_assert  "$HERE/cases/assert_04_unveraendert.sql"
report_table case_a_happy_path a_05_nach_wiederholung "$SQL_DIR/05_verify_read_only.sql" 23

# ===========================================================================
# CASE B — Reihenfolge-Verstoesse und fehlendes Backup
# ===========================================================================
new_case case_b_reihenfolge "03, 05, 04 und 06 ohne Backup"
step case_b_reihenfolge fail b_03_vor_02 \
  "$SQL_DIR/03_verify_backup_read_only.sql" '_v1" does not exist'
step case_b_reihenfolge fail b_05_vor_02 \
  "$SQL_DIR/05_verify_read_only.sql" '_v1" does not exist'
step case_b_reihenfolge fail b_04_ohne_backup \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: privates Backup fehlt.'
step case_b_reihenfolge fail b_06_ohne_backup \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: privates Backup fehlt.'
step case_b_reihenfolge ok b_backup_absent "$HERE/cases/assert_backup_absent.sql"
step case_b_reihenfolge ok b_base_state    "$HERE/cases/assert_base_state.sql"

# ===========================================================================
# CASE C — falscher Vorwert vor 02
# ===========================================================================
new_case case_c_falscher_vorwert "products weicht vor 02 vom Vorzustand ab"
step case_c_falscher_vorwert ok   c_setup "$HERE/cases/setup_wrong_pre_value.sql"
step case_c_falscher_vorwert fail c_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: Vorzustand weicht ab'
step case_c_falscher_vorwert ok c_backup_absent   "$HERE/cases/assert_backup_absent.sql"
step case_c_falscher_vorwert ok c_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE C2 — Drift zwischen 02 und 04
# ===========================================================================
new_case case_c2_drift_nach_backup "ein Vorwert driftet zwischen 02 und 04"
step case_c2_drift_nach_backup ok   c2_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_c2_drift_nach_backup ok   c2_drift     "$HERE/cases/setup_wrong_pre_value.sql"
step case_c2_drift_nach_backup fail c2_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: gemischter oder gedrifteter Zustand'
step case_c2_drift_nach_backup ok c2_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE C3 — Drift in einer Spalte, die das Paket gar nicht anfasst
# ===========================================================================
new_case case_c3_fremdspalte "tagline driftet zwischen 02 und 04"
step case_c3_fremdspalte ok   c3_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_c3_fremdspalte ok   c3_drift     "$HERE/cases/setup_fremdspalte_drift.sql"
step case_c3_fremdspalte fail c3_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'Abweichungen zwischen Backup und public.products nach dem Lock'
step case_c3_fremdspalte ok c3_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE C4 — gemischter Zustand
# ===========================================================================
new_case case_c4_gemischt "eine Zeile steht bereits im Zielzustand, neun nicht"
step case_c4_gemischt ok   c4_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_c4_gemischt ok   c4_setup     "$HERE/cases/setup_gemischter_zustand.sql"
step case_c4_gemischt fail c4_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: gemischter oder gedrifteter Zustand'
step case_c4_gemischt ok c4_assert "$HERE/cases/assert_nur_gemischte_zeile.sql"

# ===========================================================================
# CASE C5 — fehlende Zielzeile
# ===========================================================================
new_case case_c5_fehlende_zeile "eine der sieben Zielproduktzeilen existiert nicht mehr"
step case_c5_fehlende_zeile ok   c5_setup "$HERE/cases/setup_fehlende_zielzeile.sql"
step case_c5_fehlende_zeile fail c5_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: Vorzustand weicht ab'
step case_c5_fehlende_zeile ok   c5_backup_absent "$HERE/cases/assert_backup_absent.sql"
step case_c5_fehlende_zeile fail c5_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: privates Backup fehlt.'
step case_c5_fehlende_zeile ok   c5_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE D — manipuliertes Backup
# ===========================================================================
new_case case_d_backup_manipuliert "Backup-Inhalt veraendert"
step case_d_backup_manipuliert ok   d_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d_backup_manipuliert ok   d_tamper    "$HERE/cases/setup_tamper_backup.sql"
step case_d_backup_manipuliert fail d_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: Backup entspricht nicht dem bekannten Vorzustand'
step case_d_backup_manipuliert fail d_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: Backup entspricht nicht dem bekannten Vorzustand'
step case_d_backup_manipuliert fail d_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: vorhandenes Backup entspricht nicht dem bekannten Vorzustand'
step case_d_backup_manipuliert ok d_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE D2 — Backup existiert, ist aber leer
# ===========================================================================
new_case case_d2_backup_leer "Backup-Tabelle existiert, ist aber leer"
step case_d2_backup_leer ok   d2_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d2_backup_leer ok   d2_leeren    "$HERE/cases/setup_empty_backup.sql"
step case_d2_backup_leer fail d2_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: Backup hat 0/7 Produkt- und 3/3 Listenzeilen.'
step case_d2_backup_leer fail d2_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: Backup hat 0/7 Produkt- und 3/3 Listenzeilen.'
step case_d2_backup_leer fail d2_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: vorhandenes Backup hat 0/7 Produkt- und 3/3 Listenzeilen.'
step case_d2_backup_leer ok d2_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE D3 — halbes Backup
# ===========================================================================
new_case case_d3_halbes_backup "nur eine der beiden Backup-Tabellen existiert"
step case_d3_halbes_backup ok   d3_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d3_halbes_backup ok   d3_setup     "$HERE/cases/setup_halbes_backup.sql"
step case_d3_halbes_backup fail d3_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: nur eine der beiden Backup-Tabellen existiert'
step case_d3_halbes_backup fail d3_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: privates Backup fehlt.'
step case_d3_halbes_backup ok d3_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE D4 — Backup direkt fuer anon geoeffnet
# ===========================================================================
new_case case_d4_backup_offen "direkter GRANT SELECT an anon"
step case_d4_backup_offen ok   d4_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d4_backup_offen ok   d4_grant     "$HERE/cases/setup_grant_backup_to_anon.sql"
step case_d4_backup_offen fail d4_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt 1, effektiv 1).'
step case_d4_backup_offen fail d4_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt 1, effektiv 1).'
# 03 muss denselben Befund als FAIL-Zeile melden, nicht still als PASS.
report_table_expect_fail case_d4_backup_offen d4_03_meldet_fail \
  "$SQL_DIR/03_verify_backup_read_only.sql" backup_tabellenrechte_app_rollen
step case_d4_backup_offen ok d4_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE D5 — nur geerbte, effektive Rechte
# ===========================================================================
# Kein direkter GRANT an anon: das SELECT liegt bei einer Hilfsrolle, anon ist
# Mitglied. In den direkten ACLs ist anon unsichtbar — nur has_table_privilege
# sieht das Recht. Der Fall belegt, dass die effektive Rechtepruefung in 02,
# 04 und 06 nicht Zierde ist.
#
# Damit ueberhaupt ein geerbtes Recht entsteht, setzt das Setup anon fuer die
# Dauer dieses einen Negativfalls auf INHERIT — als NOINHERIT-Rolle (so legt
# fixture/00_roles.sql sie an, wie auf Supabase) erbt anon nichts, und der Fall
# waere ein Blindgaenger. Das Setup weist selbst nach, dass danach direkt 0 und
# effektiv 1 gilt; das Teardown stellt NOINHERIT wieder her.
new_case case_d5_rechte_geerbt "Backup nur ueber Rollenmitgliedschaft lesbar"
step case_d5_rechte_geerbt ok   d5_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d5_rechte_geerbt ok   d5_hilfsrolle \
  "$HERE/cases/setup_grant_backup_via_hilfsrolle.sql"
step case_d5_rechte_geerbt fail d5_02_wiederholung_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'vorhandene Backup-Tabelle cbb_private_backup.quality_fixes_20260830_products_v1 unsicher (RLS=t, Policies=0, direkt 0, effektiv 1).'
step case_d5_rechte_geerbt fail d5_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt 0, effektiv 1).'
step case_d5_rechte_geerbt fail d5_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'unsicher (fuer PUBLIC/anon/authenticated/service_role: direkt 0, effektiv 1).'
step case_d5_rechte_geerbt ok d5_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"
# Rollen UND Rollenattribute sind clusterweit: ohne Teardown (Hilfsrolle weg,
# anon wieder NOINHERIT) verfaelscht der Fall alle spaeteren.
step case_d5_rechte_geerbt ok d5_teardown "$HERE/cases/teardown_hilfsrolle.sql"

# ===========================================================================
# CASE I — eine App-Rolle fehlt, die Rechtepruefung ist damit blind
# ===========================================================================
# Alle Rechte-Zaehler in 02, 04 und 06 laufen ueber
#   pg_roles ... where rolname in ('anon', 'authenticated', 'service_role')
# Fehlt eine der beiden App-Rollen, faellt sie aus dem Join und der Zaehler
# meldet still 0 — kein Beleg fuer "keine Rechte", nur einer fuer "keine
# Rolle". 04 und 06 hatten dafuer bereits eine harte Vorbedingung; 02 nicht.
# Ausgerechnet der No-Op-Zweig von 02 (Backup existiert bereits) haette so eine
# Backup-Tabelle als sicher durchgewunken, deren Rechtelage gar nicht gemessen
# wurde. Der Fall belegt, dass alle drei schreibenden Dateien jetzt abbrechen.
#
# Die Rolle wird umbenannt statt geloescht: ACL-Eintraege haengen an der OID,
# ein DROP ROLE scheiterte an den Rechten in allen bereits angelegten
# Fall-Datenbanken. Rollen sind cluster-weit — Teardown ist deshalb Pflicht.
new_case case_i_rolle_fehlt "authenticated ist nicht mehr unter ihrem Namen vorhanden"
step case_i_rolle_fehlt ok i_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_i_rolle_fehlt ok i_setup     "$HERE/cases/setup_rolle_authenticated_geparkt.sql"
step case_i_rolle_fehlt fail i_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: 1/2 App-Rollen (anon, authenticated) vorhanden'
# 03 muss denselben Befund als FAIL-Zeile melden, nicht still als PASS.
report_table_expect_fail case_i_rolle_fehlt i_03_meldet_fail \
  "$SQL_DIR/03_verify_backup_read_only.sql" app_rollen_vorhanden
step case_i_rolle_fehlt fail i_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: 1/2 App-Rollen (anon, authenticated) vorhanden'
step case_i_rolle_fehlt fail i_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: 1/2 App-Rollen (anon, authenticated) vorhanden'
step case_i_rolle_fehlt ok i_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"
step case_i_rolle_fehlt ok i_teardown "$HERE/cases/teardown_rolle_authenticated.sql"
# Und der Gegenbeweis: mit wiederhergestellter Rolle laeuft 02 wieder durch
# (identischer Snapshot -> No-Op). Ohne diesen Schritt bliebe offen, ob das
# Teardown den Cluster wirklich sauber zurueckgestellt hat.
step case_i_rolle_fehlt ok i_02_nach_teardown "$SQL_DIR/02_backup_quality_fixes.sql"

# ===========================================================================
# CASE D6 — manipuliertes Backup gegen 06, nachdem 04 gelaufen ist
# ===========================================================================
# Das Backup ist hier die DATENQUELLE des Schreibvorgangs. 06 muss den Inhalt
# gegen den bekannten Vorzustand pruefen und darf fremden Text nicht nach
# public.products schreiben.
new_case case_d6_restore_manipuliert "manipuliertes Backup darf nicht zurueckgeschrieben werden"
step case_d6_restore_manipuliert ok   d6_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_d6_restore_manipuliert ok   d6_04_apply  "$SQL_DIR/04_apply_quality_fixes.sql"
step case_d6_restore_manipuliert ok   d6_04_assert "$HERE/cases/assert_after_04.sql"
step case_d6_restore_manipuliert ok   d6_tamper    "$HERE/cases/setup_tamper_backup.sql"
step case_d6_restore_manipuliert fail d6_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: Backup entspricht nicht dem bekannten Vorzustand'

# ===========================================================================
# CASE E — Restore, Round-Trip und Idempotenz
# ===========================================================================
new_case case_e_restore "02 -> 04 -> 06 mit exaktem Round-Trip"
step case_e_restore ok e_02_backup       "$SQL_DIR/02_backup_quality_fixes.sql"
step case_e_restore ok e_04_apply        "$SQL_DIR/04_apply_quality_fixes.sql"
step case_e_restore ok e_04_assert       "$HERE/cases/assert_after_04.sql"
step case_e_restore ok e_06_restore      "$SQL_DIR/06_restore_quality_fixes.sql"
step case_e_restore ok e_06_assert       "$HERE/cases/assert_after_06.sql"
step case_e_restore ok e_06_wiederholung "$SQL_DIR/06_restore_quality_fixes.sql"
step case_e_restore ok e_06_assert_2     "$HERE/cases/assert_after_06.sql"
step case_e_restore ok e_base_state      "$HERE/cases/assert_base_state.sql"
# Nach dem Restore ist der Vorzustand wieder da: 04 darf erneut laufen.
step case_e_restore ok e_04_erneut       "$SQL_DIR/04_apply_quality_fixes.sql"
step case_e_restore ok e_04_assert_2     "$HERE/cases/assert_after_04.sql"
report_table case_e_restore e_05_verify  "$SQL_DIR/05_verify_read_only.sql" 23

# ===========================================================================
# CASE J — updated_at IS NULL vor 02
# ===========================================================================
# schema.sql definiert updated_at nur als DEFAULT now(), nicht als NOT NULL.
# Ein NULL-Zeitstempel macht jeden spaeteren Vergleich "neu > alt" zu NULL —
# also weder wahr noch falsch — und nimmt 06 den Wert, den es zurueckspielen
# soll. 02 darf so einen Zustand nicht in den Snapshot uebernehmen.
new_case case_j_updated_at_null "eine Zielzeile hat updated_at IS NULL, bevor 02 laeuft"
step case_j_updated_at_null ok   j_setup "$HERE/cases/setup_updated_at_null_quelle.sql"
step case_j_updated_at_null fail j_02_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: 1 der sechs lastmod-Zielprodukte haben updated_at IS NULL'
step case_j_updated_at_null ok j_backup_absent    "$HERE/cases/assert_backup_absent.sql"
step case_j_updated_at_null ok j_kein_zielzustand "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE J2 — updated_at IS NULL in Quelle UND Backup, vor 04
# ===========================================================================
# Der gefaehrlichere Zwischenstand: weil beide Seiten denselben NULL-Wert
# tragen, findet der vollstaendige to_jsonb-Vergleich KEINE Abweichung. Ohne
# eigenen Guard wuerde 04 schreiben und erst an der lastmod-Nachbedingung mit
# einer irrefuehrenden Meldung scheitern.
new_case case_j2_updated_at_null_vor_04 "updated_at IS NULL in Quelle und Backup"
step case_j2_updated_at_null_vor_04 ok j2_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_j2_updated_at_null_vor_04 ok j2_setup \
  "$HERE/cases/setup_updated_at_null_quelle_und_backup.sql"
step case_j2_updated_at_null_vor_04 fail j2_04_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: 1 der sechs lastmod-Zielprodukte haben updated_at IS NULL'
step case_j2_updated_at_null_vor_04 ok j2_kein_zielzustand \
  "$HERE/cases/assert_kein_zielzustand.sql"

# ===========================================================================
# CASE J3 — updated_at IS NULL nur im Backup, vor 06
# ===========================================================================
# In 06 ist das Backup die Datenquelle. Ein NULL-Zeitstempel dort wuerde beim
# Restore zu einer Produktzeile ganz ohne lastmod fuehren — der versprochene
# exakte Round-Trip waere in Wahrheit ein Datenverlust.
new_case case_j3_updated_at_null_vor_06 "updated_at IS NULL nur im Backup, nach 04"
step case_j3_updated_at_null_vor_06 ok j3_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
step case_j3_updated_at_null_vor_06 ok j3_04_apply  "$SQL_DIR/04_apply_quality_fixes.sql"
step case_j3_updated_at_null_vor_06 ok j3_04_assert "$HERE/cases/assert_after_04.sql"
step case_j3_updated_at_null_vor_06 ok j3_setup \
  "$HERE/cases/setup_updated_at_null_nur_backup.sql"
step case_j3_updated_at_null_vor_06 fail j3_02_wiederholung_abbruch \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  'QF-Backup abgebrochen: vorhandenes Backup hat 1 der sechs lastmod-Zielprodukte mit updated_at IS NULL'
step case_j3_updated_at_null_vor_06 fail j3_06_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: updated_at IS NULL bei 0 der sechs lastmod-Zielprodukte in public.products und bei 1 im Backup'
step case_j3_updated_at_null_vor_06 ok j3_setup_ziel_und_backup \
  "$HERE/cases/setup_updated_at_null_ziel_und_backup.sql"
step case_j3_updated_at_null_vor_06 fail j3_04_noop_abbruch \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  'QF-Korrektur abgebrochen: im Zielzustand haben nur 5/6 lastmod-Zielprodukte ein neues updated_at'
step case_j3_updated_at_null_vor_06 fail j3_06_noop_abbruch \
  "$SQL_DIR/06_restore_quality_fixes.sql" \
  'QF-Restore abgebrochen: updated_at IS NULL bei 1 der sechs lastmod-Zielprodukte in public.products und bei 1 im Backup'

# ===========================================================================
# CASE G — echter Konkurrenztest fuer 02
# ===========================================================================
# Die zweite Session aendert shop_tags. shop_tags steht nicht in der
# Spaltenliste des Triggers products_set_updated_at, updated_at bleibt also
# gleich. 02 kann die Aenderung damit nur ueber die vollstaendige
# Vorzustandspruefung nach dem Lock bemerken — nicht ueber einen
# Zeitstempelvergleich.
new_case case_g_konkurrenz_02 "zweite Session aendert shop_tags, waehrend 02 auf den Lock wartet"
step case_g_konkurrenz_02 ok g_backup_absent "$HERE/cases/assert_backup_absent.sql"
konkurrenz_lauf case_g_konkurrenz_02 "$LABEL_G" \
  "$SQL_DIR/02_backup_quality_fixes.sql" \
  "select id from public.products where slug = 'pizza-socks-box-pepperoni' for update;" \
  "update public.products set shop_tags = array['CBB-TEST: konkurrierende Aenderung an shop_tags']::text[] where slug = 'pizza-socks-box-pepperoni';" \
  'QF-Backup abgebrochen: Zielzeilen wurden zwischen Vorpruefung und Sperre veraendert'
step case_g_konkurrenz_02 ok g_assert          "$HERE/cases/assert_konkurrenz_shop_tags.sql"
step case_g_konkurrenz_02 ok g_backup_absent_2 "$HERE/cases/assert_backup_absent.sql"

# ===========================================================================
# CASE H — echter Konkurrenztest fuer 04
# ===========================================================================
# Erst ein sauberes Backup aus 02. Danach aendert die zweite Session
# product_slugs einer Zielliste. public.lists hat keine Spalte updated_at — ein
# Zeitstempelvergleich waere hier gar nicht moeglich. Bewiesen wird der
# Zeitpunkt: 04 hat seine sperrfreie Vorpruefung bereits bestanden, als die
# Konkurrenz noch nicht committet war. Nur die erneute Klassifizierung nach dem
# erworbenen Lock sieht den neuen Stand.
new_case case_h_konkurrenz_04 "zweite Session aendert product_slugs, waehrend 04 auf den Lock wartet"
step case_h_konkurrenz_04 ok h_02_backup "$SQL_DIR/02_backup_quality_fixes.sql"
konkurrenz_lauf case_h_konkurrenz_04 "$LABEL_H" \
  "$SQL_DIR/04_apply_quality_fixes.sql" \
  "select id from public.lists where slug = 'geschenke-fuer-gamer' for update;" \
  "update public.lists set product_slugs = array['CBB-TEST: konkurrierende Aenderung an product_slugs']::text[] where slug = 'geschenke-fuer-gamer';" \
  'QF-Korrektur abgebrochen: Zielzeilen wurden zwischen Vorpruefung und Sperre veraendert'
step case_h_konkurrenz_04 ok h_assert "$HERE/cases/assert_konkurrenz_liste.sql"

# ===========================================================================
# CASE F — Lock-Timeout: 02 muss unter Sperrkonflikt nach ~5 s abbrechen
# ===========================================================================
new_case case_f_lock_timeout "AccessExclusiveLock auf public.products blockiert 02"
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
  record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "-" FAIL \
    "Sperre konnte nicht aufgebaut werden — Fall nicht bewertbar"
else
  F_START=$SECONDS
  timeout 30 "$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_f_lock_timeout \
    -f "$SQL_DIR/02_backup_quality_fixes.sql" > "$F_OUT" 2>&1 &
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
    record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "$F_RC" FAIL \
      "Client-Timeout nach 30s: lock_timeout greift in der Guard-Phase nicht"
  elif [[ $F_RC -ne 3 ]]; then
    mark_fail
    record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "$F_RC" FAIL \
      "Exit $F_RC statt 3 nach ${F_ELAPSED}s — $F_MSG"
  elif ! grep -Fq -- "$F_ERWARTET" "$F_OUT"; then
    mark_fail
    record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "$F_RC" FAIL \
      "falscher Fehler. erwartet: <$F_ERWARTET> | tatsaechlich: $F_MSG"
  elif [[ $F_ELAPSED -lt 3 || $F_ELAPSED -gt 15 ]]; then
    mark_fail
    record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "$F_RC" FAIL \
      "richtige Meldung, aber Laufzeit ${F_ELAPSED}s ausserhalb 3-15s (lock_timeout='5s')"
  else
    record f_02_unter_sperre "02_backup_quality_fixes.sql" "fail/3" "$F_RC" PASS \
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
step case_f_lock_timeout ok f_02_danach "$SQL_DIR/02_backup_quality_fixes.sql"
N_ELAPSED=$((SECONDS - N_START))
log "  f_02_danach Laufzeit: ${N_ELAPSED}s (muss deutlich unter pg_sleep(90) liegen)"
if [[ $N_ELAPSED -gt 30 ]]; then
  mark_fail
  log "  [FAIL] f_02_danach brauchte ${N_ELAPSED}s — die Sperre wurde nicht wirklich geloest."
fi
report_table case_f_lock_timeout f_03_verify_backup \
  "$SQL_DIR/03_verify_backup_read_only.sql" 16

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
