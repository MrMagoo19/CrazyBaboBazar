import { getProductsByPersona } from '@/lib/db'
import { PersonaPage } from '@/components/persona-page'
import { Sparkles } from 'lucide-react'
import { notFound } from 'next/navigation'
import { getPersonaCategory, personaCategorySlugs, personaSubnav } from '@/lib/taxonomy'
import type { Metadata } from 'next'

export const revalidate = 3600

// Subnav, gueltige Slugs, Labels und Intros kommen aus `lib/taxonomy.ts` —
// derselben Quelle, aus der Sitemap und Produkt-Breadcrumb ihre Links bauen.
const SUBNAV = personaSubnav('queen')

type Props = { params: Promise<{ category: string }> }

export function generateStaticParams() {
  return personaCategorySlugs('queen').map((category) => ({ category }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { category } = await params
  const cat = getPersonaCategory('queen', category)
  return {
    // Ohne Markensuffix: `title.template` im Root-Layout haengt ihn an (lib/seo-title.ts).
    title: `Geschenke für Frauen — ${cat?.label ?? category}`,
    description: cat?.intro ?? 'Handverlesene Produkte für Queens.',
    alternates: { canonical: `/queens/${category}` },
  }
}

export default async function QueensCategoryPage({ params }: Props) {
  const { category } = await params
  const cat = getPersonaCategory('queen', category)
  if (!cat) notFound()

  const products = await getProductsByPersona('queen', cat.slug)
  return (
    <PersonaPage
      persona="queen"
      title="Queens"
      description={cat.label}
      intro={cat.intro}
      icon={Sparkles}
      products={products}
      subnav={SUBNAV}
      activeCategory={cat.slug}
    />
  )
}
