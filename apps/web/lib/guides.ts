// Long-form editorial guides for SEO.
// Each guide is a standalone piece — 1500+ words, voice-bible-compliant,
// linking to real product slugs. Renders on /guide/[slug].

export type GuideSection = {
  heading: string
  body: string[] // paragraphs
  productSlugs?: string[] // optional inline product references
}

export type Guide = {
  slug: string
  title: string
  subtitle: string
  metaDescription: string
  readTime: string
  category: string
  publishedAt: string // ISO date
  updatedAt?: string
  intro: string[] // multi-paragraph intro
  sections: GuideSection[]
  keywords?: string[]
}

// Guides are imported and re-exported from a barrel — one file per guide
// keeps this file readable when the list grows past ~5 entries.

import { guideGeschenkeMaennerAllesHaben } from './guides/geschenke-maenner-die-alles-haben'
import { guideWichtelgeschenkeUnter20 } from './guides/wichtelgeschenke-unter-20-euro'
import { guideBesteKuechenGadgets } from './guides/beste-kuechen-gadgets-2026'
import { guideHomeOfficeSetupAnfaenger } from './guides/home-office-setup-anfaenger'

export const guides: Guide[] = [
  guideGeschenkeMaennerAllesHaben,
  guideWichtelgeschenkeUnter20,
  guideBesteKuechenGadgets,
  guideHomeOfficeSetupAnfaenger,
]

export function getGuideBySlug(slug: string): Guide | undefined {
  return guides.find((g) => g.slug === slug)
}
