#!/usr/bin/env bash
# =============================================================================
# LOKALER POSTGRESQL-HARNESS FUER DEN VALUE-ADD-ROLLOUT — BATCH 3
# =============================================================================
# Testet die ORIGINALDATEIEN 01_preflight_read_only.sql bis
# 05_restore_value_add_batch3.sql aus ../ gegen eine echte PostgreSQL-Instanz
# mit einer production-aehnlichen Fixture (Stand NACH Batch 1 UND Batch 2).
#
# Der Harness fasst KEINE Production- und KEINE Pilot-Datenbank an. Er startet
# einen eigenen Cluster in einem temporaeren Verzeichnis, der ausschliesslich
# ueber einen Unix-Socket erreichbar ist (listen_addresses='') und den er am
# Ende wieder stoppt. Keine Datei unter ../ wird veraendert, und keine Datei
# unter ../../production_value_add/ oder ../../production_value_add_batch2/
# wird veraendert oder ausgefuehrt — der Zustand der beiden Vorgaengerchargen
# wird von fixture/03_v1_v2_artifacts.sql nachgebaut, und CASE 0 belegt per
# sha256, dass beide Verzeichnisse byteweise unangetastet sind.
#
# ZWEISTUFIGER AUFBAU:
#   Stufe 1 (CASE 0) laeuft OHNE Cluster: sha256-Integritaet von Batch 1 und
#   Batch 2, SET-LOCAL-Position, begin/commit-Paarigkeit, Read-only-Reinheit
#   der vier lesenden Dateien, Vollstaendigkeit der zehn Zielslugs und
#   statische Disjunktheit gegen beide Vorgaengermengen. Diese Stufe laeuft
#   immer, auch ohne PostgreSQL.
#   Stufe 2 braucht einen Cluster. Fehlen die Binaries, meldet der Harness das
#   klar, gibt die Stufe-1-Ergebnisse vollstaendig aus und endet mit Exit 2.
#
# Aufruf:
#   ./run_local_postgres_test.sh                       # alles
#   CBB_STATIC_ONLY=1 ./run_local_postgres_test.sh     # nur CASE 0
#   CBB_KEEP_CLUSTER=1 ./run_local_postgres_test.sh    # Datenverzeichnis behalten
#   CBB_PG_BIN=/pfad/zu/postgresql/16 ./run_local_postgres_test.sh
#   CBB_PG_BIN=/pfad/zu/postgresql/16/bin ./run_local_postgres_test.sh
#     Beide Formen sind erlaubt: ein PostgreSQL-Prefix, das ein bin/ enthaelt,
#     oder direkt das bin-Verzeichnis.
#
# Exit-Code 0 = alle Erwartungen erfuellt, 1 = mindestens eine Abweichung,
# 2 = Umgebungsproblem (Binaries, initdb, Serverstart, createdb).
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$(cd "$HERE/.." && pwd)"          # production_value_add_batch3/
REPO_SUPABASE="$(cd "$SQL_DIR/.." && pwd)" # apps/web/supabase/

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cbb-pgtest-b3.XXXXXXXX")"
PGDATA="$WORKDIR/data"
SOCKDIR="$WORKDIR/sock"
LOGDIR="$WORKDIR/logs"
SERVERLOG="$WORKDIR/postgres.log"
RESULTS="$WORKDIR/results.tsv"
mkdir -p "$SOCKDIR" "$LOGDIR"

# Eindeutiger application_name fuer den Lock-Halter in CASE J.
LOCK_APP="cbb_lock_holder_b3_$(basename "$WORKDIR")"

# Englische Servermeldungen, damit die Erwartungs-Pattern stabil bleiben.
export LC_MESSAGES=C
export PGHOST="$SOCKDIR"
export PGUSER=postgres
export PGDATABASE=postgres

STEP=0
FAILURES=0
STATIC_FAILURES=0
CURRENT_CASE="-"
CLUSTER_UP=0

# Die zehn Batch-3-Zielslugs. Einmal definiert, mehrfach benutzt.
B3_SLUGS=(
  bartesian-cocktailmaschine-mit-kapseln
  dicmky-hoehenverstellbarer-schreibtisch-aufsatz
  laptop-staender-hoehenverstellbar-360-drehbar
  tecknet-ergonomische-kabellose-maus-bluetooth
  rocketbook-wiederverwendbares-notizbuch-a4
  ticktime-tk3-wuerfel-timer-countdown
  kabeltasche-edc-elektronik-organizer-reise
  silikon-magnete-airfryer-backpapier-4er-set
  tre-feuerstahl-xxl
  bbq-wuerstchenhalter-maennchen-3er-set
)

