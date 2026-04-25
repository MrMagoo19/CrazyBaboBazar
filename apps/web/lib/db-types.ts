export type DbCategory = {
  id: string
  slug: string
  name: string
  description: string | null
  emoji: string | null
  sort_order: number
}

export type DbProduct = {
  id: string
  slug: string
  name: string
  tagline: string | null
  description: string | null
  price_cents: number | null
  currency: string
  affiliate_url: string
  image_url: string | null
  is_published: boolean
  is_featured: boolean
  category_id: string | null
  categories: DbCategory | null
}

export function formatPrice(cents: number | null): string {
  if (!cents) return '—'
  return (cents / 100).toFixed(2).replace('.', ',')
}
