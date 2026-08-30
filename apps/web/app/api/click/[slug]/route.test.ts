/**
 * @vitest-environment node
 *
 * Tests fuer die Affiliate-Weiterleitung.
 *
 * KEIN NETZ, KEINE DATENBANK: `fetch` ist vollstaendig gemockt. Der Test
 * spricht weder Production noch Pilot an — er prueft ausschliesslich, WELCHE
 * Anfrage der Route-Handler stellen WUERDE und was er zurueckgibt.
 *
 * Die Node-Umgebung ist noetig, weil der Handler `Response`, `Headers` und
 * `AbortSignal.timeout` benutzt.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { GET } from './route'
import { CONSENT_COOKIE_NAME } from '@/lib/consent-cookie'

const ACCEPTED_COOKIE = `${CONSENT_COOKIE_NAME}=accepted`
const DECLINED_COOKIE = `${CONSENT_COOKIE_NAME}=declined`

const SUPABASE_URL = 'https://project.supabase.invalid'
const ANON_KEY = 'anon-test-key'
const SERVICE_KEY = 'service-test-key'
const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'
const SLUG = 'ticktime-tk3-wuerfel-timer-countdown'
const TARGET = 'https://amzn.to/4mQqqTX'

const DESKTOP_UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36'
const IPHONE_UA =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148'

type FakeRequest = Parameters<typeof GET>[0]

/**
 * `cookie` ist bewusst ein eigener Parameter: die Einwilligung reist NICHT im
 * Query, sondern im Cookie-Header. Jeder Test muss sie also ausdruecklich
 * mitgeben — Vergessen ergibt "keine Einwilligung", nicht "irgendwie doch".
 */
function makeRequest(
  query = '',
  userAgent: string | null = DESKTOP_UA,
  cookie: string | null = null
): FakeRequest {
  const url = new URL(`https://www.crazybabobazar.com/api/click/${SLUG}${query}`)
  const headers = new Headers()
  if (userAgent) headers.set('user-agent', userAgent)
  if (cookie) headers.set('cookie', cookie)
  // Der Handler liest ausschliesslich `nextUrl.searchParams` und `headers`.
  // Ein vollstaendiger NextRequest waere hier nur Ballast.
  return { nextUrl: url, headers } as unknown as FakeRequest
}

/** Kurzform fuer den Normalfall "eingewilligt und Kennung dabei". */
function consentedRequest(query = '', userAgent: string | null = DESKTOP_UA): FakeRequest {
  return makeRequest(query, userAgent, ACCEPTED_COOKIE)
}

function ctx(slug = SLUG) {
  return { params: Promise.resolve({ slug }) }
}

/** Antwort des Produkt-Lookups. `null` = Produkt nicht gefunden. */
function lookupResponse(affiliateUrl: string | null) {
  return new Response(JSON.stringify(affiliateUrl === null ? [] : [{ affiliate_url: affiliateUrl }]), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  })
}

type FetchCall = { url: string; init: RequestInit | undefined }

function installFetch(options: {
  affiliateUrl?: string | null
  lookupFails?: boolean
  insertFails?: boolean
  /** Statuscode der Insert-Antwort. `fetch` wirft dabei NICHT. */
  insertStatus?: number
}) {
  const calls: FetchCall[] = []
  const fetchMock = vi.fn(async (input: unknown, init?: RequestInit) => {
    const url = String(input)
    calls.push({ url, init })
    if (url.includes('/rest/v1/click_outs')) {
      if (options.insertFails) throw new Error('CBB-TEST: Insert absichtlich fehlgeschlagen.')
      return new Response(null, { status: options.insertStatus ?? 201 })
    }
    if (options.lookupFails) throw new Error('CBB-TEST: Lookup absichtlich fehlgeschlagen.')
    return lookupResponse(options.affiliateUrl ?? null)
  })
  vi.stubGlobal('fetch', fetchMock)
  return {
    calls,
    fetchMock,
    lookups: () => calls.filter((c) => c.url.includes('/rest/v1/products')),
    inserts: () => calls.filter((c) => c.url.includes('/rest/v1/click_outs')),
  }
}

