import { describe, expect, it } from 'vitest'

import { SITE_NAME, endsWithSiteName, stripSiteNameSuffix } from './seo-title'

describe('endsWithSiteName', () => {
  it('erkennt alle Trennzeichen, die im Repo als Marken-Suffix vorkamen', () => {
    expect(endsWithSiteName(`Impressum — ${SITE_NAME}`)).toBe(true)
    expect(endsWithSiteName(`Gaming Gadgets | ${SITE_NAME}`)).toBe(true)
    expect(endsWithSiteName(`Irgendwas – ${SITE_NAME}`)).toBe(true)
    expect(endsWithSiteName(`Irgendwas - ${SITE_NAME}`)).toBe(true)
  })

  it('erkennt den Markennamen auch ohne Trennzeichen davor', () => {
    expect(endsWithSiteName(`Über ${SITE_NAME}`)).toBe(true)
    expect(endsWithSiteName(SITE_NAME)).toBe(true)
  })

  it('ignoriert nachlaufenden Whitespace', () => {
    expect(endsWithSiteName(`Impressum — ${SITE_NAME}  `)).toBe(true)
  })

  it('liefert bei wiederholten Aufrufen dasselbe Ergebnis', () => {
    // Regressionsschutz gegen ein `g`-Flag: ein globales RegExp merkt sich
    // `lastIndex` und liefert dann abwechselnd true/false.
    const title = `Impressum — ${SITE_NAME}`
    expect([endsWithSiteName(title), endsWithSiteName(title), endsWithSiteName(title)]).toEqual([
      true,
      true,
      true,
    ])
  })

  it('meldet keinen Treffer, wenn die Marke nicht am Ende steht', () => {
    expect(endsWithSiteName(`${SITE_NAME} — Kuriose Produkte für schlaue Käufer`)).toBe(false)
    expect(endsWithSiteName('Über CrazyBabo Bazar — Wer steckt hinter dem Bazar?')).toBe(false)
    expect(endsWithSiteName('Kuratierte Listen')).toBe(false)
    expect(endsWithSiteName('')).toBe(false)
  })

  it('verlangt den vollstaendigen Namen', () => {
    expect(endsWithSiteName('Irgendwas — Babo Bazar')).toBe(false)
  })
})

describe('stripSiteNameSuffix', () => {
  it('entfernt den abgetrennten Markennamen genau einmal', () => {
    expect(stripSiteNameSuffix(`Impressum — ${SITE_NAME}`)).toBe('Impressum')
    expect(stripSiteNameSuffix(`Gaming Gadgets & Geschenke für Gamer | ${SITE_NAME}`)).toBe(
      'Gaming Gadgets & Geschenke für Gamer'
    )
  })

  it('laesst einen inneren Em-Dash des Titels stehen', () => {
    // Der Titel hat selbst einen Gedankenstrich; nur der Marken-Suffix faellt weg.
    expect(
      stripSiteNameSuffix(`Spielzeug & Geschenke für Kinder — STEM & Kreativität | ${SITE_NAME}`)
    ).toBe('Spielzeug & Geschenke für Kinder — STEM & Kreativität')
  })

  it('laesst Titel ohne Suffix unveraendert', () => {
    expect(stripSiteNameSuffix('Kuratierte Listen')).toBe('Kuratierte Listen')
    expect(stripSiteNameSuffix(`${SITE_NAME} — Kuriose Produkte für schlaue Käufer`)).toBe(
      `${SITE_NAME} — Kuriose Produkte für schlaue Käufer`
    )
  })

  it('schneidet den Markennamen nicht aus dem Satz heraus', () => {
    // "Über Crazy Babo Bazar" ist ein Titel, kein angehaengter Suffix. Kuerzen
    // waere Bedeutungsverlust — die Entscheidung bleibt bewusst manuell.
    const title = `Über ${SITE_NAME}`
    expect(stripSiteNameSuffix(title)).toBe(title)
    expect(endsWithSiteName(title)).toBe(true)
  })

  it('macht den Titel konventionskonform', () => {
    for (const title of [
      `Impressum — ${SITE_NAME}`,
      `Trending Gadgets & Produkte 2026 — was gerade abgeht | ${SITE_NAME}`,
      `Outdoor Gadgets & Camping Zubehör | ${SITE_NAME}`,
    ]) {
      expect(endsWithSiteName(stripSiteNameSuffix(title)), title).toBe(false)
    }
  })
})
