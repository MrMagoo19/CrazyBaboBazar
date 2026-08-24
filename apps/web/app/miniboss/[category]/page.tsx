import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Rocket } from 'lucide-react'
import { notFound } from 'next/navigation'
import { getPersonaCategory, personaCategorySlugs, personaSubnav } from '@/lib/taxonomy'
import type { Metadata } from 'next'

export const revalidate = 3600

// Subnav, gueltige Slugs, Labels und Intros kommen aus `lib/taxonomy.ts` —
// derselben Quelle, aus der Sitemap und Produkt-Breadcrumb ihre Links bauen.
const SUBNAV = personaSubnav('miniboss')

type Props = { params: Promise<{ category: string }> }

export function generateStaticParams() {
  return personaCategorySlugs('miniboss').map((category) => ({ category }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  const cat = getPersonaCategory('miniboss', category)
  return {
    title: `Geschenke für Kinder — ${cat?.label ?? category} | Crazy Babo Bazar`,
    description: cat?.intro ?? 'Handverlesene Produkte für den Miniboss.',
    alternates: { canonical: `/miniboss/${category}` },
  }
}

export default async function MinibossCategoryPage({ params }: Props) {
  const { category } = await params
  const cat = getPersonaCategory('miniboss', category)
  if (!cat) notFound()

  const products = await getProductsByPersona('miniboss', cat.slug)
  return (
    <PersonaPage
      persona="miniboss"
      title="Miniboss"
      description={cat.label}
      intro={cat.intro}
      icon={Rocket}
      products={products}
      subnav={SUBNAV}
      activeCategory={cat.slug}
    />
  )
}
