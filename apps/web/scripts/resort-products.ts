/**
 * Resort all products in Supabase through the shop-category engine.
 *
 * Usage:
 *   npx tsx scripts/resort-products.ts
 *   npx tsx scripts/resort-products.ts --dry-run
 */
import { createClient } from '@supabase/supabase-js'
import { assignShopCategory } from '../lib/assignShopCategory'

const DRY_RUN = process.argv.includes('--dry-run')

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

type RawProduct = {
  id: string
  slug: string
  name: string
  tagline: string | null
  description: string | null
  amazon_category: string | null
  brand: string | null
  shop_persona: string | null
  shop_main_category: string | null
  shop_sub_category: string | null
}

async function main() {
  console.log(`\n🔄 resort-products ${DRY_RUN ? '(DRY RUN)' : ''}\n`)

  const { data: products, error } = await supabase
    .from('products')
    .select('id, slug, name, tagline, description, amazon_category, brand, shop_persona, shop_main_category, shop_sub_category')

  if (error) {
    console.error('❌ Supabase error:', error.message)
    process.exit(1)
  }

  if (!products?.length) {
    console.log('No products found.')
    return
  }

  let changed = 0
  let unchanged = 0
  let unknown = 0

  for (const product of products as RawProduct[]) {
    const result = assignShopCategory(product)

    const same =
      product.shop_persona === result.persona &&
      product.shop_main_category === result.main_category &&
      product.shop_sub_category === result.sub_category

    if (same) {
      unchanged++
      continue
    }

    if (result.persona === 'unknown') unknown++

    const label = result.persona === 'unknown'
      ? `⚠️  ${product.slug}`
      : `✅  ${product.slug}`

    console.log(
      `${label}\n    ${product.shop_persona ?? '—'} / ${product.shop_main_category ?? '—'} / ${product.shop_sub_category ?? '—'}` +
      `\n  → ${result.persona} / ${result.main_category} / ${result.sub_category}` +
      (result.matched_rule ? ` (keyword: "${result.matched_rule.keywords[0]}")` : '') +
      '\n'
    )

    if (!DRY_RUN) {
      const { error: updateError } = await supabase
        .from('products')
        .update({
          shop_persona: result.persona,
          shop_main_category: result.main_category,
          shop_sub_category: result.sub_category,
        })
        .eq('id', product.id)

      if (updateError) {
        console.error(`  ❌ Update failed for ${product.slug}:`, updateError.message)
      }
    }

    changed++
  }

  console.log(`\n─────────────────────────────────`)
  console.log(`Total:     ${products.length}`)
  console.log(`Changed:   ${changed}`)
  console.log(`Unchanged: ${unchanged}`)
  console.log(`Unknown:   ${unknown}`)
  if (DRY_RUN) console.log(`\n⚠️  Dry run — no changes written to DB`)
  console.log()
}

main()
