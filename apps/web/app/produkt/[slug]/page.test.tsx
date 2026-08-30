import type { ReactNode } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

import type { DbProduct } from '@/lib/db-types'

/* -------------------------------------------------------------------------- */
/* Mocks — kein Netz, keine Datenbank, kein App-Router                         */
/* -------------------------------------------------------------------------- */

const db = vi.hoisted(() => ({
  getProductBySlug: vi.fn(),
  getRelatedProducts: vi.fn(),
  getPublishedProducts: vi.fn(),
  getListsForProduct: vi.fn(),
}))

const notFoundMock = vi.hoisted(() => vi.fn(() => {
  throw new Error('NEXT_NOT_FOUND')
}))

vi.mock('@/lib/db', () => db)
vi.mock('@/lib/guides', () => ({ getGuidesForProduct: () => [] }))
vi.mock('next/navigation', () => ({
  notFound: notFoundMock,
  usePathname: () => '/produkt/rocketbook-wiederverwendbares-notizbuch-a4',
}))

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

vi.mock('next/image', async () => {
  const { createElement } = await import('react')
  const ImageMock = ({ src, alt }: { src: string; alt: string }) =>
    createElement('img', { src, alt })
  return { default: ImageMock }
})

import ProduktPage from './page'

/* -------------------------------------------------------------------------- */

const SLUG = 'rocketbook-wiederverwendbares-notizbuch-a4'
const TARGET = 'https://amzn.to/4cNdmu4'

function makeProduct(overrides: Partial<DbProduct> = {}): DbProduct {
  return {
    id: 'id-1',
    slug: SLUG,
    name: 'Rocketbook Notizbuch A4',
    tagline: 'Schreiben, scannen, wischen.',
    description:
      'Beschreibbar mit Frixion-Stiften.\nPer feuchtem Tuch komplett loeschbar.\nPer App an Cloud-Dienste sendbar.',
    price_cents: 3490,
    currency: 'EUR',
    affiliate_url: TARGET,
    image_url: '/img/rocketbook.jpg',
    image_urls: null,
    is_published: true,
    is_featured: false,
    category_id: null,
    categories: null,
    shop_persona: 'babo',
    shop_main_category: 'organisation',
    shop_sub_category: null,
    amazon_category: null,
    brand: 'Rocketbook',
    video_url: null,
    editorial_note: null,
    created_at: null,
    shop_tags: null,
    fuer_wen: null,
    nicht_fuer: null,
    key_fact: null,
    pros: null,
    cons: null,
    alternative_slug: null,
    alternative_reason: null,
    alternative_kind: null,
    ...overrides,
  }
}

async function renderPage(product: DbProduct | null = makeProduct()) {
  db.getProductBySlug.mockResolvedValue(product)
  db.getRelatedProducts.mockResolvedValue([])
  db.getListsForProduct.mockResolvedValue([])
  const ui = await ProduktPage({ params: Promise.resolve({ slug: SLUG }) })
  return render(ui)
}

function affiliateLinks(): HTMLAnchorElement[] {
  return Array.from(document.querySelectorAll<HTMLAnchorElement>('a[data-affiliate-slug]'))
}

beforeEach(() => {
  window.localStorage.clear()
  window.sessionStorage.clear()
})

afterEach(() => {
  cleanup()
  window.localStorage.clear()
  window.sessionStorage.clear()
})

/* -------------------------------------------------------------------------- */

