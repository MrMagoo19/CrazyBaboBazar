"use client"

import * as React from "react"
import { useState, useEffect, useRef } from "react"
import { createPortal } from "react-dom"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Search as SearchIcon, X, Equal, ChevronDown,
  Gamepad2, Laptop, UtensilsCrossed, Sparkles, TreePine, Flower2, Baby, Dumbbell, Home, Zap,
} from "lucide-react"
import { createClient } from "@/utils/supabase/client"

// ── Config ────────────────────────────────────────────────────────────────────
type DropdownItem = { label: string; href: string; icon: React.ElementType; desc: string }

const THEMEN: DropdownItem[] = [
  { label: "Gaming",          href: "/thema/gaming",    icon: Gamepad2,        desc: "Tabletop, Retro & Collectibles" },
  { label: "Tech & Setup",    href: "/thema/tech",      icon: Laptop,          desc: "Gadgets & Schreibtisch" },
  { label: "Küche",           href: "/thema/kueche",    icon: UtensilsCrossed, desc: "Küchengeräte & Kulinarisches" },
  { label: "Lifestyle",       href: "/thema/lifestyle", icon: Sparkles,        desc: "Party, Bar & Fun" },
  { label: "Outdoor",         href: "/thema/outdoor",   icon: TreePine,        desc: "Camping & Survival" },
  { label: "Beauty & Pflege", href: "/thema/beauty",    icon: Flower2,         desc: "Pflege & Wellness" },
  { label: "Spielzeug",       href: "/thema/spielzeug", icon: Baby,            desc: "STEM & Kinderspaß" },
  { label: "Fitness",         href: "/thema/fitness",   icon: Dumbbell,        desc: "Training & Recovery" },
  { label: "Haushalt",        href: "/thema/haushalt",  icon: Home,            desc: "Smarte Alltagshelfer" },
]

const PREISE: DropdownItem[] = [
  { label: "Alle Produkte", href: "/trending",   icon: Zap, desc: "Kompletter Überblick" },
  { label: "Unter 20€",     href: "/unter-20",   icon: Zap, desc: "Günstig & gut" },
  { label: "Unter 50€",     href: "/unter-50",   icon: Zap, desc: "Top Preis-Leistung" },
  { label: "Unter 100€",    href: "/unter-100",  icon: Zap, desc: "Gute Mitte" },
  { label: "Unter 200€",    href: "/unter-200",  icon: Zap, desc: "Für besondere Anlässe" },
  { label: "Über 200€",     href: "/ueber-200",  icon: Zap, desc: "Premium & No-Compromise" },
]

// ── Search Modal ──────────────────────────────────────────────────────────────
type ProductResult = { slug: string; name: string; tagline: string | null; image_url: string | null }

