import Link from 'next/link'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Datenschutz — Crazy Babo Bazar',
  description: 'Datenschutzerklärung von Crazy Babo Bazar gemäß DSGVO',
}

export default function DatenschutzPage() {
  return (
    <div>
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#6B6560]">
            <Link href="/" className="hover:text-[#E85000] transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#9E9890]">Datenschutz</span>
          </div>
        </div>
      </div>

      <section>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <div className="mb-2 text-[#E85000] text-xs font-bold uppercase tracking-widest">Rechtliches</div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-5xl mb-3">
            Datenschutz
          </h1>
          <p className="text-[#6B6560] text-sm mb-12">Zuletzt aktualisiert: April 2026</p>

          <div className="space-y-10 text-[#9E9890]">

            {/* 1 */}
            <div className="border-l-2 border-[#E85000] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                1. Datenschutz auf einen Blick
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Die folgenden Hinweise geben einen einfachen Überblick darüber, was mit Ihren personenbezogenen Daten passiert, wenn Sie unsere Website besuchen. Personenbezogene Daten sind alle Daten, mit denen Sie persönlich identifiziert werden können.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#F0EDE8]">Cookies:</strong> Diese Website setzt keine eigenen Cookies. Externe Dienste (z. B. Amazon über Affiliate-Links) können eigene Cookies setzen, sobald Sie deren Links aufrufen. Darauf haben wir keinen Einfluss.
              </p>
            </div>

            {/* 2 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                2. Verantwortliche Stelle (Art. 4 Nr. 7 DSGVO)
              </h2>
              <p className="text-sm leading-relaxed">
                Verantwortlich für die Datenverarbeitung auf dieser Website ist:<br /><br />
                Roland Müller<br />
                c/o POSTFLEX PFX-391-821<br />
                Emsdettener Straße 10<br />
                48268 Greven<br /><br />
                E-Mail: crazybabobazar@gmail.com
              </p>
            </div>

            {/* 3 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                3. Hosting &amp; Server-Logs
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Diese Website wird auf einem externen Hosting-Server betrieben. Beim Aufruf der Website werden durch den Hosting-Anbieter automatisch folgende Daten in Server-Log-Dateien erfasst:
              </p>
              <ul className="text-sm space-y-1 mb-3">
                {[
                  'IP-Adresse des anfragenden Geräts',
                  'Datum und Uhrzeit des Zugriffs',
                  'Name und URL der abgerufenen Datei',
                  'Übertragene Datenmenge',
                  'Browsertyp und -version',
                  'Betriebssystem',
                  'Referrer-URL (zuvor besuchte Seite)',
                ].map((item) => (
                  <li key={item} className="flex items-start gap-2">
                    <span className="text-[#E85000] shrink-0 mt-0.5">▪</span>
                    {item}
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed">
                Diese Daten werden nicht zusammen mit anderen personenbezogenen Daten gespeichert. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an der Sicherheit und dem stabilen Betrieb der Website). Die Logs werden nach spätestens 7 Tagen automatisch gelöscht.
              </p>
            </div>

            {/* 4 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                4. Affiliate-Links (Amazon Partnerprogramm)
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Diese Website nimmt am Amazon EU-Partnerprogramm teil. Als Amazon-Partner verdienen wir an qualifizierten Käufen, die über unsere Links getätigt werden. Der Preis für Sie als Käufer bleibt dabei unverändert.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                Wenn Sie auf einen Affiliate-Link klicken und zu Amazon weitergeleitet werden, kann Amazon mittels Cookies und ähnlicher Technologien die Herkunft des Besuchs nachvollziehen und Ihnen personalisierte Werbung anzeigen. Amazon ist für diese Datenverarbeitung selbst verantwortlich. Rechtsgrundlage auf unserer Seite ist Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an der Refinanzierung des Angebots).
              </p>
              <p className="text-sm leading-relaxed">
                Informationen zum Datenschutz bei Amazon finden Sie unter:{' '}
                <a
                  href="https://www.amazon.de/gp/help/customer/display.html?nodeId=GX7NJQ4ZB8MHFRNJ"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#E85000] hover:text-[#E8321C] transition-colors underline underline-offset-2"
                >
                  Datenschutzerklärung von Amazon
                </a>
              </p>
            </div>

            {/* 5 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                5. Schriftarten (Google Fonts)
              </h2>
              <p className="text-sm leading-relaxed">
                Diese Website verwendet Google Fonts. Die Schriftarten werden beim ersten Aufruf vom Server des Hosting-Anbieters geladen — nicht von Google-Servern. Eine direkte Verbindung zu Google-Servern findet nicht statt, sodass keine Daten an Google übertragen werden.
              </p>
            </div>

            {/* 6 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                6. Ihre Rechte (Art. 15–22 DSGVO)
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Sie haben gegenüber uns folgende Rechte hinsichtlich der Sie betreffenden personenbezogenen Daten:
              </p>
              <ul className="text-sm space-y-2 mb-3">
                {[
                  'Recht auf Auskunft (Art. 15 DSGVO)',
                  'Recht auf Berichtigung (Art. 16 DSGVO)',
                  'Recht auf Löschung (Art. 17 DSGVO)',
                  'Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)',
                  'Recht auf Datenübertragbarkeit (Art. 20 DSGVO)',
                  'Recht auf Widerspruch gegen die Verarbeitung (Art. 21 DSGVO)',
                ].map((right) => (
                  <li key={right} className="flex items-start gap-2">
                    <span className="text-[#E85000] shrink-0 mt-0.5">▪</span>
                    {right}
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed">
                Zur Ausübung Ihrer Rechte wenden Sie sich bitte per E-Mail an: crazybabobazar@gmail.com
              </p>
            </div>

            {/* 7 */}
            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                7. Beschwerderecht bei der Aufsichtsbehörde (Art. 77 DSGVO)
              </h2>
              <p className="text-sm leading-relaxed">
                Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung Ihrer personenbezogenen Daten zu beschweren. Die zuständige Aufsichtsbehörde richtet sich nach Ihrem gewöhnlichen Aufenthaltsort, Ihrem Arbeitsplatz oder dem Ort des mutmaßlichen Verstoßes. Eine Liste der deutschen Aufsichtsbehörden finden Sie auf der Website des Bundesbeauftragten für den Datenschutz (bfdi.bund.de).
              </p>
            </div>

          </div>

          <div className="mt-16 pt-8 border-t border-[#333333]">
            <Link
              href="/impressum"
              className="text-[#E85000] text-sm hover:text-[#E8321C] transition-colors"
            >
              Zum Impressum →
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
