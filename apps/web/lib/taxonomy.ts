// Persona/Kategorie-Taxonomie — Single Source of Truth fuer alle Routen der Form
// `/<persona-route>/<kategorie>`.
//
// Vorher lag dieselbe Allowlist dreimal getrennt in den Route-Dateien
// (`app/babos/[category]`, `app/queens/[category]`, `app/miniboss/[category]`),
// waehrend `app/sitemap.ts` die Pfade frei aus `shop_persona` +
// `shop_main_category` der DB zusammensetzte und `app/produkt/[slug]` fuer jede
// bekannte Persona jeden beliebigen `shop_main_category`-Wert verlinkte. Jede
// Kategorie, die in der DB steht, aber in keiner der drei Allowlists auftaucht,
// wurde damit als strukturelle 404 in Sitemap und Breadcrumb ausgeliefert.
//
// Ab hier gilt: Wer einen Persona-Kategorie-Pfad braucht, fragt dieses Modul.
// Neue Kategorie = ein Eintrag hier + (falls gewuenscht) ein Thema-Eintrag in
// `app/thema/[tag]`; die Route-Dateien, die Sitemap und der Breadcrumb ziehen
// automatisch nach.

import { isKnownPersona, PERSONA_ROUTES, personaLabel, type KnownPersona } from './persona'

/** Ein Eintrag der Persona-Subnavigation (`PersonaPage`-Prop `subnav`). */
export type SubNavItem = {
  label: string
  href: string
}

export type PersonaCategory = {
  /** URL-Segment, identisch mit `products.shop_main_category`. */
  slug: string
  /** Ueberschrift/`description` der Kategorieseite. */
  label: string
  /** Kuerzeres Label in der Subnav. */
  navLabel: string
  /** Intro-Absatz der Kategorieseite, zugleich Meta-Description. */
  intro: string
  /**
   * Ob die Kategorie in der Subnav der Persona-Hubseite (`/babos`, `/queens`,
   * `/miniboss`) auftaucht. Die Kategorieseiten zeigen unabhaengig davon immer
   * alle Kategorien der Persona.
   *
   * Bewusst ein Pflichtfeld: eine neue Kategorie muss sich entscheiden, statt
   * still auf dem Hub zu landen.
   */
  showOnHub: boolean
}

export type PersonaTaxonomy = {
  persona: KnownPersona
  /** Erstes Pfadsegment, z. B. `babos` fuer die Persona `babo`. */
  route: string
  categories: readonly PersonaCategory[]
}

/* -------------------------------------------------------------------------- */
/* Taxonomie                                                                   */
/* -------------------------------------------------------------------------- */

