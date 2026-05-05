'use client'

import { useState } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink, ArrowRight, Flame, TrendingUp, Zap, Shuffle, SlidersHorizontal } from 'lucide-react'

// ── Design Tokens ────────────────────────────────────────────────
const DARK = {
  pageBg:     '#1C1C1C',
  navBg:      '#1C1C1C',
  navText:    '#F0EDE8',
  navBorder:  '#333333',
  cardBg:     '#1C1C1C',
  cardBorder: '#252525',
  imgBg:      '#141414',
  titleColor: '#F0EDE8',
  tagline:    '#6B6560',
  price:      '#F0EDE8',
  subText:    '#6B6560',
  accent:     '#E85000',
  accentHov:  '#E8321C',
  filterBg:   '#1C1C1C',
  filterBord: '#333333',
  badgeBg:    '#E85000',
  badgeText:  '#1C1C1C',
  divider:    '#252525',
}

const WARM = {
  pageBg:     '#F2EDE6',
  navBg:      '#1A1A1A',
  navText:    '#F2EDE6',
  navBorder:  '#2A2A2A',
  cardBg:     '#FFFFFF',
  cardBorder: '#E8E0D8',
  imgBg:      '#F9F6F2',
  titleColor: '#1A1A1A',
  tagline:    '#8B7E75',
  price:      '#1A1A1A',
  subText:    '#A09890',
  accent:     '#E85000',
  accentHov:  '#C84400',
  filterBg:   '#EDE8E0',
  filterBord: '#D9D0C5',
  badgeBg:    '#E85000',
  badgeText:  '#FFFFFF',
  divider:    '#E8E0D8',
}

type Theme = 'dark' | 'warm'

const FILTERS = [
  { key: 'neu',         label: 'Neueste',    icon: Flame },
  { key: 'beliebt',     label: 'Beliebt',    icon: TrendingUp },
  { key: 'unter20',     label: 'Unter 20€',  icon: Zap },
  { key: 'preisspanne', label: 'Preisspanne',icon: SlidersHorizontal },
  { key: 'zufaellig',   label: 'Zufällig',   icon: Shuffle },
]

