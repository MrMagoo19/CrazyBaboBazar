/**
 * Gemeinsame Affiliate-Schicht fuer Klick-out-Links (P1).
 *
 * Diese Datei ist bewusst frei von React-, Next- und Supabase-Importen: sie
 * wird sowohl im Client-Bundle (components/ui/affiliate-link.tsx) als auch im
 * Route-Handler (app/api/click/[slug]/route.ts) benutzt und ist deshalb
 * vollstaendig ohne Netz- oder DB-Zugriff testbar.
 *
 * DATENMINIMIERUNG — was hier NICHT passiert:
 *   * Es wird kein Ziel aus einem Queryparameter uebernommen. Die Ziel-URL
 *     kommt ausschliesslich serverseitig aus den veroeffentlichten
 *     Produktdaten (siehe Route-Handler). `isSafeAffiliateUrl` ist die zweite
 *     Verteidigungslinie gegen ein gekapertes Ziel in der Datenbank.
 *   * `sanitizeSourcePath` gibt garantiert nur einen PFAD zurueck — Query und
 *     Fragment werden verworfen, absolute und protokollrelative Eingaben
 *     abgelehnt. Damit kann ueber die Herkunftsangabe kein Suchbegriff und
 *     keine fremde Domain in die Datenbank gelangen.
 *   * `classifyDevice` reduziert den User-Agent auf genau vier Klassen. Der
 *     vollstaendige User-Agent wird nie weitergereicht und nie gespeichert.
 */

/** Merchant-Kennungen. Aktuell gibt es genau einen echten Partner. */
export type Merchant = 'amazon'

export type DeviceClass = 'mobile' | 'tablet' | 'desktop' | 'unknown'

/**
 * Erlaubte Ziel-Hosts je Merchant. Bewusst eine exakte Hostliste und kein
 * Suffix-Match: `amazon.de.evil.example` wuerde einen naiven `endsWith`-Test
 * bestehen, diese Liste dagegen nicht. Neue Merchants kommen als weiterer
 * Eintrag dazu, ohne dass sich die Aufrufer aendern.
 */
const MERCHANT_HOSTS: Readonly<Record<string, Merchant>> = {
  'amzn.to': 'amazon',
  'amzn.eu': 'amazon',
  'amazon.de': 'amazon',
  'www.amazon.de': 'amazon',
  'm.amazon.de': 'amazon',
  'smile.amazon.de': 'amazon',
}

/** CTA-Beschriftung je Merchant. Spaeter erweiterbar, ohne Aufrufer zu aendern. */
const MERCHANT_CTA_LABEL: Readonly<Record<Merchant, string>> = {
  amazon: 'Bei Amazon ansehen',
}

/** Kurzform fuer enge Flaechen (Karten-Footer). */
const MERCHANT_SHORT_LABEL: Readonly<Record<Merchant, string>> = {
  amazon: 'Amazon',
}

/**
 * Produkt-Slugs sind in der Datenbank durchgaengig kleingeschrieben und mit
 * Bindestrich getrennt. Der Guard haelt alles andere von der Redirect-URL fern
 * — insbesondere Pfadwechsel (`..`), Slashes und Steuerzeichen.
 */
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/

/** Zufaellige UUID (v4-Form). Nur diese Form wird als Session-ID akzeptiert. */
const SESSION_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

/** Obergrenze fuer den gespeicherten Herkunftspfad. */
export const MAX_SOURCE_PATH_LENGTH = 128

/**
 * C0-Steuerzeichen und DEL. Bewusst als Zeichencode-Schleife statt als
 * Regex-Zeichenklasse: so bleibt diese Datei reiner ASCII-Text, ohne
 * Steuerzeichen im Quelltext und ohne Escape-Sequenz, die beim Kopieren
 * kaputtgehen kann.
 */
function hasControlChar(value: string): boolean {
  for (let i = 0; i < value.length; i++) {
    const code = value.charCodeAt(i)
    if (code < 32 || code === 127) return true
  }
  return false
}

export function isValidProductSlug(slug: unknown): slug is string {
  return typeof slug === 'string' && slug.length > 0 && slug.length <= 120 && SLUG_PATTERN.test(slug)
}

export function isConsentedSessionId(value: unknown): value is string {
  return typeof value === 'string' && SESSION_ID_PATTERN.test(value)
}

