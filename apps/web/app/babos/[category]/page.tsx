import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

export const revalidate = 3600

const SUBNAV = [
  { label: 'Alle', href: '/babos' },
  { label: 'Gaming', href: '/babos/gaming' },
  { label: 'Tech & DIY', href: '/babos/tech' },
  { label: 'Lifestyle', href: '/babos/lifestyle' },
  { label: 'Outdoor', href: '/babos/outdoor' },
  { label: "Babo's Irrenhaus", href: '/babos/irrenhaus' },
]

const VALID = ['gaming', 'tech', 'lifestyle', 'outdoor', 'irrenhaus']

const LABELS: Record<string, string> = {
  gaming: 'Gaming',
  tech: 'Tech & DIY',
  lifestyle: 'Lifestyle',
  outdoor: 'Outdoor & Survival',
  irrenhaus: "Babo's Irrenhaus",
}

const INTROS: Record<string, string> = {
  gaming: 'Tabletop, Retro-Konsolen, Speed Cubes und LEGO Collectibles — alles was das Gamer-Herz begehrt.',
  tech: 'ESP32, LED-Streifen, Schreibtisch-Setup und DIY-Bausätze — für Tüftler und Tech-Enthusiasten.',
  lifestyle: 'Bier brauen, Fliegenjäger, Kochbücher und Party-Gadgets — für den Babo mit Stil.',
  outdoor: 'Survival-Kits, Campingausrüstung, Feuerstahl und Zelte — für Abenteuer in der Natur.',
  irrenhaus: 'Fisch-Schlappen. Kronkorken-Pistolen. Blobfish-Hausschuhe. Produkte die niemand braucht — und alle wollen.',
}

type Props = { params: Promise<{ category: string }> }

export function generateStaticParams() {
  return VALID.map((category) => ({ category }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  return {
    title: `Geschenke für Männer — ${LABELS[category] ?? category} | Crazy Babo Bazar`,
    description: INTROS[category] ?? LABELS[category] ?? 'Handverlesene Produkte für Babos.',
    alternates: { canonical: `/babos/${category}` },
  }
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
