import { createClient } from '@/utils/supabase/server'
import { cookies } from 'next/headers'
import type { DbCategory, DbProduct } from './db-types'
export type { DbCategory, DbProduct }
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
  let query = supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .eq('shop_persona', persona)
    .order('is_featured', { ascending: false })

  if (mainCategory) {
    query = query.eq('shop_main_category', mainCategory)
  }

  const { data } = await query
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

