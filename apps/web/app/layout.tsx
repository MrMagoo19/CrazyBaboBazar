import type { Metadata } from 'next'
import { Syne, DM_Sans } from 'next/font/google'
import Link from 'next/link'
import Image from 'next/image'
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

const footerLinks = [
  { href: '/kategorie/lustige-gadgets', label: 'Lustige Gadgets' },
  { href: '/kategorie/geschenke-maenner', label: 'Babos' },
  { href: '/kategorie/buero-gadgets', label: 'Büro-Gadgets' },
  { href: '/kategorie/kuechen-gadgets', label: 'Küchen-Gadgets' },
  { href: '/kategorie/geschenke-unter-20', label: 'Unter 20€' },
]

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="de" className={`${syne.variable} ${dmSans.variable}`}>
      <body className="bg-[#1C1C1C] text-[#F0EDE8] font-[family-name:var(--font-body)] min-h-screen flex flex-col">

        {/* Header */}
        <header className="border-b border-[#333333] sticky top-0 z-50 bg-[#1C1C1C]/95 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6">
            <div className="flex items-center justify-between h-16 gap-4">

              {/* Logo */}
              <Link
                href="/"
                className="font-[family-name:var(--font-display)] font-bold text-xl tracking-tight flex items-center gap-2 group shrink-0"
              >
                <span className="bg-[#E85000] text-[#1C1C1C] px-2 py-0.5 text-sm font-extrabold group-hover:bg-[#E8321C] transition-colors duration-200">
                  CRAZY
                </span>
                <span className="text-[#F0EDE8]">BABO BAZAR</span>
              </Link>

              {/* Desktop Nav mit Dropdowns */}
              <NavMenus />

              {/* Rechte Seite: Guide + Suche + Mobile Burger */}
              <div className="flex items-center gap-3 shrink-0">
                <Link
                  href="/guide"
                  className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 bg-[#E85000] text-[#1C1C1C] text-[10px] font-extrabold uppercase tracking-widest hover:bg-[#E8321C] transition-colors duration-200"
                >
                  Filter
                </Link>
                <NavSearch />
              </div>

            </div>
          </div>
        </header>

        {/* Main */}
        <main className="flex-1">{children}</main>

        <CookieConsent />

        {/* Footer */}
        <footer className="border-t border-[#333333] mt-auto">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">

              {/* Brand */}
              <div>
                <Image
                  src="/Logo.png"
                  alt="Crazy Babo Bazar"
                  width={160}
                  height={160}
                  className="object-contain mb-2"
                />
                <p className="text-[#6B6560] text-sm leading-relaxed max-w-xs">
                  Kuriose Produkte für schlaue Käufer. Handverlesen.
                </p>
                <p className="text-[#3A3A3A] text-xs mt-4">
                  Als Amazon-Partner verdienen wir an qualifizierten Käufen. Preise inkl. MwSt., können variieren.
                </p>
              </div>

              {/* Kategorien */}
              <div>
                <h3 className="text-xs font-bold text-[#6B6560] uppercase tracking-widest mb-4">Kategorien</h3>
                <ul className="space-y-2">
                  {footerLinks.map((link) => (
                    <li key={link.href}>
                      <Link href={link.href} className="text-sm text-[#9E9890] hover:text-[#E85000] transition-colors">
                        {link.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Legal */}
              <div>
                <h3 className="text-xs font-bold text-[#6B6560] uppercase tracking-widest mb-4">Rechtliches</h3>
                <ul className="space-y-2">
                  <li>
                    <Link href="/impressum" className="text-sm text-[#9E9890] hover:text-[#E85000] transition-colors">
                      Impressum
                    </Link>
                  </li>
                  <li>
                    <Link href="/datenschutz" className="text-sm text-[#9E9890] hover:text-[#E85000] transition-colors">
                      Datenschutz
                    </Link>
                  </li>
                </ul>
              </div>

            </div>

            <div className="mt-10 pt-6 border-t border-[#252525] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
              <p className="text-[#3A3A3A] text-xs">© 2026 Crazy Babo Bazar. Alle Rechte vorbehalten.</p>
              <p className="text-[#3A3A3A] text-xs">Made with obsession, not algorithms.</p>
            </div>
          </div>
        </footer>

      </body>
    </html>
  )
}
