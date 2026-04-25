import Link from 'next/link'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { getProductBySlug, formatPrice } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

type Props = { params: Promise<{ slug: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) return {}
  return {
    title: `${product.name} — Crazy Babo Bazar`,
    description: product.tagline ?? product.description ?? '',
  }
}

export default async function ProduktPage({ params }: Props) {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) notFound()

  const catSlug = product.categories?.slug ?? ''
  const catName = product.categories?.name ?? ''
  const catEmoji = product.categories?.emoji ?? '📦'

  return (
    <div>
      {/* ── BREADCRUMB ─────────────────────────────────────── */}
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#6B6560]">
            <Link href="/" className="hover:text-[#E85000] transition-colors">Start</Link>
            <span>→</span>
            <Link href={`/kategorie/${catSlug}`} className="hover:text-[#E85000] transition-colors">
              {catName}
            </Link>
            <span>→</span>
            <span className="text-[#9E9890] truncate max-w-[200px]">{product.name}</span>
          </div>
        </div>
      </div>

      {/* ── MAIN PRODUCT ───────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-px bg-[#333333]">
            {/* Image */}
            <div className="bg-[#252525] aspect-square flex items-center justify-center relative overflow-hidden">
              {product.image_url ? (
                <Image
                  src={product.image_url}
                  alt={product.name}
                  fill
                  className="object-cover"
                  sizes="(max-width: 1024px) 100vw, 50vw"
                />
              ) : (
                <span className="text-[160px] opacity-20 select-none">{catEmoji}</span>
              )}
              {product.is_featured && (
                <div className="absolute top-6 left-6">
                  <span className="bg-[#E8321C] text-[#F0EDE8] text-xs font-bold px-3 py-1 uppercase tracking-wide">
                    Featured
                  </span>
                </div>
              )}
            </div>

            {/* Info */}
            <div className="bg-[#1C1C1C] p-8 lg:p-12 flex flex-col justify-center">
              <Link
                href={`/kategorie/${catSlug}`}
                className="text-[#E85000] text-xs font-bold uppercase tracking-widest mb-4 hover:text-[#E8321C] transition-colors inline-block"
              >
                ← {catName}
              </Link>

              <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl sm:text-4xl leading-tight mb-4">
                {product.name}
              </h1>

              {product.tagline && (
                <p className="text-[#E85000] text-base font-bold mb-4">{product.tagline}</p>
              )}

              <p className="text-[#9E9890] text-base leading-relaxed mb-8">
                {product.description ?? ''}
              </p>

              {/* CTA */}
              <div className="border-t border-[#333333] pt-8">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <div className="text-[#6B6560] text-xs uppercase tracking-wider mb-1">Preis (ca.)</div>
                    <div className="font-[family-name:var(--font-display)] font-extrabold text-4xl">
                      {formatPrice(product.price_cents)}€
                    </div>
                    <div className="text-[#6B6560] text-[10px] mt-1">inkl. MwSt. · zzgl. Versand</div>
                  </div>
                  <div className="text-right text-xs text-[#3A3A3A]">
                    <div>Preis kann variieren.</div>
                    <div>Affiliate-Link*</div>
                  </div>
                </div>

                <a
                  href={product.affiliate_url}
                  target="_blank"
                  rel="noopener noreferrer sponsored"
                  className="block w-full text-center bg-[#E85000] text-[#1C1C1C] py-4 font-bold text-base hover:bg-[#E8321C] hover:text-[#F0EDE8] transition-all duration-200 mb-3"
                >
                  Jetzt auf Amazon ansehen →
                </a>

                <p className="text-[#3A3A3A] text-xs text-center">
                  * Als Amazon-Partner verdienen wir an qualifizierten Käufen. Kein Aufpreis für dich.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── DISCLAIMER ─────────────────────────────────────── */}
      <section>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="border border-[#333333] p-6 bg-[#252525]">
            <div className="text-[#E85000] text-xs font-bold uppercase tracking-widest mb-2">Affiliate-Hinweis</div>
            <p className="text-[#6B6560] text-xs leading-relaxed">
              Dieser Beitrag enthält Affiliate-Links. Wenn du über einen unserer Links ein Produkt kaufst, erhalten wir eine Provision. Der Preis für dich bleibt derselbe.
            </p>
          </div>
        </div>
      </section>
    </div>
  )
}
