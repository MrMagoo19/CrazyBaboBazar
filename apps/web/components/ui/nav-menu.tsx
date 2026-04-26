"use client"

import * as React from "react"
import { useState, useEffect, useRef } from "react"
import { createPortal } from "react-dom"
import Link from "next/link"
import {
  Flame, Crown, Sparkles, Rocket, Users, Equal, Search as SearchIcon, X,
  BriefcaseBusiness, UtensilsCrossed, PartyPopper, Zap,
} from "lucide-react"
import { Sheet, SheetTrigger, SheetContent } from "@/components/ui/sheet"

// ── Types ──────────────────────────────────────────────────────────────────
type MenuName = "trending" | "babos" | "queens" | "miniboss" | "squad" | null

interface SubItem { label: string; href: string; icon: React.ElementType; desc: string }
interface NavItem { key: MenuName; label: string; icon: React.ElementType; sub: SubItem[] }

// ── Real Supabase categories ───────────────────────────────────────────────
const CAT_LUSTIG:   SubItem = { label: "Lustige Gadgets",       href: "/kategorie/lustige-gadgets",    icon: PartyPopper,      desc: "Kurioses & Witziges" }
const CAT_MAENNER:  SubItem = { label: "Geschenke für Männer",  href: "/kategorie/geschenke-maenner",  icon: Crown,            desc: "Gadgets & Lifestyle" }
const CAT_BUERO:    SubItem = { label: "Büro-Gadgets",          href: "/kategorie/buero-gadgets",      icon: BriefcaseBusiness,desc: "Smarte Schreibtisch-Helfer" }
const CAT_KUECHE:   SubItem = { label: "Küchen-Gadgets",        href: "/kategorie/kuechen-gadgets",    icon: UtensilsCrossed,  desc: "Coole Küchenhelfer" }
const CAT_UNTER20:  SubItem = { label: "Unter 20€",             href: "/kategorie/geschenke-unter-20", icon: Zap,              desc: "Bestes fürs kleine Budget" }

const ALL_CATS = [CAT_LUSTIG, CAT_MAENNER, CAT_BUERO, CAT_KUECHE, CAT_UNTER20]

const NAV: NavItem[] = [
  { key: "trending",  label: "Trending",  icon: Flame,     sub: ALL_CATS },
  { key: "babos",     label: "Babos",     icon: Crown,     sub: [CAT_MAENNER, CAT_BUERO, CAT_LUSTIG, CAT_UNTER20] },
  { key: "queens",    label: "Queens",    icon: Sparkles,  sub: [CAT_KUECHE, CAT_UNTER20, CAT_LUSTIG, CAT_MAENNER] },
  { key: "miniboss",  label: "Miniboss",  icon: Rocket,    sub: [CAT_LUSTIG, CAT_UNTER20, CAT_MAENNER] },
  { key: "squad",     label: "Squad",     icon: Users,     sub: [CAT_LUSTIG, CAT_UNTER20, CAT_MAENNER, CAT_KUECHE] },
]

