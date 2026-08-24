import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { guides } from '@/lib/guides'
import { allPersonaCategoryPaths } from '@/lib/taxonomy'
import sitemap from './sitemap'

const BASE_URL = 'https://www.crazybabobazar.com'

type PersonaRow = { shop_persona: string | null; shop_main_category: string | null }

type Fixture = {
  products?: { slug: string; updated_at: string | null; created_at: string }[]
  lists?: { slug: string; created_at: string }[]
  personaRows?: PersonaRow[]
}

const DEFAULT_PRODUCTS = [{ slug: 'led-zauberwuerfel', updated_at: null, created_at: '2026-01-01T00:00:00Z' }]

/**
 * Ersetzt `fetch` durch einen Stub, der die drei Supabase-Queries der Sitemap
 * anhand der URL auseinanderhaelt. `failures` laesst die ersten n Versuche
 * fehlschlagen — so laesst sich die Retry-Logik pruefen, ohne echte Requests.
 */
function mockSupabase(fixture: Fixture, opts: { failures?: number; status?: number } = {}) {
  let remainingFailures = opts.failures ?? 0
  const calls: string[] = []

  // Bewusst ein einfaches Objekt statt `new Response`: `sitemap.ts` liest nur
  // `ok`, `status`, `statusText` und `json()`.
  const fetchMock = vi.fn(async (input: unknown) => {
    const url = String(input)
    calls.push(url)
    if (remainingFailures > 0) {
      remainingFailures--
      return { ok: false, status: opts.status ?? 500, statusText: 'Server Error', json: async () => ({}) }
    }
    let body: unknown
    if (url.includes('/lists?')) body = fixture.lists ?? []
    else if (url.includes('shop_persona')) body = fixture.personaRows ?? []
    else body = fixture.products ?? DEFAULT_PRODUCTS
    return { ok: true, status: 200, statusText: 'OK', json: async () => body }
  })

  vi.stubGlobal('fetch', fetchMock)
  return { fetchMock, calls }
}

const urls = (entries: { url: string }[]) => entries.map((e) => e.url)

beforeEach(() => {
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_URL', 'https://project.supabase.co')
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY', 'test-key')
  vi.spyOn(console, 'error').mockImplementation(() => {})
})

afterEach(() => {
  vi.unstubAllGlobals()
  vi.unstubAllEnvs()
})

describe('sitemap — Persona-Unterseiten', () => {
  it('gibt nur Persona/Kategorie-Paare aus, die eine Route haben', async () => {
    mockSupabase({
      personaRows: [
        // gueltig
        { shop_persona: 'babo', shop_main_category: 'gaming' },
        { shop_persona: 'queen', shop_main_category: 'beauty' },
        { shop_persona: 'miniboss', shop_main_category: 'spass' },
        // ungueltig: Kategorie existiert, aber nicht unter dieser Persona
        { shop_persona: 'queen', shop_main_category: 'gaming' },
        { shop_persona: 'babo', shop_main_category: 'kueche' },
        { shop_persona: 'miniboss', shop_main_category: 'outdoor' },
        // ungueltig: Kategorie hat gar keine Persona-Route
        { shop_persona: 'babo', shop_main_category: 'wellness' },
        { shop_persona: 'queen', shop_main_category: 'health' },
        // ungueltig: Persona unbekannt
        { shop_persona: 'wellness', shop_main_category: 'beauty' },
        { shop_persona: 'unknown', shop_main_category: 'gaming' },
      ],
    })

    const personaUrls = urls(await sitemap()).filter((u) =>
      /\/(babos|queens|miniboss)\/[^/]+$/.test(u.replace(BASE_URL, ''))
    )

    expect(personaUrls.sort()).toEqual(
      [`${BASE_URL}/babos/gaming`, `${BASE_URL}/queens/beauty`, `${BASE_URL}/miniboss/spass`].sort()
    )
  })

  it('erzeugt fuer jedes Paar der Taxonomie genau die passende URL', async () => {
    const valid = allPersonaCategoryPaths()
    mockSupabase({
      personaRows: valid.map((path) => {
        const [, route, category] = path.split('/')
        const personaByRoute: Record<string, string> = { babos: 'babo', queens: 'queen', miniboss: 'miniboss' }
        return { shop_persona: personaByRoute[route] ?? route, shop_main_category: category }
      }),
    })

    const all = urls(await sitemap())
    for (const path of valid) expect(all).toContain(`${BASE_URL}${path}`)
  })

  it('dedupliziert wiederholte Paare', async () => {
    mockSupabase({
      personaRows: Array.from({ length: 5 }, () => ({ shop_persona: 'babo', shop_main_category: 'tech' })),
    })
    const all = urls(await sitemap())
    expect(all.filter((u) => u === `${BASE_URL}/babos/tech`)).toHaveLength(1)
  })

  it('ueberspringt Zeilen ohne Persona oder Kategorie', async () => {
    mockSupabase({
      personaRows: [
        { shop_persona: null, shop_main_category: 'gaming' },
        { shop_persona: 'babo', shop_main_category: null },
      ],
    })
    const all = urls(await sitemap())
    expect(all.some((u) => u.includes('/babos/') || u.includes('/queens/'))).toBe(false)
  })
})

