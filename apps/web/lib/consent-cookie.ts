/**
 * FUNKTIONALER FIRST-PARTY-CONSENT-COOKIE (P1, Consent v2).
 *
 * WARUM ES DIESEN COOKIE GIBT — der Befund, der ihn erzwungen hat:
 * Die erste Fassung hat die Einwilligung ausschliesslich im Browser gehalten
 * (localStorage) und dem Server nur die Sitzungskennung `cs` im Query
 * mitgegeben. Damit war jede syntaktisch gueltige UUID im Link bereits
 * "Einwilligung": ein fremd konstruierter Link haette ohne jede Entscheidung
 * des Besuchers einen Datensatz erzeugt. Eine Einwilligung, die der Server
 * nicht selbst pruefen kann, ist keine.
 *
 * DIE KORREKTUR: Die Entscheidung wird in einem eigenen First-Party-Cookie
 * gefuehrt, den ausschliesslich die ausdrueckliche Accept-/Decline-Aktion im
 * Hinweisbanner setzt. Der Server liest sie aus dem `Cookie`-Header und
 * speichert nur, wenn dort `accepted` steht.
 *
 * WAS IN DIESEM COOKIE STEHT — und was ausdruecklich nicht:
 *   Inhalt:      exakt eine der beiden Zeichenketten `accepted` / `declined`.
 *   Nicht drin:  KEINE Sitzungskennung, keine UUID, keine Nutzer-ID, kein
 *                Zeitstempel, kein Zaehler, nichts Wiedererkennbares. Der
 *                Cookie traegt eine Entscheidung, keinen Identifikator, und
 *                ist deshalb kein Tracking-Cookie.
 *
 * Die Sitzungskennung bleibt wie vereinbart ausschliesslich im
 * `sessionStorage` (lib/click-session.ts) und gelangt NIE in einen Cookie.
 *
 * ATTRIBUTE UND IHRE BEGRUENDUNG:
 *   Path=/         Die Entscheidung gilt fuer die ganze Site.
 *   SameSite=Lax   Der Cookie soll bei fremd initiierten Unteranfragen nicht
 *                  mitfahren. `Lax` reicht, weil der Klick-out eine normale
 *                  Top-Level-Navigation auf unserer eigenen Seite ist.
 *   Secure         Nur ueber HTTPS. Bewusst NUR gesetzt, wenn die Seite auch
 *                  ueber HTTPS laeuft: ein `Secure`-Cookie wird auf
 *                  `http://localhost` vom Browser verworfen, die lokale
 *                  Entwicklung koennte die Entscheidung sonst nie speichern.
 *   KEIN HttpOnly  Der Hinweisbanner muss den Cookie selbst setzen und lesen.
 *                  Das ist unkritisch, weil der Inhalt kein Geheimnis ist.
 *
 * KEINE MIGRATION AUS v1. Der alte Schluessel `cbb-cookie-consent-v1` stammt
 * aus dem reinen Hinweis zu Vercel/Amazon und deckte die neue, persistente
 * Klick-out-Messung nicht ab. Eine damals erteilte Zustimmung galt einem
 * anderen Zweck und wird hier bewusst weder gelesen noch uebernommen — der
 * neue Zweck muss neu entschieden werden.
 */

import type { ConsentValue } from './consent-store'

/**
 * Das `v2` im Namen ist Absicht: Der Name ist die Zweckgrenze. Wer je einen
 * Zweck hinzufuegt, braucht einen neuen Namen und damit eine neue Entscheidung.
 */
export const CONSENT_COOKIE_NAME = 'cbb_consent_clickout_v2'

/** Rund sechs Monate. Danach wird ohnehin neu gefragt. */
export const CONSENT_COOKIE_MAX_AGE_SECONDS = 60 * 60 * 24 * 182

export function parseConsentValue(raw: unknown): ConsentValue | null {
  return raw === 'accepted' || raw === 'declined' ? raw : null
}

/** Die einzige Stelle, an der "darf gespeichert werden" entschieden wird. */
export function isAcceptedConsent(raw: unknown): boolean {
  return parseConsentValue(raw) === 'accepted'
}

/**
 * Liest unseren Wert aus einem Cookie-Header.
 *
 * Bewusst dieselbe Funktion fuer beide Seiten: `document.cookie` im Browser und
 * der `Cookie`-Header im Route-Handler haben dasselbe Format
 * (`name=value; name2=value2`). Ein zweiter Parser waere eine zweite
 * Fehlerquelle genau dort, wo Client und Server sich einig sein muessen.
 *
 * Alles, was nicht exakt `accepted` oder `declined` ist, ergibt `null` — ein
 * manipulierter oder fremder Wert gilt also nie als Zustimmung.
 */
export function readConsentFromCookieHeader(header: string | null | undefined): ConsentValue | null {
  if (typeof header !== 'string' || header === '') return null
  for (const part of header.split(';')) {
    const eq = part.indexOf('=')
    if (eq === -1) continue
    if (part.slice(0, eq).trim() !== CONSENT_COOKIE_NAME) continue
    const value = parseConsentValue(part.slice(eq + 1).trim())
    // Weitersuchen waere falsch: der erste Treffer ist der, den der Browser
    // auch selbst gewinnen laesst.
    return value
  }
  return null
}

/** Der `Set-Cookie`-taugliche String. Als reine Funktion direkt testbar. */
export function buildConsentCookie(value: ConsentValue, secure: boolean): string {
  const attrs = [
    `${CONSENT_COOKIE_NAME}=${value}`,
    'Path=/',
    'SameSite=Lax',
    `Max-Age=${CONSENT_COOKIE_MAX_AGE_SECONDS}`,
  ]
  if (secure) attrs.push('Secure')
  return attrs.join('; ')
}

/** Loeschform desselben Cookies — `Max-Age=0` bei identischem Pfad. */
export function buildConsentClearCookie(secure: boolean): string {
  const attrs = [`${CONSENT_COOKIE_NAME}=`, 'Path=/', 'SameSite=Lax', 'Max-Age=0']
  if (secure) attrs.push('Secure')
  return attrs.join('; ')
}

function isSecureContext(): boolean {
  return typeof location !== 'undefined' && location.protocol === 'https:'
}

export function readConsentCookie(): ConsentValue | null {
  if (typeof document === 'undefined') return null
  try {
    return readConsentFromCookieHeader(document.cookie)
  } catch {
    return null
  }
}

/** Nur aus der ausdruecklichen Accept-/Decline-Aktion aufrufen. */
export function writeConsentCookie(value: ConsentValue): void {
  if (typeof document === 'undefined') return
  try {
    document.cookie = buildConsentCookie(value, isSecureContext())
  } catch {
    // Nicht schreibbar (blockierte Storage-Zugriffe): der Store faellt dann auf
    // seinen Sitzungswert zurueck. Der Server misst mangels Cookie nicht — der
    // gewollte fail-closed Ausgang.
  }
}

/** Vollstaendiger Widerruf: die Entscheidung wird entfernt, nicht ueberschrieben. */
export function deleteConsentCookie(): void {
  if (typeof document === 'undefined') return
  try {
    document.cookie = buildConsentClearCookie(isSecureContext())
  } catch {
    // Siehe oben.
  }
}
