'use client'

import { useState, useMemo } from 'react'
import { ProductGrid } from '@/components/product-grid'
import type { DbProduct } from '@/lib/db-types'
import { Clock, TrendingUp, Zap, SlidersHorizontal, Shuffle } from 'lucide-react'

type Filter = 'neu' | 'beliebt' | 'unter20' | 'preisspanne' | 'zufaellig'

const FILTERS: { key: Filter; label: string; icon: React.ElementType }[] = [
  { key: 'neu',          label: 'Neueste',     icon: Clock },
  { key: 'beliebt',      label: 'Beliebt',     icon: TrendingUp },
  { key: 'unter20',      label: 'Unter 20€',   icon: Zap },
  { key: 'preisspanne',  label: 'Preisspanne', icon: SlidersHorizontal },
  { key: 'zufaellig',    label: 'Zufällig',    icon: Shuffle },
]

function seededShuffle<T>(arr: T[], seed: number): T[] {
  const a = [...arr]
  let s = seed
  for (let i = a.length - 1; i > 0; i--) {
    s = (s * 1664525 + 1013904223) & 0xffffffff
    const j = Math.abs(s) % (i + 1);
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

export function FilteredProducts({ allProducts }: { allProducts: DbProduct[] }) {
  const [active, setActive] = useState<Filter>('neu')
  const [shuffleSeed, setShuffleSeed] = useState(() => Math.floor(Math.random() * 100000))
  const [minPrice, setMinPrice] = useState('')
  const [maxPrice, setMaxPrice] = useState('')

  const products = useMemo(() => {
    switch (active) {
      case 'neu':
        return [...allProducts].sort((a, b) =>
          (b.created_at ?? '').localeCompare(a.created_at ?? '')
        )
      case 'beliebt':
        return [...allProducts].sort((a, b) => (b.is_featured ? 1 : 0) - (a.is_featured ? 1 : 0))
      case 'unter20':
        return allProducts.filter(p => (p.price_cents ?? 0) > 0 && (p.price_cents ?? 0) < 2000)
      case 'preisspanne': {
        const min = minPrice ? parseFloat(minPrice) * 100 : 0
        const max = maxPrice ? parseFloat(maxPrice) * 100 : Infinity
        return allProducts.filter(p => {
          const c = p.price_cents ?? 0
          return c > 0 && c >= min && c <= max
        })
      }
      case 'zufaellig':
        return seededShuffle(allProducts, shuffleSeed)
    }
  }, [active, allProducts, shuffleSeed, minPrice, maxPrice])

  function handleFilter(key: Filter) {
    if (key === 'zufaellig') setShuffleSeed(Math.floor(Math.random() * 100000))
    setActive(key)
  }

  return (
    <div>
      {/* Filter Bar */}
      <div className="sticky top-16 z-30 border-b border-[#333333] bg-[#1C1C1C]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center gap-0 overflow-x-auto scrollbar-none">
            {FILTERS.map(({ key, label, icon: Icon }) => (
              <button
                key={key}
                onClick={() => handleFilter(key)}
                className={`flex items-center gap-2 px-5 py-3.5 text-[11px] font-bold uppercase tracking-widest whitespace-nowrap border-b-2 transition-all duration-150 ${
                  active === key
                    ? 'border-[#E85000] text-[#E85000]'
                    : 'border-transparent text-[#6B6560] hover:text-[#F0EDE8] hover:border-[#333333]'
                }`}
              >
                <Icon size={13} />
                {label}
              </button>
            ))}
            <span className="ml-auto text-[11px] text-[#3A3A3A] pr-2 shrink-0">
              {products.length} Produkte
            </span>
          </div>
        </div>

        {/* Preisspanne Eingabe */}
        {active === 'preisspanne' && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-3 pt-1 flex items-center gap-3">
            <span className="text-[11px] text-[#6B6560] uppercase tracking-wider">Von</span>
            <div className="relative">
              <input
                type="number"
                min="0"
                placeholder="0"
                value={minPrice}
                onChange={e => setMinPrice(e.target.value)}
                className="w-24 bg-[#252525] border border-[#333333] text-[#F0EDE8] text-sm px-3 py-1.5 pr-6 outline-none focus:border-[#E85000] transition-colors [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-[#6B6560] text-xs">€</span>
            </div>
            <span className="text-[11px] text-[#6B6560] uppercase tracking-wider">Bis</span>
            <div className="relative">
              <input
                type="number"
                min="0"
                placeholder="∞"
                value={maxPrice}
                onChange={e => setMaxPrice(e.target.value)}
                className="w-24 bg-[#252525] border border-[#333333] text-[#F0EDE8] text-sm px-3 py-1.5 pr-6 outline-none focus:border-[#E85000] transition-colors [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-[#6B6560] text-xs">€</span>
            </div>
            {(minPrice || maxPrice) && (
              <button
                onClick={() => { setMinPrice(''); setMaxPrice('') }}
                className="text-[11px] text-[#6B6560] hover:text-[#E85000] transition-colors uppercase tracking-wider"
              >
                Zurücksetzen
              </button>
            )}
          </div>
        )}
      </div>

      {/* Grid */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-16 pt-6">
        {products.length === 0 ? (
          <div className="text-center py-16 text-[#6B6560]">
            Keine Produkte in dieser Preisklasse.
          </div>
        ) : (
          <ProductGrid products={products} />
        )}
        <p className="text-[#333333] text-xs text-center mt-10">
          * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
        </p>
      </div>
    </div>
  )
}
