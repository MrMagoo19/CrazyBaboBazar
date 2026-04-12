export type Category = {
  slug: string
  name: string
  emoji: string
  count: number
  description: string
}

export type Product = {
  slug: string
  name: string
  category: string
  categorySlug: string
  price: string
  rating: number
  reviews: number
  tag: string
  description: string
  features: string[]
  affiliateUrl: string
  image: string
}

export type Guide = {
  slug: string
  title: string
  subtitle: string
  readTime: string
  category: string
  intro: string
  sections: { heading: string; body: string }[]
}

export const categories: Category[] = [
  {
    slug: 'lustige-gadgets',
    name: 'Lustige Gadgets',
    emoji: '🎪',
    count: 47,
    description: 'Absurde Erfindungen, die du nicht gebraucht hast — bis jetzt.',
  },
  {
    slug: 'geschenke-maenner',
    name: 'Geschenke für Männer',
    emoji: '🎯',
    count: 62,
    description: 'Für den Mann, der angeblich alles hat. Spoiler: hat er nicht.',
  },
  {
    slug: 'buero-gadgets',
    name: 'Büro-Gadgets',
    emoji: '💼',
    count: 38,
    description: 'Weil der Bürojob erträglicher wird, wenn das Zubehör episch ist.',
  },
  {
    slug: 'kuechen-gadgets',
    name: 'Küchen-Gadgets',
    emoji: '🍳',
    count: 54,
    description: 'Küchengeräte, die dein Kochen auf Level Gordon Ramsay heben.',
  },
  {
    slug: 'geschenke-20-euro',
    name: 'Unter 20€',
    emoji: '💸',
    count: 91,
    description: 'Günstig, aber nicht billig. Wirkungsvoll, aber nicht protzig.',
  },
]

