import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Geschenke unter 50 Euro — Gadgets & Geschenkideen | Crazy Babo Bazar',
  description: 'Die besten Geschenke unter 50 Euro — weit weg vom Parfüm-Set aus der Drogerie. Kuratierte Gadgets, Tech und Lifestyle-Produkte mit Amazon-Link.',
}

export default async function Unter50Page() {
  const products = await getProductsByMaxPrice(5000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Geschenke unter 50€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Produkte für unter 50&nbsp;Euro
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            50 Euro ist die goldene Mitte: Genug Budget für etwas Besonderes, nicht so viel dass es zum Stress wird. Diese Kategorie zeigt Geschenke unter 50 Euro, die wirklich erinnerungswürdig sind — weit weg vom Parfüm-Set aus dem Drogerieregal.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Ob Geburtstag, Weihnachten, Valentinstag oder spontanes "ich hab an dich gedacht": In dieser Preisklasse findest du Gadgets, Gaming-Produkte, Küchenhelfer und Lifestyle-Artikel, die beim Auspacken für echte Reaktionen sorgen. Handverlesen, ohne Einheitsbrei — jedes Produkt direkt auf Amazon verfügbar.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Produkte unter 50&nbsp;Euro verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6"><ProductGrid products={products} /></div>
      )}
    </div>
  )
}
