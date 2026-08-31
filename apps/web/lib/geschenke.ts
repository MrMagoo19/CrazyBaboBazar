/**
 * Die Einstiege des Geschenkefinders — eine Quelle fuer die Startseite und fuer
 * `/geschenke`.
 *
 * Jede `href` hier zeigt auf eine Route, die es im Repo nachweislich schon gibt:
 * die Persona-Hubs (`app/babos`, `app/queens`, `app/miniboss`), die
 * Preis-Landingpages (`app/unter-*`), die Themenseiten aus `THEMA_TAGS`
 * (`lib/taxonomy.ts`), die Guides aus `lib/guides.ts` und die kuratierten Listen
 * aus `supabase/import_lists_batch1.sql` bzw.
 * `supabase/update_list_add_gamer_products.sql`.
 *
 * Es entstehen hier bewusst KEINE neuen Kind-Routen unter `/geschenke`: jeder
 * Einstieg fuehrt auf eine bestehende Seite, die bereits indexiert werden kann.
 * Eine zweite Route mit demselben Inhalt waere ein Duplikat, kein Einstieg.
 */
export type GiftEntry = {
  href: string
  label: string
  /** Ein Satz, der sagt, was hinter dem Link steht — keine Wertung, kein Versprechen. */
  hint: string
}

/** Nach Empfänger — die drei Personas der Voice Bible. */
export const RECIPIENT_ENTRIES: GiftEntry[] = [
  { href: '/babos', label: 'Für ihn', hint: 'Tech, Gaming, Werkzeug, Grill.' },
  { href: '/queens', label: 'Für sie', hint: 'Küche, Wohnen, Beauty, Lifestyle.' },
  { href: '/miniboss', label: 'Für Kinder', hint: 'Kleine Menschen, große Ansprüche.' },
]

/** Nach Budget — nur Preisbänder, nie ein exakter Preis (Amazon-Regel). */
export const BUDGET_ENTRIES: GiftEntry[] = [
  { href: '/unter-10', label: 'Unter 10€', hint: 'Wichteln mit hartem Limit.' },
  { href: '/unter-20', label: 'Unter 20€', hint: 'Der Klassiker-Korridor.' },
  { href: '/unter-50', label: 'Unter 50€', hint: 'Wenn es was werden soll.' },
  { href: '/unter-100', label: 'Unter 100€', hint: 'Für Anlässe mit Ansage.' },
]

/** Nach Thema — jeder Tag steht in `THEMA_TAGS`. */
export const THEME_ENTRIES: GiftEntry[] = [
  { href: '/thema/gaming', label: 'Gaming', hint: 'Tabletop, Retro, Collectibles.' },
  { href: '/thema/tech', label: 'Tech', hint: 'Gadgets und Schreibtisch.' },
  { href: '/thema/kueche', label: 'Küche', hint: 'Geräte und Kulinarisches.' },
  { href: '/thema/outdoor', label: 'Outdoor', hint: 'Camping und Survival.' },
  { href: '/thema/lifestyle', label: 'Lifestyle', hint: 'Party, Bar und Fun.' },
  { href: '/thema/beauty', label: 'Beauty & Pflege', hint: 'Pflege und Wellness.' },
]

/** Nach Anlass — Guides und Listen, die genau einen Anlass bedienen. */
export const OCCASION_ENTRIES: GiftEntry[] = [
  {
    href: '/guide/wichtelgeschenke-unter-20-euro',
    label: 'Wichteln im Büro',
    hint: '25 Ideen für die Kollegenrunde.',
  },
  {
    href: '/guide/geschenke-maenner-die-alles-haben',
    label: 'Er hat angeblich alles',
    hint: 'Zehn Lücken, die er nicht zugibt.',
  },
  {
    href: '/listen/spieleabend-partyspiele-erwachsene',
    label: 'Spieleabend',
    hint: 'Partyspiele, die selten vor Mitternacht enden.',
  },
  {
    href: '/guide/home-office-setup-anfaenger',
    label: 'Neuer Schreibtisch',
    hint: 'Der komplette Einkaufszettel fürs Home-Office.',
  },
  {
    href: '/guide/beste-kuechen-gadgets-2026',
    label: 'Einzug & Küche',
    hint: 'Was in der Küche wirklich einen Unterschied macht.',
  },
  {
    href: '/listen/camping-gadgets-sommer',
    label: 'Draußen-Saison',
    hint: 'Gear für Camping und lange Sommerabende.',
  },
]

/**
 * Die fünf Seiten, die am dichtesten an einer Kaufentscheidung stehen. Sie
 * stehen auf der Startseite und auf `/geschenke` an prominenter Stelle, weil
 * jede weitere Zwischenseite genau hier Klicks kostet.
 */
export const TOP_ENTRIES: GiftEntry[] = [
  {
    href: '/listen/witzige-geschenke-maenner',
    label: 'Witzige Geschenke für Männer',
    hint: 'Kein Parfüm. Kein Werkzeug-Set. Keine Socken.',
  },
  {
    href: '/listen/geschenke-fuer-gamer',
    label: 'Geschenke für echte Gamer',
    hint: 'Für Leute mit einer Meinung zum Setup.',
  },
  {
    href: '/unter-10',
    label: 'Geschenke unter 10€',
    hint: 'Die härteste Grenze — und die interessanteste.',
  },
  {
    href: '/guide/wichtelgeschenke-unter-20-euro',
    label: 'Wichtelgeschenke unter 20 Euro',
    hint: 'Für die Kollegenrunde mit Budgetdeckel.',
  },
  {
    href: '/guide/geschenke-maenner-die-alles-haben',
    label: 'Für Männer, die alles haben',
    hint: 'Zehn Kategorien, in denen noch eine Lücke ist.',
  },
]

/** Weitere kuratierte Listen, die es im Repo nachweislich gibt. */
export const CURATED_LIST_ENTRIES: GiftEntry[] = [
  {
    href: '/listen/verrueckte-amazon-gadgets',
    label: 'Verrückte Amazon Gadgets',
    hint: 'Gibt es wirklich. Leider.',
  },
  {
    href: '/listen/schreibtisch-setup-gadgets',
    label: 'Schreibtisch Setup Gadgets',
    hint: 'Der Schreibtisch ist das neue Wohnzimmer.',
  },
  {
    href: '/listen/amazon-fundstuecke',
    label: 'Amazon Fundstücke',
    hint: 'Nicht viral — und genau deshalb hier.',
  },
]
