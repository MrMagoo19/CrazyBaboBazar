/**
 * Removes brand names from product titles.
 * Usage:
 *   npx tsx scripts/clean-product-names.ts --dry-run
 *   npx tsx scripts/clean-product-names.ts
 */
import { createClient } from '@supabase/supabase-js'

const sb = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

const CLEAN_NAMES: Record<string, string> = {
  'azengear-paracord-survival-armband-set': 'Paracord Survival Armband Set',
  'yusing-gaming-haengevitrine-regal': 'Gaming Hängevitrine Regal',
  'tre-feuerstahl-xxl': 'Feuerstahl XXL',
  'mad-monkey-retro-spielekonsole': 'Retro Spielekonsole',
  'brubaker-weinflaschenhalter-totenkopf': 'Weinflaschenhalter Totenkopf',
  'mayflash-f300-arcade-joystick': 'Arcade Joystick',
  'empation-cocktailshaker-set': 'Cocktailshaker Set',
  'asdirne-pizzaschneider-edelstahl': 'Pizzaschneider Edelstahl',
  'peleg-design-pastail-walfoermiges-nudelsieb': 'Walförmiges Nudelsieb',
  'vivo-hoehenverstellbares-stehpult': 'Höhenverstellbares Stehpult',
  'diycut-taco-staender': 'Taco Ständer',
  'dicmky-hoehenverstellbarer-schreibtisch-aufsatz': 'Höhenverstellbarer Schreibtisch Aufsatz',
  'superone-zigarettenanzuender-schnellladegeraet': 'Zigarettenanzünder Schnellladegerät',
  'tecknet-ergonomische-kabellose-maus-bluetooth': 'Ergonomische Kabellose Maus',
  'porseme-ultraschall-luftbefeuchter-farbwechsel': 'Ultraschall Luftbefeuchter',
  'lifepro-infrarot-saunadecke': 'Infrarot Saunadecke',
  'kiayoo-wackelfigur-armaturenbrett-auto': 'Wackelfigur Armaturenbrett',
  'jdvootd-programmierbare-led-laufschrift-tafel': 'LED Laufschrift Tafel',
  'protoarc-xk01-bluetooth-klappbare-tastatur': 'Bluetooth Klappbare Tastatur',
  'joyroom-kabelmanagement-schreibtisch-selbstklebend': 'Kabelmanagement Schreibtisch',
  'anker-usb-c-adapter-upgraded': 'USB-C Adapter',
  'fentec-schwebendes-buecherregal': 'Schwebendes Bücherregal',
  'yuandian-dodo-duck-led-nachtlicht': 'Dodo Duck LED Nachtlicht',
  'nelux-3er-pack-planet-wolke-nachtlicht': 'Planet Wolke Nachtlicht 3er Pack',
  'joto-wasserdichte-handyhuelle-unterwasser': 'Wasserdichte Handyhülle',
  'sportneer-ultraleichter-campingstuhl': 'Ultraleichter Campingstuhl',
  'trekline-multifunktionsmesser-rostfrei': 'Multifunktionsmesser Rostfrei',
  'tosy-flying-disc-wiederaufladbar': 'Flying Disc Wiederaufladbar',
  'costway-tischkicker-kickertisch': 'Tischkicker',
  'huch-what-kartenspiel-deutsche-ausgabe': 'What! Kartenspiel',
  'suboos-aufladbare-campinglaterne': 'Aufladbare Campinglaterne',
  'derayee-schaumstoff-wasserpistole': 'Schaumstoff Wasserpistole',
  'hyako-massagepistole-triggerpunkt': 'Massagepistole',
  'ckb-retro-kaugummi-maschine-suessigkeitenspender': 'Retro Kaugummi Maschine',
  'mfi-zertifiziert-magsafe-wireless-ladestation-15w': 'MagSafe Wireless Ladestation 15W',
  'findchic-edelstahl-drehring': 'Edelstahl Drehring',
  'joyroom-brillenhalter-auto-sonnenblende': 'Brillenhalter Auto',
  'toureal-nachfuellbarer-parfuemzerstaeuber-reise': 'Nachfüllbarer Parfümzerstäuber',
  'ubergames-riesenwackelturm-jumbo-jenga': 'Riesenwackelturm Jenga',
  'kytok-controller-staender-4-etagen': 'Controller Ständer 4 Etagen',
  'talking-tables-partyspiel-geburtstag': 'Partyspiel Geburtstag',
  'caspor-akupressurmatte-ganzkoerper': 'Akupressurmatte Ganzkörper',
  'musicozy-bluetooth-schlafkopfhoerer': 'Bluetooth Schlafkopfhörer',
  'newl-reflektierende-holographic-windbreaker': 'Reflektierende Windbreaker Jacke',
  'fenree-business-rucksack-wasserdicht-usb': 'Business Rucksack Wasserdicht',
  'ticktime-tk3-wuerfel-timer-countdown': 'Würfel Timer Countdown',
}

async function main() {
  console.log(`\n🧹 clean-product-names\n`)
  let ok = 0
  for (const [slug, name] of Object.entries(CLEAN_NAMES)) {
    const { error } = await sb.from('products').update({ name }).eq('slug', slug)
    if (error) console.error(`❌ ${slug}: ${error.message}`)
    else { console.log(`✅  ${name}`); ok++ }
  }
  console.log(`\n${ok}/${Object.keys(CLEAN_NAMES).length} aktualisiert\n`)
}

main()
