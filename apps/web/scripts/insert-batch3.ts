import Anthropic from '@anthropic-ai/sdk'
import { createClient } from '@supabase/supabase-js'

const ai = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY! })
const sb = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)

const products = [
  { slug:'asien-vegetarisch-kochbuch', name:'Asien Vegetarisch Kochbuch', tagline:'120 Rezepte von Mumbai bis Peking – ohne Fleisch, mit vollem Geschmack', price_cents:2695, affiliate_url:'https://www.amazon.de/dp/3831038848?linkCode=ll2&tag=geeklist-21&linkId=abda844b9a42df8333ed3af395aa0824', image_url:'https://m.media-amazon.com/images/I/71nCPJoWdDL._SL1500_.jpg', persona:'queen', cat:'kueche' },
  { slug:'gluecksgut-voodoo-puppe', name:'GLÜCKSGUT Voodoo Puppe', tagline:'Stress-Therapie mit Nadeln – das witzigste Bürogeschenk aller Zeiten', price_cents:799, affiliate_url:'https://www.amazon.de/dp/B0D8JHKJFD?linkCode=ll2&tag=geeklist-21&linkId=a52bfed1142f5493d6872c879d634667', image_url:'https://m.media-amazon.com/images/I/81dg2LfZpVL._AC_SX679_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'scheisse-quartett-kartenspiel', name:'Das Scheiße Quartett', tagline:'32 Kackhaufen-Charaktere – das Kultspiel für Parties und Familienabende', price_cents:895, affiliate_url:'https://www.amazon.de/dp/B00JAXDDGQ?linkCode=ll2&tag=geeklist-21&linkId=399e4fc942f183c3572d4c2cf76ae6b2', image_url:'https://m.media-amazon.com/images/I/61J0K1DAhWL._AC_SX679_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'gluecksgut-anti-stress-wuerfel', name:'GLÜCKSGUT Anti-Stress-Würfel Cubizin', tagline:'6 Motive, Geschenkbox & Anleitung – Bürostress knautschen leicht gemacht', price_cents:1099, affiliate_url:'https://www.amazon.de/dp/B0D4C5ZLMR?linkCode=ll2&tag=geeklist-21&linkId=569a1794e242ba217bdf2078cbc11515', image_url:'https://m.media-amazon.com/images/I/71Sd37kClqL._AC_SX679_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'nourished-led-gesichtsmaske-nir', name:'Nourished LED-Gesichtsmaske 7 Farben NIR', tagline:'912 LEDs, 35 mW/cm² – professionelle Lichttherapie für Zuhause', price_cents:29220, affiliate_url:'https://www.amazon.de/dp/B0DQDFZCLC?linkCode=ll2&tag=geeklist-21&linkId=d1628af856fdeea57de803ca5f806a00', image_url:'https://m.media-amazon.com/images/I/711+TYuxQvL._SX522_.jpg', persona:'queen', cat:'beauty' },
  { slug:'hasbro-twister-klassik', name:'Hasbro Twister Spiel', tagline:'Hände, Füße, Chaos – der Klassiker für Partynächte ab 6 Jahren', price_cents:2458, affiliate_url:'https://www.amazon.de/dp/B082WV8TCZ?linkCode=ll2&tag=geeklist-21&linkId=bb92d28c5258f815753f134eb84dbc3d', image_url:'https://m.media-amazon.com/images/I/71u7phxw3EL._AC_SX679_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'street-fighter-arcade-machine', name:'Street Fighter Legacy Arcade Machine', tagline:'14 Games, 17" LCD, WiFi-fähig – der Arcade-Automat fürs Wohnzimmer', price_cents:52549, affiliate_url:'https://www.amazon.de/dp/B0B7KGH1BL?linkCode=ll2&tag=geeklist-21&linkId=d4bd3ab892dabe62fa69f1985ae01b42', image_url:'https://m.media-amazon.com/images/I/81xvTsJGFBL._SX522_.jpg', persona:'babo', cat:'gaming' },
  { slug:'vtech-kidi-dj-mix', name:'VTech Kidi DJ Mix Mischpult', tagline:'10-in-1 DJ-Pult mit Bluetooth – für kleine DJs von 6 bis 12 Jahren', price_cents:5961, affiliate_url:'https://www.amazon.de/dp/B0928Z1NBY?linkCode=ll2&tag=geeklist-21&linkId=0879c9d92fc05370a34347722ed0320d', image_url:'https://m.media-amazon.com/images/I/71Q9HoCaP5L._AC_SX679_.jpg', persona:'miniboss', cat:'spielzeug' },
  { slug:'lumineo-ultraschall-peelinggeraet', name:'Lumineo Ultraschall-Peelinggerät', tagline:'29.000 Wellen/Sek. + Ionen + EMS + LED – Spa-Ergebnis ohne Termin', price_cents:3490, affiliate_url:'https://www.amazon.de/dp/B0BSLJ63LL?linkCode=ll2&tag=geeklist-21&linkId=82a09a17642f32b799227e02177f744f', image_url:'https://m.media-amazon.com/images/I/71HmQkJvmQL._AC_SX522_.jpg', persona:'queen', cat:'beauty' },
  { slug:'batman-fuggler-pluesch', name:'Batman Fuggler Plüsch 23cm', tagline:'Superschurke mit Knopfzähnen – der verstörendste Batman seit Tim Burton', price_cents:1714, affiliate_url:'https://www.amazon.de/dp/B0DC1V6BBS?linkCode=ll2&tag=geeklist-21&linkId=970187c6099a3bcd61c05fcc8d832859', image_url:'https://m.media-amazon.com/images/I/81R485FZfmL._AC_SX679_.jpg', persona:'babo', cat:'gaming' },
  { slug:'led-gesichtsmaske-wireless-4-modi', name:'LED Gesichtsmaske Kabellos 4 Modi', tagline:'Rot, Blau, Bernstein + NIR – Anti-Aging ohne Kabel, beim Netflix schauen', price_cents:13999, affiliate_url:'https://www.amazon.de/dp/B0GF7SXKMB?linkCode=ll2&tag=geeklist-21&linkId=73bc9bbdbffb5e871d45810aeea8b5cc', image_url:'https://m.media-amazon.com/images/I/61glQS666gL._SX522_.jpg', persona:'queen', cat:'beauty' },
  { slug:'uag-macbook-air-15-huelle', name:'UAG Plyo MacBook Air 15 Hülle', tagline:'US-Militärstandard, transparent-schwarz – Schutz ohne den Look zu ruinieren', price_cents:6999, affiliate_url:'https://www.amazon.de/dp/B0CJFCDRM7?linkCode=ll2&tag=geeklist-21&linkId=f397a7f878c74e882821f9300e035366', image_url:'https://m.media-amazon.com/images/I/71GLlxSYAiL._AC_SX679_.jpg', persona:'miniboss', cat:'gaming' },
  { slug:'hwwr-karaoke-maschine-2-mikrofone', name:'HWWR Karaoke Maschine 2 Mikrofone', tagline:'120W, 8 RGB-Modi, Bluetooth 5.3 – Wohnzimmer wird zur Bühne', price_cents:5997, affiliate_url:'https://www.amazon.de/dp/B0CGWPMTS9?linkCode=ll2&tag=geeklist-21&linkId=bf3da7b3e9638076447fe5109d25121c', image_url:'https://m.media-amazon.com/images/I/81wI2y8CYaL._AC_SX679_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'vicseed-magnet-handyhalterung-auto', name:'VICSEED Magnetische Handyhalterung Auto', tagline:'20× N55-Magnete, 20 kg Haltekraft, 360° drehbar – MagSafe-kompatibel', price_cents:2847, affiliate_url:'https://www.amazon.de/dp/B0FNK82YBB?linkCode=ll2&tag=geeklist-21&linkId=9b35b7a06f8d895ff518696faf4146d7', image_url:'https://m.media-amazon.com/images/I/81LV-Me9rmL._AC_SX679_.jpg', persona:'miniboss', cat:'gaming' },
  { slug:'delay-spray-maenner-mega-xxl', name:'MEGA XXL Delay Spray Männer', tagline:'15 ml Herbal Formula – mehr Kontrolle, mehr Ausdauer, mehr Selbstvertrauen', price_cents:1690, affiliate_url:'https://www.amazon.de/dp/B0GT4M3V7Z?linkCode=ll2&tag=geeklist-21&linkId=210554ccac5253995aac0ee2284696c7', image_url:'https://m.media-amazon.com/images/I/71rg5RY99PL._AC_SX522_.jpg', persona:'babo', cat:'lifestyle' },
  { slug:'mini-vibrator-lippenstift-10-modi', name:'Mini Vibrator Lippenstift Design', tagline:'10 Modi, 4 Silikonköpfe, diskret wie ein Lippenstift – leise und wasserdicht', price_cents:1699, affiliate_url:'https://www.amazon.de/dp/B0DXQ64Z3P?linkCode=ll2&tag=geeklist-21&linkId=0922516efade30b2db23aa513f368c90', image_url:'https://m.media-amazon.com/images/I/61yUfjI7AeL._AC_SX522_.jpg', persona:'queen', cat:'lifestyle' },
  { slug:'mini-vibrator-klitoris-stimulator', name:'Mini Vibrator Klitoris Stimulator', tagline:'10 Vibrationsmodi, federleicht, ergonomisch – für sie, diskret und intensiv', price_cents:2519, affiliate_url:'https://www.amazon.de/dp/B0CLJF1VTL?linkCode=ll2&tag=geeklist-21&linkId=fd5e84fa0bea66bef19ab5e72fc20305', image_url:'https://m.media-amazon.com/images/I/61LAqr0X3iL._AC_SX522_.jpg', persona:'queen', cat:'lifestyle' },
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
