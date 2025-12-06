'use client'

import { useEffect, useState, use } from 'react'
import Link from 'next/link'
import { ArrowLeft, Trophy, Users, Clock, Lock, Unlock, Shuffle, Mail, MonitorPlay, Check, RefreshCw, UserX, RotateCcw, Download, Link2Off, Link2, Search, Timer } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { QRCodeDisplay } from '@/components/qr-code-display'
import { ParticipantCounter } from '@/components/participant-counter'
import { Input } from '@/components/ui/input'
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

interface Track {
  id: string
  title: string
  eventId: string
}

interface Talk {
  id: string
  title: string
  track: Track
}

interface Event {
  id: string
  name: string
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
  startsAt: string | null
  timeboxMinutes: number | null
  participants: Participant[]
  winner?: Participant | null
  drawHistory?: DrawHistory[]
  talk?: Talk | null
  event?: Event | null
  allowLinkRegistration?: boolean
  autoDrawOnEnd?: boolean
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
  const [isTogglingLink, setIsTogglingLink] = useState(false)
  const [isTogglingAutoDraw, setIsTogglingAutoDraw] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')

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
      // Check if response is valid raffle (has _count property)
      if (res.ok && data._count) {
        setRaffle(data)
      } else {
        setRaffle(null)
      }
    } catch (error) {
      console.error('Error fetching raffle:', error)
      setRaffle(null)
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

  const handleToggleLinkRegistration = async () => {
    if (!raffle) return
    setIsTogglingLink(true)
    try {
      const res = await fetch(`/api/raffles/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ allowLinkRegistration: !raffle.allowLinkRegistration })
      })
      if (res.ok) {
        fetchRaffle()
      }
    } catch (error) {
      console.error('Error toggling link registration:', error)
    } finally {
      setIsTogglingLink(false)
    }
  }

  const handleToggleAutoDraw = async () => {
    if (!raffle) return
    setIsTogglingAutoDraw(true)
    try {
      const res = await fetch(`/api/raffles/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ autoDrawOnEnd: !raffle.autoDrawOnEnd })
      })
      if (res.ok) {
        fetchRaffle()
      }
    } catch (error) {
      console.error('Error toggling auto draw:', error)
    } finally {
      setIsTogglingAutoDraw(false)
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
          <Button>Voltar aos Eventos</Button>
        </Link>
      </div>
    )
  }

  const registerUrl = `${origin}/register/${raffle.id}`

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* Header */}
      <div className="flex items-start gap-2 sm:gap-4">
        <Link href={raffle.talk ? `/admin/events/${raffle.talk.track.eventId}` : raffle.event ? `/admin/events/${raffle.event.id}` : '/admin'}>
          <Button variant="ghost" size="icon" className="h-8 w-8 sm:h-10 sm:w-10 shrink-0">
            <ArrowLeft className="h-4 w-4 sm:h-5 sm:w-5" />
          </Button>
        </Link>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-xl sm:text-3xl font-bold truncate">{raffle.name}</h1>
            {getStatusBadge(effectiveStatus!)}
            {expiredByTimeout && (
              <Badge variant="outline" className="text-orange-600 border-orange-500 text-[10px] sm:text-xs">
                <Clock className="h-3 w-3 mr-1" />
                <span className="hidden sm:inline">Tempo esgotado</span>
                <span className="sm:hidden">Expirado</span>
              </Badge>
            )}
          </div>
          <p className="text-sm sm:text-base text-muted-foreground line-clamp-1">{raffle.description || 'Sem descricao'}</p>
          {raffle.talk && (
            <p className="text-xs sm:text-sm text-muted-foreground truncate">
              <span className="hidden sm:inline">Palestra: </span>{raffle.talk.title}
            </p>
          )}
          {raffle.event && !raffle.talk && (
            <p className="text-xs sm:text-sm text-muted-foreground truncate">
              <span className="hidden sm:inline">Evento: </span>{raffle.event.name}
            </p>
          )}
        </div>
      </div>

      <div className="grid gap-4 sm:gap-6 lg:grid-cols-3">
        {/* QR Code Section */}
        <div className="lg:col-span-1 space-y-3 sm:space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">QR Code</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Event raffle without link registration - show message instead of QR */}
              {raffle.event && !raffle.talk && !raffle.allowLinkRegistration ? (
                <div className="flex flex-col items-center justify-center py-8 px-4 text-center space-y-3">
                  <div className="flex h-16 w-16 items-center justify-center rounded-full bg-muted">
                    <Link2Off className="h-8 w-8 text-muted-foreground" />
                  </div>
                  <div className="space-y-1">
                    <p className="font-medium text-muted-foreground">
                      Inscricao por link desabilitada
                    </p>
                    <p className="text-sm text-muted-foreground/70">
                      Os participantes sao selecionados automaticamente com base nas presencas do evento.
                    </p>
                  </div>
                </div>
              ) : (
                <QRCodeDisplay url={registerUrl} />
              )}
            </CardContent>
          </Card>

          {/* Toggle Link Registration - Only for Event Raffles */}
          {raffle.event && !raffle.talk && (
            <Button
              variant="outline"
              className="w-full"
              onClick={handleToggleLinkRegistration}
              disabled={isTogglingLink}
            >
              {isTogglingLink ? (
                <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
              ) : raffle.allowLinkRegistration ? (
                <Link2Off className="h-4 w-4 mr-2" />
              ) : (
                <Link2 className="h-4 w-4 mr-2" />
              )}
              {raffle.allowLinkRegistration ? 'Desabilitar Inscricao por Link' : 'Habilitar Inscricao por Link'}
            </Button>
          )}

          {/* Toggle Auto Draw - Shows when raffle has schedule and not yet drawn */}
          {raffle.endsAt && effectiveStatus !== 'drawn' && (
            <Card className={raffle.autoDrawOnEnd ? 'border-amber-500/50 bg-amber-500/5' : ''}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${raffle.autoDrawOnEnd ? 'bg-amber-500/20' : 'bg-muted'}`}>
                      <Shuffle className={`h-4 w-4 ${raffle.autoDrawOnEnd ? 'text-amber-600' : 'text-muted-foreground'}`} />
                    </div>
                    <div>
                      <p className="text-sm font-medium">Sorteio Automatico</p>
                      <p className="text-xs text-muted-foreground">
                        {raffle.autoDrawOnEnd
                          ? 'Sortear automaticamente ao encerrar countdown'
                          : 'Encerrar manualmente para sortear'}
                      </p>
                    </div>
                  </div>
                  <Button
                    variant={raffle.autoDrawOnEnd ? 'default' : 'outline'}
                    size="sm"
                    onClick={handleToggleAutoDraw}
                    disabled={isTogglingAutoDraw}
                    className={raffle.autoDrawOnEnd ? 'bg-amber-500 hover:bg-amber-600' : ''}
                  >
                    {isTogglingAutoDraw ? (
                      <RefreshCw className="h-4 w-4 animate-spin" />
                    ) : raffle.autoDrawOnEnd ? (
                      'Ativado'
                    ) : (
                      'Ativar'
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

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
              <CardContent className="p-4 sm:p-6">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                  <div className="flex items-center gap-3 sm:gap-4">
                    <div className="flex h-10 w-10 sm:h-14 sm:w-14 items-center justify-center rounded-full bg-gradient-to-br from-primary to-secondary shrink-0">
                      <Trophy className="h-5 w-5 sm:h-7 sm:w-7 text-white" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs sm:text-sm text-muted-foreground">
                        {raffle.status === 'drawn' ? 'Vencedor Confirmado' : 'Aguardando Confirmacao'}
                      </p>
                      <p className="text-lg sm:text-2xl font-bold truncate">{raffle.winner.name}</p>
                      <p className="text-xs sm:text-sm text-muted-foreground truncate">{raffle.winner.email}</p>
                    </div>
                  </div>
                  {hasPendingWinner && (
                    <div className="flex flex-col sm:flex-row gap-2">
                      <Button
                        onClick={handleConfirmWinner}
                        disabled={isConfirming}
                        className="bg-green-600 hover:bg-green-700 text-xs sm:text-sm"
                        size="sm"
                      >
                        {isConfirming ? (
                          <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        ) : (
                          <Check className="h-4 w-4 mr-2" />
                        )}
                        Confirmar
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="outline" disabled={isRedrawing} size="sm" className="text-xs sm:text-sm">
                            {isRedrawing ? (
                              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                            ) : (
                              <Shuffle className="h-4 w-4 mr-2" />
                            )}
                            Re-sortear
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
                        <Button variant="outline" disabled={isReopening} size="sm" className="text-xs sm:text-sm">
                          {isReopening ? (
                            <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                          ) : (
                            <RotateCcw className="h-4 w-4 mr-2" />
                          )}
                          Reabrir
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
              <CardHeader className="pb-3 px-4 sm:px-6">
                <CardTitle className="text-base sm:text-lg flex items-center gap-2 text-yellow-700">
                  <UserX className="h-4 w-4 sm:h-5 sm:w-5" />
                  Ausentes ({absentDraws.length})
                </CardTitle>
              </CardHeader>
              <CardContent className="px-4 sm:px-6">
                <div className="space-y-2">
                  {absentDraws.map((draw) => (
                    <div
                      key={draw.id}
                      className="flex items-center justify-between gap-2 p-2 sm:p-3 bg-yellow-500/10 rounded-lg"
                    >
                      <div className="flex items-center gap-2 sm:gap-3 min-w-0">
                        <Badge variant="outline" className="text-yellow-700 border-yellow-500 text-xs shrink-0">
                          #{draw.drawNumber}
                        </Badge>
                        <div className="min-w-0">
                          <p className="font-medium text-sm truncate">{draw.participant.name}</p>
                          <p className="text-xs text-muted-foreground truncate">{draw.participant.email}</p>
                        </div>
                      </div>
                      <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-700 text-xs shrink-0 hidden sm:inline-flex">
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
            <CardContent className="p-4 sm:p-6">
              <div className="grid grid-cols-3 gap-3 sm:gap-4">
                <div className="flex items-center gap-2 sm:gap-3">
                  <Trophy className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" />
                  <div className="min-w-0">
                    <p className="text-xs sm:text-sm text-muted-foreground">Premio</p>
                    <p className="font-semibold text-sm sm:text-base truncate">{raffle.prize}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 sm:gap-3">
                  <Users className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" />
                  <div>
                    <p className="text-xs sm:text-sm text-muted-foreground">Participantes</p>
                    <p className="font-semibold text-sm sm:text-base">{raffle._count.participants}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 sm:gap-3">
                  <Clock className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" />
                  <div>
                    <p className="text-xs sm:text-sm text-muted-foreground">Criado</p>
                    <p className="font-semibold text-sm sm:text-base">
                      {new Date(raffle.createdAt).toLocaleDateString('pt-BR')}
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Participants List */}
          <Card>
            <CardHeader className="px-4 sm:px-6">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base sm:text-lg flex items-center gap-2">
                  <Users className="h-4 w-4 sm:h-5 sm:w-5" />
                  Participantes ({raffle.participants.length})
                </CardTitle>
              </div>
              {raffle.participants.length > 0 && (
                <div className="relative mt-2">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    placeholder="Buscar..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-9 h-9 text-sm"
                  />
                </div>
              )}
            </CardHeader>
            <CardContent className="px-4 sm:px-6">
              {raffle.participants.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  Nenhum participante ainda
                </div>
              ) : (
                <>
                  {(() => {
                    const filteredParticipants = raffle.participants.filter(p =>
                      p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                      p.email.toLowerCase().includes(searchTerm.toLowerCase())
                    )
                    return (
                      <>
                        {searchTerm && (
                          <p className="text-sm text-muted-foreground mb-3">
                            Mostrando {filteredParticipants.length} de {raffle.participants.length} participantes
                          </p>
                        )}
                        {filteredParticipants.length === 0 ? (
                          <div className="text-center py-8 text-muted-foreground">
                            Nenhum participante encontrado para &quot;{searchTerm}&quot;
                          </div>
                        ) : (
                          <div className="overflow-x-auto">
                            <Table>
                              <TableHeader>
                                <TableRow>
                                  <TableHead className="min-w-[120px]">Nome</TableHead>
                                  <TableHead className="hidden sm:table-cell">Email</TableHead>
                                  <TableHead className="text-right">Data</TableHead>
                                </TableRow>
                              </TableHeader>
                              <TableBody>
                                {filteredParticipants.map((p) => (
                                  <TableRow key={p.id} className={raffle.winner?.id === p.id ? 'bg-primary/5' : ''}>
                                    <TableCell className="font-medium">
                                      <div className="flex items-center gap-1">
                                        <span className="truncate max-w-[150px] sm:max-w-none">{p.name}</span>
                                        {raffle.winner?.id === p.id && (
                                          <Trophy className="h-4 w-4 text-primary shrink-0" />
                                        )}
                                      </div>
                                      <span className="sm:hidden text-xs text-muted-foreground truncate block max-w-[180px]">
                                        {p.email}
                                      </span>
                                    </TableCell>
                                    <TableCell className="hidden sm:table-cell">
                                      <span className="flex items-center gap-1">
                                        <Mail className="h-3 w-3 shrink-0" />
                                        <span className="truncate max-w-[200px]">{p.email}</span>
                                      </span>
                                    </TableCell>
                                    <TableCell className="text-right whitespace-nowrap text-xs sm:text-sm">
                                      {new Date(p.createdAt).toLocaleDateString('pt-BR')}
                                    </TableCell>
                                  </TableRow>
                                ))}
                              </TableBody>
                            </Table>
                          </div>
                        )}
                      </>
                    )
                  })()}
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
