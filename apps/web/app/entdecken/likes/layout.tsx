import type { Metadata } from 'next'

// `./page.tsx` ist eine Client Component. `metadata` und `generateMetadata`
// werden von Next nur in Server Components ausgewertet, deshalb steht die
// Metadata hier im Layout — der Server-Ebene desselben Segments. Der bestehende
// Client-Code bleibt dadurch unangetastet.
//
// `index: false`, weil die Seite pro Swipe-Session eine andere, rein
// personalisierte Produktliste zeigt: kein stabiler Inhalt, den ein Index
// sinnvoll abbilden koennte, und bei geteilten `?session=`-Links beliebig viele
// Varianten derselben URL. `follow: true`, damit Crawler den verlinkten
// Produktseiten trotzdem folgen duerfen.
//
// Bewusst keine Canonical (die Route soll kein kanonisches Ziel sein) und keine
// Aufnahme in `app/sitemap.ts`.
export const metadata: Metadata = {
  title: 'Meine Likes',
  robots: { index: false, follow: true },
}

export default function LikesLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  // Reines Metadata-Layout: kein zusaetzliches Markup, damit sich am Rendering
  // der Seite nichts aendert.
  return <>{children}</>
}