// Labels und Intros sind unveraendert aus den drei Route-Dateien uebernommen —
// dieser Patch aendert keine sichtbaren Texte.
const TAXONOMY: Record<KnownPersona, PersonaTaxonomy> = {
  babo: {
    persona: 'babo',
    route: PERSONA_ROUTES.babo,
    categories: [
      {
        slug: 'gaming',
        label: 'Gaming',
        navLabel: 'Gaming',
        intro: 'Tabletop, Retro-Konsolen, Speed Cubes und LEGO Collectibles — alles was das Gamer-Herz begehrt.',
        showOnHub: true,
      },
      {
        slug: 'tech',
        label: 'Tech & DIY',
        navLabel: 'Tech & DIY',
        intro: 'ESP32, LED-Streifen, Schreibtisch-Setup und DIY-Bausätze — für Tüftler und Tech-Enthusiasten.',
        showOnHub: true,
      },
      {
        slug: 'lifestyle',
        label: 'Lifestyle',
        navLabel: 'Lifestyle',
        intro: 'Bier brauen, Fliegenjäger, Kochbücher und Party-Gadgets — für den Babo mit Stil.',
        showOnHub: true,
      },
      {
        slug: 'outdoor',
        label: 'Outdoor & Survival',
        navLabel: 'Outdoor',
        intro: 'Survival-Kits, Campingausrüstung, Feuerstahl und Zelte — für Abenteuer in der Natur.',
        showOnHub: true,
      },
      {
        slug: 'irrenhaus',
        label: "Babo's Irrenhaus",
        navLabel: "Babo's Irrenhaus",
        intro: 'Fisch-Schlappen. Kronkorken-Pistolen. Blobfish-Hausschuhe. Produkte die niemand braucht — und alle wollen.',
        // Die Hubseite laesst das Irrenhaus bewusst aus der Subnav: es ist der
        // Kuriositaeten-Topf, kein gleichrangiger Einstieg. Die Route existiert
        // und bleibt auf den Kategorieseiten verlinkt — nur nicht im Hub-Menue.
        showOnHub: false,
      },
    ],
  },
  queen: {
    persona: 'queen',
    route: PERSONA_ROUTES.queen,
    categories: [
      {
        slug: 'kueche',
        label: 'Küchen-Gadgets',
        navLabel: 'Küche',
        intro: 'Weinbelüfter, Katzen-Suppenkellen und AeroPress — Küche trifft Persönlichkeit.',
        showOnHub: true,
      },
      {
        slug: 'lifestyle',
        label: 'Lifestyle & Deko',
        navLabel: 'Lifestyle',
        intro: 'LEGO Botanicals, Haustier-Kameras, Harry Potter Fandom und mehr — Lifestyle für Queens.',
        showOnHub: true,
      },
      {
        slug: 'beauty',
        label: 'Beauty & Pflege',
        navLabel: 'Beauty',
        intro: 'Korean Skincare, UV-Nagellampen und japanische Gelstifte — Beauty mit Anspruch.',
        showOnHub: true,
      },
      {
        slug: 'geschenke',
        label: 'Geschenke',
        navLabel: 'Geschenke',
        intro: 'Personalisierte Puzzles, Lehrergeschenke und Jutebeutel — Geschenke die ankommen.',
        showOnHub: true,
      },
    ],
  },
  miniboss: {
    persona: 'miniboss',
    route: PERSONA_ROUTES.miniboss,
    categories: [
      {
        slug: 'spielzeug',
        label: 'Spielzeug & Lernen',
        navLabel: 'Spielzeug',
        intro: 'Lernroboter, Mikroskope und magnetische Bausteine — Spielzeug das schlau macht.',
        showOnHub: true,
      },
      {
        slug: 'gaming',
        label: 'Gaming & Collectibles',
        navLabel: 'Gaming',
        intro: 'Minecraft-Nachtlichter, Marvel-Spardosen und Disney-Digital-Pets — Sammeln und Spielen.',
        showOnHub: true,
      },
      {
        slug: 'spass',
        label: 'Spaß & Party',
        navLabel: 'Spaß',
        intro: 'Partyspiele, Wasserpistolen, Kartenspiele und Jenga-Türme — für unvergessliche Spieleabende.',
        showOnHub: true,
      },
    ],
  },
}

/** Alle Personas in stabiler Reihenfolge. */
export const KNOWN_PERSONAS: readonly KnownPersona[] = ['babo', 'queen', 'miniboss']

/* -------------------------------------------------------------------------- */
/* Lookups                                                                     */
/* -------------------------------------------------------------------------- */

export function getPersonaTaxonomy(persona: KnownPersona): PersonaTaxonomy {
  return TAXONOMY[persona]
}

/**
 * Kategorie-Definition fuer ein Persona/Kategorie-Paar oder `null`.
 *
 * Nimmt bewusst `string | null | undefined` entgegen: die Aufrufer bekommen
 * ungepruefte Werte aus der URL (`params.category`) oder aus der DB
 * (`shop_main_category`).
 */
export function getPersonaCategory(
  persona: string | null | undefined,
  category: string | null | undefined
): PersonaCategory | null {
  if (!isKnownPersona(persona) || !category) return null
  return TAXONOMY[persona].categories.find((c) => c.slug === category) ?? null
}

/** True genau dann, wenn `/${route}/${category}` eine echte Seite rendert. */
export function isValidPersonaCategory(
  persona: string | null | undefined,
  category: string | null | undefined
): boolean {
  return getPersonaCategory(persona, category) !== null
}

/** Kategorie-Slugs einer Persona — Basis fuer `generateStaticParams`. */
export function personaCategorySlugs(persona: KnownPersona): string[] {
  return TAXONOMY[persona].categories.map((c) => c.slug)
}

