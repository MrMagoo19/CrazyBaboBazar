import type { ReactNode } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, render, screen } from '@testing-library/react'

// `vi.mock` wird von Vitest über alle Imports gehoben — SwipeDeck erhält beim
// Laden also bereits die Mocks unten und nie den echten Supabase-Client.
import { SwipeDeck } from './SwipeDeck'

/* -------------------------------------------------------------------------- */
/* Typen des Supabase-Mocks                                                    */
/* -------------------------------------------------------------------------- */

type SupabaseRow = Record<string, unknown>
type QueryError = { message: string; code?: string }
type QueryResult = { data: SupabaseRow[] | null; error: QueryError | null }
type QueryFilter = { type: 'eq' | 'in'; column: string; value: unknown }

/** Was eine einzelne Query am Ende der Kette tatsächlich angefragt hat. */
type QuerySpec = {
  table: string
  operation: 'select' | 'insert'
  columns: string
  filters: QueryFilter[]
  signal: AbortSignal | null
}

type Responder = (spec: QuerySpec) => QueryResult | Promise<QueryResult>

type ProductRow = {
  slug: string
  name: string
  tagline: string | null
  image_url: string | null
  price_cents: number | null
  shop_persona: string | null
  shop_main_category: string | null
}

/* -------------------------------------------------------------------------- */
/* Supabase-Mock: thenable Query-Builder, keinerlei Netzwerk                    */
/* -------------------------------------------------------------------------- */

const supabase = vi.hoisted(() => {
  const notConfigured: Responder = (spec) => {
    throw new Error(`Kein Supabase-Responder für Tabelle "${spec.table}" gesetzt`)
  }

  let responder: Responder = notConfigured
  const calls: QuerySpec[] = []

  const createQuery = (table: string) => {
    const spec: QuerySpec = {
      table,
      operation: 'select',
      columns: '',
      filters: [],
      signal: null,
    }

    // Jede Kettenmethode gibt denselben Builder zurück — genau wie PostgREST.
    // Aufgelöst wird erst beim `await` (siehe `then`), damit der Responder das
    // AbortSignal sieht, das die Kette am Ende gesetzt hat.
    const builder = {
      select(columns: string) {
        spec.columns = columns
        return builder
      },
      insert() {
        spec.operation = 'insert'
        return builder
      },
      eq(column: string, value: unknown) {
        spec.filters.push({ type: 'eq', column, value })
        return builder
      },
      in(column: string, value: unknown) {
        spec.filters.push({ type: 'in', column, value })
        return builder
      },
      order() {
        return builder
      },
      limit() {
        return builder
      },
      abortSignal(signal: AbortSignal) {
        spec.signal = signal
        return builder
      },
      then<TResult1 = QueryResult, TResult2 = never>(
        onfulfilled?: ((value: QueryResult) => TResult1 | PromiseLike<TResult1>) | null,
        onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
      ): PromiseLike<TResult1 | TResult2> {
        const snapshot: QuerySpec = { ...spec, filters: [...spec.filters] }
        calls.push(snapshot)
        return Promise.resolve()
          .then(() => responder(snapshot))
          .then(onfulfilled, onrejected)
      },
    }

    return builder
  }

  return {
    createClient: () => ({ from: (table: string) => createQuery(table) }),
    setResponder(next: Responder) {
      responder = next
    },
    callsFor(table: string) {
      return calls.filter((call) => call.table === table)
    },
    reset() {
      calls.length = 0
      responder = notConfigured
    },
  }
})

vi.mock('@/utils/supabase/client', () => ({ createClient: supabase.createClient }))

/* -------------------------------------------------------------------------- */
/* Visuelle Drittkomponenten — nur Darstellung, keine Deck-Logik                */
/* -------------------------------------------------------------------------- */

vi.mock('framer-motion', async () => {
  const { createElement, Fragment } = await import('react')

  const ANIMATION_ONLY_PROPS = new Set([
    'initial',
    'animate',
    'exit',
    'transition',
    'variants',
    'layout',
    'layoutId',
    'whileTap',
    'whileHover',
    'drag',
    'dragConstraints',
    'dragElastic',
    'onDrag',
    'onDragEnd',
  ])

  const createMotionComponent = (tag: string) =>
    function MotionMock(props: Record<string, unknown>) {
      const domProps: Record<string, unknown> = {}
      for (const [key, value] of Object.entries(props)) {
        if (!ANIMATION_ONLY_PROPS.has(key)) domProps[key] = value
      }
      return createElement(tag, domProps)
    }

  const cache: Record<string, ReturnType<typeof createMotionComponent> | undefined> = {}
  const motion = new Proxy(cache, {
    get(target, prop) {
      if (typeof prop !== 'string') return undefined
      const cached = target[prop]
      if (cached) return cached
      const created = createMotionComponent(prop)
      target[prop] = created
      return created
    },
  })

  return {
    motion,
    AnimatePresence: ({ children }: { children?: ReactNode }) =>
      createElement(Fragment, null, children),
  }
})

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

