import Link from 'next/link'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { getProductBySlug, getRelatedProducts } from '@/lib/db'
import { getPriceBand } from '@/lib/db-types'
import { ShareButton } from '@/components/ui/share-button'
import { ImageSlider } from '@/components/ui/image-slider'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

const SITE_URL = 'https://www.crazybabobazar.com'

type Props = { params: Promise<{ slug: string }> }

function toMetaDescription(description: string | null | undefined, tagline: string | null | undefined): string {
  const raw = (description && description.trim()) || (tagline && tagline.trim()) || ''
  if (!raw) return ''
  const clean = raw
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/\*\*/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  if (clean.length <= 160) return clean
  return clean.slice(0, 157).trimEnd() + '…'
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) return {}
  const metaDescription = toMetaDescription(product.description, product.tagline)
  return {
    title: `${product.name} — Crazy Babo Bazar`,
    description: metaDescription,
    alternates: {
      canonical: `${SITE_URL}/produkt/${slug}`,
    },
    openGraph: {
      title: `${product.name} — Crazy Babo Bazar`,
      description: metaDescription,
      url: `${SITE_URL}/produkt/${slug}`,
      images: [{ url: `${SITE_URL}/api/pin/${slug}`, width: 1000, height: 1500 }],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${product.name} — Crazy Babo Bazar`,
      description: metaDescription,
      images: [`${SITE_URL}/api/pin/${slug}`],
    },
  }
}

export default async function ProduktPage({ params }: Props) {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) notFound()

  const related = await getRelatedProducts(slug, product.shop_persona, product.shop_main_category)

  const catEmoji = product.categories?.emoji ?? '📦'

  // Prefer new persona-based routing, fall back to old categories
  const persona = product.shop_persona
  const mainCat = product.shop_main_category
  const personaRoute: Record<string, string> = { babo: 'babos', queen: 'queens', miniboss: 'miniboss' }
  const catSlug = persona && mainCat ? `${personaRoute[persona] ?? persona}/${mainCat}` : `kategorie/${product.categories?.slug ?? ''}`
  const catName = persona && mainCat
    ? `${persona.charAt(0).toUpperCase() + persona.slice(1)} · ${mainCat}`
    : (product.categories?.name ?? '')

  const schemaDescription = toMetaDescription(product.description, product.tagline)
  const productUrl = `${SITE_URL}/produkt/${slug}`
  const productImages = (product.image_urls && product.image_urls.length > 0
    ? product.image_urls
    : product.image_url ? [product.image_url] : []
  )

  const productSchema: Record<string, unknown> = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: schemaDescription,
    url: productUrl,
    ...(productImages.length > 0 ? { image: productImages } : {}),
    brand: { '@type': 'Brand', name: 'Crazy Babo Bazar' },
    ...(product.price_cents
      ? {
          offers: {
            '@type': 'Offer',
            url: product.affiliate_url,
            priceCurrency: 'EUR',
            price: (product.price_cents / 100).toFixed(2),
            availability: 'https://schema.org/InStock',
          },
        }
      : {}),
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Start', item: SITE_URL },
      ...(catName && catSlug
        ? [{ '@type': 'ListItem', position: 2, name: catName, item: `${SITE_URL}/${catSlug}` }]
        : []),
      { '@type': 'ListItem', position: catName ? 3 : 2, name: product.name, item: productUrl },
    ],
  }

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />

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
            {/* Image / Slider */}
            {product.image_urls && product.image_urls.length > 1 ? (
              <ImageSlider
                images={product.image_urls}
                name={product.name}
                isFeatured={product.is_featured}
              />
            ) : (
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
            )}

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
                  const segments: { text: string; url?: string }[] = []
                  const re = /\[([^\]]+)\]\(([^)]+)\)/g
                  let last = 0, m: RegExpExecArray | null
                  while ((m = re.exec(line)) !== null) {
                    if (m.index > last) segments.push({ text: line.slice(last, m.index) })
                    segments.push({ text: m[1], url: m[2] })
                    last = re.lastIndex
                  }
                  if (last < line.length) segments.push({ text: line.slice(last) })
                  return (
                    <p key={i}>
                      {segments.map((seg, j) =>
                        seg.url ? (
                          <a key={j} href={seg.url}
                            className="text-[#0A0A0A] font-bold underline underline-offset-2 hover:text-[#555] transition-colors"
                            target={seg.url.startsWith('http') ? '_blank' : undefined}
                            rel={seg.url.startsWith('http') ? 'noopener noreferrer' : undefined}
                          >{seg.text}</a>
                        ) : (
                          <span key={j}>{seg.text.replace(/\*\*/g, '')}</span>
                        )
                      )}
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

      {/* ── UNSER URTEIL ───────────────────────────────────── */}
      {product.editorial_note && (
        <section style={{ backgroundColor: '#FFFFFF', borderBottom: '2px solid #0A0A0A' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div style={{ backgroundColor: '#FFE500', border: '2px solid #0A0A0A', padding: '24px 28px' }}>
              <div className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#0A0A0A] mb-3">
                Unser Urteil
              </div>
              <p className="text-[#0A0A0A] text-base leading-relaxed font-medium">
                {product.editorial_note}
              </p>
            </div>
          </div>
        </section>
      )}

      {/* ── ÄHNLICHE PRODUKTE ──────────────────────────────── */}
      {related.length > 0 && (
        <section style={{ backgroundColor: '#F8F8F8', borderTop: '2px solid #0A0A0A', borderBottom: '2px solid #0A0A0A' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <h2 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A] mb-6">
              Könnte dich auch interessieren
            </h2>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {related.map((p) => (
                <Link
                  key={p.slug}
                  href={`/produkt/${p.slug}`}
                  className="group flex flex-col border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors"
                >
                  <div className="aspect-square bg-[#F5F5F5] border-b-2 border-[#0A0A0A] relative overflow-hidden">
                    {p.image_url ? (
                      <Image src={p.image_url} alt={p.name} fill className="object-contain p-4" unoptimized />
                    ) : (
                      <div className="absolute inset-0 flex items-center justify-center text-4xl">📦</div>
                    )}
                  </div>
                  <div className="p-3 flex flex-col gap-1.5 flex-1">
                    <p className="font-[family-name:var(--font-display)] font-black text-xs text-[#0A0A0A] leading-tight line-clamp-2">
                      {p.name}
                    </p>
                    <span
                      className="text-[9px] font-bold font-[family-name:var(--font-mono)] mt-auto w-fit"
                      style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '1px 6px' }}
                    >
                      {getPriceBand(p.price_cents)}
                    </span>
                  </div>
                </Link>
              ))}
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
