'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
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

/**
 * Obergrenze für einen kompletten Startdeck-Ladevorgang (alle Queries zusammen).
 * Danach werden die laufenden Requests wirklich abgebrochen, statt nur das
 * Ergebnis zu ignorieren — sonst könnte ein später Rückläufer noch refs oder
 * State beschreiben.
 */
const DECK_LOAD_TIMEOUT_MS = 15_000

/** Ergebnis des Initial-Ladens — wird erst nach dem await in State übernommen. */
type InitialDeck = {
  likes: number
  total: number
  cards: Product[]
}

/** Ein laufender Startdeck-Ladevorgang samt Abbruch-Handle. */
type DeckLoad = {
  promise: Promise<InitialDeck>
  cancel: () => void
}

/**
 * Startet einen Startdeck-Ladevorgang mit hartem Timeout.
 *
 * Kein `Promise.race`: Der Timeout ruft `controller.abort()` auf, wodurch die
 * Supabase-Queries per `.abortSignal()` tatsächlich abgebrochen werden. Der
 * Timer wird in jedem Ausgang gelöscht; `cancel()` ist idempotent und darf auch
 * nach dem Settle noch aufgerufen werden (dann ein No-Op auf dem Netz).
 */
function startDeckLoad(
  run: (signal: AbortSignal) => Promise<InitialDeck>,
  timeoutMs: number = DECK_LOAD_TIMEOUT_MS
): DeckLoad {
  const controller = new AbortController()
  let timer: ReturnType<typeof setTimeout> | null = setTimeout(() => {
    timer = null
    controller.abort()
  }, timeoutMs)

  const clearTimer = () => {
    if (timer !== null) {
      clearTimeout(timer)
      timer = null
    }
  }

  // `.finally` hängt am zurückgegebenen Promise — die Ablehnung wird also von
  // der Aufruferin behandelt und erzeugt keinen zweiten, unbehandelten Zweig.
  // Das try/catch fängt nur den (bei async-Funktionen unmöglichen) synchronen
  // Wurf ab, damit dabei kein Timer stehen bleibt.
  let promise: Promise<InitialDeck>
  try {
    promise = run(controller.signal).finally(clearTimer)
  } catch (err) {
    clearTimer()
    promise = Promise.reject(err)
  }

  return {
    promise,
    cancel: () => {
      clearTimer()
      controller.abort()
    },
  }
}

/**
 * Ein Deck ist unbrauchbar, wenn weder Karten noch frühere Swipes vorliegen.
 * Das ist der typische Supabase-Fehlerfall (`data: null` statt throw) und kein
 * gültiger Endzustand. `cards.length === 0` bei `total > 0` ist dagegen gültig:
 * Die Nutzerin hat den Katalog durchgeswiped und bekommt den Done-Screen.
 */
