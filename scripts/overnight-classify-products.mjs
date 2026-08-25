#!/usr/bin/env node

// Klassifiziert die Live-Produktseiten aus dem Overnight-Audit gegen den
// GSC-90-Tage-Export und schreibt eine CSV.
//
// Aufruf:
//   node scripts/overnight-classify-products.mjs <live-audit.json> [gsc-pages.csv] <output.csv>
//
// Der Output-Pfad (4. Argument) ist IMMER anzugeben. Frueher stand hier ein
// Default auf einen datierten Report im Money-WiKi-Vault — ein zweiter Lauf
// hätte den Bericht des ersten stillschweigend überschrieben, sobald
// CBB_MONEYWIKI_ROOT gesetzt war. Es gibt deshalb keinen Default-Output mehr,
// und geschrieben wird mit `flag: "wx"`: existiert die Datei bereits, bricht
// das Skript ab statt zu überschreiben.
//
// Die GSC-Pages-CSV darf weiterhin aus CBB_MONEYWIKI_ROOT aufgelöst werden —
// das ist ein reiner Lesepfad.
//
//   CBB_MONEYWIKI_ROOT="/pfad/zum/Money WiKi" \
//     node scripts/overnight-classify-products.mjs <live-audit.json> "" <output.csv>
//
// Ohne auflösbare Pfade bricht das Skript ab, bevor irgendetwas gelesen oder
// geschrieben wird. Es wird nie an einen geratenen Pfad geschrieben.

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";

const GSC_PAGES_RELATIVE = "raw/seo/search-console/2026-08-22/pages-90d.csv";

const LIVE_AUDIT = process.argv[2] ?? "/tmp/crazybabobazar-overnight-live-audit.json";
const moneyWikiRoot = process.env.CBB_MONEYWIKI_ROOT?.trim() || null;

const USAGE =
  "node scripts/overnight-classify-products.mjs <live-audit.json> [gsc-pages.csv] <output.csv>";

const GSC_PAGES =
  process.argv[3]?.trim() || (moneyWikiRoot ? join(moneyWikiRoot, GSC_PAGES_RELATIVE) : null);
const OUTPUT = process.argv[4]?.trim() || null;

if (!GSC_PAGES) {
  throw new Error(
    "Fail-closed: GSC-Pages-CSV nicht auflösbar. Entweder CBB_MONEYWIKI_ROOT auf das " +
      `Money-WiKi-Vault setzen oder den Pfad explizit übergeben: ${USAGE}`,
  );
}

if (!OUTPUT) {
  throw new Error(
    "Fail-closed: Output-CSV nicht angegeben. Der Output-Pfad hat keinen Default — " +
      `auch nicht bei gesetztem CBB_MONEYWIKI_ROOT — damit kein vorhandener Report ` +
      `still überschrieben wird: ${USAGE}`,
  );
}

const pilotSlugs = new Set([
  "pinecil-usbc-loetkolben",
  "divoom-pixoo-led-panel",
  "sculpfun-s9-laser-engraver",
  "arc-reaktor-mk1-schwebend",
  "elektrische-wasserpistole-mit-led",
  "hot-wheels-ultimative-garage-3ft",
  "lego-creator-3in1-retro-kamera-31147",
  "ninja-staysharp-messerset-6-teilig",
  "n4-nussmilchbereiter-pflanzenmilch",
  "welpen-usb-ladekabel-hunde-design",
]);

// Ein Link auf /babos/<kategorie> kann auf der Produktseite stehen und trotzdem
// ein echter 404 sein — blosse Link-Praesenz reicht also nicht, um die
// Kategoriezuordnung gesund zu nennen. Frueher stand hier eine handgepflegte
// Allowlist der damals deployten 12 Kombinationen; sie veraltete lautlos, sobald
// eine Persona-Kategorie dazukam oder wegfiel.
//
// Quelle ist jetzt die Live-Sitemap desselben Audits: `app/sitemap.ts` leitet die
// Persona-Kategorieseiten aus derselben Taxonomie ab, aus der die Routen ihre
// Gueltigkeit ziehen. Was dort steht, ist eine erreichbare Seite.
const PERSONA_CATEGORY_PATH = /^\/(?:babos|queens|miniboss)\/[^/]+$/;

