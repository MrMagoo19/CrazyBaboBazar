#!/usr/bin/env bash
# =============================================================================
# LOKALER POSTGRESQL-HARNESS FUER DIE KLICK-OUT-MESSUNG (P1)
# =============================================================================
# Testet die ORIGINALDATEIEN 01_preflight_read_only.sql bis 05_rollback.sql aus
# ../ gegen eine echte PostgreSQL-Instanz mit einer production-aehnlichen
# Fixture (Stand NACH Value-Add Batch 2).
#
# Der Harness fasst KEINE Production- und KEINE Pilot-Datenbank an. Er startet
# einen eigenen Cluster in einem temporaeren Verzeichnis, der ausschliesslich
# ueber einen Unix-Socket erreichbar ist (listen_addresses='') und den er am
# Ende wieder stoppt. Keine Datei unter ../ wird veraendert.
#
# ZWEISTUFIGER AUFBAU:
#   Stufe 1 (CASE 0) laeuft OHNE Cluster: Read-only-Reinheit der lesenden
#   Dateien, SET-LOCAL-Position und begin/commit-Paarigkeit der schreibenden
#   Dateien sowie die Datenminimierungs-Pruefung — die Spaltenliste der Tabelle
#   muss exakt der Feldliste des Route-Handlers entsprechen, und kein verbotener
#   Feldname darf irgendwo auftauchen. Diese Stufe laeuft immer, auch ohne
#   PostgreSQL.
#   Stufe 2 braucht einen Cluster. Fehlen die Binaries, meldet der Harness das
#   klar, gibt die Stufe-1-Ergebnisse vollstaendig aus und endet mit Exit 2.
#
# Aufruf:
#   ./run_local_postgres_test.sh                       # alles
#   CBB_STATIC_ONLY=1 ./run_local_postgres_test.sh     # nur CASE 0
#   CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh    # Datenverzeichnis behalten
#   CBB_PG_BIN=/pfad/zu/postgresql/16 ./run_local_postgres_test.sh
#   CBB_PG_BIN=/pfad/zu/postgresql/16/bin ./run_local_postgres_test.sh
#
# Exit-Code 0 = alle Erwartungen erfuellt, 1 = mindestens eine Abweichung,
# 2 = Umgebungsproblem (Binaries, initdb, Serverstart, createdb).
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$(cd "$HERE/.." && pwd)"          # production_clickouts/
WEB_DIR="$(cd "$SQL_DIR/../.." && pwd)"    # apps/web/
ROUTE_FILE="$WEB_DIR/app/api/click/[slug]/route.ts"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cbb-pgtest-clicks.XXXXXXXX")"
PGDATA="$WORKDIR/data"
SOCKDIR="$WORKDIR/sock"
LOGDIR="$WORKDIR/logs"
SERVERLOG="$WORKDIR/postgres.log"
RESULTS="$WORKDIR/results.tsv"
mkdir -p "$SOCKDIR" "$LOGDIR"

export LC_MESSAGES=C
export PGHOST="$SOCKDIR"
export PGUSER=postgres
export PGDATABASE=postgres

STEP=0
FAILURES=0
STATIC_FAILURES=0
CURRENT_CASE="-"
CLUSTER_UP=0

printf 'case\tstep\tlabel\tfile\texpect\texit\tverdict\tdetail\n' > "$RESULTS"

log()   { printf '%s\n' "$*"; }
head1() { printf '\n=== %s ===\n' "$*"; }

cleanup() {
  if [[ $CLUSTER_UP -eq 1 ]] && "$PG_CTL" -D "$PGDATA" status >/dev/null 2>&1; then
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
  fi
}
trap cleanup EXIT

record() {
  printf '%s\t%03d\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$CURRENT_CASE" "$STEP" "$1" "$2" "$3" "$4" "$5" \
    "$(printf '%s' "$6" | tr '\t\n' '  ' | cut -c1-220)" >> "$RESULTS"
  printf '  [%s] %-46s expect=%-14s exit=%-3s %s\n' "$5" "$1" "$3" "$4" "$2"
  [[ -n "$6" ]] && printf '           %s\n' "$6"
}

mark_fail()        { FAILURES=$((FAILURES + 1)); }
mark_static_fail() { FAILURES=$((FAILURES + 1)); STATIC_FAILURES=$((STATIC_FAILURES + 1)); }

fail_setup() {
  log ""
  log "SETUP-ABBRUCH: $*"
  exit 2
}

# ###########################################################################
# STUFE 1 — CASE 0: statische Pruefungen, kein Cluster noetig
# ###########################################################################

# ---------------------------------------------------------------------------
# static_set_local <sql-datei>
#   Beweist, dass "set local lock_timeout" und "set local statement_timeout"
#   genau einmal vorkommen, direkt hinter "begin;" stehen (nur Kommentar- und
#   Leerzeilen dazwischen) und vor dem ersten DO-Block liegen. Zusaetzlich:
#   genau ein "begin;" und genau ein "commit;".
#   Der Grund fuer die Position: der erste DO-Block fasst public.products an
#   und wuerde ohne gesetztes lock_timeout unbegrenzt auf einen konkurrierenden
#   AccessExclusiveLock warten.
# ---------------------------------------------------------------------------
static_set_local() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="setlocal_$(basename "$file" .sql)"
  local res
  res="$(awk '
    { a[NR] = $0 }
    /^begin;[ \t]*$/                                 { begin_n++; if (begin_l == 0) begin_l = NR }
    /^commit;[ \t]*$/                                { commit_n++ }
    /^[ \t]*set[ \t]+local[ \t]/                     { setlocal_n++ }
    /^set local lock_timeout = .5s.;[ \t]*$/         { lock_n++; if (lock_l == 0) lock_l = NR }
    /^set local statement_timeout = .[0-9]+s.;[ \t]*$/ { stmt_n++; if (stmt_l == 0) stmt_l = NR }
    /^[ \t]*do[ \t]*\$\$/                            { if (do_l == 0) do_l = NR }
    END {
      p = ""
      if (begin_n != 1)    p = p sprintf("begin;-Zeilen=%d (erwartet 1); ", begin_n)
      if (commit_n != 1)   p = p sprintf("commit;-Zeilen=%d (erwartet 1); ", commit_n)
      if (lock_n != 1)     p = p sprintf("lock_timeout-Zeilen=%d (erwartet 1); ", lock_n)
      if (stmt_n != 1)     p = p sprintf("statement_timeout-Zeilen=%d (erwartet 1); ", stmt_n)
      if (setlocal_n != 2) p = p sprintf("SET-LOCAL-Zeilen gesamt=%d (erwartet 2); ", setlocal_n)
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
        printf "OK|begin;=Z%d, set local=Z%d+Z%d, erster DO-Block=Z%d, commit;=1\n", begin_l, lock_l, stmt_l, do_l
      else
        printf "PROBLEM|%s\n", p
    }
  ' "$file")"

  if [[ "$res" == OK\|* ]]; then
    record "$label" "$(basename "$file")" "SET-LOCAL+TX" "-" PASS "${res#OK|}"
  else
    mark_static_fail
    record "$label" "$(basename "$file")" "SET-LOCAL+TX" "-" FAIL "${res#PROBLEM|}"
  fi
}

