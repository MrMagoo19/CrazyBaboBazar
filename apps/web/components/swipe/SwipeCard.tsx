'use client'

import { useRef } from 'react'
import { motion, useMotionValue, useTransform, PanInfo } from 'framer-motion'
import Image from 'next/image'
import Link from 'next/link'
import { ExternalLink } from 'lucide-react'

type Product = {
  slug: string
  name: string
  tagline: string | null
  image_url: string | null
  price_cents: number | null
  shop_persona: string | null
  shop_main_category: string | null
}

type Props = {
  product: Product
  priceBand: string
  onSwipe: (product: Product, liked: boolean) => void
}

const SWIPE_THRESHOLD = 55

export function SwipeCard({ product, priceBand, onSwipe }: Props) {
  const x = useMotionValue(0)
  const rotate = useTransform(x, [-200, 200], [-18, 18])
  const likeOpacity = useTransform(x, [20, 80], [0, 1])
  const skipOpacity = useTransform(x, [-80, -20], [1, 0])
  const thresholdTriggered = useRef(false)

  const handleDrag = (_: unknown, info: PanInfo) => {
    const crossed = Math.abs(info.offset.x) > SWIPE_THRESHOLD
    if (crossed && !thresholdTriggered.current) {
      thresholdTriggered.current = true
      try { navigator.vibrate?.(15) } catch {}
    } else if (!crossed) {
      thresholdTriggered.current = false
    }
  }

  const handleDragEnd = (_: unknown, info: PanInfo) => {
    thresholdTriggered.current = false
    if (info.offset.x > SWIPE_THRESHOLD) {
      onSwipe(product, true)
    } else if (info.offset.x < -SWIPE_THRESHOLD) {
      onSwipe(product, false)
    }
  }

  return (
    <motion.div
      style={{ x, rotate, position: 'absolute', inset: 0, cursor: 'grab' }}
      drag="x"
      dragConstraints={{ left: 0, right: 0 }}
      onDrag={handleDrag}
      dragElastic={0.8}
      onDragEnd={handleDragEnd}
      exit={{ x: x.get() > 0 ? 400 : -400, opacity: 0, transition: { duration: 0.25 } }}
      whileTap={{ cursor: 'grabbing' }}
    >
      <div
        className="w-full h-full flex flex-col"
        style={{ backgroundColor: '#FFFFFF', border: '2px solid #0A0A0A', userSelect: 'none' }}
      >
        {/* Like overlay */}
        <motion.div
          style={{
            position: 'absolute', inset: 0, zIndex: 10, opacity: likeOpacity,
            backgroundColor: 'rgba(255, 229, 0, 0.35)',
            display: 'flex', alignItems: 'flex-start', justifyContent: 'flex-end',
            padding: '16px',
            pointerEvents: 'none',
          }}
        >
          <div style={{ border: '3px solid #FFE500', padding: '4px 12px', transform: 'rotate(12deg)' }}>
            <span style={{ fontWeight: 900, fontSize: '22px', color: '#0A0A0A', fontFamily: 'var(--font-mono)' }}>LIKE</span>
          </div>
        </motion.div>

        {/* Skip overlay */}
        <motion.div
          style={{
            position: 'absolute', inset: 0, zIndex: 10, opacity: skipOpacity,
            backgroundColor: 'rgba(0,0,0,0.12)',
            display: 'flex', alignItems: 'flex-start', justifyContent: 'flex-start',
            padding: '16px',
            pointerEvents: 'none',
          }}
        >
          <div style={{ border: '3px solid #0A0A0A', padding: '4px 12px', transform: 'rotate(-12deg)' }}>
            <span style={{ fontWeight: 900, fontSize: '22px', color: '#0A0A0A', fontFamily: 'var(--font-mono)' }}>SKIP</span>
          </div>
        </motion.div>

        {/* Product image */}
        <div
          className="flex items-center justify-center"
          style={{ flex: 1, backgroundColor: '#F5F5F5', borderBottom: '2px solid #0A0A0A', padding: '24px', minHeight: 0 }}
        >
          {product.image_url ? (
            <Image
              src={product.image_url}
              alt={product.name}
              width={280}
              height={280}
              className="object-contain"
              style={{ maxHeight: '260px', width: 'auto', pointerEvents: 'none' }}
              draggable={false}
              unoptimized
            />
          ) : (
            <div className="text-6xl">📦</div>
          )}
        </div>

        {/* Info */}
        <div style={{ padding: '16px 20px 12px', backgroundColor: '#FFFFFF' }}>
          {/* Persona + category badge */}
          <div className="flex items-center gap-2 mb-2">
            {product.shop_persona && (
              <span
                className="text-[9px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)]"
                style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 6px' }}
              >
                {product.shop_persona}
              </span>
            )}
            {product.shop_main_category && (
              <span className="text-[9px] text-[#888] font-[family-name:var(--font-mono)] uppercase tracking-widest">
                {product.shop_main_category}
              </span>
            )}
          </div>

          {/* Name */}
          <h2
            className="font-[family-name:var(--font-display)] font-black text-[#0A0A0A] leading-tight mb-1"
            style={{ fontSize: product.name.length > 35 ? '16px' : '18px' }}
          >
            {product.name}
          </h2>

          {/* Tagline */}
          {product.tagline && (
            <p className="text-xs text-[#555] leading-relaxed mb-3 line-clamp-2">
              {product.tagline}
            </p>
          )}

          {/* Price + Link */}
          <div className="flex items-center justify-between">
            <span
              className="text-xs font-bold font-[family-name:var(--font-mono)]"
              style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
            >
              {priceBand}
            </span>
            <Link
              href={`/produkt/${product.slug}`}
              className="flex items-center gap-1 text-[10px] font-bold text-[#555] hover:text-[#0A0A0A] transition-colors uppercase tracking-widest font-[family-name:var(--font-mono)]"
              onClick={(e) => e.stopPropagation()}
            >
              Details <ExternalLink size={10} />
            </Link>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
