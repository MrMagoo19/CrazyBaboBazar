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

vi.mock('@/components/filtered-products', () => ({
  FilteredProducts: () => <div data-testid="filtered-products" />,
}))
vi.mock('@/components/listen-grid', () => ({
  ListenGrid: () => <div data-testid="listen-grid" />,
}))

const dbMocks = vi.hoisted(() => ({
  getPublishedProductCount: vi.fn(),
  getPublishedProducts: vi.fn(),
  getAllLists: vi.fn(),
}))
vi.mock('@/lib/db', () => dbMocks)

import HomePage, { metadata as homeMetadata } from './page'
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

  it('nutzt im Swipe-Text die bereits geladene Produktmenge', async () => {
    dbMocks.getPublishedProducts.mockResolvedValue(Array.from({ length: 7 }, (_, id) => ({ id })))
    dbMocks.getAllLists.mockResolvedValue([])

    render(await HomePage())

    expect(document.body.textContent).toContain('Swipe dich durch 7 Produkte')
    expect(document.body.textContent).not.toContain('350+')
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
  })
})
