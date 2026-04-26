import Image from 'next/image'
import { ProductGrid } from '@/components/product-grid'
import { getPublishedProducts } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
  description: 'Entdecke kuriose, lustige und kaufstarke Produkte. Handverlesen, ehrlich bewertet.',
}

const tickerItems = [
  '🔥 Trending jetzt',
  '👑 Babos',
  '✨ Queens',
  '🚀 Miniboss',
  '👥 Squad',
  '💸 Unter 20€',
  '🎯 Handverlesen',
  '⚡ Täglich neu',
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

      {/* ── HERO ───────────────────────────────────────────── */}
      <div className="border-b border-[#333333] relative flex items-center justify-center py-6">
        {/* Banner links + rechts */}
        <div className="flex items-center justify-center gap-0">
          {/* CRAZY STUFF */}
          <Image
            src="/Banner.png"
            alt="Crazy Stuff"
            width={600}
            height={400}
            className="object-contain"
            style={{ clipPath: 'inset(0 50% 0 0)', filter: 'brightness(0) invert(1)', marginRight: '-40px' }}
            priority
          />

          {/* Löwe mittig */}
          <div className="shrink-0 z-10">
            <Image
              src="/LOGO_1.png"
              alt="Crazy Babo Bazar"
              width={500}
              height={334}
              className="object-contain drop-shadow-2xl"
              priority
            />
          </div>

          {/* CRAZY LIFE */}
          <Image
            src="/Banner.png"
            alt="Crazy Life"
            width={600}
            height={400}
            className="object-contain"
            style={{ clipPath: 'inset(0 0 0 50%)', filter: 'brightness(0) invert(1)', marginLeft: '-40px' }}
            priority
          />
        </div>
      </div>

      {/* ── SECTION LABEL ──────────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pt-10 pb-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-1 h-6 bg-[#E85000]" />
          <span className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8]">
            Alle Produkte
          </span>
          {products.length > 0 && (
            <span className="text-xs text-[#6B6560] border border-[#333333] px-2 py-0.5">
              {products.length} Treffer
            </span>
          )}
        </div>
      </div>

      {/* ── PRODUCT GRID ───────────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-16">
        {products.length === 0 ? (
          <div className="text-center py-24 text-[#6B6560] border border-[#252525]">
            <p className="text-4xl mb-4 font-[family-name:var(--font-display)] font-extrabold text-[#333333]">
              BALD HIER
            </p>
            <p className="text-sm">Produkte werden gerade kuratiert.</p>
          </div>
        ) : (
          <ProductGrid products={products} />
        )}
        <p className="text-[#333333] text-xs text-center mt-10">
          * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
        </p>
      </div>

    </div>
  )
}
