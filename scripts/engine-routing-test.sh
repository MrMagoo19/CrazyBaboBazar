#!/usr/bin/env bash
#
# Test-Harness fuer die Engine-Routing-Verdrahtung des CLAUDE WORKER.
#
#   ./scripts/engine-routing-test.sh              # vollstaendige Testsuite
#   ./scripts/engine-routing-test.sh <prompt>     # nur einen Prompt inspizieren
#
# Die Suite ruft NIE das echte Claude auf: der Integrationsteil startet den
# echten Runner mit einem Stub-`claude` am Anfang von PATH und einem
# Wegwerf-State-Verzeichnis. Kein Netz, kein Commit, keine Production-Aktion.

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTING_FILE="${REPO_ROOT}/.claude/agents/engine-routing.md"
ROUTING_LIB="${REPO_ROOT}/scripts/engine-routing-lib.sh"
WORKER_SCRIPT="${REPO_ROOT}/scripts/claude-worker-terminal.sh"

# shellcheck source=scripts/engine-routing-lib.sh
source "${ROUTING_LIB}"

tests_passed=0
tests_failed=0

pass() { printf '  PASS  %s\n' "$1"; tests_passed=$((tests_passed + 1)); }
fail() {
  printf '  FAIL  %s\n' "$1"
  [[ $# -lt 2 ]] || printf '        %s\n' "$2"
  tests_failed=$((tests_failed + 1))
}

assert_eq() { # <name> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    pass "$1"
  else
    fail "$1" "erwartet: '$2' | erhalten: '$3'"
  fi
}

# --------------------------------------------------------------------------
# Inspektionsmodus: einzelnen Prompt durch dieselbe Logik schicken.
# --------------------------------------------------------------------------
inspect_prompt() {
  local prompt_file="$1" agent engine
  if [[ ! -f "${prompt_file}" ]]; then
    echo "PROMPT file not found: ${prompt_file}" >&2
    exit 2
  fi

  echo "Routingdatei: ${ROUTING_FILE}"
  echo "Erlaubte Engines: $(cbb_allowed_engines "${ROUTING_FILE}" | tr '\n' ' ')"
  echo
  echo "--- Prompt head ---"
  head -n 60 -- "${prompt_file}"
  echo "--- /Prompt head ---"
  echo

  agent="$(cbb_detect_agent_from_prompt "${prompt_file}")"
  if [[ -z "${agent}" ]]; then
    echo "Kein Agent im Frontmatter gefunden — Claude laeuft mit Default-Engine."
  else
    echo "Erkannter Agent: ${agent}"
    engine="$(cbb_lookup_recommended_engine "${ROUTING_FILE}" "${agent}")"
    if [[ -n "${engine}" ]]; then
      echo "Empfohlene Engine: ${engine}"
    else
      echo "Keine empfohlene Engine fuer '${agent}' — Default-Engine."
      engine=""
    fi
  fi

  cbb_build_model_args "true" "${engine:-}"
  cbb_build_claude_args "plain" "${REPO_ROOT}" "/dev/null"
  echo
  echo "Simulierter Aufruf:"
  printf 'claude'
  printf ' %q' ${CBB_CLAUDE_MODEL_ARGS[@]+"${CBB_CLAUDE_MODEL_ARGS[@]}"} \
    ${CBB_CLAUDE_ARGS[@]+"${CBB_CLAUDE_ARGS[@]}"} -p -- '<prompt>'
  printf '\n'
}

if [[ $# -gt 0 ]]; then
  inspect_prompt "$1"
  exit 0
fi

# --------------------------------------------------------------------------
# 1. Frontmatter-Parsing
# --------------------------------------------------------------------------
echo "== 1. Frontmatter-Parsing =="
TMP_ROOT="$(mktemp -d -t cbb-engine-routing-test.XXXXXX)"
RUNNER_PID=""
STATE_DIR=""
cleanup_all() {
  [[ -z "${RUNNER_PID}" ]] || kill "${RUNNER_PID}" 2>/dev/null
  [[ -z "${STATE_DIR}" ]] || rm -rf -- "${STATE_DIR}"
  rm -rf -- "${TMP_ROOT}"
}
trap cleanup_all EXIT

printf -- '---\nagent: scout\n---\nZaehle Produkte.\n' > "${TMP_ROOT}/p-top.prompt"
printf 'Vorspann, weil ein Prompt nicht mit "---" beginnen darf.\n\n---\nagent: code-auditor\n---\nAuditiere.\n' \
  > "${TMP_ROOT}/p-preamble.prompt"
printf 'Kein Frontmatter hier.\n' > "${TMP_ROOT}/p-none.prompt"
printf -- '---\nagent: "scout; rm -rf /"\n---\nBoese.\n' > "${TMP_ROOT}/p-evil.prompt"
printf -- '---\nagent: frobnicator\n---\nUnbekannt.\n' > "${TMP_ROOT}/p-unknown.prompt"

assert_eq "Frontmatter am Prompt-Anfang" "scout" \
  "$(cbb_detect_agent_from_prompt "${TMP_ROOT}/p-top.prompt")"
assert_eq "Frontmatter nach Vorspann" "code-auditor" \
  "$(cbb_detect_agent_from_prompt "${TMP_ROOT}/p-preamble.prompt")"
assert_eq "Ohne Frontmatter kein Agent" "" \
  "$(cbb_detect_agent_from_prompt "${TMP_ROOT}/p-none.prompt")"
assert_eq "Ungueltiger Agentname wird verworfen" "" \
  "$(cbb_detect_agent_from_prompt "${TMP_ROOT}/p-evil.prompt" 2>/dev/null)"

# --------------------------------------------------------------------------
# 2. Routing-Lookup
# --------------------------------------------------------------------------
echo
echo "== 2. Routing-Lookup =="
for pair in "scout:haiku" "rechercheur:sonnet" "code-auditor:sonnet" "texter:sonnet" "pruefer:opus"; do
  agent="${pair%%:*}"
  expected="${pair##*:}"
  assert_eq "Lookup ${agent}" "${expected}" \
    "$(cbb_lookup_recommended_engine "${ROUTING_FILE}" "${agent}")"
done
assert_eq "Lookup unbekannter Agent" "" \
  "$(cbb_lookup_recommended_engine "${ROUTING_FILE}" "frobnicator" 2>/dev/null)"
assert_eq "Lookup ohne Agent" "" \
  "$(cbb_lookup_recommended_engine "${ROUTING_FILE}" "" 2>/dev/null)"
assert_eq "Top-Level-Key ist kein Agent" "" \
  "$(cbb_lookup_recommended_engine "${ROUTING_FILE}" "para_memory" 2>/dev/null)"

# --------------------------------------------------------------------------
# 3. Sichere Modellargumente
# --------------------------------------------------------------------------
echo
echo "== 3. Modellargument-Bildung =="
cbb_build_model_args "true" "haiku"
assert_eq "auto-inject an + Engine" "--model|haiku" \
  "$(IFS='|'; echo "${CBB_CLAUDE_MODEL_ARGS[*]}")"
cbb_build_model_args "false" "haiku"
assert_eq "auto-inject aus" "0" "${#CBB_CLAUDE_MODEL_ARGS[@]}"
cbb_build_model_args "true" ""
assert_eq "auto-inject an ohne Engine" "0" "${#CBB_CLAUDE_MODEL_ARGS[@]}"
cbb_build_model_args "true" "haiku; rm -rf /" 2>/dev/null
assert_eq "Shell-Metazeichen werden abgelehnt" "0" "${#CBB_CLAUDE_MODEL_ARGS[@]}"
cbb_build_model_args "true" "--dangerously-skip-permissions" 2>/dev/null
assert_eq "Fremdes Flag als Engine abgelehnt" "0" "${#CBB_CLAUDE_MODEL_ARGS[@]}"

# --------------------------------------------------------------------------
# 4. Modus-Argumente
# --------------------------------------------------------------------------
echo
echo "== 4. Modus-Argumente =="
cbb_build_claude_args "plain" "${REPO_ROOT}" "/tmp/wiki"
assert_eq "plain ohne Zusatzflags" "0" "${#CBB_CLAUDE_ARGS[@]}"
cbb_build_claude_args "edit" "${REPO_ROOT}" "/tmp/wiki"
assert_eq "edit-Modus" "--permission-mode|acceptEdits|--add-dir|/tmp/wiki" \
  "$(IFS='|'; echo "${CBB_CLAUDE_ARGS[*]}")"
cbb_build_claude_args "quatsch" "${REPO_ROOT}" "/tmp/wiki"
assert_eq "unbekannter Modus -> rc 64" "64" "$?"

# --------------------------------------------------------------------------
# 5. Integration: echter Runner mit Stub-claude
# --------------------------------------------------------------------------
echo
echo "== 5. Integration (Stub-claude, kein echter Claude-Aufruf) =="

STUB_DIR="${TMP_ROOT}/bin"
mkdir -p -- "${STUB_DIR}"
cat > "${STUB_DIR}/claude" <<'STUB'
#!/usr/bin/env bash
# Stub statt Claude Code: schreibt das komplette argv NUL-separiert weg.
printf '%s\0' "$@" > "${CBB_TEST_ARGV_FILE}"
echo "STUB-CLAUDE OK"
exit 0
STUB
chmod 700 -- "${STUB_DIR}/claude"

start_runner() { # <auto-inject-wert>
  STATE_DIR="$(mktemp -d -t cbb-worker-state.XXXXXX)"
  chmod 700 -- "${STATE_DIR}"
  rm -f -- "${TMP_ROOT}/argv.bin"
  PATH="${STUB_DIR}:${PATH}" \
  CBB_TEST_ARGV_FILE="${TMP_ROOT}/argv.bin" \
  CBB_WORKER_STATE_DIR="${STATE_DIR}" \
  CBB_AUTO_INJECT_MODEL="$1" \
  CBB_AUTO_CONFIRM_WARNINGS="false" \
    bash "${WORKER_SCRIPT}" > "${TMP_ROOT}/runner.log" 2>&1 &
  RUNNER_PID=$!
  wait_for "${STATE_DIR}/ready" || { fail "Runner startet" "$(cat "${TMP_ROOT}/runner.log")"; return 1; }
  return 0
}

stop_runner() {
  [[ -n "${RUNNER_PID}" ]] || return 0
  kill "${RUNNER_PID}" 2>/dev/null
  wait "${RUNNER_PID}" 2>/dev/null
  RUNNER_PID=""
  rm -rf -- "${STATE_DIR}"
}

wait_for() { # <datei> [sekunden]
  local target="$1" limit="${2:-30}" waited=0
  while [[ ! -e "${target}" ]]; do
    sleep 0.2
    waited=$((waited + 1))
    [[ ${waited} -lt $((limit * 5)) ]] || return 1
  done
  return 0
}

submit_job() { # <prompt-datei> [modus]
  rm -f -- "${TMP_ROOT}/argv.bin" "${STATE_DIR}/latest.status"
  [[ $# -lt 2 ]] || printf '%s' "$2" > "${STATE_DIR}/job.mode"
  cp -- "$1" "${STATE_DIR}/job.tmp"
  mv -- "${STATE_DIR}/job.tmp" "${STATE_DIR}/job.prompt"
  wait_for "${STATE_DIR}/latest.status" \
    || fail "Job wurde nicht abgearbeitet ($1)" "$(tail -n 20 "${TMP_ROOT}/runner.log")"
}

# argv des letzten Stub-Aufrufs lesen. Wichtig: der Prompt enthaelt Zeilen-
# umbrueche, deshalb wird hier ueber Array-Slices verglichen und nicht mit cut.
argv_prefix() { # [anzahl] — ohne Angabe das komplette argv
  local -a captured=()
  [[ -e "${TMP_ROOT}/argv.bin" ]] || { printf '<kein claude-aufruf>'; return 0; }
  mapfile -d '' -t captured < "${TMP_ROOT}/argv.bin"
  local IFS='|'
  if [[ $# -eq 0 ]]; then
    printf '%s' "${captured[*]}"
  else
    printf '%s' "${captured[*]:0:$1}"
  fi
}

argv_joined() { argv_prefix; }

argv_last() {
  local -a captured=()
  [[ -e "${TMP_ROOT}/argv.bin" ]] || return 0
  mapfile -d '' -t captured < "${TMP_ROOT}/argv.bin"
  [[ ${#captured[@]} -gt 0 ]] || return 0
  printf '%s' "${captured[$((${#captured[@]} - 1))]}"
}

if start_runner "true"; then
  pass "Runner startet (auto_inject_model=true)"

  # 5.1 Prompt mit Frontmatter am Anfang.
  submit_job "${TMP_ROOT}/p-top.prompt"
  assert_eq "5.1 Exit-Code" "0" "$(<"${STATE_DIR}/latest.status")"
  assert_eq "5.1 argv" "--model|haiku|-p|--|---
agent: scout
---
Zaehle Produkte." "$(argv_joined)"
  assert_eq "5.1 chosen.agent" "agent: scout" "$(<"${STATE_DIR}/chosen.agent")"
  assert_eq "5.1 chosen.engine" "recommended_engine: haiku" "$(<"${STATE_DIR}/chosen.engine")"
  if grep -q 'unknown option' "${STATE_DIR}/latest.log"; then
    fail "5.1 keine Optionsfehlinterpretation" "$(<"${STATE_DIR}/latest.log")"
  else
    pass "5.1 keine Optionsfehlinterpretation"
  fi

  # 5.2 Frontmatter nach Vorspann (der real gemeldete Auftragstyp).
  submit_job "${TMP_ROOT}/p-preamble.prompt"
  assert_eq "5.2 code-auditor -> sonnet" "--model|sonnet" "$(argv_prefix 2)"
  assert_eq "5.2 Prompt unveraendert durchgereicht" \
    "$(printf 'Vorspann, weil ein Prompt nicht mit "---" beginnen darf.\n\n---\nagent: code-auditor\n---\nAuditiere.')" \
    "$(argv_last)"

  # 5.3 Kein Agent: kein --model, keine alten chosen-Dateien.
  submit_job "${TMP_ROOT}/p-none.prompt"
  assert_eq "5.3 kein Modellargument" "-p|--|Kein Frontmatter hier." "$(argv_joined)"
  if [[ -e "${STATE_DIR}/chosen.agent" || -e "${STATE_DIR}/chosen.engine" ]]; then
    fail "5.3 chosen-Dateien zurueckgesetzt" "Datei aus vorherigem Job lebt weiter"
  else
    pass "5.3 chosen-Dateien zurueckgesetzt"
  fi

  # 5.4 Unbekannter Agent: kein --model, keine Engine-Datei.
  submit_job "${TMP_ROOT}/p-unknown.prompt"
  assert_eq "5.4 unbekannter Agent ohne Modellargument" "-p|--" "$(argv_prefix 2)"
  assert_eq "5.4 chosen.agent gesetzt" "agent: frobnicator" "$(<"${STATE_DIR}/chosen.agent")"
  if [[ -e "${STATE_DIR}/chosen.engine" ]]; then
    fail "5.4 keine Engine-Datei" "chosen.engine existiert trotz unbekanntem Agent"
  else
    pass "5.4 keine Engine-Datei"
  fi

  # 5.5 Ungueltiger Agentname im Frontmatter.
  submit_job "${TMP_ROOT}/p-evil.prompt"
  assert_eq "5.5 kein Modellargument" "-p|--" "$(argv_prefix 2)"
  if [[ -e "${STATE_DIR}/chosen.agent" ]]; then
    fail "5.5 kein Agent uebernommen" "chosen.agent existiert"
  else
    pass "5.5 kein Agent uebernommen"
  fi

  # 5.6 pruefer -> opus, im edit-Modus.
  printf -- '---\nagent: pruefer\n---\nPruefe.\n' > "${TMP_ROOT}/p-pruefer.prompt"
  submit_job "${TMP_ROOT}/p-pruefer.prompt" "edit"
  assert_eq "5.6 pruefer -> opus + edit-Flags" \
    "--model|opus|--permission-mode|acceptEdits|--add-dir" "$(argv_prefix 5)"

  # 5.7 rechercheur -> sonnet, danach wieder plain (kein Modus-Rest).
  printf -- '---\nagent: rechercheur\n---\nRecherchiere.\n' > "${TMP_ROOT}/p-rech.prompt"
  submit_job "${TMP_ROOT}/p-rech.prompt"
  assert_eq "5.7 rechercheur -> sonnet, Modus zurueckgesetzt" \
    "--model|sonnet|-p|--" "$(argv_prefix 4)"

  # 5.8 Unbekannter Modus ruft claude gar nicht auf.
  submit_job "${TMP_ROOT}/p-top.prompt" "quatsch"
  assert_eq "5.8 Exit-Code 64" "64" "$(<"${STATE_DIR}/latest.status")"
  assert_eq "5.8 kein claude-Aufruf" "<kein claude-aufruf>" "$(argv_joined)"

  stop_runner
fi

if start_runner "false"; then
  pass "Runner startet (auto_inject_model=false)"
  submit_job "${TMP_ROOT}/p-top.prompt"
  assert_eq "5.9 env-Override unterdrueckt --model" "-p|--" "$(argv_prefix 2)"
  stop_runner
fi

echo
echo "============================================================"
echo "Bestanden: ${tests_passed}   Fehlgeschlagen: ${tests_failed}"
echo "============================================================"
[[ ${tests_failed} -eq 0 ]]
