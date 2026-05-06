import { FilteredProducts } from '@/components/filtered-products'
import { getPublishedProducts } from '@/lib/db'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
  description: 'Entdecke über 200 handverlesene Gadgets, Spielzeug, Beauty-Produkte und Outdoor-Equipment. Täglich neue Empfehlungen mit direkten Amazon-Links.',
  openGraph: {
    title: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
    description: 'Über 200 handverlesene Produkte. Täglich neue Empfehlungen.',
    type: 'website',
    url: 'https://www.crazybabobazar.de',
  },
  twitter: { card: 'summary_large_image' },
}

export default async function HomePage() {
  const products = await getPublishedProducts()

  return (
    <div className="min-h-screen bg-white">

      {/* ── FILTER + PRODUCTS ──────────────────────────────── */}
      <FilteredProducts allProducts={products} />

    </div>
  )
}
