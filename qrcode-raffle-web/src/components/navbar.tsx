'use client'

import Link from 'next/link'
import Image from 'next/image'
import { usePathname } from 'next/navigation'
import { LayoutDashboard } from 'lucide-react'
import { cn } from '@/lib/utils'

export function Navbar() {
  const pathname = usePathname()

  const isActive = (path: string) => pathname === path || pathname.startsWith(path + '/')

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center px-4 mx-auto">
        <Link href="/" className="flex items-center gap-2 mr-8">
          <div className="relative">
            <div className="absolute -inset-0.5 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg blur opacity-60" />
            <Image
              src="/nava-icon.jpg"
              alt="Nava Logo"
              width={36}
              height={36}
              className="relative rounded-lg"
            />
          </div>
          <div>
            <h1 className="text-lg font-black tracking-tight">
              NAVA<span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">SUMMIT</span>
            </h1>
            <p className="text-[8px] uppercase tracking-[0.2em] text-muted-foreground font-medium -mt-0.5">
              Eventos & Sorteios
            </p>
          </div>
        </Link>

        <div className="flex items-center gap-1">
          <Link
            href="/admin"
            className={cn(
              "flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors",
              isActive('/admin')
                ? "bg-primary/10 text-primary"
                : "text-muted-foreground hover:text-foreground hover:bg-muted"
            )}
          >
            <LayoutDashboard className="h-4 w-4" />
            Dashboard
          </Link>
        </div>
      </div>
    </nav>
  )
}
