import { getProductsByTag } from '@/lib/db'
import { ProductGrid } from '@/components/product-grid'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import type { Metadata } from 'next'

export const revalidate = 3600

const TAG_CONFIG: Record<string, { label: string; desc: string; emoji: string; metaTitle: string; metaDesc: string; intro: string[] }> = {
  gaming: {
    label: 'Gaming', desc: 'Tabletop, Retro, Collectibles & Gamer-Gadgets', emoji: '🎮',
    metaTitle: 'Gaming Gadgets & Geschenke für Gamer | Crazy Babo Bazar',
    metaDesc: 'Retro-Konsolen, Speed Cubes, LEGO Collectibles und Gaming-Gadgets — handverlesen für echte Gamer. Mit direktem Amazon-Link.',
    intro: [
      'Gaming bei Crazy Babo Bazar bedeutet: Retro-Konsolen die du als Kind haben wolltest, Collector\'s Editions die nach zehn Jahren noch im Regal stehen, und Gadgets die beim Spieleabend für echte Aha-Momente sorgen. Keine Mainstream-Bestsellerlisten, kein Einheitsbrei.',
      'Diese Kategorie ist gleichzeitig die verlässlichste Anlaufstelle für Geschenke für Gamer — weil echte Gamer sich das Besondere selten selbst kaufen. Der Speed Cube landet im Weihnachtsstrumpf, die Retro-Handheld-Konsole wird zum beliebtesten Bürogegenstand. Kein Algorithmus, keine gesponserten Platzierungen — nur echte Picks.',
    ],
  },
  tech: {
    label: 'Tech & Setup', desc: 'Gadgets, Schreibtisch & Tüftler-Zeug', emoji: '💻',
    metaTitle: 'Tech Gadgets & Geschenke für Technik-Fans | Crazy Babo Bazar',
    metaDesc: 'Maker-Tools, Setup-Upgrades und Technik-Gadgets die wirklich etwas können — handverlesen mit direktem Amazon-Link.',
    intro: [
      'Tech bei Crazy Babo Bazar ist kein Elektronikmarkt-Katalog. Hier findest du Gadgets die tatsächlich etwas können — Werkzeuge für Maker, Setup-Upgrades die den Unterschied machen, und Technik-Spielzeug das bei jedem Besuch für Gesprächsstoff sorgt.',
      'Von der Wärmebildkamera die ans Smartphone gesteckt wird, über den USB-C-Lötkolben der in 6 Sekunden heiß ist, bis zum Motorrad-Headset mit Harman-Kardon-Sound: Diese Kategorie ist für alle, die Technik nicht nur benutzen, sondern verstehen wollen. Besonders geeignet als Geschenk für Technik-Fans.',
    ],
  },
  kueche: {
    label: 'Küche', desc: 'Küchengeräte, Gadgets & Kulinarisches', emoji: '🍳',
    metaTitle: 'Küchen-Gadgets & Geschenke für Kochbegeisterte | Crazy Babo Bazar',
    metaDesc: 'Clevere Küchenhelfer, ausgefallene Kochbücher und Gadgets die den Alltag in der Küche wirklich verbessern. Handverlesen auf Amazon.',
    intro: [
      'Nicht jedes Küchengerät muss in einer Packung mit 37 Zubehörteilen kommen. Die Küchen-Kategorie bei Crazy Babo Bazar zeigt was wirklich im Alltag überzeugt — oder zumindest beim Abendessen für Staunen sorgt.',
      'Ob cleveres Küchengadget das du täglich benutzt, ausgefallenes Kochbuch das den nächsten Dinner-Abend rettet, oder das eine Gerät das dein Kochverhalten tatsächlich verändert: Hier findest du handverlesene Produkte mit echtem Nutzwert. Ideal für alle, die Beschenkte haben, die "eigentlich alles haben" — ein gutes Küchengadget freut sich fast jeder.',
    ],
  },
  lifestyle: {
    label: 'Lifestyle', desc: 'Party, Bar, Deko & Geschenkideen', emoji: '✨',
    metaTitle: 'Ausgefallene Geschenkideen & Lifestyle-Gadgets | Crazy Babo Bazar',
    metaDesc: 'Bar-Gadgets, Partyzubehör, außergewöhnliche Deko und die Art von Produkten über die man noch am nächsten Tag redet.',
    intro: [
      'Lifestyle ist die Kategorie für alles, was sich nicht sauber einordnen lässt — aber sofort gekauft werden muss. Bar-Gadgets, Partyzubehör, Heimbrauset, ausgefallene Deko und Produkte, über die man am nächsten Tag noch redet.',
      'Die meisten Produkte hier erfüllen keine lebensnotwendige Funktion. Genau das macht sie zum perfekten Geschenk — für den Freund der schon alles hat, den Kollegen dem man etwas Besonderes mitbringen will, oder für sich selbst als Belohnung. Crazy Babo Bazar kuratiert Lifestyle-Produkte die auffallen, ohne in die Kitsch-Falle zu tappen.',
    ],
  },
  outdoor: {
    label: 'Outdoor', desc: 'Camping, Survival & Abenteuerzubehör', emoji: '🌿',
    metaTitle: 'Outdoor Gadgets & Camping Zubehör | Crazy Babo Bazar',
    metaDesc: 'Survival-Tools, Drohnen, Camping-Gadgets und Outdoor-Ausrüstung die man nicht bei Decathlon findet. Mit direktem Amazon-Link.',
    intro: [
      'Outdoor bedeutet hier nicht Wanderstöcke und Standard-Gore-Tex. Outdoor bei Crazy Babo Bazar ist das Gear, das auf echten Abenteuern den Unterschied macht — Survival-Tools, Camping-Gadgets, Drohnen und Ausrüstung die du nicht im nächsten Sportgeschäft findest.',
      'Von der selbstfliegenden 4K-Drohne die aus der Handfläche startet, über den Feuerstahl der auch nass funktioniert, bis zur kompakten Wärmebildkamera fürs Smartphone: Diese Kategorie ist für Menschen, die draußen nicht auf Komfort verzichten wollen. Ideal als Geschenke für Outdoor-Enthusiasten, Camper und Motorradfahrer.',
    ],
  },
  beauty: {
    label: 'Beauty & Pflege', desc: 'Hautpflege, Wellness & Körperpflege', emoji: '💆',
    metaTitle: 'Beauty Gadgets & Pflege-Produkte | Crazy Babo Bazar',
    metaDesc: 'Beauty-Gadgets und Pflegeprodukte mit echtem Mehrwert — weit weg von Mainstream-Drogerie. Handverlesen mit direktem Amazon-Link.',
    intro: [
      'Beauty-Gadgets die wirklich funktionieren, Pflegeprodukte mit messbarem Effekt und die Art von Selbstfürsorge, die man sich eigentlich öfter gönnen sollte. Die Beauty-Kategorie bei Crazy Babo Bazar ist weit weg vom Mainstream-Drogerieregal.',
      'Hier findest du Geräte und Produkte, die einen echten Unterschied machen — kein leeres Marketing-Versprechen. Besonders stark als Geschenkidee für Menschen, die Qualität über Quantität stellen. Jedes Produkt wurde manuell ausgewählt und ist direkt über Amazon verfügbar.',
    ],
  },
  spielzeug: {
    label: 'Spielzeug', desc: 'STEM, Kreativität & Kinderspaß', emoji: '🧸',
    metaTitle: 'Spielzeug & Geschenke für Kinder — STEM & Kreativität | Crazy Babo Bazar',
    metaDesc: 'Spielzeug das nicht nach drei Tagen in der Schublade verschwindet — STEM-Baukästen, Experimente-Sets und kreative Produkte für Kinder.',
    intro: [
      'Spielzeug das nicht nach drei Tagen in der Schublade verschwindet. Die Spielzeug-Kategorie bei Crazy Babo Bazar zeigt Produkte, die Kinder wirklich fordern — STEM-Baukästen, Experimente-Sets und Spielzeug das Neugier weckt statt nur Bildschirmzeit zu ersetzen.',
      'Kein Fast-Fashion-Spielzeug, keine kurzlebigen Trends. Stattdessen Produkte mit echtem Lerneffekt, die Fähigkeiten fördern und Freude machen. Ideal als Weihnachtsgeschenk oder Geburtstagsgeschenk für Kinder. Viele davon eignen sich übrigens genauso für Erwachsene, die ihren inneren Tüftler nie ganz abgelegt haben.',
    ],
  },
  fitness: {
    label: 'Fitness & Sport', desc: 'Training, Recovery & Sportequipment', emoji: '💪',
    metaTitle: 'Fitness Gadgets & Sport-Equipment | Crazy Babo Bazar',
    metaDesc: 'Trainings-Tools, Recovery-Gadgets und Sport-Equipment das wirklich genutzt wird — keine Kleiderstangen. Handverlesen mit Amazon-Link.',
    intro: [
      'Fitness-Gadgets, die den Unterschied zwischen "ich hab\'s versucht" und "ich bin dabei geblieben" ausmachen können. Die Fitness-Kategorie bei Crazy Babo Bazar zeigt Trainings-Tools, Recovery-Equipment und Sportzubehör das wirklich genutzt wird.',
      'Kein Heimtrainer der zur Kleiderstange wird. Stattdessen kompakte, clevere Lösungen für Training zuhause, unterwegs und im Gym. Von der Massagepistole für den Tag nach dem harten Workout, bis zum Accessoire das dein Training messbar macht. Ideal als Geschenk für Sportler — und für alle, die endlich anfangen wollen.',
    ],
  },
  haushalt: {
    label: 'Haushalt', desc: 'Smarte Helfer & clevere Alltagsprodukte', emoji: '🏠',
    metaTitle: 'Haushalt Gadgets & smarte Alltagshelfer | Crazy Babo Bazar',
    metaDesc: 'Clevere Haushaltsgadgets und smarte Alltagshelfer, die den täglichen Ablauf tatsächlich verbessern — handverlesen auf Amazon.',
    intro: [
      'Der Haushalt muss nicht langweilig sein. Diese Kategorie versammelt smarte Alltagshelfer und clevere Gadgets, die den täglichen Ablauf tatsächlich verbessern — ohne dabei ein Vermögen zu kosten.',
      'Vom elektrischen Nagelknipser mit LED und Auffangbehälter, über den UV-Desinfektionskasten fürs Smartphone, bis zum Gadget das du erst kaufst und dann deinen Eltern erklärst: Hier findet jeder etwas. Viele dieser Produkte sind gleichzeitig die besten Geschenkideen für Menschen, die sagen "ich brauche eigentlich nichts".',
    ],
  },
}

