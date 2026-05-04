import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Babos',
  description: 'Gaming, Tech, Lifestyle und Outdoor für echte Babos.',
}

const SUBNAV = [
  { label: 'Alle', href: '/babos' },
  { label: 'Gaming', href: '/babos/gaming' },
  { label: 'Tech & DIY', href: '/babos/tech' },
  { label: 'Lifestyle', href: '/babos/lifestyle' },
  { label: 'Outdoor', href: '/babos/outdoor' },
]

export default async function BabosPage() {
  const products = await getProductsByPersona('babo')
  return (
    <PersonaPage
      persona="babo"
      title="Babos"
      description="Zeug das Babos wollen"
      icon={Crown}
      products={products}
      subnav={SUBNAV}
    />
  )
}
