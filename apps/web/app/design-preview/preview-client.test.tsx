import type { ReactNode } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react'

vi.mock('next/navigation', () => ({ usePathname: () => '/design-preview' }))

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

import { PreviewClient } from './preview-client'
import { CONSENT_COOKIE_NAME } from '@/lib/consent-cookie'
import { CLICK_SESSION_STORAGE_KEY } from '@/lib/click-session'
import { consentStore } from '@/lib/consent'
import type { DbProduct } from '@/lib/db-types'

const SLUG = 'tre-feuerstahl-xxl'
const SESSION_ID = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'

function makeProduct(overrides: Partial<DbProduct> = {}): DbProduct {
  return {
    id: 'id-1',
    slug: SLUG,
    name: 'Feuerstahl XXL',
    tagline: 'Funke statt Feuerzeug.',
    description: null,
    price_cents: 1490,
    currency: 'EUR',
    affiliate_url: 'https://amzn.to/48jljFR',
    image_url: '/img/feuerstahl.jpg',
    image_urls: null,
    is_published: true,
    is_featured: false,
    category_id: null,
    categories: null,
    shop_persona: 'babo',
    shop_main_category: 'outdoor',
    shop_sub_category: null,
    amazon_category: null,
    brand: null,
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

function affiliateLinks(): HTMLAnchorElement[] {
  return Array.from(
    document.querySelectorAll<HTMLAnchorElement>('a[data-affiliate-slug]')
  )
}

function clearCookies() {
  for (const part of document.cookie.split(';')) {
    const name = part.split('=')[0]?.trim()
    if (name) document.cookie = `${name}=; Path=/; Max-Age=0`
  }
}

beforeEach(() => {
  clearCookies()
  consentStore.clearConsent()
  window.sessionStorage.clear()
  vi.stubGlobal('crypto', { randomUUID: () => SESSION_ID })
})

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
  clearCookies()
  window.sessionStorage.clear()
})

/**
 * Die `noindex`-Design-Werkbank ist keine Ausnahme von der Kennzeichnung: Der
 * Link dort ist ein echter Partnerlink, sobald ihn jemand aktiviert. Dass die
 * Seite intern ist, aendert daran nichts.
 *
 * Ein Rendertest statt eines Quelltext-Greps, weil hier drei Dinge gleichzeitig
 * gelten muessen — sichtbarer Hinweis, `aria-label` und abgeschaltete Messung —
 * und gerade die abgeschaltete Messung sich nur am Verhalten zeigt.
 */
describe('Design-Preview — Kennzeichnung des Partnerlinks', () => {
  it('macht das Overlay auch bei Tastaturfokus sichtbar und versteckt das dekorative Icon', () => {
    render(<PreviewClient products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    const overlay = cta.parentElement
    expect(overlay?.className).toContain('group-focus-within:opacity-100')
    expect(overlay?.className).toContain('group-focus-within:translate-y-0')
    expect(cta.querySelector('svg')?.getAttribute('aria-hidden')).toBe('true')
  })

  it('meldet aktive Theme- und Filter-Auswahlen', () => {
    render(<PreviewClient products={[makeProduct()]} />)

    const warm = screen.getByRole('button', { name: /Warm Editorial/ })
    const brutal = screen.getByRole('button', { name: /Clean Brutalist/ })
    const neueste = screen.getByRole('button', { name: 'Neueste' })
    const beliebt = screen.getByRole('button', { name: 'Beliebt' })

    expect(warm.getAttribute('aria-pressed')).toBe('true')
    expect(brutal.getAttribute('aria-pressed')).toBe('false')
    fireEvent.click(brutal)
    expect(brutal.getAttribute('aria-pressed')).toBe('true')
    expect(warm.getAttribute('aria-pressed')).toBe('false')
    expect(neueste.getAttribute('aria-pressed')).toBe('true')
    expect(beliebt.getAttribute('aria-pressed')).toBe('false')
    fireEvent.click(beliebt)
    expect(beliebt.getAttribute('aria-pressed')).toBe('true')
    expect(neueste.getAttribute('aria-pressed')).toBe('false')
  })

  it('zeigt die Kennzeichnung sichtbar unmittelbar am CTA', () => {
    render(<PreviewClient products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    const hinweis = screen.getByText('Anzeige · Affiliate-Link')

    // Im selben Hover-Container wie der Button und direkt davor: der Hinweis
    // erscheint also zusammen mit dem CTA, nicht irgendwo anders auf der Seite.
    expect(cta.previousElementSibling).toBe(hinweis)
    expect(hinweis.parentElement).toBe(cta.parentElement)
  })

  it('stellt dem aria-label die Kennzeichnung voran', () => {
    render(<PreviewClient products={[makeProduct()]} />)

    expect(affiliateLinks()[0].getAttribute('aria-label')).toBe(
      'Anzeige · Affiliate-Link — Amazon: Feuerstahl XXL'
    )
  })

  it('zaehlt trotz erteilter Einwilligung nicht — measurementEnabled={false}', () => {
    // Verhaltensbeleg statt Attributbeleg: mit Zustimmung wuerde ein messender
    // Link beim Anfassen ein `cs` anhaengen und eine Kennung im sessionStorage
    // anlegen. Beides darf hier nicht passieren, sonst verfaelschen
    // Design-Experimente die Zahlen der produktiven Seiten.
    document.cookie = `${CONSENT_COOKIE_NAME}=accepted; Path=/`

    render(<PreviewClient products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    fireEvent.pointerDown(cta)
    fireEvent.mouseDown(cta)
    act(() => cta.focus())
    fireEvent.click(cta)

    expect(cta.getAttribute('href')).toBe(`/api/click/${SLUG}?from=%2Fdesign-preview`)
    expect(cta.getAttribute('href')).not.toContain('cs=')
    expect(window.sessionStorage.getItem(CLICK_SESSION_STORAGE_KEY)).toBeNull()
  })

  it('haelt das Partnerziel aus dem Markup und behaelt rel und target', () => {
    render(<PreviewClient products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
    expect(cta.getAttribute('target')).toBe('_blank')
    expect(cta.className).toContain('touch-manipulation')
    expect(document.body.innerHTML).not.toContain('amzn.to')
  })
})
