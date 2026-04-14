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
      <div className="fixed inset-0 z-[90] bg-[#1C1C1C]/70 backdrop-blur-sm" aria-hidden="true" />

      {/* Modal — zentriert im Viewport */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Cookie-Einstellungen"
        className="fixed inset-0 z-[100] flex items-center justify-center p-4"
      >
        <div className="w-full max-w-lg bg-[#1C1C1C] border border-[#333333] border-t-2 border-t-[#E85000] px-8 py-8">

          {/* Label */}
          <div className="mb-2 text-[#E85000] text-[10px] font-bold uppercase tracking-widest">
            Datenschutz &amp; Cookies
          </div>

          {/* Heading */}
          <h2 className="font-[family-name:var(--font-display)] font-extrabold text-xl text-[#F0EDE8] mb-3">
            Bevor du weitermachst
          </h2>

          {/* Body */}
          <p className="text-sm text-[#9E9890] leading-relaxed mb-6 max-w-2xl">
            Diese Website setzt <strong className="text-[#F0EDE8]">keine eigenen Cookies</strong>.
            Wenn du auf einen Amazon-Affiliate-Link klickst, kann Amazon Cookies setzen,
            um deinen Kauf unserer Empfehlung zuzuordnen — ohne Mehrkosten für dich.
            Mit „Akzeptieren" stimmst du dem zu und bestätigst, unsere{' '}
            <Link
              href="/datenschutz"
              className="text-[#E85000] hover:text-[#E8321C] transition-colors underline underline-offset-2"
            >
              Datenschutzerklärung
            </Link>{' '}
            gelesen zu haben. Mit „Ablehnen" werden keine Tracking-Daten durch externe Dienste erhoben.
          </p>

          {/* Actions */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            <button
              onClick={() => handleConsent('accepted')}
              className="sm:w-auto text-sm font-bold bg-[#E85000] text-[#1C1C1C] px-8 py-3 hover:bg-[#E8321C] transition-colors"
            >
              Akzeptieren
            </button>
            <button
              onClick={() => handleConsent('declined')}
              className="sm:w-auto text-sm font-bold border border-[#333333] text-[#9E9890] px-8 py-3 hover:border-[#9E9890] hover:text-[#F0EDE8] transition-colors"
            >
              Ablehnen
            </button>
            <Link
              href="/datenschutz"
              className="sm:ml-auto text-xs text-[#6B6560] hover:text-[#9E9890] transition-colors self-center"
            >
              Mehr erfahren →
            </Link>
          </div>

        </div>
      </div>
    </>
  )
}
