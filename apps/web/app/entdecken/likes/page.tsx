'use client'

import { useEffect, useState, useCallback, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import Image from 'next/image'
import Link from 'next/link'
import { createClient } from '@/utils/supabase/client'
import { getPriceBand } from '@/lib/db-types'
import { Heart, RotateCcw, ArrowLeft, Share2, Check } from 'lucide-react'

const SESSION_KEY = 'cbb-swipe-session'

type Product = {
  slug: string
  name: string
  tagline: string | null
  image_url: string | null
  price_cents: number | null
  shop_persona: string | null
}

function LikesContent() {
  const searchParams = useSearchParams()
  const sharedSession = searchParams.get('session')

  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [ownSessionId, setOwnSessionId] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)

  const isSharedView = !!sharedSession

  useEffect(() => {
    async function load() {
      // Determine which session to load
      let sessionId: string | null = sharedSession
      if (!sessionId) {
        try { sessionId = localStorage.getItem(SESSION_KEY) } catch {}
        if (sessionId) setOwnSessionId(sessionId)
      }

      if (!sessionId) { setLoading(false); return }

      const sb = createClient()

      const { data: swipes } = await sb
        .from('swipes')
        .select('product_slug')
        .eq('session_id', sessionId)
        .eq('liked', true)

      if (!swipes || swipes.length === 0) { setLoading(false); return }

      const slugs = swipes.map((s) => s.product_slug)

      const { data } = await sb
        .from('products')
        .select('slug, name, tagline, image_url, price_cents, shop_persona')
        .in('slug', slugs)
        .eq('is_published', true)

      setProducts(data ?? [])
      setLoading(false)
    }
    load()
  }, [sharedSession])

  const handleShare = useCallback(async () => {
    const sessionId = ownSessionId
    if (!sessionId) return
    const url = `${window.location.origin}/entdecken/likes?session=${sessionId}`
    try {
      if (navigator.share) {
        await navigator.share({ title: 'Meine Babo-Liste', url })
      } else {
        await navigator.clipboard.writeText(url)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      }
    } catch {}
  }, [ownSessionId])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-sm font-[family-name:var(--font-mono)] text-[#555] uppercase tracking-widest">
          Lade Babo-Liste…
        </p>
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
                {isSharedView ? 'Babo-Liste' : 'Meine Babo-Liste'}
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

          <div className="flex items-center gap-3">
            {/* Share button — only on own list with products */}
            {!isSharedView && products.length > 0 && (
              <button
                onClick={handleShare}
                className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] transition-colors px-3 py-1.5"
                style={{ backgroundColor: copied ? '#0A0A0A' : '#FFE500', color: copied ? '#FFE500' : '#0A0A0A' }}
              >
                {copied ? <Check size={11} /> : <Share2 size={11} />}
                {copied ? 'Kopiert!' : 'Teilen'}
              </button>
            )}

            {!isSharedView && (
              <Link
                href="/entdecken"
                className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] transition-colors text-[#555] hover:text-[#0A0A0A]"
              >
                <RotateCcw size={12} />
                Weiter swipen
              </Link>
            )}
          </div>
        </div>
      </div>

      {/* Shared view banner */}
      {isSharedView && (
        <div style={{ backgroundColor: '#FFE500', borderBottom: '2px solid #0A0A0A' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
            <p className="text-xs font-bold text-[#0A0A0A] font-[family-name:var(--font-mono)]">
              Jemand hat dir diese Babo-Liste geteilt.
            </p>
            <Link
              href="/entdecken"
              className="text-[10px] font-black uppercase tracking-widest text-[#0A0A0A] font-[family-name:var(--font-mono)] underline"
            >
              Eigene Liste erstellen →
            </Link>
          </div>
        </div>
      )}

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
        {products.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <div className="text-5xl mb-4">💔</div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-2xl text-[#0A0A0A] mb-2">
              {isSharedView ? 'Diese Liste ist leer' : 'Noch keine Likes'}
            </h2>
            <p className="text-sm text-[#555] mb-6">
              {isSharedView ? 'Die geteilte Liste enthält keine Produkte.' : 'Swipe erst ein paar Produkte nach rechts.'}
            </p>
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

export default function LikesPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-sm font-[family-name:var(--font-mono)] text-[#555] uppercase tracking-widest">Lade…</p>
      </div>
    }>
      <LikesContent />
    </Suspense>
  )
}
