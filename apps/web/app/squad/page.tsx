import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Users } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Squad',
  description: 'Wellness, Fitness und Entspannung für deinen inneren Squad.',
}

const SUBNAV = [
  { label: 'Alle', href: '/squad' },
  { label: 'Entspannung', href: '/squad/entspannung' },
  { label: 'Fitness', href: '/squad/fitness' },
]

export default async function SquadPage() {
  const products = await getProductsByPersona('wellness')
  return (
    <PersonaPage
      persona="wellness"
      title="Squad"
      description="Wellness & Selbstfürsorge"
      icon={Users}
      products={products}
      subnav={SUBNAV}
    />
  )
}
