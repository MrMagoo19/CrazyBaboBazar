import { getPublishedProducts } from '@/lib/db'
import { GuideFinder } from '@/components/guide-finder'
import type { Metadata } from 'next'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Produkt-Finder — Crazy Babo Bazar',
  description: 'Finde das perfekte Produkt. Filter nach Preis, Beliebtheit oder lass dich überraschen.',
  alternates: { canonical: '/guide' },
}

export default async function GuidePage() {
  const products = await getPublishedProducts()

  return (
    <div>
      {/* ── Header ──────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-1 h-6 bg-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Produkt-Finder</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-4xl sm:text-5xl leading-tight text-[#0A0A0A] mb-3">
            Was suchst du?
          </h1>
          <p className="text-[#555] text-base max-w-xl">
            Filter nach Preis, stöbere nach Beliebtheit oder lass dich von zufälligen Picks überraschen.
          </p>
        </div>
      </section>

      {/* ── Finder ──────────────────────────────────────────── */}
      <GuideFinder products={products} />

      <p className="text-[#555] text-xs text-center pb-10">
        * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
      </p>
    </div>
  )
}
