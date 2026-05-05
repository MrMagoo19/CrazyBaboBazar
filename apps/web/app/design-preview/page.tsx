import { getPublishedProducts } from '@/lib/db'
import { PreviewClient } from './preview-client'

export const dynamic = 'force-dynamic'

export default async function DesignPreviewPage() {
  const products = await getPublishedProducts()
  return <PreviewClient products={products} />
}
