import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'

vi.mock('next/navigation', () => ({ usePathname: () => '/guides/outdoor' }))

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

import { GuideFinder } from './guide-finder'
import type { DbProduct } from '@/lib/db-types'

const SLUG = 'tre-feuerstahl-xxl'

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

afterEach(cleanup)

/**
 * Der GuideFinder ist die dritte Flaeche mit einem direkten Affiliate-CTA. Er
 * hatte bisher als einzige davon gar keine sichtbare Kennzeichnung — nur
 * `rel="sponsored"`, und das richtet sich an Suchmaschinen, nicht an Menschen.
 */
describe('GuideFinder — unmittelbare Affiliate-Kennzeichnung', () => {
  it('zeigt die Kennzeichnung sichtbar direkt am CTA', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    const hinweis = screen.getByText('Anzeige · Affiliate-Link')

    // Unmittelbar heisst: direkt folgendes Geschwisterelement im selben
    // Container. Ein allgemeiner Hinweis irgendwo weiter unten waere zu weit
    // weg vom Klick, um die kommerzielle Natur rechtzeitig zu zeigen.
    expect(cta.nextElementSibling).toBe(hinweis)
    expect(hinweis.getAttribute('aria-hidden')).toBeNull()
  })

  it('stellt dem aria-label die Kennzeichnung voran', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    // Der sichtbare Hinweis daneben wird nicht mitgelesen, sobald ein
    // `aria-label` gesetzt ist — es ersetzt den Linktext vollstaendig.
    expect(affiliateLinks()[0].getAttribute('aria-label')).toBe(
      'Anzeige · Affiliate-Link — Bei Amazon ansehen: Feuerstahl XXL'
    )
  })

  it('kennzeichnet jede Karte, nicht nur die erste', () => {
    render(
      <GuideFinder
        products={[
          makeProduct(),
          makeProduct({ id: 'id-2', slug: 'ticktime-tk3-wuerfel-timer-countdown', name: 'TickTime' }),
        ]}
      />
    )

    expect(affiliateLinks()).toHaveLength(2)
    expect(screen.getAllByText('Anzeige · Affiliate-Link')).toHaveLength(2)
  })
})

describe('GuideFinder — Linkstruktur bleibt unveraendert', () => {
  it('fuehrt ueber die interne Klick-Route und nicht auf das Partnerziel', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    expect(affiliateLinks()[0].getAttribute('href')).toBe(
      `/api/click/${SLUG}?from=%2Fguides%2Foutdoor`
    )
    expect(document.body.innerHTML).not.toContain('amzn.to')
  })

  it('behaelt rel und target', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.getAttribute('rel')).toBe('sponsored nofollow noopener noreferrer')
    expect(cta.getAttribute('target')).toBe('_blank')
  })

  it('behaelt den Merchant-Text im Button', () => {
    render(<GuideFinder products={[makeProduct()]} />)
    expect(affiliateLinks()[0].textContent).toContain('Amazon')
  })
})

describe('GuideFinder — Bedienbarkeit trotz zusaetzlicher Zeile', () => {
  it('haelt das Touch-Ziel bei mindestens 44px', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    // Die Kennzeichnung liegt AUSSERHALB des Links. Sie darf dessen
    // Mindesthoehe deshalb nicht anknabbern.
    expect(affiliateLinks()[0].style.minHeight).toBe('44px')
  })

  it('verschachtelt keine Links ineinander', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    // Die Kennzeichnung ist ein <span>, kein zweites <a>: ein <a> in einem <a>
    // ist ungueltiges HTML, der Browser bricht das aeussere Element auf.
    expect(document.querySelectorAll('a a')).toHaveLength(0)
  })

  it('haelt den CTA in der Tab-Reihenfolge', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    const [cta] = affiliateLinks()
    expect(cta.tagName).toBe('A')
    expect(cta.hasAttribute('href')).toBe(true)
    expect(cta.getAttribute('tabindex')).toBeNull()
    expect(cta.getAttribute('aria-hidden')).toBeNull()
  })

  it('verlinkt Bild und Titel weiterhin auf die Produktseite', () => {
    render(<GuideFinder products={[makeProduct()]} />)

    const internal = document.querySelectorAll(`a[href="/produkt/${SLUG}"]`)
    // Bild, Titel und der "Details"-Link.
    expect(internal.length).toBe(3)
  })
})
