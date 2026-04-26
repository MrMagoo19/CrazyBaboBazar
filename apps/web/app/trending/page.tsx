import { getTrendingProducts } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Flame } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Trending',
  description: 'Die aktuell beliebtesten und kuriosesten Produkte auf Crazy Babo Bazar.',
}

export default async function TrendingPage() {
  const products = await getTrendingProducts()

  return (
    <div>
      <div className="border-b border-[#252525] bg-[#141414]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Flame size={20} className="text-[#E85000]" />
            <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">Trending</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#F0EDE8]">
            Was gerade abgeht
          </h1>
          <p className="text-[#6B6560] text-sm mt-2">{products.length} Produkte</p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#6B6560]">
          Noch keine Produkte verfügbar.
        </div>
      ) : (
        <ProductGrid products={products} />
      )}
    </div>
  )
}
