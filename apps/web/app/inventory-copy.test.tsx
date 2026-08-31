import type { ReactNode } from 'react'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

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

// `FilteredProducts` und `ListenGrid` werden hier bewusst NICHT mehr gemockt:
// die Startseite benutzt sie nicht mehr. Ein Mock wuerde die Regression
// verdecken, die der statische Test weiter unten festhaelt.
vi.mock('@/components/product-grid', () => ({
  ProductGrid: ({ products }: { products: unknown[] }) => <div data-testid="product-grid">{products.length} Produkte</div>,
}))

const dbMocks = vi.hoisted(() => ({
  getPublishedProductCount: vi.fn(),
  getPublishedProducts: vi.fn(),
  getHomepageHighlights: vi.fn(),
  getAllLists: vi.fn(),
}))
vi.mock('@/lib/db', () => dbMocks)

import HomePage, { metadata as homeMetadata } from './page'
import GeschenkePage, { metadata as geschenkeMetadata } from './geschenke/page'
import UeberUnsPage from './ueber-uns/page'

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

describe('Bestandsangaben bleiben mit den Produktdaten synchron', () => {
  it('rendert auf /ueber-uns die Read-only-Zaehluung und genau drei Personas', async () => {
    dbMocks.getPublishedProductCount.mockResolvedValue(372)

    render(await UeberUnsPage())

    expect(screen.getByText('372')).toBeTruthy()
    expect(screen.getByText('Personas — Babos, Queens und Miniboss')).toBeTruthy()
    expect(document.body.textContent).toContain('Drei davon haben wir kuratiert')
    expect(document.body.textContent).not.toContain('Wellness')
    expect(document.body.textContent).not.toContain('Vier davon')
  })

  it('erfindet bei einem Zaehlerfehler keine Null', async () => {
    dbMocks.getPublishedProductCount.mockResolvedValue(null)

    render(await UeberUnsPage())

    expect(screen.getByText('Viele')).toBeTruthy()
  })

  it('lädt für die Homepage nur die kuratierte Startauswahl', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue(Array.from({ length: 12 }, (_, id) => ({ id })))

    render(await HomePage())

    expect(document.body.textContent).toContain('Aktuelle Empfehlungen')
    expect(document.body.textContent).toContain('Noch keinen Plan? In der Swipe Area')
    expect(document.body.textContent).not.toContain('Swipe dich durch')
    expect(screen.getByTestId('product-grid').textContent).toContain('12 Produkte')
    expect(dbMocks.getHomepageHighlights).toHaveBeenCalledTimes(1)
    expect(screen.getByRole('heading', { level: 1 }).textContent).toContain('Geschenke, die nicht nach Standardliste aussehen.')
    expect(screen.getByRole('link', { name: /Zum Geschenkefinder/i }).getAttribute('href')).toBe('/geschenke')
  })

  it('gibt dem Raster hoechstens zwoelf Produkte und laedt keinen Vollkatalog', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue(
      Array.from({ length: 12 }, (_, id) => ({ id }))
    )

    render(await HomePage())

    const rendered = Number(
      screen.getByTestId('product-grid').textContent?.replace(/\D+/g, '') ?? NaN
    )
    expect(rendered).toBeLessThanOrEqual(12)
    // Der frühere Datenfluss lud den vollständigen Katalog UND alle Listen und
    // serialisierte beides in das HTML der Startseite.
    expect(dbMocks.getPublishedProducts).not.toHaveBeenCalled()
    expect(dbMocks.getAllLists).not.toHaveBeenCalled()
  })

  it('bleibt ohne Empfehlungen lesbar, statt ein leeres Raster zu zeigen', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue([])

    render(await HomePage())

    expect(screen.queryByTestId('product-grid')).toBeNull()
    expect(document.body.textContent).toContain('Gerade keine Empfehlungen verfügbar')
  })

  it('traegt genau eine H1', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue([])

    render(await HomePage())

    expect(screen.getAllByRole('heading', { level: 1 })).toHaveLength(1)
  })

  it('verlinkt sekundaer eine bestehende starke Auswahl und die fuenf kaufnahen Seiten', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue([])

    render(await HomePage())

    for (const href of [
      '/listen/witzige-geschenke-maenner',
      '/listen/geschenke-fuer-gamer',
      '/unter-10',
      '/guide/wichtelgeschenke-unter-20-euro',
      '/guide/geschenke-maenner-die-alles-haben',
    ]) {
      expect(document.querySelector(`a[href="${href}"]`), href).toBeTruthy()
    }
  })

  it('oeffnet Einstiege nach Empfaenger, Budget und Thema', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue([])

    render(await HomePage())

    for (const href of [
      '/babos',
      '/queens',
      '/miniboss',
      '/unter-20',
      '/unter-50',
      '/unter-100',
      '/thema/gaming',
      '/thema/kueche',
    ]) {
      expect(document.querySelector(`a[href="${href}"]`), href).toBeTruthy()
    }
  })

  it('zeigt Swipe nur klein am Ende und ohne Produktzaehlung', async () => {
    dbMocks.getHomepageHighlights.mockResolvedValue(
      Array.from({ length: 7 }, (_, id) => ({ id }))
    )

    render(await HomePage())

    expect(document.querySelectorAll('a[href="/entdecken"]')).toHaveLength(1)
    // Die alte Zeile nannte den Bestand ("Swipe dich durch 372 Produkte").
    expect(document.body.textContent).not.toMatch(/Swipe dich durch\s*\d/)
  })

  it('reicht den Vollkatalog nicht mehr an FilteredProducts und laedt keine Listen', () => {
    const homeSource = readFileSync(resolve(process.cwd(), 'app/page.tsx'), 'utf8')

    expect(homeSource).not.toContain('FilteredProducts')
    expect(homeSource).not.toContain('ListenGrid')
    expect(homeSource).not.toContain('getPublishedProducts')
    expect(homeSource).not.toContain('getAllLists')
    expect(homeSource).toContain('getHomepageHighlights')
  })

  it('haelt statische Metadaten und Root-OG ohne veraltete Festzahl', () => {
    const description = String(homeMetadata.description)
    const openGraphDescription = String(homeMetadata.openGraph?.description)
    const ogSource = readFileSync(resolve(process.cwd(), 'app/opengraph-image.tsx'), 'utf8')

    expect(description).not.toMatch(/\b(?:100|200|350)\+?\b/)
    expect(openGraphDescription).not.toMatch(/\b(?:100|200|350)\+?\b/)
    expect(ogSource).toContain('Handverlesene Produkte')
    expect(ogSource).not.toContain('100+')
  })
})

