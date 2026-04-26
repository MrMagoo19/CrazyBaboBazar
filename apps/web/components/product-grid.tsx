'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink, ArrowRight } from 'lucide-react'

export function ProductGrid({ products }: { products: DbProduct[] }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-px bg-[#252525]">
      {products.map((product) => {

        return (
          <div
            key={product.slug}
            className="group bg-[#1C1C1C] flex flex-col overflow-hidden relative"
          >
            {/* Image */}
            <Link href={`/produkt/${product.slug}`} className="block">
              <div className="relative w-full aspect-[4/3] bg-[#141414] overflow-hidden">
                {product.image_url ? (
                  <Image
                    src={product.image_url}
                    alt={product.name}
                    fill
                    className="object-contain p-4 transition-transform duration-500 group-hover:scale-105"
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-6xl opacity-10">
                    📦
                  </div>
                )}

                {/* Hover overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1C]/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

                {/* Badges */}
                <div className="absolute top-3 left-3 flex flex-col gap-1.5">
                  {product.is_featured && (
                    <span className="bg-[#E85000] text-[#1C1C1C] text-[9px] font-extrabold px-2 py-0.5 uppercase tracking-wider">
                      TOP PICK
                    </span>
                  )}
                </div>

                {/* Quick Amazon link on hover */}
                <div className="absolute bottom-3 right-3 opacity-0 group-hover:opacity-100 transition-all duration-300 translate-y-2 group-hover:translate-y-0">
                  <a
                    href={product.affiliate_url}
                    target="_blank"
                    rel="noopener noreferrer sponsored"
                    onClick={(e) => e.stopPropagation()}
                    className="flex items-center gap-1.5 bg-[#E85000] text-[#1C1C1C] text-[10px] font-extrabold px-3 py-1.5 hover:bg-[#E8321C] transition-colors"
                  >
                    Amazon <ExternalLink size={10} />
                  </a>
                </div>
              </div>
            </Link>

            {/* Card body */}
            <div className="p-5 flex flex-col gap-3 flex-1">
              <Link href={`/produkt/${product.slug}`}>
                <h2 className="font-[family-name:var(--font-display)] font-bold text-[1rem] leading-snug text-[#F0EDE8] group-hover:text-[#E85000] transition-colors line-clamp-2">
                  {product.name}
                </h2>
              </Link>

              <p className="text-[#6B6560] text-xs leading-relaxed line-clamp-2 flex-1">
                {product.tagline ?? product.description ?? ''}
              </p>

              <div className="flex items-center justify-between pt-3 border-t border-[#252525] mt-auto">
                <span className="font-[family-name:var(--font-display)] font-extrabold text-base text-[#F0EDE8]">
                  {formatPrice(product.price_cents)}
                  <span className="text-[#6B6560] text-[10px] font-normal ml-1">€ inkl. MwSt.</span>
                </span>

                <Link
                  href={`/produkt/${product.slug}`}
                  className="flex items-center gap-1 text-xs font-bold text-[#E85000] hover:gap-2 transition-all duration-200"
                >
                  Details <ArrowRight size={12} />
                </Link>
              </div>
            </div>

            {/* Bottom border accent on hover */}
            <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-[#E85000] scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left" />
          </div>
        )
      })}
    </div>
  )
}
