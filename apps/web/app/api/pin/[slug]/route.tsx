import { ImageResponse } from 'next/og'
import { NextRequest } from 'next/server'

export const runtime = 'nodejs'

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params

  try {
    // 1. Fetch product
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
    if (!product) return new Response('Not found', { status: 404 })

    const name = product.name as string
    const tagline = product.tagline as string | null
    const imageUrl = product.image_url as string | null

    // 2. Pre-fetch product image → base64 data URL
    let imgDataUrl: string | null = null
    if (imageUrl) {
      try {
        const imgRes = await fetch(imageUrl)
        if (imgRes.ok) {
          const buf = await imgRes.arrayBuffer()
          const b64 = Buffer.from(buf).toString('base64')
          const ct = imgRes.headers.get('content-type') ?? 'image/jpeg'
          imgDataUrl = `data:${ct};base64,${b64}`
        }
      } catch { /* no image */ }
    }

    // 3. Return image
    return new ImageResponse(
      (
        <div
          style={{
            width: '1000px',
            height: '1500px',
            display: 'flex',
            flexDirection: 'column',
            backgroundColor: '#FFFFFF',
            fontFamily: 'sans-serif',
            border: '4px solid #0A0A0A',
          }}
        >
          {/* Product image */}
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
            {imgDataUrl
              ? <img src={imgDataUrl} alt="" style={{ maxWidth: '700px', maxHeight: '800px' }} /> // eslint-disable-line
              : <div style={{ fontSize: '80px', display: 'flex' }}>📦</div>
            }
          </div>

          {/* Info bar */}
          <div
            style={{
              backgroundColor: '#FFE500',
              padding: '44px 52px 40px',
              display: 'flex',
              flexDirection: 'column',
              gap: '14px',
            }}
          >
            <div style={{ backgroundColor: '#0A0A0A', color: '#FFE500', padding: '4px 12px', fontSize: '12px', fontWeight: 700, letterSpacing: '0.15em', display: 'flex', width: 'fit-content' }}>
              CRAZY BABO BAZAR
            </div>
            <div style={{ fontSize: name.length > 40 ? '30px' : '36px', fontWeight: 800, color: '#0A0A0A', lineHeight: 1.15, display: 'flex' }}>
              {name}
            </div>
            {tagline && (
              <div style={{ fontSize: '18px', color: '#333333', lineHeight: 1.4, display: 'flex' }}>
                {tagline.length > 80 ? tagline.slice(0, 80) + '…' : tagline}
              </div>
            )}
            <div style={{ marginTop: '8px', fontSize: '15px', fontWeight: 700, color: '#0A0A0A', display: 'flex' }}>
              crazybabobazar.com
            </div>
          </div>
        </div>
      ),
      { width: 1000, height: 1500 }
    )
  } catch (err) {
    console.error('[pin] error:', err)
    return new Response(`Error: ${String(err)}`, { status: 500, headers: { 'content-type': 'text/plain' } })
  }
}
