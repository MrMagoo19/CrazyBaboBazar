'use client'

import { useState, useMemo } from 'react'
import { ProductGrid } from '@/components/product-grid'
import type { DbProduct } from '@/lib/db-types'
import { Clock, TrendingUp, Zap, SlidersHorizontal, Shuffle } from 'lucide-react'

type Filter = 'neu' | 'beliebt' | 'unter20' | 'unter50' | 'zufaellig'

const FILTERS: { key: Filter; label: string; icon: React.ElementType }[] = [
  { key: 'neu',       label: 'Neueste',     icon: Clock },
  { key: 'beliebt',  label: 'Beliebt',      icon: TrendingUp },
  { key: 'unter20',  label: 'Unter 20€',    icon: Zap },
  { key: 'unter50',  label: 'Unter 50€',    icon: SlidersHorizontal },
  { key: 'zufaellig',label: 'Zufällig',     icon: Shuffle },
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

  const products = useMemo(() => {
    switch (active) {
      case 'neu':
        return [...allProducts]
      case 'beliebt':
        return [...allProducts].sort((a, b) => (b.is_featured ? 1 : 0) - (a.is_featured ? 1 : 0))
      case 'unter20':
        return allProducts.filter(p => (p.price_cents ?? 0) > 0 && (p.price_cents ?? 0) < 2000)
      case 'unter50':
        return allProducts.filter(p => (p.price_cents ?? 0) > 0 && (p.price_cents ?? 0) < 5000)
      case 'zufaellig':
        return seededShuffle(allProducts, shuffleSeed)
    }
  }, [active, allProducts, shuffleSeed])

  function handleFilter(key: Filter) {
    if (key === 'zufaellig') setShuffleSeed(Math.floor(Math.random() * 100000))
    setActive(key)
  }

  return (
    <div>
      {/* Filter Bar */}
      <div className="sticky top-16 z-30 border-b border-[#333333] bg-[#1C1C1C]/95 backdrop-blur-sm">
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
      </div>

      {/* Grid */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-16 pt-6">
        {products.length === 0 ? (
          <div className="text-center py-16 text-[#6B6560]">
            Keine Produkte in dieser Kategorie.
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
