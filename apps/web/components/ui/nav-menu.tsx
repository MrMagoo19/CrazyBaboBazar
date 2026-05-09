"use client"

import * as React from "react"
import { useState, useEffect, useRef } from "react"
import { createPortal } from "react-dom"
import Link from "next/link"
import {
  Flame, Crown, Sparkles, Rocket, Equal, Search as SearchIcon, X,
  BriefcaseBusiness, UtensilsCrossed, PartyPopper, Zap, Star, Leaf, Users,
} from "lucide-react"
import { Sheet, SheetTrigger, SheetContent } from "@/components/ui/sheet"
import { createClient } from "@/utils/supabase/client"

// ── Types ──────────────────────────────────────────────────────────────────
type MenuName = "trending" | "babos" | "queens" | "miniboss" | "wellness" | null

interface SubItem { label: string; href: string; icon: React.ElementType; desc: string }
interface NavItem { key: MenuName; label: string; icon: React.ElementType; sub: SubItem[] }

const NAV: NavItem[] = [
  {
    key: "trending", label: "Trending", icon: Flame, sub: [
      { label: "Alle Trends",    href: "/trending",   icon: Flame,       desc: "Was gerade abgeht" },
      { label: "Unter 20€",      href: "/unter-20",   icon: Zap,         desc: "Günstig & gut" },
      { label: "Unter 50€",      href: "/unter-50",   icon: Zap,         desc: "Gutes Preis-Leistungs-Verhältnis" },
    ],
  },
  {
    key: "babos", label: "Babos", icon: Zap, sub: [
      { label: "Alle Babos",     href: "/babos",             icon: Zap,               desc: "Komplette Babo-Welt" },
      { label: "Gaming",         href: "/babos/gaming",      icon: Rocket,            desc: "Tabletop, Retro & Collectibles" },
      { label: "Tech & DIY",     href: "/babos/tech",        icon: Zap,               desc: "Gadgets & Schreibtisch-Setup" },
      { label: "Lifestyle",      href: "/babos/lifestyle",   icon: PartyPopper,       desc: "Party, Bar & Fun" },
      { label: "Outdoor",        href: "/babos/outdoor",     icon: BriefcaseBusiness, desc: "Survival & Camping" },
    ],
  },
  {
    key: "queens", label: "Queens", icon: Crown, sub: [
      { label: "Alle Queens",    href: "/queens",             icon: Crown,            desc: "Komplette Queen-Welt" },
      { label: "Küche",          href: "/queens/kueche",      icon: UtensilsCrossed,  desc: "Gadgets & Kurioses" },
      { label: "Lifestyle",      href: "/queens/lifestyle",   icon: Sparkles,         desc: "Deko, Fandom & Mode" },
      { label: "Beauty",         href: "/queens/beauty",      icon: Sparkles,         desc: "Pflege & Kosmetik" },
      { label: "Geschenke",      href: "/queens/geschenke",   icon: PartyPopper,      desc: "Lehrer & Personalisiertes" },
    ],
  },
  {
    key: "miniboss", label: "Miniboss", icon: Star, sub: [
      { label: "Alle Miniboss",  href: "/miniboss",           icon: Star,             desc: "Komplette Miniboss-Welt" },
      { label: "Spielzeug",      href: "/miniboss/spielzeug", icon: Sparkles,         desc: "STEM, Lernen & Tiere" },
      { label: "Gaming",         href: "/miniboss/gaming",    icon: Rocket,           desc: "Spardosen & Collectibles" },
      { label: "Spaß",           href: "/miniboss/spass",     icon: PartyPopper,      desc: "Party & Outdoor-Fun" },
    ],
  },
  {
    key: "wellness", label: "Wellness", icon: Leaf, sub: [
      { label: "Alle Wellness",  href: "/wellness",           icon: Leaf,             desc: "Komplette Wellness-Welt" },
      { label: "Fitness & Sport",href: "/wellness/fitness",   icon: Zap,              desc: "Training & Recovery" },
      { label: "Beauty & Pflege",href: "/wellness/beauty",    icon: Sparkles,         desc: "Hautpflege & Komfort" },
      { label: "Outdoor",        href: "/wellness/outdoor",   icon: BriefcaseBusiness,desc: "Zelte, Solar & Rucksack" },
    ],
  },
]

const ALL_CATS = NAV.flatMap(n => n.sub)

// ── Search Modal ───────────────────────────────────────────────────────────
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
              placeholder="Produkt suchen… z.B. Muggle, Gaming, Massagepistole"
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
                  <div className="text-sm font-bold text-[#0A0A0A] group-hover:text-[#0A0A0A] truncate">{item.name}</div>
                  {item.tagline && <div className="text-[11px] text-[#555] group-hover:text-[#0A0A0A] truncate">{item.tagline}</div>}
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

