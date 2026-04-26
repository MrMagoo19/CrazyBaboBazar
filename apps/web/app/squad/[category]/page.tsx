import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Users } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/squad' },
  { label: 'Entspannung', href: '/squad/entspannung' },
  { label: 'Fitness', href: '/squad/fitness' },
]

const VALID = ['entspannung', 'fitness']

const LABELS: Record<string, string> = {
  entspannung: 'Entspannung & Recovery',
  fitness: 'Fitness & Beauty',
}

type Props = { params: Promise<{ category: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return { title: `Squad — ${LABELS[category] ?? category}` }
}

export default async function SquadCategoryPage({ params }: Props) {
  const { category } = await params
  if (!VALID.includes(category)) notFound()

  const products = await getProductsByPersona('wellness', category)
  return (
    <PersonaPage
      persona="wellness"
      title="Squad"
      description={LABELS[category]}
      icon={Users}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
