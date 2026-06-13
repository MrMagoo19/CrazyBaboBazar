import { FilteredProducts } from '@/components/filtered-products'
import { ListenGrid } from '@/components/listen-grid'
import { getPublishedProducts, getAllLists } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
  description: 'Entdecke über 200 handverlesene Gadgets, Spielzeug, Beauty-Produkte und Outdoor-Equipment. Täglich neue Empfehlungen mit direkten Amazon-Links.',
  openGraph: {
    title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
    description: 'Über 200 handverlesene Produkte. Täglich neue Empfehlungen.',
    type: 'website',
    url: 'https://www.crazybabobazar.com',
  },
  twitter: { card: 'summary_large_image' },
}

export default async function HomePage() {
  const [products, lists] = await Promise.all([getPublishedProducts(), getAllLists()])

  return (
    <div className="min-h-screen bg-white">
      <ListenGrid lists={lists} />

      {/* ── SWIPE CTA ─────────────────────────────────────── */}
      <section className="border-t-2 border-b-2 border-[#0A0A0A] bg-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10 flex flex-col sm:flex-row items-center justify-between gap-6">
          <div>
            <div
              className="inline-block text-[10px] font-black uppercase tracking-widest mb-3 font-[family-name:var(--font-mono)]"
              style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
            >
              Neu
            </div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl text-white leading-tight mb-2" style={{ letterSpacing: '-0.02em' }}>
              Nicht wissen was du willst?
            </h2>
            <p className="text-[#AAA] text-sm max-w-md">
              Swipe dich durch 350+ Produkte — rechts für Interesse, links für weiter. Je mehr du likest, desto besser wird die Auswahl.
            </p>
          </div>
          <a
            href="/entdecken"
            className="shrink-0 flex items-center gap-2 font-[family-name:var(--font-mono)] font-black text-sm uppercase tracking-widest px-8 py-4 transition-colors whitespace-nowrap"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A' }}
          >
            ♥ Swipe Area starten
          </a>
        </div>
      </section>

      <FilteredProducts allProducts={products} />
    </div>
  )
}
