import { execSync } from 'child_process'

const ASINS = [
  'B07WNRN9WQ',
  'B0DNW8P9HY',
  'B09ZLCFF9F',
  'B0D4TZNPP7',
  'B09PTGN4XM',
  'B0CB3FN1FM',
  'B0BXKGP3V4',
  'B0CLP63P3G',
  'B0F3XKQC3W',
  'B0GX5G77WW',
  'B0DDLH865P',
]

function fetchPage(asin) {
  return execSync(
    `curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept-Language: de-DE,de;q=0.9" -H "Accept: text/html" "https://www.amazon.de/dp/${asin}"`,
    { maxBuffer: 10 * 1024 * 1024 }
  ).toString()
}

function extractImage(html) {
  // Main product image — look for largest SL image in JSON data
  const m = html.match(/"hiRes"\s*:\s*"(https:\/\/m\.media-amazon\.com\/images\/I\/[^"]+)"/)
  if (m) return m[1]
  // Fallback: extract image ID and build SL1500 URL
  const id = html.match(/media-amazon\.com\/images\/I\/([A-Za-z0-9+_%.-]+)\._AC_/)
  if (id) return `https://m.media-amazon.com/images/I/${id[1]}._AC_SL1500_.jpg`
  return null
}

function extractPrice(html) {
  // Try JSON price data
  const m = html.match(/"priceAmount"\s*:\s*([\d.]+)/)
  if (m) return m[1]
  // Try visible price span
  const p = html.match(/class="a-price-whole">([^<]+)</)
  if (p) return p[1].replace(/[^\d,]/g, '').replace(',', '.')
  // Try data-a-price
  const d = html.match(/data-a-price[^>]*value="([^"]+)"/)
  if (d) return d[1]
  return null
}

for (const asin of ASINS) {
  process.stdout.write(`Fetching ${asin}... `)
  try {
    const html = fetchPage(asin)
    const image = extractImage(html)
    const price = extractPrice(html)
    console.log(`\n  image: ${image ?? 'NOT FOUND'}`)
    console.log(`  price: ${price ? price + ' EUR' : 'NOT FOUND'}`)
  } catch (e) {
    console.log(`ERROR: ${e.message}`)
  }
  // small delay to avoid rate limiting
  execSync('sleep 1')
}
