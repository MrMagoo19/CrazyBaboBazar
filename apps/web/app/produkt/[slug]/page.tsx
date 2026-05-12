import Link from 'next/link'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { getProductBySlug } from '@/lib/db'
import { getPriceBand } from '@/lib/db-types'
import { ShareButton } from '@/components/ui/share-button'
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
      images: [{ url: `https://www.crazybabobazar.com/api/pin/${slug}`, width: 1000, height: 1500 }],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${product.name} — Crazy Babo Bazar`,
      images: [`https://www.crazybabobazar.com/api/pin/${slug}`],
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
      <section style={{ borderBottom: '2px solid #0A0A0A', backgroundColor: '#FFFFFF' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex flex-col lg:flex-row">
            {/* Image */}
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '2px solid #0A0A0A',
                aspectRatio: '1 / 1',
                position: 'relative',
                overflow: 'hidden',
                flexShrink: 0,
              }}
              className="w-full lg:w-1/2"
            >
              {product.image_url ? (
                <Image
                  src={product.image_url}
                  alt={product.name}
                  fill
                  className="object-contain p-8"
                  sizes="(max-width: 1024px) 100vw, 50vw"
                />
              ) : (
                <span className="text-[160px] opacity-20 select-none absolute inset-0 flex items-center justify-center">{catEmoji}</span>
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
            <div
              style={{
                backgroundColor: '#FFFFFF',
                borderTop: '2px solid #0A0A0A',
                padding: '2rem',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                flex: 1,
              }}
              className="lg:border-t-0 lg:border-l-2 lg:border-l-[#0A0A0A] lg:p-12"
            >
              <Link
                href={`/${catSlug}`}
                className="font-[family-name:var(--font-mono)] font-bold text-[11px] uppercase tracking-widest mb-4 bg-[#FFE500] text-[#0A0A0A] px-2 py-1"
                style={{ alignSelf: 'flex-start' }}
              >
                ← {catName}
              </Link>

              <h1 className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl leading-tight mb-3 text-[#0A0A0A]">
                {product.name}
              </h1>

              {product.tagline && (
                <p className="text-[#555] font-semibold text-base mb-4">{product.tagline}</p>
              )}

              <div className="text-[#555555] text-base leading-relaxed mb-8 space-y-3">
                {(product.description ?? '').split('\n').map((line, i) => {
                  const parts = line.split(/(\[([^\]]+)\]\(([^)]+)\))/)
                  return (
                    <p key={i}>
                      {parts.map((part, j) => {
                        const match = part.match(/^\[([^\]]+)\]\(([^)]+)\)$/)
                        if (match) {
                          return (
                            <a key={j} href={match[2]}
                              className="text-[#0A0A0A] font-bold underline underline-offset-2 hover:text-[#555] transition-colors"
                              target={match[2].startsWith('http') ? '_blank' : undefined}
                              rel={match[2].startsWith('http') ? 'noopener noreferrer' : undefined}
                            >
                              {match[1]}
                            </a>
                          )
                        }
                        return part
                      })}
                    </p>
                  )
                })}
              </div>

              {/* CTA */}
              <div style={{ borderTop: '2px solid #E0E0E0', paddingTop: '2rem' }}>
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <div className="text-[#555] text-xs font-[family-name:var(--font-mono)] uppercase tracking-wider mb-2">Preisbereich</div>
                    <div className="font-[family-name:var(--font-mono)] font-bold text-3xl text-[#0A0A0A]">
                      {getPriceBand(product.price_cents)}
                    </div>
                    <div className="text-[#555] text-[10px] mt-1">Aktueller Preis auf Amazon</div>
                  </div>
                  <div className="text-right text-xs text-[#555] max-w-[140px]">
                    <div>Preis wird von Amazon</div>
                    <div>festgelegt & kann variieren.</div>
                  </div>
                </div>

                <a
                  href={product.affiliate_url}
                  target="_blank"
                  rel="noopener noreferrer sponsored"
                  className="block w-full text-center bg-[#0A0A0A] text-white py-4 font-bold text-base hover:bg-[#FFE500] hover:text-[#0A0A0A] transition-all duration-200 mb-3"
                >
                  Preis auf Amazon prüfen →
                </a>

                <ShareButton name={product.name} tagline={product.tagline} />

                <p className="text-[#555] text-xs text-center mt-3">
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
      <section style={{ backgroundColor: '#FFFFFF' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="border-2 border-[#0A0A0A] p-6" style={{ backgroundColor: '#FFFFFF' }}>
            <div className="text-[#0A0A0A] text-xs font-bold uppercase tracking-widest mb-2">Affiliate-Hinweis</div>
            <p className="text-[#555555] text-xs leading-relaxed">
              Dieser Beitrag enthält Affiliate-Links. Wenn du über einen unserer Links ein Produkt kaufst, erhalten wir eine Provision. Der Preis für dich bleibt derselbe.
            </p>
          </div>
        </div>
      </section>

    </div>
  )
}
