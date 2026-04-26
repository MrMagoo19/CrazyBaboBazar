import { ProductGrid } from '@/components/product-grid'
import { getPublishedProducts } from '@/lib/db'
import type { Metadata } from 'next'
import { Flame, Zap, Crown } from 'lucide-react'

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
      <div className="border-b border-[#333333] relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-16 md:py-24">
          <div className="max-w-3xl">
            <div className="flex items-center gap-2 mb-6">
              <Flame size={14} className="text-[#E85000]" />
              <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">
                DACH Affiliate Discovery
              </span>
            </div>
            <h1 className="font-[family-name:var(--font-display)] font-extrabold text-[2.8rem] sm:text-[4rem] md:text-[5rem] leading-[0.95] tracking-tight text-[#F0EDE8] mb-6">
              PRODUKTE<br />
              <span className="text-[#E85000]">DIE WAS</span><br />
              DRAUF HABEN.
            </h1>
            <p className="text-[#6B6560] text-base max-w-lg leading-relaxed mb-8">
              Kuriose, lustige und kaufstarke Produkte — handverlesen für Babos, Queens, Miniboss und Squad.
            </p>
            <div className="flex flex-wrap items-center gap-3">
              <div className="flex items-center gap-1.5 text-xs text-[#9E9890]">
                <Zap size={12} className="text-[#E85000]" />
                Täglich aktualisiert
              </div>
              <div className="w-px h-3 bg-[#333333]" />
              <div className="flex items-center gap-1.5 text-xs text-[#9E9890]">
                <Crown size={12} className="text-[#E85000]" />
                Handverlesen
              </div>
              <div className="w-px h-3 bg-[#333333]" />
              <div className="text-xs text-[#9E9890]">
                🇩🇪🇦🇹🇨🇭 DACH
              </div>
            </div>
          </div>
        </div>
        {/* Decorative background text */}
        <div className="absolute right-0 top-0 bottom-0 flex items-center pointer-events-none select-none overflow-hidden">
          <span className="font-[family-name:var(--font-display)] font-extrabold text-[12rem] md:text-[18rem] text-[#F0EDE8]/[0.03] leading-none pr-4">
            CBB
          </span>
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
