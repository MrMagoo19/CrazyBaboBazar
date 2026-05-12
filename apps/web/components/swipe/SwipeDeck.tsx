'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { AnimatePresence } from 'framer-motion'
import { createClient } from '@/utils/supabase/client'
import { getPriceBand } from '@/lib/db-types'
import { SwipeCard } from './SwipeCard'
import { Heart, RotateCcw, Flame } from 'lucide-react'
import Link from 'next/link'

type Product = {
  slug: string
  name: string
  tagline: string | null
  image_url: string | null
  price_cents: number | null
  shop_persona: string | null
  shop_main_category: string | null
}

const SESSION_KEY = 'cbb-swipe-session'
const REFILL_THRESHOLD = 4

function getOrCreateSession(): string {
  try {
    let id = localStorage.getItem(SESSION_KEY)
    if (!id) {
      id = crypto.randomUUID()
      localStorage.setItem(SESSION_KEY, id)
    }
    return id
  } catch {
    return crypto.randomUUID()
  }
}

export function SwipeDeck() {
  const [cards, setCards] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [done, setDone] = useState(false)
  const [likes, setLikes] = useState(0)
  const [total, setTotal] = useState(0)

  // persona weights: { babo: 3, queen: 1, ... }
  const personaWeights = useRef<Record<string, number>>({})
  const seenSlugs = useRef<Set<string>>(new Set())
  const sessionId = useRef<string>('')

  const fetchProducts = useCallback(async (weighted = false) => {
    const sb = createClient()

    // Build persona filter based on weights
    let personaFilter: string | null = null
    if (weighted) {
      const sorted = Object.entries(personaWeights.current).sort((a, b) => b[1] - a[1])
      if (sorted.length > 0 && sorted[0][1] > 0) {
        personaFilter = sorted[0][0]
      }
    }

    let query = sb
      .from('products')
      .select('slug, name, tagline, image_url, price_cents, shop_persona, shop_main_category')
      .eq('is_published', true)
      .limit(20)

    if (personaFilter) {
      query = query.eq('shop_persona', personaFilter)
    }

    const { data } = await query
    if (!data) return []

    // Filter out already seen
    return data.filter((p) => !seenSlugs.current.has(p.slug))
  }, [])

  const loadInitial = useCallback(async () => {
    setLoading(true)
    sessionId.current = getOrCreateSession()

    const sb = createClient()

    // Load already-swiped slugs + liked status
    const { data: swipeData } = await sb
      .from('swipes')
      .select('product_slug, liked')
      .eq('session_id', sessionId.current)

    let hasPriorLikes = false

    if (swipeData && swipeData.length > 0) {
      swipeData.forEach((s) => seenSlugs.current.add(s.product_slug))
      const likedSlugs = swipeData.filter((s) => s.liked).map((s) => s.product_slug)
      setLikes(likedSlugs.length)
      setTotal(swipeData.length)

      // Restore persona weights from previously liked products
      if (likedSlugs.length > 0) {
        hasPriorLikes = true
        const { data: likedProducts } = await sb
          .from('products')
          .select('slug, shop_persona')
          .in('slug', likedSlugs)

        if (likedProducts) {
          likedProducts.forEach((p) => {
            if (p.shop_persona) {
              personaWeights.current[p.shop_persona] =
                (personaWeights.current[p.shop_persona] ?? 0) + 1
            }
          })
        }
      }
    }

    const products = await fetchProducts(hasPriorLikes)
    const shuffled = [...products].sort(() => Math.random() - 0.5)
    shuffled.forEach((p) => seenSlugs.current.add(p.slug))
    setCards(shuffled)
    setLoading(false)
  }, [fetchProducts])

  useEffect(() => {
    loadInitial()
  }, [loadInitial])

  const refillIfNeeded = useCallback(async () => {
    if (cards.length <= REFILL_THRESHOLD) {
      const more = await fetchProducts(true)
      if (more.length === 0) {
        // Try unweighted
        const fallback = await fetchProducts(false)
        if (fallback.length === 0) {
          setDone(true)
          return
        }
        const newCards = fallback.filter((p) => !seenSlugs.current.has(p.slug))
        newCards.forEach((p) => seenSlugs.current.add(p.slug))
        setCards((prev) => [...prev, ...newCards])
      } else {
        const newCards = more.filter((p) => !seenSlugs.current.has(p.slug))
        newCards.forEach((p) => seenSlugs.current.add(p.slug))
        setCards((prev) => [...prev, ...newCards])
      }
    }
  }, [cards.length, fetchProducts])

  const handleSwipe = useCallback(async (product: Product, liked: boolean) => {
    // Update weights
    if (liked && product.shop_persona) {
      personaWeights.current[product.shop_persona] =
        (personaWeights.current[product.shop_persona] ?? 0) + 1
    }

    // Record in Supabase
    const sb = createClient()
    await sb.from('swipes').insert({
      session_id: sessionId.current,
      product_slug: product.slug,
      liked,
    })

    setTotal((t) => t + 1)
    if (liked) setLikes((l) => l + 1)

    // Remove top card
    setCards((prev) => prev.slice(0, -1))

    refillIfNeeded()
  }, [refillIfNeeded])

  const handleReset = useCallback(async () => {
    // Clear session
    try { localStorage.removeItem(SESSION_KEY) } catch {}
    seenSlugs.current = new Set()
    personaWeights.current = {}
    sessionId.current = getOrCreateSession()
    setLikes(0)
    setTotal(0)
    setDone(false)
    loadInitial()
  }, [loadInitial])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-4xl mb-4">🃏</div>
          <p className="text-sm font-[family-name:var(--font-mono)] text-[#555] uppercase tracking-widest">Lade Produkte…</p>
        </div>
      </div>
    )
  }

  if (done || (cards.length === 0 && total > 0)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white px-4">
        <div className="text-center max-w-sm">
          <div
            style={{ backgroundColor: '#FFE500', border: '3px solid #0A0A0A', padding: '48px 40px' }}
          >
            <div className="text-5xl mb-4">🎉</div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] mb-2">
              Alles gesehen!
            </h2>
            <p className="text-sm text-[#333] mb-6">
              Du hast <strong>{likes}</strong> von <strong>{total}</strong> Produkten geliked.
            </p>
            <div className="flex flex-col gap-3">
              <Link
                href="/entdecken/likes"
                className="block text-center text-sm font-black uppercase tracking-widest py-3 px-6 transition-colors"
                style={{ backgroundColor: '#0A0A0A', color: '#FFE500' }}
              >
                ♥ Deine Likes ansehen
              </Link>
              <Link
                href="/trending"
                className="block text-center text-sm font-bold uppercase tracking-widest py-3 px-6 transition-colors border-2 border-[#0A0A0A] text-[#0A0A0A] hover:bg-[#0A0A0A] hover:text-white"
              >
                Alle Produkte
              </Link>
              <button
                onClick={handleReset}
                className="flex items-center justify-center gap-2 text-sm font-bold text-[#555] hover:text-[#0A0A0A] transition-colors"
              >
                <RotateCcw size={14} />
                Nochmal starten
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  const topCard = cards[cards.length - 1]
  const behindCard = cards[cards.length - 2]

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Header */}
      <div className="border-b-2 border-[#0A0A0A] px-4 py-3 flex items-center justify-between">
        <div>
          <span
            className="text-[10px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)]"
            style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
          >
            Entdecken
          </span>
        </div>
        <div className="flex items-center gap-1.5 text-sm font-[family-name:var(--font-mono)]">
          <Heart size={14} className="text-[#FFE500]" fill="#FFE500" />
          <span className="font-bold text-[#0A0A0A]">{likes}</span>
          <span className="text-[#999]">/ {total}</span>
        </div>
      </div>

      {/* Card area */}
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-6">
        <div className="relative w-full max-w-sm" style={{ height: '520px' }}>
          {/* Background card (peek) */}
          {behindCard && (
            <div
              className="absolute inset-x-0 mx-auto"
              style={{
                top: '8px',
                width: 'calc(100% - 16px)',
                height: '100%',
                backgroundColor: '#F5F5F5',
                border: '2px solid #0A0A0A',
                borderRadius: '0px',
              }}
            />
          )}

          {/* Top card */}
          <AnimatePresence>
            {topCard && (
              <SwipeCard
                key={topCard.slug}
                product={topCard}
                priceBand={getPriceBand(topCard.price_cents ?? 0)}
                onSwipe={handleSwipe}
              />
            )}
          </AnimatePresence>
        </div>

        {/* Buttons */}
        <div className="flex items-center gap-6 mt-6">
          <button
            onClick={() => topCard && handleSwipe(topCard, false)}
            className="flex items-center justify-center transition-all active:scale-95"
            style={{
              width: '64px', height: '64px',
              border: '2px solid #0A0A0A',
              backgroundColor: '#FFFFFF',
            }}
            aria-label="Überspringen"
          >
            <span className="text-2xl">✕</span>
          </button>

          <div className="text-center">
            <p className="text-[10px] font-[family-name:var(--font-mono)] text-[#999] uppercase tracking-widest">
              {cards.length} verbleibend
            </p>
          </div>

          <button
            onClick={() => topCard && handleSwipe(topCard, true)}
            className="flex items-center justify-center transition-all active:scale-95"
            style={{
              width: '64px', height: '64px',
              border: '2px solid #0A0A0A',
              backgroundColor: '#FFE500',
            }}
            aria-label="Liken"
          >
            <Heart size={24} fill="#0A0A0A" color="#0A0A0A" />
          </button>
        </div>

        <p className="mt-4 text-[10px] text-[#AAA] font-[family-name:var(--font-mono)] uppercase tracking-widest">
          Swipe oder Buttons verwenden
        </p>
      </div>

      {/* Trending link */}
      <div className="border-t-2 border-[#0A0A0A] px-4 py-3 flex items-center justify-center gap-2">
        <Flame size={12} className="text-[#FFE500]" />
        <Link href="/trending" className="text-xs font-bold text-[#0A0A0A] hover:text-[#555] transition-colors font-[family-name:var(--font-mono)] uppercase tracking-widest">
          Alle Produkte ansehen
        </Link>
      </div>
    </div>
  )
}
