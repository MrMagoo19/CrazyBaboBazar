import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Rocket } from 'lucide-react'
import type { Metadata } from 'next'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Geschenke für Kinder — Spielzeug, Gaming & Spaß | Crazy Babo Bazar',
  description: 'STEM-Lernspielzeug, Minecraft-Spardosen, Partyspiele und digitale Haustiere für den Miniboss zuhause.',
  alternates: { canonical: '/miniboss' },
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
}

const SUBNAV = [
  { label: 'Alle', href: '/miniboss' },
  { label: 'Spielzeug', href: '/miniboss/spielzeug' },
  { label: 'Gaming', href: '/miniboss/gaming' },
  { label: 'Spaß', href: '/miniboss/spass' },
]

export default async function MinibossPage() {
  const products = await getProductsByPersona('miniboss')
  return (
    <PersonaPage
      persona="miniboss"
      title="Miniboss"
      description="Für den Boss im Kleinen"
      intro="Roboter programmieren, Spardosen sammeln, Partyspiele gewinnen — alles für den Miniboss."
      icon={Rocket}
      products={products}
      subnav={SUBNAV}
    />
  )
}
