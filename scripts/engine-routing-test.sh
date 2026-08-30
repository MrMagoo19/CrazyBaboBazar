#!/usr/bin/env bash

# Simple test harness for engine-routing detection logic.
# Usage: ./engine-routing-test.sh sample.prompt

set -euo pipefail

PROMPT_FILE="${1:-sample.prompt}"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTING_FILE="${REPO_ROOT}/.claude/agents/engine-routing.md"

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "PROMPT file not found: ${PROMPT_FILE}" >&2
  exit 2
fi

echo "Using routing file: ${ROUTING_FILE}"
echo
echo "--- Prompt head ---"
head -n 60 "${PROMPT_FILE}"
echo "--- /Prompt head ---"
echo

detect_agent_from_prompt() {
  head -c 2000 "${PROMPT_FILE}" | awk 'BEGIN{in=0} /^---/ { if(in==0){in=1; next} else {exit}} in==1{print}' | sed -n 's/^agent:[[:space:]]*\(.*\)$/\1/p' | tr -d '"\r'
}

chosen_agent="$(detect_agent_from_prompt || true)"
if [[ -z "${chosen_agent}" ]]; then
  echo "No agent found in prompt frontmatter.";
  exit 0
fi

echo "Detected agent: ${chosen_agent}"

recommended_engine=""
if [[ -f "${ROUTING_FILE}" ]]; then
  recommended_engine=$(awk -v a="${chosen_agent}" '
    BEGIN{found=0}
    $0~("^\\s*"a":") {found=1}
    found && $0~"recommended_engine:" {gsub(/^[ \t]*recommended_engine:[ \t]*/,"",$0); print $0; exit}
  ' "${ROUTING_FILE}")
fi

if [[ -n "${recommended_engine}" ]]; then
  echo "Recommended engine from routing: ${recommended_engine}"
else
  echo "No recommended engine found for agent ${chosen_agent}."
fi

echo
echo "Simulated claude invocation:"
if [[ -n "${recommended_engine}" ]]; then
  echo "claude --model ${recommended_engine} -p <prompt>"
else
  echo "claude -p <prompt>"
fi

exit 0
