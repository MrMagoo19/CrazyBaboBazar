import type { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Über CrazyBabo Bazar — Wer steckt hinter dem Bazar?',
  description: 'CrazyBabo Bazar ist kein generischer Affiliate-Shop. Wir sind ein handverlesenes Empfehlungsportal für kuriose, lustige und kaufstarke Produkte im DACH-Raum.',
  openGraph: { images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }] },
}

const values = [
  {
    label: 'Handverlesen',
    text: 'Kein Algorithmus entscheidet was hier landet. Jedes Produkt wird manuell geprüft — auf Qualität, Kuriosität und echten Mehrwert. Schlechte Produkte fliegen raus, egal wie hoch die Provision ist.',
  },
  {
    label: 'Ehrlich',
    text: 'Wir verdienen Geld wenn du über unsere Links kaufst. Das steht überall sichtbar dabei. Keine versteckten Deals, keine gesponserten Platzierungen die als Empfehlung getarnt sind.',
  },
  {
    label: 'Kurios',
    text: 'Der DACH-Raum braucht keinen weiteren Mainstream-Shop. CrazyBabo Bazar ist für Produkte die überraschen, zum Lachen bringen oder einfach besser sind als erwartet.',
  },
  {
    label: 'Direkt',
    text: 'Keine Listicles mit 47 Punkten. Keine aufgeblähten SEO-Texte. Wir sagen was das Produkt taugt — kurz, direkt, mit Haltung.',
  },
]

const personas = [
  { slug: '/babos', label: 'Babos', desc: 'Gadgets, Gaming & Tech für echte Kerle', emoji: '⚡' },
  { slug: '/queens', label: 'Queens', desc: 'Küche, Beauty & Lifestyle mit Stil', emoji: '👑' },
  { slug: '/miniboss', label: 'Miniboss', desc: 'Spielzeug & Spaß für kleine Chefs', emoji: '⭐' },
  { slug: '/wellness', label: 'Wellness', desc: 'Fitness, Pflege & Outdoor', emoji: '🌿' },
]

export default function UeberUnsPage() {
  return (
    <div>
      {/* Breadcrumb */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            <span>→</span>
            <span className="text-[#0A0A0A]">Über uns</span>
          </div>
        </div>
      </div>

      {/* Hero */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#0A0A0A]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-20">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-6 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            Wer steckt dahinter?
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-black text-4xl sm:text-6xl text-white leading-none mb-8" style={{ letterSpacing: '-0.03em' }}>
            Kein Shop.<br />
            <span style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '0 8px' }}>Ein Standpunkt.</span>
          </h1>
          <p className="text-[#AAA] text-lg leading-relaxed max-w-2xl">
            CrazyBabo Bazar ist kein automatisch befüllter Affiliate-Shop. Es ist ein Empfehlungsportal mit Haltung — kuratiert von einem Babo der weiß was er will, und nicht empfiehlt was er nicht selbst kaufen würde.
          </p>
        </div>
      </section>

      {/* Story */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-start">
            <div>
              <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] mb-6 leading-tight">
                Wie der Bazar entstand
              </h2>
              <div className="space-y-4 text-[#555] text-base leading-relaxed">
                <p>
                  Es fing mit einer simplen Frustration an: Wenn man online nach Geschenkideen oder kuriosem Zeug sucht, landet man entweder auf generischen Listen mit 50 mittelmäßigen Produkten — oder auf Seiten die offensichtlich nur existieren um Klicks zu generieren.
                </p>
                <p>
                  CrazyBabo Bazar ist die Antwort darauf. Eine Seite die auswählt, statt aufzuzählen. Die erklärt warum ein Produkt gut ist, statt nur Features aufzulisten. Die offen sagt was sie nervt und was begeistert.
                </p>
                <p>
                  Der Name ist Programm: Crazy für den Mut zu kuriosem, Babo für den Anspruch an Qualität, Bazar für die Vielfalt. DACH-Raum fokussiert, Amazon-verlinkt, handverlesen.
                </p>
              </div>
            </div>

            <div className="space-y-4">
              <div style={{ backgroundColor: '#FFE500', border: '2px solid #0A0A0A', padding: '24px' }}>
                <div className="font-[family-name:var(--font-mono)] font-black text-xs uppercase tracking-widest text-[#0A0A0A] mb-3">In Zahlen</div>
                <div className="space-y-3">
                  {[
                    ['100+', 'handverlesene Produkte'],
                    ['4', 'Personas — Babos, Queens, Miniboss, Wellness'],
                    ['0', 'automatisch hinzugefügte Produkte'],
                    ['1', 'Anspruch: nur empfehlen was überzeugt'],
                  ].map(([num, label]) => (
                    <div key={label} className="flex items-baseline gap-3">
                      <span className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] leading-none">{num}</span>
                      <span className="text-sm text-[#333] font-medium">{label}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Values */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] mb-10 leading-tight">
            Wofür wir stehen
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {values.map((v) => (
              <div key={v.label} style={{ backgroundColor: '#FFFFFF', border: '2px solid #0A0A0A', padding: '24px' }}>
                <div
                  className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest mb-3 inline-block"
                  style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 8px' }}
                >
                  {v.label}
                </div>
                <p className="text-sm text-[#555] leading-relaxed">{v.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Personas */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-16">
          <h2 className="font-[family-name:var(--font-display)] font-black text-3xl text-[#0A0A0A] mb-4 leading-tight">
            Für wen ist der Bazar?
          </h2>
          <p className="text-[#555] text-base mb-10 max-w-xl">
            Wir denken in Personas — nicht in Demographics. Jeder Mensch hat mehrere Seiten. Vier davon haben wir kuratiert.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {personas.map((p) => (
              <Link
                key={p.slug}
                href={p.slug}
                className="flex items-center gap-4 p-5 border-2 border-[#0A0A0A] hover:bg-[#FFE500] transition-colors group"
              >
                <span className="text-3xl">{p.emoji}</span>
                <div>
                  <div className="font-[family-name:var(--font-display)] font-black text-lg text-[#0A0A0A] leading-tight">{p.label}</div>
                  <div className="text-sm text-[#555] group-hover:text-[#0A0A0A]">{p.desc}</div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Affiliate disclosure */}
      <section>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-12">
          <div style={{ border: '2px solid #0A0A0A', padding: '24px', backgroundColor: '#FFFFFF' }}>
            <div className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#0A0A0A] mb-3">
              Transparenz — Affiliate-Hinweis
            </div>
            <p className="text-sm text-[#555] leading-relaxed">
              CrazyBabo Bazar nimmt am Amazon EU-Partnerprogramm teil. Wenn du über unsere Links einkaufst, erhalten wir eine kleine Provision — ohne Mehrkosten für dich. Diese Einnahmen finanzieren den Betrieb der Seite und ermöglichen uns die sorgfältige Recherche und Kuration der Produkte. Unsere Empfehlungen sind unabhängig davon: Kein Hersteller bezahlt für eine Platzierung.
            </p>
          </div>
          <div className="mt-8 flex flex-col sm:flex-row gap-4">
            <Link href="/datenschutz" className="text-sm font-bold text-[#0A0A0A] hover:underline transition-colors">
              Datenschutzerklärung →
            </Link>
            <Link href="/impressum" className="text-sm font-bold text-[#0A0A0A] hover:underline transition-colors">
              Impressum →
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
