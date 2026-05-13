import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Users } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Wellness & Fitness Produkte — Sport, Beauty & Outdoor | Crazy Babo Bazar',
  description: 'Sprossenwände, UV-Nagellampen, Insektenstichheiler und Campingzelte — Wellness für draußen und drinnen.',
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
}

const SUBNAV = [
  { label: 'Alle', href: '/wellness' },
  { label: 'Fitness & Sport', href: '/wellness/fitness' },
  { label: 'Beauty & Pflege', href: '/wellness/beauty' },
  { label: 'Outdoor', href: '/wellness/outdoor' },
]

export default async function WellnessPage() {
  const products = await getProductsByPersona('wellness')
  return (
    <PersonaPage
      persona="wellness"
      title="Wellness"
      description="Fitness, Pflege & Outdoor"
      intro="Vom Powerball-Training bis zur Korean Skincare — hier findest du alles für Körper und Geist."
      icon={Users}
      products={products}
      subnav={SUBNAV}
    />
  )
}
