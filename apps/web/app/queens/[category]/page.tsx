import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Sparkles } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/queens' },
  { label: 'Küche', href: '/queens/kueche' },
  { label: 'Lifestyle', href: '/queens/lifestyle' },
  { label: 'Beauty', href: '/queens/beauty' },
  { label: 'Geschenke', href: '/queens/geschenke' },
]

const VALID = ['kueche', 'lifestyle', 'beauty', 'geschenke']

const LABELS: Record<string, string> = {
  kueche: 'Küchen-Gadgets',
  lifestyle: 'Lifestyle & Deko',
  beauty: 'Beauty & Pflege',
  geschenke: 'Geschenke',
}

type Props = { params: Promise<{ category: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return { title: `Queens — ${LABELS[category] ?? category}` }
}

export default async function QueensCategoryPage({ params }: Props) {
  const { category } = await params
  if (!VALID.includes(category)) notFound()

  const products = await getProductsByPersona('queen', category)
  return (
    <PersonaPage
      persona="queen"
      title="Queens"
      description={LABELS[category]}
      icon={Sparkles}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
