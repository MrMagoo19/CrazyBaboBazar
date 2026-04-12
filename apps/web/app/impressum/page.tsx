import Link from 'next/link'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Impressum — Crazy Babo Bazar',
  description: 'Angaben gemäß § 5 TMG',
}

export default function ImpressumPage() {
  return (
    <div>
      <div className="border-b border-[#333333]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#6B6560]">
            <Link href="/" className="hover:text-[#E85000] transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#9E9890]">Impressum</span>
          </div>
        </div>
      </div>

      <section>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <div className="mb-2 text-[#E85000] text-xs font-bold uppercase tracking-widest">Rechtliches</div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-5xl mb-12">
            Impressum
          </h1>

          <div className="space-y-10 text-[#9E9890]">
            <div className="border-l-2 border-[#E85000] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Angaben gemäß § 5 TMG
              </h2>
              <p className="text-sm leading-loose">
                Max Mustermann<br />
                Crazy Babo Bazar<br />
                Musterstraße 1<br />
                12345 Musterstadt<br />
                Deutschland
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Kontakt
              </h2>
              <p className="text-sm leading-loose">
                E-Mail: hallo@crazybabobazar.de<br />
                (Keine postalischen Anfragen)
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Umsatzsteuer-ID
              </h2>
              <p className="text-sm leading-relaxed">
                Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz:<br />
                DE 000 000 000
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Affiliate-Hinweis
              </h2>
              <p className="text-sm leading-relaxed">
                Diese Website enthält Affiliate-Links, insbesondere Links zum Amazon-Partnerprogramm. Als Amazon-Partner verdiene ich an qualifizierten Verkäufen. Der Preis für Käufer bleibt dabei unverändert.
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Haftungsausschluss
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#F0EDE8]">Haftung für Inhalte:</strong> Die Inhalte unserer Seiten wurden mit größter Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#F0EDE8]">Haftung für Links:</strong> Unser Angebot enthält Links zu externen Webseiten Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen.
              </p>
            </div>

            <div className="border-l-2 border-[#333333] pl-6">
              <h2 className="font-[family-name:var(--font-display)] font-bold text-lg text-[#F0EDE8] mb-3">
                Urheberrecht
              </h2>
              <p className="text-sm leading-relaxed">
                Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors.
              </p>
            </div>
          </div>

          <div className="mt-16 pt-8 border-t border-[#333333]">
            <Link
              href="/datenschutz"
              className="text-[#E85000] text-sm hover:text-[#E8321C] transition-colors"
            >
              Zur Datenschutzerklärung →
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
