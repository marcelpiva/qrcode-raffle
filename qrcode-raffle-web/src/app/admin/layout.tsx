import { Navbar } from "@/components/navbar"
import { AdminAuth } from "@/components/admin-auth"
import { VersionDisplay } from "@/components/version-display"

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <AdminAuth>
      <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
        <Navbar />
        <main className="container mx-auto px-4 py-8">
          {children}
        </main>
        <VersionDisplay />
      </div>
    </AdminAuth>
  )
}
