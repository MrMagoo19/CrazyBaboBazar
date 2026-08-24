import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

import {
  allPersonaCategoryPaths,
  getPersonaCategory,
  getPersonaTaxonomy,
  isThemaTag,
  isValidPersonaCategory,
  KNOWN_PERSONAS,
  LEGACY_CATEGORY_SLUGS,
  personaCategoryPath,
  personaCategorySlugs,
  personaHubSubnav,
  personaSubnav,
  resolveLegacyCategoryRedirect,
  resolveProductCategoryLink,
  THEMA_TAGS,
} from './taxonomy'

/**
 * Die vollstaendige, erwartete Route-Matrix — bewusst als Literal notiert und
 * nicht aus der Taxonomie abgeleitet. Sonst wuerde der Test jede kuenftige
 * Aenderung der Allowlist stillschweigend mitmachen, und genau das (eine
 * Kategorie, die nur in einer der Quellen existiert) ist der Fehler, der diese
 * Regression ausgeloest hat.
 */
const EXPECTED_PAIRS: Record<string, string[]> = {
  babo: ['gaming', 'tech', 'lifestyle', 'outdoor', 'irrenhaus'],
  queen: ['kueche', 'lifestyle', 'beauty', 'geschenke'],
  miniboss: ['spielzeug', 'gaming', 'spass'],
}

const ALL_CATEGORY_SLUGS = [...new Set(Object.values(EXPECTED_PAIRS).flat())]

/**
 * Was die Hubseiten (`/babos`, `/queens`, `/miniboss`) in der Subnav zeigen —
 * ebenfalls als Literal, damit ein neues `showOnHub: true` nicht unbemerkt in
 * die Hub-Navigation rutscht. Der Babo-Hub laesst `irrenhaus` bewusst aus; die
 * Kategorieseiten zeigen weiterhin alle fuenf.
 */
const EXPECTED_HUB_PAIRS: Record<string, string[]> = {
  babo: ['gaming', 'tech', 'lifestyle', 'outdoor'],
  queen: ['kueche', 'lifestyle', 'beauty', 'geschenke'],
  miniboss: ['spielzeug', 'gaming', 'spass'],
}

/**
 * True, wenn `path` von einer echten Route bedient wird: entweder liegt eine
 * statische `app/<pfad>/page.tsx` auf der Platte, oder das letzte Segment ist
 * ein Wert aus der Allowlist einer dynamischen Route. Genau daran scheiterte
 * `/thema/irrenhaus`: `app/thema/[tag]/page.tsx` existiert, `irrenhaus` steht
 * aber in keiner `THEMA_TAGS`-Config, also `notFound()`.
 */
function isLiveRoute(path: string): boolean {
  const appDir = join(process.cwd(), 'app')
  const segments = path === '/' ? [] : path.slice(1).split('/')
  if (existsSync(join(appDir, ...segments, 'page.tsx'))) return true

  if (segments.length === 2) {
    const [route, param] = segments
    const persona = KNOWN_PERSONAS.find((p) => getPersonaTaxonomy(p).route === route)
    if (persona) {
      return existsSync(join(appDir, route, '[category]', 'page.tsx')) && isValidPersonaCategory(persona, param)
    }
    if (route === 'thema') {
      return existsSync(join(appDir, 'thema', '[tag]', 'page.tsx')) && isThemaTag(param)
    }
  }

  return false
}

