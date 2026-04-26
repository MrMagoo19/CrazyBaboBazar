import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Rocket } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/miniboss' },
  { label: 'Spiele', href: '/miniboss/spiele' },
  { label: 'Gadgets', href: '/miniboss/gadgets' },
  { label: 'Deko', href: '/miniboss/deko' },
  { label: 'Geschenke', href: '/miniboss/geschenke' },
]

const VALID = ['spiele', 'gadgets', 'deko', 'geschenke']

const LABELS: Record<string, string> = {
  spiele: 'Spiele & Spaß',
  gadgets: 'Gadgets',
  deko: 'Deko & Zimmer',
  geschenke: 'Geschenke',
}

type Props = { params: Promise<{ category: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return { title: `Miniboss — ${LABELS[category] ?? category}` }
}

export default async function MinibossCategoryPage({ params }: Props) {
  const { category } = await params
  if (!VALID.includes(category)) notFound()

  const products = await getProductsByPersona('miniboss', category)
  return (
    <PersonaPage
      persona="miniboss"
      title="Miniboss"
      description={LABELS[category]}
      icon={Rocket}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
