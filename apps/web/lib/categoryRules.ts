export type ShopPersona = 'babo' | 'queen' | 'miniboss' | 'wellness' | 'unknown'

export type CategoryRule = {
  persona: ShopPersona
  main_category: string
  sub_category: string
  keywords: string[]
}

// Rules are evaluated in ORDER — more specific rules must come BEFORE broader ones.
// Keywords must be at least 2 words or very specific (no single-word false-positives).
export const categoryRules: CategoryRule[] = [

  // ══════════════════════════════════════════════════════════════════════════
  // BABO / GAMING
  // ══════════════════════════════════════════════════════════════════════════

  // Tabletop & Board Games (most specific first)
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'tabletop',
    keywords: [
      'speed cube', 'speed-cube', 'speedcube', 'gan cube', 'gan 356', 'gan i4',
      'smart cube', 'zauberwürfel magnetisch',
      'dungeon master', 'spielleiterschirm', 'dnd starter', 'dnd tabletop',
      'initiative tracker', 'tabletop miniatur', 'army painter', 'wet palette',
      'rpg charakter', 'charakterbogen', 'mtg playmat', 'magic playmat',
      'escape room detektiv', 'krimispiel escape',
      'schachuhr', 'chess clock',
      'faltbares wüfelbrett', 'würfelbrett faltbar', 'faltbare wuerfelbretter',
      'puzzle board schubladen', 'puzzlematte puzzles',
      'huzzle cast', 'metall knobelpuzzle', 'knobelpuzzle metall',
      'shashibo', 'formwechsel box magnetisch',
      'magnetisches schachspiel', 'reise schachspiel klappbar',
      'ki-go brett', 'sense robot', 'schachroboter roboterarm',
      'go brett roboter',
      'sammelkarten aufbewahrung', 'karten aufbewahrungsbox',
      'comic backing boards', 'backing boards acid',
      'miniaturen transportkoffer', 'miniatur koffer',
    ],
  },

  // Collectibles & LEGO
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'collectibles',
    keywords: [
      'funko pop', 'funko darth',
      'lego icons star trek', 'lego star trek', 'uss enterprise lego',
      'lego harry potter quidditch', 'lego quidditch',
      'lego technic ferrari', 'lego f1 rennauto',
      'lego fifa', 'lego fussball',
      'nintendo spardose', 'game boy spardose',
      'nintendo classic mini', 'snes mini', 'classic mini snes',
    ],
  },

  // Retro Gaming Setup
  {
    persona: 'babo',
    main_category: 'gaming',
    sub_category: 'retro-setup',
    keywords: [
      'retro spielekonsole', 'retro konsole', 'mad monkey konsole', 'mad monkey retro',
      'arcade joystick', 'mayflash joystick', 'f300 arcade',
      'controller staender', 'controller ständer', 'kytok controller',
      'gaming haengevitrine', 'haengevitrine regal', 'gaming vitrine',
      'yusing regal', 'gaming hängeregal',
      'ps5 tragetasche', 'ps5 horizontale tasche',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // BABO / TECH
  // ══════════════════════════════════════════════════════════════════════════

  // DIY / 3D Puzzles / Basteln
  {
    persona: 'babo',
    main_category: 'tech',
    sub_category: 'diy',
    keywords: [
      '3d holzpuzzle', 'holzpuzzle 3d', 'rokr holzpuzzle', 'holzpuzzle raumfaehre',
      'raumfaehre modellbausatz', 'modellbausatz holz',
      'ameisenfarm acryl', 'ameisenfarm set',
    ],
  },

  // Gadgets / Electronics
  {
    persona: 'babo',
    main_category: 'tech',
    sub_category: 'gadgets',
    keywords: [
      'led schreibtischlampe gestensteurung', 'schreibtischlampe gestensteuerung',
      'adressierbarer rgb led streifen', 'ws2812b streifen', 'rgb led streifen adressierbar',
      'esp32 nodemcu', 'esp32 wifi bluetooth', 'nodemcu dev board',
      'iFixit antistatik', 'antistatik matte esd', 'esd matte faltbar',
      'messschieber edelstahl', 'digitaler messschieber',
      'filament aufbewahrungsbox', 'filament box 3d',
      'lupe mit licht standfuss', 'lupe mit standfuss',
      'ueberwachungskamera wlan', '4k mini kamera wlan', 'mini kamera nachtsicht',
      'maehroboter lidar', 'mammotion luba', 'maehroboter awd',
      'plasmakugel beruehlungsempfindlich', 'plasmakugel 8 zoll',
      'skullcandy crusher', 'crusher anc kopfhoerer',
      'sternkarte planeten', 'drehbare sternkarte', 'kosmos sternkarte',
      'periodensystem echten elementen', 'periodensystem acryl',
    ],
  },

  // Schreibtisch-Setup
  {
    persona: 'babo',
    main_category: 'tech',
    sub_category: 'setup',
    keywords: [
      'hoehenverstellbarer schreibtisch aufsatz', 'schreibtisch aufsatz höhenverstellbar',
      'dicmky schreibtisch', 'vivo stehpult', 'hoehenverstellbares stehpult',
      'ergonomische kabellose maus', 'tecknet maus bluetooth',
      'programmierbare led laufschrift', 'led laufschrift tafel', 'jdvootd laufschrift',
      'bluetooth klappbare tastatur', 'protoarc tastatur', 'klappbare bluetooth tastatur',
      'kabelmanagement schreibtisch', 'joyroom kabelmanagement',
      'usb c adapter anker', 'anker usb adapter',
      'magsafe wireless ladestation', 'mfi magsafe', 'magsafe 15w',
      'wuerfel timer countdown', 'ticktime wuerfel', 'ticktime timer',
      'spiral tastaturkabel', 'coiled usb kabel', 'custom tastaturkabel',
      'wiederverwendbares notizbuch', 'rocketbook notizbuch',
      'kabeltasche elektronik organizer', 'edc organizer reise',
      'nfc qr aufsteller', 'instagram schild nfc',
      'laptop staender hoehenverstellbar', 'laptop staender drehbar',
      'leselampe buch klemme', 'klemme leselampe',
      'elektrischer anspitzer', 'anspitzer behaelter',
      'allwetter notizbuch', 'rite in the rain', 'rite rain notizbuch',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // BABO / LIFESTYLE
  // ══════════════════════════════════════════════════════════════════════════

  // Gadgets & Fun
  {
    persona: 'babo',
    main_category: 'lifestyle',
    sub_category: 'gadgets',
    keywords: [
      'bierbrauset pils', 'bierbrauset 5 liter', 'bier brauen set',
      'bug-a-salt', 'salzgewehr fliegen', 'fliegenjager salzgewehr',
      'bug beam insektenfalle', 'insektenfalle uv',
      'snoop dogg kochbuch', 'from crook to cook',
      'toilettenbuerste gag', 'toilettenbürste geschenk',
      'stress baelle quetschball', 'quetschball set',
      'popcorn maschine retro', 'vintage popcorn cart',
      'weinflaschenhalter totenkopf', 'totenkopf weinhalter',
      'cocktailshaker set', 'empation cocktailshaker', 'barkeeper set',
      'wackelfigur armaturenbrett', 'wackelfigur auto', 'kiayoo wackelfigur',
      'brillenhalter auto sonnenblende', 'joyroom brillenhalter',
      'zigarettenanzuender schnellladegeraet', 'kfz schnellladegeraet',
      'led leuchtbrille party', 'aufladbare led brille',
      'tosy flying disc', 'leuchtfrisbee rgb', 'flying disc 108 led',
    ],
  },

  // Fashion
  {
    persona: 'babo',
    main_category: 'lifestyle',
    sub_category: 'fashion',
    keywords: [
      'stranger things lucas t-shirt', 'stranger things shirt offiziell',
      'masters of the universe t-shirt', 'he-man shirt 80er',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // BABO / OUTDOOR
  // ══════════════════════════════════════════════════════════════════════════

  // Survival & EDC
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'survival',
    keywords: [
      'paracord armband', 'paracord survival armband', 'azengear paracord',
      'feuerstahl xxl', 'tre feuerstahl', 'feuerstahl survival',
      'multifunktionsmesser rostfrei', 'trekline messer', 'trekline multifunktionsmesser',
      'wasserdichte handyhuelle unterwasser', 'joto handyhuelle unterwasser',
      'ultraleichter campingstuhl', 'sportneer campingstuhl', 'faltbarer campingstuhl',
      'aufladbare campinglaterne', 'suboos campinglaterne', 'campinglaterne aufladbar',
      'business rucksack wasserdicht', 'fenree rucksack', 'rucksack usb anschluss',
      'ultraleichter faltbarer rucksack', 'faltbarer rucksack 20l',
    ],
  },

  // Camping / Outdoor Equipment
  {
    persona: 'babo',
    main_category: 'outdoor',
    sub_category: 'camping',
    keywords: [
      'wurfzelt personen sekunden', 'wurfzelt 3 personen', 'wurfzelt 4 personen',
      'tipi zelt personen stehoehe', 'tipi zelt 4 personen',
      'solarpanel faltbar camping', 'einhell solarpanel', 'solarpanel 40w',
      'wasserdichte dry bag', 'dry bag 5l', 'dry bag 30l',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // QUEEN / KUECHE
  // ══════════════════════════════════════════════════════════════════════════

  {
    persona: 'queen',
    main_category: 'kueche',
    sub_category: 'gadgets',
    keywords: [
      'asdirne pizzaschneider', 'pizzaschneider edelstahl',
      'pastail walfoermiges nudelsieb', 'nudelsieb wal', 'peleg nudelsieb',
      'diycut taco staender', 'taco ständer', 'taco staender',
      'katie cat suppenkelle', 'suppenkelle katze', 'schwarze katze kelle',
      'one piece ramen bowl', 'ramen bowl keramik',
      'aeropress go', 'aeropress kaffeemaschine', 'tragbare kaffeemaschine',
      'weinbeluefter dekanter', 'weinbeluefter ausgiesser', 'wein dekanter ausgiesser',
      'elektrischer wein dekanter', '5 in 1 dekanter',
      'snagger snackspender', 'snackspender saubere haende',
      'bialetti moka stranger', 'moka express stranger',
      'harry potter selbstruerhrende tasse', 'selbstrüehrende tasse',
      'lunchbox kinder faecher', 'lunchbox faechern',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // QUEEN / LIFESTYLE
  // ══════════════════════════════════════════════════════════════════════════

  // Deko & Home
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'deko',
    keywords: [
      'schwebendes buecherregal', 'fentec buecherregal', 'schwebend buecherregal',
      'baby groot blumentopf', 'groot blumentopf figur',
      'aquarium deko landschaft', 'aquarium kunststoff deko',
      'yoga gartenzwerg buddha', 'gartenzwerg meditation',
      'lego botanicals japanischer', 'lego ahorn botanicals',
      'lego botanicals orchidee', 'lego orchidee kunstpflanze',
      'haustier kamera 360', 'tierkamera app',
      'petkit futterautomat kamera', 'futterautomat ki',
      'welpen usb ladekabel', 'hund ladekabel design', 'welpen kabel design',
      'sticker set neon vinyl', 'vinyl sticker set wasserfest',
      'ramen katze kawaii', 'ramen katze shirt', 'kawaii ramen t-shirt',
      'astronaut sternenhimmel projektor', 'sternenhimmel projektor galaxy',
    ],
  },

  // Harry Potter / Fandom
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'harry-potter',
    keywords: [
      'lamy safari gryffindor', 'harry potter fueller', 'gryffindor fueller',
      'harry potter nachtwecker', 'harry potter lcd wecker',
    ],
  },

  // Mode / Fashion
  {
    persona: 'queen',
    main_category: 'lifestyle',
    sub_category: 'mode',
    keywords: [
      'reflektierende holographic windbreaker', 'holographic windbreaker newl',
      'findchic edelstahl drehring', 'drehring edelstahl findchic',
      'nachfuellbarer parfuemzerstaeuber', 'parfuemzerstaeuber reise', 'toureal parfuemzerstaeuber',
      'ita bag kawaii rucksack', 'kawaii rucksack display fenster',
      'retro buchumschlaege blumen', 'buchumschlaege blumen taschenbuch',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // QUEEN / BEAUTY
  // ══════════════════════════════════════════════════════════════════════════

  {
    persona: 'queen',
    main_category: 'beauty',
    sub_category: 'pflege',
    keywords: [
      'cosrx pdrn exosome', 'cosrx maske skinplaning', 'pdrn glaze mask',
      'ninabella haarbuerste', 'haarbuerste ohne ziepen', 'bürste ohne ziepen',
      'uv led nagellampe', 'gel naegel timer', 'nagellampe gel',
      'japanische gelstifte', 'gelstifte 0.5mm', 'gelstifte 5er',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // QUEEN / GESCHENKE
  // ══════════════════════════════════════════════════════════════════════════

  // Lehrer-Geschenke
  {
    persona: 'queen',
    main_category: 'geschenke',
    sub_category: 'lehrer',
    keywords: [
      'lehrergeschenk stofftasche', 'lehrergeschenk baumwollbeutel',
      'lehrergeschenk abschiedsgeschenk', 'lehrer abschluss geschenk',
      'i teach muggles jutebeutel', 'muggles jutebeutel',
      'klassenarbeit jutebeutel', 'klassenarbeit spruch beutel',
    ],
  },

  // Personalisiert
  {
    persona: 'queen',
    main_category: 'geschenke',
    sub_category: 'personalisiert',
    keywords: [
      'personalisiertes malen nach zahlen', 'malen nach zahlen eigenes foto',
      'personalisiertes foto puzzle', 'foto puzzle 1000 teile',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // MINIBOSS / SPIELZEUG
  // ══════════════════════════════════════════════════════════════════════════

  // Lernen & STEM
  {
    persona: 'miniboss',
    main_category: 'spielzeug',
    sub_category: 'lernen',
    keywords: [
      'experimentierset kinder', 'kinder 100 experimente', 'stem experimente',
      'magnetische bausteine kinder', 'magnetische bausteine 150 teile',
      'digitales mikroskop kinder', 'mikroskop 1000 fach kinder',
      'mx2 digitales mikroskop', 'kinder mikroskop 1000x',
      'makeblock codey rocky', 'codey rocky programmierbarer',
      'programmierbarer roboter kinder',
      'bitzee disney interaktiv', 'bitzee digital haustier',
    ],
  },

  // Tierspielzeug
  {
    persona: 'miniboss',
    main_category: 'spielzeug',
    sub_category: 'tiere',
    keywords: [
      'interaktives hundespielzeug intelligenz', 'hundespielzeug intelligenz',
      'regenbogen katzenballe', 'katzenbälle 24er set',
      'vogelspielzeug nymphensittich', 'vogelspielzeug wellensittich',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // MINIBOSS / GAMING
  // ══════════════════════════════════════════════════════════════════════════

  // Collectibles & Nachtlichter
  {
    persona: 'miniboss',
    main_category: 'gaming',
    sub_category: 'collectibles',
    keywords: [
      'deadpool spardose bueste', 'deadpool spardose marvel',
      'spider-man spardose', 'spider man spardose 20cm',
      'minecraft schwein spardose', 'minecraft spardose',
      'personalisierte holz spardose', 'holz spardose kinder',
      'elektronische atm spardose', 'atm spardose kinder',
      'minecraft fuchs nachtlicht', 'minecraft nachtlicht offiziell',
      'yuandian dodo duck nachtlicht', 'dodo duck led nachtlicht',
      'nelux planet wolke nachtlicht', 'planet wolke nachtlicht 3er',
      'fifa world cup ballers minifiguren', 'fifa ballers minifiguren',
      'wer ist es marvel', 'marvel wer ist es brettspiel',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // MINIBOSS / SPASS
  // ══════════════════════════════════════════════════════════════════════════

  // Party & Indoor Fun
  {
    persona: 'miniboss',
    main_category: 'spass',
    sub_category: 'party',
    keywords: [
      'huch what kartenspiel', 'what kartenspiel deutsch',
      'talking tables partyspiel', 'partyspiel geburtstag kinder',
      'hitster musikquiz', 'musikquiz partyspiel',
      'ubergames riesenwackelturm', 'riesenwackelturm jumbo', 'jumbo jenga',
      'costway tischkicker', 'tischkicker kickertisch',
      'derayee schaumstoff wasserpistole', 'schaumstoff wasserpistole',
      'ckb retro kaugummi maschine', 'retro kaugummi maschine',
      'suessigkeitenspender retro', 'süßigkeitenspender kaugummi',
    ],
  },

  // Outdoor Fun
  {
    persona: 'miniboss',
    main_category: 'spass',
    sub_category: 'outdoor',
    keywords: [
      'tosy flying disc wiederaufladbar', 'flying disc wiederaufladbar',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // WELLNESS / FITNESS
  // ══════════════════════════════════════════════════════════════════════════

  {
    persona: 'wellness',
    main_category: 'fitness',
    sub_category: 'sport',
    keywords: [
      'sprossenwand klimmzugstange', 'sprossenwand erwachsene',
      'power tower klimmzugstange', 'power tower faltbar',
      'tennis trainer solo', 'tennis trainingsgeraet solo',
      'powerball gyro handtrainer', 'gyro handtrainer original',
      'hyako massagepistole', 'massagepistole triggerpunkt',
      'caspor akupressurmatte', 'akupressurmatte ganzkoerper',
      'lifepro infrarot saunadecke', 'infrarot saunadecke',
      'musicozy bluetooth schlafkopfhoerer', 'bluetooth schlafkopfhoerer',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // WELLNESS / BEAUTY
  // ══════════════════════════════════════════════════════════════════════════

  {
    persona: 'wellness',
    main_category: 'beauty',
    sub_category: 'pflege',
    keywords: [
      'porseme ultraschall luftbefeuchter', 'ultraschall luftbefeuchter farbwechsel',
      'mr bear family bartoeel', 'bartoeel tiki punch', 'mr bear bartoeel',
      'fusselroller tierhaare', 'fusselroller 540 blatt',
      'handventilator akku aufladbar', 'handventilator mini aufladbar',
      'white noise machine baby', 'einschlafhilfe baby machine',
      'cream noise machine baby', 'noise machine baby tragbar',
    ],
  },

  // ══════════════════════════════════════════════════════════════════════════
  // WELLNESS / OUTDOOR
  // ══════════════════════════════════════════════════════════════════════════

  {
    persona: 'wellness',
    main_category: 'outdoor',
    sub_category: 'camping',
    keywords: [
      'wurfzelt 2 sekunden', 'wurfzelt sekundenzelt',
      'tipi zelt stehoehe', 'tipi familienzelt',
      'einhell solar faltbar', 'solarpanel camping faltbar',
      'dry bag wasserdicht', 'wasserdichte dry bag',
      'ultraleichter faltbarer rucksack outdoor',
    ],
  },
]