describe('Tech-Label ist in Navigation und Footer konsistent', () => {
  it('verwendet fuer /thema/tech das kanonische kurze Label', () => {
    const layout = readFileSync(resolve(process.cwd(), 'app/layout.tsx'), 'utf8')
    const nav = readFileSync(resolve(process.cwd(), 'components/ui/nav-menu.tsx'), 'utf8')

    expect(layout).toContain("{ href: '/thema/tech',       label: 'Tech' }")
    expect(nav).toContain('{ label: "Tech",')
    expect(layout).not.toContain("label: 'Tech & Setup'")
    expect(nav).not.toContain('label: "Tech & Setup"')
    expect(nav).toContain('href="/geschenke"')
    expect(layout).not.toContain('Swipe Area</span>')
  })
})

describe('Navigation — Geschenke zuerst, kein dominanter Header-Swipe', () => {
  const nav = readFileSync(resolve(process.cwd(), 'components/ui/nav-menu.tsx'), 'utf8')
  const layout = readFileSync(resolve(process.cwd(), 'app/layout.tsx'), 'utf8')
  const desktop = nav.slice(
    nav.indexOf('export function DesktopNav'),
    nav.indexOf('function MobileSheet')
  )
  const mobile = nav.slice(nav.indexOf('function MobileSheet'))

  it('haelt im Desktop-Menue die Reihenfolge Geschenke, Themen, Preis, Guides', () => {
    const markers = ['href="/geschenke"', '{/* Themen */}', '{/* Preis */}', '{/* Guides */}']
    const positions = markers.map((marker) => desktop.indexOf(marker))

    for (const [i, position] of positions.entries()) {
      expect(position, markers[i]).toBeGreaterThan(-1)
    }
    expect([...positions].sort((a, b) => a - b)).toEqual(positions)
  })

  it('fuehrt /listen nicht mehr als Top-Level-Punkt im Desktop-Menue', () => {
    expect(desktop).not.toContain('href="/listen"')
  })

  it('stellt Geschenke im Mobile-Menue vor Themen und Preis', () => {
    const geschenke = mobile.indexOf('href="/geschenke"')

    expect(geschenke).toBeGreaterThan(-1)
    expect(geschenke).toBeLessThan(mobile.indexOf('THEMEN.map'))
    expect(geschenke).toBeLessThan(mobile.indexOf('PREISE.map'))
  })

  it('nimmt den prominenten Swipe-Knopf aus dem Header, behaelt aber die Suche', () => {
    const header = layout.slice(layout.indexOf('<header'), layout.indexOf('</header>'))

    expect(header).not.toContain('/entdecken')
    expect(header).toContain('<NavSearch />')
  })
})

