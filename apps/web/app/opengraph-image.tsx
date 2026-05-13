import { ImageResponse } from 'next/og'

export const runtime = 'edge'
export const alt = 'Crazy Babo Bazar — Kuriose Produkte für schlaue Käufer'
export const size = { width: 1200, height: 630 }
export const contentType = 'image/png'

export default function OGImage() {
  return new ImageResponse(
    (
      <div style={{ width: '1200px', height: '630px', display: 'flex', flexDirection: 'column', backgroundColor: '#0A0A0A', fontFamily: 'sans-serif', position: 'relative' }}>
        {/* Yellow accent bar */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '8px', backgroundColor: '#FFE500' }} />

        {/* Content */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px' }}>
          {/* Logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '40px' }}>
            <div style={{ backgroundColor: '#FFE500', color: '#0A0A0A', padding: '8px 20px', fontSize: '32px', fontWeight: 900, letterSpacing: '-1px' }}>
              CRAZY
            </div>
            <div style={{ color: '#FFFFFF', fontSize: '32px', fontWeight: 900, letterSpacing: '-1px' }}>
              BABO BAZAR
            </div>
          </div>

          {/* Tagline */}
          <div style={{ color: '#FFFFFF', fontSize: '52px', fontWeight: 900, textAlign: 'center', lineHeight: 1.1, marginBottom: '24px', letterSpacing: '-2px' }}>
            Kuriose Produkte für schlaue Käufer
          </div>

          <div style={{ color: '#888888', fontSize: '24px', textAlign: 'center', letterSpacing: '0.05em' }}>
            Gadgets · Geschenke · Lifestyle · Wellness
          </div>
        </div>

        {/* Bottom bar */}
        <div style={{ backgroundColor: '#FFE500', padding: '16px 60px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ color: '#0A0A0A', fontSize: '18px', fontWeight: 900, letterSpacing: '0.1em' }}>
            crazybabobazar.com
          </div>
          <div style={{ color: '#0A0A0A', fontSize: '16px', fontWeight: 700 }}>
            100+ handverlesene Produkte
          </div>
        </div>
      </div>
    ),
    { ...size }
  )
}