# ---------------------------------------------------------------------------
# static_read_only <sql-datei>
#   Fuer die zwei lesenden Dateien: nach dem Entfernen von Kommentaren und
#   Text-Literalen darf kein DDL-, DML-, Rechte- oder Transaktions-Schluesselwort
#   uebrig bleiben, und es darf genau EIN Semikolon geben.
#   Reihenfolge bewusst: erst Kommentare, dann Literale. Kein Literal dieser
#   Dateien enthaelt "--", waehrend Kommentare sehr wohl Apostrophe enthalten.
# ---------------------------------------------------------------------------
static_read_only() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="readonly_$(basename "$file" .sql)"
  local res
  res="$(awk '
    {
      l = $0
      sub(/--.*$/, "", l)
      gsub(/'"'"'([^'"'"']|'"'"''"'"')*'"'"'/, "@", l)
      semis += gsub(/;/, ";", l)
      low = tolower(l)
      split("insert update delete merge create alter drop truncate grant revoke call commit rollback begin vacuum analyze reindex copy", kw, " ")
      for (i in kw) {
        if (low ~ ("(^|[^_a-z0-9])" kw[i] "([^_a-z0-9]|$)")) {
          hits[kw[i]]++
          if (first_l[kw[i]] == 0) first_l[kw[i]] = NR
        }
      }
      if (low ~ /do[ \t]*\$\$/) { doblock++; if (do_l == 0) do_l = NR }
    }
    END {
      p = ""
      for (k in hits) p = p sprintf("%s x%d (erst Z%d); ", toupper(k), hits[k], first_l[k])
      if (doblock > 0) p = p sprintf("DO-Block x%d (erst Z%d); ", doblock, do_l)
      if (semis != 1) p = p sprintf("Semikolons=%d (erwartet genau 1); ", semis)
      if (p == "")
        printf "OK|0 schreibende Schluesselwoerter, genau %d Semikolon\n", semis
      else
        printf "PROBLEM|%s\n", p
    }
  ' "$file")"

  if [[ "$res" == OK\|* ]]; then
    record "$label" "$(basename "$file")" "read-only rein" "-" PASS "${res#OK|}"
  else
    mark_static_fail
    record "$label" "$(basename "$file")" "read-only rein" "-" FAIL "${res#PROBLEM|}"
  fi
}

# ---------------------------------------------------------------------------
# static_no_forbidden_fields
#   Datenminimierung als statische Regel: kein SQL-Artefakt und kein
#   Route-Handler darf ein Feld anlegen oder befuellen, das mehr Personenbezug
#   traegt als vereinbart. Geprueft werden Bezeichner, nicht Fliesstext —
#   Kommentare werden vorher entfernt, damit die ausdrueckliche Erwaehnung
#   "keine IP" in der Dokumentation nicht als Treffer gilt.
# ---------------------------------------------------------------------------
static_no_forbidden_fields() {
  STEP=$((STEP + 1))
  local hits=""
  local f name
  for f in "$SQL_DIR"/0*.sql "$ROUTE_FILE"; do
    [[ -f "$f" ]] || continue
    local stripped
    case "$f" in
      # In TypeScript zaehlen nur Codezeilen: Block- und Zeilenkommentare
      # beschreiben die Datenminimierung ausdruecklich und wuerden sonst als
      # Treffer gegen sich selbst gewertet.
      *.ts) stripped="$(grep -vE '^[[:space:]]*(/\*|\*|//)' "$f" | sed 's|//.*$||')" ;;
      *)    stripped="$(sed 's/--.*$//' "$f")" ;;
    esac
    # Der Bindestrich zaehlt bewusst als Wortbestandteil: `Referrer-Policy` ist
    # ein legitimer HTTP-Header und kein Datenfeld, `referrer` allein waere eins.
    for name in ip_address ip_hash user_agent useragent referrer referer email query_string device_fingerprint; do
      if printf '%s' "$stripped" | grep -qiE "(^|[^-_a-z0-9])${name}([^-_a-z0-9]|$)"; then
        hits="$hits $(basename "$f"):$name"
      fi
    done
  done

  if [[ -z "$hits" ]]; then
    record no_forbidden_fields "0*.sql + route.ts" "0 Treffer" "-" PASS \
      "keine Bezeichner fuer IP, User-Agent, Referrer, E-Mail, Querystring oder Fingerprint"
  else
    mark_static_fail
    record no_forbidden_fields "0*.sql + route.ts" "0 Treffer" "-" FAIL "Treffer:$hits"
  fi
}

# ---------------------------------------------------------------------------
# static_field_parity
#   Die Feldliste, die der Route-Handler sendet, muss exakt der Spaltenliste
#   entsprechen, die 02 anlegt (ohne id und created_at, die der Server setzt).
#   Ohne diese Pruefung koennte ein spaeterer Commit ein Feld ergaenzen, das in
#   der Dokumentation nie auftaucht.
# ---------------------------------------------------------------------------
static_field_parity() {
  STEP=$((STEP + 1))
  local expected="consented_session_id device_class merchant product_slug source_path"
  local from_route from_sql
  from_route="$(grep -oE '^[ \t]+(product_slug|merchant|source_path|device_class|consented_session_id):' "$ROUTE_FILE" \
    | tr -d ' \t:' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  from_sql="$(grep -oE '^  (product_slug|merchant|source_path|device_class|consented_session_id) ' \
    "$SQL_DIR/02_create_clickouts.sql" | tr -d ' ' | sort -u | tr '\n' ' ' | sed 's/ $//')"

  if [[ "$from_route" == "$expected" && "$from_sql" == "$expected" ]]; then
    record field_parity "route.ts <-> 02_create_clickouts.sql" "5 identisch" "-" PASS \
      "Feldliste: $expected"
  else
    mark_static_fail
    record field_parity "route.ts <-> 02_create_clickouts.sql" "5 identisch" "-" FAIL \
      "route=<$from_route> sql=<$from_sql> erwartet=<$expected>"
  fi
}

