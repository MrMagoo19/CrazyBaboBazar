# Engine routing (machine-readable guidance)

# Zweck: Diese Datei gibt eine kompakte Mapping-Referenz, die Worker/Subagenten
# beim automatischen Auswahlentscheid konsultieren sollen.

# Format: YAML-ähnlich (lesbar). Worker sollten diese Datei parsen oder als
# Referenz für Implementierung nutzen.

agents:
  scout:
    recommended_engine: haiku
    use_when: "Fakten: Dateien finden, counts, HTTP-Status, Seitengrößen, einfache SQL-Reads"
    cost_profile: low

  rechercheur:
    recommended_engine: sonnet
    use_when: "Externe Recherche mit Quellenprüfung; Belegstufe notwendig"
    cost_profile: medium

  code-auditor:
    recommended_engine: sonnet
    use_when: "Code-Befunde mit Datei:Zeile, Impact-Analyse"
    cost_profile: high

  texter:
    recommended_engine: sonnet
    use_when: "Veröffentlichungstexte, Voice-Bible-konforme Outputs"
    cost_profile: high

  pruefer:
    recommended_engine: opus
    use_when: "Gegnerische Endprüfung, kritische Freigaben"
    cost_profile: max

# Para Memory usage guidance (Kurzform)
para_memory:
  allowed_for:
    - "Large research / strategy tasks"
    - "When historical project context is materially necessary"
  forbidden_for:
    - "simple UI edits"
    - "CSS changes"
    - "component-level fixes"
    - "lint / typecheck / builds / tests"
    - "local refactors / obvious bug fixes"
    - "tasks already fully described in the current chat/task"
  prechecks:
    - "Check AGENTS.md"
    - "Check relevant repo files"
    - "Use already-loaded context"
    - "Only then call Para Memory"

# Hinweis für Implementierung/Automation:
# - Worker / scripts können diese Datei lesen und vor Ausführung eine Warnung
#   oder Bestätigung an den Benutzer ausgeben, wenn ein Engine-Wechsel stattfindet.
# - Diese Datei ist eine Hilfestellung; die endgültige Audit-Entscheidung liegt
#   bei Codex und dem Benutzer (siehe AGENTS.md §7 für Freigaben).
