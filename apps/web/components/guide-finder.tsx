'use client'

import { useState, useMemo } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import type { DbProduct } from '@/lib/db-types'
import { formatPrice } from '@/lib/db-types'
import { ExternalLink, Shuffle, TrendingUp, Clock, Zap, SlidersHorizontal, ArrowRight } from 'lucide-react'

type Tab = 'neueste' | 'beliebt' | 'unter20' | 'preisspanne' | 'zufall'

const TABS: { key: Tab; label: string; icon: React.ElementType }[] = [
  { key: 'neueste',     label: 'Neueste',      icon: Clock },
  { key: 'beliebt',    label: 'Beliebt',       icon: TrendingUp },
  { key: 'unter20',    label: 'Unter 20€',     icon: Zap },
  { key: 'preisspanne',label: 'Preisspanne',   icon: SlidersHorizontal },
  { key: 'zufall',     label: 'Zufällig',      icon: Shuffle },
]

export function GuideFinder({ products }: { products: DbProduct[] }) {
  const [activeTab, setActiveTab] = useState<Tab>('neueste')
  const [minPrice, setMinPrice] = useState(0)
  const [maxPrice, setMaxPrice] = useState(100)
  const [appliedMin, setAppliedMin] = useState(0)
  const [appliedMax, setAppliedMax] = useState(100)
  const [shuffleSeed, setShuffleSeed] = useState(0)

  const filtered = useMemo(() => {
    let list = [...products]

    switch (activeTab) {
      case 'neueste':
        // newest first (by array order — DB already ordered)
        break
      case 'beliebt':
        list = list.sort((a, b) => (b.is_featured ? 1 : 0) - (a.is_featured ? 1 : 0))
        break
      case 'unter20':
        list = list.filter(p => p.price_cents !== null && p.price_cents < 2000)
        break
      case 'preisspanne':
        list = list.filter(p =>
          p.price_cents !== null &&
          p.price_cents >= appliedMin * 100 &&
          p.price_cents <= appliedMax * 100
        )
        break
      case 'zufall':
        // seeded shuffle so it only changes on button click
        list = [...list].sort(() => Math.sin(shuffleSeed + list.indexOf(list[0])) - 0.5)
        break
    }

    return list
  }, [products, activeTab, appliedMin, appliedMax, shuffleSeed])

  return (
    <div>
      {/* ── Tabs ──────────────────────────────────────────────── */}
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center gap-0 overflow-x-auto scrollbar-none">
            {TABS.map(tab => (
              <button
                key={tab.key}
                onClick={() => {
                  setActiveTab(tab.key)
                  if (tab.key === 'zufall') setShuffleSeed(s => s + 1)
                }}
                className={`flex items-center gap-2 px-5 py-4 text-xs font-bold uppercase tracking-widest whitespace-nowrap border-b-2 transition-all duration-200
                  ${activeTab === tab.key
                    ? 'border-[#E85000] text-[#E85000]'
                    : 'border-transparent text-[#6B6560] hover:text-[#9E9890]'
                  }`}
              >
                <tab.icon size={13} />
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ── Filter bar (Preisspanne only) ──────────────────────── */}
      {activeTab === 'preisspanne' && (
        <div className="border-b border-[#333333] bg-[#252525]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex flex-wrap items-end gap-6">
            <div>
              <label className="block text-[10px] uppercase tracking-widest text-[#6B6560] mb-2">Von (€)</label>
              <input
                type="number"
                min={0}
                value={minPrice}
                onChange={e => setMinPrice(Number(e.target.value))}
                className="w-24 bg-[#1C1C1C] border border-[#333333] text-[#F0EDE8] text-sm px-3 py-2 outline-none focus:border-[#E85000]"
              />
            </div>
            <div>
              <label className="block text-[10px] uppercase tracking-widest text-[#6B6560] mb-2">Bis (€)</label>
              <input
                type="number"
                min={0}
                value={maxPrice}
                onChange={e => setMaxPrice(Number(e.target.value))}
                className="w-24 bg-[#1C1C1C] border border-[#333333] text-[#F0EDE8] text-sm px-3 py-2 outline-none focus:border-[#E85000]"
              />
            </div>
            <button
              onClick={() => { setAppliedMin(minPrice); setAppliedMax(maxPrice) }}
              className="px-6 py-2 bg-[#E85000] text-[#1C1C1C] text-xs font-extrabold uppercase tracking-widest hover:bg-[#E8321C] transition-colors"
            >
              Anwenden
            </button>
            <span className="text-xs text-[#6B6560] self-center">
              {filtered.length} Produkte gefunden
            </span>
          </div>
        </div>
      )}

      {/* ── Results ───────────────────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
        {filtered.length === 0 ? (
          <div className="text-center py-20 text-[#6B6560]">
            <div className="text-4xl mb-4">🔍</div>
            <p className="font-bold">Keine Produkte in diesem Bereich</p>
            <p className="text-sm mt-1">Preisspanne anpassen oder anderen Filter wählen.</p>
          </div>
        ) : (
          <>
            <p className="text-xs text-[#6B6560] mb-6 uppercase tracking-widest">
              {filtered.length} Produkte
              {activeTab === 'zufall' && (
                <button
                  onClick={() => setShuffleSeed(s => s + 1)}
                  className="ml-3 inline-flex items-center gap-1 text-[#E85000] hover:underline"
                >
                  <Shuffle size={10} /> Neu mischen
                </button>
              )}
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-px bg-[#252525]">
              {filtered.map(product => (
                <div key={product.slug} className="group bg-[#1C1C1C] flex flex-col overflow-hidden relative">

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
                        <div className="absolute inset-0 flex items-center justify-center text-6xl opacity-10">📦</div>
                      )}
                      {product.is_featured && (
                        <span className="absolute top-3 left-3 bg-[#E85000] text-[#1C1C1C] text-[9px] font-extrabold px-2 py-0.5 uppercase tracking-wider">
                          TOP PICK
                        </span>
                      )}
                    </div>
                  </Link>

                  {/* Body */}
                  <div className="p-5 flex flex-col gap-3 flex-1">
                    <Link href={`/produkt/${product.slug}`}>
                      <h3 className="font-[family-name:var(--font-display)] font-bold text-[1rem] leading-snug text-[#F0EDE8] group-hover:text-[#E85000] transition-colors line-clamp-2">
                        {product.name}
                      </h3>
                    </Link>
                    <p className="text-[#6B6560] text-xs leading-relaxed line-clamp-2 flex-1">
                      {product.tagline ?? product.description ?? ''}
                    </p>
                    <div className="flex items-center justify-between pt-3 border-t border-[#252525] mt-auto">
                      <span className="font-[family-name:var(--font-display)] font-extrabold text-base text-[#F0EDE8]">
                        {formatPrice(product.price_cents)}
                        <span className="text-[#6B6560] text-[10px] font-normal ml-1">€</span>
                      </span>
                      <a
                        href={product.affiliate_url}
                        target="_blank"
                        rel="noopener noreferrer sponsored"
                        className="flex items-center gap-1.5 bg-[#E85000] text-[#1C1C1C] text-[10px] font-extrabold px-3 py-1.5 hover:bg-[#E8321C] transition-colors"
                      >
                        Amazon <ExternalLink size={10} />
                      </a>
                    </div>
                    <Link
                      href={`/produkt/${product.slug}`}
                      className="flex items-center gap-1 text-xs font-bold text-[#6B6560] hover:text-[#E85000] hover:gap-2 transition-all duration-200"
                    >
                      Details <ArrowRight size={11} />
                    </Link>
                  </div>

                  <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-[#E85000] scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left" />
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
