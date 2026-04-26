-- ============================================================
-- MANUELLES AFFILIATE-URL FIX
-- Quelle: affiliate_mapping.ods (händisch ausgefüllt)
-- ============================================================

-- ============================================================
-- 1. PRODUKTE LÖSCHEN
-- ============================================================

delete from products where slug = 'fiyapoo-ergonomischer-smartphone-staender';
delete from products where slug = 'yoga-design-lab-trainingsrad';
delete from products where slug = 'mejasg-elektronischer-lcd-wuerfel';
delete from products where slug = 'wuerfelturm-lasergeaetzt-brettspiel';
delete from products where slug = 'asmodee-unlock-tombstone-express-raetselspiel';
delete from products where slug = 'lamicall-magsafe-autohalterung';
delete from products where slug = 'personalisierter-foto-kalender';

-- ============================================================
-- 2. AFFILIATE-URLS KORRIGIEREN
-- ============================================================

update products set affiliate_url = 'https://amzn.to/3OsG7UJ' where slug = 'jdvootd-programmierbare-led-laufschrift-tafel';
update products set affiliate_url = 'https://amzn.to/4tsZjkl' where slug = 'yusing-gaming-haengevitrine-regal';
update products set affiliate_url = 'https://amzn.to/4cH2WvL' where slug = 'empation-cocktailshaker-set';
update products set affiliate_url = 'https://amzn.to/41VG72x' where slug = 'newl-reflektierende-holographic-windbreaker';
update products set affiliate_url = 'https://amzn.to/3Qxky5Z' where slug = 'rfid-blocker-karte-neueste-technologie';
update products set affiliate_url = 'https://amzn.to/4vS9Mra' where slug = 'mfi-zertifiziert-magsafe-wireless-ladestation-15w';
update products set affiliate_url = 'https://amzn.to/3QuvJMO' where slug = 'findchic-edelstahl-drehring';
update products set affiliate_url = 'https://amzn.to/3Qv3uh6' where slug = 'fenree-business-rucksack-wasserdicht-usb';
update products set affiliate_url = 'https://amzn.to/3OBDVdz' where slug = 'joyroom-brillenhalter-auto-sonnenblende';
update products set affiliate_url = 'https://amzn.to/4mNxCA2' where slug = 'toureal-nachfuellbarer-parfuemzerstaeuber-reise';
update products set affiliate_url = 'https://amzn.to/4cLlLhv' where slug = 'hyako-massagepistole-triggerpunkt';
update products set affiliate_url = 'https://amzn.to/4sVUdMw' where slug = 'caspor-akupressurmatte-ganzkoerper';
update products set affiliate_url = 'https://amzn.to/4mPGYeJ' where slug = 'musicozy-bluetooth-schlafkopfhoerer';
update products set affiliate_url = 'https://amzn.to/4cxSzMb' where slug = 'fussmassage-igelball-faszienrolle';
update products set affiliate_url = 'https://amzn.to/4vMKzyp' where slug = 'porseme-ultraschall-luftbefeuchter-farbwechsel';
update products set affiliate_url = 'https://amzn.to/4tJkNJG' where slug = 'eisroller-gesicht-augen-hautpflege';
update products set affiliate_url = 'https://amzn.to/3OD5jrF' where slug = 'lifepro-infrarot-saunadecke';
update products set affiliate_url = 'https://amzn.to/4ubsMiJ' where slug = 'elektrisches-nackenmassagegeraet-schultermassage';
update products set affiliate_url = 'https://amzn.to/4vPzDQr' where slug = 'inner-peace-meditationskissen-yogakissen';
update products set affiliate_url = 'https://amzn.to/3QuwxkO' where slug = 'ubergames-riesenwackelturm-jumbo-jenga';
update products set affiliate_url = 'https://amzn.to/4d29sP7' where slug = 'talking-tables-partyspiel-geburtstag';
update products set affiliate_url = 'https://amzn.to/42sL2bl' where slug = 'huch-what-kartenspiel-deutsche-ausgabe';
update products set affiliate_url = 'https://amzn.to/3QtubCJ' where slug = 'tosy-flying-disc-wiederaufladbar';
update products set affiliate_url = 'https://amzn.to/4tJmwPa' where slug = 'shuffleboard-tischset-curling-familienspiel';
update products set affiliate_url = 'https://amzn.to/4vRPfTB' where slug = 'derayee-schaumstoff-wasserpistole';
update products set affiliate_url = 'https://amzn.to/4e9ZeND' where slug = 'costway-tischkicker-kickertisch';

-- ============================================================
-- 3. NEUES PRODUKT: Autostaubsauger
-- Noch nicht eingefügt — slug, Beschreibung, Preis und Kategorie fehlen
-- URL: https://amzn.to/4sTNlio
-- Bitte manuell ergänzen oder per Script nachliefern
-- ============================================================
