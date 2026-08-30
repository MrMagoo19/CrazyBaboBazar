import { describe, expect, it } from 'vitest'

import {
  MAX_SOURCE_PATH_LENGTH,
  buildClickOutHref,
  classifyDevice,
  isConsentedSessionId,
  isSafeAffiliateUrl,
  isValidProductSlug,
  merchantCtaLabel,
  merchantShortLabel,
  resolveMerchant,
  sanitizeSourcePath,
} from './affiliate'

describe('resolveMerchant / isSafeAffiliateUrl', () => {
  it('erkennt die echten Amazon-Ziele aus dem Bestand', () => {
    expect(resolveMerchant('https://amzn.to/4mQqqTX')).toBe('amazon')
    expect(resolveMerchant('https://www.amazon.de/dp/B07PJ5Q943?tag=geeklist-21')).toBe('amazon')
    expect(resolveMerchant('https://amazon.de/dp/B07PJ5Q943')).toBe('amazon')
  })

  it('lehnt alles ab, was nicht https ist', () => {
    expect(resolveMerchant('http://amzn.to/4mQqqTX')).toBeNull()
    expect(resolveMerchant('javascript:alert(1)')).toBeNull()
    expect(resolveMerchant('data:text/html,<script>')).toBeNull()
    expect(resolveMerchant('//amzn.to/4mQqqTX')).toBeNull()
  })

  it('faellt nicht auf einen Host herein, der nur auf amazon.de endet', () => {
    // Ein naiver endsWith-Test wuerde hier PASS melden. Genau deshalb ist die
    // Hostliste exakt und kein Suffix-Match.
    expect(resolveMerchant('https://amazon.de.evil.example/dp/B0')).toBeNull()
    expect(resolveMerchant('https://notamazon.de/dp/B0')).toBeNull()
    expect(resolveMerchant('https://evil.example/?u=https://amzn.to/x')).toBeNull()
  })

  it('lehnt eingebettete Zugangsdaten ab', () => {
    expect(resolveMerchant('https://user:pass@amzn.to/4mQqqTX')).toBeNull()
  })

  it('behandelt Unbrauchbares ohne zu werfen', () => {
    expect(resolveMerchant(null)).toBeNull()
    expect(resolveMerchant(undefined)).toBeNull()
    expect(resolveMerchant('')).toBeNull()
    expect(resolveMerchant('nicht-mal-eine-url')).toBeNull()
    expect(resolveMerchant(42)).toBeNull()
    expect(isSafeAffiliateUrl('https://amzn.to/x')).toBe(true)
    expect(isSafeAffiliateUrl('ftp://amzn.to/x')).toBe(false)
  })
})

describe('merchantCtaLabel / merchantShortLabel', () => {
  it('nennt den Merchant beim Namen', () => {
    expect(merchantCtaLabel('amazon')).toBe('Bei Amazon ansehen')
    expect(merchantShortLabel('amazon')).toBe('Amazon')
  })

  it('bleibt ohne bekannten Merchant neutral statt Amazon zu behaupten', () => {
    expect(merchantCtaLabel(null)).toBe('Zum Angebot')
    expect(merchantShortLabel(null)).toBe('Angebot')
  })
})

describe('isValidProductSlug', () => {
  it('akzeptiert echte Slugs aus dem Bestand', () => {
    expect(isValidProductSlug('ticktime-tk3-wuerfel-timer-countdown')).toBe(true)
    expect(isValidProductSlug('lego-creator-3in1-retro-kamera-31147')).toBe(true)
  })

  it('lehnt alles ab, was einen Pfad oder Header aufbrechen koennte', () => {
    for (const bad of [
      '',
      '../etc/passwd',
      'a/b',
      'Gross-Geschrieben',
      'trailing-',
      '-leading',
      'doppel--strich',
      'mit leerzeichen',
      'a'.repeat(121),
      null,
      undefined,
      7,
    ]) {
      expect(isValidProductSlug(bad), String(bad)).toBe(false)
    }
  })
})

describe('isConsentedSessionId', () => {
  it('akzeptiert nur die UUID-v4-Form', () => {
    expect(isConsentedSessionId('3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c')).toBe(true)
  })

  it('lehnt frei gewaehlte Kennungen ab', () => {
    for (const bad of [
      'user-42',
      '3f1b9c2e7a4d4f8b9c1a2d3e4f5a6b7c',
      '3F1B9C2E-7A4D-4F8B-9C1A-2D3E4F5A6B7C',
      '3f1b9c2e-7a4d-1f8b-9c1a-2d3e4f5a6b7c',
      '',
      null,
    ]) {
      expect(isConsentedSessionId(bad), String(bad)).toBe(false)
    }
  })
})

