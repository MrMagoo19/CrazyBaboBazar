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
  image_urls: string[] | null
  is_published: boolean
  is_featured: boolean
  category_id: string | null
  categories: DbCategory | null
  shop_persona: string | null
  shop_main_category: string | null
  shop_sub_category: string | null
  amazon_category: string | null
  brand: string | null
  video_url: string | null
  editorial_note: string | null
  created_at: string | null
  shop_tags: string[] | null
  // Value-Add-Template-Felder: additiv und nullable auf der Production-Tabelle,
  // derzeit ausschliesslich fuer die zehn Production-Pilotprodukte befuellt.
  // Alle uebrigen Zeilen liefern null — jeder Renderer muss das abfangen.
  // Migration: supabase/production_value_add/02_migrate_value_add.sql
  // (Backfill: 04_backfill_value_add.sql, Rollback: 07_down_migration.sql).
  fuer_wen: string | null
  nicht_fuer: string | null
  key_fact: string | null
  pros: string[] | null
  cons: string[] | null
  alternative_slug: string | null
  alternative_reason: string | null
  alternative_kind: 'alternative' | 'complement' | null
}

export type DbList = {
  id: string
  slug: string
  title: string
  intro: string | null
  body: string | null
  product_slugs: string[]
  is_published: boolean
  created_at: string
}

export function formatPrice(cents: number | null): string {
  if (!cents) return '—'
  return (cents / 100).toFixed(2).replace('.', ',')
}

export function getPriceBand(cents: number | null): string {
  if (!cents) return 'Preis auf Amazon'
  const eur = cents / 100
  if (eur < 10)  return 'Unter 10€'
  if (eur < 20)  return 'Unter 20€'
  if (eur < 50)  return '20 – 50€'
  if (eur < 100) return '50 – 100€'
  if (eur < 200) return '100 – 200€'
  return 'Über 200€'
}
