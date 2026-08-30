#!/usr/bin/env bash

set -u
set -o pipefail

readonly CBB_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CBB_MONEYWIKI_ROOT="/home/batman/Schreibtisch/Obsidian/Money WiKi"
# Der State-Pfad ist ueberschreibbar, damit der Test-Harness den Runner in einem
# Wegwerf-Verzeichnis starten kann. Ohne Override bleibt der bisherige Pfad.
readonly CBB_WORKER_STATE_DIR="${CBB_WORKER_STATE_DIR:-/tmp/crazybabobazar-claude-worker}"
readonly CBB_READY_FILE="${CBB_WORKER_STATE_DIR}/ready"
readonly CBB_JOB_FILE="${CBB_WORKER_STATE_DIR}/job.prompt"
readonly CBB_MODE_FILE="${CBB_WORKER_STATE_DIR}/job.mode"
readonly CBB_RUNNING_FILE="${CBB_WORKER_STATE_DIR}/running.prompt"
readonly CBB_LATEST_PROMPT="${CBB_WORKER_STATE_DIR}/latest.prompt"
readonly CBB_LATEST_LOG="${CBB_WORKER_STATE_DIR}/latest.log"
readonly CBB_LATEST_STATUS="${CBB_WORKER_STATE_DIR}/latest.status"
readonly CBB_CHOSEN_AGENT_FILE="${CBB_WORKER_STATE_DIR}/chosen.agent"
readonly CBB_CHOSEN_ENGINE_FILE="${CBB_WORKER_STATE_DIR}/chosen.engine"
readonly CBB_WORKER_CONFIG_FILE="${CBB_REPO_ROOT}/.claude/worker-config.yaml"
readonly CBB_ROUTING_FILE="${CBB_REPO_ROOT}/.claude/agents/engine-routing.md"
readonly CBB_AGENTS_POLICY_FILE="${CBB_REPO_ROOT}/AGENTS.md"
readonly CBB_ROUTING_LIB="${CBB_REPO_ROOT}/scripts/engine-routing-lib.sh"

if [[ ! -f "${CBB_ROUTING_LIB}" ]]; then
  echo "CLAUDE WORKER abgebrochen: ${CBB_ROUTING_LIB} fehlt."
  exit 1
fi
# shellcheck source=scripts/engine-routing-lib.sh
source "${CBB_ROUTING_LIB}"

if [[ -L "${CBB_WORKER_STATE_DIR}" ]]; then
  echo "CLAUDE WORKER abgebrochen: State-Pfad darf kein Symlink sein."
  exit 1
fi

mkdir -p -m 700 -- "${CBB_WORKER_STATE_DIR}"

if [[ -L "${CBB_WORKER_STATE_DIR}" ]]; then
  echo "CLAUDE WORKER abgebrochen: State-Pfad wurde als Symlink angelegt."
  exit 1
fi

chmod 700 -- "${CBB_WORKER_STATE_DIR}"

if [[ ! -O "${CBB_WORKER_STATE_DIR}" ]]; then
  echo "CLAUDE WORKER abgebrochen: State-Verzeichnis gehoert einem anderen Benutzer."
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "CLAUDE WORKER abgebrochen: Claude Code wurde nicht gefunden."
  exit 1
fi

# --- Repo-Config laden -------------------------------------------------------
# Muss VOR der Validierung passieren, sonst kann auto_confirm_warnings beim
# Start nicht wirken. Env-Variablen haben Vorrang vor der Datei.
cbb_auto_inject_model="${CBB_AUTO_INJECT_MODEL:-}"
if [[ -z "${cbb_auto_inject_model}" ]]; then
  # Default true: AGENTS.md §14 verlangt automatische Profilwahl. Sicher ist das,
  # weil nur Aliasse aus .claude/agents/engine-routing.md injiziert werden.
  cbb_auto_inject_model="$(cbb_config_value "${CBB_WORKER_CONFIG_FILE}" 'auto_inject_model')"
  [[ -n "${cbb_auto_inject_model}" ]] || cbb_auto_inject_model="true"
fi

cbb_auto_confirm_warnings="${CBB_AUTO_CONFIRM_WARNINGS:-}"
if [[ -z "${cbb_auto_confirm_warnings}" ]]; then
  cbb_auto_confirm_warnings="$(cbb_config_value "${CBB_WORKER_CONFIG_FILE}" 'auto_confirm_warnings')"
  [[ -n "${cbb_auto_confirm_warnings}" ]] || cbb_auto_confirm_warnings="false"
fi