/**
 * Absoluter Pfad zur Persona-Kategorieseite oder `null`, wenn das Paar keine
 * Route hat. Nie einen Pfad selbst zusammensetzen — immer hierueber.
 */
export function personaCategoryPath(
  persona: string | null | undefined,
  category: string | null | undefined
): string | null {
  if (!isKnownPersona(persona)) return null
  const cat = getPersonaCategory(persona, category)
  if (!cat) return null
  return `/${TAXONOMY[persona].route}/${cat.slug}`
}

/** Alle existierenden Persona-Kategorie-Pfade. */
export function allPersonaCategoryPaths(): string[] {
  return KNOWN_PERSONAS.flatMap((p) =>
    TAXONOMY[p].categories.map((c) => `/${TAXONOMY[p].route}/${c.slug}`)
  )
}

function subnavFor(persona: KnownPersona, categories: readonly PersonaCategory[]): SubNavItem[] {
  const t = TAXONOMY[persona]
  return [
    { label: 'Alle', href: `/${t.route}` },
    ...categories.map((c) => ({ label: c.navLabel, href: `/${t.route}/${c.slug}` })),
  ]
}

/**
 * Subnav der Kategorieseiten: "Alle" + jede Kategorie der Persona.
 *
 * Beide Subnav-Varianten kommen aus derselben Kategorienliste — was hier
 * auftaucht, hat garantiert eine Route.
 */
export function personaSubnav(persona: KnownPersona): SubNavItem[] {
  return subnavFor(persona, TAXONOMY[persona].categories)
}

/**
 * Subnav der Hubseite: "Alle" + jede Kategorie mit `showOnHub`.
 *
 * Der Hub ist der Einstieg und zeigt bewusst eine kuratierte Auswahl (aktuell
 * faellt nur `babo/irrenhaus` heraus). Ohne diesen Helfer wanderte die
 * Entscheidung wieder in eine handgepflegte Liste in `app/<route>/page.tsx` —
 * genau die Duplikate, die dieser Umbau beseitigt hat.
 */
export function personaHubSubnav(persona: KnownPersona): SubNavItem[] {
  return subnavFor(
    persona,
    TAXONOMY[persona].categories.filter((c) => c.showOnHub)
  )
}

/* -------------------------------------------------------------------------- */
/* Themen-Routen (`/thema/<tag>`)                                              */
/* -------------------------------------------------------------------------- */

/**
 * Tags, fuer die `app/thema/[tag]/page.tsx` eine Konfiguration hat. Alles andere
 * ruft dort `notFound()` auf.
 *
 * Die Reihenfolge entspricht `TAG_CONFIG`; `ThemaTag` typisiert dort das Objekt,
 * sodass ein Tag hier ohne Config (oder umgekehrt) ein Typfehler ist.
 */
export const THEMA_TAGS = [
  'gaming',
  'tech',
  'kueche',
  'lifestyle',
  'outdoor',
  'beauty',
  'spielzeug',
  'fitness',
  'haushalt',
] as const

export type ThemaTag = (typeof THEMA_TAGS)[number]

export function isThemaTag(tag: string | null | undefined): tag is ThemaTag {
  return typeof tag === 'string' && (THEMA_TAGS as readonly string[]).includes(tag)
}

/* -------------------------------------------------------------------------- */
/* Legacy-Redirects (`/kategorie/<slug>`)                                      */
/* -------------------------------------------------------------------------- */

/**
 * Ziel eines Legacy-Redirects — bewusst als Beschreibung, nicht als fertiger
 * Pfad. Der Pfad entsteht erst in `resolveLegacyCategoryRedirect()` aus
 * derselben Taxonomie, aus der die Routen ihre Gueltigkeit ableiten.
 *
 * Der Grund: `lustige-gadgets` zeigte auf `/thema/irrenhaus`, aber `irrenhaus`
 * hat keine `THEMA_TAGS`-Config — die Route rief `notFound()` auf. Ein Redirect
 * auf eine 404 ist schlimmer als gar keiner, weil der Breadcrumb der
 * Produktseiten genau hier landet. Mit `tag: ThemaTag` bzw. dem Resolver ist
 * das jetzt ein Typ- statt ein Laufzeitfehler.
 */
