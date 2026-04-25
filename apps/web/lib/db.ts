import { createClient } from '@/utils/supabase/server'
import { cookies } from 'next/headers'
export type { DbCategory, DbProduct } from './db-types'
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

export async function getPublishedProducts(): Promise<DbProduct[]> {
  const supabase = await client()
  const { data } = await supabase
    .from('products')
    .select('*, categories(*)')
    .eq('is_published', true)
    .order('is_featured', { ascending: false })
  return data ?? []
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

export function formatPrice(cents: number | null): string {
  if (!cents) return '—'
  return (cents / 100).toFixed(2).replace('.', ',')
}
