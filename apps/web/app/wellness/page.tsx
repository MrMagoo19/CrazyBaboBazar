import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Users } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Wellness',
  description: 'Fitness, Beauty und Outdoor für Wellness-Bewusste.',
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
      icon={Users}
      products={products}
      subnav={SUBNAV}
    />
  )
}
