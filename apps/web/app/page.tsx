import Link from 'next/link'
import type { Metadata } from 'next'

import { GiftEntryGrid } from '@/components/gift-entry-grid'
import { ProductGrid } from '@/components/product-grid'
import { getHomepageHighlights } from '@/lib/db'
import {
  BUDGET_ENTRIES,
  OCCASION_ENTRIES,
  RECIPIENT_ENTRIES,
  THEME_ENTRIES,
  TOP_ENTRIES,
} from '@/lib/geschenke'

export const revalidate = 3600

export const metadata: Metadata = {
  title: 'Crazy Babo Bazar — Geschenke, die nicht nach Standardliste aussehen',
  description:
    'Geschenkefinder nach Empfänger, Budget, Thema und Anlass. Handverlesene Listen und Guides statt endlosem Scrollen — mit direktem Amazon-Link.',
  alternates: { canonical: '/' },
  openGraph: {
    title: 'Crazy Babo Bazar — Geschenke, die nicht nach Standardliste aussehen',
    description: 'Geschenkefinder nach Empfänger, Budget, Thema und Anlass. Handverlesen.',
    type: 'website',
    url: 'https://www.crazybabobazar.com',
  },
  twitter: { card: 'summary_large_image' },
}

/** Der wiederkehrende Abschnittskopf — gelbes Kicker-Label über der H2. */
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

export default async function HomePage() {
  // Nur die zwoelf Karten, die diese Seite auch zeigt. Der vollstaendige Katalog
  // lag hier frueher im HTML — siehe `getHomepageHighlights` in `lib/db.ts`.
  const highlights = await getHomepageHighlights()

  return (
    <div className="min-h-screen bg-white">
      {/* ── Hero ──────────────────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-14 sm:py-20">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-5 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            Geschenkefinder
          </div>
          <h1
            className="font-[family-name:var(--font-display)] font-black text-4xl sm:text-5xl lg:text-6xl text-[#0A0A0A] leading-[1.05] max-w-3xl"
            style={{ letterSpacing: '-0.03em' }}
          >
            Geschenke, die nicht nach Standardliste aussehen.
          </h1>
          <p className="text-base sm:text-lg text-[#333] mt-5 max-w-2xl leading-relaxed">
            Keine Algorithmen. Keine Zufallstreffer. Sag uns, für wen und wie viel — die Auswahl
            dahinter haben wir schon getroffen. Wer ewig scrollt, findet auch nix.
          </p>

          <div className="mt-8 flex flex-col sm:flex-row sm:items-center gap-4">
            <Link
              href="/geschenke"
              className="inline-flex items-center justify-center gap-2 font-[family-name:var(--font-mono)] font-black text-sm uppercase tracking-widest px-8 transition-[filter] hover:brightness-95"
              style={{
                minHeight: '52px',
                backgroundColor: '#FFE500',
                color: '#0A0A0A',
                borderWidth: '2.5px',
                borderStyle: 'solid',
                borderColor: '#0A0A0A',
                boxShadow: '4px 4px 0px #0A0A0A',
              }}
            >
              Zum Geschenkefinder →
            </Link>
            <Link
              href="/listen/witzige-geschenke-maenner"
              className="inline-flex items-center justify-center font-[family-name:var(--font-mono)] font-bold text-sm uppercase tracking-widest px-6 text-[#0A0A0A] underline underline-offset-4 hover:bg-[#FFE500] transition-colors"
              style={{ minHeight: '52px' }}
            >
              Oder direkt: Witzige Geschenke für Männer
            </Link>
          </div>
        </div>
      </section>

      {/* ── Die fünf stärksten Seiten ─────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div
            className="inline-block text-[10px] font-black uppercase tracking-widest mb-3 font-[family-name:var(--font-mono)]"
            style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '3px 10px' }}
          >
            Direkt loslegen
          </div>
          <h2
            className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl text-white leading-tight mb-6"
            style={{ letterSpacing: '-0.02em' }}
          >
            Fünf schnelle Einstiege mit klarer Absicht
          </h2>
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

      {/* ── Einstieg 1: Empfänger ─────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Für wen"
            title="Erst der Mensch, dann das Produkt"
            lead="Drei Richtungen, drei sehr unterschiedliche Regale."
          />
          <GiftEntryGrid entries={RECIPIENT_ENTRIES} />
        </div>
      </section>

      {/* ── Einstieg 2: Budget ────────────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Wie viel"
            title="Budget zuerst, Ausreden später"
            lead="Wichtellimit, Mitbringsel oder richtiges Geschenk — such dir die Grenze aus."
          />
          <GiftEntryGrid entries={BUDGET_ENTRIES} columns={2} />
        </div>
      </section>

      {/* ── Einstieg 3: Themen & Anlass ───────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Thema & Anlass"
            title="Du weißt schon, worum es geht"
            lead="Ein Thema, das er sowieso lebt — oder der Anlass, der nächste Woche ansteht."
          />
          <GiftEntryGrid entries={THEME_ENTRIES} />
          <div className="mt-4">
            <GiftEntryGrid entries={OCCASION_ENTRIES.slice(0, 3)} />
          </div>
          <Link
            href="/geschenke"
            className="inline-flex items-center mt-6 text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#0A0A0A] underline underline-offset-4 hover:bg-[#FFE500] px-1 transition-colors"
            style={{ minHeight: '44px' }}
          >
            Alle Einstiege im Geschenkefinder →
          </Link>
        </div>
      </section>

      {/* ── Kuratierte Empfehlungen ───────────────────────────── */}
      <section className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <SectionHeading
            kicker="Kuratiert"
            title="Aktuelle Empfehlungen"
            lead="Eine kleine Auswahl aus dem Bestand — Top Picks zuerst, danach das Neueste."
          />
          {highlights.length === 0 ? (
            <p className="text-sm text-[#555]">
              Gerade keine Empfehlungen verfügbar. Im{' '}
              <Link href="/geschenke" className="underline font-semibold text-[#0A0A0A]">
                Geschenkefinder
              </Link>{' '}
              findest du trotzdem jede Liste.
            </p>
          ) : (
            <ProductGrid products={highlights} />
          )}
          <Link
            href="/trending"
            className="inline-flex items-center mt-8 text-xs font-black uppercase tracking-widest font-[family-name:var(--font-mono)] text-[#0A0A0A] underline underline-offset-4 hover:bg-[#FFE500] px-1 transition-colors"
            style={{ minHeight: '44px' }}
          >
            Alle Produkte ansehen →
          </Link>
        </div>
      </section>

      {/* ── Swipe — kleine Nebensektion, ohne Bestandszahl ────── */}
      <section className="bg-[#F8F8F8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <p className="text-sm text-[#555] leading-relaxed max-w-xl">
            Noch keinen Plan? In der Swipe Area entscheidest du per Daumen statt per Filter.
          </p>
          <Link
            href="/entdecken"
            className="inline-flex items-center justify-center shrink-0 font-[family-name:var(--font-mono)] font-bold text-xs uppercase tracking-widest px-5 border-2 border-[#0A0A0A] text-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors"
            style={{ minHeight: '44px' }}
          >
            ♥ Swipe Area
          </Link>
        </div>
      </section>
    </div>
  )
}