function isUsableDeck(deck: InitialDeck): boolean {
  return deck.cards.length > 0 || deck.total > 0
}

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
  const [showLikeAnim, setShowLikeAnim] = useState(false)
  const [loadFailed, setLoadFailed] = useState(false)

  // persona weights: { babo: 3, queen: 1, ... }
  const personaWeights = useRef<Record<string, number>>({})
  const seenSlugs = useRef<Set<string>>(new Set())
  const sessionId = useRef<string>('')
  // Imperativer Guard für alle manuell ausgelösten Deck-Ladevorgänge (Hard
  // Reset und Retry). Verhindert, dass zwei davon parallel laufen und sich ihre
  // Decks gegenseitig überschreiben. Ref statt State, damit der Wert schon im
  // selben Tick gilt — vor der ersten Mutation.
  const deckLoadInFlight = useRef(false)

  // `signal` wird nur aus dem Startladepfad übergeben. Ohne Signal bleibt das
  // Verhalten exakt wie bisher: Fehler enden in `data: null` → leeres Array,
  // damit Refills keinen neuen Rejection-Pfad bekommen.
  const fetchProducts = useCallback(async (weighted = false, signal?: AbortSignal) => {
    const sb = createClient()

    // Build persona filter based on weights
    let personaFilter: string | null = null
    if (weighted) {
      const sorted = Object.entries(personaWeights.current).sort((a, b) => b[1] - a[1])
      if (sorted.length > 0 && sorted[0][1] > 0) {
        personaFilter = sorted[0][0]
      }
    }

    // Fetch a larger batch so filtering seen slugs doesn't exhaust the set
    let query = sb
      .from('products')
      .select('slug, name, tagline, image_url, price_cents, shop_persona, shop_main_category')
      .eq('is_published', true)
      .order('created_at', { ascending: Math.random() > 0.5 })
      .limit(40)

    if (personaFilter) {
      query = query.eq('shop_persona', personaFilter)
    }

    if (signal) {
      query = query.abortSignal(signal)
    }

    const { data, error } = await query
    // Abbruch und Netzwerkfehler kommen bei PostgREST als `error` zurück, nicht
    // als Rejection. Im Startladepfad muss das im Fehlerzustand landen.
    if (signal && error) throw error
    if (!data) return []

    // Shuffle and filter out already seen
    const shuffled = [...data].sort(() => Math.random() - 0.5)
    return shuffled.filter((p) => !seenSlugs.current.has(p.slug))
  }, [])

  // Reines Laden: liefert den Startzustand zurück, statt ihn selbst zu setzen.
  // So bleibt der Effekt unten eine reine Synchronisation mit einem externen
  // System — State wird ausschließlich im async Callback aktualisiert.
  const loadInitialDeck = useCallback(async (signal: AbortSignal): Promise<InitialDeck> => {
    sessionId.current = getOrCreateSession()

    const sb = createClient()

    // Load already-swiped slugs + liked status
    const { data: swipeData, error: swipeError } = await sb
      .from('swipes')
      .select('product_slug, liked')
      .eq('session_id', sessionId.current)
      .abortSignal(signal)

    if (swipeError) throw swipeError

    let hasPriorLikes = false
    let likes = 0
    let total = 0

    if (swipeData && swipeData.length > 0) {
      swipeData.forEach((s) => seenSlugs.current.add(s.product_slug))
      const likedSlugs = swipeData.filter((s) => s.liked).map((s) => s.product_slug)
      likes = likedSlugs.length
      total = swipeData.length

      // Restore persona weights from previously liked products
      if (likedSlugs.length > 0) {
        hasPriorLikes = true
        const { data: likedProducts, error: likedError } = await sb
          .from('products')
          .select('slug, shop_persona')
          .in('slug', likedSlugs)
          .abortSignal(signal)

        if (likedError) throw likedError

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

    const products = await fetchProducts(hasPriorLikes, signal)
    const shuffled = [...products].sort(() => Math.random() - 0.5)
    shuffled.forEach((p) => seenSlugs.current.add(p.slug))

    return { likes, total, cards: shuffled }
  }, [fetchProducts])

  const applyInitialDeck = useCallback((deck: InitialDeck) => {
    setLikes(deck.likes)
    setTotal(deck.total)
    setCards(deck.cards)
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    // loadInitialDeck rekonstruiert seenSlugs und personaWeights ohnehin aus der
    // bestehenden Supabase-Session — der Reset isoliert Effect-Replay (Strict
    // Mode) und abgebrochene Teilversuche, damit keine doppelten Gewichte bleiben.
    seenSlugs.current = new Set()
    personaWeights.current = {}
    const load = startDeckLoad(loadInitialDeck)
    load.promise
      .then((deck) => {
        if (!active) return
        if (isUsableDeck(deck)) {
          applyInitialDeck(deck)
          return
        }
        // Ohne Karten und ohne frühere Swipes ist nichts anzuzeigen — sonst
        // bliebe die Seite dauerhaft im Ladezustand hängen.
        setLoading(false)
        setLoadFailed(true)
      })
      .catch(() => {
        if (!active) return
        setLoading(false)
        setLoadFailed(true)
      })
    return () => {
      // Erst den Guard schließen (keine State-Updates nach Unmount), dann die
      // laufenden Requests wirklich abbrechen.
      active = false
      load.cancel()
    }
  }, [loadInitialDeck, applyInitialDeck])

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

    // Like animation + haptic feedback
    if (liked) {
      setShowLikeAnim(true)
      setTimeout(() => setShowLikeAnim(false), 700)
      try { navigator.vibrate?.(40) } catch {}
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

  // Retry nach einem fehlgeschlagenen Laden: lädt dieselbe Session neu, ohne
  // SESSION_KEY zu löschen. Likes und Swipes der Nutzerin bleiben also erhalten.
  const handleRetryLoad = useCallback(async () => {
    if (deckLoadInFlight.current) return
    deckLoadInFlight.current = true

    // Sauberer In-Memory-Start: ein abgebrochener Versuch darf seine bereits
    // gezählten Persona-Gewichte nicht ein zweites Mal addieren. Die Session
    // selbst bleibt bestehen — loadInitialDeck baut beides aus Supabase neu auf.
    // Muss vor dem Start laufen, damit der Ladevorgang in die frischen Refs schreibt.
    seenSlugs.current = new Set()
    personaWeights.current = {}
    setLoadFailed(false)
    setLoading(true)

    const load = startDeckLoad(loadInitialDeck)
    try {
      const deck = await load.promise
      if (!isUsableDeck(deck)) {
        throw new Error('Retry load returned an unusable deck')
      }
      applyInitialDeck(deck)
    } catch {
      setLoading(false)
      setLoadFailed(true)
    } finally {
      // Räumt Timer und Controller in jedem Pfad ab — nach dem Settle ist der
      // Abort ein No-Op.
      load.cancel()
      deckLoadInFlight.current = false
    }
  }, [loadInitialDeck, applyInitialDeck])

  const handleReset = useCallback(async () => {
    if (deckLoadInFlight.current) return
    deckLoadInFlight.current = true

    // Clear session
    try { localStorage.removeItem(SESSION_KEY) } catch {}
    seenSlugs.current = new Set()
    personaWeights.current = {}
    sessionId.current = getOrCreateSession()
    setLoadFailed(false)
    setLikes(0)
    setTotal(0)
    setCards([])
    setDone(false)
    setLoading(true)

    const load = startDeckLoad(loadInitialDeck)
    try {
      // Erst awaiten, dann anwenden: ein fehlgeschlagener Load darf keinen
      // halben Deck-Zustand hinterlassen.
      const deck = await load.promise
      // Supabase-Fehler kommen meist als `data: null` zurück, nicht als throw.
      // Eine frische Reset-Session muss veröffentlichte Karten liefern — ein
      // leeres Deck ist deshalb ein Ladefehler und kein gültiges Ergebnis.
      if (deck.cards.length === 0) {
        throw new Error('Reset load returned an empty deck')
      }
      applyInitialDeck(deck)
    } catch {
      // Ohne diesen Ausstieg bliebe die Seite dauerhaft im Ladezustand hängen.
      setLoading(false)
      setLoadFailed(true)
    } finally {
      load.cancel()
      deckLoadInFlight.current = false
    }
  }, [loadInitialDeck, applyInitialDeck])

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

  if (loadFailed) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white px-4">
        <div className="text-center max-w-sm">
          <div role="alert" style={{ backgroundColor: '#FFE500', border: '3px solid #0A0A0A', padding: '48px 40px' }}>
            <div className="text-5xl mb-4">🃏</div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] mb-2">
              Deck klemmt
            </h2>
            <p className="text-sm text-[#333] mb-6">
              Die Produkte kamen nicht durch. Passiert. Nochmal?
            </p>
            <div className="flex flex-col gap-3">
              <button
                onClick={() => { void handleRetryLoad() }}
                className="flex items-center justify-center gap-2 text-center text-sm font-black uppercase tracking-widest py-3 px-6 transition-colors"
                style={{ backgroundColor: '#0A0A0A', color: '#FFE500' }}
              >
                <RotateCcw size={14} />
                Nochmal versuchen
              </button>
              <Link
                href="/trending"
                className="block text-center text-sm font-bold uppercase tracking-widest py-3 px-6 transition-colors border-2 border-[#0A0A0A] text-[#0A0A0A] hover:bg-[#0A0A0A] hover:text-white"
              >
                Alle Produkte
              </Link>
            </div>
          </div>
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
                onClick={() => { void handleReset() }}
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
        <div className="flex items-center gap-2">
          {likes > 0 ? (
            <Link
              href="/entdecken/likes"
              className="flex items-center gap-1.5 font-[family-name:var(--font-mono)] text-[10px] font-black uppercase tracking-widest px-3 py-1.5 transition-colors"
              style={{ backgroundColor: '#FFE500', color: '#0A0A0A' }}
            >
              <Heart size={11} fill="#0A0A0A" color="#0A0A0A" />
              Babo-Liste ({likes})
            </Link>
          ) : null}
        </div>
      </div>

      {/* Card area */}
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-6">
        {/* Like animation overlay */}
        <AnimatePresence>
          {showLikeAnim && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.4 }}
              transition={{ duration: 0.35 }}
              style={{ position: 'fixed', inset: 0, zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}
            >
              <div style={{ backgroundColor: '#FFE500', borderRadius: '50%', width: '120px', height: '120px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '3px solid #0A0A0A' }}>
                <Heart size={56} fill="#0A0A0A" color="#0A0A0A" />
              </div>
            </motion.div>
          )}
        </AnimatePresence>

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
