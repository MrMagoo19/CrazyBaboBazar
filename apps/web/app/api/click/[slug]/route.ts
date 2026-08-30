import type { NextRequest } from 'next/server'

import {
  classifyDevice,
  isConsentedSessionId,
  isValidProductSlug,
  resolveMerchant,
  sanitizeSourcePath,
} from '@/lib/affiliate'
import { isAcceptedConsent, readConsentFromCookieHeader } from '@/lib/consent-cookie'

/**
 * =============================================================================
 * AFFILIATE-WEITERLEITUNG MIT CONSENT-GEBUNDENER, DATENSPARSAMER MESSUNG (P1)
 * =============================================================================
 *
 * VERHALTENSVERSPRECHEN — in dieser Reihenfolge:
 *
 *   1. FAIL-OPEN FUER DIE WEITERLEITUNG. Ein Fehler beim Messen darf den
 *      Klick niemals kosten. Der gesamte Logging-Pfad steht in einem
 *      try/catch, dessen Fehlerfall ausdruecklich nichts tut.
 *   2. FAIL-CLOSED FUER DAS ZIEL. Die Ziel-URL kommt ausschliesslich aus den
 *      VEROEFFENTLICHTEN Produktdaten. Es gibt keinen Queryparameter, mit dem
 *      sich ein Ziel setzen liesse — diese Route kann deshalb kein offener
 *      Redirect werden. Unbekannter Slug, fehlende Konfiguration, nicht
 *      erreichbare Datenbank oder ein unsicheres Ziel enden alle auf der
 *      internen Produktseite `/produkt/<slug>`.
 *   3. CONSENT ENTSCHEIDET NUR UEBER DAS SPEICHERN — und wird HIER geprueft.
 *      Gespeichert wird ausschliesslich, wenn BEIDES zutrifft:
 *        (a) der First-Party-Consent-Cookie `cbb_consent_clickout_v2` traegt
 *            exakt `accepted` — gesetzt nur durch die ausdrueckliche
 *            Accept-Aktion im Hinweisbanner, und
 *        (b) der Queryparameter `cs` hat die UUID-Form.
 *      Eine gueltige `cs`-UUID ALLEIN reicht ausdruecklich NICHT. Ein fremd
 *      konstruierter Link mit erfundener UUID erzeugt damit null Datensaetze;
 *      die Einwilligung ist serverseitig pruefbar und wird nicht aus dem
 *      Query geglaubt. Die Weiterleitung laeuft in jedem Fall unveraendert.
 *
 * WAS GESPEICHERT WIRD — und sonst nichts:
 *   product_slug          | der geprueft gueltige Produkt-Slug
 *   merchant              | 'amazon' (aus der Host-Allowlist abgeleitet)
 *   source_path           | NUR der interne Pfad, ohne Query und Fragment
 *   device_class          | genau eine von vier groben Klassen
 *   consented_session_id  | zufaellige UUID aus dem sessionStorage
 *   created_at            | Default der Tabelle
 *
 * WAS AUSDRUECKLICH NICHT GESPEICHERT WIRD:
 *   keine IP und kein IP-Hash, kein vollstaendiger User-Agent, kein
 *   vollstaendiger Referrer, keine Querystrings, kein Cookie-Inhalt, keine
 *   Ziel-URL und keine Partner-Kennung. Der Consent-Cookie wird gelesen, aber
 *   nie gespeichert — er traegt ohnehin nur `accepted`/`declined` und keinen
 *   Identifikator.
 *
 * SERVER-GEHEIMNIS: Der Insert braucht `SUPABASE_SERVICE_ROLE_KEY`. Diese
 * Variable ist bewusst OHNE `NEXT_PUBLIC_`-Praefix, wird nur hier gelesen und
 * gelangt nie in ein Client-Bundle. Fehlt sie, bleibt die Weiterleitung
 * vollstaendig funktionsfaehig und das Logging wird uebersprungen.
 * =============================================================================
 */

// Diese Route trifft pro Aufruf eine Laufzeitentscheidung (Produktdaten,
// Header, Queryparameter) und darf niemals prerendert oder gecacht werden.
export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

const CLICK_TABLE = 'click_outs'
const LOOKUP_TIMEOUT_MS = 2500
const INSERT_TIMEOUT_MS = 1500

/**
 * `AbortSignal.timeout` gibt es in jeder Node-Laufzeit, die diese App
 * ausliefert. Der Guard schuetzt gegen exotische Testumgebungen, in denen ein
 * Polyfill die Methode nicht mitbringt — dort laeuft der Request dann ohne
 * eigenes Zeitlimit statt hart zu scheitern.
 */
function timeoutSignal(ms: number): AbortSignal | undefined {
  return typeof AbortSignal !== 'undefined' && typeof AbortSignal.timeout === 'function'
    ? AbortSignal.timeout(ms)
    : undefined
}

type ClickOutEvent = {
  product_slug: string
  merchant: string
  source_path: string | null
  device_class: string
  consented_session_id: string
}

function redirect(location: string): Response {
  const headers = new Headers()
  headers.set('Location', location)
  // Klick-outs sind personenbezogen genug, um sie niemals in einem Shared
  // Cache oder im Browser-Cache liegen zu lassen.
  headers.set('Cache-Control', 'no-store, max-age=0')
  // Die Zielseite soll unsere URL nicht als Referrer sehen. Die Partner-Kennung
  // steckt in der Ziel-URL selbst und braucht den Referrer nicht.
  headers.set('Referrer-Policy', 'no-referrer')
  // Diese Route ist nie ein Suchergebnis.
  headers.set('X-Robots-Tag', 'noindex, nofollow')
  return new Response(null, { status: 307, headers })
}

