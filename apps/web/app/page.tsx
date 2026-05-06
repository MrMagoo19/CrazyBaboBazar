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
      <div className="border-b-2 border-[#0A0A0A] bg-[#FFE500]/30 overflow-hidden">
        <div className="flex animate-[ticker_30s_linear_infinite] whitespace-nowrap py-2">
          {[...tickerItems, ...tickerItems, ...tickerItems].map((item, i) => (
            <span key={i} className="inline-flex items-center gap-6 px-8 text-[11px] font-bold uppercase tracking-widest text-[#0A0A0A]">
              {item}
              <span className="text-[#333333]">·</span>
            </span>
          ))}
        </div>
      </div>

      {/* ── HERO (Brutalist — kompakt, inline) ─────────────── */}
      <div className="border-b-2 border-[#0A0A0A] px-4 sm:px-6 py-5">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4 flex-wrap">
          <h1
            className="font-[family-name:var(--font-display)] font-black uppercase leading-none text-[#0A0A0A]"
            style={{ fontSize: 'clamp(1.8rem, 5vw, 3.2rem)', letterSpacing: '-0.04em' }}
          >
            Crazy <span style={{ background: '#FFE500', paddingLeft: '6px', paddingRight: '6px' }}>Babo</span> Bazar
          </h1>
          <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[#888]">
            Handverlesen · Kurios · Amazon
          </p>
        </div>
      </div>

      {/* ── FILTER + PRODUCTS ──────────────────────────────── */}
      <FilteredProducts allProducts={products} />

    </div>
  )
}
