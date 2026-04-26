"use client"

import * as React from "react"
import { useState, useEffect, useRef } from "react"
import Link from "next/link"
import {
  Flame, Crown, Sparkles, Rocket, Users, Equal, Search as SearchIcon, X,
  Cpu, BriefcaseBusiness, UtensilsCrossed, TreePine, PartyPopper,
  Flower2, Home, Dumbbell, Gamepad2, Palette, Zap, Heart, Plane,
} from "lucide-react"
import { Sheet, SheetTrigger, SheetContent } from "@/components/ui/sheet"

// ── Types ──────────────────────────────────────────────────────────────────
type MenuName = "trending" | "babos" | "queens" | "miniboss" | "squad" | null

interface SubItem { label: string; href: string; icon: React.ElementType }
interface NavItem { key: MenuName; label: string; icon: React.ElementType; sub: SubItem[] }

// ── Nav Data ───────────────────────────────────────────────────────────────
const NAV: NavItem[] = [
  {
    key: "trending", label: "Trending", icon: Flame,
    sub: [
      { label: "Viral Hits", href: "/kategorie/lustige-gadgets", icon: Zap },
      { label: "Neuheiten", href: "/kategorie/lustige-gadgets", icon: Sparkles },
      { label: "Bestseller", href: "/kategorie/geschenke-maenner", icon: Crown },
    ],
  },
  {
    key: "babos", label: "Babos", icon: Crown,
    sub: [
      { label: "Tech & Gadgets", href: "/kategorie/lustige-gadgets", icon: Cpu },
      { label: "Büro & Produktivität", href: "/kategorie/buero-gadgets", icon: BriefcaseBusiness },
      { label: "Grillen & Küche", href: "/kategorie/kuechen-gadgets", icon: UtensilsCrossed },
      { label: "Outdoor & Sport", href: "/kategorie/geschenke-maenner", icon: TreePine },
      { label: "Fun & Lifestyle", href: "/kategorie/geschenke-unter-20", icon: PartyPopper },
    ],
  },
  {
    key: "queens", label: "Queens", icon: Sparkles,
    sub: [
      { label: "Beauty & Wellness", href: "/kategorie/lustige-gadgets", icon: Flower2 },
      { label: "Home & Deko", href: "/kategorie/kuechen-gadgets", icon: Home },
      { label: "Fitness & Yoga", href: "/kategorie/geschenke-maenner", icon: Dumbbell },
      { label: "Fun & Lifestyle", href: "/kategorie/geschenke-unter-20", icon: Heart },
    ],
  },
  {
    key: "miniboss", label: "Miniboss", icon: Rocket,
    sub: [
      { label: "Lernspielzeug", href: "/kategorie/lustige-gadgets", icon: Palette },
      { label: "Outdoor & Action", href: "/kategorie/geschenke-maenner", icon: TreePine },
      { label: "Gaming & Tech", href: "/kategorie/buero-gadgets", icon: Gamepad2 },
      { label: "Kreativität", href: "/kategorie/lustige-gadgets", icon: Sparkles },
    ],
  },
  {
    key: "squad", label: "Squad", icon: Users,
    sub: [
      { label: "Party & Spiele", href: "/kategorie/lustige-gadgets", icon: PartyPopper },
      { label: "Date Night", href: "/kategorie/geschenke-unter-20", icon: Heart },
      { label: "Reise & Abenteuer", href: "/kategorie/geschenke-maenner", icon: Plane },
      { label: "Gemeinsam aktiv", href: "/kategorie/geschenke-maenner", icon: Users },
    ],
  },
]

