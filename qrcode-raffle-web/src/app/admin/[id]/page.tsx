'use client'

import { useEffect, useState, use } from 'react'
import Link from 'next/link'
import { ArrowLeft, Trophy, Users, Clock, Lock, Unlock, Shuffle, Mail, MonitorPlay, Check, RefreshCw, UserX, RotateCcw, Download } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { QRCodeDisplay } from '@/components/qr-code-display'
import { ParticipantCounter } from '@/components/participant-counter'
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface Participant {
  id: string
  name: string
  email: string
  createdAt: string
}

interface DrawHistory {
  id: string
  drawNumber: number
  wasPresent: boolean
  createdAt: string
  participant: Participant
}

interface Raffle {
  id: string
  name: string
  description: string | null
  prize: string
  status: 'active' | 'closed' | 'drawn'
  createdAt: string
  closedAt: string | null
  endsAt: string | null
  timeboxMinutes: number | null
  participants: Participant[]
  winner?: Participant | null
  drawHistory?: DrawHistory[]
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

export default function RaffleDetails({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const [raffle, setRaffle] = useState<Raffle | null>(null)
  const [loading, setLoading] = useState(true)
  const [origin, setOrigin] = useState('')
  const [isConfirming, setIsConfirming] = useState(false)
  const [isRedrawing, setIsRedrawing] = useState(false)
  const [isReopening, setIsReopening] = useState(false)

  useEffect(() => {
    setOrigin(window.location.origin)
    fetchRaffle()

    // Polling for real-time updates
    const interval = setInterval(() => {
      fetchParticipants()
    }, 3000)

    return () => clearInterval(interval)
  }, [id])

  const fetchRaffle = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}`)
      const data = await res.json()
      setRaffle(data)
    } catch (error) {
      console.error('Error fetching raffle:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchParticipants = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}/participants`)
      const participants = await res.json()
      setRaffle(prev => prev ? { ...prev, participants, _count: { participants: participants.length } } : null)
    } catch (error) {
      console.error('Error fetching participants:', error)
    }
  }

  const handleCloseRegistrations = async () => {
    try {
      await fetch(`/api/raffles/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'closed' })
      })
      fetchRaffle()
    } catch (error) {
      console.error('Error closing raffle:', error)
    }
  }

  const handleReopenRegistrations = async () => {
    try {
      await fetch(`/api/raffles/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'active' })
      })
      fetchRaffle()
    } catch (error) {
      console.error('Error reopening registrations:', error)
    }
  }

  const handleConfirmWinner = async () => {
    setIsConfirming(true)
    try {
      const res = await fetch(`/api/raffles/${id}/confirm-winner`, {
        method: 'POST'
      })
      if (res.ok) {
        fetchRaffle()
      }
    } catch (error) {
      console.error('Error confirming winner:', error)
    } finally {
      setIsConfirming(false)
    }
  }

  const handleRedraw = async () => {
    setIsRedrawing(true)
    try {
      const res = await fetch(`/api/raffles/${id}/draw`, {
        method: 'POST'
      })
      if (res.ok) {
        fetchRaffle()
      }
    } catch (error) {
      console.error('Error redrawing:', error)
    } finally {
      setIsRedrawing(false)
    }
  }

  const handleReopen = async () => {
    setIsReopening(true)
    try {
      const res = await fetch(`/api/raffles/${id}/reopen`, {
        method: 'POST'
      })
      if (res.ok) {
        fetchRaffle()
      }
    } catch (error) {
      console.error('Error reopening raffle:', error)
    } finally {
      setIsReopening(false)
    }
  }

  // Calcula status efetivo (considerando timeout)
  const effectiveStatus = raffle ? getEffectiveStatus(raffle) : null

  // Check if there's a pending winner (draw happened but not confirmed)
  const hasPendingWinner = raffle?.winner && raffle.status !== 'drawn'
  const absentDraws = raffle?.drawHistory?.filter(d => !d.wasPresent) || []

  // Verifica se ainda está dentro do prazo (para mostrar botão de encerrar)
  const isWithinTimebox = raffle?.endsAt ? new Date() < new Date(raffle.endsAt) : true
  // Verifica se expirou por timeout (não por ação manual)
  const expiredByTimeout = raffle?.status === 'active' && raffle?.endsAt && new Date() > new Date(raffle.endsAt)

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-500/10 text-green-600">Ativo</Badge>
      case 'closed':
        return <Badge className="bg-yellow-500/10 text-yellow-600">Encerrado</Badge>
      case 'drawn':
        return <Badge className="bg-primary/10 text-primary">Sorteado</Badge>
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

  if (!raffle) {
    return (
      <div className="text-center py-16">
        <h2 className="text-2xl font-bold mb-2">Sorteio nao encontrado</h2>
        <Link href="/admin">
          <Button>Voltar ao Dashboard</Button>
        </Link>
      </div>
    )
  }

  const registerUrl = `${origin}/register/${raffle.id}`

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/admin">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-3xl font-bold">{raffle.name}</h1>
            {getStatusBadge(effectiveStatus!)}
            {expiredByTimeout && (
              <Badge variant="outline" className="text-orange-600 border-orange-500">
                <Clock className="h-3 w-3 mr-1" />
                Tempo esgotado
              </Badge>
            )}
          </div>
          <p className="text-muted-foreground">{raffle.description || 'Sem descricao'}</p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* QR Code Section */}
        <div className="lg:col-span-1 space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">QR Code</CardTitle>
            </CardHeader>
            <CardContent>
              <QRCodeDisplay url={registerUrl} />
            </CardContent>
          </Card>

          <ParticipantCounter
            raffleId={raffle.id}
            initialCount={raffle._count.participants}
          />

          {/* Action Buttons */}
          <div className="space-y-2">
            <Link href={`/display/${raffle.id}`} target="_blank" className="block">
              <Button variant="outline" className="w-full">
                <MonitorPlay className="h-4 w-4 mr-2" />
                Abrir Painel de Exibicao
              </Button>
            </Link>

            {/* Botão Encerrar: só mostra se está ativo E dentro do prazo (não expirado) */}
            {effectiveStatus === 'active' && isWithinTimebox && (
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button variant="outline" className="w-full">
                    <Lock className="h-4 w-4 mr-2" />
                    Encerrar Inscricoes
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Encerrar inscricoes?</AlertDialogTitle>
                    <AlertDialogDescription>
                      Nenhum novo participante podera se inscrever apos esta acao.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                    <AlertDialogAction onClick={handleCloseRegistrations}>
                      Encerrar
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            )}

            {/* Botão Reabrir: mostra quando encerrado (por timeout ou manualmente) */}
            {effectiveStatus === 'closed' && (
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button variant="outline" className="w-full">
                    <Unlock className="h-4 w-4 mr-2" />
                    Reabrir Inscricoes
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Reabrir inscricoes?</AlertDialogTitle>
                    <AlertDialogDescription>
                      {raffle.winner
                        ? 'O sorteio atual sera cancelado e as inscricoes serao reabertas. O vencedor pendente sera removido.'
                        : expiredByTimeout
                        ? 'O tempo expirou. Reabrir permitira novas inscricoes (sem limite de tempo).'
                        : 'Novos participantes poderao se inscrever novamente.'}
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                    <AlertDialogAction onClick={handleReopenRegistrations}>
                      Reabrir
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            )}

            {/* Botão Sorteio: disponível quando encerrado (efetivamente) e há participantes */}
            {effectiveStatus === 'closed' && raffle._count.participants > 0 && (
              <Link href={`/admin/${raffle.id}/draw`} className="block">
                <Button className="w-full bg-gradient-to-r from-primary to-secondary hover:opacity-90">
                  <Shuffle className="h-4 w-4 mr-2" />
                  Realizar Sorteio
                </Button>
              </Link>
            )}

            {/* CSV Download */}
            {raffle._count.participants > 0 && (
              <Button
                variant="outline"
                className="w-full"
                onClick={() => {
                  window.location.href = `/api/raffles/${raffle.id}/export`
                }}
              >
                <Download className="h-4 w-4 mr-2" />
                Download CSV
              </Button>
            )}
          </div>
        </div>

        {/* Info & Participants */}
        <div className="lg:col-span-2 space-y-4">
          {/* Winner Card */}
          {raffle.winner && (
            <Card className="border-primary/50 bg-gradient-to-r from-primary/5 to-secondary/5">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-primary to-secondary">
                      <Trophy className="h-7 w-7 text-white" />
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">
                        {raffle.status === 'drawn' ? 'Vencedor Confirmado' : 'Sorteado - Aguardando Confirmacao'}
                      </p>
                      <p className="text-2xl font-bold">{raffle.winner.name}</p>
                      <p className="text-sm text-muted-foreground">{raffle.winner.email}</p>
                    </div>
                  </div>
                  {hasPendingWinner && (
                    <div className="flex gap-2">
                      <Button
                        onClick={handleConfirmWinner}
                        disabled={isConfirming}
                        className="bg-green-600 hover:bg-green-700"
                      >
                        {isConfirming ? (
                          <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        ) : (
                          <Check className="h-4 w-4 mr-2" />
                        )}
                        Confirmar Presenca
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="outline" disabled={isRedrawing}>
                            {isRedrawing ? (
                              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                            ) : (
                              <Shuffle className="h-4 w-4 mr-2" />
                            )}
                            Sortear Novamente
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Sortear novamente?</AlertDialogTitle>
                            <AlertDialogDescription>
                              O participante atual sera marcado como ausente e um novo sorteio sera realizado.
                              Participantes ausentes nao podem ser sorteados novamente.
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                            <AlertDialogAction onClick={handleRedraw}>
                              Sortear Novamente
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  )}
                  {raffle.status === 'drawn' && (
                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button variant="outline" disabled={isReopening}>
                          {isReopening ? (
                            <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                          ) : (
                            <RotateCcw className="h-4 w-4 mr-2" />
                          )}
                          Reabrir Sorteio
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent>
                        <AlertDialogHeader>
                          <AlertDialogTitle>Reabrir sorteio?</AlertDialogTitle>
                          <AlertDialogDescription>
                            O vencedor atual sera removido e o historico de sorteios sera apagado.
                            Todos os participantes poderao ser sorteados novamente.
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <AlertDialogFooter>
                          <AlertDialogCancel>Cancelar</AlertDialogCancel>
                          <AlertDialogAction onClick={handleReopen}>
                            Reabrir Sorteio
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Absent Draws History */}
          {absentDraws.length > 0 && (
            <Card className="border-yellow-500/50 bg-yellow-500/5">
              <CardHeader className="pb-3">
                <CardTitle className="text-lg flex items-center gap-2 text-yellow-700">
                  <UserX className="h-5 w-5" />
                  Sorteados Ausentes ({absentDraws.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {absentDraws.map((draw) => (
                    <div
                      key={draw.id}
                      className="flex items-center justify-between p-3 bg-yellow-500/10 rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <Badge variant="outline" className="text-yellow-700 border-yellow-500">
                          #{draw.drawNumber}
                        </Badge>
                        <div>
                          <p className="font-medium">{draw.participant.name}</p>
                          <p className="text-sm text-muted-foreground">{draw.participant.email}</p>
                        </div>
                      </div>
                      <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-700">
                        Ausente
                      </Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Prize Info */}
          <Card>
            <CardContent className="p-6">
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="flex items-center gap-3">
                  <Trophy className="h-5 w-5 text-primary" />
                  <div>
                    <p className="text-sm text-muted-foreground">Premio</p>
                    <p className="font-semibold">{raffle.prize}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Users className="h-5 w-5 text-primary" />
                  <div>
                    <p className="text-sm text-muted-foreground">Participantes</p>
                    <p className="font-semibold">{raffle._count.participants}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Clock className="h-5 w-5 text-primary" />
                  <div>
                    <p className="text-sm text-muted-foreground">Criado em</p>
                    <p className="font-semibold">
                      {new Date(raffle.createdAt).toLocaleDateString('pt-BR')}
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Participants List */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Users className="h-5 w-5" />
                Participantes ({raffle.participants.length})
              </CardTitle>
            </CardHeader>
            <CardContent>
              {raffle.participants.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  Nenhum participante ainda
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nome</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Data</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {raffle.participants.map((p) => (
                      <TableRow key={p.id} className={raffle.winner?.id === p.id ? 'bg-primary/5' : ''}>
                        <TableCell className="font-medium">
                          {p.name}
                          {raffle.winner?.id === p.id && (
                            <Trophy className="inline h-4 w-4 ml-2 text-primary" />
                          )}
                        </TableCell>
                        <TableCell>
                          <span className="flex items-center gap-1">
                            <Mail className="h-3 w-3" />
                            {p.email}
                          </span>
                        </TableCell>
                        <TableCell>
                          {new Date(p.createdAt).toLocaleDateString('pt-BR')}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
