import { getProductsByMaxPrice } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { Zap } from 'lucide-react'
import type { Metadata } from 'next'
import Link from 'next/link'

export const revalidate = 3600

export const metadata: Metadata = {
  // Ohne Markensuffix: `title.template` im Root-Layout haengt ihn an (lib/seo-title.ts).
  title: 'Geschenke unter 10 Euro — Kleinigkeiten mit Wirkung',
  description: 'Geschenke unter 10 Euro für Wichteln mit striktem Limit, Adventskalender und Nikolaus. Handverlesen statt Resterampe — mit direktem Amazon-Link.',
  alternates: { canonical: '/unter-10' },
}

export default async function Unter10Page() {
  const products = await getProductsByMaxPrice(1000)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Zap size={20} className="text-[#0A0A0A]" />
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Preisfilter</span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            Geschenke unter 10€
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {products.length} Produkte für unter 10&nbsp;Euro
          </p>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          <p className="text-[#333] text-sm leading-relaxed">
            Zehn Euro sind eine harte Grenze — und genau deshalb die interessanteste. Wer im Büro wichtelt, einen Adventskalender füllt oder am 6. Dezember noch etwas in einen Stiefel bekommen muss, hat kein Budget für Kompromisse. Unsere Faustregel für diese Preisklasse: ein Produkt, das eine Sache kann und die richtig. Multifunktions-Gadgets werden hier unten schnell zu Plastik, das nichts davon gut macht.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Deshalb steht hier nur, was auch für sich allein auf dem Tisch bestehen würde: kleine Helfer für Schreibtisch und Küche, Kurioses zum Auspacken, Nachschub für Dinge, die ständig verschwinden. Wenn dein Wichtel-Limit großzügiger ist, findest du unter <Link href="/unter-20" className="underline font-semibold text-[#0A0A0A]">Geschenke unter 20€</Link> die nächste Stufe. Jedes Produkt hier wurde manuell ausgewählt und hat einen direkten Amazon-Link.
          </p>
          <p className="text-[#333] text-sm leading-relaxed">
            Diese Seite zeigt den vollständigen Preisfilter mit allen veröffentlichten Produkten unter 10&nbsp;Euro. Wenn du lieber eine kurze redaktionelle Auswahl möchtest, findest du in <Link href="/listen/unter-10-euro-die-sich-lohnen" className="underline font-semibold text-[#0A0A0A]">Unter 10€ — und trotzdem gut</Link> zehn handverlesene Empfehlungen aus diesem Bestand.
          </p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Aktuell keine Produkte unter 10&nbsp;Euro verfügbar.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6"><ProductGrid products={products} /></div>
      )}
    </div>
  )
}
