'use client'

import { useSyncExternalStore } from 'react'
import Link from 'next/link'
import { createConsentStore, type ConsentSnapshot } from '@/lib/consent-store'

const { subscribe, getSnapshot, getServerSnapshot, setConsent } =
  createConsentStore('cbb-cookie-consent')

export function CookieBanner() {
  const consent = useSyncExternalStore<ConsentSnapshot>(subscribe, getSnapshot, getServerSnapshot)

  // SSR/Hydration ('unknown') oder bereits entschieden → nichts anzeigen
  if (consent !== null) return null

  return (
    <div
      role="dialog"
      aria-modal="false"
      aria-label="Cookie-Hinweis"
      className="fixed bottom-0 left-0 right-0 z-[100] border-t-2 border-[#0A0A0A] bg-white"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
        <div className="flex flex-col sm:flex-row sm:items-center gap-4">

          {/* Text */}
          <div className="flex-1 min-w-0">
            <p className="text-xs text-[#555] leading-relaxed">
              <strong className="text-[#0A0A0A]">Hinweis zu externen Diensten:</strong>{' '}
              Diese Website setzt keine eigenen Cookies. Wenn Sie auf einen Amazon-Affiliate-Link klicken,
              kann Amazon Cookies setzen, um Käufe Ihrer Session zuzuordnen.
              Mit Klick auf „Verstanden“ bestätigen Sie, dass Sie unsere{' '}
              <Link
                href="/datenschutz"
                className="text-[#FFE500] hover:text-[#FFE500] transition-colors underline underline-offset-2 whitespace-nowrap"
              >
                Datenschutzerklärung
              </Link>{' '}
              gelesen haben.
            </p>
          </div>

          {/* Buttons */}
          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => setConsent('declined')}
              className="text-xs text-[#555] hover:text-[#0A0A0A] transition-colors px-3 py-2 whitespace-nowrap"
              aria-label="Cookie-Hinweis schließen ohne Zustimmung"
            >
              Ablehnen
            </button>
            <button
              onClick={() => setConsent('accepted')}
              className="text-xs font-bold bg-[#FFE500] text-[#0A0A0A] px-4 py-2 hover:bg-[#FFE500] transition-colors whitespace-nowrap"
              aria-label="Datenschutzhinweis bestätigen"
            >
              Verstanden
            </button>
          </div>

        </div>
      </div>
    </div>
  )
}
