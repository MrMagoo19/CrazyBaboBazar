import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Geschenke unter 100 Euro — Gadgets & Technik | Crazy Babo Bazar',
  description: 'Gadgets und Geschenke unter 100 Euro, die man sich selten selbst kauft — aber sofort haben will. Handverlesen mit direktem Amazon-Link.',
  alternates: { canonical: '/unter-100' },
}

export default async function Unter100Page() {
  const products = await getProductsByMaxPrice(10000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Geschenke unter 100€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Produkte für unter 100&nbsp;Euro
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Mit bis zu 100 Euro Budget öffnet sich die Türe zu den wirklich interessanten Gadgets — Produkte, die man sich selten selbst kauft, aber sofort haben will wenn man sie sieht. Diese Auswahl zeigt alles was unter 100 Euro auf Amazon zu haben ist und tatsächlich begeistert.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Von hochwertigen Tech-Gadgets über Premium-Küchenhelfer bis zu Gaming-Ausrüstung: 100 Euro ist der Sweetspot für Geschenke die in Erinnerung bleiben. Besonders geeignet für besondere Anlässe, runde Geburtstage oder als Upgrade-Geschenk für Technik-Enthusiasten. Keine gesponserten Platzierungen, nur echte Picks.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Produkte unter 100&nbsp;Euro verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <ProductGrid products={products} />
        </div>
      )}
    </div>
  )
}
