import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getCategoryBySlug, getCategories, getProductsByCategory } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

type Props = { params: Promise<{ slug: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const cat = await getCategoryBySlug(slug)
  if (!cat) return {}
  return {
    title: `${cat.name} — Crazy Babo Bazar`,
    description: cat.description ?? '',
  }
}

export default async function KategoriePage({ params }: Props) {
  const { slug } = await params
  const [category, products, allCategories] = await Promise.all([
    getCategoryBySlug(slug),
    getProductsByCategory(slug),
    getCategories(),
  ])

  if (!category) notFound()

  const otherCategories = allCategories.filter((c) => c.slug !== slug)

  return (
    <div>
      {/* ── HEADER ─────────────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center gap-2 py-4 text-xs text-[#6B6560]">
            <Link href="/" className="hover:text-[#E85000] transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#9E9890]">{category.name}</span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 border-t border-[#333333]">
            <div className="lg:col-span-2 py-12 pr-0 lg:pr-12 lg:border-r border-[#333333]">
              <div className="text-6xl mb-4">{category.emoji}</div>
              <h1 className="font-[family-name:var(--font-display)] font-extrabold text-5xl sm:text-6xl leading-tight mb-4">
                {category.name}
              </h1>
              <p className="text-[#9E9890] text-lg max-w-xl leading-relaxed">
                {category.description}
              </p>
            </div>

            <div className="py-12 pl-0 lg:pl-12 flex flex-col justify-center">
              <div className="font-[family-name:var(--font-display)] font-extrabold text-7xl text-[#E85000] mb-2 tabular-nums">
                {products.length}
              </div>
              <div className="text-[#6B6560] text-sm uppercase tracking-widest">
                Produkte in dieser Kategorie
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── PRODUCTS GRID ──────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14">
          {products.length === 0 ? (
            <div className="text-center py-24 text-[#6B6560]">
              <div className="text-5xl mb-4">🔍</div>
              <p className="text-xl font-bold mb-2">Noch keine Produkte</p>
              <p className="text-sm">Wir arbeiten daran. Schau bald wieder vorbei.</p>
            </div>
          ) : (
            <ProductGrid products={products} />
          )}
        </div>
      </section>

      {/* ── ANDERE KATEGORIEN ──────────────────────────────── */}
      <section>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <h2 className="font-[family-name:var(--font-display)] font-bold text-xl mb-6 text-[#6B6560]">
            Weitere Kategorien
          </h2>
          <div className="flex flex-wrap gap-2">
            {otherCategories.map((cat) => (
              <Link
                key={cat.slug}
                href={`/kategorie/${cat.slug}`}
                className="flex items-center gap-2 px-4 py-2 border border-[#333333] text-sm text-[#9E9890] hover:border-[#E85000] hover:text-[#E85000] transition-all"
              >
                <span>{cat.emoji}</span>
                <span>{cat.name}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
