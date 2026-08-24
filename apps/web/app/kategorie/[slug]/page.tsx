import { redirect } from 'next/navigation'
import { resolveLegacyCategoryRedirect } from '@/lib/taxonomy'

type Props = { params: Promise<{ slug: string }> }

// Die Ziele stehen in `lib/taxonomy.ts` und werden dort aus derselben Quelle
// aufgeloest, aus der die Routen ihre Gueltigkeit ableiten. Vorher war die
// Tabelle eine freie String-Map — `lustige-gadgets` zeigte auf `/thema/irrenhaus`,
// einen Tag ohne Config, also auf eine 404.
export default async function KategoriePage({ params }: Props) {
  const { slug } = await params
  redirect(resolveLegacyCategoryRedirect(slug))
}