/**
 * Merchant eines Ziels — oder `null`, wenn das Ziel nicht sicher ist.
 *
 * Sicher heisst: absolute URL, Schema exakt `https:`, Host exakt in
 * MERCHANT_HOSTS, keine eingebetteten Zugangsdaten. Alles andere ist
 * fail-closed `null`; der Aufrufer leitet dann auf die interne Produktseite.
 */
export function resolveMerchant(rawUrl: unknown): Merchant | null {
  if (typeof rawUrl !== 'string' || rawUrl.length === 0) return null
  let url: URL
  try {
    url = new URL(rawUrl)
  } catch {
    return null
  }
  if (url.protocol !== 'https:') return null
  // `user:pass@host` wuerde in Logs und Redirects Zugangsdaten mitschleppen.
  if (url.username !== '' || url.password !== '') return null
  return MERCHANT_HOSTS[url.hostname.toLowerCase()] ?? null
}

export function isSafeAffiliateUrl(rawUrl: unknown): boolean {
  return resolveMerchant(rawUrl) !== null
}

export function merchantCtaLabel(merchant: Merchant | null): string {
  return merchant ? MERCHANT_CTA_LABEL[merchant] : 'Zum Angebot'
}

export function merchantShortLabel(merchant: Merchant | null): string {
  return merchant ? MERCHANT_SHORT_LABEL[merchant] : 'Angebot'
}

/**
 * Reduziert eine Herkunftsangabe auf einen reinen internen Pfad.
 *
 * Rueckgabe `null` bedeutet: keine verwertbare Herkunft. Der Aufrufer speichert
 * dann nichts statt zu raten.
 */
export function sanitizeSourcePath(raw: unknown): string | null {
  if (typeof raw !== 'string') return null
  const trimmed = raw.trim()
  if (trimmed === '') return null
  // Nur relative Pfade. `//host` waere protokollrelativ und damit extern,
  // `https://host` absolut — beides waere eine fremde Domain im Datensatz.
  if (!trimmed.startsWith('/')) return null
  if (trimmed.startsWith('//')) return null
  if (hasControlChar(trimmed)) return null

  let pathname: string
  try {
    // Die Basis ist ein Platzhalter: sie taucht im Ergebnis nie auf, weil nur
    // `pathname` gelesen wird. Query und Fragment fallen hier bewusst weg.
    pathname = new URL(trimmed, 'https://source.invalid').pathname
  } catch {
    return null
  }

  let decoded: string
  try {
    decoded = decodeURIComponent(pathname)
  } catch {
    // Kaputte Prozentkodierung — lieber nichts speichern als Muell.
    return null
  }

  if (hasControlChar(decoded)) return null
  if (decoded.includes('..')) return null
  if (decoded.length > MAX_SOURCE_PATH_LENGTH) return null
  return decoded
}

/**
 * Interne Klick-out-URL. Sie ist auch ohne JavaScript gueltig: der Redirect
 * haengt nicht am Client, nur die Consent-Kennung (`cs`) kommt spaeter dazu.
 */
export function buildClickOutHref(
  slug: string,
  sourcePath?: string | null,
  consentedSessionId?: string | null
): string {
  const base = `/api/click/${encodeURIComponent(slug)}`
  const params = new URLSearchParams()
  const cleanPath = sanitizeSourcePath(sourcePath)
  if (cleanPath) params.set('from', cleanPath)
  if (isConsentedSessionId(consentedSessionId)) params.set('cs', consentedSessionId)
  const query = params.toString()
  return query ? `${base}?${query}` : base
}

/**
 * Grobe Geraeteklasse aus dem User-Agent. Bewusst nur vier Werte — feiner
 * waere ein Fingerprint-Baustein und ist fuer die Auswertung nicht noetig.
 */
export function classifyDevice(userAgent: string | null | undefined): DeviceClass {
  if (typeof userAgent !== 'string' || userAgent.trim() === '') return 'unknown'
  const ua = userAgent.toLowerCase()
  // Tablet zuerst: iPad und Android-ohne-"mobile" wuerden sonst als mobile bzw.
  // desktop durchrutschen.
  if (/ipad|tablet|playbook|silk|kindle/.test(ua)) return 'tablet'
  if (/android/.test(ua) && !/mobile/.test(ua)) return 'tablet'
  if (/mobi|iphone|ipod|windows phone|android/.test(ua)) return 'mobile'
  if (/mozilla|chrome|safari|firefox|edge|opera|trident/.test(ua)) return 'desktop'
  return 'unknown'
}
