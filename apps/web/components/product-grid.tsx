'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { getPriceBand } from '@/lib/db-types'
import { isKnownPersona } from '@/lib/persona'
import { merchantCtaLabel, resolveMerchant } from '@/lib/affiliate'
import { AFFILIATE_DISCLOSURE, affiliateAriaLabel } from '@/lib/affiliate-disclosure'
import { AffiliateLink } from '@/components/ui/affiliate-link'
import { ExternalLink } from 'lucide-react'

const PERSONA_COLOR: Record<string, string> = {
  babo:     '#FFE500',
  queen:    '#FF6B9D',
  miniboss: '#3BFFDC',
}
const DEFAULT_COLOR = '#FFE500'

function getAccent(p: DbProduct) {
  return PERSONA_COLOR[p.shop_persona ?? ''] ?? DEFAULT_COLOR
}

export function ProductGrid({ products }: { products: DbProduct[] }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {products.map((product) => {
        const accent = getAccent(product)
        const isLight = ['#FFE500', '#B8FF3B', '#3BFFDC'].includes(accent)
        const onAccent = isLight ? '#0A0A0A' : '#fff'
        const ctaLabel = merchantCtaLabel(resolveMerchant(product.affiliate_url))

        return (
          <div
            key={product.slug}
            className="group bg-white flex flex-col overflow-hidden"
            style={{
              border: '2.5px solid #0A0A0A',
              boxShadow: '5px 5px 0px #0A0A0A',
              transition: 'box-shadow 0.1s ease, transform 0.1s ease',
            }}
            onMouseEnter={e => {
              const el = e.currentTarget as HTMLElement
              el.style.boxShadow = '2px 2px 0px #0A0A0A'
              el.style.transform = 'translate(3px, 3px)'
            }}
            onMouseLeave={e => {
              const el = e.currentTarget as HTMLElement
              el.style.boxShadow = '5px 5px 0px #0A0A0A'
              el.style.transform = 'translate(0,0)'
            }}
          >
            {/* ── Bild ──
                Der Affiliate-CTA lag frueher als <a> INNERHALB dieses <Link> und
                war nur im Hover sichtbar. Beides ist weg: verschachtelte Links
                sind ungueltiges HTML (der Browser bricht das aeussere <a> auf,
                Tastatur- und Screenreader-Navigation wird unvorhersehbar), und
                ein Hover-CTA existiert auf Touch-Geraeten praktisch nicht. Der
                CTA steht jetzt als eigenes Geschwisterelement im Karten-Footer. */}
            <Link href={`/produkt/${product.slug}`} className="block">
              <div
                className="relative w-full overflow-hidden bg-[#F5F5F5]"
                style={{ aspectRatio: '4/3', borderBottom: '2.5px solid #0A0A0A' }}
              >
                {product.image_url ? (
                  <Image
                    src={product.image_url}
                    alt={product.name}
                    fill
                    className="object-contain p-4 transition-transform duration-500 group-hover:scale-105"
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-5xl opacity-10">📦</div>
                )}

                {product.is_featured && (
                  <div className="absolute top-3 left-3">
                    <span
                      className="text-[9px] font-black px-2 py-1 uppercase tracking-widest"
                      style={{ background: '#0A0A0A', color: '#fff', border: '1.5px solid #0A0A0A' }}
                    >
                      ★ Top Pick
                    </span>
                  </div>
                )}
              </div>
            </Link>

            {/* ── Card Body ── */}
            <div className="flex flex-col flex-1 p-4 gap-3">
              <Link href={`/produkt/${product.slug}`}>
                <h2
                  className="font-[family-name:var(--font-body)] font-semibold text-[#0A0A0A] leading-snug line-clamp-2 group-hover:underline transition-colors"
                  style={{ fontSize: '0.95rem', letterSpacing: '0' }}
                >
                  {product.name}
                </h2>
              </Link>

              <p
                className="line-clamp-2 flex-1"
                style={{ color: '#333', fontSize: '12px', lineHeight: '1.55', fontWeight: 500 }}
              >
                {product.tagline ?? product.description ?? ''}
              </p>

              {/* ── Footer: Kategorie-Tag | Preis ── */}
              <div
                className="flex items-center justify-between pt-3"
                style={{ borderTop: '2px solid #0A0A0A' }}
              >
                {/* Persona-Pill — kantig, fett */}
                <span
                  className="font-[family-name:var(--font-mono)] font-bold uppercase tracking-widest"
                  style={{
                    fontSize: '9px',
                    background: accent,
                    color: onAccent,
                    border: '2px solid #0A0A0A',
                    padding: '3px 8px',
                  }}
                >
                  {isKnownPersona(product.shop_persona) ? product.shop_persona : 'CBB'}
                  {product.shop_main_category ? ` · ${product.shop_main_category}` : ''}
                </span>

                {/* Preisband */}
                <span
                  className="font-[family-name:var(--font-mono)] font-bold uppercase tracking-widest"
                  style={{
                    fontSize: '9px',
                    background: '#0A0A0A',
                    color: '#FFFFFF',
                    border: '2px solid #0A0A0A',
                    padding: '3px 8px',
                  }}
                >
                  {getPriceBand(product.price_cents)}
                </span>
              </div>

              {/* ── Affiliate-CTA — dauerhaft sichtbar, volle Kartenbreite ──
                  minHeight 44px ist die uebliche Mindestgroesse fuer ein
                  Touch-Ziel. Das aria-label wiederholt den Produktnamen, weil
                  auf einer Listenseite sonst zwanzig gleich benannte Links
                  nebeneinander stehen. Die sichtbare Kennzeichnung darunter
                  bleibt unveraendert; sie wird fuer Screenreader aber nicht
                  mitgelesen, sobald ein `aria-label` gesetzt ist — deshalb
                  steht sie zusaetzlich im Label. */}
              <AffiliateLink
                slug={product.slug}
                affiliateUrl={product.affiliate_url}
                ariaLabel={affiliateAriaLabel(`${ctaLabel}: ${product.name}`)}
                className="flex items-center justify-center gap-2 w-full text-[11px] font-black uppercase tracking-widest"
                style={{
                  minHeight: '44px',
                  // Longhand statt `background`/`border`-Kurzform: identische
                  // Darstellung, aber ein Wert, den auch strenge
                  // CSSOM-Implementierungen verlustfrei zurueckgeben — sonst
                  // liesse sich das Designsystem nicht testen.
                  backgroundColor: accent,
                  color: onAccent,
                  borderWidth: '2.5px',
                  borderStyle: 'solid',
                  borderColor: '#0A0A0A',
                  boxShadow: '3px 3px 0px #0A0A0A',
                }}
              >
                {ctaLabel}
                <ExternalLink size={12} aria-hidden />
              </AffiliateLink>

              <p className="text-[9px] text-[#777] text-center leading-tight">
                {AFFILIATE_DISCLOSURE}
              </p>
            </div>
          </div>
        )
      })}
    </div>
  )
}
