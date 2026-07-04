import { getProductsAbovePrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Premium Gadgets über 200 Euro — keine Kompromisse | Crazy Babo Bazar',
  description: 'Premium-Gadgets und Ausrüstung über 200 Euro — für alle, die wissen was sie wollen. HHKB, Sena, Laser-Engraver und mehr. Mit direktem Amazon-Link.',
  alternates: { canonical: '/ueber-200' },
}

export default async function Ueber200Page() {
  const products = await getProductsAbovePrice(20000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Premium</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Premium — über 200€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Premium-Produkte
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Manche Produkte haben einen Preis bei dem man kurz schluckt — und dann kauft, weil man weiß dass es das wert ist. Diese Kategorie zeigt Premium-Gadgets und Ausrüstung über 200 Euro, die keine Kompromisse machen.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Das HHKB Professional Hybrid für alle, die wirklich tippen. Das Sena 50S Motorrad-Headset für alle, die auf dem Bike nicht auf Kommunikation verzichten wollen. Der SCULPFUN Laser-Engraver für alle, die selbst herstellen statt kaufen. Premium für Menschen, die wissen was sie wollen — mit direktem Amazon-Link.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Premium-Produkte verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <ProductGrid products={products} />
        </div>
      )}
    </div>
  )
}