# ---------------------------------------------------------------------------
# static_sequence_hardening
#   Die Identity-Sequenz public.click_outs_id_seq ist ein eigenes Objekt mit
#   eigener ACL. Ohne Entzug gaebe `last_value` den Klick-Zaehler preis und
#   `setval` liesse die Nummernfolge verbiegen — an der ansonsten dichten
#   Tabelle vorbei. Diese Pruefung haelt die drei tragenden Zeilen fest, damit
#   ein spaeterer Umbau sie nicht still verliert:
#     * REVOKE ALL von PUBLIC, anon, authenticated UND service_role
#     * GENAU EIN GRANT auf der Sequenz, und zwar USAGE an service_role
#     * kein GRANT von SELECT oder UPDATE auf der Sequenz
#   Zusaetzlich muss 03 die Sequenzrechte selbst pruefen.
# ---------------------------------------------------------------------------
static_sequence_hardening() {
  STEP=$((STEP + 1))
  local create="$SQL_DIR/02_create_clickouts.sql"
  local verify="$SQL_DIR/03_verify_read_only.sql"
  local problems=""

  # Kommentare raus: die Begruendung nennt die Rechte im Fliesstext.
  local code
  code="$(sed 's/--.*$//' "$create")"

  local revoke_line grant_lines usage_grant bad_grant verify_hits
  # tr, weil die REVOKE-Anweisung bewusst ueber zwei Zeilen laeuft.
  revoke_line="$(printf '%s' "$code" | tr '\n' ' ' \
    | grep -cE 'revoke +all +on +sequence +public\.click_outs_id_seq +from +public, *anon, *authenticated, *service_role' || true)"
  grant_lines="$(printf '%s' "$code" | grep -ciE '^[[:space:]]*grant .*on +sequence' || true)"
  usage_grant="$(printf '%s' "$code" | grep -ciE '^[[:space:]]*grant +usage +on +sequence +public\.click_outs_id_seq +to +service_role' || true)"
  bad_grant="$(printf '%s' "$code" | grep -ciE '^[[:space:]]*grant +.*(select|update).*on +sequence' || true)"
  verify_hits="$(grep -c 'has_sequence_privilege' "$verify" || true)"

  [[ "$revoke_line" -ge 1 ]] || problems="$problems REVOKE-ALL-Zeile fehlt;"
  [[ "$usage_grant" -eq 1 ]] || problems="$problems USAGE-GRANT ${usage_grant}x (erwartet 1);"
  [[ "$grant_lines" -eq 1 ]] || problems="$problems Sequenz-GRANTs ${grant_lines} (erwartet genau 1);"
  [[ "$bad_grant" -eq 0 ]]   || problems="$problems ${bad_grant} SELECT-/UPDATE-GRANT(s) auf der Sequenz;"
  [[ "$verify_hits" -ge 1 ]] || problems="$problems 03 prueft has_sequence_privilege nicht;"

  if [[ -z "$problems" ]]; then
    record sequence_hardening "02_create + 03_verify" "revoke+1x USAGE" "-" PASS \
      "click_outs_id_seq: alle Rechte entzogen, nur service_role USAGE, 03 prueft $verify_hits x has_sequence_privilege"
  else
    mark_static_fail
    record sequence_hardening "02_create + 03_verify" "revoke+1x USAGE" "-" FAIL "$problems"
  fi
}

# ---------------------------------------------------------------------------
# static_retention_gate
#   Der Rollout darf nicht aktiviert werden, solange kein ueberwachter,
#   wiederkehrender 12-Monats-Loeschlauf eingerichtet ist. Das Gate steht im
#   RUNBOOK und muss dort auffindbar bleiben — sonst waere die Zusage aus der
#   Datenschutzerklaerung ("spaetestens nach 12 Monaten geloescht") eine
#   Absichtserklaerung ohne Mechanismus.
#
#   Zusaetzlich wird der Gate-Status selbst auf Widerspruchsfreiheit geprueft:
#   die Zeile `GATE-STATUS: ...` muss existieren, und sie darf nicht ERFUELLT
#   melden, solange das Ausfuehrungsprotokoll noch leer ist. Eine Datei, die
#   allein durch ihr Vorhandensein ein Gate erfuellt, waere kein Gate.
# ---------------------------------------------------------------------------
static_retention_gate() {
  STEP=$((STEP + 1))
  local runbook="$SQL_DIR/RUNBOOK.md"
  local problems=""

  grep -Fq 'PRE-ENABLE-GATE' "$runbook" || problems="$problems Marker PRE-ENABLE-GATE fehlt;"
  grep -Fq 'SUPABASE_SERVICE_ROLE_KEY' "$runbook" || problems="$problems Bezug zum Server-Schluessel fehlt;"
  grep -Fq '04_retention.sql' "$runbook" || problems="$problems Verweis auf 04_retention.sql fehlt;"
  grep -Fq '04a_schedule_retention.sql' "$runbook" || problems="$problems Verweis auf 04a fehlt;"
  grep -Fq '04b_verify_retention_schedule_read_only.sql' "$runbook" \
    || problems="$problems Verweis auf 04b fehlt;"

  local gate_status
  gate_status="$(grep -m1 -oE 'GATE-STATUS: (NICHT ERFUELLT|ERFUELLT)' "$runbook" || true)"
  if [[ -z "$gate_status" ]]; then
    problems="$problems Zeile GATE-STATUS fehlt oder traegt einen unbekannten Wert;"
  elif [[ "$gate_status" == "GATE-STATUS: ERFUELLT" ]] \
       && grep -Fq 'Noch nichts ausgefuehrt' "$runbook"; then
    problems="$problems GATE-STATUS meldet ERFUELLT, das Ausfuehrungsprotokoll ist aber leer;"
  fi

  if [[ -z "$problems" ]]; then
    record retention_gate "RUNBOOK.md" "Gate dokumentiert" "-" PASS \
      "hartes Pre-enable-Gate im Runbook verankert, aktueller Stand: ${gate_status:-unbekannt}"
  else
    mark_static_fail
    record retention_gate "RUNBOOK.md" "Gate dokumentiert" "-" FAIL "$problems"
  fi
}

