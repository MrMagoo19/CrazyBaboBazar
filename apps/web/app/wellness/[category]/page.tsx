import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Users } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/wellness' },
  { label: 'Fitness & Sport', href: '/wellness/fitness' },
  { label: 'Beauty & Pflege', href: '/wellness/beauty' },
  { label: 'Outdoor', href: '/wellness/outdoor' },
]

const VALID = ['fitness', 'beauty', 'outdoor']

const LABELS: Record<string, string> = {
  fitness: 'Fitness & Sport',
  beauty: 'Beauty & Pflege',
  outdoor: 'Outdoor',
}

const INTROS: Record<string, string> = {
  fitness: 'Sprossenwände, Power Tower, Tennis-Trainer und Massagepistolen — Fitness zuhause.',
  beauty: 'Korean Skincare, Bartöl, UV-Nagellampen und Haarbürsten ohne Ziepen — Pflege mit Anspruch.',
  outdoor: 'Wurfzelte, Solarpanels und Dry Bags — für spontane Outdoor-Abenteuer.',
}

type Props = { params: Promise<{ category: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return { title: `Wellness — ${LABELS[category] ?? category}` }
}

export default async function WellnessCategoryPage({ params }: Props) {
  const { category } = await params
  if (!VALID.includes(category)) notFound()

  const products = await getProductsByPersona('wellness', category)
  return (
    <PersonaPage
      persona="wellness"
      title="Wellness"
      description={LABELS[category]}
      intro={INTROS[category]}
      icon={Users}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
