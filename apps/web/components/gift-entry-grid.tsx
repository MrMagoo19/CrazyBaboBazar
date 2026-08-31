import Link from 'next/link'
import type { GiftEntry } from '@/lib/geschenke'

/**
 * Das Kachelraster der Geschenke-Einstiege. Server Component: die Kacheln sind
 * reine Links, es gibt nichts zu hydrieren.
 *
 * `minHeight: 44px` ist die uebliche Mindestgroesse fuer ein Touch-Ziel; das
 * Kartenlayout ist ohnehin hoeher, die Angabe haelt die Untergrenze aber auch
 * dann, wenn ein Eintrag spaeter nur aus einem kurzen Label besteht. Der
 * Fokusring kommt aus dem globalen `:focus-visible`-Block in `app/globals.css`
 * und wird hier bewusst nicht ueberschrieben.
 */
export function GiftEntryGrid({
  entries,
  columns = 3,
}: {
  entries: GiftEntry[]
  columns?: 2 | 3
}) {
  const gridClass =
    columns === 2
      ? 'grid grid-cols-1 sm:grid-cols-2 gap-4'
      : 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4'

  return (
    <ul className={gridClass}>
      {entries.map((entry) => (
        <li key={entry.href} className="flex">
          <Link
            href={entry.href}
            className="group flex w-full flex-col justify-center gap-1 px-5 py-4 border-2 border-[#0A0A0A] bg-white hover:bg-[#FFE500] transition-colors"
            style={{ minHeight: '44px' }}
          >
            <span className="font-[family-name:var(--font-display)] font-black text-base sm:text-lg text-[#0A0A0A] leading-tight">
              {entry.label}
            </span>
            <span className="text-xs text-[#555] leading-relaxed group-hover:text-[#0A0A0A]">
              {entry.hint}
            </span>
          </Link>
        </li>
      ))}
    </ul>
  )
}