beforeEach(() => {
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_URL', SUPABASE_URL)
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY', ANON_KEY)
  vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', SERVICE_KEY)
})

afterEach(() => {
  vi.unstubAllGlobals()
  vi.unstubAllEnvs()
})

describe('GET /api/click/[slug] — Weiterleitung', () => {
  it('leitet ohne Consent weiter und speichert dabei NICHTS', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(makeRequest('?from=%2Fthema%2Ftech'), ctx())

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })

  it('setzt Schutz-Header, damit der Klick nicht gecacht und nicht indexiert wird', async () => {
    installFetch({ affiliateUrl: TARGET })

    const res = await GET(makeRequest(), ctx())

    expect(res.headers.get('Cache-Control')).toBe('no-store, max-age=0')
    expect(res.headers.get('Referrer-Policy')).toBe('no-referrer')
    expect(res.headers.get('X-Robots-Tag')).toBe('noindex, nofollow')
  })

  it('fragt nur veroeffentlichte Produkte ab', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(makeRequest(), ctx())

    const [lookup] = net.lookups()
    expect(lookup.url).toContain('is_published=eq.true')
    expect(lookup.url).toContain(`slug=eq.${SLUG}`)
    expect(lookup.url).toContain('select=affiliate_url')
  })
})

/**
 * Der Kern des korrigierten Verhaltens: Einwilligung ist das, was im
 * Cookie-Header steht — nicht das, was jemand in den Query schreibt.
 */
describe('GET /api/click/[slug] — Einwilligung wird serverseitig geprueft', () => {
  it('speichert bei gueltiger cs-UUID OHNE Consent-Cookie NICHTS', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    // Genau der Angriff aus dem Audit: ein fremd konstruierter Link mit einer
    // frei erfundenen, aber syntaktisch gueltigen UUID.
    const res = await GET(makeRequest(`?cs=${SESSION_ID}`), ctx())

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })

  it('speichert mit accepted-Cookie und gueltiger cs-UUID genau einen Datensatz', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    expect(net.inserts()).toHaveLength(1)
  })

  it('speichert bei declined-Cookie NICHTS, auch mit gueltiger cs-UUID', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(makeRequest(`?cs=${SESSION_ID}`, DESKTOP_UA, DECLINED_COOKIE), ctx())

    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })

  it('speichert bei manipuliertem oder fremdem Cookie-Wert NICHTS', async () => {
    for (const cookie of [
      `${CONSENT_COOKIE_NAME}=`,
      `${CONSENT_COOKIE_NAME}=ACCEPTED`,
      `${CONSENT_COOKIE_NAME}=accepted-ish`,
      `${CONSENT_COOKIE_NAME}=true`,
      `${CONSENT_COOKIE_NAME}=1`,
      // Ein fremder Cookie, dessen Name unseren nur enthaelt.
      `not_${CONSENT_COOKIE_NAME}=accepted`,
      `${CONSENT_COOKIE_NAME}_other=accepted`,
      // Der alte v1-Schluessel gilt ausdruecklich nicht fuer den neuen Zweck.
      'cbb-cookie-consent-v1=accepted',
      'cbb-cookie-consent=accepted',
    ]) {
      const net = installFetch({ affiliateUrl: TARGET })
      const res = await GET(makeRequest(`?cs=${SESSION_ID}`, DESKTOP_UA, cookie), ctx())
      expect(res.headers.get('Location'), cookie).toBe(TARGET)
      expect(net.inserts(), cookie).toHaveLength(0)
      vi.unstubAllGlobals()
    }
  })

  it('findet die Einwilligung auch zwischen anderen Cookies', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(
      makeRequest(
        `?cs=${SESSION_ID}`,
        DESKTOP_UA,
        `fremd=1; ${ACCEPTED_COOKIE}; noch_einer=zwei`
      ),
      ctx()
    )

    expect(net.inserts()).toHaveLength(1)
  })

  it('speichert mit accepted-Cookie, aber OHNE cs-Kennung NICHTS', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(consentedRequest(), ctx())

    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })
})

