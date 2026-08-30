#!/usr/bin/env bash

set -u
set -o pipefail

readonly CBB_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CBB_MONEYWIKI_ROOT="/home/batman/Schreibtisch/Obsidian/Money WiKi"
readonly CBB_WORKER_STATE_DIR="/tmp/crazybabobazar-claude-worker"
readonly CBB_READY_FILE="${CBB_WORKER_STATE_DIR}/ready"
readonly CBB_JOB_FILE="${CBB_WORKER_STATE_DIR}/job.prompt"
readonly CBB_MODE_FILE="${CBB_WORKER_STATE_DIR}/job.mode"
readonly CBB_RUNNING_FILE="${CBB_WORKER_STATE_DIR}/running.prompt"
readonly CBB_LATEST_PROMPT="${CBB_WORKER_STATE_DIR}/latest.prompt"
readonly CBB_LATEST_LOG="${CBB_WORKER_STATE_DIR}/latest.log"
readonly CBB_LATEST_STATUS="${CBB_WORKER_STATE_DIR}/latest.status"

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

# --- Engine / Para Memory validation (prevent accidental engine switches) ---
ENG_ROUTING_FILE="${CBB_REPO_ROOT}/.claude/agents/engine-routing.md"
AGENTS_POLICY_FILE="${CBB_REPO_ROOT}/AGENTS.md"

validate_engine_files() {
  warn=0

  if [[ ! -f "${ENG_ROUTING_FILE}" ]]; then
    echo "WARNUNG: ${ENG_ROUTING_FILE} fehlt. Worker hat keine Engine-Routing-Referenz."
    warn=1
  else
    # einfache Plausibilitätsprüfung: wichtige Stichworte vorhanden?
    if ! grep -Ei 'agents:|para_memory:|recommended_engine' "${ENG_ROUTING_FILE}" >/dev/null 2>&1; then
      echo "WARNUNG: ${ENG_ROUTING_FILE} scheint keine erwarteten Schlüssel zu enthalten."
      warn=1
    fi
  fi

  if [[ ! -f "${AGENTS_POLICY_FILE}" ]]; then
    echo "WARNUNG: ${AGENTS_POLICY_FILE} fehlt. Projekt-Policy nicht auffindbar."
    warn=1
  else
    if ! grep -Ei 'PARA MEMORY|Engine-Auto-Selection|Para Memory' "${AGENTS_POLICY_FILE}" >/dev/null 2>&1; then
      echo "WARNUNG: ${AGENTS_POLICY_FILE} enthält keine sichtbare PARA MEMORY/Engine-Auto-Selection-Sektion."
      warn=1
    fi
  fi

  if [[ ${warn} -ne 0 ]]; then
    echo
    read -p "Weiter ausführen trotz Warnungen? (y/N) " answer
    case "${answer}" in
      [yY])
        echo "Fortsetzen auf Benutzerwunsch." ;;
      *)
        echo "CLAUDE WORKER abgebrochen: Bitte Policy/Config prüfen." ; exit 1 ;;
    esac
  fi
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
echo "Status: bereit; Codex darf jetzt einen geprüften Auftrag senden."
echo "Terminal geöffnet lassen. Mit Ctrl+C wird der Runner beendet."
echo "============================================================"