describe('Persona-Kategorie-Matrix', () => {
  it('kennt genau die drei Personas', () => {
    expect([...KNOWN_PERSONAS]).toEqual(['babo', 'queen', 'miniboss'])
  })

  it('akzeptiert jedes gueltige Paar und liefert den passenden Pfad', () => {
    const routes: Record<string, string> = { babo: 'babos', queen: 'queens', miniboss: 'miniboss' }
    for (const [persona, categories] of Object.entries(EXPECTED_PAIRS)) {
      for (const category of categories) {
        expect(isValidPersonaCategory(persona, category)).toBe(true)
        expect(personaCategoryPath(persona, category)).toBe(`/${routes[persona]}/${category}`)
      }
    }
  })

  it('lehnt jede Kombination ab, die keine Route hat', () => {
    // Kreuzprodukt aller Personas mit allen im Projekt vorkommenden Kategorien:
    // Genau die Paare aus EXPECTED_PAIRS duerfen durchkommen.
    for (const persona of KNOWN_PERSONAS) {
      for (const category of ALL_CATEGORY_SLUGS) {
        const expected = EXPECTED_PAIRS[persona].includes(category)
        expect(
          isValidPersonaCategory(persona, category),
          `${persona}/${category} sollte ${expected ? 'gueltig' : 'ungueltig'} sein`
        ).toBe(expected)
      }
    }
  })

  it('lehnt Kategorien ab, die es nur in der DB gibt', () => {
    // Reale `shop_main_category`-Werte ohne Persona-Route (Beispiele aus der
    // Voice-Bible-Taxonomie) — vorher erzeugten sie 404-URLs.
    for (const orphan of ['wellness', 'health', 'haushalt', 'deko', 'tools', 'sport', 'puzzle']) {
      for (const persona of KNOWN_PERSONAS) {
        expect(isValidPersonaCategory(persona, orphan)).toBe(false)
        expect(personaCategoryPath(persona, orphan)).toBeNull()
      }
    }
  })

  it('lehnt unbekannte, leere und fehlende Personas ab', () => {
    for (const persona of ['unknown', 'wellness', 'babos', '', null, undefined]) {
      expect(isValidPersonaCategory(persona, 'gaming')).toBe(false)
      expect(personaCategoryPath(persona, 'gaming')).toBeNull()
    }
  })

  it('lehnt leere und fehlende Kategorien ab', () => {
    for (const category of ['', null, undefined, 'GAMING', 'gaming/', '../etc']) {
      expect(isValidPersonaCategory('babo', category)).toBe(false)
      expect(personaCategoryPath('babo', category)).toBeNull()
    }
  })

  it('liefert fuer gueltige Paare Label und Intro', () => {
    const cat = getPersonaCategory('babo', 'outdoor')
    expect(cat).not.toBeNull()
    expect(cat?.label).toBe('Outdoor & Survival')
    expect(cat?.navLabel).toBe('Outdoor')
    expect(cat?.intro).toContain('Survival-Kits')
  })

  it('deckt generateStaticParams die komplette Allowlist ab', () => {
    for (const persona of KNOWN_PERSONAS) {
      expect(personaCategorySlugs(persona).sort()).toEqual([...EXPECTED_PAIRS[persona]].sort())
    }
  })

  it('listet alle Pfade doppelfrei auf', () => {
    const paths = allPersonaCategoryPaths()
    expect(paths).toHaveLength(12)
    expect(new Set(paths).size).toBe(paths.length)
    for (const path of paths) {
      const [, route, category] = path.split('/')
      const persona = KNOWN_PERSONAS.find((p) => getPersonaTaxonomy(p).route === route)
      expect(persona).toBeDefined()
      expect(isValidPersonaCategory(persona, category)).toBe(true)
    }
  })

  it('hat fuer jede Persona-Route eine echte Route-Datei', () => {
    // Haelt die Taxonomie an das Dateisystem gekoppelt: eine Persona ohne
    // `[category]`-Route wuerde sonst wieder 404-URLs in die Sitemap schreiben.
    for (const persona of KNOWN_PERSONAS) {
      const route = getPersonaTaxonomy(persona).route
      // Vitest laeuft mit `root` = apps/web.
      const file = join(process.cwd(), 'app', route, '[category]', 'page.tsx')
      expect(existsSync(file), `${file} fehlt`).toBe(true)
    }
  })
})

describe('personaSubnav', () => {
  it('beginnt mit "Alle" und listet danach jede Kategorie der Persona', () => {
    for (const persona of KNOWN_PERSONAS) {
      const nav = personaSubnav(persona)
      const route = getPersonaTaxonomy(persona).route
      expect(nav[0]).toEqual({ label: 'Alle', href: `/${route}` })
      expect(nav.slice(1).map((i) => i.href)).toEqual(
        EXPECTED_PAIRS[persona].map((c) => `/${route}/${c}`)
      )
    }
  })

  it('verlinkt ausschliesslich existierende Kategorieseiten', () => {
    for (const persona of KNOWN_PERSONAS) {
      const route = getPersonaTaxonomy(persona).route
      for (const item of personaSubnav(persona).slice(1)) {
        expect(isValidPersonaCategory(persona, item.href.replace(`/${route}/`, ''))).toBe(true)
      }
    }
  })

  it('zeigt auf der Kategorieseite alle fuenf Babo-Kategorien', () => {
    expect(personaSubnav('babo').map((i) => i.href)).toContain('/babos/irrenhaus')
  })
})