/** Ein einzelner nachgestellter Slash zaehlt nicht als anderer Pfad. */
const normalizePath = (path) =>
  typeof path === "string" && path.length > 1 && path.endsWith("/") ? path.slice(0, -1) : path;

// Der Pfad allein sagt nichts darueber, ob eine URL zu unserer Seite gehoert:
// `https://evil.example/babos/foo` hat denselben Pfad wie unsere Kategorieseite.
// Ohne Origin-Pruefung koennte ein fremder Eintrag in audit.sitemap.urls also
// eine Kategorie als "existiert" ausweisen, die es bei uns gar nicht gibt.
// Massgeblich ist die Origin, gegen die das Audit gelaufen ist.
const requireAuditOrigin = (method) => {
  const raw = typeof method?.origin === "string" ? method.origin.trim() : "";
  if (!raw) {
    throw new Error(
      "Fail-closed: audit.method.origin fehlt oder ist kein String (war: " +
        `${JSON.stringify(method?.origin)}). Ohne bekannte Audit-Origin laesst sich nicht ` +
        "entscheiden, welche Sitemap-URLs zur eigenen Seite gehoeren.",
    );
  }

  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    throw new Error(
      `Fail-closed: audit.method.origin ist keine gueltige URL (war: ${JSON.stringify(raw)})`,
    );
  }

  // Nur http(s) hat eine vergleichbare Origin — `new URL("file:///x").origin`
  // ist der undurchsichtige String "null", gegen den jeder Vergleich sinnlos waere.
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error(
      `Fail-closed: audit.method.origin ist keine http(s)-Origin (war: ${JSON.stringify(raw)})`,
    );
  }

  return parsed.origin;
};

const derivePersonaCategoryPaths = (sitemapUrls, expectedOrigin) => {
  if (!Array.isArray(sitemapUrls) || sitemapUrls.length === 0) {
    throw new Error(
      "Fail-closed: audit.sitemap.urls fehlt oder ist leer — ohne Sitemap laesst sich nicht " +
        "entscheiden, welche Persona-/Kategorie-Links echte Seiten sind.",
    );
  }

  const paths = new Set();
  const malformed = [];
  const foreign = [];

  for (const url of sitemapUrls) {
    let parsed;
    try {
      parsed = new URL(url);
    } catch {
      // Nicht ueberspringen: eine unlesbare Sitemap-URL heisst, dass die Ableitung
      // unvollstaendig waere — und eine fehlende gueltige Kategorie wuerde als
      // "404" in den Report wandern.
      malformed.push(String(url));
      continue;
    }
    if (parsed.origin !== expectedOrigin) {
      // Ebenfalls nicht still ueberspringen: eine fremde Origin in der Sitemap ist
      // ein kaputtes oder manipuliertes Audit, kein harmloses Rauschen.
      foreign.push(String(url));
      continue;
    }
    const pathname = normalizePath(parsed.pathname);
    if (PERSONA_CATEGORY_PATH.test(pathname)) paths.add(pathname);
  }

  if (malformed.length > 0) {
    throw new Error(
      `Fail-closed: ${malformed.length} unlesbare URL(s) in audit.sitemap.urls, ` +
        `erste: ${malformed.slice(0, 3).join(", ")}`,
    );
  }

  if (foreign.length > 0) {
    throw new Error(
      `Fail-closed: ${foreign.length} Sitemap-URL(s) mit fremder Origin (erwartet ${expectedOrigin}), ` +
        `erste: ${foreign.slice(0, 3).join(", ")}`,
    );
  }

  if (paths.size === 0) {
    throw new Error(
      "Fail-closed: keine /babos|queens|miniboss/<kategorie>-Pfade in audit.sitemap.urls — " +
        "jede Kategoriezuordnung wuerde faelschlich als 404 klassifiziert.",
    );
  }

  return paths;
};

