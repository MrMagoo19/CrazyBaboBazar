import type { DbList } from '@/lib/db-types'
import Link from 'next/link'

type Props = { lists: DbList[] }

export function ListenGrid({ lists }: Props) {
  if (!lists.length) return null

  return (
    <section className="border-t-2 border-[#0A0A0A]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
        {/* Section header */}
        <div className="flex items-end justify-between mb-8">
          <div>
            <div
              className="inline-block text-[10px] font-black uppercase tracking-widest mb-3 font-[family-name:var(--font-mono)]"
              style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
            >
              Kuratiert
            </div>
            <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] leading-tight" style={{ letterSpacing: '-0.02em' }}>
              Themen-Listen
            </h2>
          </div>
          <Link
            href="/listen"
            className="hidden sm:block text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#555] hover:text-[#0A0A0A] transition-colors"
          >
            Alle Listen →
          </Link>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {lists.slice(0, 6).map((list) => (
            <Link
              key={list.slug}
              href={`/listen/${list.slug}`}
              className="group flex flex-col border-2 border-[#0A0A0A] hover:bg-[#FFE500] transition-colors"
            >
              <div className="p-5 flex flex-col gap-2 flex-1">
                <div
                  className="font-[family-name:var(--font-mono)] text-[9px] font-black uppercase tracking-widest w-fit"
                  style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 7px' }}
                >
                  {list.product_slugs.length} Produkte
                </div>
                <h3 className="font-[family-name:var(--font-display)] font-black text-lg text-[#0A0A0A] leading-tight">
                  {list.title}
                </h3>
                {list.intro && (
                  <p className="text-xs text-[#555] leading-relaxed line-clamp-2 group-hover:text-[#333]">
                    {list.intro}
                  </p>
                )}
              </div>
              <div className="px-5 py-3 border-t-2 border-[#0A0A0A]">
                <span className="text-[10px] font-black text-[#0A0A0A] font-[family-name:var(--font-mono)] uppercase tracking-widest">
                  Liste ansehen →
                </span>
              </div>
            </Link>
          ))}
        </div>

        {/* Mobile: Alle Listen link */}
        <div className="mt-6 sm:hidden">
          <Link
            href="/listen"
            className="text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#555] hover:text-[#0A0A0A] transition-colors"
          >
            Alle Listen →
          </Link>
        </div>
      </div>
    </section>
  )
}