/** Fail-closed-Ziel: die interne Produktseite. Unbekannte Slugs enden dort in 404. */
function internalFallback(slug: string): Response {
  return redirect(isValidProductSlug(slug) ? `/produkt/${slug}` : '/')
}

/**
 * Liest die Ziel-URL des Produkts. Nur veroeffentlichte Produkte, nur die
 * eine Spalte, die gebraucht wird. Der Aufbau folgt bewusst dem bereits
 * vorhandenen Muster aus app/api/pin/[slug]/route.tsx (REST plus
 * NEXT_PUBLIC-Schluessel), damit es im Repo nur einen Lesepfad-Stil gibt.
 */
async function lookupAffiliateUrl(slug: string): Promise<string | null> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  if (!supabaseUrl || !supabaseKey) return null

  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/products?select=affiliate_url&slug=eq.${encodeURIComponent(slug)}&is_published=eq.true&limit=1`,
      {
        headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        cache: 'no-store',
        signal: timeoutSignal(LOOKUP_TIMEOUT_MS),
      }
    )
    if (!res.ok) return null
    const rows: unknown = await res.json()
    if (!Array.isArray(rows) || rows.length === 0) return null
    const value = (rows[0] as { affiliate_url?: unknown }).affiliate_url
    return typeof value === 'string' ? value : null
  } catch {
    // Netz-, Timeout- oder Parsefehler: kein Ziel, also fail-closed.
    return null
  }
}

/**
 * Der EINZIGE Fehlerkanal des Logging-Pfads.
 *
 * Er nimmt bewusst nur einen kurzen, generischen Grund entgegen. Ausdruecklich
 * NICHT uebergeben werden: die Ziel-URL, der Inhalt des Consent-Cookies, die
 * Sitzungskennung und der Produkt-Slug. Ein Serverlog, das den Slug traegt,
 * waere eine zweite, unkontrollierte Kopie der Messdaten — und zwar eine ohne
 * Einwilligung, ohne Retention und neben IP und Zeitstempel des Hosters.
 */
function noteLoggingFailure(reason: string): void {
  try {
    console.warn(`[click-out] Messung fehlgeschlagen: ${reason}`)
  } catch {
    // Selbst eine kaputte Konsole darf die Weiterleitung nicht kosten.
  }
}

/**
 * Schreibt genau einen Event. Wirft nie — jeder Fehler wird geschluckt, damit
 * die Weiterleitung fail-open bleibt.
 *
 * ZWEI FEHLERARTEN, EIN VERHALTEN: `fetch` wirft nur bei Netz-, Timeout- und
 * Abbruchfehlern. Ein abgelehnter Insert — fehlende Tabelle, abgelaufener
 * Schluessel, verletzter CHECK-Constraint — kommt statt dessen als normale
 * Antwort mit 4xx/5xx zurueck und wuerde ohne die `res.ok`-Pruefung als Erfolg
 * durchgehen. Eine dauerhaft tote Messung waere dann von aussen nicht von einer
 * Messung ohne Klicks zu unterscheiden. Beide Faelle enden hier gleich: notiert,
 * aber nicht blockierend.
 */
async function logClickOut(event: ClickOutEvent): Promise<void> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  // Ohne Server-Schluessel wird nicht gemessen. Das ist der Normalzustand,
  // solange die Tabelle auf Production noch nicht freigegeben ist.
  if (!supabaseUrl || !serviceKey) return

  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/${CLICK_TABLE}`, {
      method: 'POST',
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
        // Der Antwortkoerper wird nicht gebraucht — kein Rueckkanal, keine Daten.
        // Nur der Statuscode wird ausgewertet.
        Prefer: 'return=minimal',
      },
      body: JSON.stringify(event),
      cache: 'no-store',
      signal: timeoutSignal(INSERT_TIMEOUT_MS),
    })
    if (!res.ok) noteLoggingFailure(`HTTP ${res.status}`)
  } catch {
    // Ein fehlgeschlagener Insert ist ein Messverlust, kein Nutzerproblem.
    noteLoggingFailure('Netz-, Timeout- oder Abbruchfehler')
  }
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params

  // 1. Slug-Form pruefen, bevor irgendetwas damit passiert.
  if (!isValidProductSlug(slug)) return redirect('/')

  // 2. Ziel serverseitig aufloesen.
  const affiliateUrl = await lookupAffiliateUrl(slug)
  const merchant = resolveMerchant(affiliateUrl)
  if (!merchant || typeof affiliateUrl !== 'string') {
    // Unbekannter Slug, unveroeffentlicht, fehlende Konfiguration oder ein
    // Ziel ausserhalb der Merchant-Allowlist: alles endet intern.
    return internalFallback(slug)
  }

  // 3. Messen — nur mit serverseitig gepruefter Einwilligung, nur datensparsam,
  //    nie blockierend. Die UND-Verknuepfung ist der Kern: der Cookie belegt
  //    die Entscheidung, `cs` liefert die kurzlebige Kennung. Fehlt oder
  //    widerspricht eines von beiden, wird nichts geschrieben.
  const consent = readConsentFromCookieHeader(request.headers.get('cookie'))
  const consentedSessionId = request.nextUrl.searchParams.get('cs')
  if (isAcceptedConsent(consent) && isConsentedSessionId(consentedSessionId)) {
    await logClickOut({
      product_slug: slug,
      merchant,
      source_path: sanitizeSourcePath(request.nextUrl.searchParams.get('from')),
      device_class: classifyDevice(request.headers.get('user-agent')),
      consented_session_id: consentedSessionId,
    })
  }

  // 4. Weiterleiten.
  return redirect(affiliateUrl)
}
