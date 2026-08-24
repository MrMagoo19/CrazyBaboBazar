/**
 * Kleiner externer Store für den Einwilligungs-Hinweis.
 *
 * localStorage ist ein externer Store und kein React-State. Statt ihn in einem
 * Effekt nachträglich in State zu spiegeln (was einen zusätzlichen Render
 * auslöst), wird er über `useSyncExternalStore` gelesen.
 *
 * Der Server-Snapshot ist bewusst ein Platzhalter: Während SSR und Hydration
 * gibt es keinen echten Wert, der Hinweis wird dort also nie gerendert. Erst
 * nach der Hydration liest React den Client-Snapshot und zeigt den Hinweis,
 * falls noch keine Entscheidung gespeichert ist.
 */

export type ConsentValue = 'accepted' | 'declined'

/** Platzhalter für SSR/Hydration — bewusst kein `null`, damit nichts rendert. */
export const SERVER_SNAPSHOT = 'unknown'

/** `null` = noch keine (gültige) Entscheidung gespeichert. */
export type ConsentSnapshot = ConsentValue | null | typeof SERVER_SNAPSHOT

export type ConsentStore = {
  subscribe: (onStoreChange: () => void) => () => void
  getSnapshot: () => ConsentValue | null
  getServerSnapshot: () => typeof SERVER_SNAPSHOT
  setConsent: (value: ConsentValue) => void
}

function isConsentValue(value: unknown): value is ConsentValue {
  return value === 'accepted' || value === 'declined'
}

export function createConsentStore(storageKey: string): ConsentStore {
  const listeners = new Set<() => void>()

  // Fallback, falls localStorage nicht schreib- oder lesbar ist (z. B. privater
  // Modus): Die Entscheidung gilt dann zumindest für die laufende Session.
  // Wird nur benutzt, wenn kein gültiger Wert aus dem Storage kommt — ein
  // gespeicherter Wert (auch aus einem anderen Tab) gewinnt immer.
  let fallbackConsent: ConsentValue | null = null

  const emitChange = () => {
    for (const listener of listeners) listener()
  }

  const handleStorage = (event: StorageEvent) => {
    // `key === null` bedeutet `localStorage.clear()` — betrifft uns also auch.
    if (event.key !== null && event.key !== storageKey) return
    // Fremde Änderung an unserem Key: Session-Fallback verwerfen, damit er den
    // neuen Stand nicht dauerhaft überdeckt, und neu lesen lassen.
    fallbackConsent = null
    emitChange()
  }

  return {
    subscribe(onStoreChange) {
      if (listeners.size === 0) window.addEventListener('storage', handleStorage)
      listeners.add(onStoreChange)
      return () => {
        listeners.delete(onStoreChange)
        if (listeners.size === 0) window.removeEventListener('storage', handleStorage)
      }
    },

    getSnapshot() {
      let raw: string | null
      try {
        raw = localStorage.getItem(storageKey)
      } catch {
        // Nicht lesbar — nur der Session-Fallback bleibt.
        return fallbackConsent
      }
      // Fremde oder kaputte Werte nicht durchreichen.
      if (isConsentValue(raw)) return raw
      return fallbackConsent
    },

    getServerSnapshot() {
      return SERVER_SNAPSHOT
    },

    setConsent(value) {
      fallbackConsent = value
      try {
        localStorage.setItem(storageKey, value)
      } catch {
        // Nicht persistierbar — der Session-Fallback blendet den Hinweis
        // trotzdem aus, bis ein anderer Tab den Key ändert.
      }
      emitChange()
    },
  }
}