while true; do
  if [[ -s "${CBB_JOB_FILE}" && ! -e "${CBB_RUNNING_FILE}" ]]; then
    mv -- "${CBB_JOB_FILE}" "${CBB_RUNNING_FILE}"
    rm -f -- "${CBB_LATEST_STATUS}"

    worker_mode="plain"
    if [[ -s "${CBB_MODE_FILE}" ]]; then
      worker_mode="$(<"${CBB_MODE_FILE}")"
      mv -- "${CBB_MODE_FILE}" "${CBB_WORKER_STATE_DIR}/latest.mode"
    fi

    # Auto-detect agent from YAML frontmatter in the prompt (optional)
    detect_agent_from_prompt() {
      # read first 2000 chars to be safe
      head -c 2000 "${CBB_RUNNING_FILE}" | awk 'BEGIN{in=0} /^---/ { if(in==0){in=1; next} else {exit}} in==1{print}' | sed -n 's/^agent:[[:space:]]*\(.*\)$/\1/p' | tr -d '"\r'
    }

    chosen_agent="$(detect_agent_from_prompt || true)"
    if [[ -n "${chosen_agent}" ]]; then
      # record choice and attempt a lookup of recommended_engine from engine-routing.md
      echo "agent: ${chosen_agent}" > "${CBB_WORKER_STATE_DIR}/chosen.agent"
      ROUTING_FILE="${CBB_REPO_ROOT}/.claude/agents/engine-routing.md"
      recommended_engine=""
      if [[ -f "${ROUTING_FILE}" ]]; then
        # crude parsing: find the agent block and extract recommended_engine
        recommended_engine=$(awk -v a="${chosen_agent}" '
          BEGIN{found=0}
          $0~("^\\s*"a":") {found=1}
          found && $0~"recommended_engine:" {gsub(/^[ \t]*recommended_engine:[ \t]*/,"",$0); print $0; exit}
        ' "${ROUTING_FILE}")
      fi
      if [[ -n "${recommended_engine}" ]]; then
        echo "recommended_engine: ${recommended_engine}" > "${CBB_WORKER_STATE_DIR}/chosen.engine"
      fi
      # append to engine decision log
      printf '%s %s %s\n' "$(date --iso-8601=seconds)" "agent=${chosen_agent}" "engine=${recommended_engine:-unknown}" >> "${CBB_WORKER_STATE_DIR}/engine.log"

      # If claude supports a --model flag, pass recommended_engine to claude
      CLAUDE_MODEL_ARG=""
      if [[ -n "${recommended_engine}" ]]; then
        CLAUDE_MODEL_ARG="--model ${recommended_engine}"
      fi
    fi

    worker_prompt="$(<"${CBB_RUNNING_FILE}")"
    cp -- "${CBB_RUNNING_FILE}" "${CBB_LATEST_PROMPT}"

    echo
    echo "---------------- CLAUDE-AUFTRAG ----------------"
    echo "Modus: ${worker_mode}"
    printf '%s\n' "${worker_prompt}"
    echo "---------------- CLAUDE-AUSGABE ----------------"

    if [[ "${worker_mode}" == "chrome" ]]; then
      claude ${CLAUDE_MODEL_ARG} --chrome \
        --add-dir "${CBB_REPO_ROOT}" \
        --allowedTools 'mcp__claude-in-chrome__*' \
        -p "${worker_prompt}" 2>&1 | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    elif [[ "${worker_mode}" == "chrome_resume" ]]; then
      # Die Chrome-Tab-Gruppe ist an die benannte interaktive Sitzung gebunden.
      # Durch Resume bleibt die bereits sichtbar erteilte Browserfreigabe
      # erhalten, statt fuer jeden Print-Auftrag eine neue Sitzung anzulegen.
      claude ${CLAUDE_MODEL_ARG} --chrome --resume "CLAUDE WORKER" \
        --add-dir "${CBB_REPO_ROOT}" \
        --allowedTools 'mcp__claude-in-chrome__*' \
        -p "${worker_prompt}" 2>&1 \
        | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    elif [[ "${worker_mode}" == "edit" ]]; then
      # Lokale Datei-Edits fuer explizit abgegrenzte Implementierungsauftraege
      # automatisch erlauben. Bash, Netzwerk und externe Aktionen behalten
      # ihre normalen Claude-Berechtigungsgrenzen.
      claude ${CLAUDE_MODEL_ARG} --permission-mode acceptEdits \
        --add-dir "${CBB_MONEYWIKI_ROOT}" \
        -p "${worker_prompt}" 2>&1 \
        | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    elif [[ "${worker_mode}" == "supabase_read" ]]; then
      # Direkter, projektgebundener Supabase-MCP: nur die serverseitig
      # gelieferte Projekt-URL darf ohne Rueckfrage gelesen werden. Schreibende
      # Supabase-Tools bleiben fuer diesen Auftrag explizit gesperrt.
      claude ${CLAUDE_MODEL_ARG} --permission-mode dontAsk \
        --allowedTools 'mcp__supabase__get_project_url' \
        --disallowedTools 'mcp__supabase__execute_sql,mcp__supabase__apply_migration,mcp__supabase__create_branch,mcp__supabase__deploy_edge_function,mcp__supabase__update_storage_config' \
        -p "${worker_prompt}" 2>&1 \
        | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    elif [[ "${worker_mode}" == "supabase_write" ]]; then
      # Nur fuer einen einzeln freigegebenen Production-Schritt. Die Erlaubnis
      # gilt ausschliesslich fuer diesen Claude-Prozess und wird nach dessen
      # Ende nicht gespeichert. Alle anderen schreibenden Supabase-Tools sind
      # explizit gesperrt.
      claude ${CLAUDE_MODEL_ARG} --permission-mode dontAsk \
        --allowedTools 'Read,mcp__supabase__get_project_url,mcp__supabase__execute_sql' \
        --disallowedTools 'mcp__supabase__apply_migration,mcp__supabase__create_branch,mcp__supabase__deploy_edge_function,mcp__supabase__update_storage_config' \
        -p "${worker_prompt}" 2>&1 \
        | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    elif [[ "${worker_mode}" == "plain" ]]; then
      claude ${CLAUDE_MODEL_ARG} -p "${worker_prompt}" 2>&1 | tee "${CBB_LATEST_LOG}"
      worker_status="${PIPESTATUS[0]}"
    else
      echo "CLAUDE WORKER abgebrochen: unbekannter Modus '${worker_mode}'." \
        | tee "${CBB_LATEST_LOG}"
      worker_status=64
    fi

    printf '%s\n' "${worker_status}" > "${CBB_LATEST_STATUS}"
    mv -- "${CBB_RUNNING_FILE}" "${CBB_WORKER_STATE_DIR}/completed.prompt"

    echo "---------------- WORKER BEENDET ----------------"
    echo "Exit-Code: ${worker_status}"
    echo "Status: bereit für den nächsten Auftrag."
  fi

  sleep 1
done
