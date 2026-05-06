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
            className="w-full h-full min-h-[340px] bg-white hover:bg-white transition-colors"
          >
            {/* Image placeholder */}
            <div className="flex-1 flex items-center justify-center bg-[#F5F5F5] rounded-xl border border-[#E0E0E0] min-h-[160px] relative overflow-hidden">
              <span className="text-7xl opacity-20 group-hover:opacity-40 transition-opacity select-none">
                {product.categorySlug === 'lustige-gadgets' && '🎪'}
                {product.categorySlug === 'buero-gadgets' && '💼'}
                {product.categorySlug === 'kuechen-gadgets' && '🍳'}
                {product.categorySlug === 'geschenke-maenner' && '🎯'}
                {product.categorySlug === 'geschenke-20-euro' && '💸'}
              </span>
              {product.tag && (
                <span className="absolute top-3 left-3 bg-[#FFE500] text-[#0A0A0A] text-[10px] font-bold px-2 py-0.5 uppercase tracking-wide">
                  {product.tag}
                </span>
              )}
            </div>

            {/* Info */}
            <div className="flex flex-col gap-2">
              <div className="text-[#555] text-[10px] uppercase tracking-widest">
                {product.category}
              </div>
              <h3 className="font-[family-name:var(--font-body)] font-semibold text-base leading-tight text-[#0A0A0A] group-hover:text-[#0A0A0A] transition-colors">
                {product.name}
              </h3>
              <div className="flex items-center justify-between">
                <div className="flex gap-0.5" aria-label={`${product.rating} von 5 Sternen`}>
                  {[1, 2, 3, 4, 5].map((star) => (
                    <span
                      key={star}
                      className={`text-xs ${star <= Math.round(product.rating) ? 'text-[#FFE500]' : 'text-[#E0E0E0]'}`}
                    >
                      ★
                    </span>
                  ))}
                </div>
                <span className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">
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
