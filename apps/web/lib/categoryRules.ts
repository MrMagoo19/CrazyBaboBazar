export type ShopPersona = 'babo' | 'queen' | 'miniboss' | 'wellness' | 'unknown'

export type CategoryRule = {
  persona: ShopPersona
  main_category: string
  sub_category: string
  keywords: string[]
}

// Rules are evaluated in ORDER — more specific rules must come BEFORE broader ones.
export const categoryRules: CategoryRule[] = [

  // ── WELLNESS: Spezifisch zuerst ────────────────────────────────────────
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'sauna',
    keywords: ['saunadecke', 'infrarotsauna', 'infrarot sauna', 'infrarot decke', 'lifepro'],
  },
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'massage',
    keywords: ['massagepistole', 'massagegeraet', 'nackenmassage', 'akupressurmatte', 'igelball', 'faszienrolle', 'triggerpunkt'],
  },
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'schlaf',
    keywords: ['schlafkopfhoerer', 'schlafkopfhörer', 'bluetooth schlaf', 'meditationskissen', 'yogakissen'],
  },
  {
    persona: 'wellness',
    main_category: 'fitness',
    sub_category: 'yoga',
    keywords: ['trainingsrad', 'yoga rad', 'ab roller', 'yogarad'],
  },
  {
    persona: 'wellness',
    main_category: 'fitness',
    sub_category: 'beauty',
    keywords: ['eisroller gesicht', 'gesichtspflege', 'hautpflege roller', 'luftbefeuchter', 'ultraschall luftbefeuchter', 'porseme'],
  },

  // ── MINIBOSS: Spiele (spezifisch) ─────────────────────────────────────
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'party',
    keywords: ['partyspiel', 'kartenspiel', 'gesellschaftsspiel', 'familienspiel', 'tischkicker', 'shuffleboard', 'jenga', 'wackelturm', 'riesenwackelturm'],
  },
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'draussen',
    keywords: ['wasserpistole', 'schaumstoff pistole', 'flying disc', 'wurfscheibe'],
  },
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'wuerfel',
    keywords: ['wuerfelturm', 'würfelturm', 'lcd wuerfel', 'elektronischer wuerfel', 'unlock raetsel'],
  },
  {
    persona: 'miniboss',
    main_category: 'deko',
    sub_category: 'kinderzimmer',
    keywords: ['jugendzimmer', 'kinderzimmer nachtlicht', 'dodo duck', 'ente pool', 'aufblasbare ente', 'planet wolke nachtlicht'],
  },
  {
    persona: 'miniboss',
    main_category: 'gadgets',
    sub_category: 'spass',
    keywords: ['kaugummi maschine', 'suessigkeitenspender', 'süßigkeitenspender', 'retro spender'],
  },

  // ── QUEEN: Küche (spezifisch zuerst) ──────────────────────────────────
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'getränke',
    keywords: ['kaffeewaermer', 'kaffeewarmer', 'tassenwaermer', 'tassenwarmer', 'eiswuerfelform', 'eiswürfelform', 'eiswuerfel', 'eiswürfel'],
  },
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'werkzeug',
    keywords: ['pizzaschneider', 'spaghettimass', 'spaghettimass', 'nudelsieb', 'portionierer', 'mangoschneider', 'fruchthalter', 'küchenhelfer', 'kuchenhelfer'],
  },
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'kurioses',
    keywords: ['taco staender', 'taco ständer', 'ramen schuessel', 'ramen schüssel', 'walfoermiges', 'waltförmiges', 'one piece ramen'],
  },

  // ── QUEEN: Deko ────────────────────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'beleuchtung',
    keywords: ['sternenprojektor', 'sternenhimmel', 'mondlampe', 'mond deckenlampe', 'nachtlicht', 'leuchtschild', 'solarlaternen', 'planet nachtlicht'],
  },
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'wohnen',
    keywords: ['schwebendes buecherregal', 'schwebendes bücherregal', 'whiteboard kontaktpapier', 'wanddekoration', 'schubladen ordnung', 'ordnungssystem'],
  },
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'pflanzen',
    keywords: ['terracotta', 'pflanzenbewaesserung', 'pflanzenbewässerung', 'blumentopf bewaesserung'],
  },

  // ── QUEEN: Lifestyle ───────────────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'mode',
    keywords: ['windbreaker', 'holographic jacke', 'reflektierende jacke', 'rfid blocker', 'parfuemzerstaeuber', 'parfümzerstäuber', 'drehring edelstahl', 'findchic'],
  },
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'reise',
    keywords: ['business rucksack', 'reise rucksack', 'handyhuelle unterwasser', 'wasserdichte handyhuelle', 'reiserucksack', 'fenree'],
  },

  // ── BABO: Gaming ──────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'setup',
    keywords: ['gaming mauspad', 'rgb mauspad', 'led schreibtischpad', 'controller staender', 'controller ständer', 'gaming regal', 'haengevitrine gaming'],
  },
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'retro',
    keywords: ['retro spielekonsole', 'retro konsole', 'arcade joystick', 'mad monkey konsole'],
  },
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'deko',
    keywords: ['laufschrift tafel', 'led laufschrift', 'lichtschwert', 'star wars lichtschwert', 'eiswuerfelform todesstern', 'todesstern'],
  },

  // ── BABO: Outdoor & Survival ──────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'survival',
    keywords: ['paracord armband', 'feuerstahl', 'survival armband', 'multifunktionsmesser', 'trekline messer'],
  },
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'camping',
    keywords: ['campingstuhl', 'campinglaterne', 'camping laterne', 'haengematte', 'hängematte', 'ultraleichter stuhl', 'sportneer'],
  },
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'wassersport',
    keywords: ['wasserfilter trinkflasche', 'angelzubehoer', 'angelzubehör', 'angeln set'],
  },

  // ── BABO: Auto ───────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'auto',
    sub_category: 'technik',
    keywords: ['starthilfe powerbank', 'starthilfe booster', 'zigarettenanzuender schnellladegeraet', 'zigarettenanzünder ladegerät', 'kfz ladegeraet'],
  },
  {
    persona: 'babo',
    main_category: 'auto',
    sub_category: 'zubehör',
    keywords: ['autohalterung', 'magsafe autohalterung', 'brillenhalter auto', 'sonnenblende auto', 'armaturenbrett wackelfigur', 'wackelfigur auto'],
  },

  // ── BABO: Bar ─────────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'bar',
    keywords: ['cocktailshaker', 'cocktail set', 'barkeeper set', 'shaker set'],
  },

  // ── BABO: Büro ────────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'buero',
    sub_category: 'setup',
    keywords: ['kabelmanagement schreibtisch', 'kabel organizer schreibtisch', 'schreibtisch aufsatz', 'stehpult', 'hoehenverstellbar schreibtisch', 'magsafe ladestation', 'smartphone staender schreibtisch'],
  },
  {
    persona: 'babo',
    main_category: 'buero',
    sub_category: 'produktivitaet',
    keywords: ['wuerfel timer', 'würfel timer', 'countdown timer', 'ticktime', 'whiteboard selbstklebend', 'ergonomische maus', 'kabellose maus bluetooth'],
  },

  // ── BABO: Gadgets & Tech ──────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'tech',
    keywords: ['fingerabdruck schloss', 'bluetooth klappbare tastatur', 'usb c adapter', 'usb hub', 'anker adapter', 'powerbank 7000', 'magsafe wireless'],
  },
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'kurioses',
    keywords: ['weinflaschenhalter totenkopf', 'totenkopf halter', 'aufblasbare ente riesig', 'inflatable pool'],
  },

  // ── BABO: Geschenke ───────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'geschenke',
    sub_category: 'maenner',
    keywords: ['pizza socken', 'einhorn kondome', 'kondome geschenk', 'lichtschwert geschenk'],
  },

  // ── QUEEN: Geschenke ──────────────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'geschenke',
    sub_category: 'frauen',
    keywords: ['foto kalender', 'personalisierter kalender', 'jahreskalender personalisiert'],
  },

  // ── MINIBOSS: Geschenke ───────────────────────────────────────────────
  {
    persona: 'miniboss',
    main_category: 'geschenke',
    sub_category: 'kids',
    keywords: ['kindergeschenk', 'geschenk kinder', 'spielzeug kinder'],
  },
]
