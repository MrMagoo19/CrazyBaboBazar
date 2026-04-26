import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Sparkles } from 'lucide-react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Queens',
  description: 'Küche, Deko, Lifestyle und Reise für echte Queens.',
}

const SUBNAV = [
  { label: 'Alle', href: '/queens' },
  { label: 'Küche', href: '/queens/kueche' },
  { label: 'Deko', href: '/queens/deko' },
  { label: 'Lifestyle', href: '/queens/lifestyle' },
  { label: 'Geschenke', href: '/queens/geschenke' },
]

export default async function QueensPage() {
  const products = await getProductsByPersona('queen')
  return (
    <PersonaPage
      persona="queen"
      title="Queens"
      description="Zeug das Queens lieben"
      icon={Sparkles}
      products={products}
      subnav={SUBNAV}
    />
  )
}
