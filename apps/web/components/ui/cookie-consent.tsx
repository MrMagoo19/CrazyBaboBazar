'use client'

import { useSyncExternalStore } from 'react'
import Link from 'next/link'
import { consentStore } from '@/lib/consent'
import type { ConsentSnapshot } from '@/lib/consent-store'

// Eine gemeinsame Store-Instanz fuer Hinweis und Affiliate-Links (lib/consent.ts).
// Frueher legte diese Datei ihren eigenen Store an; die Affiliate-Links haetten
// eine Entscheidung dann erst nach einer Navigation mitbekommen.
//
// `setConsent` ist die EINZIGE Stelle, die den Consent-Cookie setzt — dieser
// Hinweis ist also die einzige Quelle einer Einwilligung. Das Aufraeumen der
// Sitzungskennung beim Ablehnen erledigt der Store selbst, damit es hier nicht
// vergessen werden kann.
const { subscribe, getSnapshot, getServerSnapshot, setConsent } = consentStore

export function CookieConsent() {
  const consent = useSyncExternalStore<ConsentSnapshot>(subscribe, getSnapshot, getServerSnapshot)

  // Noch keine Entscheidung gespeichert → Hinweis zeigen.
  // 'unknown' (SSR/Hydration) rendert ebenfalls nichts.
  if (consent !== null) return null

  return (
    <div
      role="dialog"
      aria-label="Cookie-Hinweis"
      style={{
        position: 'fixed',
        bottom: 0,
        left: 0,
        right: 0,
        // Bewusst hoeher als die mobile Sticky-CTA-Leiste (z-index 90):
        // der Hinweis darf nie verdeckt werden.
        zIndex: 200,
        backgroundColor: '#0A0A0A',
        borderTop: '4px solid #FFE500',
        paddingBottom: 'env(safe-area-inset-bottom)',
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
          Diese Website setzt <span className="text-white font-medium">keine Werbe- und keine
          Profiling-Cookies</span>. Wir nutzen{' '}
          <span className="text-white font-medium">Vercel Analytics</span>{' '}
          zur anonymen Besucherstatistik (ohne Cookies). Mit{' '}
          <span className="text-white font-medium">Akzeptieren</span> zählen wir zusätzlich, welcher
          Partnerlink angeklickt wurde. Dafür speichern wir Ihre Entscheidung — und nur sie, also
          „akzeptiert“ oder „abgelehnt“ — in einem funktionalen eigenen Cookie mit 182 Tagen
          Laufzeit, damit unser Server sie prüfen kann. Die zufällige Kennung des Klicks entsteht
          erst nach Ihrer Einwilligung, bleibt im sessionStorage des Browsers und endet mit dem Tab;
          sie steht nie im Cookie, IP-Adressen speichern wir nicht. Widerrufen können Sie jederzeit
          über „Datenschutz-Einstellungen“ im Fußbereich. Amazon kann beim Klick auf Affiliate-Links
          eigene Cookies setzen.{' '}
          <Link href="/datenschutz" className="text-[#FFE500] underline underline-offset-2 hover:text-white transition-colors">
            Datenschutzerklärung
          </Link>
        </p>

        {/* Buttons */}
        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={() => setConsent('declined')}
            className="text-xs font-bold text-[#888] hover:text-white transition-colors px-4 py-2 border border-[#333] hover:border-white"
          >
            Ablehnen
          </button>
          <button
            onClick={() => setConsent('accepted')}
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
