'use client'

import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink, ArrowRight } from 'lucide-react'

export function ProductGrid({ products }: { products: DbProduct[] }) {
  return (
    <div
      className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
      style={{ gap: 0, border: '2px solid #0A0A0A', borderRight: 'none', borderBottom: 'none' }}
    >
      {products.map((product) => (
        <div
          key={product.slug}
          className="group bg-white flex flex-col overflow-hidden relative border-r-2 border-b-2 border-[#0A0A0A]"
        >
          {/* Image */}
          <Link href={`/produkt/${product.slug}`} className="block">
            <div className="relative w-full aspect-[4/3] bg-white overflow-hidden border-b-2 border-[#0A0A0A]">
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

              {/* Badges */}
              <div className="absolute top-3 left-3 flex flex-col gap-1.5">
                {product.is_featured && (
                  <span className="bg-[#E85000] text-white text-[9px] font-black px-2 py-0.5 uppercase tracking-wider">
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
                  className="flex items-center gap-1.5 bg-[#E85000] text-white text-[10px] font-black px-3 py-1.5 uppercase tracking-wider"
                >
                  Amazon <ExternalLink size={10} />
                </a>
              </div>
            </div>
          </Link>

          {/* Card body */}
          <div className="p-4 flex flex-col gap-3 flex-1">
            <Link href={`/produkt/${product.slug}`}>
              <h2
                className="font-[family-name:var(--font-display)] font-black text-[0.85rem] leading-tight text-[#0A0A0A] line-clamp-2"
                style={{ letterSpacing: '-0.01em' }}
              >
                {product.name}
              </h2>
            </Link>

            <p className="text-[#555555] text-xs leading-relaxed line-clamp-2 flex-1">
              {product.tagline ?? product.description ?? ''}
            </p>

            <div className="flex items-center justify-between pt-3 border-t-2 border-[#0A0A0A] mt-auto">
              <div>
                <span className="font-black text-xl text-[#E85000]">
                  {formatPrice(product.price_cents)}
                </span>
                <span className="text-[#999999] text-[10px] ml-1">€ inkl. MwSt.</span>
              </div>

              <Link
                href={`/produkt/${product.slug}`}
                className="flex items-center gap-1 text-[10px] font-black text-[#0A0A0A] uppercase tracking-wider hover:text-[#E85000] transition-colors"
              >
                Details <ArrowRight size={10} />
              </Link>
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
