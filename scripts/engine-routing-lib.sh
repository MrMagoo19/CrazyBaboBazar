#!/usr/bin/env bash
# shellcheck shell=bash
#
# Gemeinsame Engine-Routing-Logik fuer den CLAUDE WORKER.
#
# Diese Datei wird von scripts/claude-worker-terminal.sh (Runner) und
# scripts/engine-routing-test.sh (Test-Harness) gesourct. Beide benutzen damit
# exakt dieselbe Parsing-, Lookup- und Argumentbau-Semantik; der Test prueft
# also den echten Codepfad des Runners und keine Nachbildung.
#
# Nur Funktionen und Konstanten definieren — keine Seiteneffekte beim Sourcen.

# Agentennamen und Modell-Aliasse sind bewusst eng validiert. Alles, was aus
# einem Prompt oder einer Datei stammt, wird gegen diese Muster geprueft, bevor
# es in eine Kommandozeile gelangt.
if [[ -z "${CBB_AGENT_NAME_PATTERN:-}" ]]; then
  readonly CBB_AGENT_NAME_PATTERN='^[a-z][a-z0-9_-]{0,31}$'
  readonly CBB_ENGINE_NAME_PATTERN='^[a-z][a-z0-9._-]{0,63}$'
fi

# cbb_config_value <config-file> <key>
# Liest einen flachen "key: value"-Eintrag aus der Worker-Config. Bewusst ohne
# PyYAML/python3: die Config ist flach, und eine fehlende Python-Abhaengigkeit
# darf nicht stillschweigend zu anderen Defaults fuehren.
cbb_config_value() {
  local config_file="$1" key="$2"
  [[ -f "${config_file}" ]] || return 0
  sed -n "s/^[[:space:]]*${key}[[:space:]]*:[[:space:]]*//p" -- "${config_file}" \
    | head -n 1 \
    | tr -d '"'"'"'\r' \
    | sed 's/[[:space:]]*$//'
}

# cbb_is_true <value>
cbb_is_true() {
  case "${1:-}" in
    true | True | TRUE | yes | Yes | YES | 1) return 0 ;;
    *) return 1 ;;
  esac
}

# cbb_detect_agent_from_prompt <prompt-file>
# Liest den ersten YAML-Frontmatter-Block (auch wenn ihm Fliesstext vorausgeht)
# und gibt den Wert von "agent:" aus. Ungueltige Namen werden verworfen und auf
# stderr gemeldet — sie erreichen niemals eine Kommandozeile.
cbb_detect_agent_from_prompt() {
  local prompt_file="$1" raw
  [[ -f "${prompt_file}" ]] || return 0

  raw="$(sed -n '1,400p' -- "${prompt_file}" \
    | sed -n '/^---[[:space:]]*$/,/^---[[:space:]]*$/p' \
    | sed -n 's/^agent:[[:space:]]*//p' \
    | head -n 1 \
    | tr -d '"'"'"'\r' \
    | sed 's/[[:space:]]*$//')"

  [[ -n "${raw}" ]] || return 0

  if [[ ! "${raw}" =~ ${CBB_AGENT_NAME_PATTERN} ]]; then
    echo "WARNUNG: Agent-Name im Prompt ist ungueltig und wird ignoriert." >&2
    return 0
  fi

  printf '%s\n' "${raw}"
}

# cbb_allowed_engines <routing-file>
# Die Allowlist der Modell-Aliasse ist ausschliesslich die Menge der in der
# Routingdatei hinterlegten recommended_engine-Werte.
cbb_allowed_engines() {
  local routing_file="$1"
  [[ -f "${routing_file}" ]] || return 0
  sed -n 's/^[[:space:]]*recommended_engine[[:space:]]*:[[:space:]]*//p' -- "${routing_file}" \
    | tr -d '"'"'"'\r' \
    | sed 's/[[:space:]]*$//' \
    | sort -u
}

