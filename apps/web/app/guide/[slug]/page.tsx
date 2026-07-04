import Link from 'next/link'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'
import { guides, getGuideBySlug } from '@/lib/guides'
import { getProductsBySlugs } from '@/lib/db'
import { getPriceBand } from '@/lib/db-types'
import type { DbProduct } from '@/lib/db-types'

const SITE_URL = 'https://www.crazybabobazar.com'

type Props = { params: Promise<{ slug: string }> }

export const revalidate = 3600

export async function generateStaticParams() {
  return guides.map((g) => ({ slug: g.slug }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const guide = getGuideBySlug(slug)
  if (!guide) return {}
  return {
    title: `${guide.title} — Crazy Babo Bazar`,
    description: guide.metaDescription,
    alternates: { canonical: `/guide/${slug}` },
    openGraph: {
      title: guide.title,
      description: guide.metaDescription,
      url: `${SITE_URL}/guide/${slug}`,
      type: 'article',
      publishedTime: guide.publishedAt,
      modifiedTime: guide.updatedAt ?? guide.publishedAt,
    },
    twitter: {
      card: 'summary_large_image',
      title: guide.title,
      description: guide.metaDescription,
    },
  }
}

export default async function GuidePage({ params }: Props) {
  const { slug } = await params
  const guide = getGuideBySlug(slug)
  if (!guide) notFound()

  const otherGuides = guides.filter((g) => g.slug !== slug)

  // Collect all product slugs referenced in the guide and fetch them in one query.
  const allSlugs = Array.from(
    new Set(guide.sections.flatMap((s) => s.productSlugs ?? []))
  )
  const products = allSlugs.length > 0 ? await getProductsBySlugs(allSlugs) : []
  const productMap = new Map<string, DbProduct>(products.map((p) => [p.slug, p]))

  const guideUrl = `${SITE_URL}/guide/${slug}`

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: guide.title,
    description: guide.metaDescription,
    datePublished: guide.publishedAt,
    dateModified: guide.updatedAt ?? guide.publishedAt,
    author: { '@type': 'Organization', name: 'Crazy Babo Bazar' },
    publisher: {
      '@type': 'Organization',
      name: 'Crazy Babo Bazar',
      logo: { '@type': 'ImageObject', url: `${SITE_URL}/icon.svg` },
    },
    mainEntityOfPage: { '@type': 'WebPage', '@id': guideUrl },
    ...(guide.keywords ? { keywords: guide.keywords.join(', ') } : {}),
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Start', item: SITE_URL },
      { '@type': 'ListItem', position: 2, name: 'Guide', item: `${SITE_URL}/guide` },
      { '@type': 'ListItem', position: 3, name: guide.title, item: guideUrl },
    ],
  }

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />

      {/* ── BREADCRUMB ─────────────────────────────────────── */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            <span>→</span>
            <Link href="/guide" className="hover:text-[#0A0A0A] hover:underline transition-colors">Guide</Link>
            <span>→</span>
            <span className="text-[#0A0A0A] truncate max-w-[250px]">{guide.title}</span>
          </div>
        </div>
      </div>

      {/* ── GUIDE HEADER ───────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-16">
          <div className="max-w-3xl">
            <div className="flex flex-wrap items-center gap-3 mb-6">
              <span className="bg-[#FFE500] text-[#0A0A0A] text-[10px] font-black px-3 py-1 uppercase tracking-widest">
                Guide
              </span>
              <span className="text-[#555] text-xs">{guide.category}</span>
              <span className="text-[#555]">·</span>
              <span className="text-[#555] text-xs">⏱ {guide.readTime} Lesezeit</span>
            </div>

            <h1 className="font-[family-name:var(--font-display)] font-extrabold text-4xl sm:text-5xl lg:text-6xl leading-tight mb-4 text-[#0A0A0A]">
              {guide.title}
            </h1>

            <p className="text-[#555] text-xl leading-relaxed">
              {guide.subtitle}
            </p>
          </div>
        </div>
      </section>

      {/* ── CONTENT ────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-px bg-[#0A0A0A]">
            {/* Article */}
            <article className="lg:col-span-2 bg-white p-8 lg:p-12">
              {/* Intro */}
              <div className="text-[#0A0A0A] text-lg leading-relaxed mb-12 pb-10 border-b-2 border-[#0A0A0A] space-y-5">
                {guide.intro.map((paragraph, i) => (
                  <p key={i}>{paragraph}</p>
                ))}
              </div>

              {/* Sections */}
              <div className="space-y-14">
                {guide.sections.map((section, i) => (
                  <div key={i} id={`section-${i + 1}`} className="scroll-mt-24">
                    <div className="flex items-start gap-4 mb-6">
                      <span className="font-[family-name:var(--font-display)] font-extrabold text-3xl text-[#E0E0E0] leading-none shrink-0 tabular-nums mt-1">
                        {String(i + 1).padStart(2, '0')}
                      </span>
                      <h2 className="font-[family-name:var(--font-body)] font-semibold text-2xl leading-tight text-[#0A0A0A]">
                        {section.heading}
                      </h2>
                    </div>
                    <div className="text-[#555] leading-relaxed pl-12 space-y-4">
                      {section.body.map((paragraph, j) => (
                        <p key={j}>{paragraph}</p>
                      ))}
                    </div>

                    {/* Inline product references */}
                    {section.productSlugs && section.productSlugs.length > 0 && (
                      <div className="pl-12 mt-8 grid grid-cols-1 sm:grid-cols-2 gap-3">
                        {section.productSlugs
                          .map((s) => productMap.get(s))
                          .filter((p): p is DbProduct => Boolean(p))
                          .map((p) => (
                            <Link
                              key={p.slug}
                              href={`/produkt/${p.slug}`}
                              className="group flex gap-3 border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors p-3"
                            >
                              <div className="w-20 h-20 shrink-0 bg-[#F5F5F5] border border-[#0A0A0A] relative overflow-hidden">
                                {p.image_url ? (
                                  <Image
                                    src={p.image_url}
                                    alt={p.name}
                                    fill
                                    className="object-contain p-2"
                                    unoptimized
                                    sizes="80px"
                                  />
                                ) : (
                                  <div className="absolute inset-0 flex items-center justify-center text-2xl">📦</div>
                                )}
                              </div>
                              <div className="flex flex-col justify-between min-w-0">
                                <p className="font-[family-name:var(--font-display)] font-black text-xs text-[#0A0A0A] leading-tight line-clamp-2">
                                  {p.name}
                                </p>
                                <span
                                  className="text-[9px] font-bold font-[family-name:var(--font-mono)] w-fit"
                                  style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '1px 6px' }}
                                >
                                  {getPriceBand(p.price_cents)}
                                </span>
                              </div>
                            </Link>
                          ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>

              {/* Affiliate Note */}
              <div className="mt-14 pt-8 border-t border-[#E0E0E0]">
                <p className="text-[#555] text-xs leading-relaxed">
                  * Dieser Guide enthält Affiliate-Links. Käufe über unsere Links unterstützen Crazy Babo Bazar ohne Mehrkosten für dich.
                </p>
              </div>
            </article>

            {/* Sidebar */}
            <aside className="bg-[#F5F5F5] p-6 flex flex-col gap-6">
              <div>
                <div className="text-[#555] text-xs uppercase tracking-widest mb-4 font-bold">In diesem Guide</div>
                <ul className="space-y-3">
                  {guide.sections.map((section, i) => (
                    <li key={i}>
                      <a
                        href={`#section-${i + 1}`}
                        className="flex items-start gap-2 text-sm text-[#555] hover:text-[#0A0A0A] transition-colors leading-tight group"
                      >
                        <span className="text-[#0A0A0A] font-black shrink-0">{String(i + 1).padStart(2, '0')}.</span>
                        <span className="leading-tight group-hover:underline">{section.heading}</span>
                      </a>
                    </li>
                  ))}
                </ul>
              </div>

              {otherGuides.length > 0 && (
                <div className="pt-6 border-t border-[#E0E0E0]">
                  <div className="text-[#555] text-xs uppercase tracking-widest mb-4 font-bold">Weitere Guides</div>
                  <ul className="space-y-3">
                    {otherGuides.map((g) => (
                      <li key={g.slug}>
                        <Link
                          href={`/guide/${g.slug}`}
                          className="block text-sm text-[#555] hover:text-[#0A0A0A] transition-colors leading-tight group"
                        >
                          <span className="group-hover:translate-x-0.5 inline-block transition-transform">
                            {g.title} →
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              <div className="pt-6 border-t border-[#E0E0E0] mt-auto">
                <Link
                  href="/"
                  className="block text-center border-2 border-[#0A0A0A] text-[#0A0A0A] px-4 py-3 text-sm font-bold hover:bg-[#FFE500] hover:border-[#FFE500] transition-all"
                >
                  Alle Deals entdecken →
                </Link>
              </div>
            </aside>
          </div>
        </div>
      </section>
    </div>
  )
}
