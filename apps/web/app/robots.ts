import type { MetadataRoute } from 'next'

// Oeffentliche API-Routen, die Crawler sehen duerfen. `/api/pin/<slug>` liefert
// das Pinterest-/OG-Bild, das `app/produkt/[slug]` in `openGraph.images` und
// `twitter.images` referenziert — ein pauschales `Disallow: /api/` blockiert
// genau dieses Bild fuer Crawler und Social-Previews.
//
// Bewusst NICHT enthalten:
// - `/api/download/ebook` (Lead-Magnet, kein Crawl-Ziel)
// - `/api/listen-og/` — diese Route existiert im Repo nicht (siehe Kommentar in
//   `app/listen/[slug]/page.tsx`: sie wurde nie gebaut und durch das globale
//   `app/opengraph-image` ersetzt). Eine Allow-Regel dafuer waere eine Regel auf
//   eine 404.
const PUBLIC_API_PATHS = ['/api/pin/']

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      // Next serialisiert erst alle `Allow:`-, dann alle `Disallow:`-Zeilen
      // (resolveRobots in next/dist/build/webpack/loaders/metadata/resolve-route-data).
      // Google wertet ohnehin die laengste passende Regel aus, `/api/pin/` (9 Zeichen)
      // schlaegt also `/api/` (5 Zeichen).
      allow: ['/', ...PUBLIC_API_PATHS],
      disallow: '/api/',
    },
    sitemap: 'https://www.crazybabobazar.com/sitemap.xml',
  }
}
