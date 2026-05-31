import { createClient } from '@/utils/supabase/server'
import { cookies } from 'next/headers'
import type { DbCategory, DbProduct, DbList } from './db-types'
export type { DbCategory, DbProduct, DbList }
export { formatPrice } from './db-types'

async function client() {
  const cookieStore = await cookies()
  return createClient(cookieStore)
}

export async function getCategories(): Promise<DbCategory[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('categories')
    .select('*')
    .order('sort_order')
  return data ?? []
}

export async function getCategoryBySlug(slug: string): Promise<DbCategory | null> {
  const supabase = await client()
  const { data } = await supabase
    .from('categories')
    .select('*')
    .eq('slug', slug)
    .single()
  return data
}

function seededShuffle<T>(arr: T[], seed: number): T[] {
  const a = [...arr]
  let s = seed
  for (let i = a.length - 1; i > 0; i--) {
    s = (s * 1664525 + 1013904223) & 0xffffffff
    const j = Math.abs(s) % (i + 1);
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

export async function getPublishedProducts(): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
  if (!data) return []
  // Seed changes every hour → new order per hour, stable within one request cycle
  const seed = Math.floor(Date.now() / 3_600_000)
  const featured = seededShuffle(data.filter(p => p.is_featured), seed)
  const rest = seededShuffle(data.filter(p => !p.is_featured), seed + 1)
  return [...featured, ...rest]
}

export async function getProductsByCategory(categorySlug: string): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories!inner(*)')
    .eq('is_published', true)
    .eq('categories.slug', categorySlug)
  return data ?? []
}

export async function getProductBySlug(slug: string): Promise<DbProduct | null> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('slug', slug)
    .maybeSingle()
  return data
}

export async function getProductsByPersona(
  persona: string,
  mainCategory?: string
): Promise<DbProduct[]> {
  const supabase = await client()

  if (mainCategory) {
    // Category page: primary match OR tagged → multi-category
    const tag = `${persona}:${mainCategory}`
    const { data } = await supabase
      .from('products')
      .select('*, categories(*)')
      .eq('is_published', true)
      .or(`and(shop_persona.eq.${persona},shop_main_category.eq.${mainCategory}),shop_tags.cs.{"${tag}"}`)
      .order('is_featured', { ascending: false })
    return data ?? []
  }

  // "Alle" page: primary persona only (no tag-based cross-persona bleed)
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .eq('shop_persona', persona)
    .order('is_featured', { ascending: false })
  return data ?? []
}

export async function getTrendingProducts(): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .order('is_featured', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(40)
  return data ?? []
}

export async function getRelatedProducts(
  currentSlug: string,
  persona: string | null,
  mainCategory: string | null
): Promise<DbProduct[]> {
  if (!persona) return []
  const supabase = await client()
  let query = supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .eq('shop_persona', persona)
    .neq('slug', currentSlug)
    .limit(4)
  if (mainCategory) query = query.eq('shop_main_category', mainCategory)
  const { data } = await query
  // If less than 4 results with same category, fill up from same persona only
  if ((data?.length ?? 0) < 4 && mainCategory) {
    const { data: fallback } = await supabase
      .from('products')
      .select('*, categories(*)')
      .eq('is_published', true)
      .eq('shop_persona', persona)
      .neq('slug', currentSlug)
      .limit(4)
    const existing = new Set((data ?? []).map(p => p.slug))
    const extra = (fallback ?? []).filter(p => !existing.has(p.slug))
    return [...(data ?? []), ...extra].slice(0, 4)
  }
  return data ?? []
}

export async function getAllLists(): Promise<DbList[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('lists')
    .select('*')
    .eq('is_published', true)
    .order('created_at', { ascending: false })
  return data ?? []
}

export async function getListBySlug(slug: string): Promise<DbList | null> {
  const supabase = await client()
  const { data } = await supabase
    .from('lists')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .maybeSingle()
  return data
}

export async function getProductsBySlugs(slugs: string[]): Promise<DbProduct[]> {
  if (!slugs.length) return []
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .in('slug', slugs)
  if (!data) return []
  // Preserve original slug order
  return slugs.map(s => data.find(p => p.slug === s)).filter(Boolean) as DbProduct[]
}

export async function getProductsByMaxPrice(maxCents: number): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .lt('price_cents', maxCents)
  if (!data) return []
  const seed = Math.floor(Date.now() / 3_600_000)
  const featured = seededShuffle(data.filter(p => p.is_featured), seed)
  const rest = seededShuffle(data.filter(p => !p.is_featured), seed + 1)
  return [...featured, ...rest]
}

export async function getProductsAbovePrice(minCents: number): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .gte('price_cents', minCents)
  if (!data) return []
  const seed = Math.floor(Date.now() / 3_600_000)
  const featured = seededShuffle(data.filter(p => p.is_featured), seed)
  const rest = seededShuffle(data.filter(p => !p.is_featured), seed + 1)
  return [...featured, ...rest]
}

export async function getProductsByTag(tag: string): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .eq('shop_main_category', tag)
    .order('is_featured', { ascending: false })
  if (!data) return []
  const seed = Math.floor(Date.now() / 3_600_000)
  const featured = seededShuffle(data.filter(p => p.is_featured), seed)
  const rest = seededShuffle(data.filter(p => !p.is_featured), seed + 1)
  return [...featured, ...rest]
}