# ---------------------------------------------------------------------------
# static_retention_schedule
#   Jobname, Schedule und Command sind an vier Stellen niedergeschrieben: in
#   04a (die Quelle), in 04b (die Nachpruefung), in 05 (das Abbestellen) und im
#   RUNBOOK. Weichen sie auch nur an einer Stelle ab, prueft 04b einen anderen
#   Job als 04a anlegt und 05 bestellt einen dritten ab — ohne dass irgendetwas
#   scheitern wuerde. Diese Pruefung haelt die drei Werte zusammen.
#
#   Zusaetzlich: nur 04a darf cron.schedule aufrufen, nur 05 darf
#   cron.unschedule aufrufen, und die lesenden Dateien duerfen keins von beidem
#   enthalten.
# ---------------------------------------------------------------------------
static_retention_schedule() {
  STEP=$((STEP + 1))
  local jobname='cbb-click-outs-retention-12m'
  local schedule='15 3 * * *'
  local job_command='select cbb_private_analytics.purge_click_outs(12);'
  local problems="" f

  for f in "$SQL_DIR/04a_schedule_retention.sql" \
           "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" \
           "$SQL_DIR/05_rollback.sql" \
           "$SQL_DIR/RUNBOOK.md"; do
    [[ -f "$f" ]] || { problems="$problems $(basename "$f") fehlt;"; continue; }
    grep -Fq -- "$jobname" "$f" || problems="$problems $(basename "$f"): Jobname fehlt;"
    grep -Fq -- "$job_command" "$f" || problems="$problems $(basename "$f"): Command fehlt;"
  done

  # Der Schedule steht nicht in 05 — dort wird nur abbestellt, nicht geplant.
  for f in "$SQL_DIR/04a_schedule_retention.sql" \
           "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" \
           "$SQL_DIR/RUNBOOK.md"; do
    grep -Fq -- "$schedule" "$f" || problems="$problems $(basename "$f"): Schedule fehlt;"
  done

  # Aufrufe zaehlen, Kommentare vorher entfernen.
  local sched_in_04a unsched_in_05 sched_in_04b sched_in_04 unsched_in_04b
  sched_in_04a="$(sed 's/--.*$//' "$SQL_DIR/04a_schedule_retention.sql" \
    | grep -cE 'cron\.schedule[[:space:]]*\(' || true)"
  unsched_in_05="$(sed 's/--.*$//' "$SQL_DIR/05_rollback.sql" \
    | grep -cE 'cron\.unschedule[[:space:]]*\(' || true)"
  sched_in_04b="$(sed 's/--.*$//' "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" \
    | grep -cE 'cron\.schedule[[:space:]]*\(' || true)"
  unsched_in_04b="$(sed 's/--.*$//' "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" \
    | grep -cE 'cron\.unschedule[[:space:]]*\(' || true)"
  sched_in_04="$(sed 's/--.*$//' "$SQL_DIR/04_retention.sql" \
    | grep -cE 'cron\.(schedule|unschedule)[[:space:]]*\(' || true)"

  [[ "$sched_in_04a"   -eq 1 ]] || problems="$problems 04a ruft cron.schedule ${sched_in_04a}x auf (erwartet 1);"
  [[ "$unsched_in_05"  -eq 1 ]] || problems="$problems 05 ruft cron.unschedule ${unsched_in_05}x auf (erwartet 1);"
  [[ "$sched_in_04b"   -eq 0 ]] || problems="$problems 04b ruft cron.schedule auf;"
  [[ "$unsched_in_04b" -eq 0 ]] || problems="$problems 04b ruft cron.unschedule auf;"
  [[ "$sched_in_04"    -eq 0 ]] || problems="$problems 04_retention.sql plant selbst;"

  # 04a muss VOR dem Schreiben pruefen. Ohne den Vorab-Guard wuerde
  # cron.schedule einen gleichnamigen Job stillschweigend ueberschreiben.
  grep -Fq 'Retention-Planung abgebrochen: doppelter Jobname.' \
    "$SQL_DIR/04a_schedule_retention.sql" || problems="$problems 04a ohne Guard gegen doppelten Jobnamen;"
  grep -Fq 'Retention-Planung abgebrochen: Drift.' \
    "$SQL_DIR/04a_schedule_retention.sql" || problems="$problems 04a ohne Drift-Guard;"
  grep -Fq 'Rollback abgebrochen: Drift.' \
    "$SQL_DIR/05_rollback.sql" || problems="$problems 05 ohne Drift-Guard;"

  if [[ -z "$problems" ]]; then
    record retention_schedule "04a + 04b + 05 + RUNBOOK" "Job identisch" "-" PASS \
      "Jobname, Schedule und Command wortgleich; 04a plant genau einmal, 05 bestellt genau einmal ab"
  else
    mark_static_fail
    record retention_schedule "04a + 04b + 05 + RUNBOOK" "Job identisch" "-" FAIL "$problems"
  fi
}

# ---------------------------------------------------------------------------
# static_target_named
#   Das Production-Ziel muss in jeder SQL-Datei und im Runbook sichtbar stehen.
# ---------------------------------------------------------------------------
static_target_named() {
  STEP=$((STEP + 1))
  local missing="" f
  for f in "$SQL_DIR"/0*.sql "$SQL_DIR/RUNBOOK.md"; do
    grep -Fq 'ydiihvzcxaaoqhmgoqvu' "$f" || missing="$missing $(basename "$f")"
  done
  if [[ -z "$missing" ]]; then
    record target_named "0*.sql + RUNBOOK.md" "Ziel genannt" "-" PASS \
      "project/ydiihvzcxaaoqhmgoqvu in jeder Datei sichtbar"
  else
    mark_static_fail
    record target_named "0*.sql + RUNBOOK.md" "Ziel genannt" "-" FAIL "fehlt in:$missing"
  fi
}

head1 "case_0_statisch — Read-only-Reinheit, SET-LOCAL-Position, Datenminimierung"
CURRENT_CASE=case_0_statisch

static_read_only "$SQL_DIR/01_preflight_read_only.sql"
static_read_only "$SQL_DIR/03_verify_read_only.sql"
static_read_only "$SQL_DIR/04b_verify_retention_schedule_read_only.sql"

static_set_local "$SQL_DIR/02_create_clickouts.sql"
static_set_local "$SQL_DIR/04_retention.sql"
static_set_local "$SQL_DIR/04a_schedule_retention.sql"
static_set_local "$SQL_DIR/05_rollback.sql"

static_no_forbidden_fields
static_field_parity
static_sequence_hardening
static_retention_gate
static_retention_schedule
static_target_named

log ""
log "CASE 0 abgeschlossen: $STEP statische Pruefungen, $STATIC_FAILURES Abweichungen."

if [[ $STATIC_FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: statische Pruefungen sind nicht sauber — die Datenbankfaelle"
  log "waeren nicht aussagekraeftig."
  head1 "Zusammenfassung"
  column -t -s $'\t' "$RESULTS" 2>/dev/null || cat "$RESULTS"
  log "Ergebnisdatei: $RESULTS"
  log "GESAMT: FAIL"
  exit 1
fi

# ###########################################################################
# STUFE 2 — Datenbankfaelle
# ###########################################################################

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
else
  for major in 18 17 16 15 14; do
    if [[ -x "/usr/lib/postgresql/$major/bin/initdb" ]]; then
      PG_BINDIR="/usr/lib/postgresql/$major/bin"
      break
    fi
  done
fi

# Liegen die Binaries in einem entpackten Paketbaum statt in einer echten
# Systeminstallation, steht libpq.so.5 irgendwo im selben Baum und wird ohne
# LD_LIBRARY_PATH nicht gefunden.
PG_TREE_ROOT=""
case "${PG_BINDIR:-}" in
  */usr/lib/postgresql/*/bin) PG_TREE_ROOT="${PG_BINDIR%/usr/lib/postgresql/*/bin}" ;;
  */usr/bin)                  PG_TREE_ROOT="${PG_BINDIR%/usr/bin}" ;;
  */usr/local/pgsql/bin)      PG_TREE_ROOT="${PG_BINDIR%/usr/local/pgsql/bin}" ;;