// ── Desktop Nav ────────────────────────────────────────────────────────────
export function DesktopNav() {
  const [activeMenu, setActiveMenu] = useState<MenuName>(null)
  const [mounted, setMounted] = useState(false)
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => { setMounted(true) }, [])

  const openMenu = (key: MenuName) => {
    if (closeTimer.current) clearTimeout(closeTimer.current)
    setActiveMenu(key)
  }

  const scheduleClose = () => {
    closeTimer.current = setTimeout(() => setActiveMenu(null), 300)
  }

  const toggleMenu = (key: MenuName) => {
    setActiveMenu(prev => prev === key ? null : key)
  }

  useEffect(() => {
    const handler = () => setActiveMenu(null)
    document.addEventListener("click", handler)
    return () => document.removeEventListener("click", handler)
  }, [])

  const dropdown = activeMenu && (() => {
    const item = NAV.find(n => n.key === activeMenu)
    if (!item) return null
    return (
      <div
        onMouseEnter={() => openMenu(activeMenu)}
        onMouseLeave={scheduleClose}
        style={{ position: "fixed", left: 0, right: 0, top: 64, zIndex: 9000, backgroundColor: '#FFE500', borderBottom: '2px solid #0A0A0A' }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <div className="flex items-center gap-2 mb-4">
            <item.icon size={13} style={{ color: '#0A0A0A' }} />
            <span className="text-[10px] font-black uppercase tracking-widest" style={{ color: '#0A0A0A' }}>{item.label}</span>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
            {item.sub.map(sub => (
              <Link
                key={sub.href}
                href={sub.href}
                onClick={() => setActiveMenu(null)}
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
                  <sub.icon size={13} className="shrink-0" style={{ color: '#0A0A0A', transition: 'color 0.15s' }} />
                  <span data-label className="text-sm font-bold" style={{ color: '#0A0A0A' }}>
                    {sub.label}
                  </span>
                </div>
                <span data-desc className="text-[11px] pl-5" style={{ color: '#555555' }}>{sub.desc}</span>
              </Link>
            ))}
          </div>
        </div>
      </div>
    )
  })()

  return (
    <div className="hidden md:block" onClick={e => e.stopPropagation()}>
      <nav className="flex items-center">
        {NAV.map(item => (
          <div key={item.key} onMouseEnter={() => openMenu(item.key)} onMouseLeave={scheduleClose}>
            <button
              onClick={() => toggleMenu(item.key)}
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-black uppercase tracking-wide transition-colors
                ${activeMenu === item.key ? "text-[#FFE500]" : "text-white hover:text-[#FFE500]"}`}
            >
              <item.icon size={13} />
              {item.label}
            </button>
          </div>
        ))}
      </nav>
      {mounted && createPortal(dropdown, document.body)}
    </div>
  )
}

// ── Mobile Sheet ───────────────────────────────────────────────────────────
function MobileSheet() {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <button className="md:hidden text-white hover:text-[#FFE500] transition-colors" aria-label="Menü öffnen">
          <Equal size={20} />
        </button>
      </SheetTrigger>
      <SheetContent side="right" className="w-[300px] bg-white border-l-2 border-[#0A0A0A] p-0">
        <nav className="flex flex-col py-6 overflow-y-auto h-full">
          <div className="px-6 pb-4 border-b-2 border-[#0A0A0A]">
            <p className="text-[10px] font-[family-name:var(--font-mono)] font-bold uppercase tracking-widest text-[#0A0A0A] mb-3 bg-[#FFE500] inline-block px-2 py-0.5">Kategorien</p>
            {ALL_CATS.map(cat => (
              <Link
                key={cat.href}
                href={cat.href}
                className="flex items-center gap-2 py-2.5 text-sm font-medium text-[#0A0A0A] hover:text-[#FFE500] hover:bg-[#0A0A0A] px-1 transition-colors"
              >
                <cat.icon size={13} className="shrink-0" />
                {cat.label}
              </Link>
            ))}
          </div>
          <div className="px-6 pt-6 space-y-2">
            <Link href="/impressum" className="block text-xs text-[#555] hover:text-[#0A0A0A] transition-colors font-[family-name:var(--font-mono)]">Impressum</Link>
            <Link href="/datenschutz" className="block text-xs text-[#555] hover:text-[#0A0A0A] transition-colors font-[family-name:var(--font-mono)]">Datenschutz</Link>
          </div>
        </nav>
      </SheetContent>
    </Sheet>
  )
}

// ── Export ─────────────────────────────────────────────────────────────────
export function NavMenus() {
  return (
    <>
      <DesktopNav />
      <MobileSheet />
    </>
  )
}
