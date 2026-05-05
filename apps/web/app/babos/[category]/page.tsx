import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

const SUBNAV = [
  { label: 'Alle', href: '/babos' },
  { label: 'Gaming', href: '/babos/gaming' },
  { label: 'Tech & DIY', href: '/babos/tech' },
  { label: 'Lifestyle', href: '/babos/lifestyle' },
  { label: 'Outdoor', href: '/babos/outdoor' },
]

const VALID = ['gaming', 'tech', 'lifestyle', 'outdoor']

const LABELS: Record<string, string> = {
  gaming: 'Gaming',
  tech: 'Tech & DIY',
  lifestyle: 'Lifestyle',
  outdoor: 'Outdoor & Survival',
}

const INTROS: Record<string, string> = {
  gaming: 'Tabletop, Retro-Konsolen, Speed Cubes und LEGO Collectibles — alles was das Gamer-Herz begehrt.',
  tech: 'ESP32, LED-Streifen, Schreibtisch-Setup und DIY-Bausätze — für Tüftler und Tech-Enthusiasten.',
  lifestyle: 'Bier brauen, Fliegenjäger, Kochbücher und Party-Gadgets — für den Babo mit Stil.',
  outdoor: 'Survival-Kits, Campingausrüstung, Feuerstahl und Zelte — für Abenteuer in der Natur.',
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
      intro={INTROS[category]}
      icon={Crown}
      products={products}
      subnav={SUBNAV}
      activeCategory={category}
    />
  )
}
