import type { MetadataRoute } from 'next'
import { guides } from '@/lib/guides'

const BASE_URL = 'https://www.crazybabobazar.com'

function getSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  if (!url || !key) throw new Error('Supabase env vars missing (NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)')
  return {
    restUrl: `${url}/rest/v1`,
    fetchOpts: {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
      next: { revalidate: 3600 },
    },
  }
}

type SupabaseProduct = { slug: string; updated_at: string | null; created_at: string }
type PersonaRow = { shop_persona: string; shop_main_category: string }

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const { restUrl, fetchOpts } = getSupabaseConfig()
  const [productsRes, listsRes, personaRes] = await Promise.all([
    fetch(`${restUrl}/products?select=slug,updated_at,created_at&is_published=eq.true`, fetchOpts),
    fetch(`${restUrl}/lists?select=slug,created_at&is_published=eq.true`, fetchOpts),
    fetch(
      `${restUrl}/products?select=shop_persona,shop_main_category&is_published=eq.true&shop_persona=not.is.null&shop_main_category=not.is.null`,
      fetchOpts
    ),
  ])

  const products: SupabaseProduct[] = productsRes.ok ? await productsRes.json() : []
  const lists: { slug: string; created_at: string }[] = listsRes.ok ? await listsRes.json() : []
  const personaRows: PersonaRow[] = personaRes.ok ? await personaRes.json() : []

  // Dynamische Persona-Unterseiten aus DB ableiten
  const personaSubPages = new Set<string>()
  for (const row of personaRows) {
    const { shop_persona: persona, shop_main_category: cat } = row
    if (!persona || !cat) continue
    const baseMap: Record<string, string> = { babo: 'babos', queen: 'queens', miniboss: 'miniboss' }
    const base = baseMap[persona]
    if (base) personaSubPages.add(`/${base}/${cat}`)
    personaSubPages.add(`/thema/${cat}`)
  }

  const staticPages: MetadataRoute.Sitemap = [
    { url: BASE_URL, changeFrequency: 'daily', priority: 1.0 },
    { url: `${BASE_URL}/babos`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/queens`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/miniboss`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/trending`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/listen`, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${BASE_URL}/unter-20`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/unter-50`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/unter-100`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/unter-200`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/ueber-200`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/entdecken`, changeFrequency: 'weekly', priority: 0.6 },
    { url: `${BASE_URL}/ueber-uns`, changeFrequency: 'monthly', priority: 0.4 },
    { url: `${BASE_URL}/impressum`, changeFrequency: 'yearly', priority: 0.2 },
    { url: `${BASE_URL}/datenschutz`, changeFrequency: 'yearly', priority: 0.2 },
  ]

  const dynamicCategoryPages: MetadataRoute.Sitemap = [...personaSubPages].map((path) => ({
    url: `${BASE_URL}${path}`,
    changeFrequency: 'daily' as const,
    priority: 0.7,
  }))

  const listEntries: MetadataRoute.Sitemap = lists.map((l) => ({
    url: `${BASE_URL}/listen/${l.slug}`,
    lastModified: new Date(l.created_at),
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }))

  const productEntries: MetadataRoute.Sitemap = products.map((p) => ({
    url: `${BASE_URL}/produkt/${p.slug}`,
    lastModified: new Date(p.updated_at ?? p.created_at),
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }))

  const guideEntries: MetadataRoute.Sitemap = guides.map((g) => ({
    url: `${BASE_URL}/guide/${g.slug}`,
    lastModified: new Date(g.updatedAt ?? g.publishedAt),
    changeFrequency: 'monthly' as const,
    priority: 0.9,
  }))

  return [...staticPages, ...dynamicCategoryPages, ...listEntries, ...guideEntries, ...productEntries]
}
