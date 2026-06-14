import { getTrendingProducts } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Flame } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Trending Gadgets & Produkte 2026 — was gerade abgeht | Crazy Babo Bazar',
  description: 'Die aktuell beliebtesten Gadgets und kuriosesten Produkte bei Crazy Babo Bazar — handverlesen, mit direktem Amazon-Link.',
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
}

export default async function TrendingPage() {
  const products = await getTrendingProducts()

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Flame size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Trending</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Was gerade abgeht
          </h1>
          <p className="text-[#555] text-sm mt-2">{products.length} Produkte</p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Was gerade bei Crazy Babo Bazar am meisten Aufmerksamkeit bekommt — keine künstlich aufgebauschten Trendlisten, keine gesponserten Platzierungen. Hier landet was wirklich geklickt und angeschaut wird.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Die Trending-Seite ist der beste Einstieg für alle, die noch nicht genau wissen was sie suchen. Ein kurzer Blick reicht um zu verstehen worum es hier geht: kuriose, witzige und kaufstarke Produkte — handverlesen, direkt auf Amazon. Regelmäßig aktualisiert wenn neue Highlights reinkommen.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Noch keine Produkte verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6"><ProductGrid products={products} /></div>
      )}
    </div>
  )
}
