import Link from 'next/link'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Baue deinen eigenen JARVIS mit Claude — Kostenloses E-Book',
  description: 'Der praktische Anfängerleitfaden für deinen persönlichen KI-Assistenten mit Stimme, Gedächtnis, News und Kalender. Mit lauffähigem Code. Kostenlos.',
  openGraph: {
    title: 'Baue deinen eigenen JARVIS mit Claude — Kostenlos',
    description: 'Persönlicher KI-Assistent mit Stimme, Briefings & Gedächtnis. 28 Seiten mit lauffähigem Code.',
    type: 'website',
  },
}

const chapters = [
  'Claude als KI-Gehirn einrichten',
  'ElevenLabs Stimme integrieren',
  'Wetter, News & eigene Themen',
  'Kalender & E-Mails anbinden',
  'Wake Word & Doppelklatschen',
  'Gedächtnis & Agenten',
  'Web-Dashboard im Browser',
  'Deployment mit GitHub & VPS',
]

export default function JarvisEbookPage() {
  return (
    <div>
      {/* ── HERO ─────────────────────────────────────────────── */}
      <section style={{ backgroundColor: '#0A0A0A', borderBottom: '2px solid #FFE500' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-16">
          <div className="flex flex-col lg:flex-row gap-12 items-center">

            {/* Cover */}
            <div
              className="shrink-0 w-full lg:w-[320px]"
              style={{
                border: '3px solid #FFE500',
                background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)',
                padding: '2.5rem 2rem',
                position: 'relative',
              }}
            >
              <div
                className="text-[10px] font-black uppercase tracking-widest font-[family-name:var(--font-mono)] mb-6 inline-block"
                style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
              >
                Kostenloses E-Book
              </div>

              {/* Orb */}
              <div className="flex justify-end mb-4">
                <div style={{
                  width: 80, height: 80,
                  borderRadius: '50%',
                  background: 'radial-gradient(circle at 30% 30%, #7c3aed, #4f46e5)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: '0 0 30px rgba(124, 58, 237, 0.5)',
                }}>
                  <span style={{ fontSize: 28 }}>🎙️</span>
                </div>
              </div>

              <div className="text-white text-sm mb-6 font-[family-name:var(--font-mono)] opacity-70 leading-relaxed border border-white/20 p-3" style={{ background: 'rgba(255,255,255,0.05)' }}>
                <span style={{ color: '#00BFFF', fontWeight: 'bold' }}>Jarvis</span><br />
                Guten Morgen. Heute 22 Grad,<br />
                3 Termine, 5 neue E-Mails.<br />
                <span style={{ color: '#00BFFF' }}>Worauf willst du dich vorbereiten?</span>
              </div>

              <p className="text-white text-2xl font-[family-name:var(--font-display)] font-black leading-tight mb-1">
                Baue deinen
              </p>
              <p className="text-3xl font-[family-name:var(--font-display)] font-black leading-tight mb-1" style={{ color: '#00BFFF' }}>
                eigenen JARVIS
              </p>
              <p className="text-white text-3xl font-[family-name:var(--font-display)] font-black leading-tight mb-4">
                mit Claude.
              </p>

              <p className="text-white/60 text-xs leading-relaxed mb-6">
                Der praktische Anfängerleitfaden für deinen persönlichen KI-Assistenten – mit lauffähigem Code.
              </p>

              <div className="flex gap-2 flex-wrap mb-4">
                {['Stimme', 'Briefings', 'Gedächtnis'].map(tag => (
                  <span key={tag} style={{ border: '1px solid #00BFFF', color: '#00BFFF', padding: '2px 10px', fontSize: 11, borderRadius: 999 }}>
                    {tag}
                  </span>
                ))}
              </div>

              <div className="text-white/40 text-xs font-[family-name:var(--font-mono)]">
                crazybabobazar.com
              </div>
            </div>

            {/* Text */}
            <div className="flex-1">
              <div
                className="font-[family-name:var(--font-mono)] font-black text-[11px] uppercase tracking-widest mb-4 inline-block"
                style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
              >
                Gratis Download
              </div>
              <h1 className="font-[family-name:var(--font-display)] font-black text-3xl sm:text-4xl text-white leading-tight mb-4">
                Dein eigener KI-Assistent.<br />
                <span style={{ color: '#FFE500' }}>Mit Stimme. Mit Gedächtnis.</span>
              </h1>
              <p className="text-[#AAA] text-base leading-relaxed mb-8 max-w-xl">
                28 Seiten. Lauffähiger Code. Keine Vorkenntnisse nötig. Du baust einen persönlichen Assistenten der spricht, Nachrichten liest, Termine kennt und sich Dinge merkt — auf Basis von Claude und Next.js.
              </p>

              <a
                href="https://ydiihvzcxaaoqhmgoqvu.supabase.co/storage/v1/object/public/downloads/Baue_deinen_eigenen_Jarvis_mit_Claude_Ebook_v1.2.docx"
                download="Jarvis-mit-Claude-Ebook.docx"
                className="inline-block font-bold text-base px-8 py-4 transition-all duration-200 mb-4 bg-[#FFE500] text-[#0A0A0A] border-2 border-[#FFE500] hover:bg-transparent hover:text-[#FFE500]"
              >
                ↓ E-Book kostenlos downloaden
              </a>

              <p className="text-[#555] text-xs mt-3">
                Kein Account. Keine E-Mail. Einfach herunterladen.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ── WAS DRIN STEHT ───────────────────────────────────── */}
      <section style={{ backgroundColor: '#FFFFFF', borderBottom: '2px solid #0A0A0A' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-1 h-6 bg-[#FFE500]" />
            <h2 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A]">
              16 Kapitel — was du lernst
            </h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {chapters.map((ch, i) => (
              <div
                key={i}
                className="flex items-center gap-3 border-2 border-[#0A0A0A] p-4"
                style={{ backgroundColor: '#F8F8F8' }}
              >
                <span
                  className="font-[family-name:var(--font-mono)] font-black text-xs shrink-0"
                  style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '1px 6px' }}
                >
                  {String(i + 5).padStart(2, '0')}
                </span>
                <span className="text-[#0A0A0A] text-sm font-semibold">{ch}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FÜR WEN ──────────────────────────────────────────── */}
      <section style={{ backgroundColor: '#FFE500', borderBottom: '2px solid #0A0A0A' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            {[
              { icon: '🔰', title: 'Keine Vorkenntnisse', text: 'Du brauchst keinen Informatik-Abschluss. Jeder Schritt wird erklärt.' },
              { icon: '💻', title: 'Echter Code', text: 'Lauffähige TypeScript-Beispiele für Claude API, ElevenLabs und Next.js.' },
              { icon: '🆓', title: 'Komplett kostenlos', text: 'Kein Kauf, kein Account, keine E-Mail. Einfach runterladen.' },
            ].map(item => (
              <div key={item.title} className="border-2 border-[#0A0A0A] bg-white p-6">
                <div className="text-3xl mb-3">{item.icon}</div>
                <h3 className="font-[family-name:var(--font-display)] font-black text-lg text-[#0A0A0A] mb-2">{item.title}</h3>
                <p className="text-[#555] text-sm leading-relaxed">{item.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── GEEKLIST CTA ─────────────────────────────────────── */}
      <section style={{ backgroundColor: '#F8F8F8', borderBottom: '2px solid #0A0A0A' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12 flex flex-col sm:flex-row items-center justify-between gap-6">
          <div>
            <div
              className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest mb-2 inline-block"
              style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '2px 8px' }}
            >
              Passend dazu
            </div>
            <h3 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A]">
              Die Hardware für deinen Jarvis
            </h3>
            <p className="text-[#555] text-sm mt-1">Flipper Zero, HHKB, Seek Thermal & mehr — handverlesen für echte Geeks.</p>
          </div>
          <Link
            href="/listen/geeklist"
            className="shrink-0 font-bold text-sm px-6 py-3 border-2 border-[#0A0A0A] bg-[#0A0A0A] text-white hover:bg-[#FFE500] hover:text-[#0A0A0A] transition-colors"
          >
            Zur Geeklist →
          </Link>
        </div>
      </section>
    </div>
  )
}