// ── Search Modal ───────────────────────────────────────────────────────────
export function NavSearch() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState("")
  const [mounted, setMounted] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

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
    else setQuery("")
  }, [open])

  const filtered = query.length > 0
    ? ALL_CATS.filter(c => c.label.toLowerCase().includes(query.toLowerCase()))
    : ALL_CATS

  const modal = open && (
    <>
      <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" style={{ zIndex: 9998 }} onClick={() => setOpen(false)} />
      <div className="fixed left-1/2 top-1/3 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 px-4" style={{ zIndex: 9999 }}>
        <div className="bg-[#1C1C1C] border border-[#333333] border-t-2 border-t-[#E85000] shadow-2xl">
          <div className="flex items-center gap-3 px-4 py-3 border-b border-[#2A2A2A]">
            <SearchIcon size={15} className="text-[#6B6560] shrink-0" />
            <input
              ref={inputRef}
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Kategorie suchen…"
              className="flex-1 bg-transparent text-sm text-[#F0EDE8] placeholder:text-[#6B6560] outline-none"
            />
            <button onClick={() => setOpen(false)} className="text-[#6B6560] hover:text-[#F0EDE8] transition-colors">
              <X size={14} />
            </button>
          </div>
          <div className="p-2">
            {filtered.length === 0 ? (
              <p className="px-4 py-6 text-center text-sm text-[#6B6560]">Nichts gefunden.</p>
            ) : filtered.map(item => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="flex items-center gap-3 px-3 py-2.5 hover:bg-[#252525] hover:text-[#E85000] text-[#9E9890] text-sm transition-colors group"
              >
                <item.icon size={13} className="shrink-0 opacity-60 group-hover:opacity-100 group-hover:text-[#E85000]" />
                <div>
                  <div className="font-medium text-[#F0EDE8] group-hover:text-[#E85000]">{item.label}</div>
                  <div className="text-[11px] text-[#6B6560]">{item.desc}</div>
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
        className="flex items-center gap-1.5 text-[#6B6560] hover:text-[#F0EDE8] transition-colors"
        aria-label="Suche öffnen"
      >
        <SearchIcon size={16} />
        <span className="hidden lg:inline text-xs opacity-60">⌘K</span>
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
        style={{ position: "fixed", left: 0, right: 0, top: 64, zIndex: 9000 }}
        className="w-screen border-b border-[#333333] bg-[#1C1C1C] shadow-2xl"
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
          <div className="flex items-center gap-2 mb-4">
            <item.icon size={13} className="text-[#E85000]" />
            <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">{item.label}</span>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
            {item.sub.map(sub => (
              <Link
                key={sub.href}
                href={sub.href}
                onClick={() => setActiveMenu(null)}
                className="flex flex-col gap-1 px-3 py-3 border border-[#2A2A2A] hover:border-[#E85000] hover:bg-[#252525] transition-all duration-150 group"
              >
                <div className="flex items-center gap-2">
                  <sub.icon size={13} className="text-[#6B6560] group-hover:text-[#E85000] transition-colors shrink-0" />
                  <span className="text-sm font-semibold text-[#F0EDE8] group-hover:text-[#E85000] transition-colors">
                    {sub.label}
                  </span>
                </div>
                <span className="text-[11px] text-[#6B6560] pl-5">{sub.desc}</span>
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
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-bold uppercase tracking-wide transition-colors
                ${activeMenu === item.key ? "text-[#E85000]" : "text-[#9E9890] hover:text-[#F0EDE8]"}`}
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
        <button className="md:hidden text-[#9E9890] hover:text-[#F0EDE8] transition-colors" aria-label="Menü öffnen">
          <Equal size={20} />
        </button>
      </SheetTrigger>
      <SheetContent side="right" className="w-[300px] bg-[#1C1C1C] border-l border-[#333333] p-0">
        <nav className="flex flex-col py-6 overflow-y-auto h-full">
          <div className="px-6 pb-4 border-b border-[#252525]">
            <p className="text-[10px] font-bold uppercase tracking-widest text-[#6B6560] mb-3">Kategorien</p>
            {ALL_CATS.map(cat => (
              <Link
                key={cat.href}
                href={cat.href}
                className="flex items-center gap-2 py-2.5 text-sm text-[#9E9890] hover:text-[#E85000] transition-colors"
              >
                <cat.icon size={13} className="opacity-60 shrink-0" />
                {cat.label}
              </Link>
            ))}
          </div>
          <div className="px-6 pt-6 space-y-2">
            <Link href="/impressum" className="block text-xs text-[#3A3A3A] hover:text-[#6B6560] transition-colors">Impressum</Link>
            <Link href="/datenschutz" className="block text-xs text-[#3A3A3A] hover:text-[#6B6560] transition-colors">Datenschutz</Link>
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
