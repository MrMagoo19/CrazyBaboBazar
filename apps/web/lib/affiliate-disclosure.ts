/**
 * Sichtbare Affiliate-Kennzeichnung — ein Wortlaut fuer alle direkten CTAs.
 *
 * WARUM EINE EIGENE DATEI UND NICHT `lib/affiliate.ts`:
 * Jene Datei haelt bewusst reinen ASCII-Quelltext (siehe die Begruendung bei
 * `hasControlChar` dort). Der Kennzeichnungstext braucht Mittelpunkt und
 * Geviertstrich und gehoert deshalb nicht hinein. Ausserdem ist das hier eine
 * reine Darstellungsfrage, waehrend `lib/affiliate.ts` die Sicherheits- und
 * URL-Schicht ist.
 *
 * WARUM DIE KENNZEICHNUNG NICHT IN `AffiliateLink` STECKT:
 * Die Aufrufstellen haben voellig verschiedene Layouts — Kartenraster,
 * Info-Spalte, fixe Mobil-Leiste, Hover-Overlay. Eine automatisch eingefuegte
 * Zeile wuerde dort mal die Kartenhoehe, mal die Hoehe der fixen Leiste
 * veraendern, also genau das Designsystem verschieben, das erhalten bleiben
 * soll. Die Komponente liefert deshalb weiterhin nur den Link; die
 * Kennzeichnung wird je Flaeche bewusst gesetzt. Gemeinsam ist ausschliesslich
 * der Wortlaut — und der steht hier.
 *
 * WARUM `rel="sponsored"` NICHT REICHT:
 * Das Attribut richtet sich an Suchmaschinen, nicht an Menschen. Wer die Seite
 * sieht oder hoert, erfaehrt daraus nichts. Die kommerzielle Natur muss
 * unmittelbar am CTA stehen — sichtbar UND im `aria-label`, weil ein
 * `aria-label` den Linktext fuer Screenreader ersetzt und ein daneben
 * stehender Hinweis damit nicht mitgelesen wird.
 */

/** Sichtbarer Text unmittelbar im oder direkt neben dem CTA. */
export const AFFILIATE_DISCLOSURE = 'Anzeige · Affiliate-Link'

/** Praefix jedes CTA-`aria-label`, gefolgt vom Merchant-/Produkttext. */
export const AFFILIATE_ARIA_PREFIX = `${AFFILIATE_DISCLOSURE} — `

/**
 * `aria-label` eines Affiliate-CTA: erst die kommerzielle Natur, dann der
 * bisherige Merchant-/Produkttext.
 */
export function affiliateAriaLabel(merchantAndProduct: string): string {
  return `${AFFILIATE_ARIA_PREFIX}${merchantAndProduct}`
}
