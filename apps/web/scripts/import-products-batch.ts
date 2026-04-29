/**
 * Import 40 products from /tmp/products_ready.json into Supabase.
 * Usage: npx tsx scripts/import-products-batch.ts [--dry-run]
 */
import { createClient } from '@supabase/supabase-js'
import { assignShopCategory } from '../lib/assignShopCategory'
import { readFileSync } from 'fs'

const isDryRun = process.argv.includes('--dry-run')

const sb = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

type RawProduct = {
  asin: string
  name: string
  slug: string
  description: string
  tagline: string
  price_cents: number
  image_url: string
  affiliate_url: string
}

async function main() {
  const raw: RawProduct[] = JSON.parse(
    readFileSync('/tmp/products_ready.json', 'utf-8')
  )

  console.log(`\n📦 Importing ${raw.length} products${isDryRun ? ' (DRY RUN)' : ''}\n`)

  let ok = 0
  let skip = 0

  for (const p of raw) {
    const cat = assignShopCategory({
      name: p.name,
      description: p.description,
      tagline: p.tagline,
    })

    const record = {
      name: p.name,
      slug: p.slug,
      description: p.description,
      tagline: p.tagline,
      price_cents: p.price_cents,
      image_url: p.image_url || null,
      affiliate_url: p.affiliate_url,
      is_published: false,
      is_featured: false,
      shop_persona: cat.persona === 'unknown' ? null : cat.persona,
      shop_main_category: cat.main_category,
      shop_sub_category: cat.sub_category,
    }

    const catLabel = cat.persona === 'unknown'
      ? '⚠️  unbekannt'
      : `${cat.persona}/${cat.main_category}`

    if (isDryRun) {
      console.log(`[DRY] ${p.name.padEnd(50)} → ${catLabel}`)
      ok++
      continue
    }

    // Check if slug already exists
    const { data: existing } = await sb
      .from('products')
      .select('id')
      .eq('slug', p.slug)
      .single()

    if (existing) {
      console.log(`⏭  SKIP (exists): ${p.name}`)
      skip++
      continue
    }

    const { error } = await sb.from('products').insert(record)
    if (error) {
      console.error(`❌ ${p.name}: ${error.message}`)
    } else {
      console.log(`✅  ${p.name.padEnd(50)} → ${catLabel}`)
      ok++
    }
  }

  console.log(`\n${ok} inserted, ${skip} skipped / ${raw.length} total\n`)
}

main()