describe('Produktseite — Affiliate-CTA', () => {
  it('fuehrt beide CTAs ueber die interne Klick-Route', async () => {
    await renderPage()

    const ctas = affiliateLinks()
    // Haupt-CTA in der Infospalte plus mobile Sticky-Leiste.
    expect(ctas).toHaveLength(2)
    for (const cta of ctas) {
      expect(cta.getAttribute('href')).toContain(`/api/click/${SLUG}`)
      expect(cta.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
      expect(cta.getAttribute('target')).toBe('_blank')
    }
    expect(document.body.innerHTML).not.toContain('amzn.to')
  })

  it('beschriftet den CTA merchant-genau', async () => {
    await renderPage()

    for (const cta of affiliateLinks()) {
      expect(cta.textContent).toContain('Bei Amazon ansehen')
    }
  })

  it('haelt den Affiliate-Hinweis auf der Seite', async () => {
    await renderPage()

    expect(screen.getByText('Affiliate-Hinweis')).toBeTruthy()
    expect(
      screen.getAllByText(/Als Amazon-Partner verdienen wir an qualifizierten Käufen/).length
    ).toBeGreaterThan(0)
  })
})

describe('Produktseite — unmittelbare Affiliate-Kennzeichnung', () => {
  it('stellt jedem CTA-aria-label die Kennzeichnung voran', async () => {
    await renderPage()

    // Ein `aria-label` ERSETZT den Linktext. Ein Hinweis, der nur daneben
    // steht, erreicht Screenreader deshalb nicht — er muss zusaetzlich ins
    // Label, und zwar VOR den Merchant-Text.
    const ctas = affiliateLinks()
    expect(ctas).toHaveLength(2)
    for (const cta of ctas) {
      expect(cta.getAttribute('aria-label')).toBe(
        'Anzeige · Affiliate-Link — Bei Amazon ansehen: Rocketbook Notizbuch A4'
      )
    }
  })

  it('kennzeichnet den Haupt-CTA direkt darueber — zusammen mit dem Partnersatz', async () => {
    await renderPage()

    const [haupt] = affiliateLinks()
    const hinweis = haupt.previousElementSibling as HTMLElement | null

    // Direkt davor, ohne Element dazwischen: frueher lag der Partnersatz hinter
    // dem ShareButton und damit optisch getrennt von dem Link, auf den er sich
    // bezieht.
    expect(hinweis).not.toBeNull()
    expect(hinweis!.textContent).toContain('Anzeige · Affiliate-Link')
    expect(hinweis!.textContent).toContain(
      'Als Amazon-Partner verdienen wir an qualifizierten Käufen. Kein Aufpreis für dich.'
    )
  })

  it('haelt den Partnersatz VOR dem ShareButton, nicht dahinter', async () => {
    await renderPage()

    const [haupt] = affiliateLinks()
    const hinweis = haupt.previousElementSibling as HTMLElement

    // Regressionsschutz gegen den alten Aufbau CTA → ShareButton → Hinweis.
    const share = screen.getByRole('button', { name: /teilen/i })
    expect(hinweis.compareDocumentPosition(share) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(haupt.compareDocumentPosition(share) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('kennzeichnet den Sticky-CTA sichtbar in derselben Leiste', async () => {
    await renderPage()

    const bar = screen.getByTestId('sticky-affiliate-bar')
    const sticky = affiliateLinks()[1]
    expect(bar.contains(sticky)).toBe(true)

    // Die Kennzeichnung ist das erste Element der Leiste und steht damit ueber
    // dem Button — nicht irgendwo weiter unten auf der Seite.
    const hinweis = bar.firstElementChild as HTMLElement
    expect(hinweis.textContent?.trim()).toBe('Anzeige · Affiliate-Link')
    expect(hinweis.compareDocumentPosition(sticky) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('kennzeichnet beide CTAs — nicht nur einen von beiden', async () => {
    await renderPage()

    // Genau zwei sichtbare Kennzeichnungen fuer genau zwei direkte CTAs.
    expect(screen.getAllByText('Anzeige · Affiliate-Link')).toHaveLength(2)
  })

  it('behaelt rel und target — die Kennzeichnung ersetzt sie nicht', async () => {
    await renderPage()

    for (const cta of affiliateLinks()) {
      expect(cta.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
      expect(cta.getAttribute('target')).toBe('_blank')
      expect(cta.getAttribute('href')).toContain(`/api/click/${SLUG}`)
    }
  })
})

describe('Produktseite — CTA steht oberhalb des Beschreibungstexts', () => {
  it('rendert den Haupt-CTA im Dokument VOR dem langen Beschreibungstext', async () => {
    await renderPage()

    const cta = affiliateLinks()[0]
    // getAllByText, weil sowohl das <p> als auch das darin liegende <span>
    // denselben Text tragen — der erste Treffer reicht fuer den Positionstest.
    const description = screen.getAllByText(/Beschreibbar mit Frixion-Stiften/)[0]

    // `compareDocumentPosition` liefert DOCUMENT_POSITION_FOLLOWING, wenn das
    // Argument NACH dem Referenzknoten steht.
    const relation = cta.compareDocumentPosition(description)
    expect(relation & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('zeigt das Preisband direkt beim CTA', async () => {
    await renderPage()

    expect(screen.getAllByText('20 – 50€').length).toBeGreaterThan(0)
  })

  it('bezeichnet das Preisband als Orientierung und verspricht keine Aktualitaet', async () => {
    await renderPage()

    // `price_cents` ist ein manuell gepflegter Wert. Eine Zusage wie "Aktueller
    // Preis auf Amazon" waere durch diese Datenquelle nicht gedeckt.
    expect(screen.getByText('Preisband zur Orientierung')).toBeTruthy()
    expect(screen.queryByText(/Aktueller Preis/)).toBeNull()
  })
})

describe('Produktseite — mobile Sticky-Leiste', () => {
  it('rendert die Leiste, blendet sie ab md aber aus', async () => {
    await renderPage()

    const bar = screen.getByTestId('sticky-affiliate-bar')
    expect(bar.className).toContain('md:hidden')
    expect(bar.className).toContain('fixed')
  })

  it('liegt unter dem Cookie-Hinweis und respektiert die Safe-Area', async () => {
    await renderPage()

    const bar = screen.getByTestId('sticky-affiliate-bar')
    // Der Cookie-Hinweis arbeitet mit z-index 200 — die Leiste muss darunter
    // bleiben, sonst verdeckt ein Verkaufselement die Einwilligung.
    expect(Number(bar.style.zIndex)).toBeLessThan(200)
    expect(bar.className).toContain('pb-[env(safe-area-inset-bottom)]')
  })

  it('haelt auf Mobil unten Platz frei, damit die Leiste nichts verdeckt', async () => {
    const { container } = await renderPage()

    const root = container.firstElementChild as HTMLElement
    expect(root.className).toContain('pb-24')
    expect(root.className).toContain('md:pb-0')
  })
})

describe('Produktseite — unveroeffentlichte Produkte', () => {
  it('ruft notFound auf, statt Metadaten oder Affiliate-Link zu zeigen', async () => {
    db.getProductBySlug.mockResolvedValue(null)

    await expect(
      ProduktPage({ params: Promise.resolve({ slug: 'gibt-es-nicht' }) })
    ).rejects.toThrow('NEXT_NOT_FOUND')
    expect(notFoundMock).toHaveBeenCalled()
  })
})
