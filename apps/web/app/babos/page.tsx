import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Babos',
  description: 'Gaming, Outdoor, Auto und Tech-Gadgets für echte Babos.',
}

const SUBNAV = [
  { label: 'Alle', href: '/babos' },
  { label: 'Gaming', href: '/babos/gaming' },
  { label: 'Outdoor', href: '/babos/outdoor' },
  { label: 'Auto', href: '/babos/auto' },
  { label: 'Büro', href: '/babos/buero' },
  { label: 'Gadgets', href: '/babos/gadgets' },
  { label: 'Geschenke', href: '/babos/geschenke' },
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
