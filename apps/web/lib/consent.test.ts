import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { consentStore } from './consent'
import { CONSENT_COOKIE_NAME } from './consent-cookie'
import { CLICK_SESSION_STORAGE_KEY } from './click-session'

const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'

function clearCookies() {
  for (const part of document.cookie.split(';')) {
    const name = part.split('=')[0]?.trim()
    if (name) document.cookie = `${name}=; Path=/; Max-Age=0`
  }
}

beforeEach(() => {
  clearCookies()
  // Der Store ist ein Singleton und haelt einen Sitzungs-Fallback fuer den Fall,
  // dass `document.cookie` nicht schreibbar ist. Ohne dieses Zuruecksetzen
  // truege ein Test die Entscheidung des vorherigen mit.
  consentStore.clearConsent()
  window.localStorage.clear()
  window.sessionStorage.clear()
})

afterEach(() => {
  vi.unstubAllGlobals()
  clearCookies()
  window.localStorage.clear()
  window.sessionStorage.clear()
})

describe('consentStore — Entscheidung liegt im pruefbaren Cookie', () => {
  it('meldet ohne Entscheidung null', () => {
    expect(consentStore.getSnapshot()).toBeNull()
  })

  it('schreibt eine Zustimmung in den Consent-Cookie', () => {
    consentStore.setConsent('accepted')

    expect(consentStore.getSnapshot()).toBe('accepted')
    expect(document.cookie).toContain(`${CONSENT_COOKIE_NAME}=accepted`)
  })

  it('schreibt eine Ablehnung als eigenen Zustand, nicht als Leerwert', () => {
    consentStore.setConsent('declined')

    expect(consentStore.getSnapshot()).toBe('declined')
    expect(document.cookie).toContain(`${CONSENT_COOKIE_NAME}=declined`)
  })

  it('benachrichtigt Abonnenten sofort — auch im selben Tab', () => {
    const seen: unknown[] = []
    const unsubscribe = consentStore.subscribe(() => seen.push(consentStore.getSnapshot()))

    consentStore.setConsent('accepted')
    unsubscribe()

    expect(seen).toEqual(['accepted'])
  })

  it('rendert waehrend SSR und Hydration nichts', () => {
    expect(consentStore.getServerSnapshot()).toBe('unknown')
  })
})

describe('consentStore — kein Uebertrag aus Consent v1', () => {
  it('behandelt einen alten localStorage-Wert nicht als Entscheidung', () => {
    window.localStorage.setItem('cbb-cookie-consent-v1', 'accepted')
    window.localStorage.setItem('cbb-cookie-consent', 'accepted')

    // Der alte Schluessel gehoerte zum blossen Hinweis auf Vercel/Amazon. Der
    // neue Messzweck muss neu entschieden werden.
    expect(consentStore.getSnapshot()).toBeNull()
    expect(document.cookie).not.toContain(CONSENT_COOKIE_NAME)
  })

  it('laesst den alten Schluessel unangetastet, statt ihn zu migrieren', () => {
    window.localStorage.setItem('cbb-cookie-consent-v1', 'accepted')

    consentStore.setConsent('declined')

    expect(window.localStorage.getItem('cbb-cookie-consent-v1')).toBe('accepted')
    expect(consentStore.getSnapshot()).toBe('declined')
  })
})

describe('consentStore — Widerruf raeumt die Sitzungskennung ab', () => {
  it('entfernt die Kennung bei einer Ablehnung', () => {
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    consentStore.setConsent('declined')

    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('entfernt bei clearConsent Kennung UND Entscheidung', () => {
    consentStore.setConsent('accepted')
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    consentStore.clearConsent()

    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    expect(consentStore.getSnapshot()).toBeNull()
    expect(document.cookie).not.toContain(`${CONSENT_COOKIE_NAME}=accepted`)
  })

  it('laesst eine Kennung bei einer Zustimmung stehen', () => {
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    consentStore.setConsent('accepted')

    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
  })

  it('speichert die Kennung nie im Cookie', () => {
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    consentStore.setConsent('accepted')

    expect(document.cookie).not.toContain(SESSION_ID)
  })
})
