import Link from "next/link"
import Image from "next/image"
import { QrCode, Users, Trophy } from "lucide-react"
import { Button } from "@/components/ui/button"

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
      <div className="container mx-auto px-4 py-16">
        {/* Hero Section */}
        <div className="flex flex-col items-center text-center space-y-8 mb-16">
          <Image
            src="/nava-icon.jpg"
            alt="Nava Logo"
            width={80}
            height={80}
            className="rounded-2xl shadow-lg"
          />

          <h1 className="text-5xl font-bold tracking-tight">
            <span className="bg-gradient-to-r from-primary via-accent to-secondary bg-clip-text text-transparent">
              NAVA Summit
            </span>
          </h1>

          <p className="text-xl text-muted-foreground max-w-2xl">
            Crie sorteios incriveis com QR Code. Seus participantes escaneiam,
            registram e voce sorteia o vencedor com animacoes espetaculares!
          </p>

          <div className="flex gap-4">
            <Link href="/admin">
              <Button size="lg" className="bg-gradient-to-r from-primary to-secondary hover:opacity-90 transition-opacity">
                Acessar Dashboard
              </Button>
            </Link>
            <Link href="/admin/new">
              <Button size="lg" variant="outline">
                Criar Sorteio
              </Button>
            </Link>
          </div>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className="flex flex-col items-center text-center p-6 rounded-2xl bg-card border border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-primary/10 mb-4">
              <QrCode className="h-7 w-7 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">QR Code Automatico</h3>
            <p className="text-muted-foreground text-sm">
              Cada sorteio gera um QR Code unico que seus participantes podem escanear facilmente
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-6 rounded-2xl bg-card border border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-secondary/10 mb-4">
              <Users className="h-7 w-7 text-secondary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Contador em Tempo Real</h3>
            <p className="text-muted-foreground text-sm">
              Acompanhe quantos participantes ja se inscreveram com atualizacao automatica
            </p>
          </div>

          <div className="flex flex-col items-center text-center p-6 rounded-2xl bg-card border border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-accent/10 mb-4">
              <Trophy className="h-7 w-7 text-accent" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Sorteio Animado</h3>
            <p className="text-muted-foreground text-sm">
              Realize o sorteio com animacao estilo slot machine e celebre com confetti!
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
