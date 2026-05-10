import { ImageResponse } from '@vercel/og'
import { NextRequest } from 'next/server'

export const runtime = 'edge'

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params

  const res = await fetch(
    `https://ydiihvzcxaaoqhmgoqvu.supabase.co/rest/v1/products?select=name,tagline,image_url&slug=eq.${encodeURIComponent(slug)}&is_published=eq.true`,
    {
      headers: {
        apikey: 'sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
        Authorization: 'Bearer sb_publishable_tmWc6BMWU00Nx6Z_YRy7Wg_x5chkWeM',
      },
    }
  )

  const products = await res.json()
  const product = products?.[0]

  if (!product) {
    return new Response('Not found', { status: 404 })
  }

  const fontRes = await fetch(
    'https://fonts.gstatic.com/s/syne/v22/8vIS7w4qzmVxsWxjEAfa_nr.woff'
  )
  const fontData = await fontRes.arrayBuffer()

  return new ImageResponse(
    (
      <div
        style={{
          width: '1000px',
          height: '1500px',
          display: 'flex',
          flexDirection: 'column',
          backgroundColor: '#FFFFFF',
          fontFamily: 'Syne',
          outline: '4px solid #0A0A0A',
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
          {product.image_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={product.image_url}
              alt=""
              style={{ maxWidth: '720px', maxHeight: '820px', objectFit: 'contain' }}
            />
          ) : (
            <div style={{ fontSize: '80px' }}>📦</div>
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
              fontSize: '13px',
              fontWeight: 700,
              letterSpacing: '0.18em',
              textTransform: 'uppercase',
              color: '#0A0A0A',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
            }}
          >
            <div
              style={{
                backgroundColor: '#0A0A0A',
                color: '#FFE500',
                padding: '2px 10px',
                fontSize: '11px',
                letterSpacing: '0.15em',
              }}
            >
              CRAZY BABO BAZAR
            </div>
          </div>

          <div
            style={{
              fontSize: product.name.length > 40 ? '30px' : '36px',
              fontWeight: 800,
              color: '#0A0A0A',
              lineHeight: 1.15,
              display: 'flex',
            }}
          >
            {product.name}
          </div>

          {product.tagline && (
            <div
              style={{
                fontSize: '18px',
                color: '#333333',
                lineHeight: 1.4,
                display: 'flex',
              }}
            >
              {product.tagline.length > 80
                ? product.tagline.slice(0, 80) + '…'
                : product.tagline}
            </div>
          )}

          <div
            style={{
              marginTop: '8px',
              fontSize: '14px',
              fontWeight: 700,
              color: '#0A0A0A',
              letterSpacing: '0.08em',
              display: 'flex',
            }}
          >
            crazybabobazar.com →
          </div>
        </div>
      </div>
    ),
    {
      width: 1000,
      height: 1500,
      fonts: [{ name: 'Syne', data: fontData, weight: 800 }],
    }
  )
}
