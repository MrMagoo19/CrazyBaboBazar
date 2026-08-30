'use client'

/**
 * Historischer Name des Cookie-Hinweises — jetzt nur noch ein Alias.
 *
 * Diese Datei enthielt bis zuletzt einen ZWEITEN, eigenen Consent-Mechanismus
 * ueber `createConsentStore('cbb-cookie-consent')` im localStorage. Der war
 * weder mit dem Server noch mit den Affiliate-Links verbunden: der Server liest
 * ausschliesslich den First-Party-Cookie aus `lib/consent-cookie.ts`, und die
 * Links haengen an der Singleton-Instanz aus `lib/consent.ts`. Ein Klick auf
 * „Verstanden" haette hier also eine Zustimmung angezeigt, die nirgends gewirkt
 * haette — ein veraltetes Consent-System im Repo ist genau die Art Altlast, die
 * spaeter versehentlich wieder eingebunden wird.
 *
 * Der Export bleibt erhalten, damit kein oeffentlicher Name ersatzlos
 * verschwindet; er zeigt jetzt auf den einen echten Hinweis.
 */
export { CookieConsent as CookieBanner } from './cookie-consent'
