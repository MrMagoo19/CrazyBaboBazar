import { redirect } from 'next/navigation'

type Props = { params: Promise<{ category: string }> }

export default async function WellnessCategoryPage({ params }: Props) {
  const { category } = await params
  const map: Record<string, string> = {
    fitness: '/thema/fitness',
    beauty:  '/thema/beauty',
    outdoor: '/thema/outdoor',
  }
  redirect(map[category] ?? '/babos')
}
