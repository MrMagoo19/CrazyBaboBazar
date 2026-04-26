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
  icon: LucideIcon
  accentColor?: string
  products: DbProduct[]
  subnav: SubNavItem[]
  activeCategory?: string
}

export function PersonaPage({
  title,
  description,
  icon: Icon,
  accentColor = '#E85000',
  products,
  subnav,
  activeCategory,
}: PersonaPageProps) {
  return (
    <div>
      {/* Header */}
      <div className="border-b border-[#252525] bg-[#141414]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-10">
          <div className="flex items-center gap-3 mb-2">
            <Icon size={20} style={{ color: accentColor }} />
            <span className="text-[10px] font-bold uppercase tracking-widest" style={{ color: accentColor }}>
              {title}
            </span>
          </div>
          <h1 className="font-[family-name:var(--font-display)] font-extrabold text-3xl md:text-4xl text-[#F0EDE8]">
            {description}
          </h1>
          <p className="text-[#6B6560] text-sm mt-2">{products.length} Produkte</p>
        </div>

        {/* Sub-nav */}
        {subnav.length > 0 && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 pb-0">
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
                        ? 'border-[#E85000] text-[#E85000]'
                        : 'border-transparent text-[#6B6560] hover:text-[#F0EDE8] hover:border-[#333333]'
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
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-20 text-center text-[#6B6560]">
          Noch keine Produkte in dieser Kategorie.
        </div>
      ) : (
        <ProductGrid products={products} />
      )}
    </div>
  )
}
