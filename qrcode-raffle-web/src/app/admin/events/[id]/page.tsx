'use client'

import { useEffect, useState, use } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import {
  ArrowLeft,
  Calendar,
  Users,
  Trophy,
  Plus,
  Trash2,
  Upload,
  Edit,
  Layers,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  Mic2,
  Gift
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { EventFormDialog } from '@/components/event-form-dialog'
import { TrackFormDialog } from '@/components/track-form-dialog'
import { TalkFormDialog } from '@/components/talk-form-dialog'
import { TalkCsvUploadDialog } from '@/components/talk-csv-upload-dialog'
import { RaffleWizardDialog } from '@/components/raffle-wizard-dialog'
import { AttendanceListDialog } from '@/components/attendance-list-dialog'
import { DeleteConfirmationDialog } from '@/components/delete-confirmation-dialog'

interface Raffle {
  id: string
  name: string
  prize: string
  status: string
  participantCount: number
  winner: {
    id: string
    name: string
    email: string
  } | null
}

interface Talk {
  id: string
  title: string
  speaker: string | null
  startTime: string | null
  endTime: string | null
  description: string | null
  attendanceCount: number
  raffleCount: number
  raffles: Raffle[]
}

interface Track {
  id: string
  title: string
  startDate: string
  endDate: string
  talkCount: number
  attendanceCount: number
  raffleCount: number
  talks: Talk[]
}

interface Event {
  id: string
  name: string
  startDate: string
  endDate: string
  speakers: string | null
  trackCount: number
  raffleCount: number
  attendanceCount: number
  uniqueAttendeeCount: number
  tracks: Track[]
  raffles: Raffle[]
}

export default function EventDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()
  const [event, setEvent] = useState<Event | null>(null)
  const [loading, setLoading] = useState(true)
  const [editDialogOpen, setEditDialogOpen] = useState(false)
  const [trackDialogOpen, setTrackDialogOpen] = useState(false)
  const [talkDialogOpen, setTalkDialogOpen] = useState(false)
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false)
  const [selectedTrackId, setSelectedTrackId] = useState<string | null>(null)
  const [selectedTalkId, setSelectedTalkId] = useState<string | null>(null)
  const [editTrack, setEditTrack] = useState<Track | null>(null)
  const [editTalk, setEditTalk] = useState<Talk | null>(null)
  const [expandedTracks, setExpandedTracks] = useState<Set<string>>(new Set())
  const [expandedTalks, setExpandedTalks] = useState<Set<string>>(new Set())
  const [raffleWizardOpen, setRaffleWizardOpen] = useState(false)
  const [preselectedTalkIdForRaffle, setPreselectedTalkIdForRaffle] = useState<string | undefined>(undefined)
  const [attendanceDialogOpen, setAttendanceDialogOpen] = useState(false)
  const [selectedTalkForAttendance, setSelectedTalkForAttendance] = useState<{ id: string; title: string } | null>(null)
  const [deleteTrackDialogOpen, setDeleteTrackDialogOpen] = useState(false)
  const [trackToDelete, setTrackToDelete] = useState<Track | null>(null)
  const [deleteTalkDialogOpen, setDeleteTalkDialogOpen] = useState(false)
  const [talkToDelete, setTalkToDelete] = useState<Talk | null>(null)
  const [deleteRaffleDialogOpen, setDeleteRaffleDialogOpen] = useState(false)
  const [raffleToDelete, setRaffleToDelete] = useState<Raffle | null>(null)

  const fetchEvent = async () => {
    try {
      const res = await fetch(`/api/events/${id}`)
      if (!res.ok) {
        router.push('/admin')
        return
      }
      const data = await res.json()
      setEvent(data)
      // Expand all tracks by default
      if (data.tracks) {
        setExpandedTracks(new Set(data.tracks.map((t: Track) => t.id)))
      }
    } catch (error) {
      console.error('Error fetching event:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchEvent()
  }, [id])

  const handleDeleteTrack = async (trackId: string) => {
    try {
      await fetch(`/api/tracks/${trackId}`, { method: 'DELETE' })
      fetchEvent()
    } catch (error) {
      console.error('Error deleting track:', error)
    }
  }

  const handleDeleteTalk = async (talkId: string) => {
    try {
      await fetch(`/api/talks/${talkId}`, { method: 'DELETE' })
      fetchEvent()
    } catch (error) {
      console.error('Error deleting talk:', error)
    }
  }

  const handleDeleteRaffle = async (raffleId: string) => {
    try {
      await fetch(`/api/raffles/${raffleId}`, { method: 'DELETE' })
      fetchEvent()
    } catch (error) {
      console.error('Error deleting raffle:', error)
    }
  }

  const handleOpenDeleteRaffle = (raffle: Raffle) => {
    setRaffleToDelete(raffle)
    setDeleteRaffleDialogOpen(true)
  }

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    })
  }

  const formatTime = (dateStr: string | null) => {
    if (!dateStr) return null
    return new Date(dateStr).toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const formatShortDate = (dateStr: string | null) => {
    if (!dateStr) return null
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short'
    })
  }

  const formatDateRange = (start: string, end: string) => {
    const startDate = new Date(start)
    const endDate = new Date(end)
    if (startDate.toDateString() === endDate.toDateString()) {
      return formatDate(start)
    }
    return `${formatDate(start)} - ${formatDate(end)}`
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

  const handleOpenUpload = (talkId: string) => {
    setSelectedTalkId(talkId)
    setUploadDialogOpen(true)
  }

  const handleOpenAttendance = (talk: Talk) => {
    setSelectedTalkForAttendance({ id: talk.id, title: talk.title })
    setAttendanceDialogOpen(true)
  }

  const handleOpenDeleteTrack = (track: Track) => {
    setTrackToDelete(track)
    setDeleteTrackDialogOpen(true)
  }

  const handleOpenDeleteTalk = (talk: Talk) => {
    setTalkToDelete(talk)
    setDeleteTalkDialogOpen(true)
  }

  const handleCreateRaffleForTalk = (talkId: string) => {
    setPreselectedTalkIdForRaffle(talkId)
    setRaffleWizardOpen(true)
  }

  const handleOpenGeneralRaffle = () => {
    setPreselectedTalkIdForRaffle(undefined)
    setRaffleWizardOpen(true)
  }

  const handleOpenEditTrack = (track: Track) => {
    setEditTrack(track)
    setTrackDialogOpen(true)
  }

  const handleCloseTrackDialog = () => {
    setTrackDialogOpen(false)
    setEditTrack(null)
  }

  const [selectedTrack, setSelectedTrack] = useState<Track | null>(null)

  const handleOpenNewTalk = (track: Track) => {
    setSelectedTrackId(track.id)
    setSelectedTrack(track)
    setEditTalk(null)
    setTalkDialogOpen(true)
  }

  const handleOpenEditTalk = (talk: Talk, track: Track) => {
    setSelectedTrackId(track.id)
    setSelectedTrack(track)
    setEditTalk(talk)
    setTalkDialogOpen(true)
  }

  const handleCloseTalkDialog = () => {
    setTalkDialogOpen(false)
    setEditTalk(null)
    setSelectedTrackId(null)
    setSelectedTrack(null)
  }

  const toggleTrackExpanded = (trackId: string) => {
    setExpandedTracks(prev => {
      const next = new Set(prev)
      if (next.has(trackId)) {
        next.delete(trackId)
      } else {
        next.add(trackId)
      }
      return next
    })
  }

  const toggleTalkExpanded = (talkId: string) => {
    setExpandedTalks(prev => {
      const next = new Set(prev)
      if (next.has(talkId)) {
        next.delete(talkId)
      } else {
        next.add(talkId)
      }
      return next
    })
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!event) {
    return (
      <div className="text-center py-16">
        <p className="text-muted-foreground">Evento não encontrado</p>
        <Link href="/admin">
          <Button variant="link">Voltar para eventos</Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="space-y-2">
        {/* Linha 1: Voltar + Título + Botões */}
        <div className="flex items-center justify-between gap-1">
          <div className="flex items-center gap-1 min-w-0">
            <Link href="/admin">
              <Button variant="ghost" size="icon" className="shrink-0 h-8 w-8">
                <ArrowLeft className="h-4 w-4" />
              </Button>
            </Link>
            <h1 className="text-base sm:text-2xl lg:text-3xl font-bold truncate">{event.name}</h1>
          </div>
          <div className="flex gap-1 shrink-0">
            <Button size="sm" className="h-8 px-2 sm:px-3" onClick={handleOpenGeneralRaffle}>
              <Trophy className="h-4 w-4 sm:mr-2" />
              <span className="hidden sm:inline">Novo Sorteio</span>
            </Button>
            <Button variant="outline" size="sm" className="h-8 px-2 sm:px-3" onClick={() => setEditDialogOpen(true)}>
              <Edit className="h-4 w-4 sm:mr-2" />
              <span className="hidden sm:inline">Editar</span>
            </Button>
          </div>
        </div>

        {/* Linha 2: Data e Stats - sempre visíveis */}
        <div className="flex items-center gap-2 text-xs text-muted-foreground ml-9">
          <span>{formatDateRange(event.startDate, event.endDate)}</span>
          <span>•</span>
          <Layers className="h-3 w-3" /><span>{event.trackCount}</span>
          <Users className="h-3 w-3 ml-1" /><span>{event.uniqueAttendeeCount}</span>
          <Trophy className="h-3 w-3 ml-1" /><span>{event.raffleCount}</span>
        </div>

        {/* Linha 3: Palestrantes - truncado no mobile */}
        {event.speakers && (
          <p className="text-xs text-muted-foreground line-clamp-1 ml-9">{event.speakers}</p>
        )}
      </div>

      {/* Sorteios do Evento (nível evento) - destacados */}
      {event.raffles.length > 0 && (
        <Card className="border-2 border-primary/30 bg-gradient-to-br from-primary/5 via-background to-secondary/5">
          <CardHeader>
            <div className="flex items-center gap-2">
              <div className="p-2 rounded-lg bg-primary/10">
                <Trophy className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle className="text-xl">Sorteios Gerais do Evento</CardTitle>
                <p className="text-sm text-muted-foreground">Sorteios válidos para todos os participantes do evento</p>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {event.raffles.map((raffle) => (
                <Card key={raffle.id} className="bg-card/80">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div className="space-y-1">
                        <CardTitle className="text-lg">{raffle.name}</CardTitle>
                        {getStatusBadge(raffle.status)}
                      </div>
                      <Badge variant="outline" className="bg-primary/5 text-primary border-primary/30 text-xs">
                        Evento
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex items-center gap-4 text-sm">
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <Trophy className="h-4 w-4" />
                        <span>{raffle.prize}</span>
                      </div>
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <Users className="h-4 w-4" />
                        <span>{raffle.participantCount}</span>
                      </div>
                    </div>
                    {raffle.winner && (
                      <div className="p-3 rounded-lg bg-primary/10 border border-primary/30">
                        <div className="flex items-center gap-2 text-sm">
                          <Trophy className="h-4 w-4 text-primary" />
                          <span className="font-medium text-primary">
                            Vencedor: {raffle.winner.name}
                          </span>
                        </div>
                      </div>
                    )}
                    <div className="flex gap-2">
                      <Link href={`/admin/${raffle.id}`} className="flex-1">
                        <Button variant="outline" className="w-full">
                          Ver Detalhes
                          <ChevronRight className="h-4 w-4 ml-2" />
                        </Button>
                      </Link>
                      <Button
                        variant="outline"
                        size="icon"
                        className="text-destructive hover:text-destructive hover:bg-destructive/10"
                        onClick={() => handleOpenDeleteRaffle(raffle)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Trilhas Section */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg sm:text-xl font-semibold">Trilhas</h2>
          <Button size="sm" className="sm:size-default" onClick={() => setTrackDialogOpen(true)}>
            <Plus className="h-4 w-4 sm:mr-2" />
            <span className="hidden sm:inline">Nova Trilha</span>
          </Button>
        </div>

        {event.tracks.length === 0 ? (
          <Card className="border-dashed">
            <CardContent className="flex flex-col items-center justify-center py-12">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 mb-4">
                <Layers className="h-6 w-6 text-primary" />
              </div>
              <h3 className="font-semibold mb-2">Nenhuma trilha ainda</h3>
              <p className="text-muted-foreground text-sm text-center mb-4">
                Adicione trilhas para organizar palestras e sorteios
              </p>
              <Button onClick={() => setTrackDialogOpen(true)} variant="outline">
                <Plus className="h-4 w-4 mr-2" />
                Criar Trilha
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-4">
            {event.tracks.map((track) => (
              <Card key={track.id} className="overflow-hidden">
                <CardHeader className="pb-3 px-3 sm:px-6">
                  <div
                    className="cursor-pointer"
                    onClick={() => toggleTrackExpanded(track.id)}
                  >
                    {/* Linha 1: Chevron + Título + Botões */}
                    <div className="flex items-center justify-between gap-1">
                      <div className="flex items-center gap-2 min-w-0">
                        {expandedTracks.has(track.id) ? (
                          <ChevronUp className="h-4 w-4 text-muted-foreground shrink-0" />
                        ) : (
                          <ChevronDown className="h-4 w-4 text-muted-foreground shrink-0" />
                        )}
                        <span className="font-semibold text-sm sm:text-base truncate">{track.title}</span>
                      </div>
                      <div className="flex shrink-0" onClick={(e) => e.stopPropagation()}>
                        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleOpenNewTalk(track)} title="Nova Palestra">
                          <Plus className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleOpenEditTrack(track)}>
                          <Edit className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="icon" className="h-7 w-7 text-muted-foreground hover:text-destructive" onClick={() => handleOpenDeleteTrack(track)}>
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    </div>
                    {/* Linha 2: Data e Stats */}
                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1 ml-6">
                      <span>{formatDateRange(track.startDate, track.endDate)}</span>
                      <span>•</span>
                      <Mic2 className="h-3 w-3" /><span>{track.talkCount}</span>
                      <Users className="h-3 w-3 ml-1" /><span>{track.attendanceCount}</span>
                      <Trophy className="h-3 w-3 ml-1" /><span>{track.raffleCount}</span>
                    </div>
                  </div>
                </CardHeader>

                {expandedTracks.has(track.id) && (
                  <CardContent className="border-t pt-4 space-y-4">
                    {/* Palestras da Trilha */}
                    {track.talks.length > 0 ? (
                      <div className="space-y-3">
                        {track.talks.map((talk) => (
                          <div key={talk.id} className="border rounded-lg overflow-hidden">
                            <div
                              className={`p-2 sm:p-3 bg-muted/30 ${talk.raffleCount > 0 ? 'cursor-pointer' : ''}`}
                              onClick={() => talk.raffleCount > 0 && toggleTalkExpanded(talk.id)}
                            >
                              {/* Mobile Layout */}
                              <div className="sm:hidden">
                                {/* Linha 1: Chevron + Título */}
                                <div className="flex items-center gap-1.5">
                                  {talk.raffleCount > 0 ? (
                                    expandedTalks.has(talk.id) ? (
                                      <ChevronUp className="h-4 w-4 text-muted-foreground shrink-0" />
                                    ) : (
                                      <ChevronDown className="h-4 w-4 text-muted-foreground shrink-0" />
                                    )
                                  ) : (
                                    <div className="w-4 shrink-0" />
                                  )}
                                  <Mic2 className="h-3.5 w-3.5 text-primary shrink-0" />
                                  <span className="font-medium text-sm line-clamp-2">{talk.title}</span>
                                </div>
                                {/* Linha 2: Info compacta */}
                                <div className="flex items-center justify-between mt-1.5 ml-6">
                                  <div className="flex items-center gap-1 text-xs text-muted-foreground min-w-0">
                                    {talk.speaker && <span className="truncate max-w-[80px]">{talk.speaker}</span>}
                                    {talk.speaker && <span className="mx-0.5">•</span>}
                                    {talk.startTime && <span className="shrink-0">{formatTime(talk.startTime)}</span>}
                                    <span className="mx-0.5">•</span>
                                    <button
                                      onClick={(e) => { e.stopPropagation(); handleOpenAttendance(talk) }}
                                      className="flex items-center gap-0.5 hover:text-primary shrink-0"
                                    >
                                      <Users className="h-3 w-3" />{talk.attendanceCount}
                                    </button>
                                    <Trophy className="h-3 w-3 ml-1" /><span>{talk.raffleCount}</span>
                                  </div>
                                  {/* Botões compactos mobile */}
                                  <div className="flex shrink-0 -mr-1" onClick={(e) => e.stopPropagation()}>
                                    <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => handleCreateRaffleForTalk(talk.id)}>
                                      <Gift className="h-3 w-3" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => handleOpenUpload(talk.id)}>
                                      <Upload className="h-3 w-3" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => handleOpenEditTalk(talk, track)}>
                                      <Edit className="h-3 w-3" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-6 w-6 text-muted-foreground hover:text-destructive" onClick={() => handleOpenDeleteTalk(talk)}>
                                      <Trash2 className="h-3 w-3" />
                                    </Button>
                                  </div>
                                </div>
                              </div>

                              {/* Desktop Layout */}
                              <div className="hidden sm:block">
                                {/* Linha 1: Chevron + Título + Botões */}
                                <div className="flex items-center justify-between gap-1">
                                  <div className="flex items-center gap-1.5 min-w-0">
                                    {talk.raffleCount > 0 ? (
                                      expandedTalks.has(talk.id) ? (
                                        <ChevronUp className="h-4 w-4 text-muted-foreground shrink-0" />
                                      ) : (
                                        <ChevronDown className="h-4 w-4 text-muted-foreground shrink-0" />
                                      )
                                    ) : (
                                      <div className="w-4 shrink-0" />
                                    )}
                                    <Mic2 className="h-3.5 w-3.5 text-primary shrink-0" />
                                    <span className="font-medium text-sm truncate">{talk.title}</span>
                                  </div>
                                  <div className="flex shrink-0" onClick={(e) => e.stopPropagation()}>
                                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleCreateRaffleForTalk(talk.id)} title="Criar Sorteio">
                                      <Gift className="h-3.5 w-3.5" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleOpenUpload(talk.id)} title="Importar Presenças">
                                      <Upload className="h-3.5 w-3.5" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleOpenEditTalk(talk, track)}>
                                      <Edit className="h-3.5 w-3.5" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-7 w-7 text-muted-foreground hover:text-destructive" onClick={() => handleOpenDeleteTalk(talk)}>
                                      <Trash2 className="h-3.5 w-3.5" />
                                    </Button>
                                  </div>
                                </div>
                                {/* Linha 2: Palestrante + Data + Stats */}
                                <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1 ml-6">
                                  {talk.speaker && <span className="truncate">{talk.speaker}</span>}
                                  {talk.speaker && (talk.startTime || talk.endTime) && <span>•</span>}
                                  {(talk.startTime || talk.endTime) && (
                                    <span className="shrink-0">
                                      {talk.startTime && talk.endTime
                                        ? `${formatTime(talk.startTime)}-${formatTime(talk.endTime)}`
                                        : talk.startTime
                                          ? formatTime(talk.startTime)
                                          : `até ${formatTime(talk.endTime)}`
                                      }
                                    </span>
                                  )}
                                  <span>•</span>
                                  <button
                                    onClick={(e) => { e.stopPropagation(); handleOpenAttendance(talk) }}
                                    className="flex items-center gap-0.5 hover:text-primary"
                                  >
                                    <Users className="h-3 w-3" />{talk.attendanceCount}
                                  </button>
                                  <span className="flex items-center gap-0.5">
                                    <Trophy className="h-3 w-3" />{talk.raffleCount}
                                  </span>
                                </div>
                              </div>
                            </div>

                            {expandedTalks.has(talk.id) && talk.raffles.length > 0 && (
                              <div className="p-3 border-t bg-secondary/5">
                                <div className="flex items-center gap-2 mb-3">
                                  <Trophy className="h-4 w-4 text-secondary" />
                                  <h5 className="text-sm font-medium">Sorteios desta Palestra</h5>
                                  <Badge variant="outline" className="bg-secondary/10 text-secondary border-secondary/30 text-xs">
                                    Palestra
                                  </Badge>
                                </div>
                                <div className="grid gap-2 md:grid-cols-2">
                                  {talk.raffles.map((raffle) => (
                                    <div key={raffle.id} className="p-3 rounded-lg border border-secondary/20 bg-card">
                                      <div className="flex items-start justify-between mb-2">
                                        <div>
                                          <p className="font-medium text-sm">{raffle.name}</p>
                                          <p className="text-xs text-muted-foreground">{raffle.prize}</p>
                                        </div>
                                        {getStatusBadge(raffle.status)}
                                      </div>
                                      <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
                                        <div className="flex items-center gap-1">
                                          <Users className="h-3 w-3" />
                                          <span>{raffle.participantCount} participantes</span>
                                        </div>
                                      </div>
                                      {raffle.winner && (
                                        <div className="p-2 rounded bg-amber-500/10 border border-amber-500/30 mb-2">
                                          <div className="flex items-center gap-1.5 text-xs">
                                            <Trophy className="h-3 w-3 text-amber-500" />
                                            <span className="font-medium text-amber-600">
                                              Vencedor: {raffle.winner.name}
                                            </span>
                                          </div>
                                        </div>
                                      )}
                                      <div className="flex gap-1">
                                        <Link href={`/admin/${raffle.id}`} className="flex-1">
                                          <Button variant="outline" size="sm" className="w-full text-xs h-7">
                                            Ver Detalhes
                                          </Button>
                                        </Link>
                                        <Button
                                          variant="outline"
                                          size="sm"
                                          className="h-7 px-2 text-destructive hover:text-destructive hover:bg-destructive/10"
                                          onClick={() => handleOpenDeleteRaffle(raffle)}
                                        >
                                          <Trash2 className="h-3 w-3" />
                                        </Button>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-6 text-muted-foreground text-sm">
                        <Mic2 className="h-8 w-8 mx-auto mb-2 opacity-50" />
                        <p>Nenhuma palestra nesta trilha</p>
                        <Button
                          variant="link"
                          size="sm"
                          onClick={() => handleOpenNewTalk(track)}
                          className="mt-2"
                        >
                          <Plus className="h-3 w-3 mr-1" />
                          Adicionar Palestra
                        </Button>
                      </div>
                    )}
                  </CardContent>
                )}
              </Card>
            ))}
          </div>
        )}
      </div>

      {/* Dialogs */}
      <EventFormDialog
        open={editDialogOpen}
        onOpenChange={setEditDialogOpen}
        onSuccess={fetchEvent}
        editEvent={event}
      />

      <TrackFormDialog
        open={trackDialogOpen}
        onOpenChange={handleCloseTrackDialog}
        onSuccess={fetchEvent}
        eventId={id}
        editTrack={editTrack || undefined}
      />

      {selectedTrackId && (
        <TalkFormDialog
          open={talkDialogOpen}
          onOpenChange={handleCloseTalkDialog}
          onSuccess={fetchEvent}
          trackId={selectedTrackId}
          trackStartDate={selectedTrack?.startDate}
          trackEndDate={selectedTrack?.endDate}
          editTalk={editTalk || undefined}
        />
      )}

      {selectedTalkId && (
        <TalkCsvUploadDialog
          open={uploadDialogOpen}
          onOpenChange={setUploadDialogOpen}
          talkId={selectedTalkId}
          onSuccess={fetchEvent}
        />
      )}

      <RaffleWizardDialog
        open={raffleWizardOpen}
        onOpenChange={(open) => {
          setRaffleWizardOpen(open)
          if (!open) setPreselectedTalkIdForRaffle(undefined)
        }}
        onSuccess={fetchEvent}
        eventId={id}
        eventName={event.name}
        tracks={event.tracks}
        preselectedTalkId={preselectedTalkIdForRaffle}
        eventUniqueAttendeeCount={event.uniqueAttendeeCount}
      />

      {selectedTalkForAttendance && (
        <AttendanceListDialog
          open={attendanceDialogOpen}
          onOpenChange={setAttendanceDialogOpen}
          talkId={selectedTalkForAttendance.id}
          talkTitle={selectedTalkForAttendance.title}
          onUpdate={fetchEvent}
        />
      )}

      {/* Delete Confirmation Dialogs */}
      <DeleteConfirmationDialog
        open={deleteTrackDialogOpen}
        onOpenChange={(open) => {
          setDeleteTrackDialogOpen(open)
          if (!open) setTrackToDelete(null)
        }}
        onConfirm={async () => {
          if (trackToDelete) {
            await handleDeleteTrack(trackToDelete.id)
          }
        }}
        title="Excluir trilha?"
        description="Esta ação não pode ser desfeita. Todas as palestras, presenças e sorteios da trilha serão removidos permanentemente."
        itemName={trackToDelete?.title}
      />

      <DeleteConfirmationDialog
        open={deleteTalkDialogOpen}
        onOpenChange={(open) => {
          setDeleteTalkDialogOpen(open)
          if (!open) setTalkToDelete(null)
        }}
        onConfirm={async () => {
          if (talkToDelete) {
            await handleDeleteTalk(talkToDelete.id)
          }
        }}
        title="Excluir palestra?"
        description="Esta ação não pode ser desfeita. Todas as presenças e sorteios da palestra serão removidos permanentemente."
        itemName={talkToDelete?.title}
      />

      <DeleteConfirmationDialog
        open={deleteRaffleDialogOpen}
        onOpenChange={(open) => {
          setDeleteRaffleDialogOpen(open)
          if (!open) setRaffleToDelete(null)
        }}
        onConfirm={async () => {
          if (raffleToDelete) {
            await handleDeleteRaffle(raffleToDelete.id)
          }
        }}
        title="Excluir sorteio?"
        description="Esta ação não pode ser desfeita. Todos os participantes e histórico do sorteio serão removidos permanentemente."
        itemName={raffleToDelete?.name}
      />
    </div>
  )
}
