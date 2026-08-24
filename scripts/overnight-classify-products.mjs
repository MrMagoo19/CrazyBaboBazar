#!/usr/bin/env node

// Klassifiziert die Live-Produktseiten aus dem Overnight-Audit gegen den
// GSC-90-Tage-Export und schreibt eine CSV.
//
// Aufrufvarianten:
//   node scripts/overnight-classify-products.mjs <live-audit.json> <gsc-pages.csv> <output.csv>
//     -> CLI-Argumente haben immer Vorrang.
//   CBB_MONEYWIKI_ROOT="/pfad/zum/Money WiKi" node scripts/overnight-classify-products.mjs
//     -> GSC-Pages und Output werden relativ zum Vault-Root aufgelöst.
//   node scripts/overnight-classify-products.mjs <live-audit.json>
//     -> nur zulässig, wenn CBB_MONEYWIKI_ROOT gesetzt ist.
//
// Ohne CLI-Pfade und ohne CBB_MONEYWIKI_ROOT bricht das Skript ab, bevor
// irgendetwas gelesen oder geschrieben wird. Es wird nie an einen geratenen
// Pfad geschrieben.

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";

const GSC_PAGES_RELATIVE = "raw/seo/search-console/2026-08-22/pages-90d.csv";
const OUTPUT_RELATIVE = "wiki/CrazyBaboBazar/Overnight/Produktklassifizierung-2026-08-24.csv";

const LIVE_AUDIT = process.argv[2] ?? "/tmp/crazybabobazar-overnight-live-audit.json";
const moneyWikiRoot = process.env.CBB_MONEYWIKI_ROOT?.trim() || null;

const resolveVaultPath = (cliValue, relative) => {
  if (cliValue) return cliValue;
  return moneyWikiRoot ? join(moneyWikiRoot, relative) : null;
};

const GSC_PAGES = resolveVaultPath(process.argv[3], GSC_PAGES_RELATIVE);
const OUTPUT = resolveVaultPath(process.argv[4], OUTPUT_RELATIVE);

if (!GSC_PAGES || !OUTPUT) {
  const missing = [!GSC_PAGES && "GSC-Pages-CSV", !OUTPUT && "Output-CSV"].filter(Boolean);
  throw new Error(
    `Fail-closed: ${missing.join(" und ")} nicht auflösbar. ` +
      "Entweder CBB_MONEYWIKI_ROOT auf das Money-WiKi-Vault setzen oder die Pfade explizit übergeben: " +
      "node scripts/overnight-classify-products.mjs <live-audit.json> <gsc-pages.csv> <output.csv>",
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

// The deployed route files currently accept only these combinations. A URL can
// be present in the sitemap/product HTML and still be a real 404, so mere link
// presence is not enough to call the category assignment healthy.
const validPersonaCategoryPaths = new Set([
  "/babos/gaming",
  "/babos/tech",
  "/babos/lifestyle",
  "/babos/outdoor",
  "/babos/irrenhaus",
  "/queens/kueche",
  "/queens/lifestyle",
  "/queens/beauty",
  "/queens/geschenke",
  "/miniboss/spielzeug",
  "/miniboss/gaming",
  "/miniboss/spass",
]);

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

const classify = (product, gsc) => {
  const memberships = product.memberships.length;
  const categoryLink = product.personaCategoryLinks[0] ?? null;
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

const rows = audit.productPages
  .filter((product) => !product.error)
  .map((product) => {
    const gsc = gscByPath.get(product.path) ?? {
      clicks: 0,
      impressions: 0,
      ctr: 0,
      position: null,
    };
    const classification = classify(product, gsc);
    const personaCategory = product.personaCategoryLinks[0] ?? "unbekannt";
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

if (rows.length !== 372) {
  throw new Error(`Fail-closed: erwartet 372 Live-Produktseiten, gefunden ${rows.length}`);
}

const header = Object.keys(rows[0]);
const csv = [
  header.join(","),
  ...rows.map((row) => header.map((key) => escapeCsv(row[key])).join(",")),
].join("\n");

await mkdir(dirname(OUTPUT), { recursive: true });
await writeFile(OUTPUT, `${csv}\n`, "utf8");

const counts = Object.fromEntries(
  [...new Set(rows.map((row) => row.classification))].map((className) => [
    className,
    rows.filter((row) => row.classification === className).length,
  ]),
);
const countTotal = Object.values(counts).reduce((sum, count) => sum + count, 0);
if (countTotal !== 372) throw new Error(`Fail-closed: Klassensumme ${countTotal} statt 372`);

console.log(`OUTPUT=${OUTPUT}`);
console.log(`ROWS=${rows.length}`);
for (const [className, count] of Object.entries(counts)) console.log(`${className}=${count}`);
