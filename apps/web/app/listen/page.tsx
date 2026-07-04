import { getAllLists } from '@/lib/db'
import type { Metadata } from 'next'
import Link from 'next/link'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Kuratierte Listen — Crazy Babo Bazar',
  description: 'Handverlesene Produktlisten nach Thema: Geschenke für Nerds, beste Gaming-Gadgets, Küchen-Hacks und mehr. Direkt auf Amazon verlinkt.',
  alternates: { canonical: '/listen' },
  openGraph: {
    images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }],
  },
}

export default async function ListenPage() {
  const lists = await getAllLists()

  return (
    <div>
      {/* Breadcrumb */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#0A0A0A]">Listen</span>
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
            Kuratiert
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-black text-4xl sm:text-5xl text-white leading-none mb-4" style={{ letterSpacing: '-0.03em' }}>
            Themen-Listen
          </h1>
          <p className="text-[#AAA] text-base max-w-xl">
            Keine Algorithmen. Keine Zufallstreffer. Jede Liste ist eine Entscheidung.
          </p>
        </div>
      </section>

      {/* Lists grid */}
      <section>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          {lists.length === 0 ? (
            <div className="text-center py-24">
              <p className="text-[#555] font-[family-name:var(--font-mono)] text-sm uppercase tracking-widest">Noch keine Listen veröffentlicht</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {lists.map((list) => (
                <Link
                  key={list.slug}
                  href={`/listen/${list.slug}`}
                  className="group flex flex-col border-2 border-[#0A0A0A] hover:bg-[#FFE500] transition-colors"
                >
                  <div className="p-6 flex flex-col gap-3 flex-1">
                    <div
                      className="font-[family-name:var(--font-mono)] text-[10px] font-black uppercase tracking-widest w-fit"
                      style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 8px' }}
                    >
                      {list.product_slugs.length} Produkte
                    </div>
                    <h2 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A] leading-tight group-hover:text-[#0A0A0A]">
                      {list.title}
                    </h2>
                    {list.intro && (
                      <p className="text-sm text-[#555] leading-relaxed line-clamp-2 group-hover:text-[#333]">
                        {list.intro}
                      </p>
                    )}
                  </div>
                  <div className="px-6 py-3 border-t-2 border-[#0A0A0A] flex items-center justify-between">
                    <span className="text-xs font-bold text-[#0A0A0A] font-[family-name:var(--font-mono)] uppercase tracking-widest">
                      Liste ansehen →
                    </span>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  )
}