cbb_engine_log_path="$(cbb_config_value "${CBB_WORKER_CONFIG_FILE}" 'engine_log_path')"
if [[ -z "${cbb_engine_log_path}" ]]; then
  cbb_engine_log_path="${CBB_WORKER_STATE_DIR}/engine.log"
fi
if [[ -L "${cbb_engine_log_path}" ]]; then
  echo "WARNUNG: engine_log_path ist ein Symlink; nutze Standardpfad im State-Verzeichnis."
  cbb_engine_log_path="${CBB_WORKER_STATE_DIR}/engine.log"
fi
mkdir -p -- "$(dirname -- "${cbb_engine_log_path}")" 2>/dev/null || true

readonly CBB_AUTO_INJECT_MODEL="${cbb_auto_inject_model}"
readonly CBB_AUTO_CONFIRM_WARNINGS="${cbb_auto_confirm_warnings}"
readonly CBB_ENGINE_LOG_PATH="${cbb_engine_log_path}"

# --- Engine / Para Memory validation (prevent accidental engine switches) ---
validate_engine_files() {
  local warn=0 answer=""

  if [[ ! -f "${CBB_ROUTING_FILE}" ]]; then
    echo "WARNUNG: ${CBB_ROUTING_FILE} fehlt. Worker hat keine Engine-Routing-Referenz."
    warn=1
  else
    # einfache Plausibilitätsprüfung: wichtige Stichworte vorhanden?
    if ! grep -Ei 'agents:|para_memory:|recommended_engine' "${CBB_ROUTING_FILE}" >/dev/null 2>&1; then
      echo "WARNUNG: ${CBB_ROUTING_FILE} scheint keine erwarteten Schlüssel zu enthalten."
      warn=1
    fi
  fi

  if [[ ! -f "${CBB_AGENTS_POLICY_FILE}" ]]; then
    echo "WARNUNG: ${CBB_AGENTS_POLICY_FILE} fehlt. Projekt-Policy nicht auffindbar."
    warn=1
  else
    if ! grep -Ei 'PARA MEMORY|Engine-Auto-Selection|Para Memory' "${CBB_AGENTS_POLICY_FILE}" >/dev/null 2>&1; then
      echo "WARNUNG: ${CBB_AGENTS_POLICY_FILE} enthält keine sichtbare PARA MEMORY/Engine-Auto-Selection-Sektion."
      warn=1
    fi
  fi

  if [[ ${warn} -eq 0 ]]; then
    return 0
  fi

  echo
  if cbb_is_true "${CBB_AUTO_CONFIRM_WARNINGS}"; then
    echo "Fortsetzen: auto_confirm_warnings ist aktiv."
    return 0
  fi

  # Ohne Terminal gibt es keine stillschweigende Fortsetzung.
  if [[ ! -t 0 ]]; then
    echo "CLAUDE WORKER abgebrochen: Policy-Warnungen ohne interaktive Bestätigung."
    exit 1
  fi

  read -r -p "Weiter ausführen trotz Warnungen? (y/N) " answer
  case "${answer}" in
    [yY])
      echo "Fortsetzen auf Benutzerwunsch." ;;
    *)
      echo "CLAUDE WORKER abgebrochen: Bitte Policy/Config prüfen." ; exit 1 ;;
  esac
}

# Führe die Validierung einmal beim Start aus
validate_engine_files

# Im sichtbaren VS-Code-Terminal den vereinbarten Namen setzen. Die Escape-
# Sequenz wirkt nur bei interaktiver Terminalausgabe; Logs bleiben unveraendert.
if [[ -t 1 ]]; then
  printf '\033]0;CLAUDE WORKER\007'
fi

