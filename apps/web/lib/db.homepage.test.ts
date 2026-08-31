import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

/**
 * Der Startseiten-Helper wird gegen einen aufzeichnenden Supabase-Stub
 * geprueft. Getestet wird die Abfrage selbst — Filter, Sortierung und Limit —,
 * weil genau dort die Zusage steht: „nur veroeffentlicht, featured zuerst,
 * danach die neuesten, hoechstens zwoelf". Ein Test, der nur das Ergebnis
 * zaehlt, wuerde ein fehlendes `limit` nicht bemerken.
 */
const recorded = vi.hoisted(() => ({
  table: '',
  select: '',
  filters: [] as { column: string; value: unknown }[],
  orders: [] as { column: string; ascending: boolean | undefined }[],
  limit: undefined as number | undefined,
  data: null as unknown[] | null,
}))

vi.mock('@supabase/supabase-js', () => {
  // Explizit typisiert: ohne Annotation waere `builder` in seinem eigenen
  // Initialisierer implizit `any` und `strict` wuerde das ablehnen.
  type Builder = {
    select: (select: string) => Builder
    eq: (column: string, value: unknown) => Builder
    order: (column: string, opts?: { ascending?: boolean }) => Builder
    limit: (count: number) => Promise<{ data: unknown[] | null; error: null }>
  }

  const builder: Builder = {
    select(select) {
      recorded.select = select
      return builder
    },
    eq(column, value) {
      recorded.filters.push({ column, value })
      return builder
    },
    order(column, opts) {
      recorded.orders.push({ column, ascending: opts?.ascending })
      return builder
    },
    limit(count) {
      recorded.limit = count
      return Promise.resolve({ data: recorded.data, error: null })
    },
  }

  return {
    createClient: () => ({
      from(table: string) {
        recorded.table = table
        return builder
      },
    }),
  }
})

import { HOMEPAGE_HIGHLIGHT_LIMIT, getHomepageHighlights } from './db'

beforeEach(() => {
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_URL', 'https://project.supabase.co')
  vi.stubEnv('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY', 'test-key')
  recorded.table = ''
  recorded.select = ''
  recorded.filters = []
  recorded.orders = []
  recorded.limit = undefined
  recorded.data = []
})

afterEach(() => {
  vi.unstubAllEnvs()
})

describe('getHomepageHighlights', () => {
  it('begrenzt die Abfrage auf zwoelf Zeilen', async () => {
    await getHomepageHighlights()

    expect(HOMEPAGE_HIGHLIGHT_LIMIT).toBe(12)
    expect(recorded.limit).toBe(HOMEPAGE_HIGHLIGHT_LIMIT)
  })

  it('liest nur veroeffentlichte Produkte', async () => {
    await getHomepageHighlights()

    expect(recorded.table).toBe('products')
    expect(recorded.filters).toEqual([{ column: 'is_published', value: true }])
  })

  it('sortiert featured zuerst und danach die neuesten', async () => {
    await getHomepageHighlights()

    expect(recorded.orders).toEqual([
      { column: 'is_featured', ascending: false },
      { column: 'created_at', ascending: false },
    ])
  })

  it('gibt bei einem Lesefehler eine leere Liste statt null zurueck', async () => {
    recorded.data = null

    await expect(getHomepageHighlights()).resolves.toEqual([])
  })

  it('reicht die gelieferten Zeilen unveraendert durch', async () => {
    recorded.data = [{ slug: 'a' }, { slug: 'b' }]

    const products = await getHomepageHighlights()

    expect(products).toHaveLength(2)
    expect(products.length).toBeLessThanOrEqual(HOMEPAGE_HIGHLIGHT_LIMIT)
  })
})
