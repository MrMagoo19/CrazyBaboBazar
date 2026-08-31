import { readdirSync } from 'node:fs'
import { resolve, sep } from 'node:path'

import type { Metadata } from 'next'
import { describe, expect, it, vi } from 'vitest'

import type { DbList, DbProduct } from '@/lib/db-types'
import type { KnownPersona } from '@/lib/persona'
import { getListBySlug, getProductBySlug } from '@/lib/db'
import { guides } from '@/lib/guides'
import { SITE_NAME, endsWithSiteName, stripSiteNameSuffix } from '@/lib/seo-title'
import { THEMA_TAGS, getPersonaCategory, personaCategorySlugs } from '@/lib/taxonomy'

import { metadata as babosMetadata } from './babos/page'
import { metadata as datenschutzMetadata } from './datenschutz/page'
import { metadata as designPreviewMetadata } from './design-preview/page'
import { metadata as entdeckenMetadata } from './entdecken/page'
import { metadata as likesMetadata } from './entdecken/likes/layout'
import { metadata as guideIndexMetadata } from './guide/page'
import { metadata as geschenkeMetadata } from './geschenke/page'
import { metadata as impressumMetadata } from './impressum/page'
import { metadata as jarvisMetadata } from './jarvis-ebook/page'
import { metadata as listenIndexMetadata } from './listen/page'
import { metadata as minibossMetadata } from './miniboss/page'
import { metadata as queensMetadata } from './queens/page'
import { metadata as trendingMetadata } from './trending/page'
import { metadata as ueber200Metadata } from './ueber-200/page'
import { metadata as ueberUnsMetadata } from './ueber-uns/page'
import { metadata as unter10Metadata } from './unter-10/page'
import { metadata as unter20Metadata } from './unter-20/page'
import { metadata as unter50Metadata } from './unter-50/page'
import { metadata as unter100Metadata } from './unter-100/page'
import { metadata as unter200Metadata } from './unter-200/page'

import { generateMetadata as babosCategoryMetadata } from './babos/[category]/page'
import { generateMetadata as guideMetadata } from './guide/[slug]/page'
import { generateMetadata as listeMetadata } from './listen/[slug]/page'
import { generateMetadata as minibossCategoryMetadata } from './miniboss/[category]/page'
import { generateMetadata as produktMetadata } from './produkt/[slug]/page'
import { generateMetadata as queensCategoryMetadata } from './queens/[category]/page'
import { generateMetadata as themaMetadata } from './thema/[tag]/page'

// Nur die beiden datengetriebenen Loader werden ersetzt; alle uebrigen Exporte
// von `@/lib/db` bleiben echt, damit die importierten Page-Module vollstaendig
// aufloesen.
vi.mock('@/lib/db', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@/lib/db')>()),
  getProductBySlug: vi.fn(),
  getListBySlug: vi.fn(),
}))

/* -------------------------------------------------------------------------- */
/* Helfer                                                                      */
/* -------------------------------------------------------------------------- */

/**
 * Der document title, so wie ihn Next in `<title>` schreibt — vor dem Anhaengen
 * von `title.template`. Ein Nicht-String (TemplateString, null) waere in diesem
 * Projekt ein Fehler und soll den Test hart scheitern lassen, statt still
 * durchzurutschen.
 */
function documentTitle(metadata: Metadata, label: string): string {
  const title = metadata.title
  if (typeof title !== 'string') {
    throw new Error(`${label}: erwartet wurde ein String-title, war: ${JSON.stringify(title)}`)
  }
  return title
}

/** Der eigenstaendige Social-Titel — auf ihn wirkt `title.template` nicht. */
function openGraphTitle(metadata: Metadata, label: string): string {
  const title = metadata.openGraph?.title
  if (typeof title !== 'string') {
    throw new Error(
      `${label}: erwartet wurde ein String-openGraph.title, war: ${JSON.stringify(title)}`
    )
  }
  return title
}

/**
 * Die Felder, die `generateMetadata` der Produktseite tatsaechlich liest.
 * `DbProduct` hat rund 30 Spalten — ein vollstaendiges Fixture wuerde den Test
 * an Schema-Aenderungen koppeln, die mit Titeln nichts zu tun haben.
 */
