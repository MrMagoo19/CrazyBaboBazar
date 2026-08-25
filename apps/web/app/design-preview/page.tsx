import type { Metadata } from 'next'
import { getPublishedProducts } from '@/lib/db'
import { PreviewClient } from './preview-client'

export const dynamic = 'force-dynamic'

// Interne Design-Spielwiese ohne redaktionellen Wert. Sie war bisher ohne jede
// Robots-Angabe live crawlbar und konkurrierte damit als Duplikat um dieselben
// Produktinhalte wie die echten Listen.
//
// `follow: false`, weil hier ausschliesslich Links auf Seiten stehen, die
// ohnehin ueber Sitemap und Navigation erreichbar sind — diese Route soll
// keinerlei Crawl-Signal setzen. Bewusst KEINE Canonical: eine nicht
// indexierbare Seite soll gar nicht erst als kanonisches Ziel auftauchen.
export const metadata: Metadata = {
  title: 'Design-Preview (intern)',
  robots: { index: false, follow: false },
}

export default async function DesignPreviewPage() {
  const products = await getPublishedProducts()
  return <PreviewClient products={products} />
}
