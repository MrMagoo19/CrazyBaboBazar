import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

import { guides } from './guides'

describe('Guide-Cover', () => {
  it.each(guides.map((g) => ({ slug: g.slug, cover: g.cover })))(
    '$slug zeigt auf /images/guides/<slug>.webp',
    ({ slug, cover }) => {
      expect(cover).toBe(`/images/guides/${slug}.webp`)
    }
  )

  it.each(guides.map((g) => ({ slug: g.slug, cover: g.cover })))(
    '$slug hat eine tatsaechlich vorhandene Cover-Datei unter public/',
    ({ cover }) => {
      const file = join(process.cwd(), 'public', cover)
      expect(existsSync(file), `${file} fehlt`).toBe(true)
    }
  )
})
