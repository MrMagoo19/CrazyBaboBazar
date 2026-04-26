import { ProductGrid } from '@/components/product-grid'
import { MorphingText } from '@/components/ui/liquid-text'
import { getPublishedProducts } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
  description: 'Entdecke kuriose, lustige und kaufstarke Produkte. Handverlesen, ehrlich bewertet.',
}

const morphTexts = ['MIT', 'CRAZY BABO BAZAR', 'SCHENKST DU', 'EIN LÄCHELN']

export default async function HomePage() {
  const products = await getPublishedProducts()

  return (
    <div className="min-h-screen bg-[#1C1C1C]">

      {/* ── MORPHING TEXT BANNER ─────────────────────────── */}
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6 flex items-center justify-center">
          <MorphingText
            texts={morphTexts}
            className="text-[#F0EDE8] h-10 md:h-14 lg:text-[2.2rem] text-[1.4rem]"
          />
        </div>
      </div>

      {/* ── MAIN PRODUCT GRID ────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        {products.length === 0 ? (
          <div className="text-center py-24 text-[#6B6560]">
            <div className="text-5xl mb-4">🔍</div>
            <p className="text-xl font-bold mb-2">Noch keine Produkte veröffentlicht</p>
            <p className="text-sm">Setze Produkte in Supabase auf is_published = true.</p>
          </div>
        ) : (
          <ProductGrid products={products} />
        )}
        <p className="text-[#333333] text-xs text-center mt-10 pb-4">
          * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
        </p>
      </div>
    </div>
  )
}
