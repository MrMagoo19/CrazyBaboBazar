'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink } from 'lucide-react'

// NeoBrutalism accent colors per persona
const PERSONA_COLOR: Record<string, string> = {
  babo:     '#FFE500',  // electric yellow
  queen:    '#FF6B9D',  // hot pink
  miniboss: '#3BFFDC',  // cyan mint
  wellness: '#B8FF3B',  // lime green
}
const DEFAULT_COLOR = '#E85000'

function getAccent(product: DbProduct): string {
  return PERSONA_COLOR[product.shop_persona ?? ''] ?? DEFAULT_COLOR
}

export function ProductGrid({ products }: { products: DbProduct[] }) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 sm:gap-5">
      {products.map((product) => {
        const accent = getAccent(product)
        const isLight = ['#FFE500', '#B8FF3B', '#3BFFDC'].includes(accent)
        const labelColor = isLight ? '#0A0A0A' : '#FFFFFF'

        return (
          <div
            key={product.slug}
            className="group flex flex-col bg-white relative"
            style={{
              border: '2.5px solid #0A0A0A',
              boxShadow: '4px 4px 0px #0A0A0A',
              transition: 'box-shadow 0.12s ease, transform 0.12s ease',
            }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLElement).style.boxShadow = '2px 2px 0px #0A0A0A'
              ;(e.currentTarget as HTMLElement).style.transform = 'translate(2px, 2px)'
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLElement).style.boxShadow = '4px 4px 0px #0A0A0A'
              ;(e.currentTarget as HTMLElement).style.transform = 'translate(0,0)'
            }}
          >
            {/* ── Kategorie-Streifen (Trading Card Header) ── */}
            <div
              className="flex items-center justify-between px-2.5 py-1.5"
              style={{ background: accent, borderBottom: '2.5px solid #0A0A0A' }}
            >
              <span
                className="text-[9px] font-black uppercase tracking-widest truncate"
                style={{ color: labelColor }}
              >
                {product.shop_persona && product.shop_main_category
                  ? `${product.shop_persona} · ${product.shop_main_category}`
                  : 'Crazy Babo Bazar'}
              </span>
              {product.is_featured && (
                <span className="text-[8px] font-black uppercase tracking-wider bg-[#0A0A0A] text-white px-1.5 py-0.5 ml-1 shrink-0">
                  ★ TOP
                </span>
              )}
            </div>

            {/* ── Bild ── */}
            <Link href={`/produkt/${product.slug}`} className="block">
              <div
                className="relative w-full overflow-hidden"
                style={{ aspectRatio: '1/1', background: '#FAFAFA', borderBottom: '2.5px solid #0A0A0A' }}
              >
                {product.image_url ? (
                  <Image
                    src={product.image_url}
                    alt={product.name}
                    fill
                    className="object-contain p-3 transition-transform duration-300 group-hover:scale-105"
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-4xl opacity-10">📦</div>
                )}

                {/* Amazon Quick-Link */}
                <div className="absolute bottom-2 right-2 opacity-0 group-hover:opacity-100 transition-all duration-200 translate-y-1 group-hover:translate-y-0">
                  <a
                    href={product.affiliate_url}
                    target="_blank"
                    rel="noopener noreferrer sponsored"
                    onClick={e => e.stopPropagation()}
                    className="flex items-center gap-1 text-[9px] font-black uppercase tracking-wide px-2 py-1"
                    style={{ background: accent, color: labelColor, border: '1.5px solid #0A0A0A' }}
                  >
                    Amazon <ExternalLink size={8} />
                  </a>
                </div>
              </div>
            </Link>

            {/* ── Card Body ── */}
            <div className="flex flex-col flex-1 p-3 gap-2">
              <Link href={`/produkt/${product.slug}`}>
                <h2
                  className="font-[family-name:var(--font-display)] font-black text-[0.78rem] leading-tight text-[#0A0A0A] line-clamp-2"
                  style={{ letterSpacing: '-0.01em' }}
                >
                  {product.name}
                </h2>
              </Link>

              <p className="text-[#666] text-[11px] leading-snug line-clamp-2 flex-1">
                {product.tagline ?? ''}
              </p>

              {/* ── Preis-Footer (Trading Card Stats) ── */}
              <div
                className="flex items-center justify-between pt-2 mt-auto"
                style={{ borderTop: '2px solid #0A0A0A' }}
              >
                <div
                  className="px-2 py-0.5"
                  style={{ background: accent, border: '1.5px solid #0A0A0A' }}
                >
                  <span
                    className="font-black text-base leading-none"
                    style={{ color: isLight ? '#0A0A0A' : '#0A0A0A', letterSpacing: '-0.03em' }}
                  >
                    {formatPrice(product.price_cents)}€
                  </span>
                </div>
                <Link
                  href={`/produkt/${product.slug}`}
                  className="text-[9px] font-black uppercase tracking-wider text-[#0A0A0A] hover:text-[#E85000] transition-colors"
                >
                  Mehr →
                </Link>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
