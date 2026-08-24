import { describe, expect, it } from 'vitest'

import robots from './robots'

/**
 * Nachbildung der Robots-Exclusion-Auswertung, wie Google sie macht: die
 * laengste passende Pfad-Regel gewinnt, bei Gleichstand gewinnt `Allow`.
 * Damit testen wir die tatsaechliche Crawl-Entscheidung und nicht nur, dass
 * irgendein String im Objekt steht.
 */
function isCrawlable(path: string): boolean {
  const rule = robots().rules
  if (Array.isArray(rule)) throw new Error('Test erwartet eine einzelne Regel')
  const toArray = (v: string | string[] | undefined) => (v === undefined ? [] : Array.isArray(v) ? v : [v])

  let best: { length: number; allowed: boolean } | null = null
  for (const [patterns, allowed] of [
    [toArray(rule.allow), true],
    [toArray(rule.disallow), false],
  ] as const) {
    for (const pattern of patterns) {
      if (!path.startsWith(pattern)) continue
      if (!best || pattern.length > best.length) best = { length: pattern.length, allowed }
    }
  }
  return best ? best.allowed : true
}

describe('robots.txt', () => {
  it('sperrt /api/ weiterhin pauschal', () => {
    expect(isCrawlable('/api/download/ebook')).toBe(false)
    expect(isCrawlable('/api/irgendwas')).toBe(false)
  })

  it('gibt die oeffentlichen OG-Bilder unter /api/pin/ frei', () => {
    // Diese URL steht in openGraph.images / twitter.images jeder Produktseite.
    expect(isCrawlable('/api/pin/led-zauberwuerfel')).toBe(true)
  })

  it('laesst den Rest der Seite crawlbar', () => {
    for (const path of ['/', '/babos/gaming', '/produkt/x', '/guide', '/thema/tech']) {
      expect(isCrawlable(path), path).toBe(true)
    }
  })

  it('nennt die Sitemap', () => {
    expect(robots().sitemap).toBe('https://www.crazybabobazar.com/sitemap.xml')
  })

  it('liefert die Allow-Ausnahme in der von Next erwarteten Form', () => {
    const rule = robots().rules
    if (Array.isArray(rule)) throw new Error('Test erwartet eine einzelne Regel')
    // MetadataRoute.Robots: allow/disallow sind `string | string[]`; Next
    // serialisiert Arrays zu je einer Zeile (resolveRobots).
    expect(rule.userAgent).toBe('*')
    expect(rule.allow).toEqual(['/', '/api/pin/'])
    expect(rule.disallow).toBe('/api/')
  })
})