export function NavSearch() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState("")
  const [results, setResults] = useState<ProductResult[]>([])
  const [loading, setLoading] = useState(false)
  const [mounted, setMounted] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => { setMounted(true) }, [])

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) { e.preventDefault(); setOpen(o => !o) }
      if (e.key === "Escape") setOpen(false)
    }
    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [])

  useEffect(() => {
    if (open) setTimeout(() => inputRef.current?.focus(), 50)
    else { setQuery(""); setResults([]) }
  }, [open])

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    if (query.trim().length < 2) { setResults([]); return }
    debounceRef.current = setTimeout(async () => {
      setLoading(true)
      const sb = createClient()
      const { data } = await sb
        .from("products")
        .select("slug, name, tagline, image_url")
        .eq("is_published", true)
        .or(`name.ilike.%${query}%,description.ilike.%${query}%,tagline.ilike.%${query}%,brand.ilike.%${query}%`)
        .limit(8)
      setResults(data ?? [])
      setLoading(false)
    }, 250)
  }, [query])

  const modal = open && (
    <>
      <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" style={{ zIndex: 9998 }} onClick={() => setOpen(false)} />
      <div style={{ position: 'fixed', top: '72px', left: '50%', transform: 'translateX(-50%)', width: '100%', maxWidth: '520px', padding: '0 1rem', zIndex: 9999 }}>
        <div className="bg-white border-2 border-[#0A0A0A] border-t-4 border-t-[#FFE500]" style={{ boxShadow: '5px 5px 0px #0A0A0A' }}>
          <div className="flex items-center gap-3 px-4 py-3 border-b-2 border-[#0A0A0A]">
            <SearchIcon size={15} className="text-[#0A0A0A] shrink-0" />
            <input
              ref={inputRef}
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Produkt suchen… z.B. Massagepistole, Gaming, Küche"
              className="flex-1 bg-transparent text-sm text-[#0A0A0A] placeholder:text-[#999] outline-none font-[family-name:var(--font-body)]"
            />
            <button onClick={() => setOpen(false)} className="text-[#555] hover:text-[#0A0A0A] transition-colors">
              <X size={14} />
            </button>
          </div>
          <div className="p-2 max-h-[60vh] overflow-y-auto">
            {query.length < 2 ? (
              <p className="px-4 py-4 text-center text-xs text-[#999] font-[family-name:var(--font-mono)]">Mindestens 2 Zeichen eingeben…</p>
            ) : loading ? (
              <p className="px-4 py-4 text-center text-xs text-[#999] font-[family-name:var(--font-mono)]">Suche…</p>
            ) : results.length === 0 ? (
              <p className="px-4 py-6 text-center text-sm text-[#555]">Nichts gefunden für „{query}"</p>
            ) : results.map(item => (
              <Link
                key={item.slug}
                href={`/produkt/${item.slug}`}
                onClick={() => setOpen(false)}
                className="flex items-center gap-3 px-3 py-2.5 hover:bg-[#FFE500] transition-colors group border-b border-[#E0E0E0] last:border-0"
              >
                <div className="w-10 h-10 bg-[#F5F5F5] border border-[#E0E0E0] shrink-0 flex items-center justify-center overflow-hidden">
                  {item.image_url
                    ? <img src={item.image_url} alt="" className="w-full h-full object-contain p-1" />
                    : <span className="text-xl">📦</span>
                  }
                </div>
                <div className="min-w-0">
                  <div className="text-sm font-bold text-[#0A0A0A] truncate">{item.name}</div>
                  {item.tagline && <div className="text-[11px] text-[#555] truncate">{item.tagline}</div>}
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </>
  )

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-1.5 text-white hover:text-[#FFE500] transition-colors font-[family-name:var(--font-mono)] text-xs font-bold"
        aria-label="Suche öffnen"
      >
        <SearchIcon size={16} />
        <span className="hidden lg:inline">⌘K</span>
      </button>
      {mounted && createPortal(modal, document.body)}
    </>
  )
}

// ── Shared Dropdown Grid ──────────────────────────────────────────────────────
function DropdownGrid({ items, onClose }: { items: DropdownItem[]; onClose: () => void }) {
  return (
    <div className="grid grid-cols-3 md:grid-cols-5 gap-2">
      {items.map(item => (
        <Link
          key={item.href}
          href={item.href}
          onClick={onClose}
          className="flex flex-col gap-1 px-3 py-3 transition-all duration-150"
          style={{ border: '2px solid #0A0A0A', backgroundColor: '#FFFFFF' }}
          onMouseEnter={e => {
            const el = e.currentTarget as HTMLElement
            el.style.backgroundColor = '#0A0A0A'
            el.querySelectorAll('[data-label]').forEach(n => ((n as HTMLElement).style.color = '#FFE500'))
            el.querySelectorAll('[data-desc]').forEach(n => ((n as HTMLElement).style.color = '#888'))
            el.querySelectorAll('svg').forEach(n => ((n as unknown as HTMLElement).style.color = '#FFE500'))
          }}
          onMouseLeave={e => {
            const el = e.currentTarget as HTMLElement
            el.style.backgroundColor = '#FFFFFF'
            el.querySelectorAll('[data-label]').forEach(n => ((n as HTMLElement).style.color = '#0A0A0A'))
            el.querySelectorAll('[data-desc]').forEach(n => ((n as HTMLElement).style.color = '#555555'))
            el.querySelectorAll('svg').forEach(n => ((n as unknown as HTMLElement).style.color = '#0A0A0A'))
          }}
        >
          <div className="flex items-center gap-2">
            <item.icon size={13} className="shrink-0" style={{ color: '#0A0A0A', transition: 'color 0.15s' }} />
            <span data-label className="text-sm font-bold" style={{ color: '#0A0A0A' }}>{item.label}</span>
          </div>
          <span data-desc className="text-[11px] pl-5" style={{ color: '#555555' }}>{item.desc}</span>
        </Link>
      ))}
    </div>
  )
}

// ── Desktop Nav ───────────────────────────────────────────────────────────────
type OpenMenu = "themen" | "preis" | null

export function DesktopNav() {
  const [open, setOpen] = useState<OpenMenu>(null)
  const [mounted, setMounted] = useState(false)
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const pathname = usePathname()

  useEffect(() => { setMounted(true) }, [])

  const openMenu = (key: OpenMenu) => {
    if (closeTimer.current) clearTimeout(closeTimer.current)
    setOpen(key)
  }
  const scheduleClose = () => {
    closeTimer.current = setTimeout(() => setOpen(null), 300)
  }

  useEffect(() => {
    const handler = () => setOpen(null)
    document.addEventListener("click", handler)
    return () => document.removeEventListener("click", handler)
  }, [])

  const isThemenActive = pathname?.startsWith('/thema')
  const isListenActive = pathname?.startsWith('/listen')
  const isGuideActive = pathname?.startsWith('/guide')
  const isPreisActive = ['/trending', '/unter-20', '/unter-50', '/unter-100', '/unter-200', '/ueber-200'].includes(pathname ?? '')

  const dropdown = open && (
    <div
      onMouseEnter={() => openMenu(open)}
      onMouseLeave={scheduleClose}
      style={{ position: "fixed", left: 0, right: 0, top: 64, zIndex: 9000, backgroundColor: '#FFE500', borderBottom: '2px solid #0A0A0A' }}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        <div className="text-[10px] font-black uppercase tracking-widest text-[#0A0A0A] mb-4">
          {open === "themen" ? "Themen" : "Nach Preis"}
        </div>
        <DropdownGrid
          items={open === "themen" ? THEMEN : PREISE}
          onClose={() => setOpen(null)}
        />
      </div>
    </div>
  )

  return (
    <div className="hidden md:block" onClick={e => e.stopPropagation()}>
      <nav className="flex items-center">

        {/* Themen */}
        <div onMouseEnter={() => openMenu("themen")} onMouseLeave={scheduleClose}>
          <button
            onClick={e => { e.stopPropagation(); setOpen(o => o === "themen" ? null : "themen") }}
            className={`flex items-center gap-1 px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors font-[family-name:var(--font-mono)] ${
              open === "themen" || isThemenActive ? 'text-[#FFE500]' : 'text-white hover:text-[#FFE500]'
            }`}
          >
            Themen
            <ChevronDown size={11} className={`transition-transform duration-150 ${open === "themen" ? 'rotate-180' : ''}`} />
          </button>
        </div>

        {/* Listen */}
        <Link
          href="/listen"
          className={`px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors font-[family-name:var(--font-mono)] ${
            isListenActive ? 'text-[#FFE500]' : 'text-white hover:text-[#FFE500]'
          }`}
        >
          Listen
        </Link>

        {/* Guides */}
        <Link
          href="/guide"
          className={`px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors font-[family-name:var(--font-mono)] ${
            isGuideActive ? 'text-[#FFE500]' : 'text-white hover:text-[#FFE500]'
          }`}
        >
          Guides
        </Link>

        {/* Preis */}
        <div onMouseEnter={() => openMenu("preis")} onMouseLeave={scheduleClose}>
          <button
            onClick={e => { e.stopPropagation(); setOpen(o => o === "preis" ? null : "preis") }}
            className={`flex items-center gap-1 px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors font-[family-name:var(--font-mono)] ${
              open === "preis" || isPreisActive ? 'text-[#FFE500]' : 'text-white hover:text-[#FFE500]'
            }`}
          >
            Preis
            <ChevronDown size={11} className={`transition-transform duration-150 ${open === "preis" ? 'rotate-180' : ''}`} />
          </button>
        </div>

      </nav>
      {mounted && createPortal(dropdown, document.body)}
    </div>
  )
}

// ── Mobile Menu ───────────────────────────────────────────────────────────────
function MobileSheet() {
  const [open, setOpen] = useState(false)
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])

  const sectionLabel = (text: string, topBorder = false) => (
    <div style={{
      padding: '12px 24px 4px',
      fontSize: '9px', fontWeight: 900, textTransform: 'uppercase' as const,
      letterSpacing: '0.12em', color: '#999', fontFamily: 'var(--font-mono)',
      ...(topBorder ? { borderTop: '2px solid #0A0A0A', marginTop: '8px' } : {}),
    }}>
      {text}
    </div>
  )

  const menu = open ? (
    <>
      <div onClick={() => setOpen(false)} style={{ position: 'fixed', inset: 0, zIndex: 9998, backgroundColor: 'rgba(0,0,0,0.6)' }} />
      <div style={{
        position: 'fixed', top: 0, right: 0, bottom: 0, zIndex: 9999,
        width: '300px', maxWidth: '85vw',
        backgroundColor: '#FFFFFF', borderLeft: '2px solid #0A0A0A',
        display: 'flex', flexDirection: 'column', overflowY: 'auto',
      }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '2px solid #0A0A0A' }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: '10px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em', background: '#FFE500', color: '#0A0A0A', padding: '2px 8px' }}>
            Menü
          </span>
          <button onClick={() => setOpen(false)} style={{ color: '#0A0A0A', padding: '4px', background: 'none', border: 'none', cursor: 'pointer' }}>
            <X size={18} />
          </button>
        </div>

        <nav style={{ flex: 1, padding: '8px 0' }}>
          {/* Themen */}
          {sectionLabel("Themen")}
          {THEMEN.map(item => (
            <Link key={item.href} href={item.href} onClick={() => setOpen(false)}
              style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 24px', fontSize: '14px', fontWeight: 500, color: '#0A0A0A', textDecoration: 'none', borderBottom: '1px solid #F0F0F0' }}>
              <item.icon size={14} style={{ flexShrink: 0 }} />
              {item.label}
            </Link>
          ))}

          {/* Preis */}
          {sectionLabel("Nach Preis", true)}
          {PREISE.map(item => (
            <Link key={item.href} href={item.href} onClick={() => setOpen(false)}
              style={{ display: 'flex', alignItems: 'center', padding: '10px 24px', fontSize: '14px', fontWeight: 700, color: '#0A0A0A', textDecoration: 'none', borderBottom: '1px solid #F0F0F0', fontFamily: 'var(--font-mono)' }}>
              {item.label}
            </Link>
          ))}

          {/* Kuratiert */}
          {sectionLabel("Kuratiert", true)}
          <Link href="/listen" onClick={() => setOpen(false)}
            style={{ display: 'flex', alignItems: 'center', padding: '10px 24px', fontSize: '14px', fontWeight: 700, color: '#0A0A0A', textDecoration: 'none', borderBottom: '1px solid #F0F0F0', fontFamily: 'var(--font-mono)' }}>
            Listen
          </Link>
          <Link href="/guide" onClick={() => setOpen(false)}
            style={{ display: 'flex', alignItems: 'center', padding: '10px 24px', fontSize: '14px', fontWeight: 700, color: '#0A0A0A', textDecoration: 'none', borderBottom: '1px solid #F0F0F0', fontFamily: 'var(--font-mono)' }}>
            Guides
          </Link>
        </nav>

        {/* Footer */}
        <div style={{ padding: '16px 24px', borderTop: '2px solid #0A0A0A' }}>
          <Link
            href="/entdecken"
            onClick={() => setOpen(false)}
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', backgroundColor: '#FFE500', color: '#0A0A0A', padding: '12px', fontFamily: 'var(--font-mono)', fontSize: '12px', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.12em', textDecoration: 'none', marginBottom: '12px' }}
          >
            ♥ Swipe Area
          </Link>
          <div style={{ display: 'flex', gap: '16px' }}>
            <Link href="/impressum" onClick={() => setOpen(false)} style={{ fontSize: '11px', color: '#555', fontFamily: 'var(--font-mono)' }}>Impressum</Link>
            <Link href="/datenschutz" onClick={() => setOpen(false)} style={{ fontSize: '11px', color: '#555', fontFamily: 'var(--font-mono)' }}>Datenschutz</Link>
          </div>
        </div>
      </div>
    </>
  ) : null

  return (
    <>
      <button className="md:hidden text-white hover:text-[#FFE500] transition-colors" aria-label="Menü öffnen" onClick={() => setOpen(true)}>
        <Equal size={20} />
      </button>
      {mounted && createPortal(menu, document.body)}
    </>
  )
}

// ── Export ────────────────────────────────────────────────────────────────────
export function NavMenus() {
  return (
    <>
      <DesktopNav />
      <MobileSheet />
    </>
  )
}
