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
  # extract YAML frontmatter between the first pair of '---' lines and look for agent:
  sed -n '1,2000p' "${PROMPT_FILE}" | sed -n '/^---$/,/^---$/p' | sed -n 's/^agent:[[:space:]]*//p' | tr -d '"\r'
}

chosen_agent="$(detect_agent_from_prompt || true)"
if [[ -z "${chosen_agent}" ]]; then
  echo "No agent found in prompt frontmatter.";
  exit 0
fi

echo "Detected agent: ${chosen_agent}"

recommended_engine=""
if [[ -f "${ROUTING_FILE}" ]]; then
  # Use python to robustly parse the small YAML-like mapping
  recommended_engine=$(python3 - <<PY
import re,sys
f=open('${ROUTING_FILE}','r')
lines=f.readlines()
f.close()
agent='''${chosen_agent}'''
found=False
for i,l in enumerate(lines):
    if re.match(r'^\s*'+re.escape(agent)+r'\s*:\s*$', l):
        found=True
        for j in range(i+1, len(lines)):
            m=re.match(r'^\s*recommended_engine\s*:\s*(\S+)', lines[j])
            if m:
                print(m.group(1))
                sys.exit(0)
            if re.match(r'^\S', lines[j]):
                break
        break
sys.exit(0)
PY
)
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
