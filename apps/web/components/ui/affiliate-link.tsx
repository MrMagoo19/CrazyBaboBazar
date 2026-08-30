'use client'

import { useState, useSyncExternalStore } from 'react'
import { usePathname } from 'next/navigation'
import type { CSSProperties, ReactNode, SyntheticEvent } from 'react'

import { buildClickOutHref, merchantCtaLabel, resolveMerchant } from '@/lib/affiliate'
import { getOrCreateClickSessionId } from '@/lib/click-session'
import { consentStore } from '@/lib/consent'
import type { ConsentSnapshot } from '@/lib/consent-store'

/**
 * Der eine Affiliate-CTA der App.
 *
 * WAS DIESE KOMPONENTE GARANTIERT:
 *   * Das `href` zeigt IMMER auf die interne Route `/api/click/<slug>` — auch
 *     im servergerenderten HTML und auch ohne JavaScript. Die eigentliche
 *     Ziel-URL steht nirgends im Markup; sie wird erst serverseitig aus den
 *     veroeffentlichten Produktdaten aufgeloest.
 *   * Ohne Einwilligung fehlt der Parameter `cs`. Der Server speichert dann
 *     keinen Event und leitet trotzdem weiter.
 *   * Die Kennzeichnung bleibt erhalten: `rel="sponsored nofollow noopener
 *     noreferrer"` und `target="_blank"` wie bisher.
 *
 * `affiliateUrl` wird ausschliesslich fuer die Beschriftung ausgewertet
 * (Merchant-Erkennung). Sie landet bewusst NICHT im `href`.
 *
 * WARUM DIE KENNUNG ERST BEI DER AKTIVIERUNG ENTSTEHT:
 * Die Kennung anzulegen heisst, in den `sessionStorage` zu schreiben. Das ist
 * ein Seiteneffekt und gehoert damit weder ins Rendern noch in einen Effekt,
 * der beim Mounten `setState` aufruft (React 19: `set-state-in-effect`). Sie
 * entsteht deshalb genau dort, wo sie gebraucht wird — im Ereignis-Handler der
 * tatsaechlichen Aktivierung (Zeiger, Fokus, Klick). Zwei erwuenschte
 * Nebenwirkungen:
 *   * Das erste `href` ist auf Server und Client identisch (nie `cs`), also
 *     hydrierungsstabil.
 *   * Wer nie einen Partnerlink anfasst, bekommt auch nie eine Kennung —
 *     Datenminimierung ohne Zusatzcode.
 * `href` bleibt in jedem Zustand die interne Route: ohne JavaScript, ohne
 * Einwilligung und mitten im Handler funktioniert die Weiterleitung.
 *
 * MESSUNG ABSCHALTBAR (`measurementEnabled={false}`):
 * Fuer Flaechen, die keine echten Klick-outs erzeugen duerfen — etwa die
 * `noindex`-Design-Werkbank unter `/design-preview`. Der Link bleibt dann
 * trotzdem IMMER die interne Route (das Partnerziel steht also auch dort nie
 * im Markup), es entsteht aber selbst bei erteilter Einwilligung nie eine
 * Kennung: kein `cs` im `href` und kein Schreiben in den `sessionStorage`.
 * Ohne `cs` speichert der Server nichts und leitet nur weiter.
 */
export type AffiliateLinkProps = {
  slug: string
  /** Nur zur Merchant-Erkennung fuer die Beschriftung. Nie das Linkziel. */
  affiliateUrl?: string | null
  children?: ReactNode
  className?: string
  style?: CSSProperties
  /** Ueberschreibt den per `usePathname` ermittelten Herkunftspfad. */
  sourcePath?: string | null
  /** Zusatz fuer Screenreader, z. B. der Produktname. */
  ariaLabel?: string
  title?: string
  /**
   * `false` schaltet die Klick-Messung fuer diesen Link vollstaendig ab: nie
   * eine Kennung, nie ein `cs`-Parameter — auch bei erteilter Einwilligung
   * nicht. Das `href` bleibt die interne Route. Default: `true`.
   */
  measurementEnabled?: boolean
}