cleanup() {
  rm -f -- "${CBB_READY_FILE}"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'ready\n' > "${CBB_READY_FILE}"

echo "============================================================"
echo "CLAUDE WORKER — sichtbarer CrazyBaboBazar-Worker"
echo "Repo: ${CBB_REPO_ROOT}"
echo "Auto-Engine: ${CBB_AUTO_INJECT_MODEL} (Allowlist: $(cbb_allowed_engines "${CBB_ROUTING_FILE}" | tr '\n' ' '))"
if ! cbb_is_true "${CBB_AUTO_INJECT_MODEL}"; then
  echo "HINWEIS: Automatische Engine-Wahl ist AUS. AGENTS.md §14 verlangt sie —"
  echo "         setze auto_inject_model: true in .claude/worker-config.yaml"
  echo "         oder starte mit CBB_AUTO_INJECT_MODEL=true."
fi
echo "Status: bereit; Codex darf jetzt einen geprüften Auftrag senden."
echo "Terminal geöffnet lassen. Mit Ctrl+C wird der Runner beendet."
echo "============================================================"

while true; do
  if [[ -s "${CBB_JOB_FILE}" && ! -e "${CBB_RUNNING_FILE}" ]]; then
    mv -- "${CBB_JOB_FILE}" "${CBB_RUNNING_FILE}"
    rm -f -- "${CBB_LATEST_STATUS}"

    # Pro Job zuruecksetzen: keine Datei und kein Wert aus einem frueheren Job
    # darf in diesen Job hineinwirken.
    rm -f -- "${CBB_CHOSEN_AGENT_FILE}" "${CBB_CHOSEN_ENGINE_FILE}"
    chosen_agent=""
    recommended_engine=""
    CBB_CLAUDE_MODEL_ARGS=()
    CBB_CLAUDE_ARGS=()

    worker_mode="plain"
    if [[ -s "${CBB_MODE_FILE}" ]]; then
      worker_mode="$(<"${CBB_MODE_FILE}")"
      mv -- "${CBB_MODE_FILE}" "${CBB_WORKER_STATE_DIR}/latest.mode"
    fi

    # Agent aus dem YAML-Frontmatter des Prompts lesen (optional) und die
    # empfohlene Engine in der Routingdatei nachschlagen.
    chosen_agent="$(cbb_detect_agent_from_prompt "${CBB_RUNNING_FILE}")"
    if [[ -n "${chosen_agent}" ]]; then
      printf 'agent: %s\n' "${chosen_agent}" > "${CBB_CHOSEN_AGENT_FILE}"
      recommended_engine="$(cbb_lookup_recommended_engine "${CBB_ROUTING_FILE}" "${chosen_agent}")"
      if [[ -n "${recommended_engine}" ]]; then
        printf 'recommended_engine: %s\n' "${recommended_engine}" > "${CBB_CHOSEN_ENGINE_FILE}"
      fi
    fi

    # Modellargument immer neu bauen — auch ohne Agent. Danach ist das Array
    # garantiert definiert (set -u) und enthaelt nie einen alten Wert.
    cbb_build_model_args "${CBB_AUTO_INJECT_MODEL}" "${recommended_engine}"

    printf '%s agent=%s engine=%s injected=%s\n' \
      "$(date --iso-8601=seconds)" \
      "${chosen_agent:-none}" \
      "${recommended_engine:-unknown}" \
      "$([[ ${#CBB_CLAUDE_MODEL_ARGS[@]} -gt 0 ]] && echo yes || echo no)" \
      >> "${CBB_ENGINE_LOG_PATH}"

    worker_prompt="$(<"${CBB_RUNNING_FILE}")"
    cp -- "${CBB_RUNNING_FILE}" "${CBB_LATEST_PROMPT}"

    echo
    echo "---------------- CLAUDE-AUFTRAG ----------------"
    echo "Modus: ${worker_mode}"
    echo "Agent: ${chosen_agent:-none} | Engine: ${recommended_engine:-default}"
    printf '%s\n' "${worker_prompt}"
    echo "---------------- CLAUDE-AUSGABE ----------------"

    if ! cbb_build_claude_args "${worker_mode}" "${CBB_REPO_ROOT}" "${CBB_MONEYWIKI_ROOT}"; then
      echo "CLAUDE WORKER abgebrochen: unbekannter Modus '${worker_mode}'." \
        | tee "${CBB_LATEST_LOG}"
      worker_status=64
    else
      # "-p --" ist Pflicht: ohne den Optionsabschluss liest die CLI einen
      # Prompt, der mit "---" (YAML-Frontmatter) beginnt, als Option.
      claude \
        ${CBB_CLAUDE_MODEL_ARGS[@]+"${CBB_CLAUDE_MODEL_ARGS[@]}"} \
        ${CBB_CLAUDE_ARGS[@]+"${CBB_CLAUDE_ARGS[@]}"} \
        -p -- "${worker_prompt}" 2>&1 \
        | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    fi

    printf '%s\n' "${worker_status}" > "${CBB_LATEST_STATUS}"
    mv -- "${CBB_RUNNING_FILE}" "${CBB_WORKER_STATE_DIR}/completed.prompt"

    echo "---------------- WORKER BEENDET ----------------"
    echo "Exit-Code: ${worker_status}"
    echo "Status: bereit für den nächsten Auftrag."
  fi

  sleep 1
done
