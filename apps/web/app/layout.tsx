import type { Metadata } from 'next'
import { Syne, DM_Sans } from 'next/font/google'
import Link from 'next/link'
import Image from 'next/image'
import { CookieConsent } from '@/components/ui/cookie-consent'
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

const navLinks = [
  { href: '/kategorie/lustige-gadgets', label: 'Lustige Gadgets' },
  { href: '/kategorie/geschenke-maenner', label: 'Geschenke' },
  { href: '/kategorie/buero-gadgets', label: 'Büro' },
  { href: '/kategorie/kuechen-gadgets', label: 'Küche' },
  { href: '/kategorie/geschenke-unter-20', label: 'Unter 20€' },
]

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="de"
      className={`${syne.variable} ${dmSans.variable}`}
    >
      <body className="bg-[#1C1C1C] text-[#F0EDE8] font-[family-name:var(--font-body)] min-h-screen flex flex-col">
        {/* Nav */}
        <header className="border-b border-[#333333] sticky top-0 z-50 bg-[#1C1C1C]/95 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6">
            <div className="flex items-center justify-between h-16">
              {/* Logo */}
              <Link
                href="/"
                className="font-[family-name:var(--font-display)] font-bold text-xl tracking-tight flex items-center gap-2 group"
              >
                <span className="bg-[#E85000] text-[#1C1C1C] px-2 py-0.5 text-sm font-extrabold group-hover:bg-[#E8321C] transition-colors duration-200">
                  CRAZY
                </span>
                <span className="text-[#F0EDE8]">BABO BAZAR</span>
              </Link>

              {/* Desktop Nav */}
              <nav className="hidden md:flex items-center gap-1" aria-label="Hauptnavigation">
                {navLinks.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="px-3 py-2 text-sm text-[#9E9890] hover:text-[#E85000] hover:bg-[#252525] transition-all duration-150 font-medium"
                  >
                    {link.label}
                  </Link>
                ))}
              </nav>

              {/* CTA */}
              <Link
                href="/guide/beste-buero-gadgets-2024"
                className="hidden sm:block text-xs font-bold bg-[#E85000] text-[#1C1C1C] px-4 py-2 hover:bg-[#E8321C] hover:text-[#F0EDE8] transition-all duration-200"
              >
                GUIDES →
              </Link>
            </div>

            {/* Mobile Nav */}
            <nav className="md:hidden flex gap-1 pb-3 overflow-x-auto" aria-label="Mobile Navigation">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className="shrink-0 px-3 py-1.5 text-xs text-[#9E9890] hover:text-[#E85000] border border-[#333333] hover:border-[#E85000] transition-all duration-150 font-medium whitespace-nowrap"
                >
                  {link.label}
                </Link>
              ))}
            </nav>
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
                  {navLinks.map((link) => (
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