describe('sanitizeSourcePath', () => {
  it('behaelt nur den internen Pfad', () => {
    expect(sanitizeSourcePath('/thema/tech')).toBe('/thema/tech')
    expect(sanitizeSourcePath('/produkt/ticktime-tk3-wuerfel-timer-countdown')).toBe(
      '/produkt/ticktime-tk3-wuerfel-timer-countdown'
    )
  })

  it('wirft Query und Fragment weg — dort steckt der Suchbegriff', () => {
    expect(sanitizeSourcePath('/suche?q=geschenk+fuer+opa')).toBe('/suche')
    expect(sanitizeSourcePath('/listen/geeklist#pos3')).toBe('/listen/geeklist')
    expect(sanitizeSourcePath('/thema/tech?utm_source=pinterest&utm_id=42')).toBe('/thema/tech')
  })

  it('lehnt externe und protokollrelative Herkunft ab', () => {
    expect(sanitizeSourcePath('https://evil.example/x')).toBeNull()
    expect(sanitizeSourcePath('//evil.example/x')).toBeNull()
    expect(sanitizeSourcePath('thema/tech')).toBeNull()
  })

  it('loest Pfadwechsel auf, statt sie durchzureichen', () => {
    // Der WHATWG-URL-Parser normalisiert `..` und `%2e%2e` bereits beim Parsen
    // und klemmt sie an der Wurzel ab. Es bleibt also immer ein Pfad INNERHALB
    // der Seite uebrig — kein Verzeichniswechsel und kein fremder Host.
    // Der zusaetzliche `..`-Guard in sanitizeSourcePath ist die zweite
    // Verteidigungslinie fuer alles, was der Parser stehen laesst.
    expect(sanitizeSourcePath('/../../etc/passwd')).toBe('/etc/passwd')
    expect(sanitizeSourcePath('/thema/%2e%2e/geheim')).toBe('/geheim')
    expect(sanitizeSourcePath('/thema/a..b')).toBeNull()
  })

  it('lehnt Steuerzeichen und Ueberlaenge ab', () => {
    expect(sanitizeSourcePath('/thema/tech\nX-Injected: 1')).toBeNull()
    expect(sanitizeSourcePath('/thema/tech\r\nLocation: https://evil.example')).toBeNull()
    expect(sanitizeSourcePath(`/${'a'.repeat(MAX_SOURCE_PATH_LENGTH + 1)}`)).toBeNull()
  })

  it('gibt bei unbrauchbarer Eingabe null statt eines geratenen Werts', () => {
    expect(sanitizeSourcePath(null)).toBeNull()
    expect(sanitizeSourcePath(undefined)).toBeNull()
    expect(sanitizeSourcePath('   ')).toBeNull()
    expect(sanitizeSourcePath('/%E0%A4%A')).toBeNull()
  })
})

describe('buildClickOutHref', () => {
  it('zeigt immer auf die interne Route und nie auf das Ziel', () => {
    expect(buildClickOutHref('tre-feuerstahl-xxl')).toBe('/api/click/tre-feuerstahl-xxl')
  })

  it('haengt nur einen sauberen Herkunftspfad an', () => {
    expect(buildClickOutHref('tre-feuerstahl-xxl', '/thema/outdoor')).toBe(
      '/api/click/tre-feuerstahl-xxl?from=%2Fthema%2Foutdoor'
    )
    expect(buildClickOutHref('tre-feuerstahl-xxl', 'https://evil.example')).toBe(
      '/api/click/tre-feuerstahl-xxl'
    )
  })

  it('haengt die Consent-Kennung nur an, wenn sie die UUID-Form hat', () => {
    const valid = '3f1b9c2e-7a4d-4f8b-9c1a-2d3e4f5a6b7c'
    expect(buildClickOutHref('tre-feuerstahl-xxl', null, valid)).toBe(
      `/api/click/tre-feuerstahl-xxl?cs=${valid}`
    )
    expect(buildClickOutHref('tre-feuerstahl-xxl', null, 'user-42')).toBe(
      '/api/click/tre-feuerstahl-xxl'
    )
    expect(buildClickOutHref('tre-feuerstahl-xxl', null, null)).toBe(
      '/api/click/tre-feuerstahl-xxl'
    )
  })
})

describe('classifyDevice', () => {
  it('liefert genau vier grobe Klassen', () => {
    expect(
      classifyDevice(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148'
      )
    ).toBe('mobile')
    expect(classifyDevice('Mozilla/5.0 (Linux; Android 14; Pixel 8) Mobile Safari/537.36')).toBe(
      'mobile'
    )
    expect(classifyDevice('Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) Safari/605.1.15')).toBe(
      'tablet'
    )
    expect(classifyDevice('Mozilla/5.0 (Linux; Android 14; SM-X200) Safari/537.36')).toBe('tablet')
    expect(
      classifyDevice('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36')
    ).toBe('desktop')
  })

  it('meldet unknown statt zu raten', () => {
    expect(classifyDevice(null)).toBe('unknown')
    expect(classifyDevice(undefined)).toBe('unknown')
    expect(classifyDevice('')).toBe('unknown')
    expect(classifyDevice('   ')).toBe('unknown')
    expect(classifyDevice('curl/8.5.0')).toBe('unknown')
  })
})
