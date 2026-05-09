'use client'

import { useState } from 'react'
import { Share2, Check } from 'lucide-react'

export function ShareButton({ name, tagline }: { name: string; tagline?: string | null }) {
  const [copied, setCopied] = useState(false)

  const handleShare = async () => {
    const url = window.location.href
    const text = tagline ?? name

    if (navigator.share) {
      try {
        await navigator.share({ title: name, text, url })
      } catch {
        // user cancelled — no action needed
      }
      return
    }

    // Fallback: copy to clipboard
    try {
      await navigator.clipboard.writeText(url)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // clipboard blocked — ignore
    }
  }

  return (
    <button
      onClick={handleShare}
      className="flex items-center justify-center gap-2 w-full border-2 border-[#0A0A0A] py-3 text-sm font-bold text-[#0A0A0A] hover:bg-[#0A0A0A] hover:text-white transition-all duration-200"
    >
      {copied ? (
        <>
          <Check size={14} />
          Link kopiert!
        </>
      ) : (
        <>
          <Share2 size={14} />
          Teilen
        </>
      )}
    </button>
  )
}
