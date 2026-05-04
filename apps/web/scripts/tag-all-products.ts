/**
 * Assigns shop_tags to all published products based on ALL matching category rules.
 * A product can appear in multiple categories simultaneously.
 *
 * Usage:
 *   SUPABASE_SERVICE_ROLE_KEY=xxx npx tsx scripts/tag-all-products.ts --dry-run
 *   SUPABASE_SERVICE_ROLE_KEY=xxx npx tsx scripts/tag-all-products.ts
 */
import { createClient } from '@supabase/supabase-js'
import { assignAllTags } from '../lib/assignAllTags'

const isDryRun = process.argv.includes('--dry-run')

const sb = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

async function main() {
  console.log(`\n🏷️  tag-all-products${isDryRun ? ' (DRY RUN)' : ''}\n`)

  const { data: products, error } = await sb
    .from('products')
    .select('id, slug, name, description, tagline, brand, price_cents, shop_persona, shop_main_category')
    .eq('is_published', true)

  if (error || !products) {
    console.error('Fehler beim Laden:', error?.message)
    process.exit(1)
  }

  console.log(`${products.length} Produkte geladen\n`)

  let updated = 0
  const stats: Record<string, number> = {}

  for (const p of products) {
    const tags = assignAllTags({
      name: p.name,
      description: p.description,
      tagline: p.tagline,
      brand: p.brand,
      price_cents: p.price_cents,
    })

    // Count tag distribution
    for (const tag of tags) stats[tag] = (stats[tag] ?? 0) + 1

    const tagCount = tags.length
    const primary = `${p.shop_persona}:${p.shop_main_category}`

    if (isDryRun) {
      const extra = tags.filter(t => t !== primary && !t.startsWith('preis:'))
      const preis = tags.filter(t => t.startsWith('preis:'))
      console.log(
        `  ${p.slug.substring(0, 45).padEnd(45)} ` +
        `[${tagCount} Tags] ${primary}` +
        (extra.length ? ` + ${extra.join(', ')}` : '') +
        (preis.length ? ` 💰${preis.map(t => t.replace('preis:', '')).join(',')}` : '')
      )
      updated++
      continue
    }

    const { error: updateError } = await sb
      .from('products')
      .update({ shop_tags: tags })
      .eq('id', p.id)

    if (updateError) {
      console.error(`❌ ${p.slug}: ${updateError.message}`)
    } else {
      console.log(`✅ ${p.slug.substring(0, 50)} → [${tags.join(', ')}]`)
      updated++
    }
  }

  console.log(`\n✅ ${updated}/${products.length} Produkte getaggt\n`)
  console.log('📊 Tag-Verteilung:')
  const sorted = Object.entries(stats).sort((a, b) => b[1] - a[1])
  for (const [tag, count] of sorted) {
    console.log(`   ${tag.padEnd(25)} ${count} Produkte`)
  }
}

main()