esac
if [[ -n "$PG_TREE_ROOT" && "$PG_TREE_ROOT" != "/" && -d "$PG_TREE_ROOT" ]]; then
  PG_LIBPQ="$(find "$PG_TREE_ROOT" -name 'libpq.so.5' -print -quit 2>/dev/null)"
  if [[ -n "$PG_LIBPQ" ]]; then
    export LD_LIBRARY_PATH="$(dirname "$PG_LIBPQ")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi
fi

summary_and_exit_env() {
  head1 "Zusammenfassung"
  column -t -s $'\t' "$RESULTS" 2>/dev/null || cat "$RESULTS"
  log ""
  log "Statische Pruefungen: $STEP Schritte, $STATIC_FAILURES Abweichungen — alle bestanden."
  log "Datenbankfaelle:      NICHT AUSGEFUEHRT."
  log "Grund:                $1"
  log "Ergebnisdatei:        $RESULTS"
  log ""
  log "GESAMT: UMGEBUNG UNVOLLSTAENDIG (Exit 2). Das ist KEIN PASS und KEIN FAIL"
  log "der Rollout-Dateien — die Datenbankfaelle sind schlicht nicht bewertet."
  exit 2
}

if [[ "${CBB_STATIC_ONLY:-0}" == "1" ]]; then
  summary_and_exit_env "CBB_STATIC_ONLY=1 gesetzt."
fi

if [[ -z "$PG_BINDIR" ]]; then
  summary_and_exit_env "PostgreSQL-Binaries nicht gefunden. CBB_PG_BIN ist nicht gesetzt und weder pg_config noch initdb liegen im PATH. Beispiel: CBB_PG_BIN=/usr/lib/postgresql/16 $0"
fi

INITDB="$PG_BINDIR/initdb"
PG_CTL="$PG_BINDIR/pg_ctl"
PSQL="$PG_BINDIR/psql"
CREATEDB="$PG_BINDIR/createdb"
POSTGRES="$PG_BINDIR/postgres"

for exe in "$INITDB" "$PG_CTL" "$PSQL" "$CREATEDB" "$POSTGRES"; do
  if [[ ! -x "$exe" ]]; then
    summary_and_exit_env "In $PG_BINDIR liegt keine vollstaendige PostgreSQL-Installation ($exe fehlt)."
  fi
done

# ---------------------------------------------------------------------------
# step <db> <expect: ok|fail> <label> <sql-datei> [erwartetes-fehler-literal]
#   expect=fail verlangt Exit 3 UND das Literal im Output. Das Literal ist
#   Pflicht: "irgendein Fehler" ist kein Beleg.
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
      verdict=PASS; detail="$server_msg"
    else
      verdict=FAIL; mark_fail; detail="unerwarteter Abbruch (exit=$rc): $server_msg"
    fi
  else
    expect_label="fail/3"
    if [[ -z "$want" ]]; then
      verdict=FAIL; mark_fail
      detail="HARNESS-FEHLER: kein erwartetes Fehler-Literal angegeben (exit=$rc)"
    elif [[ $rc -ne 3 ]]; then
      verdict=FAIL; mark_fail
      if [[ $rc -eq 0 ]]; then
        detail="lief durch, erwartet war Exit 3 mit: $want"
      else
        detail="Exit $rc statt 3 (erwartet: $want) — $server_msg"
      fi
    elif ! grep -Fq -- "$want" "$out"; then
      verdict=FAIL; mark_fail
      detail="falscher Fehler. erwartet: <$want> | tatsaechlich: $server_msg"
    else
      verdict=PASS; detail="erwarteter Abbruch: $want"
    fi
  fi

  record "$label" "$(basename "$file")" "$expect_label" "$rc" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# report_table <db> <label> <sql-datei> <erwartete-PASS-zeilen>
#   Die lesenden Dateien melden Probleme NICHT ueber den Exit-Code, sondern als
#   Zeile mit status = FAIL. Verlangt wird die EXAKTE Zahl an PASS-Zeilen und
#   0 FAIL-Zeilen — eine geschrumpfte Pruefliste faellt damit auf.
# ---------------------------------------------------------------------------
report_table() {
  local db="$1" label="$2" file="$3" want_pass="$4"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local rc=0

  "$PSQL" -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$file" > "$base.txt" 2>&1 || rc=$?
  "$PSQL" -X -q -A -F '|' -t -v ON_ERROR_STOP=1 -d "$db" -f "$file" > "$base.psv" 2>&1 || true

  local failrows=0 passrows=0
  if [[ $rc -eq 0 ]]; then
    failrows="$(grep -c '|FAIL$' "$base.psv" || true)"
    passrows="$(grep -c '|PASS$' "$base.psv" || true)"
  fi

  local verdict detail
  if [[ $rc -eq 0 && "$failrows" -eq 0 && "$passrows" -eq "$want_pass" ]]; then
    verdict=PASS; detail="exakt $passrows PASS-Zeilen, 0 FAIL-Zeilen -> $base.txt"
  else
    verdict=FAIL; mark_fail
    detail="exit=$rc, $passrows PASS (erwartet $want_pass), $failrows FAIL (erwartet 0) -> $base.txt"
  fi

  record "$label" "$(basename "$file")" "${want_pass}xPASS/0xFAIL" "$rc" "$verdict" "$detail"
  return 0
}