# Die zwanzig Slugs der Vorgaengerchargen. Keiner davon darf in der
# Batch-3-Zielmenge stehen.
VORGAENGER_SLUGS=(
  pinecil-usbc-loetkolben divoom-pixoo-led-panel sculpfun-s9-laser-engraver
  arc-reaktor-mk1-schwebend elektrische-wasserpistole-mit-led
  hot-wheels-ultimative-garage-3ft lego-creator-3in1-retro-kamera-31147
  ninja-staysharp-messerset-6-teilig n4-nussmilchbereiter-pflanzenmilch
  welpen-usb-ladekabel-hunde-design
  livondo-terracotta-pflanzenbewaesserung wixies-wichstuecher-scherzartikel
  kaffeewaermer-tassenwaermer-elektrisch gluecksgut-anti-stress-wuerfel
  infactory-boyfriend-kissen scheisse-quartett-kartenspiel
  riesige-aufblasbare-ente-pool shashibo-formwechsel-box-magnetisch
  eiswuerfelform-todesstern-star-wars katzenschlafsack-fuer-menschen
)

printf 'case\tstep\tlabel\tfile\texpect\texit\tverdict\tdetail\n' > "$RESULTS"

log()   { printf '%s\n' "$*"; }
head1() { printf '\n=== %s ===\n' "$*"; }

