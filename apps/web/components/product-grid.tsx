'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink } from 'lucide-react'

const PERSONA_COLOR: Record<string, string> = {
  babo:     '#FFE500',
  queen:    '#FF6B9D',
  miniboss: '#3BFFDC',
  wellness: '#B8FF3B',
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
            {/* ── Bild ── */}
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

                {/* Amazon Hover */}
                <div className="absolute bottom-3 right-3 opacity-0 group-hover:opacity-100 translate-y-2 group-hover:translate-y-0 transition-all duration-200">
                  <a
                    href={product.affiliate_url}
                    target="_blank"
                    rel="noopener noreferrer sponsored"
                    onClick={e => e.stopPropagation()}
                    className="flex items-center gap-1.5 text-[10px] font-black px-3 py-1.5 uppercase tracking-wider"
                    style={{ background: accent, color: onAccent, border: '2px solid #0A0A0A' }}
                  >
                    Amazon <ExternalLink size={9} />
                  </a>
                </div>
              </div>
            </Link>

            {/* ── Card Body ── */}
            <div className="flex flex-col flex-1 p-4 gap-3">
              <Link href={`/produkt/${product.slug}`}>
                <h2
                  className="font-[family-name:var(--font-display)] font-black text-[#0A0A0A] leading-tight line-clamp-2 group-hover:underline transition-colors"
                  style={{ fontSize: '1.05rem', letterSpacing: '-0.03em' }}
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
                  className="font-black uppercase tracking-widest"
                  style={{
                    fontSize: '9px',
                    background: accent,
                    color: onAccent,
                    border: '2px solid #0A0A0A',
                    padding: '3px 8px',
                  }}
                >
                  {product.shop_persona ?? 'CBB'}
                  {product.shop_main_category ? ` · ${product.shop_main_category}` : ''}
                </span>

                {/* Preis */}
                <div className="text-right">
                  <span
                    className="font-[family-name:var(--font-display)] font-black leading-none"
                    style={{ fontSize: '1.35rem', letterSpacing: '-0.04em', color: '#0A0A0A' }}
                  >
                    {formatPrice(product.price_cents)}
                    <span style={{ fontSize: '0.75rem', color: '#0A0A0A', marginLeft: '2px' }}>€</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