function productFixture(
  fields: Pick<DbProduct, 'slug' | 'name' | 'description' | 'tagline'>
): DbProduct {
  return fields as unknown as DbProduct
}

function listFixture(fields: Pick<DbList, 'slug' | 'title' | 'intro' | 'product_slugs'>): DbList {
  return fields as unknown as DbList
}

/* -------------------------------------------------------------------------- */
/* Konvention: kein Child-Titel traegt den Markennamen selbst                  */
/* -------------------------------------------------------------------------- */

/** Routen mit statischem `metadata`-Export, Pfad relativ zu `app/`. */
const STATIC_ROUTES: { path: string; metadata: Metadata }[] = [
  { path: 'babos/page.tsx', metadata: babosMetadata },
  { path: 'datenschutz/page.tsx', metadata: datenschutzMetadata },
  { path: 'design-preview/page.tsx', metadata: designPreviewMetadata },
  { path: 'entdecken/page.tsx', metadata: entdeckenMetadata },
  { path: 'guide/page.tsx', metadata: guideIndexMetadata },
  { path: 'geschenke/page.tsx', metadata: geschenkeMetadata },
  { path: 'impressum/page.tsx', metadata: impressumMetadata },
  { path: 'jarvis-ebook/page.tsx', metadata: jarvisMetadata },
  { path: 'listen/page.tsx', metadata: listenIndexMetadata },
  { path: 'miniboss/page.tsx', metadata: minibossMetadata },
  { path: 'queens/page.tsx', metadata: queensMetadata },
  { path: 'trending/page.tsx', metadata: trendingMetadata },
  { path: 'ueber-200/page.tsx', metadata: ueber200Metadata },
  { path: 'ueber-uns/page.tsx', metadata: ueberUnsMetadata },
  { path: 'unter-10/page.tsx', metadata: unter10Metadata },
  { path: 'unter-20/page.tsx', metadata: unter20Metadata },
  { path: 'unter-50/page.tsx', metadata: unter50Metadata },
  { path: 'unter-100/page.tsx', metadata: unter100Metadata },
  { path: 'unter-200/page.tsx', metadata: unter200Metadata },
]

/** Routen mit `generateMetadata` — je eigener Test weiter unten. */
const DYNAMIC_ROUTES = [
  'babos/[category]/page.tsx',
  'guide/[slug]/page.tsx',
  'listen/[slug]/page.tsx',
  'miniboss/[category]/page.tsx',
  'produkt/[slug]/page.tsx',
  'queens/[category]/page.tsx',
  'thema/[tag]/page.tsx',
]

/**
 * Routen, die bewusst KEINEN eigenen document title haben.
 *
 * - `page.tsx` (Homepage): liegt im selben Segment wie das Root-Layout. Laut
 *   Next-Doku greift `title.template` nicht auf die Page desselben Segments —
 *   die Homepage traegt ihren vollen Markentitel deshalb selbst.
 * - Redirect-Routen: rendern nie ein Dokument, sondern rufen nur `redirect()`.
 * - `entdecken/likes/page.tsx`: Client Component; die Metadata liegt im Layout
 *   desselben Segments und wird unten separat geprueft.
 */
const EXEMPT_ROUTES = [
  'page.tsx',
  'kategorie/[slug]/page.tsx',
  'squad/page.tsx',
  'squad/[category]/page.tsx',
  'wellness/page.tsx',
  'wellness/[category]/page.tsx',
  'entdecken/likes/page.tsx',
]

/** Alle `page.tsx` unter `app/`, Pfad relativ zu `app/` und mit `/` normalisiert. */
function findPageFiles(): string[] {
  // Aus dem Arbeitsverzeichnis statt aus `import.meta.url` aufgeloest: Vitest
  // transformiert Testdateien und `import.meta.url` traegt dann nicht zwingend
  // ein `file:`-Schema, was `fileURLToPath` scheitern laesst. Der Testlauf
  // startet in `apps/web` (vitest.config.mts liegt dort), also ist `app/`
  // relativ zum cwd der stabile Anker.
  const appDir = resolve(process.cwd(), 'app')
  return readdirSync(appDir, { recursive: true, encoding: 'utf8' })
    .map((entry) => entry.split(sep).join('/'))
    .filter((entry) => entry === 'page.tsx' || entry.endsWith('/page.tsx'))
    .sort()
}

