#!/usr/bin/env node

import { writeFile } from "node:fs/promises";

const ORIGIN = "https://www.crazybabobazar.com";
const OUTPUT = process.argv[2] ?? "/tmp/crazybabobazar-overnight-live-audit.json";
const CONCURRENCY = 5;
const TIMEOUT_MS = 25_000;

const decodeEntities = (value) =>
  value
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");

const stripTags = (value) =>
  decodeEntities(
    value
      .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
      .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
      .replace(/<svg\b[^>]*>[\s\S]*?<\/svg>/gi, " ")
      .replace(/<[^>]+>/g, " "),
  )
    .replace(/\s+/g, " ")
    .trim();

const firstMatch = (html, patterns) => {
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match?.[1]) return stripTags(match[1]);
  }
  return "";
};

const uniqueMatches = (html, pattern, transform = (value) => value) => {
  const values = [];
  for (const match of html.matchAll(pattern)) {
    if (match[1]) values.push(transform(decodeEntities(match[1])));
  }
  return [...new Set(values)];
};

const fetchText = async (url) => {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      // Der Node-20-Fetch-Pool hielt nach dem vollstaendigen Crawl zwei
      // TCPSocketWraps offen; der Report war fertig geschrieben, der Prozess
      // beendete sich aber nicht. Dieser Batch-Crawler profitiert nicht von
      // langlebigen Verbindungen nach dem letzten Request, deshalb schliesst
      // jede Antwort ihre Verbindung explizit.
      headers: {
        "user-agent": "CrazyBaboBazar-overnight-readonly-audit/1.0",
        connection: "close",
      },
      redirect: "follow",
      signal: controller.signal,
    });
    return {
      status: response.status,
      finalUrl: response.url,
      html: await response.text(),
    };
  } finally {
    clearTimeout(timer);
  }
};

const mapConcurrent = async (items, mapper) => {
  const results = new Array(items.length);
  let nextIndex = 0;

  const worker = async () => {
    while (true) {
      const index = nextIndex++;
      if (index >= items.length) return;
      try {
        results[index] = await mapper(items[index], index);
      } catch (error) {
        results[index] = {
          url: items[index],
          error: error instanceof Error ? error.message : String(error),
        };
      }
    }
  };

  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  return results;
};

const parseJsonLd = (html) => {
  const parsed = [];
  for (const match of html.matchAll(
    /<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi,
  )) {
    try {
      parsed.push(JSON.parse(match[1]));
    } catch {
      parsed.push({ parseError: true });
    }
  }
  return parsed;
};

const flattenJsonLd = (value) => {
  if (Array.isArray(value)) return value.flatMap(flattenJsonLd);
  if (!value || typeof value !== "object") return [];
  const nested = Array.isArray(value["@graph"])
    ? value["@graph"].flatMap(flattenJsonLd)
    : [];
  return [value, ...nested];
};

