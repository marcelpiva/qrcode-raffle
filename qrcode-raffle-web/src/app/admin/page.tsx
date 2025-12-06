'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Plus, Users, Trophy, Calendar, Trash2, BarChart3, Layers, ChevronRight, Mic2 } from 'lucide-react'
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
import { EventWizardDialog } from '@/components/event-wizard-dialog'
import { useRouter } from 'next/navigation'

interface Talk {
  id: string
  title: string
  speaker: string | null
  attendanceCount: number
  raffleCount: number
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
  tracks: Track[]
}

export default function AdminDashboard() {
  const router = useRouter()
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [dialogOpen, setDialogOpen] = useState(false)

  const handleEventCreated = (eventId: string) => {
    router.push(`/admin/events/${eventId}`)
  }

  const fetchEvents = async () => {
    try {
      const res = await fetch('/api/events')
      const data = await res.json()
      if (Array.isArray(data)) {
        setEvents(data)
      } else {
        console.error('Error fetching events:', data.error || 'Unknown error')
        setEvents([])
      }
    } catch (error) {
      console.error('Error fetching events:', error)
      setEvents([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchEvents()
  }, [])

  const handleDelete = async (id: string) => {
    try {
      await fetch(`/api/events/${id}`, { method: 'DELETE' })
      setEvents(events.filter(e => e.id !== id))
    } catch (error) {
      console.error('Error deleting event:', error)
    }
  }

  const formatDateRange = (start: string, end: string) => {
    const startDate = new Date(start)
    const endDate = new Date(end)
    const formatter = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' })

    if (startDate.toDateString() === endDate.toDateString()) {
      return formatter.format(startDate)
    }
    return `${formatter.format(startDate)} - ${formatter.format(endDate)}`
  }

  const pluralize = (count: number, singular: string, plural: string) => {
    return count === 1 ? singular : plural
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
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold">Dashboard</h1>
          <p className="text-sm sm:text-base text-muted-foreground">Gerencie seus eventos e sorteios</p>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/admin/ranking">
            <Button variant="outline" size="sm" className="sm:size-default">
              <BarChart3 className="h-4 w-4 sm:mr-2" />
              <span className="hidden sm:inline">Ranking</span>
            </Button>
          </Link>
          <Button
            onClick={() => setDialogOpen(true)}
            size="sm"
            className="sm:size-default bg-gradient-to-r from-primary to-secondary hover:opacity-90"
          >
            <Plus className="h-4 w-4 sm:mr-2" />
            <span className="hidden sm:inline">Novo Evento</span>
          </Button>
        </div>
      </div>

      {events.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-16">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 mb-4">
              <Calendar className="h-8 w-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Nenhum evento ainda</h3>
            <p className="text-muted-foreground text-center mb-4">
              Crie seu primeiro evento para gerenciar trilhas, presenças e sorteios!
            </p>
            <Button onClick={() => setDialogOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Criar Primeiro Evento
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {events.map((event) => (
            <Card key={event.id} className="hover:shadow-md transition-shadow group">
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div className="space-y-1 flex-1">
                    <CardTitle className="text-lg">{event.name}</CardTitle>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Calendar className="h-4 w-4" />
                      <span>{formatDateRange(event.startDate, event.endDate)}</span>
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
                        <AlertDialogTitle>Excluir evento?</AlertDialogTitle>
                        <AlertDialogDescription>
                          Esta ação não pode ser desfeita. Todas as trilhas, presenças e sorteios serão removidos.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={() => handleDelete(event.id)}
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
                {event.speakers && (
                  <div className="text-sm text-muted-foreground line-clamp-2">
                    {event.speakers}
                  </div>
                )}

                <div className="flex flex-wrap items-center gap-3 text-sm">
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Layers className="h-4 w-4" />
                    <span>{event.trackCount} {pluralize(event.trackCount, 'trilha', 'trilhas')}</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Users className="h-4 w-4" />
                    <span>{event.attendanceCount}</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Trophy className="h-4 w-4" />
                    <span>{event.raffleCount}</span>
                  </div>
                </div>

                {event.tracks.length > 0 && (
                  <div className="space-y-1">
                    {event.tracks.slice(0, 2).map((track) => (
                      <div
                        key={track.id}
                        className="flex items-center justify-between gap-2 text-xs text-muted-foreground py-1.5 px-2 rounded bg-muted/50"
                      >
                        <span className="truncate flex-1 min-w-0">{track.title}</span>
                        <div className="flex items-center gap-1.5 shrink-0">
                          <span className="flex items-center gap-1">
                            <Mic2 className="h-3 w-3" />
                            {track.talkCount}
                          </span>
                          <span className="flex items-center gap-1">
                            <Users className="h-3 w-3" />
                            {track.attendanceCount}
                          </span>
                        </div>
                      </div>
                    ))}
                    {event.tracks.length > 2 && (
                      <div className="text-xs text-muted-foreground text-center py-1">
                        +{event.tracks.length - 2} {pluralize(event.tracks.length - 2, 'trilha', 'trilhas')}
                      </div>
                    )}
                  </div>
                )}

                <Link href={`/admin/events/${event.id}`} className="block">
                  <Button variant="outline" className="w-full">
                    Ver Detalhes
                    <ChevronRight className="h-4 w-4 ml-2" />
                  </Button>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <EventWizardDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onSuccess={handleEventCreated}
      />
    </div>
  )
}
