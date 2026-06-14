import { getListBySlug, getProductsBySlugs, getAllLists } from '@/lib/db'
// Note: getAllLists used only for "Weitere Listen" section, not generateStaticParams
import { getPriceBand } from '@/lib/db-types'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'
import Image from 'next/image'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

type Props = { params: Promise<{ slug: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const list = await getListBySlug(slug)
  if (!list) return {}
  return {
    title: `${list.title} — Crazy Babo Bazar`,
    description: list.intro ?? `${list.product_slugs.length} handverlesene Produkte: ${list.title}`,
    openGraph: {
      title: `${list.title} — Crazy Babo Bazar`,
      description: list.intro ?? '',
      images: [{ url: `https://www.crazybabobazar.com/api/listen-og/${slug}`, width: 1200, height: 630 }],
    },
  }
}

export default async function ListDetailPage({ params }: Props) {
  const { slug } = await params
  const [list, allLists] = await Promise.all([getListBySlug(slug), getAllLists()])
  if (!list) notFound()

  const products = await getProductsBySlugs(list.product_slugs)

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: list.title,
    description: list.intro ?? '',
    url: `https://www.crazybabobazar.com/listen/${list.slug}`,
    numberOfItems: products.length,
    itemListElement: products.map((p, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      name: p.name,
      url: `https://www.crazybabobazar.com/produkt/${p.slug}`,
    })),
  }

  const breadcrumbLd = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Start', item: 'https://www.crazybabobazar.com' },
      { '@type': 'ListItem', position: 2, name: 'Listen', item: 'https://www.crazybabobazar.com/listen' },
      { '@type': 'ListItem', position: 3, name: list.title, item: `https://www.crazybabobazar.com/listen/${list.slug}` },
    ],
  }

  const otherLists = allLists.filter(l => l.slug !== slug).slice(0, 3)

  return (
    <div>
      {/* Schema.org */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbLd) }} />

      {/* Breadcrumb */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline">Start</Link>
            <span>→</span>
            <Link href="/listen" className="hover:text-[#0A0A0A] hover:underline">Listen</Link>
            <span>→</span>
            <span className="text-[#0A0A0A] truncate max-w-[200px]">{list.title}</span>
          </div>
        </div>
      </div>

      {/* Header */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-4 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            {products.length} Produkte
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-black text-3xl sm:text-5xl text-white leading-none mb-4" style={{ letterSpacing: '-0.03em' }}>
            {list.title}
          </h1>
          {list.intro && (
            <div className="text-[#AAA] text-base leading-relaxed max-w-2xl space-y-4">
              {list.intro.split('\n\n').map((para, i) => (
                <p key={i}>{para}</p>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Product grid */}
      <section>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {products.map((product, i) => (
              <Link
                key={product.slug}
                href={`/produkt/${product.slug}`}
                className="group flex flex-col border-2 border-[#0A0A0A] hover:border-[#FFE500] transition-colors"
              >
                {/* Position badge */}
                <div className="relative">
                  <div className="aspect-square bg-[#F5F5F5] border-b-2 border-[#0A0A0A] relative overflow-hidden">
                    {product.image_url ? (
                      <Image
                        src={product.image_url}
                        alt={product.name}
                        fill
                        className="object-contain p-6"
                        unoptimized
                      />
                    ) : (
                      <div className="absolute inset-0 flex items-center justify-center text-5xl">📦</div>
                    )}
                  </div>
                  <div
                    className="absolute top-3 left-3 font-[family-name:var(--font-mono)] font-black text-[11px]"
                    style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 7px' }}
                  >
                    #{i + 1}
                  </div>
                </div>

                <div className="p-4 flex flex-col gap-2 flex-1">
                  {product.shop_persona && (
                    <span
                      className="text-[9px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] w-fit"
                      style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 6px' }}
                    >
                      {product.shop_persona}
                    </span>
                  )}
                  <h2 className="font-[family-name:var(--font-display)] font-black text-[#0A0A0A] text-sm leading-tight group-hover:text-[#555] transition-colors">
                    {product.name}
                  </h2>
                  {product.tagline && (
                    <p className="text-xs text-[#555] line-clamp-2 flex-1">{product.tagline}</p>
                  )}
                  <div
                    className="text-xs font-bold font-[family-name:var(--font-mono)] mt-auto w-fit"
                    style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
                  >
                    {getPriceBand(product.price_cents)}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Geeklist: JARVIS Ebook CTA */}
      {slug === 'geeklist' && (
        <section style={{ backgroundColor: '#0A0A0A', borderTop: '2px solid #FFE500', borderBottom: '2px solid #FFE500' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10 flex flex-col sm:flex-row items-center justify-between gap-6">
            <div>
              <div
                className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest mb-2 inline-block"
                style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
              >
                Gratis E-Book
              </div>
              <h3 className="font-[family-name:var(--font-display)] font-black text-xl text-white leading-tight">
                Baue deinen eigenen JARVIS mit Claude
              </h3>
              <p className="text-[#AAA] text-sm mt-1 max-w-md">
                28 Seiten. Lauffähiger Code. Stimme, Briefings & Gedächtnis — kein Account, kein Kauf.
              </p>
            </div>
            <a
              href="/api/download/ebook"
              download="Jarvis-mit-Claude-Ebook.pdf"
              className="shrink-0 font-bold text-sm px-6 py-3 border-2 border-[#FFE500] bg-[#FFE500] text-[#0A0A0A] hover:bg-transparent hover:text-[#FFE500] transition-colors"
            >
              ↓ Kostenlos downloaden
            </a>
          </div>
        </section>
      )}

      {/* Article body */}
      {list.body && (
        <section className="border-t-2 border-[#0A0A0A] bg-white">
          <div className="max-w-3xl mx-auto px-4 sm:px-6 py-14">
            {list.body.split('\n\n').map((block, i) => {
              if (block.startsWith('## ')) {
                return (
                  <h2 key={i} className="font-[family-name:var(--font-display)] font-black text-xl sm:text-2xl text-[#0A0A0A] mt-12 mb-4 leading-tight">
                    {block.slice(3)}
                  </h2>
                )
              }
              return <p key={i} className="text-[#444] text-base leading-relaxed mb-4">{block}</p>
            })}
          </div>
        </section>
      )}

      {/* Other lists */}
      {otherLists.length > 0 && (
        <section className="border-t-2 border-[#0A0A0A]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <h2 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A] mb-6">
              Weitere Listen
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {otherLists.map(l => (
                <Link
                  key={l.slug}
                  href={`/listen/${l.slug}`}
                  className="group border-2 border-[#0A0A0A] p-5 hover:bg-[#FFE500] transition-colors"
                >
                  <div
                    className="font-[family-name:var(--font-mono)] text-[9px] font-black uppercase tracking-widest mb-2 w-fit"
                    style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 6px' }}
                  >
                    {l.product_slugs.length} Produkte
                  </div>
                  <div className="font-[family-name:var(--font-display)] font-black text-[#0A0A0A] leading-tight">
                    {l.title}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}
    </div>
  )
}