const parsePage = (url, response) => {
  const { html, status, finalUrl } = response;
  const jsonLd = parseJsonLd(html);
  const jsonLdNodes = jsonLd.flatMap(flattenJsonLd);
  const productSchema = jsonLdNodes.find((node) => node["@type"] === "Product") ?? null;
  const plainText = stripTags(html);
  const hrefs = uniqueMatches(html, /\bhref=["']([^"']+)["']/gi);
  const internalPaths = hrefs
    .map((href) => {
      try {
        const parsed = new URL(href, ORIGIN);
        return parsed.origin === ORIGIN ? parsed.pathname : null;
      } catch {
        return null;
      }
    })
    .filter(Boolean);
  const externalHosts = hrefs
    .map((href) => {
      try {
        const parsed = new URL(href, ORIGIN);
        return parsed.origin !== ORIGIN ? parsed.hostname : null;
      } catch {
        return null;
      }
    })
    .filter(Boolean);
  const images = uniqueMatches(html, /<img\b[^>]*\bsrc=["']([^"']+)["']/gi);
  const title = firstMatch(html, [/<title\b[^>]*>([\s\S]*?)<\/title>/i]);
  const description = firstMatch(html, [
    /<meta\b[^>]*\bname=["']description["'][^>]*\bcontent=["']([^"']*)["'][^>]*>/i,
    /<meta\b[^>]*\bcontent=["']([^"']*)["'][^>]*\bname=["']description["'][^>]*>/i,
  ]);
  const canonical = firstMatch(html, [
    /<link\b[^>]*\brel=["']canonical["'][^>]*\bhref=["']([^"']+)["'][^>]*>/i,
    /<link\b[^>]*\bhref=["']([^"']+)["'][^>]*\brel=["']canonical["'][^>]*>/i,
  ]);
  const robots = firstMatch(html, [
    /<meta\b[^>]*\bname=["']robots["'][^>]*\bcontent=["']([^"']*)["'][^>]*>/i,
    /<meta\b[^>]*\bcontent=["']([^"']*)["'][^>]*\bname=["']robots["'][^>]*>/i,
  ]);
  const h1 = firstMatch(html, [/<h1\b[^>]*>([\s\S]*?)<\/h1>/i]);

  return {
    url,
    path: new URL(url).pathname,
    status,
    finalUrl,
    bytes: Buffer.byteLength(html),
    title,
    titleLength: [...title].length,
    description,
    descriptionLength: [...description].length,
    canonical,
    robots,
    h1,
    textWords: plainText ? plainText.split(/\s+/).length : 0,
    internalPaths: [...new Set(internalPaths)],
    externalHosts: [...new Set(externalHosts)],
    imageCount: images.length,
    jsonLdTypes: [...new Set(jsonLdNodes.map((node) => node["@type"]).filter(Boolean))],
    jsonLdParseErrors: jsonLd.filter((item) => item?.parseError).length,
    productSchema: productSchema
      ? {
          name: productSchema.name ?? null,
          brand:
            typeof productSchema.brand === "object"
              ? productSchema.brand?.name ?? null
              : productSchema.brand ?? null,
          imageCount: Array.isArray(productSchema.image)
            ? productSchema.image.length
            : productSchema.image
              ? 1
              : 0,
          offersPresent: Boolean(productSchema.offers),
          price: productSchema.offers?.price ?? null,
        }
      : null,
    markers: {
      editorial: plainText.includes("Unser Urteil"),
      atAGlance: plainText.includes("Auf einen Blick"),
      proContra: plainText.includes("Pro & Contra"),
      alternative: plainText.includes("Alternative"),
      fitsWith: plainText.includes("Passt dazu"),
      topPick: plainText.includes("Top Pick"),
      affiliateDisclosure: plainText.includes("Amazon-Partner"),
    },
  };
};

const sitemapResponse = await fetchText(`${ORIGIN}/sitemap.xml`);
if (sitemapResponse.status !== 200) {
  throw new Error(`Sitemap lieferte HTTP ${sitemapResponse.status}`);
}

const sitemapUrls = uniqueMatches(sitemapResponse.html, /<loc>([^<]+)<\/loc>/gi);
const productUrls = sitemapUrls.filter((url) => new URL(url).pathname.startsWith("/produkt/"));
const collectionUrls = sitemapUrls.filter((url) => {
  const path = new URL(url).pathname;
  return path.startsWith("/listen/") || path.startsWith("/guide/");
});

const [productPages, collectionPages] = await Promise.all([
  mapConcurrent(productUrls, async (url) => parsePage(url, await fetchText(url))),
  mapConcurrent(collectionUrls, async (url) => parsePage(url, await fetchText(url))),
]);

const memberships = new Map(productUrls.map((url) => [new URL(url).pathname, []]));
for (const collection of collectionPages) {
  if (collection.error) continue;
  for (const path of collection.internalPaths.filter((item) => item.startsWith("/produkt/"))) {
    if (memberships.has(path)) memberships.get(path).push(collection.path);
  }
}

for (const product of productPages) {
  if (product.error) continue;
  product.slug = product.path.slice("/produkt/".length);
  product.memberships = [...new Set(memberships.get(product.path) ?? [])].sort();
  product.personaCategoryLinks = product.internalPaths.filter((path) =>
    /^\/(babos|queens|miniboss)\//.test(path),
  );
  product.themeLinks = product.internalPaths.filter((path) => path.startsWith("/thema/"));
}

const routeUrls = [
  "/",
  "/entdecken",
  "/unter-10",
  "/unknown/sonstiges",
  // Die Likes-Liste liegt unter /entdecken/likes. Das frueher hier stehende
  // /likes ist gar keine Route — die Diagnose mass also nur die 404-Seite.
  "/entdecken/likes",
  "/jarvis-ebook",
  "/design-preview",
  "/squad",
  "/wellness",
  "/kategorie",
].map((path) => `${ORIGIN}${path}`);
const routePages = await mapConcurrent(routeUrls, async (url) => parsePage(url, await fetchText(url)));

const result = {
  generatedAt: new Date().toISOString(),
  method: {
    source: "public sitemap and public server-rendered HTML only",
    origin: ORIGIN,
    concurrency: CONCURRENCY,
    mutation: "none",
  },
  sitemap: {
    status: sitemapResponse.status,
    urlCount: sitemapUrls.length,
    productCount: productUrls.length,
    collectionCount: collectionUrls.length,
    urls: sitemapUrls,
  },
  routePages,
  collectionPages,
  productPages,
};

await writeFile(OUTPUT, `${JSON.stringify(result, null, 2)}\n`, "utf8");
console.log(`AUDIT_OUTPUT=${OUTPUT}`);
console.log(`SITEMAP_URLS=${sitemapUrls.length}`);
console.log(`PRODUCT_URLS=${productUrls.length}`);
console.log(`COLLECTION_URLS=${collectionUrls.length}`);
console.log(`PRODUCT_ERRORS=${productPages.filter((page) => page.error).length}`);
console.log(`COLLECTION_ERRORS=${collectionPages.filter((page) => page.error).length}`);
