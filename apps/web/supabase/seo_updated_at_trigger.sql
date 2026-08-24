-- ============================================================
-- SEO: updated_at nur bei sichtbaren / indexierungsrelevanten Aenderungen
-- ============================================================
--
-- Warum es das braucht:
--   schema.sql definiert  updated_at timestamptz default now()  — ein Default,
--   kein Trigger. updated_at wird also genau einmal beim INSERT gesetzt und
--   danach nur, wenn ein Statement die Spalte ausdruecklich mitschreibt.
--   Von 32 inhaltsaendernden UPDATE-Skripten im Repo tut das genau eines.
--   sitemap.ts liest  lastModified: new Date(p.updated_at ?? p.created_at)  —
--   die Sitemap meldet Google daher seit Monaten veraltete lastmod-Werte.
--
-- Aufnahmekriterium fuer jede Spalte unten:
--   Sie veraendert entweder sichtbaren Seiteninhalt, ein Feld in der
--   Metadata/JSON-LD-Ausgabe, oder die internen Links AUF DER PRODUKTSEITE
--   SELBST. Reine Zuordnungs- oder Kurationsflags bleiben draussen.
--
-- Belegstellen beziehen sich auf apps/web/app/produkt/[slug]/page.tsx
-- (Stand: Commit 03b641c).
--
-- NICHT ausfuehren, bevor backfill_lastmod_20260704.sql geprueft ist —
-- Reihenfolge und Rollback stehen in der Begleitdokumentation.
-- ============================================================

create or replace function products_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  -- Schreibt der Aufrufer updated_at selbst (z. B. der einmalige Backfill mit
  -- einem historischen Datum), hat das Vorrang. Der Trigger ueberschreibt eine
  -- bewusst gesetzte Zeit nicht mit now().
  if new.updated_at is not distinct from old.updated_at
     and (
       -- name
       --   H1 der Seite, <title>, JSON-LD Product.name, BreadcrumbList-Endglied.
       --   (Zeilen 40, 106, 149, 128)
       new.name,

       -- tagline
       --   Sichtbar unter dem Titel und Fallback fuer die Meta-Description,
       --   wenn description leer ist. (toMetaDescription, Zeile 25)
       new.tagline,

       -- description
       --   Sichtbarer Fliesstext, Meta-Description und JSON-LD
       --   Product.description. (Zeilen 25, 38, 93)
       new.description,

       -- editorial_note
       --   Sichtbarer "Unser Urteil"-Block. Der eigentliche redaktionelle
       --   Mehrwert der Seite — genau das, was am 04.07.2026 ergaenzt wurde.
       new.editorial_note,

       -- image_url
       --   Primaeres Produktbild. Sichtbar und Fallback fuer JSON-LD
       --   Product.image, wenn image_urls leer ist. (Zeile 96-99)
       --   image_urls bleibt bewusst DRAUSSEN: eine nachgetragene Galerie
       --   aendert den redaktionellen Inhalt der Seite nicht, und Bulk-Laeufe
       --   ueber image_urls wuerden sonst alle lastmod-Werte gleichzeitig
       --   verschieben.
       new.image_url,

       -- is_published
       --   Entscheidet, ob die Seite ueberhaupt existiert (notFound, Zeile 66)
       --   und ob die URL in der Sitemap steht (is_published=eq.true).
       --   Eine Wiederveroeffentlichung ist eine echte Aenderung.
       new.is_published,

       -- shop_persona
       --   Baut den sichtbaren Breadcrumb-Link und dessen Label (Zeile 81-90),
       --   erscheint im BreadcrumbList-JSON-LD und steuert den Block
       --   "aehnliche Produkte" — also die ausgehenden internen Links der
       --   Seite (getRelatedProducts, lib/db.ts:122).
       new.shop_persona,

       -- shop_main_category
       --   Zweite Haelfte desselben Breadcrumb-Links und zusaetzlicher Filter
       --   fuer die verwandten Produkte. (Zeile 82, 86, lib/db.ts:136)
       new.shop_main_category,

       -- brand
       --   Erzeugt den JSON-LD Brand-Node. Fehlt die Marke, entfaellt die
       --   Property komplett. Aenderung = geaendertes strukturiertes Datum.
       --   (Zeile 109-111)
       new.brand,

       -- category_id
       --   Ersatz-Breadcrumb, wenn shop_persona/shop_main_category fehlen:
       --   dann zeigt der Link auf /kategorie/<slug>. Aendert damit sichtbaren
       --   Text und einen internen Link. (Zeile 88-91)
       new.category_id
     )
     is distinct from (
       old.name,
       old.tagline,
       old.description,
       old.editorial_note,
       old.image_url,
       old.is_published,
       old.shop_persona,
       old.shop_main_category,
       old.brand,
       old.category_id
     )
  then
    new.updated_at := now();
  end if;

  return new;
end
$$;

-- ------------------------------------------------------------
-- Bewusst NICHT aufgenommen
-- ------------------------------------------------------------
--   image_urls          Auf deine ausdrueckliche Vorgabe draussen. Folge: eine
--                       nachgetragene Bildergalerie aendert zwar das JSON-LD
--                       image-Array, loest aber kein neues lastmod aus.
--   shop_sub_category   Kommt im gesamten Rendering nicht vor, nur in
--                       lib/db-types.ts als Typfeld.
--   shop_tags           Steuert ausschliesslich, auf welchen LISTENSEITEN das
--                       Produkt erscheint (lib/db.ts:95). Aendert die
--                       Produktseite selbst nicht — die eingehenden Links
--                       aendern sich, nicht diese Seite.
--   is_featured         Grenzfall: rendert ein sichtbares Badge (Zeile 188) und
--                       beeinflusst die Sortierung auf Listenseiten. Bewusst
--                       draussen, weil ein Kurationsflag ohne inhaltliche
--                       Aussage sonst bei jedem Umschalten ein "Seite
--                       aktualisiert" an Google meldet. Soll es doch zaehlen:
--                       new.is_featured / old.is_featured in beide Listen
--                       aufnehmen.
--   price_cents         Sichtbar ist ausschliesslich das Preisband
--                       (getPriceBand, lib/db-types.ts:52-61: Unter 10€ /
--                       Unter 20€ / 20-50€ / 50-100€ / 100-200€ / Ueber 200€).
--                       Ein exakter Preis wird nirgends gerendert; formatPrice
--                       ist toter Code. Eine Preiskorrektur innerhalb eines
--                       Bandes aendert die Seite also gar nicht.
--                       Die Alternative — im Trigger pruefen, ob sich das Band
--                       aendert — wuerde die Bandgrenzen ein zweites Mal in
--                       PL/pgSQL abbilden. Aendern sich die Grenzen in
--                       db-types.ts, driftet der Trigger stillschweigend und
--                       meldet ab da falsche oder fehlende lastmod-Werte.
--                       Deshalb draussen. Springt ein Preis ausnahmsweise doch
--                       ueber eine Bandgrenze, im betreffenden Skript
--                       updated_at = now() ausdruecklich mitschreiben — der
--                       Guard oben laesst das zu.
--   affiliate_url       Ausgehender Amazon-Link, rel="sponsored nofollow".
--                       Kein indexierbarer Seiteninhalt.
--   currency            Konstant 'EUR', wird nirgends gerendert.
-- ------------------------------------------------------------

create trigger products_set_updated_at
  before update on products
  for each row
  execute function products_touch_updated_at();