describe('GET /api/click/[slug] — Messung nur mit Consent', () => {
  it('speichert mit Consent genau die datensparsamen Felder', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(
      consentedRequest(`?from=%2Fthema%2Ftech%3Fq%3Dgeschenk&cs=${SESSION_ID}`, IPHONE_UA),
      ctx()
    )

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)

    const inserts = net.inserts()
    expect(inserts).toHaveLength(1)
    const body = JSON.parse(String(inserts[0].init?.body))

    // Exakt diese Schluessel — nicht mehr. Ein zusaetzliches Feld waere ein
    // Datenschutz-Regress und faellt hier auf.
    expect(Object.keys(body).sort()).toEqual([
      'consented_session_id',
      'device_class',
      'merchant',
      'product_slug',
      'source_path',
    ])
    expect(body).toEqual({
      product_slug: SLUG,
      merchant: 'amazon',
      // Der Querystring `?q=geschenk` ist weg — nur der Pfad bleibt.
      source_path: '/thema/tech',
      device_class: 'mobile',
      consented_session_id: SESSION_ID,
    })
    // Der Consent-Cookie wird gelesen, aber nie gespeichert.
    expect(JSON.stringify(body)).not.toContain(CONSENT_COOKIE_NAME)
    expect(JSON.stringify(body)).not.toContain('accepted')
  })

  it('benutzt fuer den Insert den Server-Schluessel, nie den oeffentlichen', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    const headers = new Headers(net.inserts()[0].init?.headers)
    expect(headers.get('apikey')).toBe(SERVICE_KEY)
    expect(headers.get('Authorization')).toBe(`Bearer ${SERVICE_KEY}`)
    expect(headers.get('Prefer')).toBe('return=minimal')
  })

  it('ignoriert eine Kennung, die nicht die UUID-Form hat', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(consentedRequest('?cs=besucher-42'), ctx())

    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })

  it('speichert source_path als null, wenn die Herkunft unbrauchbar ist', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(consentedRequest(`?from=https%3A%2F%2Fevil.example%2Fx&cs=${SESSION_ID}`), ctx())

    const body = JSON.parse(String(net.inserts()[0].init?.body))
    expect(body.source_path).toBeNull()
  })

  it('speichert unknown statt eines User-Agent-Fragments', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    await GET(consentedRequest(`?cs=${SESSION_ID}`, null), ctx())

    const body = JSON.parse(String(net.inserts()[0].init?.body))
    expect(body.device_class).toBe('unknown')
    // Der vollstaendige User-Agent taucht in keinem gespeicherten Feld auf.
    expect(JSON.stringify(body)).not.toContain('Mozilla')
  })
})

describe('GET /api/click/[slug] — fail-open beim Messen', () => {
  it('leitet auch dann weiter, wenn der Insert scheitert', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const net = installFetch({ affiliateUrl: TARGET, insertFails: true })

    const res = await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(1)
    // Auch der geworfene Fehler laeuft ueber den einen, datensparsamen Kanal.
    expect(warn).toHaveBeenCalledTimes(1)
    expect(String(warn.mock.calls[0]?.[0])).not.toContain(TARGET)
  })

  it('behandelt HTTP 500 der Insert-Antwort als Fehlerpfad und leitet trotzdem weiter', async () => {
    // `fetch` wirft hier NICHT — genau deshalb braucht es die res.ok-Pruefung.
    // Ohne sie waere ein dauerhaft abgelehnter Insert von aussen unsichtbar.
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const net = installFetch({ affiliateUrl: TARGET, insertStatus: 500 })

    const res = await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(1)

    expect(warn).toHaveBeenCalledTimes(1)
    const message = String(warn.mock.calls[0]?.[0])
    expect(message).toContain('500')
    // Der Fehlerpfad darf keine zweite, einwilligungsfreie Kopie der Messdaten
    // im Serverlog anlegen: kein Ziel, kein Cookie-Inhalt, keine Kennung.
    expect(message).not.toContain(TARGET)
    expect(message).not.toContain('amzn.to')
    expect(message).not.toContain(CONSENT_COOKIE_NAME)
    expect(message).not.toContain('accepted')
    expect(message).not.toContain(SESSION_ID)
    expect(message).not.toContain(SLUG)
  })

  it('meldet bei erfolgreichem Insert nichts', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    installFetch({ affiliateUrl: TARGET })

    await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    expect(warn).not.toHaveBeenCalled()
  })

  it('leitet ohne Server-Schluessel weiter und misst einfach nicht', async () => {
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', '')
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.inserts()).toHaveLength(0)
  })
})

