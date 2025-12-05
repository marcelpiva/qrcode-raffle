'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Plus, Users, Trophy, Clock, Trash2, BarChart3 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"

interface Raffle {
  id: string
  name: string
  description: string | null
  prize: string
  status: 'active' | 'closed' | 'drawn'
  createdAt: string
  endsAt: string | null
  winner?: {
    name: string
    email: string
  } | null
  _count: {
    participants: number
  }
}

// Calcula o status efetivo considerando o timeout
function getEffectiveStatus(raffle: Raffle): 'active' | 'closed' | 'drawn' {
  if (raffle.status === 'drawn') return 'drawn'
  if (raffle.status === 'closed') return 'closed'
  // Se active mas endsAt expirou, considerar como closed
  if (raffle.status === 'active' && raffle.endsAt) {
    const now = new Date()
    const endsAt = new Date(raffle.endsAt)
    if (now > endsAt) return 'closed'
  }
  return 'active'
}

export default function AdminDashboard() {
  const [raffles, setRaffles] = useState<Raffle[]>([])
  const [loading, setLoading] = useState(true)

  const fetchRaffles = async () => {
    try {
      const res = await fetch('/api/raffles')
      const data = await res.json()
      setRaffles(data)
    } catch (error) {
      console.error('Error fetching raffles:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchRaffles()
  }, [])

  const handleDelete = async (id: string) => {
    try {
      await fetch(`/api/raffles/${id}`, { method: 'DELETE' })
      setRaffles(raffles.filter(r => r.id !== id))
    } catch (error) {
      console.error('Error deleting raffle:', error)
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-500/10 text-green-600 hover:bg-green-500/20">Ativo</Badge>
      case 'closed':
        return <Badge className="bg-yellow-500/10 text-yellow-600 hover:bg-yellow-500/20">Encerrado</Badge>
      case 'drawn':
        return <Badge className="bg-primary/10 text-primary hover:bg-primary/20">Sorteado</Badge>
      default:
        return null
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">Gerencie seus sorteios</p>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/admin/ranking">
            <Button variant="outline">
              <BarChart3 className="h-4 w-4 mr-2" />
              Ranking
            </Button>
          </Link>
          <Link href="/admin/new">
            <Button className="bg-gradient-to-r from-primary to-secondary hover:opacity-90">
              <Plus className="h-4 w-4 mr-2" />
              Novo Sorteio
            </Button>
          </Link>
        </div>
      </div>

      {raffles.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-16">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 mb-4">
              <Trophy className="h-8 w-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Nenhum sorteio ainda</h3>
            <p className="text-muted-foreground text-center mb-4">
              Crie seu primeiro sorteio e comece a engajar seus participantes!
            </p>
            <Link href="/admin/new">
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                Criar Primeiro Sorteio
              </Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {raffles.map((raffle) => (
            <Card key={raffle.id} className="hover:shadow-md transition-shadow group">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <CardTitle className="text-lg">{raffle.name}</CardTitle>
                    <div className="flex items-center gap-2">
                      {getStatusBadge(getEffectiveStatus(raffle))}
                      {raffle.status === 'active' && raffle.endsAt && new Date() > new Date(raffle.endsAt) && (
                        <Badge variant="outline" className="text-orange-600 border-orange-500 text-xs">
                          Tempo esgotado
                        </Badge>
                      )}
                    </div>
                  </div>
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="opacity-0 group-hover:opacity-100 transition-opacity text-muted-foreground hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Excluir sorteio?</AlertDialogTitle>
                        <AlertDialogDescription>
                          Esta acao nao pode ser desfeita. Todos os participantes serao removidos.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={() => handleDelete(raffle.id)}
                          className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        >
                          Excluir
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="text-sm text-muted-foreground line-clamp-2">
                  {raffle.description || 'Sem descricao'}
                </div>

                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Trophy className="h-4 w-4" />
                    <span>{raffle.prize}</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Users className="h-4 w-4" />
                    <span>{raffle._count.participants} participantes</span>
                  </div>
                </div>

                {raffle.winner && (
                  <div className="p-3 rounded-lg bg-primary/5 border border-primary/20">
                    <div className="flex items-center gap-2 text-sm">
                      <Trophy className="h-4 w-4 text-primary" />
                      <span className="font-medium text-primary">Vencedor: {raffle.winner.name}</span>
                    </div>
                  </div>
                )}

                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <Clock className="h-3 w-3" />
                  <span>Criado em {new Date(raffle.createdAt).toLocaleDateString('pt-BR')}</span>
                </div>

                <Link href={`/admin/${raffle.id}`} className="block">
                  <Button variant="outline" className="w-full">
                    Ver Detalhes
                  </Button>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
