import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'

// `vi.mock` wird ueber die Imports gehoben — die Komponente sieht also nie den
// echten App-Router.
vi.mock('next/navigation', () => ({
  usePathname: () => '/thema/tech',
}))

import { AffiliateLink } from './affiliate-link'
import { consentStore } from '@/lib/consent'
import { CONSENT_COOKIE_NAME } from '@/lib/consent-cookie'
import { CLICK_SESSION_STORAGE_KEY } from '@/lib/click-session'

const SLUG = 'tre-feuerstahl-xxl'
const TARGET = 'https://amzn.to/48jljFR'
const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'
/** Zweite Kennung fuer den Widerruf-und-neu-Zustimmen-Fall. */
const SECOND_SESSION_ID = '8c7d6e5f-4a3b-4c2d-91e0-fa9b8c7d6e5f'
const PLAIN_HREF = `/api/click/${SLUG}?from=%2Fthema%2Ftech`
const DECORATED_HREF = `${PLAIN_HREF}&cs=${SESSION_ID}`

function link(): HTMLAnchorElement {
  return screen.getByRole('link') as HTMLAnchorElement
}

/** Setzt den echten Consent-Cookie — genau so, wie der Hinweisbanner es tut. */
function setConsentCookie(value: 'accepted' | 'declined') {
  document.cookie = `${CONSENT_COOKIE_NAME}=${value}; Path=/`
}

function clearCookies() {
  for (const part of document.cookie.split(';')) {
    const name = part.split('=')[0]?.trim()
    if (name) document.cookie = `${name}=; Path=/; Max-Age=0`
  }
}

beforeEach(() => {
  clearCookies()
  // Der Store ist ein Singleton mit Sitzungs-Fallback — ohne Zuruecksetzen
  // truege ein Test die Entscheidung des vorherigen mit.
  consentStore.clearConsent()
  window.localStorage.clear()
  window.sessionStorage.clear()
  // Deterministische Kennung statt echter Zufall — der Test prueft die
  // Verdrahtung, nicht die Qualitaet des Zufallsgenerators.
  vi.stubGlobal('crypto', { randomUUID: () => SESSION_ID })
})

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
  clearCookies()
  window.localStorage.clear()
  window.sessionStorage.clear()
})

describe('AffiliateLink — Linkstruktur', () => {
  it('zeigt auf die interne Klick-Route und nie auf das Partnerziel', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    const a = link()
    expect(a.getAttribute('href')).toBe(PLAIN_HREF)
    // Das echte Ziel steht nirgends im ausgelieferten Markup.
    expect(document.body.innerHTML).not.toContain('amzn.to')
  })

  it('behaelt Kennzeichnung und Zielfenster bei', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    const a = link()
    expect(a.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('referrerpolicy')).toBe('no-referrer')
  })

  it('beschriftet den CTA nach dem erkannten Merchant', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    expect(link().textContent).toBe('Bei Amazon ansehen')
  })

  it('behauptet bei unbekanntem Ziel keinen Merchant', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl="https://irgendwo.example/x" />)
    expect(link().textContent).toBe('Zum Angebot')
  })

  it('ist per Tastatur erreichbar — echtes <a> mit href, kein div mit onClick', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    const a = link()
    expect(a.tagName).toBe('A')
    expect(a.hasAttribute('href')).toBe(true)
    expect(a.getAttribute('tabindex')).toBeNull()
  })

  it('liefert das erste href auch bei erteiltem Consent unveraendert aus', () => {
    // Hydrierungsstabilitaet: Server und Client rendern denselben Link. Die
    // Kennung kommt erst bei der tatsaechlichen Aktivierung dazu.
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    // Und ohne Beruehrung entsteht auch keine Kennung.
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })
})