describe('/geschenke — Kundenreise-Hub', () => {
  it('zeigt genau eine H1 und verifizierte Einstiege für Person, Budget und Intent', () => {
    render(<GeschenkePage />)

    expect(screen.getAllByRole('heading', { level: 1 })).toHaveLength(1)
    expect(screen.getByRole('heading', { level: 1 }).textContent).toContain('Geschenke finden')
    for (const href of ['/babos', '/queens', '/miniboss', '/unter-10', '/unter-20', '/unter-50', '/unter-100', '/listen/geschenke-fuer-gamer']) {
      expect(document.querySelector(`a[href="${href}"]`), href).toBeTruthy()
    }
    expect(geschenkeMetadata.alternates?.canonical).toBe('/geschenke')
  })

  it('traegt eigene deutsche Metadaten ohne Markensuffix', () => {
    const title = String(geschenkeMetadata.title)

    expect(title).toBe('Geschenke finden — nach Empfänger, Budget und Anlass')
    // `title.template` im Root-Layout haengt den Markennamen an.
    expect(title).not.toContain('Crazy Babo Bazar')
    expect(String(geschenkeMetadata.description)).toContain('Geschenkefinder')
    expect(String(geschenkeMetadata.description).length).toBeGreaterThan(60)
  })

  it('verlinkt die fuenf kaufnahen Seiten und die Anlass-Guides', () => {
    render(<GeschenkePage />)

    for (const href of [
      '/listen/witzige-geschenke-maenner',
      '/listen/geschenke-fuer-gamer',
      '/unter-10',
      '/guide/wichtelgeschenke-unter-20-euro',
      '/guide/geschenke-maenner-die-alles-haben',
      '/guide/home-office-setup-anfaenger',
      '/guide/beste-kuechen-gadgets-2026',
      '/listen/camping-gadgets-sommer',
      '/listen/spieleabend-partyspiele-erwachsene',
      '/listen/schreibtisch-setup-gadgets',
      '/listen/verrueckte-amazon-gadgets',
      '/thema/gaming',
      '/thema/kueche',
      '/thema/outdoor',
    ]) {
      expect(document.querySelector(`a[href="${href}"]`), href).toBeTruthy()
    }
  })

  it('zeigt eine Brotkrumen-Navigation zurueck auf die Startseite', () => {
    render(<GeschenkePage />)

    const breadcrumb = screen.getByRole('navigation', { name: 'Brotkrumen' })
    expect(breadcrumb.querySelector('a[href="/"]')).toBeTruthy()
    expect(breadcrumb.textContent).toContain('Geschenke')
  })

  it('erzeugt keine duplizierenden Kind-Routen unter /geschenke', () => {
    render(<GeschenkePage />)

    const own = Array.from(document.querySelectorAll('a[href^="/geschenke/"]'))
    expect(own).toHaveLength(0)
  })

  it('behauptet weder Testsieger noch Bewertungen noch exakte Preise', () => {
    render(<GeschenkePage />)
    const text = document.body.textContent ?? ''

    for (const claim of ['Testsieger', 'Sterne', 'Bewertung', 'garantiert', 'Bestseller']) {
      expect(text, claim).not.toContain(claim)
    }
    // Preisbaender wie "Unter 20€" sind erlaubt, ein konkreter Preis nicht.
    expect(text).not.toMatch(/\d+,\d{2}\s*€/)
  })
})
