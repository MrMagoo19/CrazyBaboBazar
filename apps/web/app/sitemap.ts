import type { MetadataRoute } from 'next'

const BASE_URL = 'https://www.crazybabobazar.com'

type SupabaseProduct = {
  slug: string
  updated_at: string | null
  created_at: string
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  // Fetch all published products directly via Supabase REST API (server-only, no cookies needed)
  const res = await fetch(
    'https://ydiihvzcxaaoqhmgoqvu.supabase.co/rest/v1/products?select=slug,updated_at,created_at&is_published=eq.true',
    {
      headers: {
        apikey: 'sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
        Authorization: 'Bearer sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
      },
      next: { revalidate: 3600 },
    }
  )

  const products: SupabaseProduct[] = res.ok ? await res.json() : []

  const productEntries: MetadataRoute.Sitemap = products.map((product) => ({
    url: `${BASE_URL}/produkt/${product.slug}`,
    lastModified: new Date(product.updated_at ?? product.created_at),
    changeFrequency: 'weekly',
    priority: 0.8,
  }))

  const personaPages: MetadataRoute.Sitemap = [
    '/babos',
    '/queens',
    '/miniboss',
    '/wellness',
    '/trending',
  ].map((path) => ({
    url: `${BASE_URL}${path}`,
    changeFrequency: 'daily',
    priority: 0.7,
  }))

  const categoryPages: MetadataRoute.Sitemap = [
    '/babos/gaming',
    '/babos/tech',
    '/babos/lifestyle',
    '/babos/outdoor',
    '/queens/kueche',
    '/queens/lifestyle',
    '/queens/beauty',
    '/queens/geschenke',
    '/miniboss/spielzeug',
    '/miniboss/gaming',
    '/miniboss/spass',
    '/wellness/fitness',
    '/wellness/beauty',
    '/wellness/outdoor',
    '/unter-20',
    '/unter-50',
  ].map((path) => ({
    url: `${BASE_URL}${path}`,
    changeFrequency: 'daily',
    priority: 0.7,
  }))

  return [
    {
      url: BASE_URL,
      changeFrequency: 'daily',
      priority: 1.0,
    },
    ...personaPages,
    ...categoryPages,
    ...productEntries,
  ]
}