describe('personaHubSubnav', () => {
  it('zeigt pro Persona genau die Hub-Kategorien', () => {
    for (const persona of KNOWN_PERSONAS) {
      const route = getPersonaTaxonomy(persona).route
      const nav = personaHubSubnav(persona)
      expect(nav[0]).toEqual({ label: 'Alle', href: `/${route}` })
      expect(nav.slice(1).map((i) => i.href)).toEqual(
        EXPECTED_HUB_PAIRS[persona].map((c) => `/${route}/${c}`)
      )
    }
  })

  it('laesst Babo’s Irrenhaus vom Hub weg, behaelt es aber als Route', () => {
    // Die Hub-UX vor dem Taxonomie-Umbau: Gaming, Tech, Lifestyle, Outdoor.
    expect(personaHubSubnav('babo').map((i) => i.href)).not.toContain('/babos/irrenhaus')
    expect(isValidPersonaCategory('babo', 'irrenhaus')).toBe(true)
    expect(allPersonaCategoryPaths()).toContain('/babos/irrenhaus')
  })

  it('laesst Queens und Miniboss unveraendert', () => {
    for (const persona of ['queen', 'miniboss'] as const) {
      expect(personaHubSubnav(persona)).toEqual(personaSubnav(persona))
    }
  })

  it('ist immer eine Teilmenge der vollen Subnav', () => {
    for (const persona of KNOWN_PERSONAS) {
      const full = new Set(personaSubnav(persona).map((i) => i.href))
      for (const item of personaHubSubnav(persona)) {
        expect(full.has(item.href), `${item.href} fehlt in personaSubnav('${persona}')`).toBe(true)
      }
    }
  })
})

describe('isThemaTag', () => {
  it('akzeptiert jeden konfigurierten Tag', () => {
    for (const tag of THEMA_TAGS) expect(isThemaTag(tag)).toBe(true)
  })

  it('lehnt Kategorien ohne Thema-Seite ab', () => {
    // `irrenhaus`, `geschenke` und `spass` sind gueltige Persona-Kategorien,
    // haben aber keine `/thema/`-Konfiguration — sie duerfen nicht als
    // `/thema/<cat>` in die Sitemap wandern.
    for (const tag of ['irrenhaus', 'geschenke', 'spass', 'wellness', '', null, undefined]) {
      expect(isThemaTag(tag)).toBe(false)
    }
  })
})