describe('document titles — Konvention', () => {
  it('kennt jede Route unter app/', () => {
    // Ohne diesen Abgleich koennte eine neue Route mit doppeltem Markennamen
    // unbemerkt an allen Tests vorbeilaufen.
    const known = new Set([...STATIC_ROUTES.map((r) => r.path), ...DYNAMIC_ROUTES, ...EXEMPT_ROUTES])
    const found = findPageFiles()

    expect(found.length).toBeGreaterThan(20)
    expect(
      found.filter((path) => !known.has(path)),
      'Neue Route: entweder mit statischem Titel in STATIC_ROUTES aufnehmen, ' +
        'in DYNAMIC_ROUTES testen oder in EXEMPT_ROUTES begruenden'
    ).toEqual([])
    // Gegenrichtung: keine Liste zeigt auf eine geloeschte Datei.
    expect([...known].filter((path) => !found.includes(path)).sort()).toEqual([])
  })

  it.each(STATIC_ROUTES)('$path setzt einen Titel ohne Markennamen', ({ path, metadata }) => {
    const title = documentTitle(metadata, path)
    expect(title.length).toBeGreaterThan(0)
    // `title.template` im Root-Layout haengt den Markennamen an — steht er hier
    // schon, entsteht "… | Crazy Babo Bazar | Crazy Babo Bazar".
    expect(endsWithSiteName(title), `${path}: "${title}"`).toBe(false)
  })

  it('deckt /entdecken/likes ueber das Layout des Segments ab', () => {
    const title = documentTitle(likesMetadata, 'entdecken/likes/layout.tsx')
    expect(title.length).toBeGreaterThan(0)
    expect(endsWithSiteName(title)).toBe(false)
  })
})

describe('/jarvis-ebook — Indexierungsvertrag', () => {
  it('ist selbstkanonisch und nicht auf noindex gesetzt', () => {
    expect(jarvisMetadata.alternates?.canonical).toBe('/jarvis-ebook')
    expect(jarvisMetadata.robots).toBeUndefined()
  })
})

/* -------------------------------------------------------------------------- */
/* Preis-Landingpages                                                          */
/* -------------------------------------------------------------------------- */

/** Die Preisstufen in der Reihenfolge der Navigation. */
const PRICE_ROUTES: { path: string; metadata: Metadata }[] = [
  { path: '/unter-10', metadata: unter10Metadata },
  { path: '/unter-20', metadata: unter20Metadata },
  { path: '/unter-50', metadata: unter50Metadata },
  { path: '/unter-100', metadata: unter100Metadata },
  { path: '/unter-200', metadata: unter200Metadata },
  { path: '/ueber-200', metadata: ueber200Metadata },
]

describe('Preis-Landingpages', () => {
  it('/unter-10 setzt Titel, Beschreibung und Self-Canonical', () => {
    const title = documentTitle(unter10Metadata, '/unter-10')

    expect(title).toBe('Geschenke unter 10 Euro — Kleinigkeiten mit Wirkung')
    expect(endsWithSiteName(title)).toBe(false)
    expect(unter10Metadata.alternates?.canonical).toBe('/unter-10')
    expect(unter10Metadata.description).toEqual(expect.stringContaining('10 Euro'))
  })

  it.each(PRICE_ROUTES)('$path zeigt kanonisch auf sich selbst', ({ path, metadata }) => {
    // Die Seiten entstehen durch Kopieren desselben Musters. Ein mitkopierter
    // Canonical wuerde die neue Preisstufe still auf eine bestehende falten —
    // aus Sicht von Google waere sie dann gar nicht vorhanden.
    expect(metadata.alternates?.canonical, path).toBe(path)
  })

  it('vergibt je Preisstufe einen eigenen Titel und eine eigene Beschreibung', () => {
    const titles = PRICE_ROUTES.map((r) => documentTitle(r.metadata, r.path))
    const descriptions = PRICE_ROUTES.map((r) => r.metadata.description)

    expect(new Set(titles).size).toBe(PRICE_ROUTES.length)
    expect(new Set(descriptions).size).toBe(PRICE_ROUTES.length)
    for (const description of descriptions) expect(typeof description).toBe('string')
  })
})

/* -------------------------------------------------------------------------- */
/* /ueber-uns                                                                  */
/* -------------------------------------------------------------------------- */

