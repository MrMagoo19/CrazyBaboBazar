import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Rocket } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Miniboss',
  description: 'Spiele, Spaß und Gadgets für den Miniboss.',
}

const SUBNAV = [
  { label: 'Alle', href: '/miniboss' },
  { label: 'Spiele', href: '/miniboss/spiele' },
  { label: 'Gadgets', href: '/miniboss/gadgets' },
  { label: 'Deko', href: '/miniboss/deko' },
  { label: 'Geschenke', href: '/miniboss/geschenke' },
]

export default async function MinibossPage() {
  const products = await getProductsByPersona('miniboss')
  return (
    <PersonaPage
      persona="miniboss"
      title="Miniboss"
      description="Für den Boss im Kleinen"
      icon={Rocket}
      products={products}
      subnav={SUBNAV}
    />
  )
}
