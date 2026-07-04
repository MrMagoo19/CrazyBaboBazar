import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Rocket } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

export const revalidate = 3600

const SUBNAV = [
  { label: 'Alle', href: '/miniboss' },
  { label: 'Spielzeug', href: '/miniboss/spielzeug' },
  { label: 'Gaming', href: '/miniboss/gaming' },
  { label: 'Spaß', href: '/miniboss/spass' },
]

const VALID = ['spielzeug', 'gaming', 'spass']

const LABELS: Record<string, string> = {
  spielzeug: 'Spielzeug & Lernen',
  gaming: 'Gaming & Collectibles',
  spass: 'Spaß & Party',
}

const INTROS: Record<string, string> = {
  spielzeug: 'Lernroboter, Mikroskope und magnetische Bausteine — Spielzeug das schlau macht.',
  gaming: 'Minecraft-Nachtlichter, Marvel-Spardosen und Disney-Digital-Pets — Sammeln und Spielen.',
  spass: 'Partyspiele, Wasserpistolen, Kartenspiele und Jenga-Türme — für unvergessliche Spieleabende.',
}

type Props = { params: Promise<{ category: string }> }

export function generateStaticParams() {
  return VALID.map((category) => ({ category }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return {
    title: `Geschenke für Kinder — ${LABELS[category] ?? category} | Crazy Babo Bazar`,
    description: INTROS[category] ?? LABELS[category] ?? 'Handverlesene Produkte für den Miniboss.',
    alternates: { canonical: `/miniboss/${category}` },
  }
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
      intro={INTROS[category]}
      icon={Rocket}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
