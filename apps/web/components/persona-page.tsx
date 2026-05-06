import Link from 'next/link'
import { ProductGrid } from '@/components/product-grid'
import type { DbProduct } from '@/lib/db-types'
import type { LucideIcon } from 'lucide-react'

type SubNavItem = {
  label: string
  href: string
}

type PersonaPageProps = {
  persona: string
  title: string
  description: string
  intro?: string
  icon: LucideIcon
  accentColor?: string
  products: DbProduct[]
  subnav: SubNavItem[]
  activeCategory?: string
}

export function PersonaPage({
  title,
  description,
  intro,
  icon: Icon,
  accentColor = '#FFE500',
  products,
  subnav,
  activeCategory,
}: PersonaPageProps) {
  return (
    <div>
      {/* Header */}
      <div className="border-b-2 border-[#0A0A0A] bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Icon size={20} style={{ color: accentColor }} />
            <span className="text-[10px] font-bold uppercase tracking-widest" style={{ color: accentColor }}>
              {title}
            </span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#0A0A0A]">
            {description}
          </h1>
          {intro && (
            <p className="text-[#555555] text-sm leading-relaxed mt-2 max-w-2xl">{intro}</p>
          )}
          <p className="text-[#555555] text-sm mt-2">{products.length} Produkte</p>
        </div>

        {/* Sub-nav */}
        {subnav.length > 0 && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-0 border-t-2 border-[#0A0A0A]">
            <div className="flex gap-0 overflow-x-auto">
              {subnav.map((item) => {
                const isActive = item.label === 'Alle'
                  ? !activeCategory
                  : activeCategory === item.href.split('/').pop()
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`shrink-0 px-4 py-3 text-xs font-bold uppercase tracking-wider border-b-2 transition-all duration-150 ${
                      isActive
                        ? 'border-[#FFE500] bg-[#FFE500] text-[#0A0A0A]'
                        : 'border-transparent text-[#555555] hover:text-[#0A0A0A] hover:border-[#0A0A0A]'
                    }`}
                  >
                    {item.label}
                  </Link>
                )
              })}
            </div>
          </div>
        )}
      </div>

      {/* Products */}
      {products.length === 0 ? (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#555555]">
          Noch keine Produkte in dieser Kategorie.
        </div>
      ) : (
        <ProductGrid products={products} />
      )}
    </div>
  )
}
