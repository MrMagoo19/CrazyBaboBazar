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
          <p className="text-[#6B6560] text-sm mb-12">Zuletzt aktualisiert: April 2025</p>

          <div className="space-y-10 text-[#9E9890]">
            <div className="border-l-2 border-[#E85000] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                1. Datenschutz auf einen Blick
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Die folgenden Hinweise geben einen einfachen Überblick darüber, was mit Ihren personenbezogenen Daten passiert, wenn Sie unsere Website besuchen.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#F0EDE8]">Datenerfassung auf dieser Website:</strong> Wir erfassen keine personenbezogenen Daten, es sei denn, Sie stellen uns diese freiwillig zur Verfügung. Technisch notwendige Daten (Server-Logs) werden automatisch beim Besuch unserer Website erfasst.
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                2. Verantwortliche Stelle
              </h2>
              <p className="text-sm leading-relaxed">
                Verantwortlich für die Datenverarbeitung auf dieser Website ist:<br /><br />
                Max Mustermann<br />
                Crazy Babo Bazar<br />
                Musterstraße 1, 12345 Musterstadt<br />
                E-Mail: hallo@crazybabobazar.de
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                3. Affiliate-Links (Amazon Partnerprogramm)
              </h2>
              <p className="text-sm leading-relaxed">
                Diese Website nimmt am Amazon EU-Partnerprogramm teil. Amazon setzt Cookies ein, um die Herkunft von Bestellungen nachvollziehen zu können. Dabei kann Amazon erkennen, dass Sie den Partnerlink auf unserer Website geklickt haben.
              </p>
              <p className="text-sm leading-relaxed mt-3">
                Amazon ist Verantwortlicher für die dabei erhobenen Daten. Informationen zum Datenschutz bei Amazon finden Sie unter:{' '}
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

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                4. Google Fonts
              </h2>
              <p className="text-sm leading-relaxed">
                Diese Website nutzt Google Fonts. Beim Laden der Seite werden Schriftarten von Google-Servern geladen. Dabei kann Google Ihre IP-Adresse erfassen. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an einheitlicher Darstellung).
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                5. Ihre Rechte
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Sie haben folgende Rechte bezüglich Ihrer Daten:
              </p>
              <ul className="text-sm space-y-2">
                {[
                  'Recht auf Auskunft (Art. 15 DSGVO)',
                  'Recht auf Berichtigung (Art. 16 DSGVO)',
                  'Recht auf Löschung (Art. 17 DSGVO)',
                  'Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)',
                  'Recht auf Widerspruch (Art. 21 DSGVO)',
                  'Recht auf Datenübertragbarkeit (Art. 20 DSGVO)',
                ].map((right) => (
                  <li key={right} className="flex items-start gap-2">
                    <span className="text-[#E85000] shrink-0 mt-0.5">▪</span>
                    {right}
                  </li>
                ))}
              </ul>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                6. Beschwerderecht
              </h2>
              <p className="text-sm leading-relaxed">
                Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung Ihrer Daten zu beschweren. Die zuständige Aufsichtsbehörde richtet sich nach Ihrem Wohnort.
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
