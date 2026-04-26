"use client"

import * as React from "react"
import { useState, useEffect } from "react"
import Link from "next/link"
import {
  Flame, Crown, Sparkles, Rocket, Users, Equal, Search as SearchIcon,
  Cpu, BriefcaseBusiness, UtensilsCrossed, TreePine, PartyPopper,
  Flower2, Home, Dumbbell, Gamepad2, Palette, Zap, Heart, Plane,
} from "lucide-react"
import {
  CommandDialog, CommandEmpty, CommandGroup, CommandInput,
  CommandItem, CommandList, CommandSeparator,
} from "@/components/ui/command"
import { Sheet, SheetTrigger, SheetContent } from "@/components/ui/sheet"

// ── Types ──────────────────────────────────────────────────────────────────
type MenuName = "trending" | "babos" | "queens" | "miniboss" | "squad" | null

interface SubItem {
  label: string
  href: string
  icon: React.ElementType
}

interface NavItem {
  key: MenuName
  label: string
  icon: React.ElementType
  sub: SubItem[]
}

// ── Nav Data ───────────────────────────────────────────────────────────────
const NAV: NavItem[] = [
  {
    key: "trending",
    label: "Trending",
    icon: Flame,
    sub: [
      { label: "Viral Hits", href: "/kategorie/trending", icon: Zap },
      { label: "Neuheiten", href: "/kategorie/trending", icon: Sparkles },
      { label: "Bestseller", href: "/kategorie/trending", icon: Crown },
    ],
  },
  {
    key: "babos",
    label: "Babos",
    icon: Crown,
    sub: [
      { label: "Tech & Gadgets", href: "/kategorie/lustige-gadgets", icon: Cpu },
      { label: "Büro & Produktivität", href: "/kategorie/buero-gadgets", icon: BriefcaseBusiness },
      { label: "Grillen & Küche", href: "/kategorie/kuechen-gadgets", icon: UtensilsCrossed },
      { label: "Outdoor & Sport", href: "/kategorie/geschenke-maenner", icon: TreePine },
      { label: "Fun & Lifestyle", href: "/kategorie/geschenke-unter-20", icon: PartyPopper },
    ],
  },
  {
    key: "queens",
    label: "Queens",
    icon: Sparkles,
    sub: [
      { label: "Beauty & Wellness", href: "/kategorie/lustige-gadgets", icon: Flower2 },
      { label: "Home & Deko", href: "/kategorie/kuechen-gadgets", icon: Home },
      { label: "Fitness & Yoga", href: "/kategorie/geschenke-maenner", icon: Dumbbell },
      { label: "Fun & Lifestyle", href: "/kategorie/geschenke-unter-20", icon: Heart },
    ],
  },
  {
    key: "miniboss",
    label: "Miniboss",
    icon: Rocket,
    sub: [
      { label: "Lernspielzeug", href: "/kategorie/lustige-gadgets", icon: Palette },
      { label: "Outdoor & Action", href: "/kategorie/geschenke-maenner", icon: TreePine },
      { label: "Gaming & Tech", href: "/kategorie/buero-gadgets", icon: Gamepad2 },
      { label: "Kreativität", href: "/kategorie/lustige-gadgets", icon: Sparkles },
    ],
  },
  {
    key: "squad",
    label: "Squad",
    icon: Users,
    sub: [
      { label: "Party & Spiele", href: "/kategorie/lustige-gadgets", icon: PartyPopper },
      { label: "Date Night", href: "/kategorie/geschenke-unter-20", icon: Heart },
      { label: "Reise & Abenteuer", href: "/kategorie/geschenke-maenner", icon: Plane },
      { label: "Gemeinsam aktiv", href: "/kategorie/geschenke-maenner", icon: Users },
    ],
  },
]

