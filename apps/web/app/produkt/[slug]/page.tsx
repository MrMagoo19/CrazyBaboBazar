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
    openGraph: {
      title: `${product.name} — Crazy Babo Bazar`,
      description: product.tagline ?? product.description ?? '',
      images: product.image_url ? [{ url: product.image_url }] : [],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${product.name} — Crazy Babo Bazar`,
      images: product.image_url ? [product.image_url] : [],
    },
  }
}

export default async function ProduktPage({ params }: Props) {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) notFound()

  const catEmoji = product.categories?.emoji ?? '📦'

  // Prefer new persona-based routing, fall back to old categories
  const persona = product.shop_persona
  const mainCat = product.shop_main_category
  const catSlug = persona && mainCat ? `${persona}s/${mainCat}` : `kategorie/${product.categories?.slug ?? ''}`
  const catName = persona && mainCat
    ? `${persona.charAt(0).toUpperCase() + persona.slice(1)} · ${mainCat}`
    : (product.categories?.name ?? '')

  return (
    <div>
      {/* ── BREADCRUMB ─────────────────────────────────────── */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            <span>→</span>
            <Link href={`/${catSlug}`} className="hover:text-[#0A0A0A] hover:underline transition-colors">
              {catName}
            </Link>
            <span>→</span>
            <span className="text-[#0A0A0A] truncate max-w-[200px]">{product.name}</span>
          </div>
        </div>
      </div>

      {/* ── MAIN PRODUCT ───────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-px bg-[#0A0A0A]">
            {/* Image */}
            <div className="bg-white border-2 border-[#0A0A0A] aspect-square flex items-center justify-center relative overflow-hidden p-8">
              {product.image_url ? (
                <Image
                  src={product.image_url}
                  alt={product.name}
                  fill
                  className="object-contain p-8"
                  sizes="(max-width: 1024px) 100vw, 50vw"
                />
              ) : (
                <span className="text-[160px] opacity-20 select-none">{catEmoji}</span>
              )}
              {product.is_featured && (
                <div className="absolute top-6 left-6">
                  <span className="bg-[#FFE500] text-[#0A0A0A] text-xs font-black px-3 py-1 uppercase tracking-wide">
                    Featured
                  </span>
                </div>
              )}
            </div>

            {/* Info */}
            <div className="bg-white p-8 lg:p-12 flex flex-col justify-center">
              <Link
                href={`/kategorie/${catSlug}`}
                className="inline-block bg-[#FFE500] text-[#0A0A0A] text-xs font-black px-2 py-0.5 uppercase tracking-widest mb-4"
              >
                ← {catName}
              </Link>

              <h1 className="font-[family-name:var(--font-body)] font-bold text-2xl sm:text-3xl leading-snug mb-3 text-[#0A0A0A]">
                {product.name}
              </h1>

              {product.tagline && (
                <p className="text-[#555] font-semibold text-base mb-4">{product.tagline}</p>
              )}

              <p className="text-[#555555] text-base leading-relaxed mb-8">
                {product.description ?? ''}
              </p>

              {/* CTA */}
              <div className="border-t-2 border-[#E0E0E0] pt-8">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <div className="text-[#555] text-xs uppercase tracking-wider mb-1">Preis (ca.)</div>
                    <div className="font-[family-name:var(--font-body)] font-bold text-4xl text-[#0A0A0A]" style={{ letterSpacing: '-0.02em' }}>
                      {formatPrice(product.price_cents)}€
                    </div>
                    <div className="text-[#555] text-[10px] mt-1">inkl. MwSt. · zzgl. Versand</div>
                  </div>
                  <div className="text-right text-xs text-[#555]">
                    <div>Preis kann variieren.</div>
                    <div>Affiliate-Link*</div>
                  </div>
                </div>

                <a
                  href={product.affiliate_url}
                  target="_blank"
                  rel="noopener noreferrer sponsored"
                  className="block w-full text-center bg-[#0A0A0A] text-white py-4 font-bold text-base hover:bg-[#FFE500] hover:text-[#0A0A0A] transition-all duration-200 mb-3"
                >
                  Jetzt auf Amazon ansehen →
                </a>

                <p className="text-[#555] text-xs text-center">
                  * Als Amazon-Partner verdienen wir an qualifizierten Käufen. Kein Aufpreis für dich.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── VIDEO ─────────────────────────────────────────── */}
      {product.video_url && (
        <section className="border-b-2 border-[#0A0A0A]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-1 h-6 bg-[#FFE500]" />
              <span className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">Produkt-Video</span>
            </div>
            <div className="relative w-full aspect-video bg-white border-2 border-[#0A0A0A]">
              <iframe
                src={product.video_url}
                title={`${product.name} Video`}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="absolute inset-0 w-full h-full"
              />
            </div>
          </div>
        </section>
      )}

      {/* ── DISCLAIMER ─────────────────────────────────────── */}
      <section>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="border-2 border-[#0A0A0A] p-6 bg-white">
            <div className="text-[#0A0A0A] text-xs font-bold uppercase tracking-widest mb-2">Affiliate-Hinweis</div>
            <p className="text-[#555555] text-xs leading-relaxed">
              Dieser Beitrag enthält Affiliate-Links. Wenn du über einen unserer Links ein Produkt kaufst, erhalten wir eine Provision. Der Preis für dich bleibt derselbe.
            </p>
          </div>
        </div>
      </section>

      {/* ── SCHEMA.ORG ─────────────────────────────────────── */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'Product',
            name: product.name,
            description: product.description ?? '',
            image: product.image_url ?? '',
            offers: {
              '@type': 'Offer',
              price: ((product.price_cents ?? 0) / 100).toFixed(2),
              priceCurrency: 'EUR',
              availability: 'https://schema.org/InStock',
              url: product.affiliate_url,
              seller: {
                '@type': 'Organization',
                name: 'Amazon',
              },
            },
          }),
        }}
      />
    </div>
  )
}
