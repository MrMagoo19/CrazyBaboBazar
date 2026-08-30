'use client'

/**
 * WIDERRUF DER EINWILLIGUNG — jederzeit erreichbar (P1, Consent v2).
 *
 * WARUM ES DIESEN KNOPF GIBT:
 * Der Hinweisbanner verschwindet, sobald eine Entscheidung gefallen ist. Ohne
 * einen dauerhaft erreichbaren Widerruf waere die einzige Rueckfahrkarte das
 * Loeschen der Websitedaten in den Browsereinstellungen — das ist kein
 * gleichwertig einfacher Widerruf im Sinne von Art. 7 Abs. 3 DSGVO.
 *
 * WAS DER KLICK TUT: `consentStore.clearConsent()` und sonst nichts. Der Store
 * loescht den Entscheidungs-Cookie, entfernt die Sitzungskennung aus dem
 * sessionStorage und benachrichtigt seine Abonnenten. Der Banner erscheint
 * dadurch sofort wieder — ohne Reload, weil er ueber `useSyncExternalStore` an
 * derselben Store-Instanz haengt.
 *
 * Bewusst ein natives `<button>`: damit ist der Widerruf ohne Zusatzarbeit per
 * Tastatur erreichbar und wird von Screenreadern als Schaltflaeche angesagt.
 * Ein `<div onClick>` waere hier ein Barrierefreiheits-Regress.
 */

import { consentStore } from '@/lib/consent'

export function ConsentSettingsButton() {
  return (
    <button
      type="button"
      data-testid="consent-settings-button"
      onClick={() => consentStore.clearConsent()}
      className="text-left text-sm text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors font-medium"
    >
      Datenschutz-Einstellungen
    </button>
  )
}