describe('sitemap — /thema', () => {
  it('leitet /thema nur aus DB-Kategorien mit echter Themenseite ab', async () => {
    mockSupabase({
      personaRows: [
        { shop_persona: 'babo', shop_main_category: 'tech' },
        { shop_persona: 'queen', shop_main_category: 'kueche' },
        // gueltige Persona-Kategorien ohne /thema-Konfiguration:
        { shop_persona: 'babo', shop_main_category: 'irrenhaus' },
        { shop_persona: 'queen', shop_main_category: 'geschenke' },
        { shop_persona: 'miniboss', shop_main_category: 'spass' },
      ],
    })

    const themaUrls = urls(await sitemap()).filter((u) => u.includes('/thema/'))
    expect(themaUrls.sort()).toEqual([`${BASE_URL}/thema/kueche`, `${BASE_URL}/thema/tech`].sort())
  })

  it('erzeugt keine /thema-URL fuer Kategorien, die es nur in der DB gibt', async () => {
    mockSupabase({
      personaRows: [{ shop_persona: 'babo', shop_main_category: 'wellness' }],
    })
    expect(urls(await sitemap()).some((u) => u.includes('/thema/'))).toBe(false)
  })
})

describe('sitemap — statische Seiten', () => {
  it('enthaelt den erreichbaren /guide-Hub', async () => {
    mockSupabase({})
    expect(urls(await sitemap())).toContain(`${BASE_URL}/guide`)
  })

  it('enthaelt weiterhin jede Guide-Detailseite', async () => {
    mockSupabase({})
    const all = urls(await sitemap())
    for (const g of guides) expect(all).toContain(`${BASE_URL}/guide/${g.slug}`)
  })

  it('enthaelt Produkte und Listen', async () => {
    mockSupabase({
      products: [{ slug: 'p1', updated_at: '2026-02-02T00:00:00Z', created_at: '2026-01-01T00:00:00Z' }],
      lists: [{ slug: 'l1', created_at: '2026-01-01T00:00:00Z' }],
    })
    const all = urls(await sitemap())
    expect(all).toContain(`${BASE_URL}/produkt/p1`)
    expect(all).toContain(`${BASE_URL}/listen/l1`)
  })

  it('liefert keine doppelten URLs', async () => {
    mockSupabase({
      personaRows: [
        { shop_persona: 'babo', shop_main_category: 'gaming' },
        { shop_persona: 'miniboss', shop_main_category: 'gaming' },
      ],
    })
    const all = urls(await sitemap())
    expect(new Set(all).size).toBe(all.length)
  })
})

describe('sitemap — Fail-closed und Retry', () => {
  it('wiederholt fehlgeschlagene Requests und liefert danach die volle Sitemap', async () => {
    // Ein Fehlschlag pro Query (drei parallele Queries) — Versuch 2 greift.
    const { fetchMock } = mockSupabase({ personaRows: [{ shop_persona: 'babo', shop_main_category: 'gaming' }] }, { failures: 3 })
    const all = urls(await sitemap())
    expect(fetchMock).toHaveBeenCalledTimes(6)
    expect(all).toContain(`${BASE_URL}/babos/gaming`)
  })

  it('wirft, statt eine gekuerzte Sitemap zu liefern', async () => {
    mockSupabase({}, { failures: 99 })
    await expect(sitemap()).rejects.toThrow(/nach 3 Versuchen fehlgeschlagen/)
  })

  it('wirft bei 0 veroeffentlichten Produkten', async () => {
    mockSupabase({ products: [] })
    await expect(sitemap()).rejects.toThrow(/0 veroeffentlichte Produkte/)
  })

  it('wirft ohne Supabase-Env', async () => {
    vi.stubEnv('NEXT_PUBLIC_SUPABASE_URL', '')
    mockSupabase({})
    await expect(sitemap()).rejects.toThrow(/Supabase env vars missing/)
  })
})
