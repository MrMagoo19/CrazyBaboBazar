import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Sparkles } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/queens' },
  { label: 'Küche', href: '/queens/kueche' },
  { label: 'Deko', href: '/queens/deko' },
  { label: 'Lifestyle', href: '/queens/lifestyle' },
  { label: 'Geschenke', href: '/queens/geschenke' },
]

const VALID = ['kueche', 'deko', 'lifestyle', 'geschenke']

const LABELS: Record<string, string> = {
  kueche: 'Küchen-Gadgets',
  deko: 'Deko & Wohnen',
  lifestyle: 'Lifestyle & Mode',
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