export const products: Product[] = [
  {
    slug: 'pizza-socken-witzige-edition',
    name: 'Pizza-Socken Witzige Edition',
    category: 'Lustige Gadgets',
    categorySlug: 'lustige-gadgets',
    price: '12,99',
    rating: 4.7,
    reviews: 2341,
    tag: 'Bestseller',
    description: 'Socken mit realistischer Pizza-Optik. Perfekt für alle, die beim Anziehen hungrig werden.',
    features: ['85% Baumwolle', 'Einheitsgröße 36–45', 'Maschinenwäsche', '6 Varianten'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
  },
  {
    slug: 'desktop-vakuumsauger',
    name: 'Mini Desktop-Staubsauger',
    category: 'Büro-Gadgets',
    categorySlug: 'buero-gadgets',
    price: '14,95',
    rating: 4.5,
    reviews: 1876,
    tag: 'Top bewertet',
    description: 'Krümel, Radiergummi-Reste, Kollegentränen — dieser Mini-Staubsauger saugt alles weg.',
    features: ['USB-betrieben', 'Kompakt: 15 cm', 'Inkl. zwei Aufsätze', 'Lautlos-Modus'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=400&fit=crop',
  },
  {
    slug: 'avocado-messerset',
    name: 'Profi-Avocado-Messerset',
    category: 'Küchen-Gadgets',
    categorySlug: 'kuechen-gadgets',
    price: '18,90',
    rating: 4.8,
    reviews: 4102,
    tag: 'Neu',
    description: 'Aufschneiden, Entkernen, Schälen — drei Arbeitsschritte, ein Werkzeug.',
    features: ['Edelstahl-Klinge', 'Rutschfester Griff', 'Spülmaschinenfest', '3-in-1'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1519162808019-7de1683fa2ad?w=400&h=400&fit=crop',
  },
  {
    slug: 'mini-projektor-portable',
    name: 'Pocket-Projektor 1080p',
    category: 'Geschenke für Männer',
    categorySlug: 'geschenke-maenner',
    price: '89,99',
    rating: 4.6,
    reviews: 998,
    tag: 'Deal',
    description: 'Filme an die Decke werfen war noch nie so einfach. Kinogefühl im Handtaschen-Format.',
    features: ['1080p Full HD', 'Akku: 2,5h', 'BT-Lautsprecher', 'HDMI + USB-C'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&h=400&fit=crop',
  },
  {
    slug: 'witzige-notizblöcke',
    name: "To-Don't List Notizblock",
    category: 'Unter 20€',
    categorySlug: 'geschenke-20-euro',
    price: '7,99',
    rating: 4.9,
    reviews: 5671,
    tag: 'Viral',
    description: 'Für alle Dinge, die du heute definitiv NICHT erledigst. Ehrlicher als eine To-Do-Liste.',
    features: ['100 Blatt', 'A6 Format', 'Recyclingpapier', '5 Rubriken'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&h=400&fit=crop',
  },
  {
    slug: 'kaffee-warmhalter-schreibtisch',
    name: 'Smart Kaffee-Wärmer USB',
    category: 'Büro-Gadgets',
    categorySlug: 'buero-gadgets',
    price: '19,95',
    rating: 4.6,
    reviews: 3210,
    tag: 'Büro-Favorit',
    description: 'Weil kalter Kaffee keine Option ist. Hält deinen Becher auf exakt 55°C.',
    features: ['USB-C', 'Temperatur-LED', 'Anti-Rutsch Pad', '∅ 12cm'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=400&fit=crop',
  },
  {
    slug: 'magnetische-levitationslampe',
    name: 'Magnetisch schwebende Lampe',
    category: 'Lustige Gadgets',
    categorySlug: 'lustige-gadgets',
    price: '49,99',
    rating: 4.4,
    reviews: 823,
    tag: 'Krass',
    description: 'Eine Lampe, die schwebt. Einfach so. Deine Gäste werden ausrasten.',
    features: ['Magnetisches Levitation', 'LED Touch', '360° drehbar', 'Kein Kabel nötig'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1565814329452-e1efa11c5b89?w=400&h=400&fit=crop',
  },
  {
    slug: 'pizza-schneider-fahrrad',
    name: 'Pizza-Schneider als Fahrrad',
    category: 'Küchen-Gadgets',
    categorySlug: 'kuechen-gadgets',
    price: '11,99',
    rating: 4.7,
    reviews: 7432,
    tag: 'Viral',
    description: 'Kein normaler Pizzaschneider. Ein Miniaturrad das durch deine Pizza brettert.',
    features: ['Edelstahl-Klinge', 'Spülmaschinenfest', 'Lustige Optik', 'Perfektes Schnittbild'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=400&fit=crop',
  },
  {
    slug: 'kabellose-ladestation-3in1',
    name: '3-in-1 Ladestation kabellos',
    category: 'Geschenke für Männer',
    categorySlug: 'geschenke-maenner',
    price: '34,99',
    rating: 4.7,
    reviews: 2190,
    tag: 'Bestseller',
    description: 'iPhone, AirPods und Watch gleichzeitig laden. Ein Kabel regiert sie alle.',
    features: ['15W Qi2', 'MagSafe kompatibel', 'LED-Anzeige', 'Nachtmodus'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1586816001966-79b736744398?w=400&h=400&fit=crop',
  },
  {
    slug: 'eieruhr-analog-retro',
    name: 'Retro Küchen-Timer analog',
    category: 'Unter 20€',
    categorySlug: 'geschenke-20-euro',
    price: '9,99',
    rating: 4.5,
    reviews: 3801,
    tag: '',
    description: 'Tick tack tick tack. Läutet wenn die Nudeln al dente sind. Kein Akku nötig.',
    features: ['60 Minuten', 'Lautes Klingeln', 'Kein Akku', '5 Farben'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?w=400&h=400&fit=crop',
  },
  {
    slug: 'faltbare-wasserflaschen',
    name: 'Faltbare Silikon-Trinkflasche',
    category: 'Lustige Gadgets',
    categorySlug: 'lustige-gadgets',
    price: '13,95',
    rating: 4.3,
    reviews: 1540,
    tag: '',
    description: 'Leer? Zusammenfalten. Voll? Entfalten. Genial simpel.',
    features: ['600 ml', 'BPA-frei', 'Spülmaschinenfest', '8 Farben'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400&h=400&fit=crop',
  },
  {
    slug: 'mini-kettlebell-set',
    name: 'Mini Kettlebell Set 3-teilig',
    category: 'Geschenke für Männer',
    categorySlug: 'geschenke-maenner',
    price: '44,90',
    rating: 4.8,
    reviews: 1120,
    tag: 'Neu',
    description: 'Für das Homeoffice-Workout zwischen zwei Calls. Kein Fitnessstudio nötig.',
    features: ['2 kg / 4 kg / 6 kg', 'Neoprenhülle', 'Rutschfest', 'Inkl. Übungsplan'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&h=400&fit=crop',
  },
  {
    slug: 'led-schreibtischlampe-usb',
    name: 'LED Schreibtischlampe USB-C',
    category: 'Büro-Gadgets',
    categorySlug: 'buero-gadgets',
    price: '29,99',
    rating: 4.6,
    reviews: 4512,
    tag: 'Top bewertet',
    description: 'Augenschonend, dimmbar, USB-C. Dein Schreibtisch wird zum Profi-Setup.',
    features: ['5 Farbtemperaturen', '10 Helligkeitsstufen', 'USB-C', 'Touch-Steuerung'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1504707748692-419802cf939d?w=400&h=400&fit=crop',
  },
  {
    slug: 'knoblauchpresse-premium',
    name: 'Premium Knoblauchpresse Edelstahl',
    category: 'Küchen-Gadgets',
    categorySlug: 'kuechen-gadgets',
    price: '16,90',
    rating: 4.9,
    reviews: 8901,
    tag: 'Bestseller',
    description: 'Kein Schälen, kein Stinken an den Händen. Drücken, fertig.',
    features: ['Edelstahl 18/8', 'Ohne Schälen', 'Spülmaschinenfest', 'Unzerstörbar'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=400&fit=crop',
  },
  {
    slug: 'sticker-pack-memes',
    name: 'Meme-Sticker Pack 100 Stk.',
    category: 'Unter 20€',
    categorySlug: 'geschenke-20-euro',
    price: '6,99',
    rating: 4.6,
    reviews: 12003,
    tag: 'Viral',
    description: '100 wasserfeste Sticker für Laptop, Flasche, Koffer. Dein Leben als Meme.',
    features: ['100 Sticker', 'Wasserfest', 'UV-beständig', 'Keine Rückstände'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1572375992501-4b0892d50c69?w=400&h=400&fit=crop',
  },
  {
    slug: 'drehbarer-bildschirmhalter',
    name: 'Ergonomischer Monitor-Arm',
    category: 'Büro-Gadgets',
    categorySlug: 'buero-gadgets',
    price: '39,95',
    rating: 4.5,
    reviews: 2876,
    tag: '',
    description: 'Endlich Nackenfreiheit. Dein Monitor auf der perfekten Höhe, überall.',
    features: ['17"–32"', 'VESA 75x75/100x100', '360° drehbar', 'Kabelmanagement'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=400&h=400&fit=crop',
  },
  {
    slug: 'brotbackform-silikon',
    name: 'Silikon Brotbackform Set',
    category: 'Küchen-Gadgets',
    categorySlug: 'kuechen-gadgets',
    price: '15,99',
    rating: 4.4,
    reviews: 2310,
    tag: '',
    description: 'Brot backen ohne Kleben, ohne Einölen. Einfach rein, raus, fertig.',
    features: ['2er Set', 'BPA-frei', 'Bis 260°C', 'Spülmaschinenfest'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=400&fit=crop',
  },
  {
    slug: 'taschenmesser-multitool',
    name: 'Multitool Taschenmesser 18in1',
    category: 'Geschenke für Männer',
    categorySlug: 'geschenke-maenner',
    price: '24,99',
    rating: 4.7,
    reviews: 6430,
    tag: 'Deal',
    description: '18 Funktionen in einem. Weil echter Mann immer vorbereitet ist.',
    features: ['18 Funktionen', 'Edelstahl', 'Mit Etui', 'Flugzeugkompatibel'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=400&h=400&fit=crop',
  },
  {
    slug: 'katzen-laser-roboter',
    name: 'Automatischer Katzen-Laser',
    category: 'Lustige Gadgets',
    categorySlug: 'lustige-gadgets',
    price: '22,99',
    rating: 4.5,
    reviews: 3890,
    tag: '',
    description: 'Deine Katze dreht durch. Du sitzt entspannt. Win-win.',
    features: ['Auto-Rotation', 'Timer 15/30 min', 'USB-C', 'Stilles Betrieb'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1478098711619-5ab0b478d6e6?w=400&h=400&fit=crop',
  },
  {
    slug: 'mini-bluetooth-lautsprecher',
    name: 'Mini BT Lautsprecher wasserdicht',
    category: 'Unter 20€',
    categorySlug: 'geschenke-20-euro',
    price: '17,99',
    rating: 4.3,
    reviews: 9210,
    tag: '',
    description: 'Duschen mit Soundtrack. IPX7 — überlebt auch das längste Konzert unter der Brause.',
    features: ['IPX7 wasserdicht', 'BT 5.3', '10h Akku', '360° Sound'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=400&fit=crop',
  },
  {
    slug: 'stickie-notes-leuchtend',
    name: 'Neon Haftnotizen 600 Stk.',
    category: 'Büro-Gadgets',
    categorySlug: 'buero-gadgets',
    price: '8,99',
    rating: 4.4,
    reviews: 4560,
    tag: '',
    description: '600 Haftnotizen in 6 Neonfarben. Damit niemand übersehen kann, was du dir gemerkt hast.',
    features: ['600 Stück', '6 Neonfarben', '3 Größen', 'Rückstandsfrei'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=400&h=400&fit=crop',
  },
  {
    slug: 'digitale-küchenwaage',
    name: 'Digitale Küchenwaage flach',
    category: 'Küchen-Gadgets',
    categorySlug: 'kuechen-gadgets',
    price: '12,95',
    rating: 4.6,
    reviews: 7120,
    tag: 'Bestseller',
    description: 'Auf 1g genau. Flach wie ein Blatt. Backen wie ein Profi.',
    features: ['1g Genauigkeit', 'Max. 5kg', 'LCD Display', 'Tara-Funktion'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400&h=400&fit=crop',
  },
  {
    slug: 'gaming-mauspad-xl',
    name: 'XL Gaming Mauspad mit RGB',
    category: 'Geschenke für Männer',
    categorySlug: 'geschenke-maenner',
    price: '19,99',
    rating: 4.8,
    reviews: 5530,
    tag: 'Gamer Pick',
    description: 'Mauspad in Schreibtischgröße. RGB inklusive. Weil Schreibtisch ohne Licht traurig ist.',
    features: ['90x40cm', '14 RGB-Modi', 'USB-C', 'Rutschfeste Basis'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=400&h=400&fit=crop',
  },
  {
    slug: 'aufblasbare-bierkühler',
    name: 'Aufblasbarer Bier-Pool-Kühler',
    category: 'Lustige Gadgets',
    categorySlug: 'lustige-gadgets',
    price: '14,99',
    rating: 4.6,
    reviews: 2870,
    tag: 'Sommer-Hit',
    description: 'Weil Bier kalt sein muss. Aufblasbarer Ring fürs Pool-Erlebnis. Fasst 6 Dosen.',
    features: ['Fasst 6 Dosen + Eis', 'PVC robust', 'Aufblasbar', 'Cuphalter integriert'],
    affiliateUrl: '#',
    image: 'https://images.unsplash.com/photo-1504279577054-acfeccf8fc52?w=400&h=400&fit=crop',
  },
]

export const guides: Guide[] = [
  {
    slug: 'beste-buero-gadgets-2024',
    title: 'Die 10 besten Büro-Gadgets',
    subtitle: 'Mehr Produktivität oder wenigstens bessere Ausreden.',
    readTime: '5 min',
    category: 'Büro-Gadgets',
    intro:
      'Ob Homeoffice-Held oder Open-Space-Überlebender — mit dem richtigen Zubehör wird jeder Arbeitstag ein bisschen erträglicher.',
    sections: [
      {
        heading: '1. Der unterschätzte Mini-Staubsauger',
        body: 'Klingt banal, verändert alles. Wer einmal mit dem Desktop-Staubsauger die Tastatur gereinigt hat, will nie wieder ohne.',
      },
      {
        heading: '2. Kaffee-Warmhalter — nicht verhandelbar',
        body: 'Kalter Kaffee macht schlechte Entscheidungen. Ein guter USB-Warmhalter kostet weniger als ein Mittagessen.',
      },
      {
        heading: '3. Ergonomische Mauspad-Kombis',
        body: 'Handgelenk dankt es. Chef merkt nichts. Win-win.',
      },
    ],
  },
  {
    slug: 'geschenke-maenner-die-alles-haben',
    title: 'Geschenke für Männer, die alles haben',
    subtitle: 'Spoiler: haben sie nicht. Hier sind die Lücken.',
    readTime: '7 min',
    category: 'Geschenke für Männer',
    intro:
      'Jedes Jahr dasselbe Drama. Jedes Jahr "er hat doch schon alles." Wir haben uns durch hunderte Produkte gewühlt.',
    sections: [
      {
        heading: 'Der Pocket-Projektor: Kino in der Hosentasche',
        body: 'Für den Mann, der Filme mag aber Netflix-Abo "zu teuer" findet. Ein Projektor macht ihn zum Regisseur seines Wohnzimmerkinos.',
      },
      {
        heading: 'Das Multitool: Klassiker neu gedacht',
        body: 'Nein, wir meinen nicht den Schraubenzieher-Set von 2003. Die neuen Modelle haben Bits, Karten-Format und passen in jede Hosentasche.',
      },
    ],
  },
]

export function getCategoryBySlug(slug: string): Category | undefined {
  return categories.find((c) => c.slug === slug)
}

export function getProductBySlug(slug: string): Product | undefined {
  return products.find((p) => p.slug === slug)
}

export function getProductsByCategory(categorySlug: string): Product[] {
  return products.filter((p) => p.categorySlug === categorySlug)
}

export function getGuideBySlug(slug: string): Guide | undefined {
  return guides.find((g) => g.slug === slug)
}
