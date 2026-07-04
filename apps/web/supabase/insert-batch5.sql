-- ============================================================
-- Batch 5 — 18 Produkte (9 vollständig, 9 Platzhalter)
-- Platzhalter = ASIN im Namen → im Table Editor nachpflegen
-- is_published = false → manuell reviewen vor Veröffentlichung
-- ============================================================

insert into products (category_id, slug, name, tagline, affiliate_url, is_published, is_featured) values

  -- ── VOLLSTÄNDIG GESCANNTE PRODUKTE ────────────────────────────────────────

  -- 1. heat it Insektenstichheiler
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'heat-it-insektenstichheiler-smartphone',
    'heat it Insektenstichheiler',
    'Chemiefreier Juckreiz-Stopper — konzentrierte Wärme direkt vom Smartphone.',
    'https://www.amazon.de/dp/B0D26GWWD1?coliid=I3TZJ1OZR01GOH&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=5d73266c510ddf6f58e3e6c0308b5331&ref_=as_li_ss_tl',
    false, false
  ),

  -- 3. CASO HW 660 Heißwasserspender
  (
    (select id from categories where slug = 'kuechen-gadgets'),
    'caso-hw660-heisswasserspender',
    'CASO HW 660 Heißwasserspender',
    'Heißes Wasser in Sekunden — bis zu 50 % energiesparender als ein Wasserkocher.',
    'https://www.amazon.de/dp/B0886SSPYB?coliid=I3KOOEQW2H3B1&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=1632a4fd744ceeeaa100d04dd250b959&ref_=as_li_ss_tl',
    false, false
  ),

  -- 5. HealthRelife 3D Massagesessel
  (
    (select id from categories where slug = 'geschenke-maenner'),
    'healthrelife-3d-massagesessel-sl-schiene',
    'HealthRelife 3D Massagesessel SL-Schiene',
    'Ganzkörpermassage mit 135 cm SL-Schiene, 28 Airbags, Wärme und Bluetooth.',
    'https://www.amazon.de/dp/B0G46CRRG8?coliid=I30QOR3CTYBOBU&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=e92194de96ee3faef835cc8dc39c3609&ref_=as_li_ss_tl',
    false, false
  ),

  -- 7. GHome Smart WLAN-Steckdose 4er Pack
  (
    (select id from categories where slug = 'buero-gadgets'),
    'ghome-smart-wlan-steckdose-4er-pack',
    'GHome Smart WLAN-Steckdose 4er Pack',
    'Alexa- & Google-Home-kompatibel mit Strommessung und App-Steuerung.',
    'https://www.amazon.de/dp/B0D3VBRSCF?coliid=I1296XL3ND92OZ&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=52d39e0eb313fac0b02ee35f1ff6c752&ref_=as_li_ss_tl',
    false, false
  ),

  -- 8. Ferrofluid Sound-Visualizer
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'ferrofluid-sound-visualizer-lampe',
    'Ferrofluid Sound-Visualizer Lampe',
    'Tanzende Ferrofluid-Lampe die im Takt der Musik mit bunten Lichtern leuchtet.',
    'https://www.amazon.de/dp/B0DFM94J1J?coliid=IH2QVUGQNJ07S&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=d97f6bc4e9c2df9d8b185addd2b73c5b&ref_=as_li_ss_tl',
    false, true
  ),

  -- 10. Plaud Note Pro KI-Diktiergerät
  (
    (select id from categories where slug = 'buero-gadgets'),
    'plaud-note-pro-ki-diktiergeraet',
    'Plaud Note Pro KI-Diktiergerät',
    'KI-Aufnahmegerät mit automatischer Transkription, Zusammenfassung und 50h Kapazität.',
    'https://www.amazon.de/dp/B0FXL8WZQN?coliid=I1GV1KCLDQFLR4&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=9c85be874252d042b1029ac363e6a844&ref_=as_li_ss_tl',
    false, true
  ),

  -- 11. Teenage Engineering TP-7
  (
    (select id from categories where slug = 'buero-gadgets'),
    'teenage-engineering-tp7-audio-recorder',
    'Teenage Engineering TP-7 Audio Recorder',
    'Portabler Profi-Recorder mit USB-C Audio, Bluetooth, Mikrofon und 128 GB Speicher.',
    'https://www.amazon.de/dp/B0F7Y1WRJS?coliid=IDVPEKYNLZAV5&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=2f4770fa2b206098ae50b4f2902ddc05&ref_=as_li_ss_tl',
    false, true
  ),

  -- 16. GiiKER Super Slide Puzzle
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'giiker-super-slide-puzzle',
    'GiiKER Super Slide Puzzle',
    'Elektronisches Schiebepuzzle mit über 500 Rätseln — Denkspiel für Kinder und Erwachsene.',
    'https://www.amazon.de/dp/B0D45SSNVS?coliid=I1T2XIWXMM5F5V&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=4aebb728bc46d7dc21b3c82c455cc14c&ref_=as_li_ss_tl',
    false, false
  ),

  -- 17. DealKits 3D Labyrinth-Würfel
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'dealkit-3d-labyrinth-wuerfel',
    'DealKits 3D Labyrinth-Würfel',
    'Interaktives 3D-Puzzle mit rollenden Kugeln für kniffliges Gehirntraining.',
    'https://www.amazon.de/dp/B0G6Z2CY2Y?coliid=I25GSX2XJMERGA&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=0f352e40ea81c4d6a92321d3ea343c94&ref_=as_li_ss_tl',
    false, false
  ),

  -- ── PLATZHALTER — Name & Kategorie im Table Editor ergänzen ──────────────

  -- 2. ASIN B0DS8SK65N
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0ds8sk65n',
    '[Name ergänzen] B0DS8SK65N',
    null,
    'https://www.amazon.de/dp/B0DS8SK65N?coliid=I8HG4X98ZHRN8&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=1c84dd54fc941d6a82e11e01cb128fa4&ref_=as_li_ss_tl',
    false, false
  ),

  -- 4. ASIN B0BXYHWBS7
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0bxyhwbs7',
    '[Name ergänzen] B0BXYHWBS7',
    null,
    'https://www.amazon.de/dp/B0BXYHWBS7?coliid=I7XYGB8YWYFJ3&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=11eb8ed4e8992e527fcadbad8f64c68e&ref_=as_li_ss_tl',
    false, false
  ),

  -- 6. ASIN B0G717152X
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0g717152x',
    '[Name ergänzen] B0G717152X',
    null,
    'https://www.amazon.de/dp/B0G717152X?coliid=I832TLJCUI3SF&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=4d1ffa9d2f4d1e79e1398af376ee2beb&ref_=as_li_ss_tl',
    false, false
  ),

  -- 9. ASIN B0DHYZB1KD
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0dhyzb1kd',
    '[Name ergänzen] B0DHYZB1KD',
    null,
    'https://www.amazon.de/dp/B0DHYZB1KD?coliid=I3RBNM3KX2E9NI&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=dd9e4b998ffe230fa5a79278f397763c&ref_=as_li_ss_tl',
    false, false
  ),

  -- 12. ASIN B0D72Y7XNT
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0d72y7xnt',
    '[Name ergänzen] B0D72Y7XNT',
    null,
    'https://www.amazon.de/dp/B0D72Y7XNT?coliid=ID2ZNDY4ZCBMG&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=dec57a409fe96748fa5eb9aafb04adba&ref_=as_li_ss_tl',
    false, false
  ),

  -- 13. ASIN B0GLWVNH19
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0glwvnh19',
    '[Name ergänzen] B0GLWVNH19',
    null,
    'https://www.amazon.de/dp/B0GLWVNH19?coliid=I250ROFOI9GVGM&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=e69b65261a4821b85eaa20ed14cc4a29&ref_=as_li_ss_tl',
    false, false
  ),

  -- 14. ASIN B06X3WN5FF
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b06x3wn5ff',
    '[Name ergänzen] B06X3WN5FF',
    null,
    'https://www.amazon.de/dp/B06X3WN5FF?coliid=I14N3SCWKGWNTT&colid=1VQK9PCRQEC5P&th=1&linkCode=ll2&tag=geeklist-21&linkId=366fda140ee4c3cc10eed7fb78d039e7&ref_=as_li_ss_tl',
    false, false
  ),

  -- 15. ASIN B09FMVDHDM
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b09fmvdhdm',
    '[Name ergänzen] B09FMVDHDM',
    null,
    'https://www.amazon.de/dp/B09FMVDHDM?coliid=IOK811JT1M3R7&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=950a09d702e23ccaca129270583884a2&ref_=as_li_ss_tl',
    false, false
  ),

  -- 18. ASIN B0DHSDWG2R
  (
    (select id from categories where slug = 'lustige-gadgets'),
    'asin-b0dhsdwg2r',
    '[Name ergänzen] B0DHSDWG2R',
    null,
    'https://www.amazon.de/dp/B0DHSDWG2R?coliid=I3PMS3IIA2BK0D&colid=1VQK9PCRQEC5P&psc=1&linkCode=ll2&tag=geeklist-21&linkId=26daaff69e17c08be21bb86db7fe5e3b&ref_=as_li_ss_tl',
    false, false
  )

on conflict (slug) do nothing;
