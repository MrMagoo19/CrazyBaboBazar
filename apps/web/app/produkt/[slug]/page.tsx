import Link from 'next/link'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { getProductBySlug, getRelatedProducts, getPublishedProducts, getListsForProduct } from '@/lib/db'
import { getGuidesForProduct } from '@/lib/guides'
import { resolveProductCategoryLink } from '@/lib/taxonomy'
import { getPriceBand } from '@/lib/db-types'
import { ShareButton } from '@/components/ui/share-button'
import { ImageSlider } from '@/components/ui/image-slider'
import type { Metadata } from 'next'

export const revalidate = 3600
export const dynamicParams = true

const SITE_URL = 'https://www.crazybabobazar.com'

type Props = { params: Promise<{ slug: string }> }

export async function generateStaticParams() {
  const products = await getPublishedProducts()
  return products.map((p) => ({ slug: p.slug }))
}

function toMetaDescription(description: string | null | undefined, tagline: string | null | undefined): string {
  const raw = (description && description.trim()) || (tagline && tagline.trim()) || ''
  if (!raw) return ''
  const clean = raw
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/\*\*/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  if (clean.length <= 160) return clean
  return clean.slice(0, 157).trimEnd() + '…'
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) return {}
  const metaDescription = toMetaDescription(product.description, product.tagline)
  return {
    title: `${product.name} — Crazy Babo Bazar`,
    description: metaDescription,
    alternates: {
      canonical: `${SITE_URL}/produkt/${slug}`,
    },
    openGraph: {
      title: `${product.name} — Crazy Babo Bazar`,
      description: metaDescription,
      url: `${SITE_URL}/produkt/${slug}`,
      images: [{ url: `${SITE_URL}/api/pin/${slug}`, width: 1000, height: 1500 }],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${product.name} — Crazy Babo Bazar`,
      description: metaDescription,
      images: [`${SITE_URL}/api/pin/${slug}`],
    },
  }
}

export default async function ProduktPage({ params }: Props) {
  const { slug } = await params
  const product = await getProductBySlug(slug)
  if (!product) notFound()

  const [related, inLists, inGuides, alternativeRaw] = await Promise.all([
    // alternative_slug wird bereits in der Query ausgeschlossen, damit die
    // Alternative keinen der vier Relations-Plaetze belegt.
    getRelatedProducts(slug, product.shop_persona, product.shop_main_category, product.alternative_slug),
    getListsForProduct(slug),
    Promise.resolve(getGuidesForProduct(slug)),
    // Value-Add: echte Alternative nur laden, wenn ein Verweis gesetzt ist.
    // getProductBySlug liefert null bei unbekanntem Slug → graceful.
    product.alternative_slug ? getProductBySlug(product.alternative_slug) : Promise.resolve(null),
  ])

  // Alternative/Passt-dazu nur zeigen, wenn Ziel existiert, veröffentlicht ist und
  // nicht auf sich selbst verweist. Sonst wird der ganze Block ausgelassen.
  // `is_published` filtert getProductBySlug inzwischen selbst; die Prüfung hier
  // bleibt als zweite Verteidigungslinie stehen.
  const alternative =
    alternativeRaw && alternativeRaw.is_published && alternativeRaw.slug !== product.slug
      ? alternativeRaw
      : null
  // 'complement' = ergänzendes Produkt ("Passt dazu"); alles andere (inkl. Default)
  // = echtes Ersatzprodukt ("Alternative"). Steuert die Überschrift des Blocks.
  const isComplement = product.alternative_kind === 'complement'
  const relationLabel = isComplement ? 'Passt dazu' : 'Alternative'

  // Zweite Verteidigungslinie: der Ausschluss passiert schon in getRelatedProducts,
  // aber ein Produkt, das als Alternative/Passt-dazu-Karte gezeigt wird, darf hier
  // auch dann nicht auftauchen, wenn die Query-Seite je wieder aufweicht.
  const relatedFiltered = (alternative
    ? related.filter((p) => p.slug !== alternative.slug)
    : related
  ).slice(0, 4)

  // Graceful-Degradation-Flags: jeder neue Block rendert nur bei echten Daten.
  const hasGlance = Boolean(product.fuer_wen || product.nicht_fuer || product.key_fact)
  const pros = product.pros ?? []
  const cons = product.cons ?? []
  const hasProsCons = pros.length > 0 || cons.length > 0

  const catEmoji = product.categories?.emoji ?? '📦'

  // Category/breadcrumb target — only ever point at routes that actually exist.
  // Die Aufloesung liegt in `lib/taxonomy.ts`, damit Breadcrumb und Sitemap
  // dieselbe Route-Matrix benutzen: Eine bekannte Persona allein reicht nicht,
  // das Paar Persona+`shop_main_category` muss eine echte Seite haben. Sonst
  // greift die (immer weiterleitende, nie 404) /kategorie-Route, und wenn auch
  // die fehlt, wird gar kein Kategorie-Link gerendert.
  const categoryLink = resolveProductCategoryLink({
    persona: product.shop_persona,
    mainCategory: product.shop_main_category,
    categorySlug: product.categories?.slug,
    categoryName: product.categories?.name,
  })
  const catHref = categoryLink?.href ?? null
  const catName = categoryLink?.name ?? null

  const schemaDescription = toMetaDescription(product.description, product.tagline)
  const productUrl = `${SITE_URL}/produkt/${slug}`
  const productImages = (product.image_urls && product.image_urls.length > 0
    ? product.image_urls
    : product.image_url ? [product.image_url] : []
  )

  const productSchema: Record<string, unknown> = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: schemaDescription,
    url: productUrl,
    ...(productImages.length > 0 ? { image: productImages } : {}),
    // Only emit a real manufacturer brand. No brand → omit the property entirely
    // (never fall back to the site name; that would misattribute the product).
    ...(product.brand && product.brand.trim()
      ? { brand: { '@type': 'Brand', name: product.brand.trim() } }
      : {}),
    // No `offers` node: the only price source is manually-maintained `price_cents`
    // (no PA-API, no timestamp), so an exact price + availability here would be a
    // stale, non-compliant claim. The Product snippet stays valid without offers.
    // Re-add offers with a live price + priceValidUntil once PA-API is available.
    //
    // Pros/cons are rendered visibly on the page but deliberately NOT emitted as
    // structured data (no positiveNotes/negativeNotes, no Review, no rating). The
    // Product snippet carries only name/description/image/brand + breadcrumb.
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Start', item: SITE_URL },
      ...(catHref && catName
        ? [{ '@type': 'ListItem', position: 2, name: catName, item: `${SITE_URL}${catHref}` }]
        : []),
      { '@type': 'ListItem', position: catHref ? 3 : 2, name: product.name, item: productUrl },
    ],
  }

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />

      {/* ── BREADCRUMB ─────────────────────────────────────── */}
      <div className="border-b-2 border-[#0A0A0A]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-[#555555]">
            <Link href="/" className="hover:text-[#0A0A0A] hover:underline transition-colors">Start</Link>
            {catHref && catName && (
              <>
                <span>→</span>
                <Link href={catHref} className="hover:text-[#0A0A0A] hover:underline transition-colors">
                  {catName}
                </Link>
              </>
            )}
            <span>→</span>
            <span className="text-[#0A0A0A] truncate max-w-[200px]">{product.name}</span>
          </div>
        </div>
      </div>

      {/* ── MAIN PRODUCT ───────────────────────────────────── */}
      <section style={{ borderBottom: '2px solid #0A0A0A', backgroundColor: '#FFFFFF' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-12">
          <div className="flex flex-col lg:flex-row">
            {/* Image / Slider */}
            {product.image_urls && product.image_urls.length > 1 ? (
              <ImageSlider
                images={product.image_urls}
                name={product.name}
                isFeatured={product.is_featured}
              />
            ) : (
              <div
                style={{
                  backgroundColor: '#FFFFFF',
                  border: '2px solid #0A0A0A',
                  aspectRatio: '1 / 1',
                  position: 'relative',
                  overflow: 'hidden',
                  flexShrink: 0,
                }}
                className="w-full lg:w-1/2"
              >
                {product.image_url ? (
                  <Image
                    src={product.image_url}
                    alt={product.name}
                    fill
                    className="object-contain p-8"
                    sizes="(max-width: 1024px) 100vw, 50vw"
                  />
                ) : (
                  <span className="text-[160px] opacity-20 select-none absolute inset-0 flex items-center justify-center">{catEmoji}</span>
                )}
                {product.is_featured && (
                  <div className="absolute top-6 left-6">
                    <span className="bg-[#FFE500] text-[#0A0A0A] text-xs font-black px-3 py-1 uppercase tracking-wide">
                      Featured
                    </span>
                  </div>
                )}
              </div>
            )}

            {/* Info */}
            <div
              style={{
                backgroundColor: '#FFFFFF',
                borderTop: '2px solid #0A0A0A',
                padding: '2rem',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                flex: 1,
              }}
              className="lg:border-t-0 lg:border-l-2 lg:border-l-[#0A0A0A] lg:p-12"
            >
              {catHref && catName && (
                <Link
                  href={catHref}
                  className="font-[family-name:var(--font-mono)] font-bold text-[11px] uppercase tracking-widest mb-4 bg-[#FFE500] text-[#0A0A0A] px-2 py-1"
                  style={{ alignSelf: 'flex-start' }}
                >
                  ← {catName}
                </Link>
              )}

              <h1 className="font-[family-name:var(--font-display)] font-black text-2xl sm:text-3xl leading-tight mb-3 text-[#0A0A0A]">
                {product.name}
              </h1>

              {product.tagline && (
                <p className="text-[#555] font-semibold text-base mb-4">{product.tagline}</p>
              )}

              <div className="text-[#555555] text-base leading-relaxed mb-8 space-y-3">
                {(product.description ?? '').split('\n').map((line, i) => {
                  const segments: { text: string; url?: string }[] = []
                  const re = /\[([^\]]+)\]\(([^)]+)\)/g
                  let last = 0, m: RegExpExecArray | null
                  while ((m = re.exec(line)) !== null) {
                    if (m.index > last) segments.push({ text: line.slice(last, m.index) })
                    segments.push({ text: m[1], url: m[2] })
                    last = re.lastIndex
                  }
                  if (last < line.length) segments.push({ text: line.slice(last) })
                  return (
                    <p key={i}>
                      {segments.map((seg, j) =>
                        seg.url ? (
                          <a key={j} href={seg.url}
                            className="text-[#0A0A0A] font-bold underline underline-offset-2 hover:text-[#555] transition-colors"
                            target={seg.url.startsWith('http') ? '_blank' : undefined}
                            rel={seg.url.startsWith('http') ? 'noopener noreferrer' : undefined}
                          >{seg.text}</a>
                        ) : (
                          <span key={j}>{seg.text.replace(/\*\*/g, '')}</span>
                        )
                      )}
                    </p>
                  )
                })}
              </div>

              {/* CTA */}
              <div style={{ borderTop: '2px solid #E0E0E0', paddingTop: '2rem' }}>
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <div className="text-[#555] text-xs font-[family-name:var(--font-mono)] uppercase tracking-wider mb-2">Preisbereich</div>
                    <div className="font-[family-name:var(--font-mono)] font-bold text-3xl text-[#0A0A0A]">
                      {getPriceBand(product.price_cents)}
                    </div>
                    <div className="text-[#555] text-[10px] mt-1">Aktueller Preis auf Amazon</div>
                  </div>
                  <div className="text-right text-xs text-[#555] max-w-[140px]">
                    <div>Preis wird von Amazon</div>
                    <div>festgelegt & kann variieren.</div>
                  </div>
                </div>

                <a
                  href={product.affiliate_url}
                  target="_blank"
                  rel="sponsored nofollow noopener noreferrer"
                  className="block w-full text-center bg-[#0A0A0A] text-white py-4 font-bold text-base hover:bg-[#FFE500] hover:text-[#0A0A0A] transition-colors duration-200 mb-3"
                >
                  Preis auf Amazon prüfen →
                </a>

                <ShareButton name={product.name} tagline={product.tagline} />

                <p className="text-[#555] text-xs text-center mt-3">
                  * Als Amazon-Partner verdienen wir an qualifizierten Käufen. Kein Aufpreis für dich.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── AUF EINEN BLICK ────────────────────────────────── */}
      {hasGlance && (
        <section className="border-b-2 border-[#0A0A0A] bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-1 h-6 bg-[#FFE500]" />
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">Auf einen Blick</h2>
            </div>
            <dl className="grid gap-4 sm:grid-cols-3">
              {product.fuer_wen && (
                <div className="border-2 border-[#0A0A0A] p-5">
                  <dt className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#555] mb-2">Am besten für</dt>
                  <dd className="text-[#0A0A0A] text-sm leading-relaxed font-medium">{product.fuer_wen}</dd>
                </div>
              )}
              {product.nicht_fuer && (
                <div className="border-2 border-[#0A0A0A] p-5">
                  <dt className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#555] mb-2">Weniger geeignet für</dt>
                  <dd className="text-[#0A0A0A] text-sm leading-relaxed font-medium">{product.nicht_fuer}</dd>
                </div>
              )}
              {product.key_fact && (
                <div className="border-2 border-[#0A0A0A] p-5">
                  <dt className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#555] mb-2">Gut zu wissen</dt>
                  {/* KEINE pauschale Quellenkennzeichnung. `key_fact` ist ein freies
                      Textfeld ohne Quellenfeld: der Inhalt mischt je nach Produkt
                      Herstellerangaben mit eigener Einordnung (z. B. beim N4 die
                      Einschraenkung zur manuellen Nachreinigung, die aus einem
                      unabhaengigen Test stammt). Ein fixes Label "Herstellerangabe"
                      wuerde solche Saetze dem Hersteller zuschreiben — eine falsche
                      Attribution. Erst wenn es ein echtes Quellenfeld in der DB gibt,
                      darf hier wieder eine Quelle stehen, und zwar pro Produkt. */}
                  <dd className="text-[#0A0A0A] text-sm leading-relaxed font-medium">
                    {product.key_fact}
                  </dd>
                </div>
              )}
            </dl>
          </div>
        </section>
      )}

      {/* ── PRO & CONTRA ───────────────────────────────────── */}
      {hasProsCons && (
        <section className="border-b-2 border-[#0A0A0A] bg-[#F8F8F8]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-1 h-6 bg-[#FFE500]" />
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">Pro &amp; Contra</h2>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              {pros.length > 0 && (
                <div className="border-2 border-[#0A0A0A] bg-white p-5">
                  <h3 id="pro-heading" className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#0A0A0A] mb-3">Pro</h3>
                  <ul aria-labelledby="pro-heading" className="space-y-2">
                    {pros.map((pro, i) => (
                      <li key={i} className="flex gap-2 text-sm text-[#0A0A0A] leading-relaxed">
                        <span aria-hidden className="font-black text-[#0A0A0A] select-none">+</span>
                        <span>{pro}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              {cons.length > 0 && (
                <div className="border-2 border-[#0A0A0A] bg-white p-5">
                  <h3 id="contra-heading" className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#555] mb-3">Contra</h3>
                  <ul aria-labelledby="contra-heading" className="space-y-2">
                    {cons.map((con, i) => (
                      <li key={i} className="flex gap-2 text-sm text-[#555] leading-relaxed">
                        <span aria-hidden className="font-black text-[#555] select-none">–</span>
                        <span>{con}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          </div>
        </section>
      )}

      {/* ── VIDEO ─────────────────────────────────────────── */}
      {product.video_url && (
        <section className="border-b-2 border-[#0A0A0A]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-1 h-6 bg-[#FFE500]" />
              <span className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">Produkt-Video</span>
            </div>
            <div className="relative w-full aspect-video bg-white border-2 border-[#0A0A0A]">
              <iframe
                src={product.video_url}
                title={`${product.name} Video`}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="absolute inset-0 w-full h-full"
              />
            </div>
          </div>
        </section>
      )}

      {/* ── UNSER URTEIL ───────────────────────────────────── */}
      {product.editorial_note && (
        <section style={{ backgroundColor: '#FFFFFF', borderBottom: '2px solid #0A0A0A' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div style={{ backgroundColor: '#FFE500', border: '2px solid #0A0A0A', padding: '24px 28px' }}>
              <div className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#0A0A0A] mb-3">
                Unser Urteil
              </div>
              <p className="text-[#0A0A0A] text-base leading-relaxed font-medium">
                {product.editorial_note}
              </p>
            </div>
          </div>
        </section>
      )}

      {/* ── ALTERNATIVE / PASST DAZU ───────────────────────── */}
      {alternative && (
        <section className="border-b-2 border-[#0A0A0A] bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-1 h-6 bg-[#FFE500]" />
              <h2 className="font-[family-name:var(--font-body)] font-semibold text-lg text-[#0A0A0A]">{relationLabel}</h2>
            </div>
            {/* Kein lokaler Focus-Ring mehr: der globale `:focus-visible`-Block in
                globals.css ist jetzt zweifarbig (schwarze outline + weisser
                box-shadow-Ring) und damit auf der weissen Karte wie im gelben
                Hover-Zustand sichtbar. Die frühere !important-Sonderloesung ist
                dadurch redundant. */}
            <Link
              href={`/produkt/${alternative.slug}`}
              className="group flex flex-col sm:flex-row gap-5 border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors p-5"
            >
              <div className="w-full sm:w-40 aspect-square shrink-0 bg-[#F5F5F5] border-2 border-[#0A0A0A] relative overflow-hidden">
                {alternative.image_url ? (
                  // alt="" — der Produktname steht direkt daneben im selben Link.
                  <Image src={alternative.image_url} alt="" fill className="object-contain p-4" unoptimized />
                ) : (
                  <div aria-hidden className="absolute inset-0 flex items-center justify-center text-5xl">📦</div>
                )}
              </div>
              {/* min-w-0: Flex-Items haben min-width:auto und wachsen sonst ueber die
                  Karte hinaus, sobald Name oder Begruendung ein sehr langes Wort
                  (z. B. eine Modellbezeichnung) enthalten. break-words bricht ein
                  solches Wort dann innerhalb der Spalte um. */}
              <div className="flex flex-col gap-2 min-w-0">
                {/* Kein Relationstyp-Badge: wiederholt nur die Abschnittsueberschrift. */}
                <h3 className="font-[family-name:var(--font-display)] font-black text-lg text-[#0A0A0A] leading-tight break-words">
                  {alternative.name}
                </h3>
                {product.alternative_reason && (
                  <p className="text-sm text-[#555] leading-relaxed break-words">{product.alternative_reason}</p>
                )}
                <div className="mt-auto flex items-center justify-between gap-3">
                  <span
                    className="text-xs font-bold font-[family-name:var(--font-mono)] w-fit"
                    style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}
                  >
                    {getPriceBand(alternative.price_cents)}
                  </span>
                  <span
                    aria-hidden
                    className="text-xs font-bold font-[family-name:var(--font-mono)] text-[#555] group-hover:text-[#0A0A0A] transition-colors whitespace-nowrap"
                  >
                    Produkt ansehen →
                  </span>
                </div>
              </div>
            </Link>
          </div>
        </section>
      )}

      {/* ── ENTHALTEN IN LISTEN & GUIDES ───────────────────── */}
      {(inLists.length > 0 || inGuides.length > 0) && (
        <section className="border-b-2 border-[#0A0A0A] bg-white">
          <nav aria-label="Enthalten in Listen und Guides" className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
            <h2 className="font-[family-name:var(--font-mono)] font-black text-[10px] uppercase tracking-widest text-[#555] mb-4">
              Enthalten in Listen &amp; Guides
            </h2>
            <ul className="flex flex-wrap gap-2">
              {inLists.map((l) => (
                <li key={`list-${l.slug}`}>
                  <Link
                    href={`/listen/${l.slug}`}
                    className="inline-flex items-center gap-2 border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors px-3 py-1.5 text-xs font-bold text-[#0A0A0A]"
                  >
                    <span className="font-[family-name:var(--font-mono)] text-[9px] uppercase tracking-widest text-[#555]">Liste</span>
                    <span>{l.title}</span>
                  </Link>
                </li>
              ))}
              {inGuides.map((g) => (
                <li key={`guide-${g.slug}`}>
                  <Link
                    href={`/guide/${g.slug}`}
                    className="inline-flex items-center gap-2 border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors px-3 py-1.5 text-xs font-bold text-[#0A0A0A]"
                  >
                    <span className="font-[family-name:var(--font-mono)] text-[9px] uppercase tracking-widest text-[#555]">Guide</span>
                    <span>{g.title}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
        </section>
      )}

      {/* ── ÄHNLICHE PRODUKTE ──────────────────────────────── */}
      {relatedFiltered.length > 0 && (
        <section style={{ backgroundColor: '#F8F8F8', borderTop: '2px solid #0A0A0A', borderBottom: '2px solid #0A0A0A' }}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
            <h2 className="font-[family-name:var(--font-display)] font-black text-xl text-[#0A0A0A] mb-6">
              Könnte dich auch interessieren
            </h2>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {relatedFiltered.map((p) => (
                <Link
                  key={p.slug}
                  href={`/produkt/${p.slug}`}
                  className="group flex flex-col border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors"
                >
                  <div className="aspect-square bg-[#F5F5F5] border-b-2 border-[#0A0A0A] relative overflow-hidden">
                    {p.image_url ? (
                      <Image src={p.image_url} alt={p.name} fill className="object-contain p-4" unoptimized />
                    ) : (
                      <div className="absolute inset-0 flex items-center justify-center text-4xl">📦</div>
                    )}
                  </div>
                  <div className="p-3 flex flex-col gap-1.5 flex-1">
                    <p className="font-[family-name:var(--font-display)] font-black text-xs text-[#0A0A0A] leading-tight line-clamp-2">
                      {p.name}
                    </p>
                    <span
                      className="text-[9px] font-bold font-[family-name:var(--font-mono)] mt-auto w-fit"
                      style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '1px 6px' }}
                    >
                      {getPriceBand(p.price_cents)}
                    </span>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ── DISCLAIMER ─────────────────────────────────────── */}
      <section style={{ backgroundColor: '#FFFFFF' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="border-2 border-[#0A0A0A] p-6" style={{ backgroundColor: '#FFFFFF' }}>
            <div className="text-[#0A0A0A] text-xs font-bold uppercase tracking-widest mb-2">Affiliate-Hinweis</div>
            <p className="text-[#555555] text-xs leading-relaxed">
              Dieser Beitrag enthält Affiliate-Links. Wenn du über einen unserer Links ein Produkt kaufst, erhalten wir eine Provision. Der Preis für dich bleibt derselbe.
            </p>
          </div>
        </div>
      </section>

    </div>
  )
}
