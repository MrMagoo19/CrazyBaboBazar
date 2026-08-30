import Link from 'next/link'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  // Ohne Markensuffix: `title.template` im Root-Layout haengt ihn an (lib/seo-title.ts).
  title: 'Datenschutz',
  description: 'Datenschutzerklärung von Crazy Babo Bazar gemäß DSGVO',
  alternates: { canonical: '/datenschutz' },
}

export default function DatenschutzPage() {
  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#0A0A0A]">Datenschutz</span>
          </div>
        </div>
      </div>

      <section>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <div className="mb-2 text-[#0A0A0A] text-xs font-bold uppercase tracking-widest">Rechtliches</div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-5xl mb-3">
            Datenschutz
          </h1>
          <p className="text-[#555] text-sm mb-12">Zuletzt aktualisiert: August 2026</p>

          <div className="space-y-10 text-[#555]">

            {/* 1 */}
            <div className="border-l-2 border-[#FFE500] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                1. Datenschutz auf einen Blick
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Die folgenden Hinweise geben einen einfachen Überblick darüber, was mit Ihren personenbezogenen Daten passiert, wenn Sie unsere Website besuchen. Personenbezogene Daten sind alle Daten, mit denen Sie persönlich identifiziert werden können.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#0A0A0A]">Cookies:</strong> Diese Website setzt keine Werbe- und keine Profiling-Cookies. Wir setzen genau <strong className="text-[#0A0A0A]">einen</strong> eigenen, funktionalen First-Party-Cookie — und nur dann, wenn Sie im Hinweisbanner eine Entscheidung treffen. Er speichert ausschließlich diese Entscheidung („akzeptiert“ oder „abgelehnt“), läuft nach 182 Tagen (rund sechs Monaten) ab und enthält keine Kennung, mit der Sie wiedererkannt werden könnten (Einzelheiten in Abschnitt 6). Externe Dienste (z. B. Amazon über Affiliate-Links) können eigene Cookies setzen, sobald Sie deren Links aufrufen. Darauf haben wir keinen Einfluss.
              </p>
              <p className="text-sm leading-relaxed mt-3">
                <strong className="text-[#0A0A0A]">Klick-Messung:</strong> Wenn Sie im Hinweisbanner „Akzeptieren“ wählen, speichern wir beim Klick auf einen Partnerlink einen pseudonymisierten, datensparsamen Zähl-Datensatz (siehe Abschnitt 6). Ohne Ihre Einwilligung funktioniert die Weiterleitung genauso, es wird dann aber nichts gespeichert.
              </p>
              <p className="text-sm leading-relaxed mt-3">
                <strong className="text-[#0A0A0A]">Widerruf:</strong> Ihre Entscheidung können Sie jederzeit mit einem Klick zurücknehmen — über die Schaltfläche <strong className="text-[#0A0A0A]">Datenschutz-Einstellungen</strong> im Fußbereich jeder Seite.
              </p>
            </div>

            {/* 2 */}
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
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
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
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
                    <span className="text-[#0A0A0A] shrink-0 mt-0.5">▪</span>
                    {item}
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed mb-3">
                Diese Daten werden nicht zusammen mit anderen personenbezogenen Daten gespeichert. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an der Sicherheit und dem stabilen Betrieb der Website). Die Logs werden nach spätestens 7 Tagen automatisch gelöscht.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#0A0A0A]">Hosting-Anbieter:</strong> Diese Website wird gehostet von Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, USA. Vercel verarbeitet Server-Log-Daten auf Basis von Standardvertragsklauseln (Art. 46 Abs. 2 lit. c DSGVO). Weitere Informationen: <a href="https://vercel.com/legal/privacy-policy" target="_blank" rel="noopener noreferrer" className="underline underline-offset-2 hover:text-[#0A0A0A]">vercel.com/legal/privacy-policy</a>
              </p>
            </div>

            {/* 4 */}
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                4. Affiliate-Links (Amazon Partnerprogramm)
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Diese Website nimmt am Amazon EU-Partnerprogramm teil. Als Amazon-Partner verdienen wir an qualifizierten Käufen, die über unsere Links getätigt werden. Der Preis für Sie als Käufer bleibt dabei unverändert.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                Wenn Sie auf einen Affiliate-Link klicken und zu Amazon weitergeleitet werden, kann Amazon mittels Cookies und ähnlicher Technologien die Herkunft des Besuchs nachvollziehen und Ihnen personalisierte Werbung anzeigen. Amazon ist für diese Datenverarbeitung selbst verantwortlich. Rechtsgrundlage auf unserer Seite ist Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an der Refinanzierung des Angebots).
              </p>
              <p className="text-sm leading-relaxed mb-3">
                Der Klick läuft technisch über unsere eigene Weiterleitungsadresse. Ob dabei ein pseudonymisierter Zähl-Datensatz gespeichert wird, entscheiden ausschließlich Sie über den Hinweis-Banner — Einzelheiten in Abschnitt 6.
              </p>
              <p className="text-sm leading-relaxed">
                Informationen zum Datenschutz bei Amazon finden Sie unter:{' '}
                <a
                  href="https://www.amazon.de/gp/help/customer/display.html?nodeId=GX7NJQ4ZB8MHFRNJ"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#0A0A0A] hover:underline transition-colors underline underline-offset-2"
                >
                  Datenschutzerklärung von Amazon
                </a>
              </p>
            </div>

            {/* 5 */}
            <div className="border-l-2 border-[#FFE500] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                5. Webanalyse (Vercel Analytics)
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Diese Website nutzt Vercel Analytics, einen datenschutzfreundlichen Analysedienst von Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, USA.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Was erfasst wird:</strong> Seitenaufrufe, Herkunftsland, Gerätetyp und Referrer-URL — ausschließlich in aggregierter, anonymisierter Form. Es werden <strong className="text-[#0A0A0A]">keine Cookies gesetzt</strong>, keine IP-Adressen dauerhaft gespeichert und keine persönlichen Profile erstellt.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Rechtsgrundlage:</strong> Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an der anonymen Auswertung des Nutzerverhaltens zur Verbesserung des Angebots). Da keine personenbezogenen Daten verarbeitet werden, ist keine Einwilligung erforderlich.
              </p>
              <p className="text-sm leading-relaxed">
                Weitere Informationen:{' '}
                <a href="https://vercel.com/docs/analytics/privacy-policy" target="_blank" rel="noopener noreferrer" className="underline underline-offset-2 hover:text-[#0A0A0A]">
                  vercel.com/docs/analytics/privacy-policy
                </a>
              </p>
            </div>

            {/* 6 */}
            <div className="border-l-2 border-[#FFE500] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                6. Klick-Messung bei Partnerlinks (nur mit Einwilligung)
              </h2>
              <p className="text-sm leading-relaxed mb-3">
                Partnerlinks auf dieser Website führen zunächst über unsere eigene
                Weiterleitungsadresse <span className="text-[#0A0A0A]">/api/click/&lt;produkt&gt;</span> und
                erst von dort zum Partnershop. Die Zieladresse wird ausschließlich auf unserem Server
                aus den veröffentlichten Produktdaten ermittelt.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Ohne Einwilligung:</strong> Die Weiterleitung
                funktioniert unverändert. Es wird <strong className="text-[#0A0A0A]">kein</strong> Datensatz
                gespeichert und <strong className="text-[#0A0A0A]">keine</strong> Kennung vergeben.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Mit Einwilligung</strong> („Akzeptieren“ im Hinweisbanner)
                speichern wir pro Klick genau diese Angaben — datensparsam und pseudonymisiert, also
                ohne Ihren Namen, aber mit einer zufälligen, kurzlebigen Sitzungskennung:
              </p>
              <ul className="text-sm space-y-1 mb-3">
                {[
                  'Produkt-Kennung (Slug) des angeklickten Produkts',
                  'Partnershop (derzeit ausschließlich Amazon)',
                  'Seitenpfad, von dem der Klick ausging — ohne Suchbegriffe und ohne sonstige Parameter',
                  'grobe Gerätekategorie (Mobil, Tablet, Desktop oder unbekannt)',
                  'zufällige Sitzungskennung, die nur bis zum Schließen des Browser-Tabs gilt',
                  'Zeitpunkt des Klicks',
                ].map((item) => (
                  <li key={item} className="flex items-start gap-2">
                    <span className="text-[#0A0A0A] shrink-0 mt-0.5">▪</span>
                    {item}
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Ausdrücklich nicht gespeichert werden:</strong> Ihre
                IP-Adresse (auch nicht als Hashwert), Ihre vollständige Browserkennung (User-Agent), die
                vollständige Herkunfts-URL, Suchbegriffe oder sonstige Adressparameter. Es werden keine
                Profile gebildet und keine Daten mit anderen Quellen zusammengeführt.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Datenbankdienst und Empfänger:</strong> Für die
                Speicherung der in diesem Abschnitt genannten Zähl-Datensätze nutzen wir Supabase als
                Datenbank- und Hosting-Dienstleister. Vertragspartner und Auftragsverarbeiter ist Supabase
                Pte. Ltd., 65 Chulia Street #38-02/03, OCBC Centre, Singapore 049513. Supabase verarbeitet
                diese Daten in unserem Auftrag auf Grundlage der aktuellen Auftragsverarbeitungsvereinbarung
                (DPA) von Supabase. An Supabase werden nur die oben ausdrücklich aufgeführten Angaben
                übermittelt; insbesondere erhält Supabase von uns für diese Messung weder Ihre IP-Adresse
                noch Ihre vollständige Browserkennung. Der primäre Speicherort unseres Supabase-Projekts ist
                die Region West EU (Ireland) (eu-west-1).
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Drittlandübermittlung:</strong> Auch bei einem
                Projektspeicherort in der EU setzt Supabase für einzelne Leistungen weitere
                Unterauftragsverarbeiter ein — laut der von Supabase veröffentlichten Liste etwa Amazon Web
                Services, Inc. für das Hosting und Supabase, Inc. für den Support. Dadurch kann es zu einer
                Verarbeitung in Drittländern, insbesondere den USA oder Singapur, kommen — Singapur
                deshalb, weil Supabase Pte. Ltd. dort als Vertragspartei und Datenimporteurin sitzt.
                Der primäre Speicherort unseres Supabase-Projekts in der EU (siehe oben) bleibt davon
                unberührt. Supabase nennt für solche
                Übermittlungen die Standardvertragsklauseln der Europäischen Kommission (Modul 2:
                Verantwortlicher an Auftragsverarbeiter) als Übermittlungsmechanismus gemäß Art. 46 Abs. 2
                lit. c DSGVO. Die aktuelle Auftragsverarbeitungsvereinbarung (DPA) und die aktuelle Liste der
                Unterauftragsverarbeiter finden Sie unter:{' '}
                <a
                  href="https://supabase.com/legal/customer-resources/data-processing-addendum"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline underline-offset-2 hover:text-[#0A0A0A]"
                >
                  Auftragsverarbeitungsvereinbarung (DPA) von Supabase
                </a>{' '}
                und{' '}
                <a
                  href="https://supabase.com/legal/customer-resources/subprocessor-list"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline underline-offset-2 hover:text-[#0A0A0A]"
                >
                  Liste der Unterauftragsverarbeiter von Supabase
                </a>. Allgemeine Informationen zum Datenschutz bei Supabase (kein Ersatz für das DPA) finden
                Sie in der{' '}
                <a
                  href="https://supabase.com/privacy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline underline-offset-2 hover:text-[#0A0A0A]"
                >
                  Datenschutzerklärung von Supabase
                </a>.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Wie Ihre Entscheidung zu uns gelangt:</strong> Die
                Messung findet auf unserem Server statt. Damit dieser Ihre Einwilligung überhaupt prüfen
                kann, speichert Ihre Entscheidung im Hinweisbanner einen funktionalen First-Party-Cookie
                unter dem Namen{' '}
                <span className="text-[#0A0A0A]">cbb_consent_clickout_v2</span> (Attribute:{' '}
                <span className="text-[#0A0A0A]">SameSite=Lax</span>,{' '}
                <span className="text-[#0A0A0A]">Secure</span> (auf HTTPS-Verbindungen),{' '}
                <span className="text-[#0A0A0A]">Path=/</span>, Laufzeit genau 182 Tage, also rund
                sechs Monate). Sein Inhalt ist
                ausschließlich das Wort <span className="text-[#0A0A0A]">accepted</span> oder{' '}
                <span className="text-[#0A0A0A]">declined</span>. Er enthält{' '}
                <strong className="text-[#0A0A0A]">keine</strong> Kennung, keine Nummer und keinen
                Zeitstempel und dient nicht der Wiedererkennung. Gesetzt wird er nur durch Ihre
                ausdrückliche Auswahl — nicht schon beim bloßen Aufruf der Seite.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Speicherort der Kennung:</strong> Die zufällige
                Sitzungskennung liegt im <span className="text-[#0A0A0A]">sessionStorage</span> Ihres
                Browsers und steht <strong className="text-[#0A0A0A]">nie</strong> in einem Cookie — auch
                nicht in dem oben genannten. Sie entsteht erst, wenn Sie nach Ihrer Einwilligung
                tatsächlich einen Partnerlink anklicken, wird beim Schließen des Tabs gelöscht und gilt
                nicht tab- oder geräteübergreifend.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Ohne beides passiert nichts:</strong> Unser Server
                speichert einen Klick nur, wenn der Consent-Cookie „akzeptiert“ trägt{' '}
                <em>und</em> eine gültige Sitzungskennung mitgeschickt wird. Ein Link, in den jemand von
                außen eine erfundene Kennung schreibt, erzeugt keinen Datensatz.
              </p>
              <p className="text-sm leading-relaxed mb-3">
                <strong className="text-[#0A0A0A]">Rechtsgrundlage:</strong> Art. 6 Abs. 1 lit. a DSGVO
                (Einwilligung) sowie § 25 Abs. 1 TDDDG für die Speicherung im Endgerät. Die Einwilligung ist
                freiwillig und <strong className="text-[#0A0A0A]">jederzeit</strong> mit Wirkung für die
                Zukunft widerrufbar — so einfach, wie sie erteilt wurde: Klicken Sie im Fußbereich jeder
                Seite auf <strong className="text-[#0A0A0A]">Datenschutz-Einstellungen</strong>. Das löscht
                den Entscheidungs-Cookie und die Sitzungskennung sofort, und der Hinweisbanner erscheint
                erneut, sodass Sie neu entscheiden können. Alternativ können Sie im Hinweisbanner
                „Ablehnen“ wählen oder die Websitedaten dieser Seite (Cookie und sessionStorage) in Ihren
                Browsereinstellungen löschen — beides ist möglich, aber nicht der einzige Weg.
              </p>
              <p className="text-sm leading-relaxed">
                <strong className="text-[#0A0A0A]">Speicherdauer:</strong> Die Zähl-Datensätze werden
                spätestens nach 12 Monaten gelöscht. Sie enthalten keinen Namen und keine Kontaktdaten und
                sind für uns keiner Person zuzuordnen; ein Auskunftsersuchen zu einem einzelnen Datensatz
                können wir deshalb regelmäßig nicht beantworten (Art. 11 DSGVO).
              </p>
            </div>

            {/* 7 */}
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                7. Schriftarten (Google Fonts)
              </h2>
              <p className="text-sm leading-relaxed">
                Diese Website verwendet Google Fonts. Die Schriftarten werden beim ersten Aufruf vom Server des Hosting-Anbieters geladen — nicht von Google-Servern. Eine direkte Verbindung zu Google-Servern findet nicht statt, sodass keine Daten an Google übertragen werden.
              </p>
            </div>

            {/* 8 */}
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                8. Ihre Rechte (Art. 15–22 DSGVO)
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
                    <span className="text-[#0A0A0A] shrink-0 mt-0.5">▪</span>
                    {right}
                  </li>
                ))}
              </ul>
              <p className="text-sm leading-relaxed">
                Zur Ausübung Ihrer Rechte wenden Sie sich bitte per E-Mail an: crazybabobazar@gmail.com
              </p>
            </div>

            {/* 9 */}
            <div className="border-l-2 border-[#E0E0E0] pl-6">
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A] mb-3">
                9. Beschwerderecht bei der Aufsichtsbehörde (Art. 77 DSGVO)
              </h2>
              <p className="text-sm leading-relaxed">
                Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung Ihrer personenbezogenen Daten zu beschweren. Die zuständige Aufsichtsbehörde richtet sich nach Ihrem gewöhnlichen Aufenthaltsort, Ihrem Arbeitsplatz oder dem Ort des mutmaßlichen Verstoßes. Eine Liste der deutschen Aufsichtsbehörden finden Sie auf der Website des Bundesbeauftragten für den Datenschutz (bfdi.bund.de).
              </p>
            </div>

          </div>

          <div className="mt-16 pt-8 border-t border-[#E0E0E0]">
            <Link
              href="/impressum"
              className="text-[#0A0A0A] text-sm hover:underline transition-colors"
            >
              Zum Impressum →
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
