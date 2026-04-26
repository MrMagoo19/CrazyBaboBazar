export type ShopPersona = 'babo' | 'queen' | 'miniboss' | 'wellness' | 'unknown'

export type CategoryRule = {
  persona: ShopPersona
  main_category: string
  sub_category: string
  keywords: string[]
}

export const categoryRules: CategoryRule[] = [
  // ── BABO: Gaming ──────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'setup',
    keywords: ['gaming', 'mauspad', 'led schreibtisch', 'rgb', 'mousepad', 'controller ständer', 'gaming regal'],
  },
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'retro',
    keywords: ['retro konsole', 'spielekonsole', 'arcade', 'joystick', 'old school games'],
  },
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'deko',
    keywords: ['laufschrift', 'led tafel', 'neon schild', 'lichtschwert', 'star wars'],
  },

  // ── BABO: Outdoor & Survival ──────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'survival',
    keywords: ['paracord', 'feuerstahl', 'survival', 'messer', 'multifunktionsmesser', 'feuer'],
  },
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'camping',
    keywords: ['camping', 'campingstuhl', 'laterne', 'campinglampe', 'hängematte', 'outdoor lampe', 'ultraleicht'],
  },
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'wassersport',
    keywords: ['wasserpistole', 'wassersport', 'angelzubehör', 'angel', 'wasserfilter trinkflasche'],
  },

  // ── BABO: Auto ───────────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'auto',
    sub_category: 'technik',
    keywords: ['starthilfe', 'booster', 'powerbank auto', 'zigarettenanzünder', 'schnellladegerät auto', 'autoladegerät'],
  },
  {
    persona: 'babo',
    main_category: 'auto',
    sub_category: 'zubehör',
    keywords: ['autohalterung', 'brillenhalter auto', 'sonnenblende auto', 'armaturenbrett', 'wackelfigur auto'],
  },

  // ── BABO: Bar & Gadgets ───────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'bar',
    keywords: ['cocktailshaker', 'shaker', 'barkeeper', 'bar set', 'cocktail'],
  },
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'tech',
    keywords: ['fingerabdruck', 'schloss', 'powerbank', 'usb', 'bluetooth tastatur', 'klappbare tastatur', 'stehpult', 'schreibtisch aufsatz'],
  },
  {
    persona: 'babo',
    main_category: 'gadgets',
    sub_category: 'kurioses',
    keywords: ['totenkopf', 'skull', 'totenkopf weinhalter', 'wackelturm', 'jenga', 'inflatable', 'aufblasbar'],
  },

  // ── QUEEN: Küche ─────────────────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'werkzeug',
    keywords: ['pizzaschneider', 'spaghettimass', 'nudelsieb', 'nudelmaß', 'portionierer', 'mangoschneider', 'fruchthalter', 'küchenhelfer'],
  },
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'kurioses',
    keywords: ['taco ständer', 'ramen schüssel', 'wal', 'walförmig', 'anime küche', 'one piece'],
  },
  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'getränke',
    keywords: ['kaffeewarmer', 'tassenwarmer', 'eiswürfelform', 'eiswürfel', 'getränk'],
  },

  // ── QUEEN: Deko & Wohnen ─────────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'beleuchtung',
    keywords: ['sternenprojektor', 'sternenhimmel', 'mondlampe', 'mond deckenlampe', 'nachtlicht', 'planet', 'wolke lampe', 'dodo duck', 'schildkröte laterne', 'leuchtschild'],
  },
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'wohnen',
    keywords: ['schwebendes bücherregal', 'bücherregal', 'whiteboard', 'kontaktpapier', 'wanddekoration', 'schubladen ordnung', 'ordnungssystem'],
  },
  {
    persona: 'queen',
    main_category: 'deko',
    sub_category: 'pflanzen',
    keywords: ['terracotta', 'pflanzenbewässerung', 'bewässerung', 'blumen', 'pflanzen'],
  },

  // ── QUEEN: Mode & Lifestyle ───────────────────────────────────────────
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'mode',
    keywords: ['windbreaker', 'holographic', 'reflektierend', 'rfid blocker', 'parfümzerstäuber', 'reise parfüm', 'drehring', 'ring'],
  },
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'reise',
    keywords: ['rucksack', 'reise', 'reiserucksack', 'wasserdicht rucksack', 'handyhülle unterwasser', 'wasserdichte hülle'],
  },

  // ── WELLNESS: Entspannung & Fitness ──────────────────────────────────
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'massage',
    keywords: ['massagepistole', 'massage', 'nackenmassage', 'akupressurmatte', 'igelball', 'faszienrolle', 'triggerpunkt'],
  },
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'schlaf',
    keywords: ['schlafkopfhörer', 'bluetooth schlaf', 'schlafmaske', 'meditationskissen', 'yoga kissen'],
  },
  {
    persona: 'wellness',
    main_category: 'entspannung',
    sub_category: 'sauna',
    keywords: ['saunadecke', 'infrarot', 'infrarotsauna'],
  },
  {
    persona: 'wellness',
    main_category: 'fitness',
    sub_category: 'yoga',
    keywords: ['trainingsrad', 'yoga', 'yogarad', 'ab roller'],
  },
  {
    persona: 'wellness',
    main_category: 'fitness',
    sub_category: 'beauty',
    keywords: ['eisroller', 'gesicht pflege', 'hautpflege', 'beauty', 'luftbefeuchter', 'ultraschall befeuchter'],
  },

  // ── MINIBOSS: Spaß & Spiele ───────────────────────────────────────────
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'party',
    keywords: ['partyspiel', 'kartenspiel', 'what kartenspiel', 'gesellschaftsspiel', 'familien spiel', 'tischkicker', 'shuffleboard'],
  },
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'draussen',
    keywords: ['wasserpistole', 'flying disc', 'wurfscheibe', 'outdoor spiel', 'schaumstoff'],
  },
  {
    persona: 'miniboss',
    main_category: 'spiele',
    sub_category: 'wuerfel',
    keywords: ['würfelturm', 'würfel', 'lcd würfel', 'elektronischer würfel', 'brettspiel', 'unlock'],
  },
  {
    persona: 'miniboss',
    main_category: 'deko',
    sub_category: 'kinderzimmer',
    keywords: ['nachtlicht kinderzimmer', 'led nachtlicht jugend', 'jugendzimmer', 'sterne projektor kind', 'ente pool', 'aufblasbare ente'],
  },
  {
    persona: 'miniboss',
    main_category: 'gadgets',
    sub_category: 'spass',
    keywords: ['kaugummi maschine', 'süßigkeitenspender', 'retro spender', 'wackelfigur'],
  },

  // ── Shared: Geschenke ─────────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'geschenke',
    sub_category: 'maenner',
    keywords: ['geschenk männer', 'männergeschenk', 'pizza socken', 'socken geschenk', 'kondome geschenk', 'einhorn kondome', 'lichtschwert'],
  },
  {
    persona: 'queen',
    main_category: 'geschenke',
    sub_category: 'frauen',
    keywords: ['geschenk frauen', 'frauengeschenk', 'foto kalender', 'personalisierter kalender'],
  },
  {
    persona: 'miniboss',
    main_category: 'geschenke',
    sub_category: 'kids',
    keywords: ['geschenk kinder', 'kindergeschenk', 'spielzeug', 'kinderspiel'],
  },

  // ── BÜRO: Cross-Persona ───────────────────────────────────────────────
  {
    persona: 'babo',
    main_category: 'buero',
    sub_category: 'setup',
    keywords: ['kabelmanagement', 'schreibtisch organizer', 'bildschirmhalter', 'monitor halter', 'usb hub', 'kabel organizer', 'magsafe', 'smartphone ständer'],
  },
  {
    persona: 'babo',
    main_category: 'buero',
    sub_category: 'produktivitaet',
    keywords: ['timer', 'würfel timer', 'countdown', 'whiteboard', 'maus bluetooth', 'ergonomisch', 'ticktime'],
  },
]
