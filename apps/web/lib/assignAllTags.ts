import { categoryRules } from './categoryRules'

type ProductFields = {
  name?: string | null
  description?: string | null
  tagline?: string | null
  amazon_category?: string | null
  brand?: string | null
  price_cents?: number | null
}

function normalize(text: string): string {
  return text
    .toLowerCase()
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue').replace(/ß/g, 'ss')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

/**
 * Returns ALL matching category tags for a product.
 * Format: "persona:main_category" e.g. "babo:gaming", "queen:kueche"
 * Also adds price tags: "preis:unter20", "preis:unter50", "preis:unter100"
 */
export function assignAllTags(product: ProductFields): string[] {
  const haystack = normalize(
    [product.name, product.description, product.tagline, product.amazon_category, product.brand]
      .filter(Boolean)
      .join(' ')
  )

  const tags = new Set<string>()

  for (const rule of categoryRules) {
    for (const keyword of rule.keywords) {
      if (haystack.includes(normalize(keyword))) {
        // Skip wellness as primary — add it as a cross-tag only
        tags.add(`${rule.persona}:${rule.main_category}`)
        break
      }
    }
  }

  // Price tags
  const cents = product.price_cents ?? 0
  if (cents > 0) {
    if (cents < 2000) tags.add('preis:unter20')
    if (cents < 5000) tags.add('preis:unter50')
    if (cents < 10000) tags.add('preis:unter100')
  }

  return Array.from(tags)
}
