import Anthropic from '@anthropic-ai/sdk'
import { createClient } from '@supabase/supabase-js'

const ai = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY! })
const sb = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)

const products = [
  { slug:'relaxdays-tierpinata-set', name:'Relaxdays Tierpinata Set', tagline:'Bunte Tier-Piñata zum Befüllen – für Geburtstag, Einschulung oder einfach so', price_cents:1499, affiliate_url:'https://www.amazon.de/dp/B08CKFRSJG?linkCode=ll2&tag=geeklist-21&linkId=6282b2971c8abe2475790e5c882944e7', image_url:'https://m.media-amazon.com/images/I/81teZ2VGM8L._AC_SL1500_.jpg', persona:'miniboss', cat:'spass' },
  { slug:'personalisierter-kinder-riegel-xxl-30er', name:'Personalisierter Kinder Riegel XXL 30er-Set', tagline:'30 Riegel mit deinem Namen – das schokoladigste Geschenk überhaupt', price_cents:2800, affiliate_url:'https://www.amazon.de/dp/B0BPCZHM88?linkCode=ll2&tag=geeklist-21&linkId=0c28cc2eb92f6bd684f311c8b53ab01c', image_url:'https://m.media-amazon.com/images/I/81dpjCNYkbL._SL1500_.jpg', persona:'queen', cat:'geschenke' },
  { slug:'frittierte-regenwuermer-aus-der-dose', name:'Frittierte Regenwürmer aus der Dose', tagline:'Knusprige Gummiwürmer im Delikatessen-Look – das kurioseste Mitbringsel ever', price_cents:1100, affiliate_url:'https://www.amazon.de/dp/B0C1P8195W?linkCode=ll2&tag=geeklist-21&linkId=fd7f9c35124e8eb38291540b3e531ad0', image_url:'https://m.media-amazon.com/images/I/61CHBoKA-yL._SL1000_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'sudoku-klopapier-toilettenpapier', name:'Sudoku Klopapier', tagline:'Rätsel auf jedem Blatt – für die produktivste Auszeit des Tages', price_cents:899, affiliate_url:'https://www.amazon.de/dp/B00MPUR9N4?linkCode=ll2&tag=geeklist-21&linkId=8faa6ba6e6357416f60794e1fb6dd7ec', image_url:'https://m.media-amazon.com/images/I/711dE-3YX5L._AC_SL1500_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'layersmith-schaf-toilettenpapierhalter', name:'LAYERSMITH Schaf Toilettenpapierhalter', tagline:'Stapelbarer Schaf-Klorollenhalter aus Bio-Plastik – Emma, Dori oder Flocke', price_cents:1995, affiliate_url:'https://www.amazon.de/dp/B0CMTQFRXM?linkCode=ll2&tag=geeklist-21&linkId=52986274488e237c4f768a8bf1f9a23b', image_url:'https://m.media-amazon.com/images/I/71fHzYLER4L._AC_SL1500_.jpg', persona:'queen', cat:'kueche' },
]

async function gen(p: typeof products[0]): Promise<string> {
  const msg = await ai.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 400,
    messages: [{
      role: 'user',
      content: `Schreibe eine Produktbeschreibung auf Deutsch für Crazy Babo Bazar. Produkt: ${p.name}. Tagline: ${p.tagline}. 150-200 Wörter, informal, leicht humorvoll, direkte Ansprache (du/dein), kein Titel, kein Markdown.`
    }]
  })
  return msg.content[0].type === 'text' ? msg.content[0].text.trim() : ''
}

async function main() {
  for (const p of products) {
    try {
      console.log(`[${products.indexOf(p)+1}/${products.length}] ${p.name}`)
      const description = await gen(p)
      const { error } = await sb.from('products').insert({
        slug: p.slug, name: p.name, tagline: p.tagline, description,
        price_cents: p.price_cents, affiliate_url: p.affiliate_url,
        image_url: p.image_url, shop_persona: p.persona,
        shop_main_category: p.cat, is_published: true, is_featured: false,
      })
      console.log(error ? `  ✗ ${error.message}` : `  ✓ ${description.length}c`)
      await new Promise(r => setTimeout(r, 200))
    } catch(e: any) { console.log(`  ✗ ${e.message}`) }
  }
}

main()