# ---------------------------------------------------------------------------
# report_table_expect_fail <db> <label> <datei> <pass> <fail> <name…>
#   want_names ist eine LEERZEICHENGETRENNTE Liste. JEDER Name muss in einer
#   FAIL-Zeile vorkommen. Ohne diese Liste hiesse "irgendwas ist FAIL" schon
#   Erfolg — und ein Report, der aus dem falschen Grund rot ist, waere kein
#   Beleg.
# ---------------------------------------------------------------------------
report_table_expect_fail() {
  local db="$1" label="$2" file="$3" want_pass="$4" want_fail="$5" want_names="$6"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local rc=0

  "$PSQL" -X -q -A -F '|' -t -v ON_ERROR_STOP=1 -d "$db" -f "$file" > "$base.psv" 2>&1 || rc=$?

  local failrows=0 passrows=0 fehlende="" name
  if [[ $rc -eq 0 ]]; then
    failrows="$(grep -c '|FAIL$' "$base.psv" || true)"
    passrows="$(grep -c '|PASS$' "$base.psv" || true)"
    for name in $want_names; do
      grep '|FAIL$' "$base.psv" | grep -q -F -- "$name" || fehlende="$fehlende $name"
    done
  else
    fehlende=" (nicht geprueft, exit=$rc)"
  fi

  local verdict detail
  if [[ $rc -eq 0 && "$failrows" -eq "$want_fail" && "$passrows" -eq "$want_pass" && -z "$fehlende" ]]; then
    verdict=PASS
    detail="Luecke korrekt als FAIL gemeldet: $failrows FAIL ($want_names), $passrows PASS"
  else
    verdict=FAIL; mark_fail
    detail="exit=$rc, $passrows PASS (erwartet $want_pass), $failrows FAIL (erwartet $want_fail), fehlende FAIL-Namen:${fehlende:- keine}"
  fi

  record "$label" "$(basename "$file")" "${want_pass}xPASS/${want_fail}xFAIL" "$rc" "$verdict" "$detail"
  return 0
}

new_case() {
  CURRENT_CASE="$1"
  head1 "$1 — $2"
  "$CREATEDB" -T cbb_fixture "$1" \
    || fail_setup "createdb -T cbb_fixture $1 fehlgeschlagen — Folgeergebnisse waeren wertlos."
}

# ===========================================================================
# Cluster aufsetzen — fail closed
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
CLUSTER_UP=1

# ===========================================================================
# Fixture-Datenbank bauen
# ===========================================================================
head1 "Fixture"
CURRENT_CASE=fixture
CREATEDB_RC=0
"$CREATEDB" cbb_fixture || CREATEDB_RC=$?
log "createdb cbb_fixture exit=$CREATEDB_RC"
if [[ $CREATEDB_RC -ne 0 ]]; then
  fail_setup "createdb cbb_fixture fehlgeschlagen (exit=$CREATEDB_RC)."
fi

step cbb_fixture ok fixture_roles  "$HERE/fixture/00_roles.sql"
step cbb_fixture ok fixture_schema "$HERE/fixture/01_schema.sql"
step cbb_fixture ok fixture_seed   "$HERE/fixture/02_seed.sql"
step cbb_fixture ok fixture_cron   "$HERE/fixture/02b_cron_stub.sql"
step cbb_fixture ok fixture_assert "$HERE/fixture/03_assert_fixture.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: Fixture ist nicht sauber, weitere Ergebnisse waeren wertlos."
  exit 1
fi

# ===========================================================================
# CASE A — Happy Path 01 -> 02 -> 03 plus Wirksamkeitstests
# ===========================================================================
new_case case_a_happy_path "01 bis 03 in Reihenfolge"
report_table case_a_happy_path a_01_preflight "$SQL_DIR/01_preflight_read_only.sql" 11
step case_a_happy_path ok a_02_create      "$SQL_DIR/02_create_clickouts.sql"
step case_a_happy_path ok a_02_assert      "$HERE/cases/assert_after_02.sql"
report_table case_a_happy_path a_03_verify "$SQL_DIR/03_verify_read_only.sql" 17
step case_a_happy_path ok a_rechte         "$HERE/cases/assert_rechte_wirken.sql"
step case_a_happy_path ok a_constraints    "$HERE/cases/assert_constraints_greifen.sql"
step case_a_happy_path ok a_view           "$HERE/cases/assert_view_aggregiert.sql"

# ===========================================================================
# CASE B — Wiederholung und verfruehte Verify-Laeufe
# ===========================================================================
new_case case_b_wiederholung "Doppelausfuehrung und zu frueher Verify"
step case_b_wiederholung fail b_03_vor_02 "$SQL_DIR/03_verify_read_only.sql" \
  'relation "public.click_outs" does not exist'
step case_b_wiederholung fail b_04_vor_02 "$SQL_DIR/04_retention.sql" \
  'Retention abgebrochen: public.click_outs fehlt.'
step case_b_wiederholung fail b_04a_vor_02 "$SQL_DIR/04a_schedule_retention.sql" \
  'Retention-Planung abgebrochen: public.click_outs fehlt.'
# 04b scheitert hier NICHT hart — cron.job existiert ja. Es meldet stattdessen
# genau die Zeilen als FAIL, die belegen, dass nichts geplant ist.
report_table_expect_fail case_b_wiederholung b_04b_vor_02 \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 1 8 \
  'loeschpfad_vorhanden retention_job_genau_einmal retention_job_aktiv retention_job_schedule retention_job_command retention_job_datenbank kein_zweiter_loeschjob retention_job_ohne_fehlgeschlagene_laeufe'
step case_b_wiederholung ok b_04a_assert "$HERE/cases/assert_kein_retention_job.sql"
step case_b_wiederholung fail b_05_vor_02 "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: public.click_outs existiert nicht.'
step case_b_wiederholung ok   b_02_create  "$SQL_DIR/02_create_clickouts.sql"
step case_b_wiederholung fail b_02_zweitlauf "$SQL_DIR/02_create_clickouts.sql" \
  'Klick-out-Anlage abgebrochen: public.click_outs existiert bereits.'
step case_b_wiederholung ok   b_02_assert  "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE C — Pilot-Marker
# ===========================================================================
new_case case_c_pilot_artefakt "Pilot-Marker vorhanden"
step case_c_pilot_artefakt ok   c_setup   "$HERE/cases/setup_pilot_artifact.sql"
step case_c_pilot_artefakt fail c_02      "$SQL_DIR/02_create_clickouts.sql" \
  'Klick-out-Anlage abgebrochen: Pilot-Artefakt gefunden.'
step case_c_pilot_artefakt ok   c_assert  "$HERE/cases/assert_no_clickout_artifacts.sql"

# ===========================================================================
# CASE D — Bestand unter 300
# ===========================================================================
new_case case_d_zu_wenig_produkte "Bestand unter 300"
step case_d_zu_wenig_produkte ok   d_setup  "$HERE/cases/setup_shrink_below_300.sql"
step case_d_zu_wenig_produkte fail d_02     "$SQL_DIR/02_create_clickouts.sql" \
  'Klick-out-Anlage abgebrochen: nur 299 Produkte (< 300).'
step case_d_zu_wenig_produkte ok   d_assert "$HERE/cases/assert_no_clickout_artifacts.sql"

