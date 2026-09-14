import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

import { guides } from '@/lib/guides'

/* -------------------------------------------------------------------------- */
/* Mocks — kein Netz, keine Datenbank, kein App-Router                         */
/* -------------------------------------------------------------------------- */

const db = vi.hoisted(() => ({
  getPublishedProducts: vi.fn(async () => []),
}))

vi.mock('@/lib/db', () => db)
vi.mock('next/navigation', () => ({ usePathname: () => '/guide' }))

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

import GuideOverviewPage from './page'

/* -------------------------------------------------------------------------- */

afterEach(() => {
  cleanup()
})

describe('Guide-Uebersicht — Cover', () => {
  it('zeigt fuer jeden Guide ein Cover mit beschreibendem Alt-Text', async () => {
    const ui = await GuideOverviewPage()
    render(ui)

    for (const g of guides) {
      const img = screen.getByAltText(`Cover-Grafik zum Guide „${g.title}“`)
      expect(img.getAttribute('src')).toBe(g.cover)
    }
  })
})
