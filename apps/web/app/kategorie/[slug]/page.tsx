import { redirect } from 'next/navigation'

const REDIRECT_MAP: Record<string, string> = {
  'lustige-gadgets':    '/thema/irrenhaus',
  'geschenke-maenner':  '/babos',
  'buero-gadgets':      '/thema/tech',
  'kuechen-gadgets':    '/thema/kueche',
  'geschenke-unter-20': '/unter-20',
}

type Props = { params: Promise<{ slug: string }> }

export default async function KategoriePage({ params }: Props) {
  const { slug } = await params
  redirect(REDIRECT_MAP[slug] ?? '/')
}
