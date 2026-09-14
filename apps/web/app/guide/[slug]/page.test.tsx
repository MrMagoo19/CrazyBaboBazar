import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

import { guides } from '@/lib/guides'

/* -------------------------------------------------------------------------- */
/* Mocks — kein Netz, keine Datenbank, kein App-Router                         */
/* -------------------------------------------------------------------------- */

const db = vi.hoisted(() => ({
  getProductsBySlugs: vi.fn(async () => []),
}))

vi.mock('@/lib/db', () => db)

vi.mock('next/navigation', () => ({
  notFound: vi.fn(() => {
    throw new Error('NEXT_NOT_FOUND')
  }),
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

import GuidePage from './page'

/* -------------------------------------------------------------------------- */

const SLUG = guides[0].slug
const GUIDE = guides[0]

afterEach(() => {
  cleanup()
})

describe('Guide-Detailseite — Cover', () => {
  it('zeigt das Cover als breite Hero-Grafik mit beschreibendem Alt-Text', async () => {
    const ui = await GuidePage({ params: Promise.resolve({ slug: SLUG }) })
    render(ui)

    const hero = screen.getByAltText(`Cover-Grafik zum Guide „${GUIDE.title}“`)
    expect(hero.getAttribute('src')).toBe(GUIDE.cover)
  })

  it('traegt das Cover als absolute Bild-URL im Article-JSON-LD', async () => {
    const ui = await GuidePage({ params: Promise.resolve({ slug: SLUG }) })
    const { container } = render(ui)

    const scripts = Array.from(container.querySelectorAll('script[type="application/ld+json"]'))
    const articleScript = scripts.find((s) => s.textContent?.includes('"@type":"Article"'))
    expect(articleScript).toBeTruthy()

    const schema = JSON.parse(articleScript!.textContent!)
    expect(schema.image).toEqual([`https://www.crazybabobazar.com${GUIDE.cover}`])
  })
})
