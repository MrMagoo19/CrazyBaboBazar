import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Geschenke unter 200 Euro — Premium Gadgets & Technik | Crazy Babo Bazar',
  description: 'Besondere Geschenke unter 200 Euro für Partner, beste Freunde oder sich selbst. Premium-Gadgets und Ausrüstung mit direktem Amazon-Link.',
}

export default async function Unter200Page() {
  const products = await getProductsByMaxPrice(20000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Geschenke unter 200€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Produkte für unter 200&nbsp;Euro
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Das Budget für Menschen, für die du wirklich etwas Besonderes willst. Unter 200 Euro findest du bei Crazy Babo Bazar Produkte, die in keiner normalen Geschenkideen-Liste auftauchen — von professionellem Tech-Gear über spezialisierte Outdoor-Ausrüstung bis zu Gadgets die jahrelang benutzt werden.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Diese Preisklasse ist ideal für Partner, beste Freunde, Eltern oder sich selbst. Genug Budget um ein echtes Statement zu machen — ohne in den Premium-Overkill zu fallen. Jedes Produkt wurde manuell kuratiert und ist direkt über Amazon erhältlich.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Produkte unter 200&nbsp;Euro verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <ProductGrid products={products} />
        </div>
      )}
    </div>
  )
}
