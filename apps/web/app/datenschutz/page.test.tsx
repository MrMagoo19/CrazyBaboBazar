import type { ReactNode } from 'react'
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

import DatenschutzPage from './page'

afterEach(cleanup)

describe('Datenschutz — Supabase als Empfaenger der Klick-Messung', () => {
  it('nennt Anbieter, Rolle, Region, verarbeitete Daten und Datenminimierung', () => {
    render(<DatenschutzPage />)

    const text = document.body.textContent ?? ''
    expect(text).toContain('Datenbankdienst und Empfänger')
    expect(text).toContain('Supabase Pte. Ltd.')
    expect(text).toContain('65 Chulia Street')
    expect(text).toContain('Singapore 049513')
    expect(text).toContain('West EU (Ireland)')
    expect(text).toContain('eu-west-1')
    expect(text).toContain('verarbeitet diese Daten in unserem Auftrag')
    expect(text).toContain('weder Ihre IP-Adresse noch Ihre vollständige Browserkennung')
    expect(text).not.toContain('Supabase, Inc., c/o Incorporating')
    expect(text).not.toContain('Delaware, USA')
  })

  it('nennt Unterauftragsverarbeiter, Drittlaender, Garantien und die Anbieterquellen', () => {
    render(<DatenschutzPage />)

    const text = document.body.textContent ?? ''
    expect(text).toContain('Unterauftragsverarbeiter')
    expect(text).toContain('Amazon Web Services, Inc.')
    expect(text).toContain('Supabase, Inc. für den Support')
    expect(text).toContain('Standardvertragsklauseln der Europäischen Kommission')
    expect(text).toContain('Art. 46 Abs. 2 lit. c DSGVO')

    const dpa = screen.getByRole('link', { name: 'Auftragsverarbeitungsvereinbarung (DPA) von Supabase' })
    const subprocessors = screen.getByRole('link', { name: 'Liste der Unterauftragsverarbeiter von Supabase' })
    const privacy = screen.getByRole('link', { name: 'Datenschutzerklärung von Supabase' })
    expect(dpa.getAttribute('href')).toBe(
      'https://supabase.com/legal/customer-resources/data-processing-addendum'
    )
    expect(subprocessors.getAttribute('href')).toBe(
      'https://supabase.com/legal/customer-resources/subprocessor-list'
    )
    expect(privacy.getAttribute('href')).toBe('https://supabase.com/privacy')
    expect(dpa.getAttribute('rel')).toBe('noopener noreferrer')
    expect(subprocessors.getAttribute('rel')).toBe('noopener noreferrer')
    expect(privacy.getAttribute('rel')).toBe('noopener noreferrer')

    const allLinks = Array.from(document.querySelectorAll('a'))
    expect(
      allLinks.some(
        (link) =>
          link.getAttribute('href') ===
          'https://supabase.com/downloads/docs/Supabase%2BTIA%2B250314.pdf'
      )
    ).toBe(false)
    expect(screen.queryByRole('link', { name: 'Transfer-Folgenabschätzung von Supabase' })).toBeNull()
  })

  it('behaelt die consent-gebundene Speicherdauer von hoechstens 12 Monaten', () => {
    render(<DatenschutzPage />)

    expect(document.body.textContent).toContain('spätestens nach 12 Monaten gelöscht')
  })
})