export function AffiliateLink({
  slug,
  affiliateUrl,
  children,
  className,
  style,
  sourcePath,
  ariaLabel,
  title,
  measurementEnabled = true,
}: AffiliateLinkProps) {
  const consent = useSyncExternalStore<ConsentSnapshot>(
    consentStore.subscribe,
    consentStore.getSnapshot,
    consentStore.getServerSnapshot
  )

  // Wird ausschliesslich aus Ereignis-Handlern gesetzt — nie im Render, nie in
  // einem Effekt.
  const [sessionId, setSessionId] = useState<string | null>(null)

  // `usePathname` liefert auch beim Serverrendern den echten Pfad, das `href`
  // ist also schon im ausgelieferten HTML vollstaendig.
  const pathname = usePathname()
  const from = sourcePath === undefined ? pathname : sourcePath

  // Ein widerrufener Consent entwertet eine bereits geholte Kennung sofort und
  // rein rechnerisch — kein Aufraeum-Effekt noetig.
  // Abgeschaltete Messung wirkt hier wie ein dauerhaft fehlender Consent — das
  // `href` kann also gar nicht erst dekoriert werden.
  const activeSessionId = measurementEnabled && consent === 'accepted' ? sessionId : null
  const href = buildClickOutHref(slug, from, activeSessionId)

  /**
   * Haengt die Kennung an, sobald der Besucher den Link tatsaechlich anfasst.
   *
   * Zwei Wege, mit Absicht beide:
   *   1. `setSessionId` haelt den Wert fuer alle folgenden Renderdurchlaeufe.
   *   2. Das direkte `setAttribute` wirkt SOFORT — auch wenn React vor der
   *      eigentlichen Navigation nicht mehr neu rendert. Ohne diesen Schritt
   *      koennte der allererste Klick noch mit dem alten `href` losfahren.
   * Das ist kein Render-Seiteneffekt: es passiert im Handler an genau dem
   * Element, das der Besucher gerade aktiviert.
   *
   * Die Autoritaet ist immer der `sessionStorage`, nie der State: nach einem
   * Widerruf hat der Store die Kennung dort geloescht, waehrend `sessionId`
   * noch den alten Wert traegt. Wuerde der State gewinnen, verbaende ein
   * spaeteres erneutes Einwilligen die alte mit der neuen Sitzung — genau die
   * Wiedererkennung, die hier nicht stattfinden soll.
   */
  const attachSessionId = (event: SyntheticEvent<HTMLAnchorElement>) => {
    // Zuerst: ohne Messung passiert hier gar nichts — insbesondere entsteht
    // keine Kennung im `sessionStorage`, die es sonst nur nicht in den Link
    // schaffen wuerde.
    if (!measurementEnabled) return
    if (consent !== 'accepted') return
    const id = getOrCreateClickSessionId()
    // Kein Web-Crypto oder kein sessionStorage: dann bleibt es beim Link ohne
    // Kennung. Der Klick funktioniert, er wird nur nicht gezaehlt.
    if (!id) return
    if (id !== sessionId) setSessionId(id)
    const decorated = buildClickOutHref(slug, from, id)
    const anchor = event.currentTarget
    if (anchor.getAttribute('href') !== decorated) anchor.setAttribute('href', decorated)
  }

  const merchant = resolveMerchant(affiliateUrl)

  return (
    <a
      href={href}
      target="_blank"
      rel="sponsored nofollow noopener noreferrer"
      // Unser eigener Endpunkt braucht den Referrer nicht: die Herkunft steht
      // bereits sanitisiert im `from`-Parameter.
      referrerPolicy="no-referrer"
      className={className}
      style={style}
      aria-label={ariaLabel}
      title={title}
      data-affiliate-slug={slug}
      // Vier Ausloeser, alle idempotent: Zeiger deckt Maus, Touch, Mittel- und
      // Rechtsklick ab, `onMouseDown` faengt Umgebungen ohne Pointer-Events,
      // Fokus deckt die Tastatur ab (Enter setzt Fokus voraus) und `onClick`
      // ist die letzte Rueckfalllinie. Mehrfaches Ausloesen kostet nichts —
      // der zweite Aufruf findet Kennung und `href` bereits vor.
      onPointerDown={attachSessionId}
      onMouseDown={attachSessionId}
      onFocus={attachSessionId}
      onClick={attachSessionId}
    >
      {children ?? merchantCtaLabel(merchant)}
    </a>
  )
}
