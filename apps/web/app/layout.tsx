import type { Metadata } from 'next'
import { Syne, DM_Sans, IBM_Plex_Mono } from 'next/font/google'
import Link from 'next/link'
import { CookieConsent } from '@/components/ui/cookie-consent'
import { NavMenus, NavSearch } from '@/components/ui/nav-menu'
import './globals.css'

const syne = Syne({
  subsets: ['latin'],
  weight: ['400', '600', '700', '800'],
  variable: '--font-display',
  display: 'swap',
})

const dmSans = DM_Sans({
  subsets: ['latin'],
  weight: ['300', '400', '500'],
  variable: '--font-body',
  display: 'swap',
})

const ibmPlexMono = IBM_Plex_Mono({
  subsets: ['latin'],
  weight: ['400', '500', '700'],
  variable: '--font-mono',
  display: 'swap',
})

export const metadata: Metadata = {
  title: {
    default: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
    template: '%s | Crazy Babo Bazar',
  },
  description:
    'Entdecke kuriose, lustige und kaufstarke Produkte aus dem DACH-Raum. Handverlesen, ehrlich bewertet.',
  keywords: ['Gadgets', 'Geschenke', 'Affiliate', 'DACH', 'Kurios', 'Lustig'],
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
  },
  openGraph: {
    type: 'website',
    locale: 'de_DE',
    siteName: 'Crazy Babo Bazar',
  },
}

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="de" className={`${syne.variable} ${dmSans.variable} ${ibmPlexMono.variable}`} data-scroll-behavior="smooth">
      <body className="bg-white text-[#0A0A0A] font-[family-name:var(--font-body)] min-h-screen flex flex-col">

        {/* Header */}
        <header className="border-b-2 border-[#0A0A0A] sticky top-0 z-50 bg-[#0A0A0A]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6">
            <div className="flex items-center justify-between h-16 gap-4">

              {/* Logo */}
              <Link
                href="/"
                className="font-[family-name:var(--font-body)] font-semibold text-xl tracking-tight flex items-center gap-2 group shrink-0"
              >
                <span className="bg-[#FFE500] text-[#0A0A0A] px-2 py-0.5 text-sm font-extrabold transition-colors duration-200">
                  CRAZY
                </span>
                <span className="text-white">BABO BAZAR</span>
              </Link>

              {/* Desktop Nav mit Dropdowns */}
              <NavMenus />

              {/* Rechte Seite: Suche */}
              <div className="flex items-center gap-3 shrink-0">
                <NavSearch />
              </div>

            </div>
          </div>
        </header>

        {/* Main */}
        <main className="flex-1">{children}</main>

        <CookieConsent />

        {/* Footer */}
        <footer className="border-t-2 border-[#0A0A0A] mt-auto bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pb-8 border-b-2 border-[#0A0A0A]">

              {/* Brand */}
              <div>
                <div className="font-[family-name:var(--font-display)] font-black text-2xl text-[#0A0A0A] leading-none tracking-tight mb-4" style={{ letterSpacing: '-0.04em' }}>
                  CRAZY<br />
                  <span style={{ background: '#FFE500', color: '#0A0A0A', paddingLeft: '4px', paddingRight: '4px' }}>BABO</span>{' '}
                  BAZAR
                </div>
                <p className="text-[#555] text-sm leading-relaxed max-w-xs">
                  Kuriose Produkte für schlaue Käufer. Handverlesen.
                </p>
                <p className="text-[#888] text-xs mt-4">
                  Als Amazon-Partner verdienen wir an qualifizierten Käufen.
                </p>
              </div>

              {/* Kategorien */}
              <div>
                <h3 className="text-xs font-black text-[#0A0A0A] uppercase tracking-widest mb-4 inline-block bg-[#FFE500] px-2 py-0.5">Kategorien</h3>
                <ul className="space-y-2">
                  {[
                    { href: '/babos', label: 'Babos' },
                    { href: '/queens', label: 'Queens' },
                    { href: '/miniboss', label: 'Miniboss' },
                    { href: '/wellness', label: 'Wellness' },
                    { href: '/unter-20', label: 'Unter 20€' },
                  ].map(link => (
                    <li key={link.href}>
                      <Link href={link.href} className="text-sm text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors font-medium">
                        {link.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Legal */}
              <div>
                <h3 className="text-xs font-black text-[#0A0A0A] uppercase tracking-widest mb-4 inline-block bg-[#FFE500] px-2 py-0.5">Rechtliches</h3>
                <ul className="space-y-2">
                  <li><Link href="/impressum" className="text-sm text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors font-medium">Impressum</Link></li>
                  <li><Link href="/datenschutz" className="text-sm text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors font-medium">Datenschutz</Link></li>
                </ul>
              </div>
            </div>

            <div className="pt-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
              <p className="text-[#888] text-xs font-medium">© 2026 Crazy Babo Bazar.</p>
              <p className="text-[#888] text-xs font-medium">Made with obsession, not algorithms.</p>
            </div>
          </div>
        </footer>

      </body>
    </html>
  )
}
