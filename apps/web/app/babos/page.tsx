import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Geschenke für Männer — Gaming, Tech & Gadgets | Crazy Babo Bazar',
  description: 'Handverlesene Gadgets, Gaming-Zubehör, Tech-Spielzeug und Outdoor-Equipment für echte Babos. Kurios, kaufstark, direkt auf Amazon.',
  alternates: { canonical: '/babos' },
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
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
      intro="Von LED-Zauberwürfeln bis zum KI-Schachroboter — hier findest du Gadgets, die echte Babos begeistern. Alles handverlesen, mit direktem Amazon-Link."
      icon={Crown}
      products={products}
      subnav={SUBNAV}
    />
  )
}