describe('GET /api/click/[slug] — fail-closed beim Ziel', () => {
  it('faellt bei unbekanntem Slug auf die interne Produktseite zurueck', async () => {
    const net = installFetch({ affiliateUrl: null })

    const res = await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx('gibt-es-nicht'))

    expect(res.status).toBe(307)
    expect(res.headers.get('Location')).toBe('/produkt/gibt-es-nicht')
    expect(net.inserts()).toHaveLength(0)
  })

  it('faellt bei unsicherem Ziel auf die interne Produktseite zurueck', async () => {
    for (const unsafe of [
      'http://amzn.to/4mQqqTX',
      'https://evil.example/?u=https://amzn.to/4mQqqTX',
      'javascript:alert(1)',
      'https://amazon.de.evil.example/dp/B0',
    ]) {
      const net = installFetch({ affiliateUrl: unsafe })
      const res = await GET(consentedRequest(`?cs=${SESSION_ID}`), ctx())
      expect(res.headers.get('Location'), unsafe).toBe(`/produkt/${SLUG}`)
      expect(net.inserts(), unsafe).toHaveLength(0)
      vi.unstubAllGlobals()
    }
  })

  it('faellt bei formal ungueltigem Slug auf die Startseite zurueck und fragt nichts ab', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(makeRequest(), ctx('../../etc/passwd'))

    expect(res.headers.get('Location')).toBe('/')
    expect(net.lookups()).toHaveLength(0)
    expect(net.inserts()).toHaveLength(0)
  })

  it('faellt bei nicht erreichbarer Datenbank auf die interne Produktseite zurueck', async () => {
    const net = installFetch({ lookupFails: true })

    const res = await GET(makeRequest(), ctx())

    expect(res.headers.get('Location')).toBe(`/produkt/${SLUG}`)
    expect(net.inserts()).toHaveLength(0)
  })

  it('faellt ohne Lookup-Konfiguration auf die interne Produktseite zurueck', async () => {
    vi.stubEnv('NEXT_PUBLIC_SUPABASE_URL', '')
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(makeRequest(), ctx())

    expect(res.headers.get('Location')).toBe(`/produkt/${SLUG}`)
    expect(net.calls).toHaveLength(0)
  })

  it('akzeptiert NIEMALS ein Ziel aus einem Queryparameter', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(
      makeRequest(
        '?to=https%3A%2F%2Fevil.example&url=https%3A%2F%2Fevil.example&redirect=https%3A%2F%2Fevil.example'
      ),
      ctx()
    )

    // Das Ziel bleibt das serverseitig aufgeloeste Produktziel.
    expect(res.headers.get('Location')).toBe(TARGET)
    expect(net.lookups()).toHaveLength(1)
  })

  it('akzeptiert auch MIT Einwilligung kein Ziel aus einem Queryparameter', async () => {
    const net = installFetch({ affiliateUrl: TARGET })

    const res = await GET(
      consentedRequest(
        `?to=https%3A%2F%2Fevil.example&url=https%3A%2F%2Fevil.example&redirect=https%3A%2F%2Fevil.example&cs=${SESSION_ID}`
      ),
      ctx()
    )

    expect(res.headers.get('Location')).toBe(TARGET)
    // Und der Insert traegt weiterhin kein Ziel — nur den Slug.
    const body = JSON.parse(String(net.inserts()[0].init?.body))
    expect(JSON.stringify(body)).not.toContain('evil.example')
    expect(JSON.stringify(body)).not.toContain('amzn.to')
  })
})
