import Link from 'next/link'
import { notFound } from 'next/navigation'
import { categories, getCategoryBySlug, getProductsByCategory, products } from '@/lib/data'
import type { Metadata } from 'next'

type Props = { params: Promise<{ slug: string }> }

export async function generateStaticParams() {
  return categories.map((c) => ({ slug: c.slug }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const cat = getCategoryBySlug(slug)
  if (!cat) return {}
  return {
    title: `${cat.name} — Crazy Babo Bazar`,
    description: cat.description,
  }
}

export default async function KategoriePage({ params }: Props) {
  const { slug } = await params
  const category = getCategoryBySlug(slug)
  if (!category) notFound()

  const catProducts = getProductsByCategory(slug)
  // Fallback: show all products if category has none yet
  const displayProducts = catProducts.length > 0 ? catProducts : products.slice(0, 4)

  const otherCategories = categories.filter((c) => c.slug !== slug)

  return (
    <div>
      {/* ── HEADER ─────────────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          {/* Breadcrumb */}
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
                {category.count}
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
          {displayProducts.length === 0 ? (
            <div className="text-center py-24 text-[#6B6560]">
              <div className="text-5xl mb-4">🔍</div>
              <p className="text-xl font-bold mb-2">Noch keine Produkte</p>
              <p className="text-sm">Wir arbeiten daran. Schau bald wieder vorbei.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-px bg-[#333333]">
              {displayProducts.map((product) => (
                <Link
                  key={product.slug}
                  href={`/produkt/${product.slug}`}
                  className="bg-[#1C1C1C] p-5 group hover:bg-[#252525] transition-colors block"
                >
                  {/* Image */}
                  <div className="aspect-square bg-[#252525] mb-4 relative border border-[#333333] overflow-hidden">
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="text-5xl opacity-25 group-hover:opacity-50 transition-opacity select-none">
                        {category.emoji}
                      </span>
                    </div>
                    {product.tag && (
                      <div className="absolute top-2 left-2">
                        <span className="bg-[#E8321C] text-[#F0EDE8] text-[10px] font-bold px-2 py-0.5 uppercase tracking-wide">
                          {product.tag}
                        </span>
                      </div>
                    )}
                  </div>

                  <h2 className="font-[family-name:var(--font-display)] font-bold text-base leading-tight mb-2 group-hover:text-[#E85000] transition-colors">
                    {product.name}
                  </h2>

                  <div className="flex items-center gap-1.5 mb-3">
                    <div className="flex gap-0.5" aria-label={`${product.rating} von 5 Sternen`}>
                      {[1, 2, 3, 4, 5].map((star) => (
                        <span
                          key={star}
                          className={`text-[10px] ${star <= Math.round(product.rating) ? 'text-[#E85000]' : 'text-[#333333]'}`}
                        >
                          ★
                        </span>
                      ))}
                    </div>
                    <span className="text-[#6B6560] text-[10px]">({product.reviews.toLocaleString('de-DE')})</span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="font-[family-name:var(--font-display)] font-bold text-lg">
                      {product.price}€
                    </span>
                    <span className="text-[#E85000] text-[11px] font-bold group-hover:translate-x-0.5 transition-transform inline-block">
                      →
                    </span>
                  </div>
                </Link>
              ))}
            </div>
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
