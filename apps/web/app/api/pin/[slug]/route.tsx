import { ImageResponse } from '@vercel/og'
import { NextRequest } from 'next/server'

export const runtime = 'edge'

async function toDataUrl(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; CrazyBaboBazar/1.0)' },
    })
    if (!res.ok) return null
    const buffer = await res.arrayBuffer()
    const bytes = new Uint8Array(buffer)
    let binary = ''
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    const base64 = btoa(binary)
    const ct = res.headers.get('content-type') || 'image/jpeg'
    return `data:${ct};base64,${base64}`
  } catch {
    return null
  }
}

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params

  try {
    const res = await fetch(
      `https://ydiihvzcxaaoqhmgoqvu.supabase.co/rest/v1/products?select=name,tagline,image_url&slug=eq.${encodeURIComponent(slug)}&is_published=eq.true`,
      {
        headers: {
          apikey: 'sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
          Authorization: 'Bearer sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
        },
        cache: 'no-store',
      }
    )

    const products = await res.json()
    const product = products?.[0]

    if (!product) {
      return new Response('Not found', { status: 404 })
    }

    const name = product.name as string
    const tagline = product.tagline as string | null
    const imageUrl = product.image_url as string | null

    // Pre-fetch image as base64 so Satori doesn't need to fetch it
    const imgDataUrl = imageUrl ? await toDataUrl(imageUrl) : null

    // Fetch font with fallback
    let fontData: ArrayBuffer | null = null
    try {
      const fontRes = await fetch(
        'https://fonts.gstatic.com/s/syne/v22/8vIS7w4qzmVxsWxjEAfa_nr.woff'
      )
      if (fontRes.ok) fontData = await fontRes.arrayBuffer()
    } catch {
      // use sans-serif fallback
    }

    return new ImageResponse(
      (
        <div
          style={{
            width: '1000px',
            height: '1500px',
            display: 'flex',
            flexDirection: 'column',
            backgroundColor: '#FFFFFF',
            fontFamily: fontData ? 'Syne' : 'sans-serif',
            border: '4px solid #0A0A0A',
          }}
        >
          {/* Image area */}
          <div
            style={{
              flex: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: '#F5F5F5',
              padding: '60px',
              borderBottom: '4px solid #0A0A0A',
            }}
          >
            {imgDataUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={imgDataUrl}
                alt=""
                style={{ maxWidth: '700px', maxHeight: '800px' }}
              />
            ) : (
              <div style={{ fontSize: '80px', display: 'flex' }}>📦</div>
            )}
          </div>

          {/* Yellow info bar */}
          <div
            style={{
              backgroundColor: '#FFE500',
              padding: '44px 52px 40px',
              display: 'flex',
              flexDirection: 'column',
              gap: '14px',
            }}
          >
            <div
              style={{
                backgroundColor: '#0A0A0A',
                color: '#FFE500',
                padding: '4px 12px',
                fontSize: '12px',
                fontWeight: 700,
                letterSpacing: '0.15em',
                display: 'flex',
                width: 'fit-content',
              }}
            >
              CRAZY BABO BAZAR
            </div>

            <div
              style={{
                fontSize: name.length > 40 ? '30px' : '36px',
                fontWeight: 800,
                color: '#0A0A0A',
                lineHeight: 1.15,
                display: 'flex',
              }}
            >
              {name}
            </div>

            {tagline && (
              <div
                style={{
                  fontSize: '18px',
                  color: '#333333',
                  lineHeight: 1.4,
                  display: 'flex',
                }}
              >
                {tagline.length > 80 ? tagline.slice(0, 80) + '…' : tagline}
              </div>
            )}

            <div
              style={{
                marginTop: '8px',
                fontSize: '15px',
                fontWeight: 700,
                color: '#0A0A0A',
                letterSpacing: '0.06em',
                display: 'flex',
              }}
            >
              crazybabobazar.com
            </div>
          </div>
        </div>
      ),
      {
        width: 1000,
        height: 1500,
        fonts: fontData
          ? [{ name: 'Syne', data: fontData, weight: 800 }]
          : [],
      }
    )
  } catch (err) {
    console.error('Pin generation error:', err)
    return new Response(`Error: ${err}`, { status: 500 })
  }
}
