import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import {
  CONSENT_COOKIE_NAME,
  buildConsentClearCookie,
  buildConsentCookie,
  deleteConsentCookie,
  isAcceptedConsent,
  parseConsentValue,
  readConsentCookie,
  readConsentFromCookieHeader,
  writeConsentCookie,
} from './consent-cookie'

function clearCookies() {
  for (const part of document.cookie.split(';')) {
    const name = part.split('=')[0]?.trim()
    if (name) document.cookie = `${name}=; Path=/; Max-Age=0`
  }
}

beforeEach(clearCookies)
afterEach(clearCookies)

describe('parseConsentValue / isAcceptedConsent', () => {
  it('erkennt genau die beiden erlaubten Werte', () => {
    expect(parseConsentValue('accepted')).toBe('accepted')
    expect(parseConsentValue('declined')).toBe('declined')
    expect(isAcceptedConsent('accepted')).toBe(true)
    expect(isAcceptedConsent('declined')).toBe(false)
  })

  it('behandelt alles andere als "keine Entscheidung"', () => {
    for (const raw of ['', ' accepted', 'ACCEPTED', 'true', '1', 'yes', null, undefined, 0, {}]) {
      expect(parseConsentValue(raw), String(raw)).toBeNull()
      expect(isAcceptedConsent(raw), String(raw)).toBe(false)
    }
  })
})

describe('readConsentFromCookieHeader', () => {
  it('liest den eigenen Wert aus einem Header mit mehreren Cookies', () => {
    expect(
      readConsentFromCookieHeader(`a=1; ${CONSENT_COOKIE_NAME}=accepted; b=2`)
    ).toBe('accepted')
    expect(readConsentFromCookieHeader(`${CONSENT_COOKIE_NAME}=declined`)).toBe('declined')
  })

  it('verwechselt fremde Cookie-Namen nicht mit dem eigenen', () => {
    for (const header of [
      `not_${CONSENT_COOKIE_NAME}=accepted`,
      `${CONSENT_COOKIE_NAME}_alt=accepted`,
      `x${CONSENT_COOKIE_NAME}=accepted`,
      // Die alten Schluessel gelten fuer den neuen Zweck ausdruecklich nicht.
      'cbb-cookie-consent-v1=accepted',
      'cbb-cookie-consent=accepted',
    ]) {
      expect(readConsentFromCookieHeader(header), header).toBeNull()
    }
  })

  it('liefert ohne Header null', () => {
    expect(readConsentFromCookieHeader(null)).toBeNull()
    expect(readConsentFromCookieHeader('')).toBeNull()
    expect(readConsentFromCookieHeader('kaputt')).toBeNull()
  })
})

describe('buildConsentCookie', () => {
  it('setzt Pfad, SameSite und Laufzeit — und traegt nur die Entscheidung', () => {
    const cookie = buildConsentCookie('accepted', true)

    expect(cookie).toContain(`${CONSENT_COOKIE_NAME}=accepted`)
    expect(cookie).toContain('Path=/')
    expect(cookie).toContain('SameSite=Lax')
    expect(cookie).toContain('Max-Age=')
    expect(cookie).toContain('Secure')
  })

  it('laesst Secure weg, wenn die Seite nicht ueber HTTPS laeuft', () => {
    // Sonst verwuerfe der Browser den Cookie auf http://localhost und die
    // Entscheidung liesse sich lokal nie speichern.
    expect(buildConsentCookie('declined', false)).not.toContain('Secure')
  })

  it('loescht mit Max-Age=0 bei identischem Pfad', () => {
    const cookie = buildConsentClearCookie(false)
    expect(cookie).toContain('Max-Age=0')
    expect(cookie).toContain('Path=/')
  })
})

describe('Schreiben und Lesen im Browser', () => {
  it('schreibt die Entscheidung und liest sie wieder', () => {
    writeConsentCookie('accepted')
    expect(readConsentCookie()).toBe('accepted')

    writeConsentCookie('declined')
    expect(readConsentCookie()).toBe('declined')
  })

  it('entfernt die Entscheidung vollstaendig', () => {
    writeConsentCookie('accepted')
    deleteConsentCookie()

    expect(readConsentCookie()).toBeNull()
    expect(document.cookie).not.toContain(`${CONSENT_COOKIE_NAME}=accepted`)
  })

  it('speichert im Cookie ausschliesslich die Entscheidung, nie eine Kennung', () => {
    writeConsentCookie('accepted')

    const raw = document.cookie
    expect(raw).toContain(`${CONSENT_COOKIE_NAME}=accepted`)
    // Keine UUID-Form irgendwo im Cookie-Speicher.
    expect(raw).not.toMatch(/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}/)
  })
})
