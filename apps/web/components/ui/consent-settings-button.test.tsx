/**
 * Der Widerruf muss ohne Umweg ueber die Browsereinstellungen funktionieren.
 *
 * Geprueft wird das Zusammenspiel, nicht nur der Klick: Knopf und Hinweisbanner
 * haengen an DERSELBEN Store-Instanz (lib/consent.ts). Genau deshalb erscheint
 * der Banner nach dem Widerruf ohne Reload wieder — dieser Test wuerde
 * fehlschlagen, wenn jemand den Knopf spaeter an einen eigenen Store haengt.
 */
import type { ReactNode } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'

// Der Hinweisbanner verlinkt auf /datenschutz. Ohne App-Router-Kontext ist
// `next/link` in jsdom Ballast — hier zaehlt nur, dass der Banner erscheint.
vi.mock('next/link', async () => {
  const { createElement } = await import('react')
  const LinkMock = ({
    href,
    children,
    ...rest
  }: { href: string; children?: ReactNode } & Record<string, unknown>) =>
    createElement('a', { href, ...rest }, children)
  return { default: LinkMock }
})

import { ConsentSettingsButton } from './consent-settings-button'
import { CookieConsent } from './cookie-consent'
import { consentStore } from '@/lib/consent'
import { CONSENT_COOKIE_NAME } from '@/lib/consent-cookie'
import { CLICK_SESSION_STORAGE_KEY } from '@/lib/click-session'

const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'

function clearCookies() {
  for (const part of document.cookie.split(';')) {
    const name = part.split('=')[0]?.trim()
    if (name) document.cookie = `${name}=; Path=/; Max-Age=0`
  }
}

function reset() {
  cleanup()
  clearCookies()
  // Der Store ist ein Singleton mit Sitzungs-Fallback — ohne dieses
  // Zuruecksetzen truege ein Test die Entscheidung des vorherigen mit.
  consentStore.clearConsent()
  window.sessionStorage.clear()
}

/** Der Knopf, so wie ihn eine Besucherin im Fussbereich findet. */
function widerrufsknopf() {
  return screen.getByRole('button', { name: 'Datenschutz-Einstellungen' })
}

function hinweisbanner() {
  return screen.queryByRole('dialog', { name: 'Cookie-Hinweis' })
}

beforeEach(reset)
afterEach(reset)

describe('ConsentSettingsButton — Widerruf jederzeit', () => {
  it('ist eine echte, per Tastatur bedienbare Schaltflaeche', () => {
    render(<ConsentSettingsButton />)

    const button = widerrufsknopf()
    // Ein natives <button> ist ohne tabIndex fokussierbar und reagiert auf
    // Enter und Leertaste. Ein <div onClick> taete das nicht.
    expect(button.tagName).toBe('BUTTON')
    expect(button.getAttribute('type')).toBe('button')
  })

  it('loescht Entscheidung UND Sitzungskennung und zeigt den Hinweis wieder', () => {
    consentStore.setConsent('accepted')
    window.sessionStorage.setItem(CLICK_SESSION_STORAGE_KEY, SESSION_ID)

    render(
      <>
        <ConsentSettingsButton />
        <CookieConsent />
      </>
    )

    // Ausgangslage: entschieden, also kein Banner.
    expect(hinweisbanner()).toBeNull()

    fireEvent.click(widerrufsknopf())

    expect(consentStore.getSnapshot()).toBeNull()
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    expect(document.cookie).not.toContain(`${CONSENT_COOKIE_NAME}=accepted`)
    // Ohne Reload wieder da: der Store ist reaktiv.
    expect(hinweisbanner()).not.toBeNull()
  })

  it('widerruft auch eine Ablehnung, statt sie festzuschreiben', () => {
    consentStore.setConsent('declined')

    render(
      <>
        <ConsentSettingsButton />
        <CookieConsent />
      </>
    )

    fireEvent.click(widerrufsknopf())

    // Nach dem Widerruf ist der Zustand "noch nicht entschieden" — nicht
    // "abgelehnt". Sonst koennte niemand eine Ablehnung je zuruecknehmen.
    expect(consentStore.getSnapshot()).toBeNull()
    expect(hinweisbanner()).not.toBeNull()
  })

  it('erzeugt beim Widerruf selbst keine Kennung und keinen Cookie-Wert', () => {
    render(<ConsentSettingsButton />)

    fireEvent.click(widerrufsknopf())

    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    expect(document.cookie).not.toContain(`${CONSENT_COOKIE_NAME}=accepted`)
    expect(document.cookie).not.toContain(`${CONSENT_COOKIE_NAME}=declined`)
  })
})