// ── Custom Search Modal (kein CSS-Variablen-Problem) ───────────────────────
export function NavSearch() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState("")
  const inputRef = useRef<HTMLInputElement>(null)

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

  const allItems = NAV.flatMap(n => n.sub.map(s => ({ ...s, group: n.label, groupIcon: n.icon })))
  const filtered = query.length > 0
    ? allItems.filter(i => i.label.toLowerCase().includes(query.toLowerCase()) || i.group.toLowerCase().includes(query.toLowerCase()))
    : allItems

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

      {open && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-[200] bg-black/60 backdrop-blur-sm"
            onClick={() => setOpen(false)}
          />
          {/* Modal — zentriert im Viewport */}
          <div className="fixed left-1/2 top-1/3 z-[201] w-full max-w-lg -translate-x-1/2 -translate-y-1/2 px-4">
            <div className="bg-[#1C1C1C] border border-[#333333] border-t-2 border-t-[#E85000] shadow-2xl">

              {/* Input */}
              <div className="flex items-center gap-3 px-4 py-3 border-b border-[#2A2A2A]">
                <SearchIcon size={15} className="text-[#6B6560] shrink-0" />
                <input
                  ref={inputRef}
                  value={query}
                  onChange={e => setQuery(e.target.value)}
                  placeholder="Produkt oder Kategorie suchen…"
                  className="flex-1 bg-transparent text-sm text-[#F0EDE8] placeholder:text-[#6B6560] outline-none"
                />
                <button onClick={() => setOpen(false)} className="text-[#6B6560] hover:text-[#F0EDE8] transition-colors">
                  <X size={14} />
                </button>
              </div>

              {/* Results */}
              <div className="max-h-72 overflow-y-auto">
                {filtered.length === 0 ? (
                  <p className="px-4 py-6 text-center text-sm text-[#6B6560]">Nichts gefunden.</p>
                ) : (
                  <div className="p-2">
                    {NAV.map(nav => {
                      const items = filtered.filter(i => i.group === nav.label)
                      if (items.length === 0) return null
                      return (
                        <div key={nav.key} className="mb-3">
                          <div className="flex items-center gap-1.5 px-2 py-1 mb-1">
                            <nav.icon size={11} className="text-[#E85000]" />
                            <span className="text-[10px] font-bold uppercase tracking-widest text-[#6B6560]">{nav.label}</span>
                          </div>
                          {items.map(item => (
                            <Link
                              key={item.label}
                              href={item.href}
                              onClick={() => setOpen(false)}
                              className="flex items-center gap-2.5 px-3 py-2 hover:bg-[#252525] hover:text-[#E85000] text-[#9E9890] text-sm transition-colors"
                            >
                              <item.icon size={13} className="shrink-0 opacity-60" />
                              {item.label}
                            </Link>
                          ))}
                        </div>
                      )
                    })}
                  </div>
                )}
              </div>

            </div>
          </div>
        </>
      )}
    </>
  )
}

// ── Desktop Nav ────────────────────────────────────────────────────────────
export function DesktopNav() {
  const [activeMenu, setActiveMenu] = useState<MenuName>(null)
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  const openMenu = (key: MenuName) => {
    if (closeTimer.current) clearTimeout(closeTimer.current)
    setActiveMenu(key)
  }

  const scheduleClose = () => {
    closeTimer.current = setTimeout(() => setActiveMenu(null), 120)
  }

  return (
    <div className="hidden md:block relative">
      <nav className="flex items-center">
        {NAV.map((item) => (
          <div key={item.key} onMouseEnter={() => openMenu(item.key)} onMouseLeave={scheduleClose}>
            <button
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-bold uppercase tracking-wide transition-colors
                ${activeMenu === item.key ? "text-[#E85000]" : "text-[#9E9890] hover:text-[#F0EDE8]"}`}
            >
              <item.icon size={13} />
              {item.label}
            </button>
          </div>
        ))}
      </nav>

      {/* Dropdown — gleiche hover-Gruppe über onMouseEnter/Leave */}
      {NAV.map((item) => (
        activeMenu === item.key && (
          <div
            key={item.key}
            onMouseEnter={() => openMenu(item.key)}
            onMouseLeave={scheduleClose}
            className="fixed left-0 right-0 top-16 z-[999] w-screen border-b border-[#333333] bg-[#1C1C1C] shadow-2xl"
          >
            <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
              <div className="flex items-center gap-2 mb-4">
                <item.icon size={13} className="text-[#E85000]" />
                <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">{item.label}</span>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
                {item.sub.map((sub) => (
                  <Link
                    key={sub.label}
                    href={sub.href}
                    className="flex items-center gap-2.5 px-3 py-2.5 border border-[#2A2A2A] hover:border-[#E85000] hover:bg-[#252525] transition-all duration-150 group"
                  >
                    <sub.icon size={13} className="text-[#6B6560] group-hover:text-[#E85000] transition-colors shrink-0" />
                    <span className="text-sm text-[#9E9890] group-hover:text-[#F0EDE8] transition-colors font-medium">
                      {sub.label}
                    </span>
                  </Link>
                ))}
              </div>
            </div>
          </div>
        )
      ))}
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
          {NAV.map((item) => (
            <div key={item.key} className="border-b border-[#252525]">
              <div className="flex items-center gap-2 px-6 py-3">
                <item.icon size={14} className="text-[#E85000]" />
                <span className="text-xs font-bold uppercase tracking-widest text-[#6B6560]">{item.label}</span>
              </div>
              {item.sub.map((sub) => (
                <Link
                  key={sub.label}
                  href={sub.href}
                  className="flex items-center gap-2 px-8 py-2.5 text-sm text-[#9E9890] hover:text-[#E85000] hover:bg-[#252525] transition-colors"
                >
                  <sub.icon size={12} className="opacity-60 shrink-0" />
                  {sub.label}
                </Link>
              ))}
            </div>
          ))}
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
