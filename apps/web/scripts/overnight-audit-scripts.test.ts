import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

/**
 * Die beiden Overnight-Audit-Skripte liegen im Repo-Root und sind reines Node
 * ohne Build-Schritt. Vitest laeuft nur in `apps/web`, also werden sie hier als
 * Kindprozess getrieben — das ist zugleich die Ebene, auf der ihr Vertrag
 * tatsaechlich haengt: Exit-Code, Fehlermeldung, geschriebene Datei.
 *
 * Beide Skripte sind read-only gegenueber der Live-Seite. Die Tests hier rufen
 * nur `overnight-classify-products.mjs` auf; das ist der Teil ohne Netzzugriff.
 * `overnight-live-audit.mjs` wuerde die echte Domain crawlen und wird deshalb
 * nur syntaktisch und ueber seine Routenliste geprueft.
 */
const REPO_SCRIPTS = resolve(process.cwd(), '../../scripts')
const CLASSIFY = join(REPO_SCRIPTS, 'overnight-classify-products.mjs')
const LIVE_AUDIT = join(REPO_SCRIPTS, 'overnight-live-audit.mjs')

const ORIGIN = 'https://www.crazybabobazar.com'

type Run = { status: number | null; stdout: string; stderr: string }

/**
 * Nur die Overrides werden hier typisiert — `NodeJS.ProcessEnv` verlangt in
 * diesem Projekt ein gesetztes `NODE_ENV`, das aber aus `process.env` kommt.
 */
function run(args: string[], env: Record<string, string> = {}): Run {
  // `CBB_MONEYWIKI_ROOT` aus der Umgebung des Entwicklers wuerde die
  // Pfadaufloesung des Skripts veraendern — bewusst nicht durchreichen.
  // Overrides per `Object.assign`, damit das Literal die aus `process.env`
  // geerbten Pflichtfelder (NODE_ENV) unveraendert behaelt.
  const childEnv: NodeJS.ProcessEnv = { ...process.env, CBB_MONEYWIKI_ROOT: '' }
  Object.assign(childEnv, env)
  const result = spawnSync(process.execPath, [CLASSIFY, ...args], {
    encoding: 'utf8',
    env: childEnv,
  })
  return { status: result.status, stdout: result.stdout, stderr: result.stderr }
}

/* -------------------------------------------------------------------------- */
/* Fixtures                                                                    */
/* -------------------------------------------------------------------------- */

type ProductPage = {
  url: string
  path: string
  slug: string
  h1: string
  titleLength: number
  memberships: string[]
  personaCategoryLinks: string[]
  markers: { editorial: boolean }
  productSchema: { imageCount: number } | null
  error?: string
}

function productPage(slug: string, overrides: Partial<ProductPage> = {}): ProductPage {
  return {
    url: `${ORIGIN}/produkt/${slug}`,
    path: `/produkt/${slug}`,
    slug,
    h1: slug,
    titleLength: 42,
    memberships: ['/listen/eine-liste'],
    personaCategoryLinks: ['/babos/testkategorie'],
    markers: { editorial: true },
    productSchema: { imageCount: 3 },
    ...overrides,
  }
}

type Audit = {
  method: { origin: unknown }
  sitemap: { productCount: number; urls: unknown[] }
  productPages: ProductPage[]
}

function auditFixture(overrides: Partial<Audit> = {}): Audit {
  const products = overrides.productPages ?? [productPage('produkt-a'), productPage('produkt-b')]
  return {
    // `overnight-live-audit.mjs` schreibt die gecrawlte Origin nach method.origin;
    // historische Audit-JSONs enthalten das Feld ebenfalls.
    method: overrides.method ?? { origin: ORIGIN },
    sitemap: {
      productCount: products.length,
      urls: [
        ORIGIN,
        // Eine Persona-Kategorie, die in der frueher hartcodierten 12er-Allowlist
        // garantiert nicht stand: nur eine echte Ableitung aus der Sitemap kann
        // sie als gueltig erkennen.
        `${ORIGIN}/babos/testkategorie`,
        `${ORIGIN}/queens/beauty`,
        `${ORIGIN}/thema/tech`,
        ...products.map((p) => p.url),
      ],
      ...overrides.sitemap,
    },
    productPages: products,
  }
}

const GSC_CSV = [
  'Page,Clicks,Impressions,CTR,Position',
  `${ORIGIN}/produkt/produkt-a,0,0,0,0`,
  `${ORIGIN}/listen/eine-liste,5,100,0.05,3.2`,
].join('\n')

let dir: string
let auditPath: string
let gscPath: string
let outPath: string

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'cbb-classify-'))
  auditPath = join(dir, 'audit.json')
  gscPath = join(dir, 'pages-90d.csv')
  outPath = join(dir, 'out.csv')
  writeFileSync(gscPath, `${GSC_CSV}\n`, 'utf8')
})

afterEach(() => {
  rmSync(dir, { recursive: true, force: true })
})

function writeAudit(audit: unknown) {
  writeFileSync(auditPath, JSON.stringify(audit), 'utf8')
}

