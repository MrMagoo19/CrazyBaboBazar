'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'

const STORAGE_KEY = 'cbb-cookie-consent-v1'

type ConsentState = 'accepted' | 'declined'

export function CookieConsent() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (!stored) setVisible(true)
    } catch {
      setVisible(true)
    }
  }, [])

  const handleConsent = (value: ConsentState) => {
    try {
      localStorage.setItem(STORAGE_KEY, value)
    } catch {
      // privater Modus — kein localStorage
    }
    setVisible(false)
  }

  if (!visible) return null

  return (
    <>
      {/* Backdrop — blockiert Klicks auf die Seite */}
      <div className="fixed inset-0 z-[90] bg-[#0A0A0A]/70" aria-hidden="true" />

      {/* Modal — zentriert im Viewport */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Cookie-Einstellungen"
        className="fixed inset-0 z-[100] flex items-center justify-center p-4"
      >
        <div className="w-full max-w-lg bg-white border-2 border-[#0A0A0A] border-t-4 border-t-[#FFE500] px-8 py-8">

          {/* Label */}
          <div className="mb-2 text-[10px] font-black uppercase tracking-widest" style={{ background: '#FFE500', color: '#0A0A0A', display: 'inline-block', padding: '2px 8px' }}>
            Datenschutz &amp; Cookies
          </div>

          {/* Heading */}
          <h2 className="font-[family-name:var(--font-display)] font-extrabold text-xl text-[#0A0A0A] mb-3 mt-3">
            Bevor du weitermachst
          </h2>

          {/* Body */}
          <p className="text-sm text-[#555] leading-relaxed mb-6 max-w-2xl">
            Diese Website setzt <strong className="text-[#0A0A0A]">keine eigenen Cookies</strong>.
            Wenn du auf einen Amazon-Affiliate-Link klickst, kann Amazon Cookies setzen,
            um deinen Kauf unserer Empfehlung zuzuordnen — ohne Mehrkosten für dich.
            Mit „Akzeptieren" stimmst du dem zu und bestätigst, unsere{' '}
            <Link
              href="/datenschutz"
              className="text-[#FFE500] hover:text-[#FFE500] transition-colors underline underline-offset-2"
            >
              Datenschutzerklärung
            </Link>{' '}
            gelesen zu haben. Mit „Ablehnen" werden keine Tracking-Daten durch externe Dienste erhoben.
          </p>

          {/* Actions */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            <button
              onClick={() => handleConsent('accepted')}
              className="sm:w-auto text-sm font-bold bg-[#FFE500] text-[#0A0A0A] px-8 py-3 hover:bg-[#FFE500] transition-colors"
            >
              Akzeptieren
            </button>
            <button
              onClick={() => handleConsent('declined')}
              className="sm:w-auto text-sm font-bold border-2 border-[#0A0A0A] text-[#0A0A0A] px-8 py-3 hover:bg-[#F5F5F5] transition-colors"
            >
              Ablehnen
            </button>
            <Link
              href="/datenschutz"
              className="sm:ml-auto text-xs text-[#555] hover:text-[#0A0A0A] transition-colors self-center"
            >
              Mehr erfahren →
            </Link>
          </div>

        </div>
      </div>
    </>
  )
}