type LegacyRedirectTarget =
  /** Persona-Hub, z. B. `/babos`. */
  | { kind: 'persona'; persona: KnownPersona }
  /** Persona-Kategorieseite, z. B. `/babos/irrenhaus`. */
  | { kind: 'personaCategory'; persona: KnownPersona; category: string }
  /** Themenseite — `ThemaTag` erzwingt eine existierende Config. */
  | { kind: 'thema'; tag: ThemaTag }
  /** Statische Seite ohne Taxonomie-Bezug, z. B. `/unter-20`. */
  | { kind: 'page'; path: string }

// `Map` statt Objekt-Literal: der Slug kommt ungeprueft aus der URL, und ein
// Objekt-Lookup wuerde bei `/kategorie/constructor` die Prototype-Kette treffen.
const LEGACY_CATEGORY_REDIRECTS = new Map<string, LegacyRedirectTarget>([
  ['lustige-gadgets',    { kind: 'personaCategory', persona: 'babo', category: 'irrenhaus' }],
  ['geschenke-maenner',  { kind: 'persona', persona: 'babo' }],
  ['buero-gadgets',      { kind: 'thema', tag: 'tech' }],
  ['kuechen-gadgets',    { kind: 'thema', tag: 'kueche' }],
  ['geschenke-unter-20', { kind: 'page', path: '/unter-20' }],
])

/** Alle Slugs mit konfiguriertem Redirect, in stabiler Reihenfolge. */
export const LEGACY_CATEGORY_SLUGS: readonly string[] = [...LEGACY_CATEGORY_REDIRECTS.keys()]

/**
 * Ziel-Pfad fuer `/kategorie/<slug>`. Unbekannte Slugs landen auf der Homepage,
 * damit die Route nie eine 404 ausliefert.
 */
export function resolveLegacyCategoryRedirect(slug: string | null | undefined): string {
  const target = slug ? LEGACY_CATEGORY_REDIRECTS.get(slug) : undefined
  if (!target) return '/'

  switch (target.kind) {
    case 'persona':
      return `/${TAXONOMY[target.persona].route}`
    case 'personaCategory':
      // Faellt auf den Persona-Hub zurueck, falls die Kategorie irgendwann aus
      // der Taxonomie verschwindet — nie auf einen toten Pfad.
      return personaCategoryPath(target.persona, target.category) ?? `/${TAXONOMY[target.persona].route}`
    case 'thema':
      return `/thema/${target.tag}`
    case 'page':
      return target.path
  }
}

/* -------------------------------------------------------------------------- */
/* Breadcrumb-/Kategorie-Link-Aufloesung                                       */
/* -------------------------------------------------------------------------- */

export type CategoryLink = {
  href: string
  name: string
}

export type ProductCategoryInput = {
  persona: string | null | undefined
  mainCategory: string | null | undefined
  /** `products.categories.slug` — Fallback auf die immer weiterleitende Route. */
  categorySlug?: string | null
  categoryName?: string | null
}

/**
 * Ziel des Produkt-Breadcrumbs.
 *
 * 1. Gueltiges Persona/Kategorie-Paar → Persona-Kategorieseite.
 * 2. Sonst, falls eine DB-Kategorie existiert → `/kategorie/<slug>`. Diese Route
 *    leitet immer weiter (unbekannte Slugs auf `/`) und ist damit nie eine 404.
 * 3. Sonst kein Kategorie-Link.
 *
 * Fall 1 galt frueher fuer *jede* bekannte Persona mit *irgendeinem*
 * `shop_main_category` — genau der Pfad, ueber den tote Breadcrumb-Links
 * entstanden sind.
 */
export function resolveProductCategoryLink(input: ProductCategoryInput): CategoryLink | null {
  const { persona, mainCategory, categorySlug, categoryName } = input

  const href = personaCategoryPath(persona, mainCategory)
  if (href) {
    // Textform unveraendert: "Babo · gaming".
    return { href, name: `${personaLabel(persona)} · ${mainCategory}` }
  }

  if (categorySlug) {
    return { href: `/kategorie/${categorySlug}`, name: categoryName ?? categorySlug }
  }

  return null
}