/** Die Datenzeilen der Ausgabe-CSV als Spaltenlisten (Header uebersprungen). */
function outputRows(): string[][] {
  return readFileSync(outPath, 'utf8')
    .trim()
    .split('\n')
    .slice(1)
    .map((line) => line.split(','))
}

/* -------------------------------------------------------------------------- */
/* Syntax                                                                      */
/* -------------------------------------------------------------------------- */

describe('Overnight-Skripte — Syntax', () => {
  it.each([CLASSIFY, LIVE_AUDIT])('%s parst', (script) => {
    const result = spawnSync(process.execPath, ['--check', script], { encoding: 'utf8' })
    expect(result.stderr, result.stderr).not.toMatch(/SyntaxError/)
    expect(result.status).toBe(0)
  })
})

/* -------------------------------------------------------------------------- */
/* Ableitung der Persona-Kategoriepfade aus der Sitemap                        */
/* -------------------------------------------------------------------------- */

describe('overnight-classify-products — Kategorie-Ableitung', () => {
  it('erkennt eine Persona-Kategorie als gueltig, sobald sie in der Sitemap steht', () => {
    // `/babos/testkategorie` gab es in der alten hartcodierten Allowlist nicht.
    writeAudit(auditFixture())
    const result = run([auditPath, gscPath, outPath])

    expect(result.status, result.stderr).toBe(0)
    // Spalten: slug,name,persona,category,categoryLinkStatus,…
    for (const row of outputRows()) expect(row[4]).toBe('200')
  })

  it('meldet einen Kategorie-Link als 404, wenn die Sitemap ihn nicht kennt', () => {
    writeAudit(
      auditFixture({
        productPages: [productPage('produkt-a', { personaCategoryLinks: ['/babos/gibt-es-nicht'] })],
      })
    )
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).toBe(0)
    expect(outputRows()[0][4]).toBe('404')
  })

  it('bricht bei unlesbarer Sitemap-URL ab, statt sie zu ueberspringen', () => {
    const audit = auditFixture()
    audit.sitemap.urls = [...audit.sitemap.urls, 'nicht-mal-eine-url']
    writeAudit(audit)
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/unlesbare URL\(s\) in audit\.sitemap\.urls/)
  })

  it('bricht ab, wenn die Sitemap gar keine Persona-Kategoriepfade enthaelt', () => {
    const audit = auditFixture()
    audit.sitemap.urls = [ORIGIN, `${ORIGIN}/thema/tech`, ...audit.productPages.map((p) => p.url)]
    writeAudit(audit)
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/keine \/babos\|queens\|miniboss/)
  })

  it('lehnt Sitemap-URLs fremder Origin ab, statt sie als gueltige Kategorie zu zaehlen', () => {
    // Nur den Pfad zu pruefen hiesse, `https://evil.example/babos/gekapert` wuerde
    // eine Kategorie als erreichbar ausweisen, die es auf unserer Seite nicht gibt.
    const audit = auditFixture()
    audit.sitemap.urls = [...audit.sitemap.urls, 'https://evil.example/babos/gekapert']
    writeAudit(audit)
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/Sitemap-URL\(s\) mit fremder Origin/)
    expect(result.stderr).toContain('https://evil.example/babos/gekapert')
  })

  const brokenOrigins: Array<{ label: string; origin: unknown; message: RegExp }> = [
    { label: 'fehlt', origin: undefined, message: /audit\.method\.origin fehlt oder ist kein String/ },
    { label: 'leer ist', origin: '   ', message: /audit\.method\.origin fehlt oder ist kein String/ },
    { label: 'kein String ist', origin: 42, message: /audit\.method\.origin fehlt oder ist kein String/ },
    {
      label: 'keine URL ist',
      origin: 'nicht-mal-eine-url',
      message: /audit\.method\.origin ist keine gueltige URL/,
    },
    {
      label: 'kein http(s) ist',
      origin: 'file:///tmp',
      message: /audit\.method\.origin ist keine http\(s\)-Origin/,
    },
  ]

  it.each(brokenOrigins)('bricht ab, wenn die Audit-Origin $label', ({ origin, message }) => {
    writeAudit(auditFixture({ method: { origin } }))
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(message)
  })

  it('bricht bei fehlender Sitemap-URL-Liste ab', () => {
    const audit = auditFixture()
    audit.sitemap.urls = []
    writeAudit(audit)
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/audit\.sitemap\.urls fehlt oder ist leer/)
  })
})

/* -------------------------------------------------------------------------- */
/* Vollstaendigkeit gegen sitemap.productCount                                 */
/* -------------------------------------------------------------------------- */

