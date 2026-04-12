import Link from 'next/link'
import { notFound } from 'next/navigation'
import { guides, getGuideBySlug } from '@/lib/data'
import type { Metadata } from 'next'

type Props = { params: Promise<{ slug: string }> }

export async function generateStaticParams() {
  return guides.map((g) => ({ slug: g.slug }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const guide = getGuideBySlug(slug)
  if (!guide) return {}
  return {
    title: `${guide.title} — Crazy Babo Bazar`,
    description: guide.subtitle,
  }
}

export default async function GuidePage({ params }: Props) {
  const { slug } = await params
  const guide = getGuideBySlug(slug)
  if (!guide) notFound()

  const otherGuides = guides.filter((g) => g.slug !== slug)

  return (
    <div>
      {/* ── BREADCRUMB ─────────────────────────────────────── */}
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#6B6560]">
            <Link href="/" className="hover:text-[#E85000] transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#9E9890]">Guide</span>
            <span>→</span>
            <span className="text-[#9E9890] truncate max-w-[200px]">{guide.title}</span>
          </div>
        </div>
      </div>

      {/* ── GUIDE HEADER ───────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-16">
          <div className="max-w-3xl">
            <div className="flex items-center gap-3 mb-6">
              <span className="bg-[#E85000] text-[#1C1C1C] text-[10px] font-bold px-3 py-1 uppercase tracking-widest">
                Guide
              </span>
              <span className="text-[#6B6560] text-xs">{guide.category}</span>
              <span className="text-[#3A3A3A]">·</span>
              <span className="text-[#6B6560] text-xs">⏱ {guide.readTime} Lesezeit</span>
            </div>

            <h1 className="font-[family-name:var(--font-display)] font-extrabold text-4xl sm:text-5xl lg:text-6xl leading-tight mb-4">
              {guide.title}
            </h1>

            <p className="text-[#9E9890] text-xl leading-relaxed">
              {guide.subtitle}
            </p>
          </div>
        </div>
      </section>

      {/* ── CONTENT ────────────────────────────────────────── */}
      <section className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-px bg-[#333333]">
            {/* Article */}
            <div className="lg:col-span-2 bg-[#1C1C1C] p-8 lg:p-12">
              {/* Intro */}
              <p className="text-[#F0EDE8] text-lg leading-relaxed mb-10 pb-10 border-b border-[#333333]">
                {guide.intro}
              </p>

              {/* Sections */}
              <div className="space-y-10">
                {guide.sections.map((section, i) => (
                  <div key={i}>
                    <div className="flex items-start gap-4 mb-4">
                      <span className="font-[family-name:var(--font-display)] font-extrabold text-3xl text-[#333333] leading-none shrink-0 tabular-nums mt-1">
                        {String(i + 1).padStart(2, '0')}
                      </span>
                      <h2 className="font-[family-name:var(--font-display)] font-bold text-xl leading-tight text-[#F0EDE8]">
                        {section.heading}
                      </h2>
                    </div>
                    <p className="text-[#9E9890] leading-relaxed pl-12">
                      {section.body}
                    </p>
                  </div>
                ))}
              </div>

              {/* Affiliate Note */}
              <div className="mt-12 pt-8 border-t border-[#333333]">
                <p className="text-[#3A3A3A] text-xs leading-relaxed">
                  * Dieser Guide enthält Affiliate-Links. Käufe über unsere Links unterstützen Crazy Babo Bazar ohne Mehrkosten für dich.
                </p>
              </div>
            </div>

            {/* Sidebar */}
            <div className="bg-[#252525] p-6 flex flex-col gap-6">
              <div>
                <div className="text-[#6B6560] text-xs uppercase tracking-widest mb-4">In diesem Guide</div>
                <ul className="space-y-3">
                  {guide.sections.map((section, i) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-[#9E9890]">
                      <span className="text-[#E85000] font-bold shrink-0">{String(i + 1).padStart(2, '0')}.</span>
                      <span className="leading-tight">{section.heading}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {otherGuides.length > 0 && (
                <div className="pt-6 border-t border-[#333333]">
                  <div className="text-[#6B6560] text-xs uppercase tracking-widest mb-4">Weitere Guides</div>
                  <ul className="space-y-3">
                    {otherGuides.map((g) => (
                      <li key={g.slug}>
                        <Link
                          href={`/guide/${g.slug}`}
                          className="block text-sm text-[#9E9890] hover:text-[#E85000] transition-colors leading-tight group"
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

              <div className="pt-6 border-t border-[#333333] mt-auto">
                <Link
                  href="/"
                  className="block text-center border border-[#E85000] text-[#E85000] px-4 py-3 text-sm font-bold hover:bg-[#E85000] hover:text-[#1C1C1C] transition-all"
                >
                  Alle Deals entdecken →
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