const SUBNAV = Object.entries(TAG_CONFIG).map(([key, { label }]) => ({
  label,
  href: `/thema/${key}`,
}))

type Props = { params: Promise<{ tag: string }> }

export function generateStaticParams() {
  return Object.keys(TAG_CONFIG).map((tag) => ({ tag }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { tag } = await params
  const config = TAG_CONFIG[tag]
  if (!config) return { title: 'Nicht gefunden', robots: { index: false, follow: false } }
  return {
    title: config.metaTitle,
    description: config.metaDesc,
    alternates: { canonical: `/thema/${tag}` },
    openGraph: {
      title: config.metaTitle,
      description: config.metaDesc,
      url: `https://www.crazybabobazar.com/thema/${tag}`,
    },
  }
}

export default async function ThemaPage({ params }: Props) {
  const { tag } = await params
  const config = TAG_CONFIG[tag]
  if (!config) notFound()

  const products = await getProductsByTag(tag)

  return (
    <div>
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <span className="text-xl leading-none">{config.emoji}</span>
            <span style={{ background: '#FFE500', color: '#0A0A0A', padding: '2px 8px', fontSize: '10px', fontWeight: 900, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: 'var(--font-mono)' }}>
              Thema
            </span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            {config.label}
          </h1>
          <p className="text-[#555] text-sm mt-2">
            {config.desc} · {products.length} Produkte
          </p>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 border-t-2 border-[#0A0A0A]">
          <div className="flex gap-0 overflow-x-auto scrollbar-none">
            {SUBNAV.map(item => (
              <Link
                key={item.href}
                href={item.href}
                className={`shrink-0 px-4 py-3 text-xs font-[family-name:var(--font-mono)] font-bold uppercase tracking-wider border-b-2 transition-all duration-150 ${
                  item.href === `/thema/${tag}`
                    ? 'border-[#FFE500] bg-[#FFE500] text-[#0A0A0A]'
                    : 'border-transparent text-[#555555] hover:text-[#0A0A0A] hover:border-[#0A0A0A]'
                }`}
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
      </div>

      <div className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-3">
          {config.intro.map((p, i) => (
            <p key={i} className="text-[#333] text-sm leading-relaxed">{p}</p>
          ))}
        </div>
      </div>

      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555]">
          Noch keine Produkte in diesem Thema.
        </div>
      ) : (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <ProductGrid products={products} />
        </div>
      )}
    </div>
  )
}