describe('document title — /ueber-uns', () => {
  it('nennt die Marke nicht selbst', () => {
    // Der fruehere Titel trug den Markennamen als „CrazyBabo Bazar" — ohne
    // Leerzeichen und deshalb an `endsWithSiteName` vorbei. Im `<title>` stand
    // die Marke dadurch zweimal, in zwei Schreibweisen.
    const title = documentTitle(ueberUnsMetadata, '/ueber-uns')

    expect(title).toBe('Über uns — Wer steckt hinter dem Bazar?')
    expect(endsWithSiteName(title)).toBe(false)
    expect(title.replace(/\s+/g, '').toLowerCase()).not.toContain('crazybabobazar')
  })
})

/* -------------------------------------------------------------------------- */
/* Produktseite                                                                */
/* -------------------------------------------------------------------------- */

describe('document title — /produkt/[slug]', () => {
  it('nutzt den Produktnamen ohne Markennamen und behaelt ihn im Social-Titel', async () => {
    vi.mocked(getProductBySlug).mockResolvedValue(
      productFixture({
        slug: 'led-zauberwuerfel',
        name: 'LED-Zauberwürfel',
        description: 'Leuchtet in acht Farben.',
        tagline: null,
      })
    )

    const metadata = await produktMetadata({
      params: Promise.resolve({ slug: 'led-zauberwuerfel' }),
    })

    expect(documentTitle(metadata, '/produkt')).toBe('LED-Zauberwürfel')
    // openGraph und twitter stehen in Social-Previews fuer sich allein — dort
    // bleibt der Markenbezug bewusst erhalten.
    expect(openGraphTitle(metadata, '/produkt')).toBe(`LED-Zauberwürfel — ${SITE_NAME}`)
    expect(metadata.twitter?.title).toBe(`LED-Zauberwürfel — ${SITE_NAME}`)
  })

  it('trennt document title und Social-Titel', async () => {
    vi.mocked(getProductBySlug).mockResolvedValue(
      productFixture({ slug: 'x', name: 'Ein Produkt', description: null, tagline: 'Ein Haken.' })
    )

    const metadata = await produktMetadata({ params: Promise.resolve({ slug: 'x' }) })
    const title = documentTitle(metadata, '/produkt')
    const ogTitle = openGraphTitle(metadata, '/produkt')

    expect(endsWithSiteName(title)).toBe(false)
    expect(endsWithSiteName(ogTitle)).toBe(true)
    expect(stripSiteNameSuffix(ogTitle)).toBe(title)
  })

  it('liefert bei unbekanntem Slug weiterhin leere Metadata', async () => {
    vi.mocked(getProductBySlug).mockResolvedValue(null)
    await expect(
      produktMetadata({ params: Promise.resolve({ slug: 'gibt-es-nicht' }) })
    ).resolves.toEqual({})
  })
})

/* -------------------------------------------------------------------------- */
/* Listenseite                                                                 */
/* -------------------------------------------------------------------------- */

describe('document title — /listen/[slug]', () => {
  it('nutzt den Listentitel ohne Markennamen', async () => {
    vi.mocked(getListBySlug).mockResolvedValue(
      listFixture({
        slug: 'geschenke-fuer-echte-gamer',
        title: 'Geschenke für echte Gamer',
        intro: 'Kein Einheitsbrei.',
        product_slugs: ['a', 'b'],
      })
    )

    const metadata = await listeMetadata({
      params: Promise.resolve({ slug: 'geschenke-fuer-echte-gamer' }),
    })
    const title = documentTitle(metadata, '/listen')

    expect(title).toBe('Geschenke für echte Gamer')
    expect(endsWithSiteName(title)).toBe(false)
    expect(openGraphTitle(metadata, '/listen')).toBe(`Geschenke für echte Gamer — ${SITE_NAME}`)
  })

  it('liefert bei unbekanntem Slug weiterhin leere Metadata', async () => {
    vi.mocked(getListBySlug).mockResolvedValue(null)
    await expect(
      listeMetadata({ params: Promise.resolve({ slug: 'gibt-es-nicht' }) })
    ).resolves.toEqual({})
  })
})

/* -------------------------------------------------------------------------- */
/* Guides                                                                      */
/* -------------------------------------------------------------------------- */