vi.mock('./SwipeCard', async () => {
  const { createElement } = await import('react')

  const SwipeCard = ({ product, priceBand }: { product: ProductRow; priceBand: string }) =>
    createElement(
      'article',
      null,
      createElement('h2', null, product.name),
      createElement('span', null, priceBand),
    )

  return { SwipeCard }
})

/* -------------------------------------------------------------------------- */
/* Fixtures & Helfer                                                           */
/* -------------------------------------------------------------------------- */

const SESSION_KEY = 'cbb-swipe-session'

const productRow = (slug: string, name: string, persona = 'babo'): ProductRow => ({
  slug,
  name,
  tagline: 'Kurz, laut, gut.',
  image_url: null,
  price_cents: 1999,
  shop_persona: persona,
  shop_main_category: 'tech',
})

const BOOMBOX = productRow('babo-boombox', 'Babo Boombox')

const isDeckQuery = (spec: QuerySpec) =>
  spec.table === 'products' && spec.columns.includes('price_cents')

const isLikedProductsQuery = (spec: QuerySpec) =>
  spec.table === 'products' && spec.filters.some((filter) => filter.type === 'in')

function createDeferred<T>() {
  let settle: (value: T) => void = () => {}
  const promise = new Promise<T>((resolve) => {
    settle = resolve
  })
  return { promise, resolve: (value: T) => settle(value) }
}

/**
 * Lässt alle offenen Microtasks durchlaufen (nur mit echten Timern verwenden).
 * `act` fängt dabei die daraus folgenden React-Updates ein.
 */
const flushPending = () =>
  act(async () => {
    await new Promise<void>((resolve) => setTimeout(resolve, 0))
  })

/** Query, die niemals von selbst antwortet — sie wartet auf das AbortSignal. */
const hangUntilAborted = (signal: AbortSignal | null) =>
  new Promise<QueryResult>((resolve) => {
    const aborted: QueryResult = {
      data: null,
      error: { message: 'AbortError: signal is aborted without reason', code: '20' },
    }
    if (!signal) return
    if (signal.aborted) {
      resolve(aborted)
      return
    }
    signal.addEventListener('abort', () => resolve(aborted), { once: true })
  })

/* -------------------------------------------------------------------------- */

