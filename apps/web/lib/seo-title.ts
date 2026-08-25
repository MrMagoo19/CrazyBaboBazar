/**
 * Der Markenname steht als `title.template` (`'%s | Crazy Babo Bazar'`) im
 * Root-Layout (`app/layout.tsx`). Next haengt ihn an den document title jeder
 * Child-Route an.
 *
 * Kind-Routen duerfen den Namen deshalb NICHT selbst im `title` mitliefern —
 * sonst steht er doppelt im `<title>` ("Impressum — Crazy Babo Bazar | Crazy
 * Babo Bazar"). Zwei dokumentierte Ausnahmen:
 *
 * - `app/page.tsx`: liegt im selben Segment wie das Root-Layout. `title.template`
 *   greift laut Next-Doku ausdruecklich nicht auf die Page desselben Segments,
 *   die Homepage traegt ihren vollen Markentitel also selbst.
 * - `openGraph.title` / `twitter.title`: das Template gilt nur fuer den document
 *   title. Social-Titel stehen fuer sich allein und duerfen die Marke tragen.
 */
export const SITE_NAME = 'Crazy Babo Bazar'

/**
 * Trennzeichen, mit denen der Markenname im Repo angehaengt wurde: Pipe,
 * Em-Dash, En-Dash, Bindestrich.
 */
const SEPARATORS = '|\\u2014\\u2013-'

/**
 * Der Markenname als abgetrennter Suffix — die Form, die `stripSiteNameSuffix`
 * sicher entfernen kann, ohne Bedeutung zu verlieren.
 *
 * Bewusst ohne `g`-Flag: ein globales RegExp-Literal haelt `lastIndex` zwischen
 * `.test()`-Aufrufen fest und liefert dann abwechselnd `true` und `false`.
 */
const SITE_NAME_SUFFIX = new RegExp(`\\s*[${SEPARATORS}]\\s*${SITE_NAME}\\s*$`, 'i')

/**
 * Breitere Pruefung: der Titel endet auf den Markennamen — mit oder ohne
 * Trennzeichen davor ("Impressum — Crazy Babo Bazar", aber auch
 * "Ueber Crazy Babo Bazar"). Das ist die Konvention, gegen die Child-Routen
 * getestet werden.
 */
const TRAILING_SITE_NAME = new RegExp(`(?:^|[\\s${SEPARATORS}])\\s*${SITE_NAME}\\s*$`, 'i')

/** Traegt der document title den Markennamen bereits am Ende? */
export function endsWithSiteName(title: string): boolean {
  return TRAILING_SITE_NAME.test(title)
}

/**
 * Entfernt den abgetrennten Markennamen, damit `title.template` ihn genau einmal
 * setzt. Titel ohne diesen Suffix bleiben unveraendert — insbesondere solche,
 * bei denen der Markenname Teil des Satzes ist ("Ueber Crazy Babo Bazar"). Dort
 * waere ein Abschneiden Bedeutungsverlust, nicht Entdopplung; solche Titel
 * meldet `endsWithSiteName` weiterhin, damit sie bewusst entschieden werden.
 */
export function stripSiteNameSuffix(title: string): string {
  return title.replace(SITE_NAME_SUFFIX, '').trimEnd()
}
