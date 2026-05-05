import Image from 'next/image'
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
    <div className="min-h-screen bg-[#1C1C1C]">

      {/* ── TICKER ─────────────────────────────────────────── */}
      <div className="border-b border-[#333333] bg-[#E85000]/10 overflow-hidden">
        <div className="flex animate-[ticker_30s_linear_infinite] whitespace-nowrap py-2">
          {[...tickerItems, ...tickerItems, ...tickerItems].map((item, i) => (
            <span key={i} className="inline-flex items-center gap-6 px-8 text-[11px] font-bold uppercase tracking-widest text-[#E85000]">
              {item}
              <span className="text-[#333333]">·</span>
            </span>
          ))}
        </div>
      </div>

      {/* ── HERO (kompakt) ─────────────────────────────────── */}
      <div className="border-b border-[#333333] flex items-center justify-center py-3 gap-4">
        <Image
          src="/Banner.png"
          alt=""
          width={160}
          height={40}
          className="object-contain opacity-60 hidden sm:block"
          style={{ filter: 'brightness(0) invert(1)' }}
          priority
        />
        <Image
          src="/Logo_4.png"
          alt="Crazy Babo Bazar"
          width={80}
          height={54}
          className="object-contain drop-shadow-lg"
          priority
        />
        <Image
          src="/Banner.png"
          alt=""
          width={160}
          height={40}
          className="object-contain opacity-60 hidden sm:block"
          style={{ filter: 'brightness(0) invert(1)', transform: 'scaleX(-1)' }}
          priority
        />
      </div>

      {/* ── FILTER + PRODUCTS ──────────────────────────────── */}
      <FilteredProducts allProducts={products} />

    </div>
  )
}
