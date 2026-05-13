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
    } catch {}
    setVisible(false)
  }

  if (!visible) return null

  return (
    <div
      role="dialog"
      aria-label="Cookie-Hinweis"
      style={{
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 200,
        backgroundColor: '#0A0A0A',
        borderTop: '4px solid #FFE500',
      }}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex flex-col sm:flex-row items-start sm:items-center gap-4">

        {/* Text */}
        <p className="text-sm text-[#CCC] leading-relaxed flex-1">
          <span
            className="font-[family-name:var(--font-mono)] font-bold text-[10px] uppercase tracking-widest mr-2"
            style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 6px' }}
          >
            Cookies
          </span>
          Diese Website verwendet keine Tracking-Cookies. Wir nutzen{' '}
          <span className="text-white font-medium">Vercel Analytics</span>{' '}
          zur anonymen Besucherstatistik (ohne Cookies, DSGVO-konform). Amazon kann beim Klick auf Affiliate-Links eigene Cookies setzen.{' '}
          <Link href="/datenschutz" className="text-[#FFE500] underline underline-offset-2 hover:text-white transition-colors">
            Datenschutzerklärung
          </Link>
        </p>

        {/* Buttons */}
        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={() => handleConsent('declined')}
            className="text-xs font-bold text-[#888] hover:text-white transition-colors px-4 py-2 border border-[#333] hover:border-white"
          >
            Ablehnen
          </button>
          <button
            onClick={() => handleConsent('accepted')}
            className="text-xs font-black uppercase tracking-widest px-6 py-2 transition-colors"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A' }}
          >
            Akzeptieren
          </button>
        </div>

      </div>
    </div>
  )
}
