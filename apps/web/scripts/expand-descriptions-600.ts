import Anthropic from '@anthropic-ai/sdk'
import { createClient } from '@supabase/supabase-js'

const sb = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)
const ai = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY! })

async function expandDescription(name: string, tagline: string, current: string): Promise<string> {
  const msg = await ai.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 400,
    messages: [{
      role: 'user',
      content: `Du schreibst Produktbeschreibungen für einen deutschen Affiliate-Shop (Crazy Babo Bazar).
Schreibe eine prägnante, ansprechende Produktbeschreibung auf Deutsch.

Produkt: ${name}
Tagline: ${tagline || '(keine)'}
Aktuelle Beschreibung: ${current || '(keine)'}

Anforderungen:
- 150-200 Wörter
- Informal, leicht ironisch-humorvoll (passt zum "Crazy Babo" Stil)
- Hebt die wichtigsten Features hervor
- Endet mit einem subtilen Kaufanreiz
- Kein generischer KI-Text, kein "Entdecke jetzt"
- Direkte Ansprache ("du/dein")
- Nur die Beschreibung, kein Titel, keine Überschrift`,
    }],
  })
  return msg.content[0].type === 'text' ? msg.content[0].text.trim() : ''
}

async function main() {
  const { data: products, error } = await sb
    .from('products')
    .select('id, slug, name, tagline, description')
    .eq('is_published', true)

  if (error) { console.error(error); process.exit(1) }

  const short = (products ?? []).filter(p => (p.description ?? '').length < 600)
  console.log(`Found ${short.length} products with descriptions < 600 chars. Starting...\n`)

  let updated = 0, failed = 0

  for (const p of short) {
    try {
      process.stdout.write(`[${updated + failed + 1}/${short.length}] ${p.name.slice(0, 50)}... `)
      const newDesc = await expandDescription(p.name, p.tagline ?? '', p.description ?? '')
      const { error: err } = await sb.from('products').update({ description: newDesc }).eq('id', p.id)
      if (err) { console.log('✗ ' + err.message); failed++ }
      else { console.log('✓ ' + newDesc.length + 'c'); updated++ }
      await new Promise(r => setTimeout(r, 150))
    } catch (e: any) {
      console.log('✗ ' + e.message)
      failed++
    }
  }

  console.log(`\nDone. Updated: ${updated}, Failed: ${failed}`)
}

main()
