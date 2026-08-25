import type { Metadata } from 'next'
import { describe, expect, it } from 'vitest'

// `/design-preview` haelt die Metadata in der Page (Server Component).
import { metadata as designPreviewMetadata } from './design-preview/page'
// `/entdecken/likes` ist eine Client Component und kann selbst keine Metadata
// exportieren — die Server-Ebene desselben Segments ist das Layout.
import { metadata as likesMetadata } from './entdecken/likes/layout'

type RobotsObject = Exclude<Metadata['robots'], string | null | undefined>

function robotsOf(metadata: Metadata, label: string): RobotsObject {
  const robots = metadata.robots
  if (!robots || typeof robots === 'string') {
    throw new Error(`${label}: erwartet wurde ein Robots-Objekt, war: ${JSON.stringify(robots)}`)
  }
  return robots
}

/**
 * Nachbildung der Direktiven, die Next aus `robots.index` / `robots.follow` in
 * `<meta name="robots">` schreibt. Damit prueft der Test die Crawl-Anweisung,
 * die tatsaechlich im HTML landet, und nicht nur die Feldwerte — ein
 * versehentliches `robots: { index: false }` ohne `follow` faellt so auf.
 */
function robotsDirectives(robots: RobotsObject): string[] {
  const out: string[] = []
  if (robots.index !== undefined) out.push(robots.index ? 'index' : 'noindex')
  if (robots.follow !== undefined) out.push(robots.follow ? 'follow' : 'nofollow')
  return out
}

describe('/design-preview', () => {
  it('ist weder indexierbar noch link-gebend', () => {
    // Interne Design-Spielwiese ohne redaktionellen Wert: sie war bisher ganz
    // ohne Robots-Angabe live crawlbar und konkurrierte als Duplikat mit den
    // echten Listen.
    const robots = robotsOf(designPreviewMetadata, '/design-preview')
    expect(robots.index).toBe(false)
    expect(robots.follow).toBe(false)
    expect(robotsDirectives(robots)).toEqual(['noindex', 'nofollow'])
  })

  it('setzt keine Canonical', () => {
    // Eine nicht indexierbare Route soll gar nicht erst kanonisches Ziel sein.
    expect(designPreviewMetadata.alternates?.canonical).toBeUndefined()
  })

  it('hat einen erkennbaren internen Titel', () => {
    expect(typeof designPreviewMetadata.title).toBe('string')
    expect(designPreviewMetadata.title).not.toBe('')
  })
})

describe('/entdecken/likes', () => {
  it('ist nicht indexierbar, laesst Crawler den Produktlinks aber folgen', () => {
    // Personalisierte Session-Liste: kein stabiler Index-Inhalt und bei
    // geteilten `?session=`-Links beliebig viele Varianten derselben URL. Die
    // verlinkten Produktseiten sollen ihr Crawl-Signal trotzdem behalten.
    const robots = robotsOf(likesMetadata, '/entdecken/likes')
    expect(robots.index).toBe(false)
    expect(robots.follow).toBe(true)
    expect(robotsDirectives(robots)).toEqual(['noindex', 'follow'])
  })

  it('setzt keine Canonical', () => {
    expect(likesMetadata.alternates?.canonical).toBeUndefined()
  })

  it('hat einen Titel', () => {
    expect(typeof likesMetadata.title).toBe('string')
    expect(likesMetadata.title).not.toBe('')
  })
})