describe('AffiliateLink — Consent steuert nur die Messung', () => {
  it('haengt ohne Entscheidung keine Kennung an und legt keine an', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    fireEvent.pointerDown(link())
    fireEvent.click(link())

    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    expect(link().getAttribute('href')).not.toContain('cs=')
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('haengt nach Ablehnung keine Kennung an', () => {
    setConsentCookie('declined')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    fireEvent.pointerDown(link())
    fireEvent.click(link())

    expect(link().getAttribute('href')).not.toContain('cs=')
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('behandelt eine alte v1-Zustimmung im localStorage NICHT als Einwilligung', () => {
    // Der alte Schluessel gehoerte zu einem anderen Zweck. Er darf die neue
    // Messung nicht freischalten — die Entscheidung muss neu fallen.
    window.localStorage.setItem('cbb-cookie-consent-v1', 'accepted')
    window.localStorage.setItem('cbb-cookie-consent', 'accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    fireEvent.pointerDown(link())
    fireEvent.click(link())

    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    // Und es entsteht kein Consent-Cookie aus dem Nichts.
    expect(document.cookie).not.toContain(CONSENT_COOKIE_NAME)
  })

  it('haengt bei einem Mausklick nach Zustimmung eine zufaellige Kennung an', async () => {
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    fireEvent.pointerDown(link())

    // Das href ist schon VOR dem Klick dekoriert — die Navigation faehrt also
    // nicht mit dem alten Wert los.
    expect(link().getAttribute('href')).toBe(DECORATED_HREF)

    fireEvent.click(link())
    await waitFor(() => expect(link().getAttribute('href')).toBe(DECORATED_HREF))

    // Die Kennung liegt im sessionStorage — nicht im localStorage, nicht im Cookie.
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
    expect(window.localStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
    expect(document.cookie).not.toContain(SESSION_ID)
  })

  it('haengt bei Tastaturbedienung nach Zustimmung eine Kennung an', async () => {
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    // Enter setzt Fokus voraus — der Fokus ist deshalb der Tastatur-Ausloeser.
    act(() => link().focus())
    fireEvent.keyDown(link(), { key: 'Enter' })
    fireEvent.click(link())

    await waitFor(() => expect(link().getAttribute('href')).toBe(DECORATED_HREF))
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBe(SESSION_ID)
  })

  it('reagiert auf eine Zustimmung, die auf derselben Seite erteilt wird', async () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    fireEvent.pointerDown(link())
    expect(link().getAttribute('href')).not.toContain('cs=')

    // Genau das leistet die gemeinsame Store-Instanz aus lib/consent.ts: ein
    // `setConsent` im Cookie-Hinweis erreicht auch die Affiliate-Links.
    act(() => {
      consentStore.setConsent('accepted')
    })

    fireEvent.pointerDown(link())
    await waitFor(() => expect(link().getAttribute('href')).toContain(`cs=${SESSION_ID}`))
  })

  it('entfernt die Kennung wieder, wenn die Einwilligung widerrufen wird', async () => {
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    fireEvent.pointerDown(link())
    expect(link().getAttribute('href')).toBe(DECORATED_HREF)

    act(() => {
      consentStore.setConsent('declined')
    })

    // Kein `cs` mehr im Link und keine Kennung mehr im Storage.
    await waitFor(() => expect(link().getAttribute('href')).toBe(PLAIN_HREF))
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()

    // Auch ein erneuter Klick legt nichts Neues an.
    fireEvent.pointerDown(link())
    fireEvent.click(link())
    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('vergibt nach Widerruf und erneuter Zustimmung eine NEUE Kennung', async () => {
    // Sonst verbaende die alte Kennung die Sitzung vor dem Widerruf mit der
    // danach — genau die Wiedererkennung, die hier nicht stattfinden soll.
    const ids = [SESSION_ID, SECOND_SESSION_ID]
    let issued = 0
    vi.stubGlobal('crypto', {
      randomUUID: () => ids[Math.min(issued++, ids.length - 1)],
    })

    setConsentCookie('accepted')
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)

    fireEvent.pointerDown(link())
    expect(link().getAttribute('href')).toContain(`cs=${SESSION_ID}`)

    act(() => {
      consentStore.setConsent('declined')
    })
    act(() => {
      consentStore.setConsent('accepted')
    })
    fireEvent.pointerDown(link())

    await waitFor(() => expect(link().getAttribute('href')).toContain(`cs=${SECOND_SESSION_ID}`))
    expect(link().getAttribute('href')).not.toContain(SESSION_ID)
  })

  it('bleibt ohne Web-Crypto klickbar und haengt einfach keine Kennung an', () => {
    setConsentCookie('accepted')
    vi.stubGlobal('crypto', {})

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    fireEvent.pointerDown(link())
    fireEvent.click(link())

    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })
})

describe('AffiliateLink — measurementEnabled={false}', () => {
  it('bleibt intern verlinkt, zaehlt aber trotz Zustimmung nicht', () => {
    // Der Fall der Design-Werkbank: das Partnerziel darf nicht ins Markup, ein
    // echtes Klick-out-Ereignis aber genauso wenig entstehen.
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} measurementEnabled={false} />)

    fireEvent.pointerDown(link())
    fireEvent.mouseDown(link())
    act(() => link().focus())
    fireEvent.click(link())

    // Interne Route, keine Kennung — der Server leitet weiter und speichert nichts.
    expect(link().getAttribute('href')).toBe(PLAIN_HREF)
    expect(link().getAttribute('href')).not.toContain('cs=')
    expect(document.body.innerHTML).not.toContain('amzn.to')
    // Und es entsteht auch keine Kennung, die nur den Link nicht erreicht.
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('aendert nichts an Kennzeichnung und Zielfenster', () => {
    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} measurementEnabled={false} />)

    const a = link()
    expect(a.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
    expect(a.getAttribute('target')).toBe('_blank')
  })

  it('misst weiter, wenn die Prop weggelassen wird (Default true)', () => {
    setConsentCookie('accepted')

    render(<AffiliateLink slug={SLUG} affiliateUrl={TARGET} />)
    fireEvent.pointerDown(link())

    expect(link().getAttribute('href')).toBe(DECORATED_HREF)
  })
})

describe('Design-Preview verlinkt nicht direkt auf das Partnerziel', () => {
  // Statischer Regressionsschutz: die `noindex`-Design-Werkbank ist die einzige
  // Flaeche, die frueher ein direktes `href` auf `affiliate_url` hatte. Ein
  // Rendertest waere hier teurer als der Quelltext-Blick und wuerde die
  // eigentliche Regression — das direkte Attribut — nicht schaerfer treffen.
  // Aus dem Arbeitsverzeichnis statt aus `import.meta.url` aufgeloest: Vitest
  // transformiert Testdateien und `import.meta.url` traegt dann nicht zwingend
  // ein `file:`-Schema. Der Testlauf startet in `apps/web` (vitest.config.mts
  // liegt dort), also ist der Pfad relativ zum cwd der stabile Anker. Fehlt die
  // Datei, wirft `readFileSync` — der Regressionsschutz kann nicht still
  // durchrutschen.
  const source = readFileSync(
    resolve(process.cwd(), 'app/design-preview/preview-client.tsx'),
    'utf8'
  )

  it('setzt kein href direkt auf affiliate_url', () => {
    expect(source).not.toMatch(/href=\{[^}]*affiliate_url/)
  })

  it('nutzt AffiliateLink mit abgeschalteter Messung', () => {
    expect(source).toContain('<AffiliateLink')
    expect(source).toContain('measurementEnabled={false}')
  })
})