# ===========================================================================
# CASE E — Retention trifft genau die alten Zeilen
# ===========================================================================
new_case case_e_retention "12-Monats-Fenster"
step case_e_retention ok e_02      "$SQL_DIR/02_create_clickouts.sql"
step case_e_retention ok e_seed    "$HERE/cases/setup_seed_events.sql"
step case_e_retention ok e_view    "$HERE/cases/assert_view_aggregiert.sql"
step case_e_retention ok e_04      "$SQL_DIR/04_retention.sql"
step case_e_retention ok e_assert  "$HERE/cases/assert_after_04.sql"
# Idempotenz: ein zweiter Lauf loescht nichts mehr.
step case_e_retention ok e_04_wdh  "$SQL_DIR/04_retention.sql"
step case_e_retention ok e_assert2 "$HERE/cases/assert_after_04.sql"

# ===========================================================================
# CASE F — Rollback-Roundtrip
# ===========================================================================
new_case case_f_rollback "02 -> Daten -> 05"
step case_f_rollback ok   f_02          "$SQL_DIR/02_create_clickouts.sql"
step case_f_rollback ok   f_seed        "$HERE/cases/setup_seed_events.sql"
step case_f_rollback ok   f_05          "$SQL_DIR/05_rollback.sql"
step case_f_rollback ok   f_assert      "$HERE/cases/assert_after_05.sql"
step case_f_rollback fail f_05_zweitlauf "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: public.click_outs existiert nicht.'
# Nach dem Rollback laesst sich sauber neu anlegen.
step case_f_rollback ok   f_02_erneut   "$SQL_DIR/02_create_clickouts.sql"
step case_f_rollback ok   f_02_assert   "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE G — Rollback verweigert die Arbeit, wenn fremde Artefakte fehlen
# ===========================================================================
new_case case_g_rollback_geschuetzt "Value-Add-Artefakt fehlt"
step case_g_rollback_geschuetzt ok   g_02     "$SQL_DIR/02_create_clickouts.sql"
step case_g_rollback_geschuetzt ok   g_setup  "$HERE/cases/setup_drop_v2_payload.sql"
step case_g_rollback_geschuetzt fail g_05     "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: ein Value-Add-Artefakt fehlt'
step case_g_rollback_geschuetzt ok   g_assert "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE H — 03 meldet ein Rechte-Loch als FAIL statt es zu uebersehen
# ===========================================================================
new_case case_h_rechteloch "anon bekommt SELECT auf click_outs"
step case_h_rechteloch ok h_02 "$SQL_DIR/02_create_clickouts.sql"
report_table case_h_rechteloch h_03_vorher "$SQL_DIR/03_verify_read_only.sql" 17

STEP=$((STEP + 1))
GRANT_RC=0
"$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_h_rechteloch \
  -c "grant select on public.click_outs to anon" > "$LOGDIR/$(printf '%03d' "$STEP")_h_grant.log" 2>&1 \
  || GRANT_RC=$?
if [[ $GRANT_RC -eq 0 ]]; then
  record h_setup_grant "grant select to anon" "ok/0" "$GRANT_RC" PASS "Rechte-Loch aufgerissen"
else
  mark_fail
  record h_setup_grant "grant select to anon" "ok/0" "$GRANT_RC" FAIL "grant fehlgeschlagen"
fi

report_table_expect_fail case_h_rechteloch h_03_nachher \
  "$SQL_DIR/03_verify_read_only.sql" 16 1 'click_outs_tabellenrechte_app_rollen'

# ===========================================================================
# CASE I — 03 meldet ein Rechte-Loch AUF DER SEQUENZ als FAIL
# ===========================================================================
# Die Tabelle bleibt hier vollstaendig dicht. Nur die Identity-Sequenz bekommt
# SELECT fuer anon — damit koennte anon ueber `last_value` die Zahl aller
# gezaehlten Klick-outs auslesen, ohne je eine Zeile zu sehen. Genau dieses
# Loch soll 03 finden.
new_case case_i_sequenzloch "anon bekommt SELECT auf click_outs_id_seq"
step case_i_sequenzloch ok i_02 "$SQL_DIR/02_create_clickouts.sql"
report_table case_i_sequenzloch i_03_vorher "$SQL_DIR/03_verify_read_only.sql" 17

STEP=$((STEP + 1))
SEQ_GRANT_RC=0
"$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_i_sequenzloch \
  -c "grant select on sequence public.click_outs_id_seq to anon" \
  > "$LOGDIR/$(printf '%03d' "$STEP")_i_grant.log" 2>&1 || SEQ_GRANT_RC=$?
if [[ $SEQ_GRANT_RC -eq 0 ]]; then
  record i_setup_grant "grant select on sequence to anon" "ok/0" "$SEQ_GRANT_RC" PASS \
    "Sequenz-Rechte-Loch aufgerissen"
else
  mark_fail
  record i_setup_grant "grant select on sequence to anon" "ok/0" "$SEQ_GRANT_RC" FAIL \
    "grant fehlgeschlagen"
fi

report_table_expect_fail case_i_sequenzloch i_03_nachher \
  "$SQL_DIR/03_verify_read_only.sql" 16 1 'click_outs_sequenzrechte'

# ===========================================================================
# CASE J — Retention-Planung: anlegen, nachpruefen, wiederholen
# ===========================================================================
# Der Happy Path von 04a/04b. Der zweite 04a-Lauf ist der wichtigste Schritt:
# er muss ein NO-OP sein und darf den Job weder ueberschreiben noch verdoppeln.
new_case case_j_retention_plan "04a anlegen, 04b nachpruefen, 04a wiederholen"
step case_j_retention_plan ok j_02        "$SQL_DIR/02_create_clickouts.sql"
step case_j_retention_plan ok j_04a       "$SQL_DIR/04a_schedule_retention.sql"
step case_j_retention_plan ok j_04a_assert "$HERE/cases/assert_after_04a.sql"
report_table case_j_retention_plan j_04b_frisch \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 9
# Zweitlauf: gleiche Werte, also kein Schreibvorgang und kein zweiter Job.
step case_j_retention_plan ok j_04a_wdh     "$SQL_DIR/04a_schedule_retention.sql"
step case_j_retention_plan ok j_04a_assert2 "$HERE/cases/assert_after_04a.sql"
report_table case_j_retention_plan j_04b_wdh \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 9
# Saubere Laufhistorie: 04b bleibt gruen.
step case_j_retention_plan ok j_runs_ok "$HERE/cases/setup_seed_job_runs.sql"
report_table case_j_retention_plan j_04b_mit_historie \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 9
# Ein fehlgeschlagener Lauf MUSS auffallen — sonst waere ein stillgelegter
# Loeschlauf von einem laufenden nicht zu unterscheiden.
step case_j_retention_plan ok j_run_failed "$HERE/cases/setup_seed_job_run_failed.sql"
report_table_expect_fail case_j_retention_plan j_04b_nach_fehlschlag \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 8 1 \
  'retention_job_ohne_fehlgeschlagene_laeufe'
