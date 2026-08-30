'use client'

import { ExternalLink } from 'lucide-react'

import { merchantCtaLabel, resolveMerchant } from '@/lib/affiliate'
import { AFFILIATE_DISCLOSURE, affiliateAriaLabel } from '@/lib/affiliate-disclosure'
import { AffiliateLink } from '@/components/ui/affiliate-link'

/**
 * Mobile Sticky-CTA-Leiste der Produktseite.
 *
 * ENTSCHEIDUNGEN UND IHRE GRUENDE:
 *   * `md:hidden` — auf dem Desktop steht der CTA ohnehin oberhalb des Falzes
 *     in der rechten Spalte. Eine zusaetzliche fixe Leiste waere dort nur
 *     Verdeckung.
 *   * `zIndex: 90` liegt bewusst UNTER dem Cookie-Hinweis (zIndex 200). Solange
 *     der Hinweis offen ist, gewinnt er — die Einwilligungsentscheidung darf
 *     nie von einem Verkaufselement verdeckt werden.
 *   * `paddingBottom: env(safe-area-inset-bottom)` haelt die Leiste auf
 *     Geraeten mit Homebar/Notch aus dem Systembereich heraus.
 *   * Die Leiste rendert serverseitig mit; sie ist kein nachgeladenes Overlay
 *     und verschiebt deshalb nichts nach der Hydration.
 */
export function StickyAffiliateBar({
  slug,
  affiliateUrl,
  productName,
  priceBand,
}: {
  slug: string
  affiliateUrl: string | null
  productName: string
  priceBand: string
}) {
  const ctaLabel = merchantCtaLabel(resolveMerchant(affiliateUrl))

  return (
    <div
      // safe-area als Utility-Klasse statt als Inline-Style: so steht der Wert
      // im generierten Stylesheet und nicht im style-Attribut, wo ihn strenge
      // CSSOM-Implementierungen (etwa in Testumgebungen) als unbekannte
      // Funktion verwerfen wuerden.
      className="md:hidden fixed bottom-0 left-0 right-0 pb-[env(safe-area-inset-bottom)]"
      style={{
        zIndex: 90,
        backgroundColor: '#FFFFFF',
        borderTop: '2.5px solid #0A0A0A',
      }}
      data-testid="sticky-affiliate-bar"
    >
      {/* ── Kennzeichnung, volle Leistenbreite ──
          Die Leiste ist das einzige Verkaufselement, das dauerhaft im Bild
          steht — sie muss sich selbst erklaeren, ohne dass jemand zum
          Fussbereich scrollt. Eigene Zeile statt Text im Button: der Button
          traegt bereits die Merchant-Beschriftung, ein zweizeiliger Inhalt
          wuerde entweder die 48px-Hoehe sprengen oder die Beschriftung
          verkleinern. `leading-none` und die knappen Abstaende halten die
          Leiste unter den 96px (`pb-24`), die die Produktseite auf Mobil
          freihaelt. */}
      <p className="px-4 pt-2 pb-1 font-[family-name:var(--font-mono)] text-[10px] uppercase tracking-widest leading-none text-[#555]">
        {AFFILIATE_DISCLOSURE}
      </p>

      <div className="flex items-center gap-3 px-4 pb-2 pt-1">
        <div className="min-w-0">
          <div className="font-[family-name:var(--font-mono)] text-[9px] uppercase tracking-widest text-[#555]">
            Preisbereich
          </div>
          <div className="font-[family-name:var(--font-mono)] font-bold text-sm text-[#0A0A0A] truncate">
            {priceBand}
          </div>
        </div>

        <AffiliateLink
          slug={slug}
          affiliateUrl={affiliateUrl}
          // Die Kennzeichnungszeile steht daneben, nicht im Link — ein
          // `aria-label` ersetzt aber den Linktext, nicht die Umgebung. Der
          // Hinweis gehoert deshalb auch ins Label.
          ariaLabel={affiliateAriaLabel(`${ctaLabel}: ${productName}`)}
          // Hover-Rueckmeldung ueber die Deckkraft, nicht ueber `brightness`:
          // Der Button ist fast schwarz (#0A0A0A), ein `brightness(1.25)` hebt
          // ihn nur auf #0D0D0D — das sieht niemand. Gleichzeitig klemmt
          // derselbe Filter das Markengelb der Schrift auf #FFFF00 hoch, also
          // genau die Farbverschiebung, die hier nicht passieren soll.
          // `opacity` mischt den Button stattdessen gegen den weissen
          // Leistengrund auf, was sichtbar ist und den Farbton haelt: die
          // Flaeche geht auf rgb(35,35,35), das Gelb bleibt praktisch
          // unveraendert und der Kontrast dazwischen bleibt weit ueber 4,5:1.
          className="ml-auto flex items-center justify-center gap-2 flex-1 text-xs font-black uppercase tracking-widest transition-opacity hover:opacity-90"
          style={{
            minHeight: '48px',
            backgroundColor: '#0A0A0A',
            color: '#FFE500',
            border: '2.5px solid #0A0A0A',
          }}
        >
          {ctaLabel}
          <ExternalLink size={12} aria-hidden />
        </AffiliateLink>
      </div>
    </div>
  )
}
