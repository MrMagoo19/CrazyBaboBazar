/** Consent-bound, tab-scoped identifier for Swipe & Likes. */
export const SWIPE_SESSION_STORAGE_KEY = 'cbb-swipe-session-v2'
const LEGACY_SWIPE_LOCAL_STORAGE_KEY = 'cbb-swipe-session'

function isSessionId(value: string | null): value is string {
  return Boolean(value && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value))
}

/** Read only: opening the Swipe page must never create an identifier. */
export function getStoredSwipeSessionId(): string | null {
  if (typeof window === 'undefined') return null
  try {
    const value = window.sessionStorage.getItem(SWIPE_SESSION_STORAGE_KEY)
    return isSessionId(value) ? value : null
  } catch {
    return null
  }
}

/** Call only after explicit consent and the user's first active swipe. */
export function getOrCreateSwipeSessionId(): string | null {
  const existing = getStoredSwipeSessionId()
  if (existing) return existing
  if (typeof window === 'undefined' || typeof globalThis.crypto?.randomUUID !== 'function') return null
  const created = globalThis.crypto.randomUUID()
  if (!isSessionId(created)) return null
  try {
    window.sessionStorage.setItem(SWIPE_SESSION_STORAGE_KEY, created)
    return created
  } catch {
    return null
  }
}

export function clearSwipeSessionId(): void {
  if (typeof window === 'undefined') return
  try {
    window.sessionStorage.removeItem(SWIPE_SESSION_STORAGE_KEY)
  } catch {
    // Storage unavailable; nothing remains to clear.
  }
  try {
    window.localStorage.removeItem(LEGACY_SWIPE_LOCAL_STORAGE_KEY)
  } catch {
    // Legacy storage unavailable; nothing remains to clear.
  }
}

/** Removes the old durable identifier without reading or migrating it. */
export function removeLegacySwipeSessionId(): void {
  if (typeof window === 'undefined') return
  try {
    window.localStorage.removeItem(LEGACY_SWIPE_LOCAL_STORAGE_KEY)
  } catch {
    // Storage unavailable.
  }
}
