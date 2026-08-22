// Persona helpers — single source of truth for which persona values are valid
// and how they map to their hub routes. Prevents links to non-existent persona
// routes (e.g. the historical `/unknown/...` 404) and stops raw/invalid persona
// strings (like "unknown") from being shown as if they were a real persona.

export type KnownPersona = 'babo' | 'queen' | 'miniboss'

export const PERSONA_ROUTES: Record<KnownPersona, string> = {
  babo: 'babos',
  queen: 'queens',
  miniboss: 'miniboss',
}

export function isKnownPersona(p: string | null | undefined): p is KnownPersona {
  return p === 'babo' || p === 'queen' || p === 'miniboss'
}

// Capitalised label for a known persona, or null if the value is missing/invalid.
export function personaLabel(p: string | null | undefined): string | null {
  return isKnownPersona(p) ? p.charAt(0).toUpperCase() + p.slice(1) : null
}
