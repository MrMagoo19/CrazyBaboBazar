'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { Product } from '@/lib/data'

const categoryEmoji: Record<string, string> = {
  'lustige-gadgets': '🎪',
  'buero-gadgets': '💼',
  'kuechen-gadgets': '🍳',
  'geschenke-maenner': '🎯',
  'geschenke-20-euro': '💸',
}

export function ProductGrid({ products }: { products: Product[] }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {products.map((product) => (
        <div
          key={product.slug}
          className="group bg-[#1C1C1C] flex flex-col overflow-hidden border-2 border-[#333333] hover:border-[#E85000] transition-colors duration-300"
        >
          {/* Image */}
          <Link href={`/produkt/${product.slug}`} className="block">
            <div className="relative w-full aspect-square bg-[#252525] overflow-hidden">
              {product.image ? (
                <Image
                  src={product.image}
                  alt={product.name}
                  fill
                  className="object-cover group-hover:scale-105 transition-transform duration-500"
                  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                />
              ) : (
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="text-8xl opacity-15 group-hover:opacity-30 transition-opacity select-none">
                    {categoryEmoji[product.categorySlug] ?? '📦'}
                  </span>
                </div>
              )}

              {/* Hover overlay */}
              <div className="absolute inset-0 bg-[#1C1C1C]/0 group-hover:bg-[#1C1C1C]/20 transition-colors duration-300" />

              {/* Tag */}
              {product.tag && (
                <div className="absolute top-3 left-3">
                  <span className="bg-[#E85000] text-[#1C1C1C] text-[10px] font-extrabold px-2 py-0.5 uppercase tracking-wider">
                    {product.tag}
                  </span>
                </div>
              )}

            </div>
          </Link>

          {/* Card body */}
          <div className="p-4 flex flex-col gap-3 flex-1">
            {/* Category + Stars */}
            <div className="flex items-center justify-between">
              <span className="text-[#6B6560] text-[10px] uppercase tracking-widest">
                {product.category}
              </span>
              <div className="flex gap-0.5" aria-label={`${product.rating} Sterne`}>
                {[1, 2, 3, 4, 5].map((s) => (
                  <span
                    key={s}
                    className={`text-[10px] ${s <= Math.round(product.rating) ? 'text-[#E85000]' : 'text-[#333333]'}`}
                  >
                    ★
                  </span>
                ))}
              </div>
            </div>

            {/* Title */}
            <Link href={`/produkt/${product.slug}`}>
              <h2 className="font-[family-name:var(--font-display)] font-bold text-base leading-tight text-[#F0EDE8] group-hover:text-[#E85000] transition-colors line-clamp-2">
                {product.name}
              </h2>
            </Link>

            {/* Description */}
            <p className="text-[#6B6560] text-xs leading-relaxed line-clamp-2 flex-1">
              {product.description}
            </p>

            {/* Buttons */}
            <div className="flex items-center gap-2 pt-2 border-t border-[#252525] mt-auto">
              <Link
                href={`/produkt/${product.slug}`}
                className="flex-1 text-center text-xs font-bold py-2 px-3 bg-[#252525] text-[#F0EDE8] hover:bg-[#E85000] hover:text-[#1C1C1C] transition-all duration-200"
              >
                Mehr lesen
              </Link>
              <a
                href={product.affiliateUrl}
                target="_blank"
                rel="noopener noreferrer sponsored"
                onClick={(e) => e.stopPropagation()}
                className="flex-1 text-center text-xs font-bold py-2 px-3 border border-[#E85000] text-[#E85000] hover:bg-[#E85000] hover:text-[#1C1C1C] transition-all duration-200 whitespace-nowrap"
              >
                Checkst du Amazon ↗
              </a>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
