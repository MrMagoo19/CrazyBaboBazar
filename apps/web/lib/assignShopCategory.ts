import { categoryRules, type CategoryRule, type ShopPersona } from './categoryRules'

export type ShopCategoryResult = {
  persona: ShopPersona | 'unknown'
  main_category: string
  sub_category: string
  matched_rule?: CategoryRule
}

type ProductFields = {
  name?: string | null
  description?: string | null
  tagline?: string | null
  amazon_category?: string | null
  brand?: string | null
}

function normalize(text: string): string {
  return text
    .toLowerCase()
    .replace(/ä/g, 'ae')
    .replace(/ö/g, 'oe')
    .replace(/ü/g, 'ue')
    .replace(/ß/g, 'ss')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

export function assignShopCategory(product: ProductFields): ShopCategoryResult {
  const haystack = normalize(
    [product.name, product.description, product.tagline, product.amazon_category, product.brand]
      .filter(Boolean)
      .join(' ')
  )

  for (const rule of categoryRules) {
    for (const keyword of rule.keywords) {
      if (haystack.includes(normalize(keyword))) {
        return {
          persona: rule.persona,
          main_category: rule.main_category,
          sub_category: rule.sub_category,
          matched_rule: rule,
        }
      }
    }
  }

  return {
    persona: 'unknown',
    main_category: 'sonstiges',
    sub_category: 'ungeordnet',
  }
}
