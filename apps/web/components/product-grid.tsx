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
const DEFAULT_COLOR = '#E85000'

function getAccent(product: DbProduct): string {
  return PERSONA_COLOR[product.shop_persona ?? ''] ?? DEFAULT_COLOR
}

export function ProductGrid({ products }: { products: DbProduct[] }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {products.map((product) => {
        const accent = getAccent(product)
        const isLight = ['#FFE500', '#B8FF3B', '#3BFFDC'].includes(accent)

        return (
          <div
            key={product.slug}
            className="group bg-white flex flex-col overflow-hidden rounded-2xl border border-[#E8E8E8] transition-all duration-200 hover:-translate-y-1 hover:shadow-xl"
            style={{ boxShadow: '0 2px 8px rgba(0,0,0,0.07)' }}
          >
            {/* ── Bild ── */}
            <Link href={`/produkt/${product.slug}`} className="block">
              <div className="relative w-full overflow-hidden rounded-t-2xl bg-[#F7F7F7]"
                   style={{ aspectRatio: '4/3' }}>
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
                    <span className="bg-[#0A0A0A] text-white text-[9px] font-black px-2 py-1 rounded-full uppercase tracking-wider">
                      ★ Top Pick
                    </span>
                  </div>
                )}

                {/* Amazon hover */}
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-all duration-300 flex items-end justify-end p-3">
                  <a
                    href={product.affiliate_url}
                    target="_blank"
                    rel="noopener noreferrer sponsored"
                    onClick={e => e.stopPropagation()}
                    className="flex items-center gap-1.5 text-[10px] font-black px-3 py-1.5 rounded-full opacity-0 group-hover:opacity-100 translate-y-2 group-hover:translate-y-0 transition-all duration-200 uppercase tracking-wide"
                    style={{ background: '#0A0A0A', color: '#fff' }}
                  >
                    Amazon <ExternalLink size={9} />
                  </a>
                </div>
              </div>
            </Link>

            {/* ── Card Body ── */}
            <div className="p-4 flex flex-col gap-3 flex-1">
              <Link href={`/produkt/${product.slug}`}>
                <h2 className="font-[family-name:var(--font-display)] font-black text-[1rem] leading-tight text-[#0A0A0A] line-clamp-2 group-hover:text-[#E85000] transition-colors"
                    style={{ letterSpacing: '-0.02em' }}>
                  {product.name}
                </h2>
              </Link>

              <p className="text-[#888] text-[12px] leading-snug line-clamp-2 flex-1">
                {product.tagline ?? product.description ?? ''}
              </p>

              {/* ── Footer Row (wie NFT-Card: links Kategorie, rechts Preis) ── */}
              <div className="flex items-center justify-between pt-3 border-t border-[#F0F0F0]">
                {/* Kategorie-Pill */}
                <span
                  className="text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-full"
                  style={{
                    background: accent,
                    color: isLight ? '#0A0A0A' : '#fff',
                  }}
                >
                  {product.shop_persona
                    ? `${product.shop_persona}${product.shop_main_category ? ' · ' + product.shop_main_category : ''}`
                    : 'Discover'}
                </span>

                {/* Preis-Badge */}
                <div className="text-right">
                  <div className="text-[10px] text-[#AAA] uppercase tracking-wider leading-none mb-0.5">Preis ca.</div>
                  <div className="font-black text-[1.1rem] text-[#0A0A0A] leading-none"
                       style={{ letterSpacing: '-0.03em' }}>
                    {formatPrice(product.price_cents)}<span className="text-[11px] font-bold text-[#E85000] ml-0.5">€</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
