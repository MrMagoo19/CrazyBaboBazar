import { redirect } from 'next/navigation'

type Props = { params: Promise<{ category: string }> }

export default async function SquadCategoryPage({ params }: Props) {
  const { category } = await params
  redirect(`/babos/${category}`)
}