cleanup() {
  if [[ $CLUSTER_UP -eq 1 ]] && "$PG_CTL" -D "$PGDATA" status >/dev/null 2>&1; then
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
# static_v1_v2_manifest
#   sha256-Beleg, dass KEINE Datei der Changesets von Batch 1 und Batch 2
#   veraendert wurde. Deckt alle 73 Dateien unter production_value_add/ und
#   production_value_add_batch2/ plus den gemeinsam genutzten
#   seo_updated_at_trigger.sql ab.
# ---------------------------------------------------------------------------
static_v1_v2_manifest() {
  STEP=$((STEP + 1))
  local out="$LOGDIR/$(printf '%03d' "$STEP")_v1_v2_manifest.log"
  local rc=0
  ( cd "$HERE" && sha256sum -c V1_V2_MANIFEST.sha256 ) > "$out" 2>&1 || rc=$?

  local n_ok n_bad
  n_ok="$(grep -c ': OK$' "$out" || true)"
  n_bad="$(grep -cE ': (FAILED|FEHLGESCHLAGEN)' "$out" || true)"

  if [[ $rc -eq 0 && "$n_bad" -eq 0 && "$n_ok" -ge 74 ]]; then
    record v1_v2_manifest_sha256 "V1_V2_MANIFEST.sha256" "74x OK" "$rc" PASS \
      "$n_ok Dateien byte-identisch, 0 Abweichungen"
  else
    mark_static_fail
    record v1_v2_manifest_sha256 "V1_V2_MANIFEST.sha256" "74x OK" "$rc" FAIL \
      "$n_ok OK, $n_bad abweichend -> $out"
  fi
}

# ---------------------------------------------------------------------------
# static_set_local <sql-datei>
#   Beweist, dass "set local lock_timeout" und "set local statement_timeout"
#   genau einmal vorkommen, direkt hinter "begin;" stehen (nur Kommentar- und
#   Leerzeilen dazwischen) und vor dem ersten DO-Block liegen. Zusaetzlich:
#   genau ein "begin;" und genau ein "commit;".
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
    /^set local statement_timeout = .60s.;[ \t]*$/   { stmt_n++; if (stmt_l == 0) stmt_l = NR }
    /^[ \t]*do[ \t]*\$\$/                            { if (do_l == 0) do_l = NR }
    END {
      p = ""
      if (begin_n != 1)    p = p sprintf("begin;-Zeilen=%d (erwartet 1); ", begin_n)
      if (commit_n != 1)   p = p sprintf("commit;-Zeilen=%d (erwartet 1); ", commit_n)
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
# static_write_safety <sql-datei>
#   Fuer die drei schreibenden Dateien:
#     * kein DROP, kein TRUNCATE, kein DELETE ausserhalb von Kommentaren —
#       Batch 3 entfernt nichts, auch keine v3-Artefakte. Einzige erlaubte
#       Ausnahme ist die Klausel "on commit drop" der temporaeren Payload-
#       Tabelle in 03: sie raeumt ausschliesslich die Sitzungstabelle ab.
#     * jede ausfuehrbare Zeile, die value_add_*_v1 oder value_add_*_v2 nennt,
#       muss dies innerhalb eines to_regclass()-Aufrufs tun. Damit ist statisch
#       belegt, dass beide Vorgaengerchargen ausschliesslich auf Existenz
#       geprueft und nie gelesen oder geschrieben werden.
# ---------------------------------------------------------------------------
static_write_safety() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="writesafe_$(basename "$file" .sql)"
  local res
  res="$(awk '
    {
      l = $0
      sub(/--.*$/, "", l)           # Kommentare entfernen
      if (l ~ /^[ \t]*$/) next
      low = tolower(l)
      if (low ~ /on[ \t]+commit[ \t]+drop/) { oncommit++; sub(/on[ \t]+commit[ \t]+drop/, "@", low) }
      if (low ~ /(^|[^_a-z0-9])drop([^_a-z0-9]|$)/)     bad_drop++
      if (low ~ /(^|[^_a-z0-9])truncate([^_a-z0-9]|$)/) bad_trunc++
      if (low ~ /(^|[^_a-z0-9])delete([^_a-z0-9]|$)/)   bad_del++
      if (low ~ /value_add_(pre_backfill|payload)_v[12]/) {
        vorg_lines++
        if (low !~ /to_regclass/) { vorg_bad++; if (vorg_bad_l == 0) vorg_bad_l = NR }
      }
    }
    END {
      p = ""
      if (bad_drop  > 0) p = p sprintf("%d ausfuehrbare DROP-Zeile(n); ", bad_drop)
      if (bad_trunc > 0) p = p sprintf("%d ausfuehrbare TRUNCATE-Zeile(n); ", bad_trunc)
      if (bad_del   > 0) p = p sprintf("%d ausfuehrbare DELETE-Zeile(n); ", bad_del)
      if (vorg_bad  > 0) p = p sprintf("%d v1-/v2-Referenz(en) ohne to_regclass, erste in Z%d; ", vorg_bad, vorg_bad_l)
      if (p == "")
        printf "OK|0 DROP/TRUNCATE/DELETE (%d x erlaubtes on-commit-drop), %d v1-/v2-Referenzen alle via to_regclass\n", oncommit, vorg_lines
      else
        printf "PROBLEM|%s\n", p
    }
  ' "$file")"

  if [[ "$res" == OK\|* ]]; then
    record "$label" "$(basename "$file")" "kein DROP, v1/v2 ro" "-" PASS "${res#OK|}"
  else
    mark_static_fail
    record "$label" "$(basename "$file")" "kein DROP, v1/v2 ro" "-" FAIL "${res#PROBLEM|}"
  fi
}

# ---------------------------------------------------------------------------
# static_read_only <sql-datei>
#   Fuer die vier lesenden Dateien: nach dem Entfernen von Kommentaren und
#   Text-Literalen darf kein DDL-, DML-, Rechte- oder Transaktions-Schluesselwort
#   uebrig bleiben, und es darf genau EIN Semikolon geben.
#
#   Reihenfolge bewusst: erst Kommentare, dann Literale. Kein Literal dieser
#   Dateien enthaelt "--", waehrend Kommentare sehr wohl Apostrophe enthalten
#   koennen. Umgekehrt waere die Auswertung fragil.
# ---------------------------------------------------------------------------
static_read_only() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="readonly_$(basename "$file" .sql)"
  local res
  res="$(awk '
    {
      l = $0
      sub(/--.*$/, "", l)                       # 1. Kommentare weg
      gsub(/'"'"'([^'"'"']|'"'"''"'"')*'"'"'/, "@", l)  # 2. Text-Literale weg
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
# static_slug_set <sql-datei>
#   Belegt, dass in JEDER Batch-3-Datei alle zehn Zielslugs vorkommen. Ein
#   vergessener Slug wuerde sonst erst im Cluster auffallen.
# ---------------------------------------------------------------------------
static_slug_set() {
  local file="$1"
  STEP=$((STEP + 1))
  local label="slugs_$(basename "$file" .sql)"
  local missing="" found=0 s
  for s in "${B3_SLUGS[@]}"; do
    if grep -Fq -- "$s" "$file"; then
      found=$((found + 1))
    else
      missing="$missing $s"
    fi
  done

  if [[ $found -eq 10 ]]; then
    record "$label" "$(basename "$file")" "10/10 Slugs" "-" PASS \
      "alle zehn Batch-3-Slugs vorhanden"
  else
    mark_static_fail
    record "$label" "$(basename "$file")" "10/10 Slugs" "-" FAIL \
      "nur $found/10 Slugs, es fehlen:$missing"
  fi
}

# ---------------------------------------------------------------------------
# static_disjunkt
#   Statischer Disjunktheitsbeweis: keiner der zwanzig Slugs aus Batch 1 und
#   Batch 2 darf in der Batch-3-Zielliste stehen. Geprueft wird gegen die im
#   Harness definierte Liste — nicht gegen den Dateiinhalt, in dem die
#   Vorgaengerslugs als Referenzmengen absichtlich vorkommen.
# ---------------------------------------------------------------------------
static_disjunkt() {
  STEP=$((STEP + 1))
  local kollisionen="" a b
  for a in "${B3_SLUGS[@]}"; do
    for b in "${VORGAENGER_SLUGS[@]}"; do
      [[ "$a" == "$b" ]] && kollisionen="$kollisionen $a"
    done
  done

  if [[ -z "$kollisionen" ]]; then
    record disjunkt_b3_gegen_b1_b2 "Slug-Listen" "0 Kollisionen" "-" PASS \
      "10 Batch-3-Slugs gegen 20 Vorgaengerslugs, keine Ueberschneidung"
  else
    mark_static_fail
    record disjunkt_b3_gegen_b1_b2 "Slug-Listen" "0 Kollisionen" "-" FAIL \
      "Kollisionen:$kollisionen"
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

head1 "case_0_statisch — Integritaet von Batch 1 und 2, SET-LOCAL, Read-only, Disjunktheit"
CURRENT_CASE=case_0_statisch

static_v1_v2_manifest

static_set_local "$SQL_DIR/02_backup_value_add_batch3.sql"
static_set_local "$SQL_DIR/03_backfill_value_add_batch3.sql"
static_set_local "$SQL_DIR/05_restore_value_add_batch3.sql"

static_write_safety "$SQL_DIR/02_backup_value_add_batch3.sql"
static_write_safety "$SQL_DIR/03_backfill_value_add_batch3.sql"
static_write_safety "$SQL_DIR/05_restore_value_add_batch3.sql"

static_read_only "$SQL_DIR/01_preflight_read_only.sql"
static_read_only "$SQL_DIR/02b_verify_snapshot_read_only.sql"
static_read_only "$SQL_DIR/04_verify_read_only.sql"
static_read_only "$SQL_DIR/04b_verify_payload_security_read_only.sql"

static_slug_set "$SQL_DIR/01_preflight_read_only.sql"
static_slug_set "$SQL_DIR/02_backup_value_add_batch3.sql"
static_slug_set "$SQL_DIR/02b_verify_snapshot_read_only.sql"
static_slug_set "$SQL_DIR/03_backfill_value_add_batch3.sql"
static_slug_set "$SQL_DIR/04_verify_read_only.sql"
static_slug_set "$SQL_DIR/05_restore_value_add_batch3.sql"

static_disjunkt
static_target_named

log ""
log "CASE 0 abgeschlossen: $STEP statische Pruefungen, $STATIC_FAILURES Abweichungen."

if [[ $STATIC_FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: statische Pruefungen sind nicht sauber — der Lock-Test und die"
  log "Datenbankfaelle waeren nicht aussagekraeftig."
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
# LD_LIBRARY_PATH nicht gefunden (initdb bricht sonst mit Exit 127 ab).
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
#
#   expect=ok    -> psql muss mit Exit 0 zurueckkommen.
#   expect=fail  -> psql muss mit Exit 3 zurueckkommen (Server-Exception bei
#                   ON_ERROR_STOP=1) UND das uebergebene Literal muss im
#                   Output stehen. Das Literal ist PFLICHT: fehlt es, ist der
#                   Schritt FAIL. Ein anderer Fehler als der erwartete ist
#                   ebenfalls FAIL — "irgendein Exit != 0" reicht nicht.
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
#   Die vier lesenden Dateien melden Probleme NICHT ueber den Exit-Code,
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
# report_table_expect_fail <db> <label> <sql-datei> <erwartete-PASS>
#                          <erwartete-FAIL> <pflicht-pruefname>
#   Fuer den bewusst kaputt gemachten Sicherheitsfall: die Datei MUSS FAIL
#   melden, und zwar in exakt dieser Zahl und mit dem genannten Pruefnamen.
#   Ein PASS waere hier der eigentliche Befund.
# ---------------------------------------------------------------------------
report_table_expect_fail() {
  local db="$1" label="$2" file="$3" want_pass="$4" want_fail="$5" want_name="$6"
  STEP=$((STEP + 1))
  local base="$LOGDIR/$(printf '%03d' "$STEP")_${label//[^A-Za-z0-9_.-]/_}"
  local rc=0

  "$PSQL" -X -q -A -F '|' -t -v ON_ERROR_STOP=1 -d "$db" -f "$file" \
    > "$base.psv" 2>&1 || rc=$?

  local failrows=0 passrows=0 namehit=0
  if [[ $rc -eq 0 ]]; then
    failrows="$(grep -c '|FAIL$' "$base.psv" || true)"
    passrows="$(grep -c '|PASS$' "$base.psv" || true)"
    namehit="$(grep '|FAIL$' "$base.psv" | grep -c -F -- "$want_name" || true)"
  fi

  local verdict detail
  if [[ $rc -eq 0 && "$failrows" -eq "$want_fail" && "$passrows" -eq "$want_pass" \
        && "$namehit" -ge 1 ]]; then
    verdict=PASS
    detail="Sicherheitsluecke korrekt als FAIL gemeldet: $failrows FAIL (davon $want_name), $passrows PASS"
  else
    verdict=FAIL
    mark_fail
    detail="exit=$rc, $passrows PASS (erwartet $want_pass), $failrows FAIL (erwartet $want_fail), Treffer fuer <$want_name>: $namehit"
  fi

  record "$label" "$(basename "$file")" "${want_pass}xPASS/${want_fail}xFAIL" "$rc" \
    "$verdict" "$detail"
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

step cbb_fixture ok fixture_roles           "$HERE/fixture/00_roles.sql"
step cbb_fixture ok fixture_schema          "$HERE/fixture/01_schema.sql"
step cbb_fixture ok fixture_seed            "$HERE/fixture/02_seed.sql"
step cbb_fixture ok fixture_real_trigger    "$REPO_SUPABASE/seo_updated_at_trigger.sql"
step cbb_fixture ok fixture_v1_v2_artefakte "$HERE/fixture/03_v1_v2_artifacts.sql"
step cbb_fixture ok fixture_assert          "$HERE/fixture/04_assert_fixture.sql"
step cbb_fixture ok fixture_baseline        "$HERE/fixture/05_baseline.sql"

if [[ $FAILURES -ne 0 ]]; then
  log ""
  log "ABBRUCH: Fixture ist nicht sauber, weitere Ergebnisse waeren wertlos."
  exit 1
fi

# ===========================================================================
# CASE A — Happy Path 01 -> 04b in der vorgesehenen Reihenfolge
# ===========================================================================
new_case case_a_happy_path "01 bis 04b in Reihenfolge"
report_table case_a_happy_path a_01_preflight "$SQL_DIR/01_preflight_read_only.sql" 18
step case_a_happy_path ok a_02_backup   "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_a_happy_path ok a_02_assert   "$HERE/cases/assert_after_02.sql"
report_table case_a_happy_path a_02b_verify_snapshot "$SQL_DIR/02b_verify_snapshot_read_only.sql" 17
step case_a_happy_path ok a_03_backfill "$SQL_DIR/03_backfill_value_add_batch3.sql"
step case_a_happy_path ok a_03_assert   "$HERE/cases/assert_after_03.sql"
step case_a_happy_path ok a_vorgaenger  "$HERE/cases/assert_v1_v2_untouched.sql"
report_table case_a_happy_path a_04_verify "$SQL_DIR/04_verify_read_only.sql" 17
report_table case_a_happy_path a_04b_verify_security "$SQL_DIR/04b_verify_payload_security_read_only.sql" 10

# ===========================================================================
# CASE B — Fail-closed-Wiederholungen und verfruehte Verify-Laeufe
# ===========================================================================
new_case case_b_wiederholungen "Doppelausfuehrung jeder schreibenden Datei"
step case_b_wiederholungen fail b_02b_vor_backup "$SQL_DIR/02b_verify_snapshot_read_only.sql" \
  'relation "cbb_private_backup.value_add_pre_backfill_v3" does not exist'
step case_b_wiederholungen fail b_03_vor_backup  "$SQL_DIR/03_backfill_value_add_batch3.sql" \
  'Batch-3-Backfill abgebrochen: privater Snapshot v3 fehlt.'
step case_b_wiederholungen fail b_05_vor_backup  "$SQL_DIR/05_restore_value_add_batch3.sql" \
  'Batch-3-Restore abgebrochen: privater Snapshot v3 fehlt.'
step case_b_wiederholungen ok   b_02_backup      "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_b_wiederholungen fail b_02_wiederholung "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: Snapshot v3 existiert bereits.'
step case_b_wiederholungen ok   b_02_nach_abbruch "$HERE/cases/assert_after_02.sql"
step case_b_wiederholungen fail b_04_vor_backfill "$SQL_DIR/04_verify_read_only.sql" \
  'relation "cbb_private_backup.value_add_payload_v3" does not exist'
step case_b_wiederholungen fail b_04b_vor_backfill "$SQL_DIR/04b_verify_payload_security_read_only.sql" \
  'relation "cbb_private_backup.value_add_payload_v3" does not exist'
step case_b_wiederholungen ok   b_03_backfill     "$SQL_DIR/03_backfill_value_add_batch3.sql"
# Nach einem erfolgreichen 03 schlaegt der PAYLOAD-Guard zu, nicht der
# Drift-Guard: die Existenzpruefung von value_add_payload_v3 steht bewusst im
# ersten Guard-Block und damit vor dem Zeilen-Lock. Der Drift-Guard wird in
# case_n_drift eigens geprueft.
step case_b_wiederholungen fail b_03_wiederholung "$SQL_DIR/03_backfill_value_add_batch3.sql" \
  'Batch-3-Backfill abgebrochen: Audit-Payload v3 existiert bereits.'
step case_b_wiederholungen ok   b_03_nach_abbruch "$HERE/cases/assert_after_03.sql"
step case_b_wiederholungen ok   b_vorgaenger      "$HERE/cases/assert_v1_v2_untouched.sql"

# ===========================================================================
# CASE N — Drift zwischen Snapshot und Bestand
# ===========================================================================
new_case case_n_drift "Zielzeile aendert sich nach dem Snapshot"
step case_n_drift ok   n_02_backup   "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_n_drift ok   n_setup_drift "$HERE/cases/setup_drift_after_snapshot.sql"
step case_n_drift fail n_03_abbruch  "$SQL_DIR/03_backfill_value_add_batch3.sql" \
  'Batch-3-Backfill abgebrochen: 1 Zielzeilen sind seit dem Snapshot gedriftet.'
step case_n_drift ok   n_assert      "$HERE/cases/assert_drift_unchanged.sql"
step case_n_drift ok   n_vorgaenger  "$HERE/cases/assert_v1_v2_untouched.sql"
# 02b ist read-only und meldet den Drift nicht ueber den Exit-Code, sondern als
# FAIL-Zeile. Genau eine Zeile muss umschlagen.
report_table_expect_fail case_n_drift n_02b_meldet_drift \
  "$SQL_DIR/02b_verify_snapshot_read_only.sql" 16 1 \
  'snapshot_v3_gegen_products_drift'

# ===========================================================================
# CASE C — Transaktions-Rollback mitten in 03
# ===========================================================================
new_case case_c_rollback "Abbruch nach dem Payload-DDL in 03"
step case_c_rollback ok   c_02_backup         "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_c_rollback ok   c_block_installieren "$HERE/cases/setup_block_updates.sql"
step case_c_rollback fail c_03_bricht_ab      "$SQL_DIR/03_backfill_value_add_batch3.sql" \
  'CBB-TEST: UPDATE auf products absichtlich blockiert.'
step case_c_rollback ok   c_rollback_assert   "$HERE/cases/assert_03_rolled_back.sql"
step case_c_rollback ok   c_vorgaenger        "$HERE/cases/assert_v1_v2_untouched.sql"
step case_c_rollback ok   c_block_entfernen   "$HERE/cases/teardown_block_updates.sql"
step case_c_rollback ok   c_03_danach_ok      "$SQL_DIR/03_backfill_value_add_batch3.sql"
step case_c_rollback ok   c_03_assert         "$HERE/cases/assert_after_03.sql"

# ===========================================================================
# CASE D — Restore-Roundtrip
# ===========================================================================
new_case case_d_restore_roundtrip "02 -> 03 -> 05 -> 05 mit Round-Trip-Beweis"
step case_d_restore_roundtrip ok   d_02_backup       "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_d_restore_roundtrip ok   d_03_backfill     "$SQL_DIR/03_backfill_value_add_batch3.sql"
step case_d_restore_roundtrip ok   d_05_restore      "$SQL_DIR/05_restore_value_add_batch3.sql"
step case_d_restore_roundtrip ok   d_05_assert       "$HERE/cases/assert_after_05.sql"
step case_d_restore_roundtrip ok   d_05_wiederholung "$SQL_DIR/05_restore_value_add_batch3.sql"
step case_d_restore_roundtrip ok   d_05_assert_2     "$HERE/cases/assert_after_05.sql"
step case_d_restore_roundtrip fail d_03_nach_restore "$SQL_DIR/03_backfill_value_add_batch3.sql" \
  'Batch-3-Backfill abgebrochen: Audit-Payload v3 existiert bereits.'
step case_d_restore_roundtrip ok   d_05_assert_3     "$HERE/cases/assert_after_05.sql"
step case_d_restore_roundtrip ok   d_vorgaenger      "$HERE/cases/assert_v1_v2_untouched.sql"

# ===========================================================================
# CASE E-H, M — Negative Umgebungs- und Zustands-Guards
# ===========================================================================
new_case case_e_pilot_artefakt "Pilot-Marker vorhanden"
step case_e_pilot_artefakt ok   e_setup      "$HERE/cases/setup_pilot_artifact.sql"
step case_e_pilot_artefakt fail e_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: Pilot-Artefakt gefunden.'
step case_e_pilot_artefakt ok   e_assert     "$HERE/cases/assert_no_batch3_artifacts.sql"
step case_e_pilot_artefakt ok   e_vorgaenger "$HERE/cases/assert_v1_v2_untouched.sql"

new_case case_f_zu_wenig_produkte "Bestand unter 300"
step case_f_zu_wenig_produkte ok   f_setup      "$HERE/cases/setup_shrink_below_300.sql"
step case_f_zu_wenig_produkte fail f_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: nur 299 Produkte (< 300).'
step case_f_zu_wenig_produkte ok   f_assert     "$HERE/cases/assert_no_batch3_artifacts.sql"
step case_f_zu_wenig_produkte ok   f_vorgaenger "$HERE/cases/assert_v1_v2_untouched.sql"

new_case case_g_unvollstaendiges_schema "7 von 8 Value-Add-Spalten"
step case_g_unvollstaendiges_schema ok   g_setup      "$HERE/cases/setup_drop_value_add_column.sql"
step case_g_unvollstaendiges_schema fail g_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: Value-Add-Schema unvollstaendig (7 Spalten, 7 Typen, 2 Constraints).'
step case_g_unvollstaendiges_schema ok   g_assert     "$HERE/cases/assert_schema_teilzustand.sql"

new_case case_h_relationsziel_offline "Ein Relationsziel unpublished"
step case_h_relationsziel_offline ok   h_setup      "$HERE/cases/setup_unpublish_relation.sql"
step case_h_relationsziel_offline fail h_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: 9/10 Zielprodukte published.'
step case_h_relationsziel_offline ok   h_assert     "$HERE/cases/assert_no_batch3_artifacts.sql"
step case_h_relationsziel_offline ok   h_vorgaenger "$HERE/cases/assert_v1_v2_untouched.sql"

new_case case_m_fremdbefuellung "Eine Zielzeile traegt schon Value-Add-Daten"
step case_m_fremdbefuellung ok   m_setup      "$HERE/cases/setup_prefill_one_target.sql"
step case_m_fremdbefuellung fail m_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: 1 Zielprodukte enthalten bereits Value-Add-Daten.'
step case_m_fremdbefuellung ok   m_assert     "$HERE/cases/assert_prefill_unchanged.sql"
step case_m_fremdbefuellung ok   m_vorgaenger "$HERE/cases/assert_v1_v2_untouched.sql"

# ===========================================================================
# CASE K — Vorgaenger-Artefakt fehlt
# ===========================================================================
new_case case_k_vorgaenger_artefakt_fehlt "value_add_payload_v2 geloescht"
step case_k_vorgaenger_artefakt_fehlt ok   k_setup      "$HERE/cases/setup_drop_v2_payload.sql"
step case_k_vorgaenger_artefakt_fehlt fail k_02_abbruch "$SQL_DIR/02_backup_value_add_batch3.sql" \
  'Batch-3-Backup abgebrochen: Batch-2-Payload v2 fehlt.'
step case_k_vorgaenger_artefakt_fehlt ok   k_assert     "$HERE/cases/assert_v2_payload_missing.sql"

# ===========================================================================
# CASE L — Payload-Sicherheit: 04b muss ein Rechte-Loch als FAIL melden
# ===========================================================================
new_case case_l_payload_security "anon bekommt SELECT auf die Audit-Payload"
step case_l_payload_security ok l_02_backup   "$SQL_DIR/02_backup_value_add_batch3.sql"
step case_l_payload_security ok l_03_backfill "$SQL_DIR/03_backfill_value_add_batch3.sql"
report_table case_l_payload_security l_04b_vorher \
  "$SQL_DIR/04b_verify_payload_security_read_only.sql" 10
step case_l_payload_security ok l_setup_grant "$HERE/cases/setup_grant_payload_to_anon.sql"
# Erwartet schlagen genau zwei Zeilen um: die Tabellenrechte auf der Payload
# (direkt UND effektiv) und die Schemarechte (USAGE fuer anon).
report_table_expect_fail case_l_payload_security l_04b_nachher \
  "$SQL_DIR/04b_verify_payload_security_read_only.sql" 8 2 \
  'payload_v3_tabellenrechte_app_rollen'

# ===========================================================================
# CASE O — Snapshot-Sicherheit: 02b muss ein Rechte-Loch als FAIL melden
# Bewusst ein eigener Fall und nicht Teil von case_l: 02b verlangt zusaetzlich,
# dass value_add_payload_v3 noch NICHT existiert. Nach einem Backfill waere
# diese Zeile ebenfalls FAIL und die Zaehlung nicht mehr eindeutig dem
# Rechte-Loch zuzuordnen.
# ===========================================================================
new_case case_o_snapshot_security "anon bekommt SELECT auf den Snapshot"
step case_o_snapshot_security ok o_02_backup "$SQL_DIR/02_backup_value_add_batch3.sql"
report_table case_o_snapshot_security o_02b_vorher \
  "$SQL_DIR/02b_verify_snapshot_read_only.sql" 17
step case_o_snapshot_security ok o_setup_grant "$HERE/cases/setup_grant_snapshot_to_anon.sql"
report_table_expect_fail case_o_snapshot_security o_02b_nachher \
  "$SQL_DIR/02b_verify_snapshot_read_only.sql" 15 2 \
  'snapshot_v3_tabellenrechte_app_rollen'

# ===========================================================================
# CASE I — Trigger-Verhalten (Voraussetzung fuer 03 und 05)
# ===========================================================================
new_case case_i_trigger "seo_updated_at_trigger im Zusammenspiel"
step case_i_trigger ok i_trigger "$HERE/cases/assert_trigger_behaviour.sql"

# ===========================================================================
# CASE J — Lock-Timeout: 02 muss unter Sperrkonflikt nach ~5 s abbrechen
# ===========================================================================
new_case case_j_lock_timeout "AccessExclusiveLock blockiert 02"
step case_j_lock_timeout ok j_vorbereitung "$HERE/cases/assert_no_batch3_artifacts.sql"

J_ERWARTET='canceling statement due to lock timeout'
LOCKER_SQL="$WORKDIR/locker.sql"
cat > "$LOCKER_SQL" <<'LOCKEOF'
begin;
lock table public.products in access exclusive mode;
select pg_sleep(90);
rollback;
LOCKEOF

PGAPPNAME="$LOCK_APP" "$PSQL" -X -q -d case_j_lock_timeout -f "$LOCKER_SQL" \
  > "$LOGDIR/900_locker.log" 2>&1 &
LOCKER_PID=$!

# pg_locks ist clusterweit, pg_class aber datenbanklokal. Die Abfrage laeuft
# deshalb IN case_j_lock_timeout und filtert zusaetzlich auf dessen OID.
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

STEP=$((STEP + 1))
J_OUT="$LOGDIR/$(printf '%03d' "$STEP")_j_02_unter_sperre.log"
J_DIAG="$LOGDIR/$(printf '%03d' "$STEP")_j_02_wartet_auf.log"
J_RC=0
J_ELAPSED=-1

if [[ $LOCK_HELD -ne 1 ]]; then
  mark_fail
  record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "-" FAIL \
    "Sperre konnte nicht aufgebaut werden — Fall nicht bewertbar"
else
  J_START=$SECONDS
  timeout 30 "$PSQL" -X -q -v ON_ERROR_STOP=1 -d case_j_lock_timeout \
    -f "$SQL_DIR/02_backup_value_add_batch3.sql" > "$J_OUT" 2>&1 &
  J_PSQL_PID=$!

  # Belegen, WO 02 haengt. Der Wartepunkt muss bereits unter dem gesetzten
  # lock_timeout liegen.
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
    record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "$J_RC" FAIL \
      "Client-Timeout nach 30s: lock_timeout greift in der Guard-Phase nicht"
  elif [[ $J_RC -ne 3 ]]; then
    mark_fail
    record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "$J_RC" FAIL \
      "Exit $J_RC statt 3 nach ${J_ELAPSED}s — $J_MSG"
  elif ! grep -Fq -- "$J_ERWARTET" "$J_OUT"; then
    mark_fail
    record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "$J_RC" FAIL \
      "falscher Fehler. erwartet: <$J_ERWARTET> | tatsaechlich: $J_MSG"
  elif [[ $J_ELAPSED -lt 3 || $J_ELAPSED -gt 15 ]]; then
    mark_fail
    record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "$J_RC" FAIL \
      "richtige Meldung, aber Laufzeit ${J_ELAPSED}s ausserhalb 3-15s (lock_timeout='5s')"
  else
    record j_02_unter_sperre "02_backup_value_add_batch3.sql" "fail/3" "$J_RC" PASS \
      "lock timeout nach ${J_ELAPSED}s: $J_ERWARTET"
  fi
fi

# Lock-Halter zuverlaessig beenden: pg_terminate_backend ueber den eindeutigen
# application_name. Ein blosser kill des psql-Clients wuerde das Server-Backend
# nicht garantiert beenden.
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

step case_j_lock_timeout ok j_assert_unveraendert "$HERE/cases/assert_no_batch3_artifacts.sql"

# Der Nachtest darf nicht auf das Ende von pg_sleep(90) warten.
N_START=$SECONDS
step case_j_lock_timeout ok j_02_danach "$SQL_DIR/02_backup_value_add_batch3.sql"
N_ELAPSED=$((SECONDS - N_START))
log "  j_02_danach Laufzeit: ${N_ELAPSED}s (muss deutlich unter pg_sleep(90) liegen)"
if [[ $N_ELAPSED -gt 30 ]]; then
  mark_fail
  log "  [FAIL] j_02_danach brauchte ${N_ELAPSED}s — die Sperre wurde nicht wirklich geloest."
fi
step case_j_lock_timeout ok j_02_assert "$HERE/cases/assert_after_02.sql"

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