describe('document title — /guide/[slug]', () => {
  it('hat ueberhaupt Guides', () => {
    expect(guides.length).toBeGreaterThan(0)
  })

  it.each(guides.map((g) => ({ slug: g.slug, guideTitle: g.title })))(
    '$slug nutzt den Guide-Titel ohne Markennamen',
    async ({ slug, guideTitle }) => {
      const metadata = await guideMetadata({ params: Promise.resolve({ slug }) })
      const title = documentTitle(metadata, `/guide/${slug}`)

      expect(title).toBe(guideTitle)
      expect(endsWithSiteName(title), `${slug}: "${title}"`).toBe(false)
    }
  )

  it('liefert bei unbekanntem Slug weiterhin leere Metadata', async () => {
    await expect(
      guideMetadata({ params: Promise.resolve({ slug: 'gibt-es-nicht' }) })
    ).resolves.toEqual({})
  })
})

/* -------------------------------------------------------------------------- */
/* Themenseiten                                                                */
/* -------------------------------------------------------------------------- */

describe('document title — /thema/[tag]', () => {
  it.each([...THEMA_TAGS])('%s trennt document title und openGraph-Titel', async (tag) => {
    const metadata = await themaMetadata({ params: Promise.resolve({ tag }) })
    const title = documentTitle(metadata, `/thema/${tag}`)
    const ogTitle = openGraphTitle(metadata, `/thema/${tag}`)

    // Beide Titel kommen aus derselben `metaTitle`-Konfiguration. Der
    // Markenname gehoert in den Social-Titel, nicht in den document title.
    expect(title.length).toBeGreaterThan(0)
    expect(endsWithSiteName(title), `/thema/${tag}: "${title}"`).toBe(false)
    expect(endsWithSiteName(ogTitle), `/thema/${tag}: "${ogTitle}"`).toBe(true)
    expect(stripSiteNameSuffix(ogTitle)).toBe(title)
  })

  it('bleibt bei unbekanntem Tag auf noindex', async () => {
    const metadata = await themaMetadata({ params: Promise.resolve({ tag: 'gibt-es-nicht' }) })
    expect(metadata.title).toBe('Nicht gefunden')
    expect(metadata.robots).toEqual({ index: false, follow: false })
  })
})

/* -------------------------------------------------------------------------- */
/* Persona-Kategorieseiten                                                     */
/* -------------------------------------------------------------------------- */

type PersonaCategoryRoute = {
  persona: KnownPersona
  prefix: string
  generateMetadata: (props: { params: Promise<{ category: string }> }) => Promise<Metadata>
}

const PERSONA_CATEGORY_ROUTES: PersonaCategoryRoute[] = [
  { persona: 'babo', prefix: 'Geschenke für Männer', generateMetadata: babosCategoryMetadata },
  { persona: 'queen', prefix: 'Geschenke für Frauen', generateMetadata: queensCategoryMetadata },
  { persona: 'miniboss', prefix: 'Geschenke für Kinder', generateMetadata: minibossCategoryMetadata },
]

describe('document title — Persona-Kategorien', () => {
  it.each(PERSONA_CATEGORY_ROUTES)(
    '$persona baut den Titel aus dem Kategorie-Label',
    async (route) => {
      const slugs = personaCategorySlugs(route.persona)
      expect(slugs.length).toBeGreaterThan(0)

      for (const category of slugs) {
        const label = getPersonaCategory(route.persona, category)?.label
        const metadata = await route.generateMetadata({ params: Promise.resolve({ category }) })
        const title = documentTitle(metadata, `${route.persona}/${category}`)

        expect(title).toBe(`${route.prefix} — ${label}`)
        expect(endsWithSiteName(title), title).toBe(false)
      }
    }
  )

  it.each(PERSONA_CATEGORY_ROUTES)(
    '$persona faellt bei unbekannter Kategorie auf den Slug zurueck',
    async (route) => {
      const metadata = await route.generateMetadata({
        params: Promise.resolve({ category: 'gibt-es-nicht' }),
      })
      const title = documentTitle(metadata, `${route.persona}/gibt-es-nicht`)

      expect(title).toBe(`${route.prefix} — gibt-es-nicht`)
      expect(endsWithSiteName(title)).toBe(false)
    }
  )
})
