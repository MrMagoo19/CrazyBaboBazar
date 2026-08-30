/**
 * Consent-gebundene Session-Kennung fuer die Klick-out-Messung (P1).
 *
 * ENTSCHEIDUNG UND IHRE BEGRUENDUNG:
 *   * Die Kennung entsteht ERST, wenn der Consent-Store (lib/consent.ts,
 *     Cookie `cbb_consent_clickout_v2`) ausdruecklich `accepted` meldet, und
 *     erst in dem Moment, in dem ein Partnerlink tatsaechlich aktiviert wird.
 *     Ohne Einwilligung wird nichts erzeugt, nichts gespeichert und nichts an
 *     den Server gesendet — die Weiterleitung funktioniert trotzdem, sie
 *     braucht die Kennung nicht.
 *   * Speicherort ist `sessionStorage`, NICHT `localStorage` und ausdruecklich
 *     KEIN Cookie. Auch der Consent-Cookie enthaelt sie nie; der traegt nur
 *     `accepted`/`declined`. Damit endet die Kennung spaetestens mit dem Tab;
 *     sie ueberdauert weder den Browser-Neustart noch andere Tabs und ist
 *     deshalb kein geraetedauerhafter Identifikator.
 *   * Der Wert ist eine zufaellige UUID (v4) ohne jeden Bezug zu Geraet,
 *     Netzwerk oder Person. Es gibt bewusst keinen IP-Hash und keinen
 *     User-Agent-Fingerprint.
 *   * Faellt `sessionStorage` aus (privater Modus, blockierter Storage), gibt
 *     es keine Kennung. Der Klick wird dann nicht gezaehlt — das ist der
 *     gewollte fail-closed Ausgang fuer die Messung, waehrend die
 *     Weiterleitung fail-open bleibt.
 */

import { isConsentedSessionId } from './affiliate'

export const CLICK_SESSION_STORAGE_KEY = 'cbb-clickout-session-v1'

function randomSessionId(): string | null {
  const cryptoRef = globalThis.crypto
  if (cryptoRef && typeof cryptoRef.randomUUID === 'function') {
    return cryptoRef.randomUUID()
  }
  // Ohne Web-Crypto lieber gar keine Kennung als eine schwach zufaellige.
  // `Math.random` waere hier kein tragfaehiger Ersatz.
  return null
}

/**
 * Liefert die Session-Kennung des laufenden Tabs — und legt sie beim ersten
 * Aufruf an. Nur aufrufen, wenn die Einwilligung `accepted` ist.
 */
export function getOrCreateClickSessionId(): string | null {
  if (typeof window === 'undefined') return null

  let store: Storage
  try {
    store = window.sessionStorage
  } catch {
    return null
  }

  try {
    const existing = store.getItem(CLICK_SESSION_STORAGE_KEY)
    if (isConsentedSessionId(existing)) return existing
  } catch {
    return null
  }

  const created = randomSessionId()
  if (!created || !isConsentedSessionId(created)) return null

  try {
    store.setItem(CLICK_SESSION_STORAGE_KEY, created)
  } catch {
    // Nicht persistierbar: dann gilt die Kennung nur fuer diesen einen Klick.
    // Das ist zulaessig, weil sie ohnehin rein zufaellig und kurzlebig ist.
  }
  return created
}

/**
 * Entfernt eine vorhandene Kennung. Wird beim Widerruf der Einwilligung
 * aufgerufen, damit nach einem `declined` nichts Zaehlbares zurueckbleibt.
 */
export function clearClickSessionId(): void {
  if (typeof window === 'undefined') return
  try {
    window.sessionStorage.removeItem(CLICK_SESSION_STORAGE_KEY)
  } catch {
    // Kein Storage — dann gibt es auch nichts zu entfernen.
  }
}
