/**
 * Genau EINE Consent-Store-Instanz fuer die ganze App (Consent v2).
 *
 * WARUM DER COOKIE UND NICHT MEHR localStorage:
 * Der Store fuehrt die Entscheidung jetzt im First-Party-Cookie aus
 * lib/consent-cookie.ts. Das ist kein Stil-, sondern ein Korrektheitsgrund:
 * die Klick-out-Messung passiert auf dem Server, also muss der Server die
 * Einwilligung selbst pruefen koennen. Ein localStorage-Wert erreicht ihn nie.
 * Es gibt damit genau EINE Quelle der Wahrheit, die Client und Server lesen —
 * kein Auseinanderdriften zwischen "Banner sagt akzeptiert" und "Server sieht
 * keine Einwilligung".
 *
 * WARUM KEIN ZUGRIFF AUF v1:
 * Der alte localStorage-Schluessel `cbb-cookie-consent-v1` wird bewusst weder
 * gelesen noch migriert noch geloescht. Er gehoerte zum blossen Hinweis auf
 * Vercel/Amazon; die neue, persistente Klick-out-Messung ist ein anderer Zweck
 * und braucht eine eigene Entscheidung. Wer damals zugestimmt hat, sieht den
 * Hinweis deshalb erneut — das ist gewollt, nicht vergessen.
 *
 * WARUM EIN SINGLETON:
 * Die Listener-Menge haengt an der Instanz. Legte jede Komponente ihren eigenen
 * Store an, benachrichtigte ein `setConsent` im Hinweisbanner nur die eigenen
 * Abonnenten — die Affiliate-Links derselben Seite bekaemen die Entscheidung
 * erst nach einer Navigation mit.
 */

import { clearClickSessionId } from './click-session'
import { deleteConsentCookie, readConsentCookie, writeConsentCookie } from './consent-cookie'
import { SERVER_SNAPSHOT, type ConsentStore, type ConsentValue } from './consent-store'

function createCookieConsentStore(): ConsentStore & { clearConsent: () => void } {
  const listeners = new Set<() => void>()

  // Nur relevant, wenn `document.cookie` nicht schreibbar ist (blockierter
  // Storage, privater Modus). Dann haelt der Hinweis die Entscheidung
  // wenigstens fuer die laufende Seite fest. Ein wirklich gespeicherter Cookie
  // gewinnt immer — der Server sieht ohnehin nur den Cookie.
  let fallbackConsent: ConsentValue | null = null

  const emitChange = () => {
    for (const listener of listeners) listener()
  }

  // Cookies loesen kein `storage`-Event aus. Beim Zurueckkehren auf den Tab neu
  // zu lesen ist der guenstigste Weg, eine Entscheidung aus einem anderen Tab
  // trotzdem zu uebernehmen. Der Fallback faellt dabei nur, wenn es wirklich
  // einen gespeicherten Cookie gibt — sonst wuerde ein blosser Tabwechsel die
  // Entscheidung in Umgebungen ohne schreibbaren Cookie wieder wegwerfen.
  const handleVisibility = () => {
    if (document.visibilityState !== 'visible') return
    if (readConsentCookie() !== null) fallbackConsent = null
    emitChange()
  }

  return {
    subscribe(onStoreChange) {
      if (listeners.size === 0) window.addEventListener('visibilitychange', handleVisibility)
      listeners.add(onStoreChange)
      return () => {
        listeners.delete(onStoreChange)
        if (listeners.size === 0) window.removeEventListener('visibilitychange', handleVisibility)
      }
    },

    getSnapshot() {
      return readConsentCookie() ?? fallbackConsent
    },

    getServerSnapshot() {
      return SERVER_SNAPSHOT
    },

    /**
     * Die einzige Stelle, an der eine Einwilligung entsteht oder endet.
     *
     * Das Aufraeumen der Sitzungskennung steht bewusst HIER und nicht im
     * Hinweisbanner: so kann kein kuenftiger Aufrufer eines Widerrufs es
     * vergessen. Nach `declined` bleibt garantiert nichts Zaehlbares zurueck.
     */
    setConsent(value) {
      if (value !== 'accepted') clearClickSessionId()
      fallbackConsent = value
      writeConsentCookie(value)
      emitChange()
    },

    /** Vollstaendiger Widerruf: zurueck in den Zustand "noch nicht entschieden". */
    clearConsent() {
      clearClickSessionId()
      fallbackConsent = null
      deleteConsentCookie()
      emitChange()
    },
  }
}

export const consentStore = createCookieConsentStore()
