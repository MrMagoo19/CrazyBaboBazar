'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { createClient } from '@/utils/supabase/client'
import { getPriceBand } from '@/lib/db-types'
import { Heart, RotateCcw, ArrowLeft } from 'lucide-react'

const SESSION_KEY = 'cbb-swipe-session'

type Product = {
  slug: string
  name: string
  tagline: string | null
  image_url: string | null
  price_cents: number | null
  shop_persona: string | null
}

export default function LikesPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      let sessionId: string | null = null
      try { sessionId = localStorage.getItem(SESSION_KEY) } catch {}

      if (!sessionId) { setLoading(false); return }

      const sb = createClient()

      // Get liked slugs for this session
      const { data: swipes } = await sb
        .from('swipes')
        .select('product_slug')
        .eq('session_id', sessionId)
        .eq('liked', true)

      if (!swipes || swipes.length === 0) { setLoading(false); return }

      const slugs = swipes.map((s) => s.product_slug)

      // Fetch those products
      const { data } = await sb
        .from('products')
        .select('slug, name, tagline, image_url, price_cents, shop_persona')
        .in('slug', slugs)
        .eq('is_published', true)

      setProducts(data ?? [])
      setLoading(false)
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-sm font-[family-name:var(--font-mono)] text-[#555] uppercase tracking-widest">Lade deine Likes…</p>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="border-b-2 border-[#0A0A0A] px-4 sm:px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/entdecken" className="text-[#555] hover:text-[#0A0A0A] transition-colors">
              <ArrowLeft size={18} />
            </Link>
            <div className="flex items-center gap-2">
              <Heart size={16} fill="#FFE500" color="#FFE500" />
              <span className="font-[family-name:var(--font-mono)] font-black text-sm uppercase tracking-widest text-[#0A0A0A]">
                Deine Likes
              </span>
              {products.length > 0 && (
                <span
                  className="font-[family-name:var(--font-mono)] text-[10px] font-bold"
                  style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '1px 6px' }}
                >
                  {products.length}
                </span>
              )}
            </div>
          </div>
          <Link
            href="/entdecken"
            className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] transition-colors text-[#555] hover:text-[#0A0A0A]"
          >
            <RotateCcw size={12} />
            Weiter swipen
          </Link>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
        {products.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <div className="text-5xl mb-4">💔</div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-2xl text-[#0A0A0A] mb-2">
              Noch keine Likes
            </h2>
            <p className="text-sm text-[#555] mb-6">Swipe erst ein paar Produkte nach rechts.</p>
            <Link
              href="/entdecken"
              className="text-sm font-black uppercase tracking-widest px-6 py-3 transition-colors font-[family-name:var(--font-mono)]"
              style={{ backgroundColor: '#FFE500', color: '#0A0A0A' }}
            >
              ♥ Jetzt entdecken
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {products.map((product) => (
              <Link
                key={product.slug}
                href={`/produkt/${product.slug}`}
                className="group flex flex-col border-2 border-[#0A0A0A] hover:border-[#FFE500] transition-colors"
              >
                {/* Image */}
                <div className="relative aspect-square bg-[#F5F5F5] border-b-2 border-[#0A0A0A]">
                  {product.image_url ? (
                    <Image
                      src={product.image_url}
                      alt={product.name}
                      fill
                      className="object-contain p-6"
                      unoptimized
                    />
                  ) : (
                    <div className="absolute inset-0 flex items-center justify-center text-5xl">📦</div>
                  )}
                </div>

                {/* Info */}
                <div className="p-4 flex flex-col gap-2 flex-1">
                  {product.shop_persona && (
                    <span
                      className="text-[9px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] w-fit"
                      style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 6px' }}
                    >
                      {product.shop_persona}
                    </span>
                  )}
                  <h3 className="font-[family-name:var(--font-display)] font-black text-[#0A0A0A] text-sm leading-tight group-hover:text-[#555] transition-colors">
                    {product.name}
                  </h3>
                  {product.tagline && (
                    <p className="text-xs text-[#555] line-clamp-2 flex-1">{product.tagline}</p>
                  )}
                  <div
                    className="text-xs font-bold font-[family-name:var(--font-mono)] mt-auto w-fit"
                    style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
                  >
                    {getPriceBand(product.price_cents ?? 0)}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
