import Link from 'next/link'
import type { Metadata } from 'next'

import { GiftEntryGrid } from '@/components/gift-entry-grid'
import {
  BUDGET_ENTRIES,
  CURATED_LIST_ENTRIES,
  OCCASION_ENTRIES,
  RECIPIENT_ENTRIES,
  THEME_ENTRIES,
  TOP_ENTRIES,
} from '@/lib/geschenke'

// Rein statische Seite: keine Datenbankabfrage, alle Einstiege stehen in
// `lib/geschenke.ts`. Das `revalidate` bleibt trotzdem gesetzt, damit die Route
// dieselbe ISR-Einstufung hat wie die uebrigen Hubs.
export const revalidate = 3600

export const metadata: Metadata = {
  // Ohne Markensuffix: `title.template` im Root-Layout haengt ihn an (lib/seo-title.ts).
  title: 'Geschenke finden — nach Empfänger, Budget und Anlass',
  description:
    'Der Geschenkefinder von Crazy Babo Bazar: Einstiege nach Empfänger, Budget, Thema und Anlass. Kuratierte Listen und Guides statt endlosem Scrollen.',
  alternates: { canonical: '/geschenke' },
  openGraph: {
    title: 'Geschenke finden — nach Empfänger, Budget und Anlass',
    description: 'Einstiege nach Empfänger, Budget, Thema und Anlass. Handverlesen kuratiert.',
    type: 'website',
    url: 'https://www.crazybabobazar.com/geschenke',
  },
}

const BASE_URL = 'https://www.crazybabobazar.com'

// Genau die zwei sichtbaren Breadcrumb-Stufen, nicht mehr. Serialisiert wie in
// `node_modules/next/dist/docs/01-app/02-guides/json-ld.md` beschrieben: `<`
// wird escaped, damit ein spaeterer Label-Text den Script-Kontext nicht
// verlassen kann.
const breadcrumbLd = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Start', item: BASE_URL },
    { '@type': 'ListItem', position: 2, name: 'Geschenke', item: `${BASE_URL}/geschenke` },
  ],
}

function SectionHeading({ kicker, title, lead }: { kicker: string; title: string; lead?: string }) {
  return (
    <div className="mb-6">
      <div
        className="inline-block text-[10px] font-black uppercase tracking-widest mb-3 font-[family-name:var(--font-mono)]"
        style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
      >
        {kicker}
      </div>
      <h2
        className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl text-[#0A0A0A] leading-tight"
        style={{ letterSpacing: '-0.02em' }}
      >
        {title}
      </h2>
      {lead && <p className="text-sm text-[#555] mt-2 max-w-xl leading-relaxed">{lead}</p>}
    </div>
  )
}

export default function GeschenkePage() {
  return (
    <div className="bg-white">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(breadcrumbLd).replace(/</g, '\\u003c'),
        }}
      />

      {/* ── Breadcrumb ────────────────────────────────────────── */}
      <nav aria-label="Brotkrumen" className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <ol className="flex items-center gap-2 text-xs text-[#555]">
            <li>
              <Link href="/" className="hover:text-[#0A0A0A] hover:underline">
                Start
              </Link>
            </li>
            <li aria-hidden>→</li>
            <li>
              <span aria-current="page" className="text-[#0A0A0A]">
                Geschenke
              </span>
            </li>
          </ol>
        </div>
      </nav>

      {/* ── Kopf ──────────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-4 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            Geschenkefinder
          </div>
          <h1
            className="font-[family-name:var(--font-display)] font-black text-3xl sm:text-4xl lg:text-5xl text-[#0A0A0A] leading-[1.08] max-w-3xl"
            style={{ letterSpacing: '-0.03em' }}
          >
            Geschenke finden, ohne dich durch alles zu scrollen
          </h1>
          <p className="text-base text-[#333] mt-4 max-w-2xl leading-relaxed">
            Vier Wege hinein: Empfänger, Budget, Thema oder Anlass. Dahinter liegen kuratierte
            Listen und Guides — jede Auswahl ist eine Entscheidung, kein Algorithmus.
          </p>
        </div>
      </section>

      {/* ── Empfänger ─────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Nach Empfänger"
            title="Für wen suchst du?"
            lead="Drei Richtungen, drei sehr unterschiedliche Regale."
          />
          <GiftEntryGrid entries={RECIPIENT_ENTRIES} />
        </div>
      </section>

      {/* ── Budget ────────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Nach Budget"
            title="Wie viel darf es werden?"
            lead="Preisbänder statt Preisversprechen — der aktuelle Preis steht immer beim Händler."
          />
          <GiftEntryGrid entries={BUDGET_ENTRIES} columns={2} />
        </div>
      </section>

      {/* ── Anlass ────────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Nach Anlass"
            title="Was steht an?"
            lead="Wichteln, Spieleabend, Einzug — der Anlass entscheidet öfter als das Thema."
          />
          <GiftEntryGrid entries={OCCASION_ENTRIES} />
        </div>
      </section>

      {/* ── Thema ─────────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Nach Thema"
            title="Er lebt das sowieso"
            lead="Wenn du weißt, wofür sie brennt, ist das der kürzeste Weg."
          />
          <GiftEntryGrid entries={THEME_ENTRIES} />
        </div>
      </section>

      {/* ── Kuratierte Empfehlungen ───────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-3 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            Kuratiert
          </div>
          <h2
            className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl text-white leading-tight mb-2"
            style={{ letterSpacing: '-0.02em' }}
          >
            Die Seiten, mit denen die meisten anfangen
          </h2>
          <p className="text-[#AAA] text-sm mb-6 max-w-xl leading-relaxed">
            Wenn du keinen Filter brauchst, sondern nur eine gute Liste.
          </p>
          <ul className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {TOP_ENTRIES.map((entry) => (
              <li key={entry.href} className="flex">
                <Link
                  href={entry.href}
                  className="group flex w-full flex-col justify-center gap-1 px-5 py-4 bg-white hover:bg-[#FFE500] transition-colors"
                  style={{
                    minHeight: '44px',
                    borderWidth: '2px',
                    borderStyle: 'solid',
                    borderColor: '#FFE500',
                  }}
                >
                  <span className="font-[family-name:var(--font-display)] font-black text-base sm:text-lg text-[#0A0A0A] leading-tight">
                    {entry.label}
                  </span>
                  <span className="text-xs text-[#555] leading-relaxed group-hover:text-[#0A0A0A]">
                    {entry.hint}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* ── Weitere Listen ────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Noch mehr"
            title="Weitere kuratierte Listen"
            lead="Für alle, die sich lieber treiben lassen."
          />
          <GiftEntryGrid entries={CURATED_LIST_ENTRIES} />
          <div className="mt-6 flex flex-col sm:flex-row gap-4">
            <Link
              href="/listen"
              className="inline-flex items-center text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#0A0A0A] underline underline-offset-4 hover:bg-[#FFE500] px-1 transition-colors"
              style={{ minHeight: '44px' }}
            >
              Alle Listen →
            </Link>
            <Link
              href="/guide"
              className="inline-flex items-center text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#0A0A0A] underline underline-offset-4 hover:bg-[#FFE500] px-1 transition-colors"
              style={{ minHeight: '44px' }}
            >
              Alle Guides →
            </Link>
          </div>
        </div>
      </section>

      <p className="text-[#555] text-xs text-center py-8 px-4">
        Affiliate-Links — wir verdienen eine Provision ohne Mehrkosten für dich.
      </p>
    </div>
  )
}