# Der manuelle Loeschlauf bleibt neben der Planung unveraendert nutzbar.
step case_j_retention_plan ok j_04_manuell "$SQL_DIR/04_retention.sql"
step case_j_retention_plan ok j_04a_assert3 "$HERE/cases/assert_after_04a.sql"

# ===========================================================================
# CASE K — pg_cron gar nicht verfuegbar
# ===========================================================================
new_case case_k_ohne_cron "pg_cron fehlt vollstaendig"
step case_k_ohne_cron ok   k_02      "$SQL_DIR/02_create_clickouts.sql"
step case_k_ohne_cron ok   k_setup   "$HERE/cases/setup_drop_cron.sql"
step case_k_ohne_cron fail k_04a     "$SQL_DIR/04a_schedule_retention.sql" \
  'Retention-Planung abgebrochen: pg_cron ist nicht nutzbar'
step case_k_ohne_cron fail k_04b     "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" \
  'relation "cron.job" does not exist'
# Der manuelle Loeschlauf und der Rollback muessen ohne pg_cron unveraendert
# funktionieren — 04a darf keine neue Abhaengigkeit eingeschleppt haben.
step case_k_ohne_cron ok   k_04      "$SQL_DIR/04_retention.sql"
step case_k_ohne_cron ok   k_05      "$SQL_DIR/05_rollback.sql"
step case_k_ohne_cron ok   k_assert  "$HERE/cases/assert_after_05.sql"

# ===========================================================================
# CASE L — gleichnamiger Job mit fremdem Inhalt (Drift)
# ===========================================================================
# Der Kern des Ganzen: cron.schedule wuerde diesen Eintrag ueberschreiben.
# 04a und 05 muessen ihn stattdessen unangetastet lassen.
new_case case_l_job_drift "gleichnamiger Job mit anderem Schedule und Command"
step case_l_job_drift ok   l_02     "$SQL_DIR/02_create_clickouts.sql"
step case_l_job_drift ok   l_setup  "$HERE/cases/setup_drift_job.sql"
step case_l_job_drift fail l_04a    "$SQL_DIR/04a_schedule_retention.sql" \
  'Retention-Planung abgebrochen: Drift.'
step case_l_job_drift ok   l_assert "$HERE/cases/assert_drift_job_unveraendert.sql"
report_table_expect_fail case_l_job_drift l_04b \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 6 3 \
  'retention_job_schedule retention_job_command kein_zweiter_loeschjob'
step case_l_job_drift fail l_05     "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: Drift.'
step case_l_job_drift ok   l_assert2 "$HERE/cases/assert_drift_job_unveraendert.sql"
step case_l_job_drift ok   l_assert3 "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE M — derselbe Jobname zweimal im Katalog
# ===========================================================================
# Auf pg_cron liegt der eindeutige Index auf (jobname, username). Zwei Nutzer
# koennen denselben Jobnamen belegen — dann ist nicht entscheidbar, welcher
# Eintrag gemeint ist. Beide schreibenden Dateien muessen abbrechen.
new_case case_m_doppelter_jobname "derselbe Jobname unter zwei Nutzern"
step case_m_doppelter_jobname ok   m_02      "$SQL_DIR/02_create_clickouts.sql"
step case_m_doppelter_jobname ok   m_setup   "$HERE/cases/setup_doppelter_jobname.sql"
step case_m_doppelter_jobname fail m_04a     "$SQL_DIR/04a_schedule_retention.sql" \
  'Retention-Planung abgebrochen: doppelter Jobname.'
step case_m_doppelter_jobname ok   m_assert  "$HERE/cases/assert_zwei_jobs_unveraendert.sql"
step case_m_doppelter_jobname fail m_05      "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: doppelter Jobname.'
step case_m_doppelter_jobname ok   m_assert2 "$HERE/cases/assert_zwei_jobs_unveraendert.sql"
report_table_expect_fail case_m_doppelter_jobname m_04b \
  "$SQL_DIR/04b_verify_retention_schedule_read_only.sql" 2 7 \
  'retention_job_genau_einmal retention_job_aktiv retention_job_schedule retention_job_command retention_job_datenbank kein_zweiter_loeschjob retention_job_ohne_fehlgeschlagene_laeufe'

# ===========================================================================
# CASE N — anders benannter Job auf denselben Loeschpfad
# ===========================================================================
new_case case_n_fremder_purge_job "zweiter Loeschjob unter anderem Namen"
step case_n_fremder_purge_job ok   n_02      "$SQL_DIR/02_create_clickouts.sql"
step case_n_fremder_purge_job ok   n_setup   "$HERE/cases/setup_fremder_purge_job.sql"
step case_n_fremder_purge_job fail n_04a     "$SQL_DIR/04a_schedule_retention.sql" \
  'Retention-Planung abgebrochen: fremder purge_click_outs-Job.'
step case_n_fremder_purge_job ok   n_assert  "$HERE/cases/assert_nur_fremder_purge_job.sql"
step case_n_fremder_purge_job fail n_05      "$SQL_DIR/05_rollback.sql" \
  'Rollback abgebrochen: fremder purge_click_outs-Job.'
step case_n_fremder_purge_job ok   n_assert2 "$HERE/cases/assert_nur_fremder_purge_job.sql"
step case_n_fremder_purge_job ok   n_assert3 "$HERE/cases/assert_after_02.sql"

# ===========================================================================
# CASE O — Rollback bestellt den eigenen Job ab
# ===========================================================================
new_case case_o_rollback_mit_job "02 -> 04a -> Daten -> 05"
step case_o_rollback_mit_job ok   o_02        "$SQL_DIR/02_create_clickouts.sql"
step case_o_rollback_mit_job ok   o_04a       "$SQL_DIR/04a_schedule_retention.sql"
step case_o_rollback_mit_job ok   o_seed      "$HERE/cases/setup_seed_events.sql"
step case_o_rollback_mit_job ok   o_runs      "$HERE/cases/setup_seed_job_runs.sql"
step case_o_rollback_mit_job ok   o_05        "$SQL_DIR/05_rollback.sql"
step case_o_rollback_mit_job ok   o_assert    "$HERE/cases/assert_after_05.sql"
step case_o_rollback_mit_job ok   o_kein_job  "$HERE/cases/assert_kein_retention_job.sql"
# Danach laesst sich sauber neu anlegen und neu planen.
step case_o_rollback_mit_job ok   o_02_erneut "$SQL_DIR/02_create_clickouts.sql"
step case_o_rollback_mit_job ok   o_04a_erneut "$SQL_DIR/04a_schedule_retention.sql"
step case_o_rollback_mit_job ok   o_04a_assert "$HERE/cases/assert_after_04a.sql"

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
