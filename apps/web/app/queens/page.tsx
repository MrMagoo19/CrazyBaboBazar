import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Sparkles } from 'lucide-react'
import type { Metadata } from 'next'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Geschenke für Frauen — Lifestyle, Küche & Beauty | Crazy Babo Bazar',
  description: 'Kuriose Küchengadgets, Beauty-Finds, Lifestyle-Produkte und persönliche Geschenke für Queens. Handverlesen mit Amazon-Links.',
  alternates: { canonical: '/queens' },
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
}

const SUBNAV = [
  { label: 'Alle', href: '/queens' },
  { label: 'Küche', href: '/queens/kueche' },
  { label: 'Lifestyle', href: '/queens/lifestyle' },
  { label: 'Beauty', href: '/queens/beauty' },
  { label: 'Geschenke', href: '/queens/geschenke' },
]

export default async function QueensPage() {
  const products = await getProductsByPersona('queen')
  return (
    <PersonaPage
      persona="queen"
      title="Queens"
      description="Zeug das Queens lieben"
      intro="Vom selbstrührenden Harry-Potter-Becher bis zur Glass-Skin-Maske — hier shoppt die Queen."
      icon={Sparkles}
      products={products}
      subnav={SUBNAV}
    />
  )
}
