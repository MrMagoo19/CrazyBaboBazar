import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Crown } from 'lucide-react'
import { notFound } from 'next/navigation'
import { getPersonaCategory, personaCategorySlugs, personaSubnav } from '@/lib/taxonomy'
import type { Metadata } from 'next'

export const revalidate = 3600

// Subnav, gueltige Slugs, Labels und Intros kommen aus `lib/taxonomy.ts` —
// derselben Quelle, aus der Sitemap und Produkt-Breadcrumb ihre Links bauen.
const SUBNAV = personaSubnav('babo')

type Props = { params: Promise<{ category: string }> }

export function generateStaticParams() {
  return personaCategorySlugs('babo').map((category) => ({ category }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  const cat = getPersonaCategory('babo', category)
  return {
    title: `Geschenke für Männer — ${cat?.label ?? category} | Crazy Babo Bazar`,
    description: cat?.intro ?? 'Handverlesene Produkte für Babos.',
    alternates: { canonical: `/babos/${category}` },
  }
}

export default async function BabosCategoryPage({ params }: Props) {
  const { category } = await params
  const cat = getPersonaCategory('babo', category)
  if (!cat) notFound()

  const products = await getProductsByPersona('babo', cat.slug)
  return (
    <PersonaPage
      persona="babo"
      title="Babos"
      description={cat.label}
      intro={cat.intro}
      icon={Crown}
      products={products}
      subnav={SUBNAV}
      activeCategory={cat.slug}
    />
  )
}
