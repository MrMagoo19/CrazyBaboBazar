import type { MetadataRoute } from 'next'
import { guides } from '@/lib/guides'
import { isThemaTag, personaCategoryPath } from '@/lib/taxonomy'

const BASE_URL = 'https://www.crazybabobazar.com'

// Revalidierung der Sitemap-Route explizit setzen. Ohne dieses Export haengt das
// Intervall nur indirekt am `next: { revalidate: 3600 }` der verschachtelten
// Supabase-Fetches — eine Implementierungsdetail-Kopplung, die beim kleinsten
// Umbau der Fetch-Optionen stillschweigend kippt.
export const revalidate = 3600

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

type SupabaseFetchOpts = ReturnType<typeof getSupabaseConfig>['fetchOpts']

class SitemapDataError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'SitemapDataError'
  }
}

const FETCH_ATTEMPTS = 3
const BACKOFF_MS = 500

/**
 * Holt eine Supabase-REST-Query fuer die Sitemap.
 *
 * Frueher fiel jeder Aufruf bei `!res.ok` still auf `[]` zurueck. Ein rotierter
 * Key (401), ein Supabase-500 oder ein RLS-Fehler haette damit eine Sitemap aus
 * nur den statischen URLs erzeugt — mit HTTP 200. Google haette das als
 * Entfernung aller Produktseiten gelesen.
 *
 * Jetzt: bis zu drei Versuche, danach ein harter Fehler. Beim Build bricht das
 * `next build` ab (das vorherige Deployment bleibt live), bei einer ISR-
 * Revalidierung zur Laufzeit behaelt Next die letzte erfolgreiche Sitemap im
 * Cache und liefert sie weiter aus. In keinem Fall entsteht eine gekuerzte
 * Sitemap mit Status 200.
 *
 * Geloggt werden ausschliesslich Label und Fehlergrund — niemals die URL oder
 * `opts`, da diese den apikey- und Authorization-Header tragen.
 */
async function fetchJson<T>(url: string, opts: SupabaseFetchOpts, label: string): Promise<T> {
  let lastReason = 'unbekannter Fehler'

  for (let attempt = 1; attempt <= FETCH_ATTEMPTS; attempt++) {
    try {
      const res = await fetch(url, opts)
      if (res.ok) return (await res.json()) as T
      lastReason = `HTTP ${res.status} ${res.statusText}`.trim()
    } catch (err) {
      // Netzwerkfehler, DNS-Fehler, Timeout: derselbe Wiederholungspfad.
      lastReason = err instanceof Error ? `${err.name}: ${err.message}` : String(err)
    }

    console.error(`[sitemap] ${label}: Versuch ${attempt}/${FETCH_ATTEMPTS} fehlgeschlagen (${lastReason})`)

    if (attempt < FETCH_ATTEMPTS) {
      await new Promise((resolve) => setTimeout(resolve, attempt * BACKOFF_MS))
    }
  }

  throw new SitemapDataError(`${label}: nach ${FETCH_ATTEMPTS} Versuchen fehlgeschlagen (${lastReason})`)
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const { restUrl, fetchOpts } = getSupabaseConfig()
  const [products, lists, personaRows] = await Promise.all([
    fetchJson<SupabaseProduct[]>(
      `${restUrl}/products?select=slug,updated_at,created_at&is_published=eq.true`,
      fetchOpts,
      'products'
    ),
    fetchJson<{ slug: string; created_at: string }[]>(
      `${restUrl}/lists?select=slug,created_at&is_published=eq.true`,
      fetchOpts,
      'lists'
    ),
    fetchJson<PersonaRow[]>(
      `${restUrl}/products?select=shop_persona,shop_main_category&is_published=eq.true&shop_persona=not.is.null&shop_main_category=not.is.null`,
      fetchOpts,
      'persona-rows'
    ),
  ])

  // Ein erfolgreicher Request mit leerem Ergebnis ist genauso gefaehrlich wie ein
  // Fehlschlag: ohne Produkte bliebe nur die Handvoll statischer URLs uebrig.
  // Keine Ersatzdaten erzeugen — abbrechen und die letzte gute Sitemap stehen
  // lassen.
  if (products.length === 0) {
    console.error('[sitemap] products: Request erfolgreich, aber 0 Zeilen — Sitemap wird nicht erzeugt')
    throw new SitemapDataError('products: 0 veroeffentlichte Produkte')
  }

  // Dynamische Unterseiten aus der DB ableiten — aber ausschliesslich solche,
  // fuer die es auch eine Route gibt.
  //
  // Frueher wurde hier `/${base}/${cat}` fuer jede Persona/Kategorie-Kombination
  // der DB gebaut und `/thema/${cat}` fuer jede Kategorie. Die drei
  // Persona-Kategorieseiten und `app/thema/[tag]` kennen aber nur eine feste
  // Allowlist und rufen sonst `notFound()` auf — die Sitemap meldete Google also
  // programmatisch erzeugte 404s. `personaCategoryPath` und `isThemaTag` sind
  // jetzt dieselbe Quelle, aus der die Routen ihre Gueltigkeit ableiten.
  //
  // Es entstehen dadurch keine neuen URLs: gefiltert wird nur nach unten.
  const personaSubPages = new Set<string>()
  for (const row of personaRows) {
    const { shop_persona: persona, shop_main_category: cat } = row
    if (!persona || !cat) continue
    const personaPath = personaCategoryPath(persona, cat)
    if (personaPath) personaSubPages.add(personaPath)
    if (isThemaTag(cat)) personaSubPages.add(`/thema/${cat}`)
  }

  const staticPages: MetadataRoute.Sitemap = [
    { url: BASE_URL, changeFrequency: 'daily', priority: 1.0 },
    { url: `${BASE_URL}/babos`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/queens`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/miniboss`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${BASE_URL}/trending`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/listen`, changeFrequency: 'weekly', priority: 0.8 },
    // Der Guide-Hub ist verlinkt und erreichbar, fehlte aber als Sitemap-Eintrag;
    // nur die einzelnen /guide/<slug> standen drin.
    { url: `${BASE_URL}/guide`, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${BASE_URL}/unter-10`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/unter-20`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/unter-50`, changeFrequency: 'daily', priority: 0.7 },
    { url: `${BASE_URL}/unter-100`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/unter-200`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/ueber-200`, changeFrequency: 'daily', priority: 0.6 },
    { url: `${BASE_URL}/entdecken`, changeFrequency: 'weekly', priority: 0.6 },
    { url: `${BASE_URL}/jarvis-ebook`, changeFrequency: 'monthly', priority: 0.6 },
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