describe('resolveLegacyCategoryRedirect', () => {
  const EXPECTED_REDIRECTS: Record<string, string> = {
    'lustige-gadgets': '/babos/irrenhaus',
    'geschenke-maenner': '/babos',
    'buero-gadgets': '/thema/tech',
    'kuechen-gadgets': '/thema/kueche',
    'geschenke-unter-20': '/unter-20',
  }

  it('leitet lustige-gadgets auf die Persona-Kategorieseite statt auf /thema/irrenhaus', () => {
    // Der Breadcrumb-Fallback der Produktseiten zeigt auf /kategorie/lustige-gadgets
    // (15 Produkte im aktuellen Build). Das alte Ziel /thema/irrenhaus hat keine
    // Tag-Config und war damit eine 404 am Ende der Weiterleitungskette.
    expect(resolveLegacyCategoryRedirect('lustige-gadgets')).toBe('/babos/irrenhaus')
    expect(resolveLegacyCategoryRedirect('lustige-gadgets')).not.toContain('/thema/')
    expect(isThemaTag('irrenhaus')).toBe(false)
  })

  it('haelt jedes bekannte Mapping auf seinem Ziel', () => {
    for (const [slug, target] of Object.entries(EXPECTED_REDIRECTS)) {
      expect(resolveLegacyCategoryRedirect(slug), slug).toBe(target)
    }
  })

  it('kennt genau diese Slugs', () => {
    expect([...LEGACY_CATEGORY_SLUGS].sort()).toEqual(Object.keys(EXPECTED_REDIRECTS).sort())
  })

  it('zeigt mit keinem Mapping auf eine tote Route', () => {
    for (const slug of LEGACY_CATEGORY_SLUGS) {
      const target = resolveLegacyCategoryRedirect(slug)
      expect(isLiveRoute(target), `${slug} → ${target} rendert keine Seite`).toBe(true)
    }
  })

  it('faellt fuer unbekannte, leere und fehlende Slugs auf die Startseite', () => {
    // `constructor`/`__proto__`: der Slug kommt aus der URL, ein Objekt-Lookup
    // haette hier die Prototype-Kette getroffen und `redirect(undefined)` erzeugt.
    for (const slug of [
      'unbekannt',
      'irrenhaus',
      'LUSTIGE-GADGETS',
      'constructor',
      '__proto__',
      'toString',
      '',
      null,
      undefined,
    ]) {
      expect(resolveLegacyCategoryRedirect(slug), `${slug}`).toBe('/')
    }
    expect(isLiveRoute('/')).toBe(true)
  })

  it('erkennt tote Ziele ueberhaupt als tot', () => {
    // Absicherung der Pruefung selbst: waere isLiveRoute() zu grosszuegig,
    // wuerde der Test oben nichts mehr fangen.
    expect(isLiveRoute('/thema/irrenhaus')).toBe(false)
    expect(isLiveRoute('/babos/wellness')).toBe(false)
    expect(isLiveRoute('/gibt-es-nicht')).toBe(false)
  })
})

describe('resolveProductCategoryLink', () => {
  it('verlinkt bei gueltigem Paar die Persona-Kategorieseite', () => {
    expect(
      resolveProductCategoryLink({
        persona: 'queen',
        mainCategory: 'beauty',
        categorySlug: 'kuechen-gadgets',
        categoryName: 'Küchen-Gadgets',
      })
    ).toEqual({ href: '/queens/beauty', name: 'Queen · beauty' })
  })

  it('faellt bei ungueltigem Paar auf die /kategorie-Route zurueck', () => {
    // `babo` ist bekannt, `wellness` hat aber keine Route unter /babos.
    expect(
      resolveProductCategoryLink({
        persona: 'babo',
        mainCategory: 'wellness',
        categorySlug: 'buero-gadgets',
        categoryName: 'Büro-Gadgets',
      })
    ).toEqual({ href: '/kategorie/buero-gadgets', name: 'Büro-Gadgets' })
  })

  it('rendert ohne Persona-Route und ohne DB-Kategorie gar keinen Link', () => {
    expect(
      resolveProductCategoryLink({ persona: 'babo', mainCategory: 'wellness' })
    ).toBeNull()
    expect(
      resolveProductCategoryLink({ persona: 'unknown', mainCategory: 'gaming' })
    ).toBeNull()
    expect(resolveProductCategoryLink({ persona: null, mainCategory: null })).toBeNull()
  })

  it('zeigt eine unbekannte Persona nie als Label', () => {
    const link = resolveProductCategoryLink({
      persona: 'unknown',
      mainCategory: 'gaming',
      categorySlug: 'lustige-gadgets',
      categoryName: 'Lustige Gadgets',
    })
    expect(link).toEqual({ href: '/kategorie/lustige-gadgets', name: 'Lustige Gadgets' })
    expect(link?.name).not.toContain('unknown')
  })

  it('nutzt den Slug als Namen, wenn die DB-Kategorie keinen Namen hat', () => {
    expect(
      resolveProductCategoryLink({
        persona: null,
        mainCategory: null,
        categorySlug: 'buero-gadgets',
        categoryName: null,
      })
    ).toEqual({ href: '/kategorie/buero-gadgets', name: 'buero-gadgets' })
  })

  it('erzeugt fuer jedes gueltige Paar einen Link auf eine existierende Route', () => {
    const valid = new Set(allPersonaCategoryPaths())
    for (const [persona, categories] of Object.entries(EXPECTED_PAIRS)) {
      for (const mainCategory of categories) {
        const link = resolveProductCategoryLink({ persona, mainCategory })
        expect(link?.href).toBeDefined()
        expect(valid.has(link?.href ?? '')).toBe(true)
      }
    }
  })
})
