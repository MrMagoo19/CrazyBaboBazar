import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

vi.mock('next/navigation', () => ({ usePathname: () => '/thema/tools' }))

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

import { ProductGrid } from './product-grid'
import type { DbProduct } from '@/lib/db-types'

function makeProduct(overrides: Partial<DbProduct> = {}): DbProduct {
  return {
    id: 'id-1',
    slug: 'tre-feuerstahl-xxl',
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

afterEach(cleanup)

describe('ProductGrid — Affiliate-CTA', () => {
  it('zeigt den CTA dauerhaft, ohne dass gehovert werden muss', () => {
    render(
      <ProductGrid
        products={[
          makeProduct(),
          makeProduct({ id: 'id-2', slug: 'rocketbook-wiederverwendbares-notizbuch-a4', name: 'Rocketbook' }),
        ]}
      />
    )

    const ctas = affiliateLinks()
    expect(ctas).toHaveLength(2)
    // Frueher lag der CTA in einem Container mit `opacity-0 group-hover:opacity-100`.
    // Genau das darf nicht zurueckkommen: auf Touch-Geraeten gibt es kein Hover.
    for (const cta of ctas) {
      expect(cta.className).not.toContain('opacity-0')
      let el: HTMLElement | null = cta
      while (el) {
        expect(el.className ?? '').not.toContain('opacity-0')
        el = el.parentElement
      }
    }
  })

  it('verlinkt auf die interne Klick-Route und nicht auf das Partnerziel', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.getAttribute('href')).toBe(
      '/api/click/tre-feuerstahl-xxl?from=%2Fthema%2Ftools'
    )
    expect(document.body.innerHTML).not.toContain('amzn.to')
  })

  it('behaelt Kennzeichnung und Zielfenster', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
    expect(cta.getAttribute('target')).toBe('_blank')

    // `rel="sponsored"` richtet sich an Suchmaschinen. Fuer Menschen zaehlt der
    // sichtbare Hinweis — und der muss UNMITTELBAR am CTA stehen, nicht als
    // Fussnote am Seitenende. Deshalb das direkt folgende Geschwisterelement.
    const hinweis = screen.getByText('Anzeige · Affiliate-Link')
    expect(cta.nextElementSibling).toBe(hinweis)
  })

  it('nennt im aria-label die Kennzeichnung, den Merchant UND das Produkt', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    // Ein `aria-label` ERSETZT den Linktext fuer Screenreader. Der sichtbare
    // Hinweis unter dem Button wird damit nicht mitgelesen — die Kennzeichnung
    // muss deshalb im Label selbst stehen, vor dem bisherigen Text.
    expect(affiliateLinks()[0].getAttribute('aria-label')).toBe(
      'Anzeige · Affiliate-Link — Bei Amazon ansehen: Feuerstahl XXL'
    )
  })
})

describe('ProductGrid — Semantik und Bedienbarkeit', () => {
  it('verschachtelt keine Links ineinander', () => {
    render(
      <ProductGrid
        products={[makeProduct(), makeProduct({ id: 'id-2', slug: 'ticktime-tk3-wuerfel-timer-countdown' })]}
      />
    )

    // Ein <a> in einem <a> ist ungueltiges HTML: der Browser bricht das
    // aeussere Element auf und Tastatur-/Screenreader-Reihenfolge wird
    // unvorhersehbar. Genau das war der alte Hover-CTA im Bild-Link.
    expect(document.querySelectorAll('a a')).toHaveLength(0)
  })

  it('gibt dem CTA ein ausreichend grosses Touch-Ziel', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    const minHeight = affiliateLinks()[0].style.minHeight
    expect(minHeight).toBe('44px')
    expect(affiliateLinks()[0].className).toContain('touch-manipulation')
    expect(affiliateLinks()[0].className).toContain('hover:brightness-95')
  })

  it('haelt jeden CTA in der Tab-Reihenfolge', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.tagName).toBe('A')
    expect(cta.hasAttribute('href')).toBe(true)
    expect(cta.getAttribute('tabindex')).toBeNull()
    expect(cta.getAttribute('aria-hidden')).toBeNull()
  })

  it('verlinkt weiterhin Bild und Titel auf die Produktseite', () => {
    render(<ProductGrid products={[makeProduct()]} />)

    const internal = Array.from(
      document.querySelectorAll<HTMLAnchorElement>('a[href="/produkt/tre-feuerstahl-xxl"]')
    )
    expect(internal.length).toBe(2)
  })
})

describe('ProductGrid — Designsystem bleibt erhalten', () => {
  // Farben werden je nach CSSOM-Implementierung als Hex oder als rgb()
  // zurueckgegeben. Beide Schreibweisen gelten.
  const GELB = /#ffe500|rgb\(255,\s*229,\s*0\)/i
  const SCHWARZ = /#0a0a0a|rgb\(10,\s*10,\s*10\)/i
  const PINK = /#ff6b9d|rgb\(255,\s*107,\s*157\)/i
  const WEISS = /#fff\b|#ffffff|rgb\(255,\s*255,\s*255\)/i

  it('faerbt den CTA in der babo-Persona-Farbe mit schwarzer Schrift', () => {
    render(<ProductGrid products={[makeProduct({ shop_persona: 'babo' })]} />)

    const style = affiliateLinks()[0].style
    expect(style.backgroundColor).toMatch(GELB)
    expect(style.color).toMatch(SCHWARZ)
  })

  it('nimmt fuer queen die Persona-Farbe mit hellem Text', () => {
    render(<ProductGrid products={[makeProduct({ shop_persona: 'queen' })]} />)

    const style = affiliateLinks()[0].style
    expect(style.backgroundColor).toMatch(PINK)
    expect(style.color).toMatch(WEISS)
  })

  it('gibt dem CTA die volle Kartenbreite', () => {
    render(<ProductGrid products={[makeProduct()]} />)
    expect(affiliateLinks()[0].className).toContain('w-full')
  })
})