# cbb_lookup_recommended_engine <routing-file> <agent>
# Sucht den recommended_engine-Wert im Block des Agenten. Portables awk (kein
# "\s"), der Agentenname wird via -v uebergeben und ist vorher validiert.
cbb_lookup_recommended_engine() {
  local routing_file="$1" agent="$2" engine allowed

  [[ -f "${routing_file}" ]] || return 0
  [[ "${agent}" =~ ${CBB_AGENT_NAME_PATTERN} ]] || return 0

  engine="$(awk -v a="${agent}" '
    { line = $0; sub(/\r$/, "", line) }
    !found && line ~ ("^[ \t]+" a "[ \t]*:[ \t]*$") { found = 1; next }
    found {
      if (line ~ /^[ \t]*recommended_engine[ \t]*:/) {
        sub(/^[ \t]*recommended_engine[ \t]*:[ \t]*/, "", line)
        sub(/[ \t]*$/, "", line)
        gsub(/"/, "", line)
        print line
        exit
      }
      # Naechster Block oder linke Spalte erreicht: Agentenblock ist zu Ende.
      if (line ~ /^[^ \t]/) { exit }
      if (line ~ /^[ \t]*[A-Za-z][A-Za-z0-9_-]*[ \t]*:[ \t]*$/) { exit }
    }
  ' "${routing_file}")"

  engine="$(printf '%s' "${engine}" | tr -d "'")"
  [[ -n "${engine}" ]] || return 0

  if [[ ! "${engine}" =~ ${CBB_ENGINE_NAME_PATTERN} ]]; then
    echo "WARNUNG: recommended_engine fuer '${agent}' hat ein unzulaessiges Format und wird ignoriert." >&2
    return 0
  fi

  # Zweite Schranke: nur Aliasse, die in der Routingdatei tatsaechlich als
  # recommended_engine stehen, duerfen weiterverwendet werden.
  while IFS= read -r allowed; do
    if [[ "${engine}" == "${allowed}" ]]; then
      printf '%s\n' "${engine}"
      return 0
    fi
  done < <(cbb_allowed_engines "${routing_file}")

  echo "WARNUNG: Engine '${engine}' steht nicht auf der Allowlist der Routingdatei." >&2
  return 0
}

# cbb_build_model_args <auto-inject> [engine]
# Setzt das Array CBB_CLAUDE_MODEL_ARGS — leer oder genau (--model <alias>).
# Immer aufrufen, auch ohne Agent: so kann kein Wert aus einem frueheren Job
# ueberleben, und unter "set -u" ist die Variable stets definiert.
cbb_build_model_args() {
  local auto_inject="${1:-false}" engine="${2:-}"
  CBB_CLAUDE_MODEL_ARGS=()

  cbb_is_true "${auto_inject}" || return 0
  [[ -n "${engine}" ]] || return 0

  if [[ ! "${engine}" =~ ${CBB_ENGINE_NAME_PATTERN} ]]; then
    echo "WARNUNG: Engine '${engine}' wird nicht injiziert (unzulaessiges Format)." >&2
    return 0
  fi

  CBB_CLAUDE_MODEL_ARGS=(--model "${engine}")
}

# cbb_build_claude_args <mode> <repo-root> <moneywiki-root>
# Setzt das Array CBB_CLAUDE_ARGS mit den modusabhaengigen Claude-Flags.
# Der Prompt gehoert NICHT hierher: er wird vom Aufrufer immer als
#   claude "${CBB_CLAUDE_MODEL_ARGS[@]}" "${CBB_CLAUDE_ARGS[@]}" -p -- "<prompt>"
# uebergeben. Das "--" beendet die Optionsauswertung, damit ein Prompt, der mit
# "---" (YAML-Frontmatter) beginnt, nie als CLI-Option gelesen wird.
# Rueckgabe 64 bei unbekanntem Modus.
cbb_build_claude_args() {
  local mode="$1" repo_root="$2" moneywiki_root="$3"
  CBB_CLAUDE_ARGS=()

  case "${mode}" in
    plain)
      CBB_CLAUDE_ARGS=()
      ;;
    chrome)
      CBB_CLAUDE_ARGS=(
        --chrome
        --add-dir "${repo_root}"
        --allowedTools 'mcp__claude-in-chrome__*'
      )
      ;;
    chrome_resume)
      # Die Chrome-Tab-Gruppe ist an die benannte interaktive Sitzung gebunden.
      # Durch Resume bleibt die bereits sichtbar erteilte Browserfreigabe
      # erhalten, statt fuer jeden Print-Auftrag eine neue Sitzung anzulegen.
      CBB_CLAUDE_ARGS=(
        --chrome
        --resume "CLAUDE WORKER"
        --add-dir "${repo_root}"
        --allowedTools 'mcp__claude-in-chrome__*'
      )
      ;;
    edit)
      # Lokale Datei-Edits fuer explizit abgegrenzte Implementierungsauftraege
      # automatisch erlauben. Bash, Netzwerk und externe Aktionen behalten
      # ihre normalen Claude-Berechtigungsgrenzen.
      CBB_CLAUDE_ARGS=(
        --permission-mode acceptEdits
        --add-dir "${moneywiki_root}"
      )
      ;;
    supabase_read)
      # Direkter, projektgebundener Supabase-MCP: nur die serverseitig
      # gelieferte Projekt-URL darf ohne Rueckfrage gelesen werden. Schreibende
      # Supabase-Tools bleiben fuer diesen Auftrag explizit gesperrt.
      CBB_CLAUDE_ARGS=(
        --permission-mode dontAsk
        --allowedTools 'mcp__supabase__get_project_url'
        --disallowedTools 'mcp__supabase__execute_sql,mcp__supabase__apply_migration,mcp__supabase__create_branch,mcp__supabase__deploy_edge_function,mcp__supabase__update_storage_config'
      )
      ;;
    supabase_write)
      # Nur fuer einen einzeln freigegebenen Production-Schritt. Die Erlaubnis
      # gilt ausschliesslich fuer diesen Claude-Prozess und wird nach dessen
      # Ende nicht gespeichert. Alle anderen schreibenden Supabase-Tools sind
      # explizit gesperrt.
      CBB_CLAUDE_ARGS=(
        --permission-mode dontAsk
        --allowedTools 'Read,mcp__supabase__get_project_url,mcp__supabase__execute_sql'
        --disallowedTools 'mcp__supabase__apply_migration,mcp__supabase__create_branch,mcp__supabase__deploy_edge_function,mcp__supabase__update_storage_config'
      )
      ;;
    *)
      return 64
      ;;
  esac

  return 0
}
