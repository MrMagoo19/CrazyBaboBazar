import { redirect } from 'next/navigation'
import { personaCategoryPath } from '@/lib/taxonomy'

type Props = { params: Promise<{ category: string }> }

export default async function SquadCategoryPage({ params }: Props) {
  const { category } = await params
  // Legacy-Redirect. Vorher wurde jeder Slug blind an `/babos/<slug>` gehaengt,
  // was fuer unbekannte Kategorien in einer 404 endete. Kennt die Taxonomie das
  // Paar nicht, landet der Besucher auf dem Persona-Hub.
  redirect(personaCategoryPath('babo', category) ?? '/babos')
}
