import { getPublishedProducts } from '@/lib/db'
import { GuideFinder } from '@/components/guide-finder'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Produkt-Finder — Crazy Babo Bazar',
  description: 'Finde das perfekte Produkt. Filter nach Preis, Beliebtheit oder lass dich überraschen.',
}

export default async function GuidePage() {
  const products = await getPublishedProducts()

  return (
    <div>
      {/* ── Header ──────────────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-1 h-6 bg-[#E85000]" />
            <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">Produkt-Finder</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-4xl sm:text-5xl leading-tight text-[#F0EDE8] mb-3">
            Was suchst du?
          </h1>
          <p className="text-[#6B6560] text-base max-w-xl">
            Filter nach Preis, stöbere nach Beliebtheit oder lass dich von zufälligen Picks überraschen.
          </p>
        </div>
      </section>

      {/* ── Finder ──────────────────────────────────────────── */}
      <GuideFinder products={products} />

      <p className="text-[#333333] text-xs text-center pb-10">
        * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
      </p>
    </div>
  )
}
