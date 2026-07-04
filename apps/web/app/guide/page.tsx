import Link from 'next/link'
import { getPublishedProducts } from '@/lib/db'
import { guides } from '@/lib/guides'
import { GuideFinder } from '@/components/guide-finder'
import type { Metadata } from 'next'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Guides & Produkt-Finder — Crazy Babo Bazar',
  description: 'Kuratierte Guides zu Geschenken, Küchen-Gadgets, Home-Office-Setup und mehr. Plus Produkt-Finder mit Preis- und Persona-Filter.',
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
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Guides & Finder</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-4xl sm:text-5xl leading-tight text-[#0A0A0A] mb-3">
            Alle Guides
          </h1>
          <p className="text-[#555] text-base max-w-xl">
            Kuratierte Long-Form-Artikel zu Geschenkideen, Küchen-Gadgets und Setup-Themen. Unten findest du zusätzlich den Produkt-Finder.
          </p>
        </div>
      </section>

      {/* ── Guides Grid ───────────────────────────────────────── */}
      <section style={{ borderBottom: '2px solid #0A0A0A', backgroundColor: '#FFFFFF' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {guides.map((g) => (
              <Link
                key={g.slug}
                href={`/guide/${g.slug}`}
                className="group flex flex-col border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors p-6"
              >
                <div className="flex items-center gap-2 mb-4">
                  <span className="bg-[#0A0A0A] text-white text-[9px] font-black px-2 py-0.5 uppercase tracking-widest">
                    Guide
                  </span>
                  <span className="text-[#555] text-xs">{g.category}</span>
                  <span className="text-[#555]">·</span>
                  <span className="text-[#555] text-xs">{g.readTime}</span>
                </div>
                <h2 className="font-[family-name:var(--font-display)] font-black text-xl sm:text-2xl text-[#0A0A0A] leading-tight mb-3">
                  {g.title}
                </h2>
                <p className="text-[#555] text-sm leading-relaxed">
                  {g.subtitle}
                </p>
                <span className="mt-4 text-xs font-bold text-[#0A0A0A] font-[family-name:var(--font-mono)] uppercase tracking-widest inline-block group-hover:translate-x-0.5 transition-transform">
                  Guide lesen →
                </span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* ── Produkt-Finder ────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-1 h-6 bg-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Produkt-Finder</span>
          </div>
          <h2 className="font-[family-name:var(--font-display)] font-extrabold text-3xl sm:text-4xl leading-tight text-[#0A0A0A] mb-3">
            Was suchst du?
          </h2>
          <p className="text-[#555] text-base max-w-xl">
            Filter nach Preis, stöbere nach Beliebtheit oder lass dich von zufälligen Picks überraschen.
          </p>
        </div>
      </section>

      <GuideFinder products={products} />

      <p className="text-[#555] text-xs text-center pb-10">
        * Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
      </p>
    </div>
  )
}