describe('SwipeDeck', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  afterEach(() => {
    // Reihenfolge zählt: erst unmounten (Effect-Cleanup bricht laufende Loads ab
    // und löscht deren Timer), danach Timer und Mock-State zurücksetzen.
    cleanup()
    vi.useRealTimers()
    supabase.reset()
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('zeigt nach erfolgreichem Initial-Load die erste Karte', async () => {
    supabase.setResponder((spec) => {
      if (spec.table === 'swipes') return { data: [], error: null }
      if (isDeckQuery(spec)) return { data: [BOOMBOX], error: null }
      throw new Error(`Unerwartete Query: ${spec.table}/${spec.columns}`)
    })

    render(<SwipeDeck />)

    expect(await screen.findByText('1 verbleibend')).toBeTruthy()
    expect(screen.getByText('Babo Boombox')).toBeTruthy()
    expect(screen.queryByText('Deck klemmt')).toBeNull()
    expect(screen.queryByText('Alles gesehen!')).toBeNull()
  })

  it('zeigt bei sofortigem Supabase-Queryfehler den Fehlerzustand mit Retry', async () => {
    supabase.setResponder((spec) => {
      if (spec.table === 'swipes') {
        // PostgREST meldet Fehler als `error`-Feld, nicht als Rejection.
        return { data: null, error: { message: 'permission denied for table swipes', code: '42501' } }
      }
      throw new Error(`Nach dem Fehler darf keine weitere Query laufen: ${spec.table}`)
    })

    render(<SwipeDeck />)

    const alertBox = await screen.findByRole('alert')
    expect(alertBox.textContent).toContain('Deck klemmt')
    expect(screen.getByRole('button', { name: /nochmal versuchen/i })).toBeTruthy()
    expect(screen.queryByText('Lade Produkte…')).toBeNull()
    // Der Fehlerpfad darf die Produkt-Query gar nicht erst erreichen.
    expect(supabase.callsFor('products')).toHaveLength(0)
  })

  it('zeigt bei erschöpfter Session den Done-Screen statt des Fehlerzustands', async () => {
    const swipes = [
      { product_slug: 'babo-boombox', liked: true },
      { product_slug: 'queen-kanne', liked: true },
      { product_slug: 'mini-mop', liked: false },
    ]

    supabase.setResponder((spec) => {
      if (spec.table === 'swipes') return { data: swipes, error: null }
      if (isLikedProductsQuery(spec)) {
        return {
          data: [
            { slug: 'babo-boombox', shop_persona: 'babo' },
            { slug: 'queen-kanne', shop_persona: 'babo' },
          ],
          error: null,
        }
      }
      if (isDeckQuery(spec)) {
        // Katalog liefert nur bereits gesehene Slugs → cards === [] bei total > 0.
        return {
          data: [
            productRow('babo-boombox', 'Babo Boombox'),
            productRow('queen-kanne', 'Queen Kanne'),
            productRow('mini-mop', 'Mini Mop'),
          ],
          error: null,
        }
      }
      throw new Error(`Unerwartete Query: ${spec.table}/${spec.columns}`)
    })

    render(<SwipeDeck />)

    expect(await screen.findByText('Alles gesehen!')).toBeTruthy()

    const summary = screen.getByText(/Produkten geliked/)
    expect(summary.textContent?.replace(/\s+/g, ' ').trim()).toBe(
      'Du hast 2 von 3 Produkten geliked.',
    )
    expect(screen.queryByText('Deck klemmt')).toBeNull()
    expect(screen.queryByRole('alert')).toBeNull()
  })

  it('bricht einen hängenden Initial-Query nach 15 s per AbortSignal ab', async () => {
    vi.useFakeTimers()
    supabase.setResponder((spec) => hangUntilAborted(spec.signal))

    render(<SwipeDeck />)

    await act(async () => {
      await vi.advanceTimersByTimeAsync(14_999)
    })

    const [initialQuery] = supabase.callsFor('swipes')
    expect(initialQuery).toBeDefined()
    expect(initialQuery.signal).toBeInstanceOf(AbortSignal)
    expect(initialQuery.signal?.aborted).toBe(false)
    expect(screen.getByText('Lade Produkte…')).toBeTruthy()
    expect(screen.queryByText('Deck klemmt')).toBeNull()

    await act(async () => {
      await vi.advanceTimersByTimeAsync(1)
    })

    // Der Query wird wirklich abgebrochen, nicht nur sein Ergebnis ignoriert.
    expect(initialQuery.signal?.aborted).toBe(true)
    expect(screen.queryByText('Lade Produkte…')).toBeNull()
    expect(screen.getByText('Deck klemmt')).toBeTruthy()
  })

  it('startet bei zwei Retry-Klicks im selben Tick nur einen zusätzlichen Load', async () => {
    localStorage.setItem(SESSION_KEY, 'bestehende-session')

    const retrySwipes = createDeferred<QueryResult>()
    let swipeQueries = 0

    supabase.setResponder((spec) => {
      if (spec.table === 'swipes') {
        swipeQueries += 1
        if (swipeQueries === 1) {
          return { data: null, error: { message: 'connection reset', code: '08006' } }
        }
        // Der Retry bleibt kontrolliert offen, solange der Guard geprüft wird.
        return retrySwipes.promise
      }
      if (isDeckQuery(spec)) return { data: [BOOMBOX], error: null }
      throw new Error(`Unerwartete Query: ${spec.table}/${spec.columns}`)
    })

    render(<SwipeDeck />)

    const retryButton = await screen.findByRole('button', { name: /nochmal versuchen/i })

    // Beide Klicks im selben Tick: React flusht innerhalb von `act` erst am Ende,
    // der Button bleibt also für den zweiten Klick montiert.
    act(() => {
      retryButton.click()
      // Wäre der Button hier schon abgehängt, liefe der zweite Klick ins Leere
      // und der Guard würde gar nicht geprüft — deshalb hart absichern.
      expect(retryButton.isConnected).toBe(true)
      retryButton.click()
    })

    expect(screen.getByText('Lade Produkte…')).toBeTruthy()

    // Ausstehende Microtasks flushen, damit ein etwaiger zweiter Load seine
    // Query wirklich absetzen könnte, bevor gezählt wird.
    await flushPending()

    expect(supabase.callsFor('swipes')).toHaveLength(2)
    expect(localStorage.getItem(SESSION_KEY)).toBe('bestehende-session')
    expect(supabase.callsFor('swipes')[1].filters).toContainEqual({
      type: 'eq',
      column: 'session_id',
      value: 'bestehende-session',
    })

    // Kontrollierten Retry auflösen — sonst leaken Promise und Timeout-Timer.
    await act(async () => {
      retrySwipes.resolve({ data: [], error: null })
      await retrySwipes.promise
    })

    expect(await screen.findByText('1 verbleibend')).toBeTruthy()
    expect(supabase.callsFor('swipes')).toHaveLength(2)
    expect(localStorage.getItem(SESSION_KEY)).toBe('bestehende-session')
  })
})
