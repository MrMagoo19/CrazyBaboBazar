import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/babos' },
  { label: 'Gaming', href: '/babos/gaming' },
  { label: 'Outdoor', href: '/babos/outdoor' },
  { label: 'Auto', href: '/babos/auto' },
  { label: 'Büro', href: '/babos/buero' },
  { label: 'Gadgets', href: '/babos/gadgets' },
  { label: 'Geschenke', href: '/babos/geschenke' },
]

const VALID = ['gaming', 'outdoor', 'auto', 'buero', 'gadgets', 'geschenke']

const LABELS: Record<string, string> = {
  gaming: 'Gaming',
  outdoor: 'Outdoor & Survival',
  auto: 'Auto',
  buero: 'Büro',
  gadgets: 'Gadgets & Tech',
  geschenke: 'Geschenke',
}

type Props = { params: Promise<{ category: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return { title: `Babos — ${LABELS[category] ?? category}` }
}

export default async function BabosCategoryPage({ params }: Props) {
  const { category } = await params
  if (!VALID.includes(category)) notFound()

  const products = await getProductsByPersona('babo', category)
  return (
    <PersonaPage
      persona="babo"
      title="Babos"
      description={LABELS[category]}
      icon={Crown}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
