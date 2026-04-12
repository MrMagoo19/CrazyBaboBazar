'use client'

import Link from 'next/link'
import { GlowCard } from '@/components/ui/spotlight-card'
import type { Product } from '@/lib/data'

const glowColors = ['yellow', 'orange', 'red'] as const

export function FeaturedProducts({ products }: { products: Product[] }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {products.map((product, i) => (
        <Link key={product.slug} href={`/produkt/${product.slug}`} className="block group">
          <GlowCard
            glowColor={glowColors[i % glowColors.length]}
            customSize
            className="w-full h-full min-h-[340px] bg-[#1C1C1C] hover:bg-[#1C1C1C] transition-colors"
          >
            {/* Image placeholder */}
            <div className="flex-1 flex items-center justify-center bg-[#252525] rounded-xl border border-[#333333] min-h-[160px] relative overflow-hidden">
              <span className="text-7xl opacity-20 group-hover:opacity-40 transition-opacity select-none">
                {product.categorySlug === 'lustige-gadgets' && '🎪'}
                {product.categorySlug === 'buero-gadgets' && '💼'}
                {product.categorySlug === 'kuechen-gadgets' && '🍳'}
                {product.categorySlug === 'geschenke-maenner' && '🎯'}
                {product.categorySlug === 'geschenke-20-euro' && '💸'}
              </span>
              {product.tag && (
                <span className="absolute top-3 left-3 bg-[#E8321C] text-[#F0EDE8] text-[10px] font-bold px-2 py-0.5 uppercase tracking-wide">
                  {product.tag}
                </span>
              )}
            </div>

            {/* Info */}
            <div className="flex flex-col gap-2">
              <div className="text-[#6B6560] text-[10px] uppercase tracking-widest">
                {product.category}
              </div>
              <h3 className="font-[family-name:var(--font-display)] font-bold text-base leading-tight text-[#F0EDE8] group-hover:text-[#E85000] transition-colors">
                {product.name}
              </h3>
              <div className="flex items-center justify-between">
                <div className="flex gap-0.5" aria-label={`${product.rating} von 5 Sternen`}>
                  {[1, 2, 3, 4, 5].map((star) => (
                    <span
                      key={star}
                      className={`text-xs ${star <= Math.round(product.rating) ? 'text-[#E85000]' : 'text-[#333333]'}`}
                    >
                      ★
                    </span>
                  ))}
                </div>
                <span className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8]">
                  {product.price}€
                </span>
              </div>
            </div>
          </GlowCard>
        </Link>
      ))}
    </div>
  )
}
