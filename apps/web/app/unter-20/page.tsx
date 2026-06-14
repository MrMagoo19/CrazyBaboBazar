import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Geschenke unter 20 Euro — Wichtelgeschenke & Mitbringsel | Crazy Babo Bazar',
  description: 'Kuriose und witzige Geschenke unter 20 Euro — ideal für Wichteln, spontane Mitbringsel und Geburtstage. Handverlesen mit direktem Amazon-Link.',
}

export default async function Unter20Page() {
  const products = await getProductsByMaxPrice(2000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Geschenke unter 20€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Produkte für unter 20&nbsp;Euro
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Wenig Budget, großer Eindruck. Geschenke unter 20 Euro müssen nicht nach 20 Euro aussehen — wenn man weiß wo man suchen muss. Diese Auswahl zeigt Produkte, die überraschen, nützlich sind oder einfach für einen echten Moment sorgen.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Ideal für Wichtelgeschenke, spontane Mitbringsel, Geburtstagsgeschenke für Kollegen oder alle Situationen, in denen du schnell ein gutes Geschenk brauchst. Jedes Produkt hier wurde manuell ausgewählt und hat einen direkten Amazon-Link — kein Account, keine Umwege.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Produkte unter 20&nbsp;Euro verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6"><ProductGrid products={products} /></div>
      )}
    </div>
  )
}
