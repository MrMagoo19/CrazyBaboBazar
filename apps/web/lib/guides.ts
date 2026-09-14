// Long-form editorial guides for SEO.
// Each guide is a standalone piece — 1500+ words, voice-bible-compliant,
// linking to real product slugs. Renders on /guide/[slug].

export type GuideSection = {
  heading: string
  body: string[] // paragraphs
  productSlugs?: string[] // optional inline product references
  duel?: {
    leftLabel: string
    rightLabel: string
    winner: 'left' | 'right' | 'draw'
    verdict: string
  }
}

export type Guide = {
  slug: string
  title: string
  subtitle: string
  cover: string // 3:2 Cover, z. B. /images/guides/<slug>.webp
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
import { guideStarTrekVsStarWars } from './guides/star-trek-vs-star-wars'
import { guidePokemonVsDragonBall } from './guides/pokemon-vs-dragon-ball'
import { guideDieHoehleDerLoewenProdukte } from './guides/die-hoehle-der-loewen-produkte'
import { guideUglydollsVsFuggler } from './guides/uglydolls-vs-fuggler'
import { guideLegoVsPlaymobil } from './guides/lego-vs-playmobil'
import { guideDingeDieBeimEinzugFehlen } from './guides/dinge-die-beim-einzug-fehlen'
import { guideKBeautyVsDeutscheKosmetik } from './guides/k-beauty-vs-deutsche-kosmetik'

export const guides: Guide[] = [
  guidePokemonVsDragonBall,
  guideStarTrekVsStarWars,
  guideGeschenkeMaennerAllesHaben,
  guideWichtelgeschenkeUnter20,
  guideBesteKuechenGadgets,
  guideHomeOfficeSetupAnfaenger,
  guideDieHoehleDerLoewenProdukte,
  guideUglydollsVsFuggler,
  guideLegoVsPlaymobil,
  guideDingeDieBeimEinzugFehlen,
  guideKBeautyVsDeutscheKosmetik,
]

export function getGuideBySlug(slug: string): Guide | undefined {
  return guides.find((g) => g.slug === slug)
}

// Guides that actually reference this product (real relation via section productSlugs).
// Used for the "Enthalten in Listen & Guides" back-link block on product pages.
export function getGuidesForProduct(productSlug: string): Pick<Guide, 'slug' | 'title'>[] {
  return guides
    .filter((g) => g.sections.some((s) => s.productSlugs?.includes(productSlug)))
    .map((g) => ({ slug: g.slug, title: g.title }))
}
