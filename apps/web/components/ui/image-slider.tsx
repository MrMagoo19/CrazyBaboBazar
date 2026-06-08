"use client"

import { useState } from "react"
import Image from "next/image"

type Props = {
  images: string[]
  name: string
  isFeatured?: boolean
}

export function ImageSlider({ images, name, isFeatured }: Props) {
  const [active, setActive] = useState(0)

  if (images.length === 0) return null

  const prev = () => setActive(i => (i - 1 + images.length) % images.length)
  const next = () => setActive(i => (i + 1) % images.length)

  return (
    <div className="flex flex-col w-full lg:w-1/2 shrink-0">
      {/* Main image */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          border: '2px solid #0A0A0A',
          aspectRatio: '1 / 1',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <Image
          key={active}
          src={images[active]}
          alt={`${name} Bild ${active + 1}`}
          fill
          className="object-contain p-8"
          sizes="(max-width: 1024px) 100vw, 50vw"
          priority={active === 0}
        />

        {isFeatured && (
          <div className="absolute top-6 left-6 z-10">
            <span className="bg-[#FFE500] text-[#0A0A0A] text-xs font-black px-3 py-1 uppercase tracking-wide">
              Featured
            </span>
          </div>
        )}

        {/* Arrows — only if more than one image */}
        {images.length > 1 && (
          <>
            <button
              onClick={prev}
              aria-label="Vorheriges Bild"
              className="absolute left-3 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white border-2 border-[#0A0A0A] hover:bg-[#FFE500] transition-colors font-black text-lg"
            >
              ‹
            </button>
            <button
              onClick={next}
              aria-label="Nächstes Bild"
              className="absolute right-3 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white border-2 border-[#0A0A0A] hover:bg-[#FFE500] transition-colors font-black text-lg"
            >
              ›
            </button>
            {/* Counter */}
            <div className="absolute bottom-3 right-3 bg-[#0A0A0A] text-white text-[10px] font-bold font-mono px-2 py-0.5">
              {active + 1} / {images.length}
            </div>
          </>
        )}
      </div>

      {/* Thumbnails */}
      {images.length > 1 && (
        <div className="flex gap-0 border-l-2 border-r-2 border-b-2 border-[#0A0A0A] overflow-x-auto">
          {images.map((src, i) => (
            <button
              key={i}
              onClick={() => setActive(i)}
              className="shrink-0 w-16 h-16 relative border-r-2 border-[#0A0A0A] last:border-r-0 overflow-hidden transition-colors"
              style={{ backgroundColor: i === active ? '#FFE500' : '#F5F5F5' }}
              aria-label={`Bild ${i + 1}`}
            >
              <Image
                src={src}
                alt={`${name} ${i + 1}`}
                fill
                className="object-contain p-1.5"
                sizes="64px"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