// ── Search ─────────────────────────────────────────────────────────────────
export function NavSearch() {
  const [open, setOpen] = React.useState(false)

  React.useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setOpen((o) => !o)
      }
    }
    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [])

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-1.5 text-[#6B6560] hover:text-[#F0EDE8] transition-colors"
        aria-label="Suche öffnen"
      >
        <SearchIcon size={16} />
        <span className="hidden lg:inline text-xs">⌘K</span>
      </button>

      <CommandDialog open={open} onOpenChange={setOpen}>
        <CommandInput placeholder="Produkt oder Kategorie suchen…" />
        <CommandList>
          <CommandEmpty>Nichts gefunden.</CommandEmpty>
          <CommandGroup heading="Zielgruppen">
            {NAV.map((item) => (
              <CommandItem key={item.key} onSelect={() => { setOpen(false) }}>
                <item.icon size={14} className="opacity-60" />
                <span>{item.label}</span>
              </CommandItem>
            ))}
          </CommandGroup>
          <CommandSeparator />
          <CommandGroup heading="Kategorien">
            <CommandItem onSelect={() => setOpen(false)}>
              <Cpu size={14} className="opacity-60" /><span>Tech & Gadgets</span>
            </CommandItem>
            <CommandItem onSelect={() => setOpen(false)}>
              <UtensilsCrossed size={14} className="opacity-60" /><span>Küchen-Gadgets</span>
            </CommandItem>
            <CommandItem onSelect={() => setOpen(false)}>
              <PartyPopper size={14} className="opacity-60" /><span>Lustige Gadgets</span>
            </CommandItem>
            <CommandItem onSelect={() => setOpen(false)}>
              <Heart size={14} className="opacity-60" /><span>Geschenke unter 20€</span>
            </CommandItem>
          </CommandGroup>
        </CommandList>
      </CommandDialog>
    </>
  )
}

// ── Dropdown Content ───────────────────────────────────────────────────────
function DropdownContent({ item, isOpen }: { item: NavItem; isOpen: boolean }) {
  const [visible, setVisible] = useState(isOpen)

  useEffect(() => {
    if (isOpen) {
      setVisible(true)
    } else {
      const t = setTimeout(() => setVisible(false), 300)
      return () => clearTimeout(t)
    }
  }, [isOpen])

  if (!visible) return null

  return (
    <div
      className={`fixed left-0 right-0 top-[64px] z-40 w-screen border-b border-[#333333] bg-[#1C1C1C]/98 backdrop-blur-sm
        transition-all duration-300 ease-out
        ${isOpen ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2 pointer-events-none"}`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6">
        <div className="flex items-center gap-2 mb-4">
          <item.icon size={14} className="text-[#E85000]" />
          <span className="text-[10px] font-bold uppercase tracking-widest text-[#E85000]">
            {item.label}
          </span>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
          {item.sub.map((sub) => (
            <Link
              key={sub.label}
              href={sub.href}
              className="flex items-center gap-2.5 px-3 py-2.5 border border-[#2A2A2A] hover:border-[#E85000] hover:bg-[#252525] transition-all duration-150 group"
            >
              <sub.icon size={14} className="text-[#6B6560] group-hover:text-[#E85000] transition-colors shrink-0" />
              <span className="text-sm text-[#9E9890] group-hover:text-[#F0EDE8] transition-colors font-medium whitespace-nowrap">
                {sub.label}
              </span>
            </Link>
          ))}
        </div>
      </div>
    </div>
  )
}

// ── Desktop Nav ────────────────────────────────────────────────────────────
export function DesktopNav() {
  const [activeMenu, setActiveMenu] = useState<MenuName>(null)

  return (
    <div className="hidden md:block">
      <nav className="flex items-center">
        {NAV.map((item) => (
          <div
            key={item.key}
            onMouseEnter={() => setActiveMenu(item.key)}
            onMouseLeave={() => setActiveMenu(null)}
          >
            <button
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-bold uppercase tracking-wide transition-colors
                ${activeMenu === item.key ? "text-[#E85000]" : "text-[#9E9890] hover:text-[#F0EDE8]"}`}
            >
              <item.icon size={13} />
              {item.label}
            </button>
            <DropdownContent item={item} isOpen={activeMenu === item.key} />
          </div>
        ))}
      </nav>
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
      <SheetContent
        side="right"
        className="w-[300px] bg-[#1C1C1C] border-l border-[#333333] p-0"
      >
        <nav className="flex flex-col py-6">
          {NAV.map((item) => (
            <div key={item.key} className="border-b border-[#252525]">
              <div className="flex items-center gap-2 px-6 py-3">
                <item.icon size={14} className="text-[#E85000]" />
                <span className="text-xs font-bold uppercase tracking-widest text-[#6B6560]">
                  {item.label}
                </span>
              </div>
              {item.sub.map((sub) => (
                <Link
                  key={sub.label}
                  href={sub.href}
                  className="flex items-center gap-2 px-8 py-2 text-sm text-[#9E9890] hover:text-[#E85000] transition-colors"
                >
                  <sub.icon size={12} className="opacity-60" />
                  {sub.label}
                </Link>
              ))}
            </div>
          ))}
          <div className="px-6 pt-6 space-y-2">
            <Link href="/impressum" className="block text-xs text-[#3A3A3A] hover:text-[#6B6560]">Impressum</Link>
            <Link href="/datenschutz" className="block text-xs text-[#3A3A3A] hover:text-[#6B6560]">Datenschutz</Link>
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
