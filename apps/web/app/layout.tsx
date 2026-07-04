import type { Metadata } from 'next'
import { Syne, DM_Sans, IBM_Plex_Mono } from 'next/font/google'
import Link from 'next/link'
import { CookieConsent } from '@/components/ui/cookie-consent'
import { NavMenus, NavSearch } from '@/components/ui/nav-menu'
import { Analytics } from '@vercel/analytics/next'
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
  metadataBase: new URL('https://www.crazybabobazar.com'),
  verification: {
    google: '0-2fBgkGdD22Ok1XDFgGoP_zORgrokNpxohfuAJeL8Y',
    other: { 'p:domain_verify': 'cc1b46f6fda96fe7577d48e03001aa32' },
  },
  title: {
    default: 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer',
    template: '%s | Crazy Babo Bazar',
  },
  description:
    'Entdecke kuriose, lustige und kaufstarke Produkte aus dem DACH-Raum. Handverlesen, ehrlich bewertet.',
  keywords: ['Gadgets', 'Geschenke', 'Affiliate', 'DACH', 'Kurios', 'Lustig'],
  openGraph: {
    type: 'website',
    locale: 'de_DE',
    siteName: 'Crazy Babo Bazar',
    images: [{ url: 'https://www.crazybabobazar.com/opengraph-image', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    images: ['https://www.crazybabobazar.com/opengraph-image'],
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

              {/* Rechte Seite: Entdecken + Suche */}
              <div className="flex items-center gap-3 shrink-0">
                <Link
                  href="/entdecken"
                  className="flex items-center gap-1.5 text-xs font-black uppercase tracking-widest transition-colors font-[family-name:var(--font-mono)] px-3 py-1.5"
                  style={{ backgroundColor: '#FFE500', color: '#0A0A0A' }}
                  aria-label="Produkte entdecken"
                >
                  <span>♥</span>
                  <span className="hidden sm:inline">Swipe Area</span>
                </Link>
                <NavSearch />
              </div>

            </div>
          </div>
        </header>

        {/* Main */}
        <main className="flex-1">{children}</main>

        <Analytics />
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

              {/* Themen */}
              <div>
                <h3 className="text-xs font-black text-[#0A0A0A] uppercase tracking-widest mb-4 inline-block bg-[#FFE500] px-2 py-0.5">Themen</h3>
                <ul className="space-y-2">
                  {[
                    { href: '/thema/gaming',    label: 'Gaming' },
                    { href: '/thema/tech',       label: 'Tech & Setup' },
                    { href: '/thema/kueche',     label: 'Küche' },
                    { href: '/thema/lifestyle',  label: 'Lifestyle' },
                    { href: '/thema/outdoor',    label: 'Outdoor' },
                    { href: '/listen',           label: 'Listen & Guides' },
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
                  <li><Link href="/ueber-uns" className="text-sm text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors font-medium">Über uns</Link></li>
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