const parseGsc = (csv) => {
  const rows = csv.trim().split(/\r?\n/).slice(1);
  const byPath = new Map();
  for (const row of rows) {
    const [page, clicks, impressions, ctr, position] = row.split(",");
    if (!page?.includes("/produkt/")) continue;
    byPath.set(new URL(page).pathname, {
      clicks: Number(clicks),
      impressions: Number(impressions),
      ctr: Number(ctr),
      position: Number(position),
    });
  }
  return byPath;
};

const classify = (product, gsc, validPersonaCategoryPaths) => {
  const memberships = product.memberships.length;
  const categoryLink = normalizePath(product.personaCategoryLinks[0]) ?? null;
  const hasValidCategoryLink = categoryLink != null && validPersonaCategoryPaths.has(categoryLink);
  const highReasons = [];
  if (pilotSlugs.has(product.slug)) highReasons.push("Value-Add-Pilotseite");
  if (gsc.clicks > 0) highReasons.push(`GSC: ${gsc.clicks} Klick(s) in 90 Tagen`);
  if (gsc.impressions >= 20) highReasons.push(`GSC: ${gsc.impressions} Impressionen in 90 Tagen`);
  if (memberships >= 3) highReasons.push(`redaktioneller Knoten in ${memberships} Listen/Guides`);
  if (highReasons.length > 0) {
    return { className: "hoher strategischer Wert", reason: highReasons.join("; ") };
  }

  const improveReasons = [];
  if (!product.markers.editorial) improveReasons.push("kein sichtbarer Block „Unser Urteil“");
  if (!hasValidCategoryLink) {
    improveReasons.push(categoryLink ? `Persona-/Kategorie-Link liefert 404: ${categoryLink}` : "keine gültige Persona-/Kategorie-Verlinkung");
  }
  if ((product.productSchema?.imageCount ?? 0) <= 1) improveReasons.push("nur ein Bild im Product-JSON-LD");
  if (gsc.impressions >= 5) improveReasons.push(`GSC-Signal ohne Klick: ${gsc.impressions} Impressionen`);
  if (improveReasons.length > 0) {
    return { className: "verbessern", reason: improveReasons.join("; ") };
  }

  if (memberships === 0) {
    return {
      className: "in Vergleich/Liste integrieren",
      reason: "redaktionell befüllt, aber in keiner bestehenden Liste oder keinem Guide enthalten",
    };
  }

  return {
    className: "niedrige Priorität",
    reason: `Grundhygiene vorhanden und bereits in ${memberships} Liste/Guide eingebunden; kein GSC-Nachfragesignal im 90-Tage-Export`,
  };
};