export function PreviewClient({ products }: { products: DbProduct[] }) {
  const [theme, setTheme] = useState<Theme>('warm')
  const t = theme === 'dark' ? DARK : WARM

  return (
    <div style={{ background: t.pageBg, minHeight: '100vh', fontFamily: 'inherit', transition: 'background 0.3s' }}>

      {/* ── PREVIEW BANNER ─────────────────────────── */}
      <div style={{ background: t.accent, color: theme === 'warm' ? '#fff' : '#1C1C1C' }}
           className="text-center py-2 text-[11px] font-bold uppercase tracking-widest">
        Design-Vorschau — nur für dich sichtbar
      </div>

      {/* ── TOGGLE ─────────────────────────────────── */}
      <div style={{ background: t.navBg, borderBottom: `1px solid ${t.navBorder}` }}
           className="sticky top-0 z-50 px-6 py-3 flex items-center justify-between">
        <span style={{ color: t.navText }} className="font-bold text-sm tracking-tight">
          CRAZY BABO BAZAR
        </span>
        <div className="flex items-center gap-2 bg-black/20 rounded-full p-1">
          {(['dark', 'warm'] as Theme[]).map(v => (
            <button
              key={v}
              onClick={() => setTheme(v)}
              className="px-4 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wider transition-all duration-200"
              style={{
                background: theme === v ? t.accent : 'transparent',
                color: theme === v ? '#fff' : '#999',
              }}
            >
              {v === 'dark' ? '🌑 Aktuell' : '☀️ Warm Editorial'}
            </button>
          ))}
        </div>
        <Link href="/" style={{ color: t.navText }}
              className="text-[11px] opacity-50 hover:opacity-100 transition-opacity">
          ← Zurück zur Seite
        </Link>
      </div>

      {/* ── HERO (kompakt) ────────────────────────── */}
      <div style={{ borderBottom: `1px solid ${t.navBorder}` }}
           className="flex items-center justify-center py-4 gap-3">
        <span style={{ color: t.tagline }} className="text-[11px] font-bold uppercase tracking-widest">
          Über 200 handverlesene Produkte
        </span>
        <span style={{ background: t.accent, color: '#fff' }}
              className="px-2 py-0.5 text-[11px] font-extrabold uppercase tracking-wider">
          CRAZY
        </span>
        <span style={{ color: t.navText === '#F2EDE6' ? t.pageBg === '#F2EDE6' ? '#1A1A1A' : '#F2EDE6' : '#1A1A1A' }}
              className="font-bold">BABO BAZAR</span>
      </div>

      {/* ── FILTER BAR ────────────────────────────── */}
      <div style={{ background: t.filterBg, borderBottom: `1px solid ${t.filterBord}` }}
           className="sticky top-[53px] z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center overflow-x-auto">
            {FILTERS.map(({ key, label, icon: Icon }) => (
              <button key={key}
                className="flex items-center gap-2 px-5 py-3.5 text-[11px] font-bold uppercase tracking-widest whitespace-nowrap border-b-2 transition-all"
                style={{ borderColor: key === 'neu' ? t.accent : 'transparent',
                         color: key === 'neu' ? t.accent : t.tagline }}>
                <Icon size={12} />
                {label}
              </button>
            ))}
            <span className="ml-auto text-[11px] pr-2 shrink-0" style={{ color: t.subText }}>
              {products.length} Produkte
            </span>
          </div>
        </div>
      </div>

      {/* ── PRODUCT GRID ──────────────────────────── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-6 pb-16">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
             style={{ gap: '1px', background: t.divider }}>
          {products.map(product => (
            <div key={product.slug}
                 className="group flex flex-col overflow-hidden relative"
                 style={{ background: t.cardBg }}>

              {/* Image */}
              <div className="relative w-full overflow-hidden"
                   style={{ aspectRatio: '4/3', background: t.imgBg }}>
                {product.image_url ? (
                  <Image
                    src={product.image_url}
                    alt={product.name}
                    fill
                    className="object-contain p-4 transition-transform duration-500 group-hover:scale-105"
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-5xl opacity-10">📦</div>
                )}

                {product.is_featured && (
                  <div className="absolute top-3 left-3">
                    <span style={{ background: t.badgeBg, color: t.badgeText }}
                          className="text-[9px] font-extrabold px-2 py-0.5 uppercase tracking-wider">
                      TOP PICK
                    </span>
                  </div>
                )}

                {/* Hover: Amazon CTA */}
                <div className="absolute bottom-3 right-3 opacity-0 group-hover:opacity-100 transition-all duration-300 translate-y-2 group-hover:translate-y-0">
                  <a href={product.affiliate_url} target="_blank" rel="noopener noreferrer sponsored"
                     style={{ background: t.accent, color: theme === 'warm' ? '#fff' : '#1C1C1C' }}
                     className="flex items-center gap-1.5 text-[10px] font-extrabold px-3 py-1.5">
                    Amazon <ExternalLink size={10} />
                  </a>
                </div>
              </div>

              {/* Card Body */}
              <div className="p-5 flex flex-col gap-2 flex-1">
                <h2 className="font-bold text-[0.95rem] leading-snug line-clamp-2 transition-colors"
                    style={{ color: t.titleColor, fontFamily: 'var(--font-display, inherit)' }}>
                  {product.name}
                </h2>
                <p className="text-xs leading-relaxed line-clamp-2 flex-1"
                   style={{ color: t.tagline }}>
                  {product.tagline ?? product.description ?? ''}
                </p>
                <div className="flex items-center justify-between pt-3 mt-auto"
                     style={{ borderTop: `1px solid ${t.divider}` }}>
                  <span className="font-extrabold text-base" style={{ color: t.price }}>
                    {formatPrice(product.price_cents)}
                    <span className="text-[10px] font-normal ml-1" style={{ color: t.subText }}>€</span>
                  </span>
                  <span className="flex items-center gap-1 text-xs font-bold"
                        style={{ color: t.accent }}>
                    Details <ArrowRight size={12} />
                  </span>
                </div>
              </div>

              {/* Bottom accent */}
              <div className="absolute bottom-0 left-0 right-0 h-[2px] scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"
                   style={{ background: t.accent }} />
            </div>
          ))}
        </div>
      </div>

      {/* ── FOOTER NOTE ───────────────────────────── */}
      <div className="text-center py-8 text-[11px]" style={{ color: t.subText }}>
        Das ist nur eine Vorschau. Kein Code wird verändert bis du grünes Licht gibst.
      </div>
    </div>
  )
}
