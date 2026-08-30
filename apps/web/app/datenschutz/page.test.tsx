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
  it('nennt Anbieter, Rolle, verarbeitete Daten und Datenminimierung', () => {
    render(<DatenschutzPage />)

    const text = document.body.textContent ?? ''
    expect(text).toContain('Datenbankdienst und Empfänger')
    expect(text).toContain('Supabase, Inc.')
    expect(text).toContain('3500 S. DuPont Highway')
    expect(text).toContain('verarbeitet diese Daten in unserem Auftrag')
    expect(text).toContain('weder Ihre IP-Adresse noch Ihre vollständige Browserkennung')
  })

  it('nennt Drittlaender, Garantien und die Anbieterquellen', () => {
    render(<DatenschutzPage />)

    const text = document.body.textContent ?? ''
    expect(text).toContain('USA oder Singapur')
    expect(text).toContain('Standardvertragsklauseln der Europäischen Kommission')
    expect(text).toContain('Art. 46 Abs. 2 lit. c DSGVO')

    const privacy = screen.getByRole('link', { name: 'Datenschutzerklärung von Supabase' })
    const tia = screen.getByRole('link', { name: 'Transfer-Folgenabschätzung von Supabase' })
    expect(privacy.getAttribute('href')).toBe('https://supabase.com/privacy')
    expect(tia.getAttribute('href')).toBe(
      'https://supabase.com/downloads/docs/Supabase%2BTIA%2B250314.pdf'
    )
    expect(privacy.getAttribute('rel')).toBe('noopener noreferrer')
    expect(tia.getAttribute('rel')).toBe('noopener noreferrer')
  })

  it('behaelt die consent-gebundene Speicherdauer von hoechstens 12 Monaten', () => {
    render(<DatenschutzPage />)

    expect(document.body.textContent).toContain('spätestens nach 12 Monaten gelöscht')
  })
})