const escapeCsv = (value) => {
  const text = value == null ? "" : String(value);
  return /[",\n\r]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};

const audit = JSON.parse(await readFile(LIVE_AUDIT, "utf8"));
const gscByPath = parseGsc(await readFile(GSC_PAGES, "utf8"));

const auditOrigin = requireAuditOrigin(audit.method);
const validPersonaCategoryPaths = derivePersonaCategoryPaths(audit.sitemap?.urls, auditOrigin);

// Sollwert fuer alles Weitere: wie viele /produkt/-URLs die Sitemap gemeldet hat.
// Frueher stand hier die Konstante 372 — sie war ab dem naechsten neuen Produkt
// falsch und haette einen sonst korrekten Lauf abgebrochen.
const productCount = audit.sitemap?.productCount;
if (!Number.isInteger(productCount) || productCount <= 0) {
  throw new Error(
    `Fail-closed: audit.sitemap.productCount ist keine positive ganze Zahl (war: ${JSON.stringify(productCount)})`,
  );
}

const productPages = audit.productPages;
if (!Array.isArray(productPages)) {
  throw new Error(
    `Fail-closed: audit.productPages ist kein Array (war: ${JSON.stringify(productPages)})`,
  );
}

// Fehlerhafte Produktseiten nicht still wegfiltern: eine abgebrochene Anfrage
// heisst nicht, dass die Seite in Ordnung ist — sie wurde nur nicht gemessen.
// Wer sie aus der Zeilenzahl herausrechnet, bekommt einen Report, der vollstaendig
// aussieht und es nicht ist.
const failedProducts = productPages.filter((product) => product.error);
if (failedProducts.length > 0) {
  const first = failedProducts.slice(0, 3).map((product) => product.url ?? "(ohne URL)");
  throw new Error(
    `Fail-closed: ${failedProducts.length} von ${productPages.length} Produktseiten konnten im ` +
      `Audit nicht geladen werden, erste: ${first.join(", ")}. Audit wiederholen, bevor klassifiziert wird.`,
  );
}

const rows = productPages
  .map((product) => {
    const gsc = gscByPath.get(product.path) ?? {
      clicks: 0,
      impressions: 0,
      ctr: 0,
      position: null,
    };
    const classification = classify(product, gsc, validPersonaCategoryPaths);
    const personaCategory = normalizePath(product.personaCategoryLinks[0]) ?? "unbekannt";
    const [, persona = "unbekannt", category = "unbekannt"] = personaCategory.split("/");
    const categoryLinkStatus = validPersonaCategoryPaths.has(personaCategory)
      ? "200"
      : personaCategory === "unbekannt" ? "fehlt" : "404";
    return {
      slug: product.slug,
      name: product.h1,
      persona,
      category,
      categoryLinkStatus,
      classification: classification.className,
      reason: classification.reason,
      editorial: product.markers.editorial ? "ja" : "nein",
      schemaImages: product.productSchema?.imageCount ?? 0,
      curationCount: product.memberships.length,
      memberships: product.memberships.join(" | "),
      gscClicks90d: gsc.clicks,
      gscImpressions90d: gsc.impressions,
      gscPosition90d: gsc.position == null ? "" : gsc.position.toFixed(1),
      titleLength: product.titleLength,
      url: product.url,
    };
  })
  .sort((a, b) =>
    a.classification.localeCompare(b.classification, "de") || a.name.localeCompare(b.name, "de"),
  );

if (rows.length !== productCount) {
  throw new Error(
    `Fail-closed: Sitemap meldet ${productCount} Produktseiten, klassifiziert wurden ${rows.length}`,
  );
}

const counts = Object.fromEntries(
  [...new Set(rows.map((row) => row.classification))].map((className) => [
    className,
    rows.filter((row) => row.classification === className).length,
  ]),
);
const countTotal = Object.values(counts).reduce((sum, count) => sum + count, 0);
if (countTotal !== productCount) {
  throw new Error(`Fail-closed: Klassensumme ${countTotal} statt ${productCount}`);
}

const header = Object.keys(rows[0]);
const csv = [
  header.join(","),
  ...rows.map((row) => header.map((key) => escapeCsv(row[key])).join(",")),
].join("\n");

// Erst pruefen, dann schreiben: wegen `flag: "wx"` waere eine nach dem Schreiben
// geworfene Pruefung nicht wiederholbar — der zweite Lauf scheiterte am
// halbfertigen Report des ersten.
await mkdir(dirname(OUTPUT), { recursive: true });
// `flag: "wx"` statt Ueberschreiben: ein bereits vorhandener Report ist das
// Ergebnis eines frueheren Laufs und wird nicht angetastet.
try {
  await writeFile(OUTPUT, `${csv}\n`, { encoding: "utf8", flag: "wx" });
} catch (error) {
  if (error?.code === "EEXIST") {
    throw new Error(
      `Fail-closed: ${OUTPUT} existiert bereits und wird nicht überschrieben. ` +
        "Einen neuen Ausgabepfad wählen oder die vorhandene Datei bewusst entfernen.",
    );
  }
  throw error;
}

console.log(`OUTPUT=${OUTPUT}`);
console.log(`ROWS=${rows.length}`);
for (const [className, count] of Object.entries(counts)) console.log(`${className}=${count}`);
