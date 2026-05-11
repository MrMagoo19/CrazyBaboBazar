import { SwipeDeck } from '@/components/swipe/SwipeDeck'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Entdecken',
  description: 'Swipe dich durch kuriose Produkte. Je mehr du likest, desto besser werden die Empfehlungen.',
}

export default function EntdeckenPage() {
  return <SwipeDeck />
}
