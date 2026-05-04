import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Unter 20€ — Günstige Produkte',
  description: 'Kuriose und lustige Produkte für unter 20 Euro auf Crazy Babo Bazar.',
}

export default async function Unter20Page() {
  const products = await getProductsByMaxPrice(2000)

  return (
    <div>
      <div className="border-b border-[#252525] bg-[#141414]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#E85000]" />
            <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#F0EDE8]">
            Unter 20€
          </h1>
          <p className="text-[#6B6560] text-sm mt-2">
            {products.length} Produkte für unter 20&nbsp;Euro
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#6B6560]">
          Aktuell keine Produkte unter 20&nbsp;Euro verfügbar.
        </div>
      ) : (
        <ProductGrid products={products} />
      )}
    </div>
  )
}
