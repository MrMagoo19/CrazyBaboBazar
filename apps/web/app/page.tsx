import { FilteredProducts } from '@/components/filtered-products'
import { getPublishedProducts } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
  description: 'Entdecke über 200 handverlesene Gadgets, Spielzeug, Beauty-Produkte und Outdoor-Equipment. Täglich neue Empfehlungen mit direkten Amazon-Links.',
  openGraph: {
    title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
    description: 'Über 200 handverlesene Produkte. Täglich neue Empfehlungen.',
    type: 'website',
    url: 'https://www.crazybabobazar.de',
  },
  twitter: { card: 'summary_large_image' },
}

const tickerItems = [
  '🎁 Geschenke für Männer',
  '💐 Geschenke für Frauen',
  '🧸 Geschenke für Kinder',
  '🐾 Geschenke für Tiere',
  '❤️ Geschenke für Lieblingsmenschen',
  '🍎 Geschenke für Lehrer',
]

export default async function HomePage() {
  const products = await getPublishedProducts()

  return (
    <div className="min-h-screen bg-white">

      {/* ── TICKER ─────────────────────────────────────────── */}
      <div className="border-b-2 border-[#0A0A0A] bg-[#E85000]/5 overflow-hidden">
        <div className="flex animate-[ticker_30s_linear_infinite] whitespace-nowrap py-2">
          {[...tickerItems, ...tickerItems, ...tickerItems].map((item, i) => (
            <span key={i} className="inline-flex items-center gap-6 px-8 text-[11px] font-bold uppercase tracking-widest text-[#E85000]">
              {item}
              <span className="text-[#333333]">·</span>
            </span>
          ))}
        </div>
      </div>

      {/* ── HERO (Brutalist) ─────────────────────────────────── */}
      <div className="border-b-2 border-[#0A0A0A] py-8 px-4 sm:px-6">
        <div className="max-w-7xl mx-auto">
          <p className="text-[11px] font-black uppercase tracking-[0.2em] text-[#555555] mb-2">
            Handverlesen. Kurios. Direkt auf Amazon.
          </p>
          <h1 className="font-[family-name:var(--font-display)] font-black text-4xl sm:text-6xl lg:text-7xl text-[#0A0A0A] leading-none tracking-tight uppercase">
            Crazy<br />
            <span className="text-[#E85000]">Babo</span>{' '}
            Bazar
          </h1>
        </div>
      </div>

      {/* ── FILTER + PRODUCTS ──────────────────────────────── */}
      <FilteredProducts allProducts={products} />

    </div>
  )
}
