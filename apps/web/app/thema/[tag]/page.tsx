import { getProductsByTag } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

const TAG_CONFIG: Record<string, { label: string; desc: string; emoji: string }> = {
  gaming:    { label: 'Gaming',         desc: 'Tabletop, Retro, Collectibles & Gamer-Gadgets', emoji: '🎮' },
  tech:      { label: 'Tech & Setup',   desc: 'Gadgets, Schreibtisch & Tüftler-Zeug',          emoji: '💻' },
  kueche:    { label: 'Küche',          desc: 'Küchengeräte, Gadgets & Kulinarisches',          emoji: '🍳' },
  lifestyle: { label: 'Lifestyle',      desc: 'Party, Bar, Deko & Geschenkideen',               emoji: '✨' },
  outdoor:   { label: 'Outdoor',        desc: 'Camping, Survival & Abenteuerzubehör',           emoji: '🌿' },
  beauty:    { label: 'Beauty & Pflege',desc: 'Hautpflege, Wellness & Körperpflege',            emoji: '💆' },
  spielzeug: { label: 'Spielzeug',      desc: 'STEM, Kreativität & Kinderspaß',                 emoji: '🧸' },
  fitness:   { label: 'Fitness & Sport',desc: 'Training, Recovery & Sportequipment',            emoji: '💪' },
  haushalt:  { label: 'Haushalt',       desc: 'Smarte Helfer & clevere Alltagsprodukte',        emoji: '🏠' },
}

const SUBNAV = Object.entries(TAG_CONFIG).map(([key, { label }]) => ({
  label,
  href: `/thema/${key}`,
}))

type Props = { params: Promise<{ tag: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { tag } = await params
  const config = TAG_CONFIG[tag]
  if (!config) return { title: 'Nicht gefunden' }
  return {
    title: `${config.label} — Produkte & Gadgets | Crazy Babo Bazar`,
    description: `${config.desc}. Handverlesene Produkte mit direktem Amazon-Link.`,
    openGraph: {
      title: `${config.label} | Crazy Babo Bazar`,
      description: config.desc,
    },
  }
}

export default async function ThemaPage({ params }: Props) {
  const { tag } = await params
  const config = TAG_CONFIG[tag]
  if (!config) notFound()

  const products = await getProductsByTag(tag)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <span className="text-xl leading-none">{config.emoji}</span>
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: 'var(--font-mono)' }}>
              Thema
            </span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            {config.label}
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {config.desc} · {products.length} Produkte
          </p>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 border-t-2 border-[#0A0A0A]">
          <div className="flex gap-0 overflow-x-auto scrollbar-none">
            {SUBNAV.map(item => (
              <Link
                key={item.href}
                href={item.href}
                className={`shrink-0 px-4 py-3 text-xs font-[family-name:var(--font-mono)] font-bold uppercase tracking-wider border-b-2 transition-all duration-150 ${
                  item.href === `/thema/${tag}`
                    ? 'border-[#FFE500] bg-[#FFE500] text-[#0A0A0A]'
                    : 'border-transparent text-[#555555] hover:text-[#0A0A0A] hover:border-[#0A0A0A]'
                }`}
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Noch keine Produkte in diesem Thema.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <ProductGrid products={products} />
        </div>
      )}
    </div>
  )
}