describe('overnight-classify-products — Vollstaendigkeit', () => {
  it('akzeptiert jede positive Anzahl, nicht mehr nur 372', () => {
    writeAudit(auditFixture())
    const result = run([auditPath, gscPath, outPath])

    // Der Vertrag haengt an Exit-Code und geschriebener Datei, nicht an stdout:
    // unter Vitest kommt die Ausgabe des Kindprozesses nicht zuverlaessig an.
    expect(result.status, result.stderr).toBe(0)
    const rows = outputRows()
    expect(rows).toHaveLength(2)
    expect(rows.map((row) => row[0]).sort()).toEqual(['produkt-a', 'produkt-b'])
  })

  it.each([0, -1, 2.5, null, 'viele'])(
    'bricht bei productCount %s ab',
    (productCount) => {
      const audit = auditFixture()
      audit.sitemap.productCount = productCount as number
      writeAudit(audit)
      const result = run([auditPath, gscPath, outPath])

      expect(result.status).not.toBe(0)
      expect(result.stderr).toMatch(/productCount ist keine positive ganze Zahl/)
    }
  )

  it('bricht ab, wenn weniger Seiten klassifiziert wurden als die Sitemap meldet', () => {
    const audit = auditFixture()
    audit.sitemap.productCount = 3
    writeAudit(audit)
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/Sitemap meldet 3 Produktseiten, klassifiziert wurden 2/)
  })

  it('verschluckt fehlerhafte Produktseiten nicht', () => {
    // Frueher wurden Fehlerzeilen herausgefiltert; mit exakt 372 fehlerfreien
    // Seiten waere ein Fehlschlag unbemerkt durchgelaufen.
    writeAudit(
      auditFixture({
        productPages: [
          productPage('produkt-a'),
          productPage('produkt-b', { error: 'The operation was aborted' }),
        ],
      })
    )
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/Produktseiten konnten im Audit nicht geladen werden/)
  })
})

/* -------------------------------------------------------------------------- */
/* Output-Pfad: kein Default, kein Ueberschreiben                              */
/* -------------------------------------------------------------------------- */

describe('overnight-classify-products — Output-Pfad', () => {
  it('verlangt den Output-Pfad explizit', () => {
    writeAudit(auditFixture())
    const result = run([auditPath, gscPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/Output-CSV nicht angegeben/)
  })

  it('schreibt auch mit CBB_MONEYWIKI_ROOT nirgendwohin ohne expliziten Pfad', () => {
    // Der frueher hier stehende Default zeigte auf einen datierten Report im
    // Vault — ein zweiter Lauf haette den ersten still ueberschrieben.
    writeAudit(auditFixture())
    const result = run([auditPath, gscPath], { CBB_MONEYWIKI_ROOT: dir })

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/Output-CSV nicht angegeben/)
    expect(result.stderr).toMatch(/keinen Default/)
  })

  it('ueberschreibt eine vorhandene Ausgabedatei nicht', () => {
    writeAudit(auditFixture())
    writeFileSync(outPath, 'bereits-vorhanden\n', 'utf8')
    const result = run([auditPath, gscPath, outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/existiert bereits und wird nicht überschrieben/)
    expect(readFileSync(outPath, 'utf8')).toBe('bereits-vorhanden\n')
  })

  it('bricht ohne aufloesbare GSC-CSV ab', () => {
    writeAudit(auditFixture())
    const result = run([auditPath, '', outPath])

    expect(result.status).not.toBe(0)
    expect(result.stderr).toMatch(/GSC-Pages-CSV nicht auflösbar/)
  })
})

/* -------------------------------------------------------------------------- */
/* Diagnostizierte Routen des Live-Audits                                      */
/* -------------------------------------------------------------------------- */

describe('overnight-live-audit — diagnostizierte Routen', () => {
  /** Die Pfade aus dem `routeUrls`-Literal, ohne das Skript auszufuehren. */
  function routeUrls(): string[] {
    const source = readFileSync(LIVE_AUDIT, 'utf8')
    const block = source.match(/const routeUrls = \[([\s\S]*?)\]\.map/)
    if (!block) throw new Error('routeUrls-Literal in overnight-live-audit.mjs nicht gefunden')
    return [...block[1].matchAll(/"([^"]+)"/g)].map((m) => m[1])
  }

  it('diagnostiziert die echte Likes-Route statt eines Nicht-Pfades', () => {
    // `/likes` ist keine Route der App — die Diagnose mass dort nur die 404-Seite.
    const paths = routeUrls()
    expect(paths).toContain('/entdecken/likes')
    expect(paths).not.toContain('/likes')
  })

  it('nimmt /jarvis-ebook auf', () => {
    expect(routeUrls()).toContain('/jarvis-ebook')
  })

  it('behaelt die uebrigen Diagnosepfade', () => {
    const paths = routeUrls()
    for (const path of ['/', '/entdecken', '/unter-10', '/design-preview', '/squad', '/wellness']) {
      expect(paths, path).toContain(path)
    }
  })

  it('schliesst HTTP-Verbindungen nach jedem Request', () => {
    // Node 20 hielt nach dem vollstaendigen Crawl sonst TCPSocketWraps offen:
    // Der Report war geschrieben, aber der Prozess beendete sich nicht. Der
    // Live-Lauf selbst bleibt aus diesem Unit-Test heraus; hier sichern wir den
    // Header ab, dessen Wirkung im Production-Audit mit natuerlichem Exit 0
    // nachgewiesen wurde.
    const source = readFileSync(LIVE_AUDIT, 'utf8')
    expect(source).toMatch(/connection:\s*["']close["']/)
  })
})
