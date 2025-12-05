'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Plus, Calendar, Users, Trophy, Trash2, ChevronRight, Layers } from 'lucide-react'
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
import { EventFormDialog } from '@/components/event-form-dialog'

interface Track {
  id: string
  title: string
  day: string
  speaker: string | null
  attendanceCount: number
  raffleCount: number
}

interface Event {
  id: string
  name: string
  startDate: string
  endDate: string
  speakers: string | null
  trackCount: number
  raffleCount: number
  tracks: Track[]
}

export default function EventsPage() {
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [dialogOpen, setDialogOpen] = useState(false)

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

  const getTotalAttendances = (tracks: Track[]) => {
    return tracks.reduce((sum, t) => sum + t.attendanceCount, 0)
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
          <h1 className="text-3xl font-bold">Eventos</h1>
          <p className="text-muted-foreground">Gerencie eventos e trilhas</p>
        </div>
        <Button
          onClick={() => setDialogOpen(true)}
          className="bg-gradient-to-r from-primary to-secondary hover:opacity-90"
        >
          <Plus className="h-4 w-4 mr-2" />
          Novo Evento
        </Button>
      </div>

      {events.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-16">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 mb-4">
              <Calendar className="h-8 w-8 text-primary" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Nenhum evento ainda</h3>
            <p className="text-muted-foreground text-center mb-4">
              Crie seu primeiro evento para gerenciar trilhas e presenças!
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
                          Esta ação não pode ser desfeita. Todas as trilhas e presenças serão removidas.
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

                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Layers className="h-4 w-4" />
                    <span>{event.trackCount} trilhas</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Users className="h-4 w-4" />
                    <span>{getTotalAttendances(event.tracks)} presenças</span>
                  </div>
                  <div className="flex items-center gap-1.5 text-muted-foreground">
                    <Trophy className="h-4 w-4" />
                    <span>{event.raffleCount} sorteios</span>
                  </div>
                </div>

                {event.tracks.length > 0 && (
                  <div className="space-y-1">
                    {event.tracks.slice(0, 3).map((track) => (
                      <div
                        key={track.id}
                        className="flex items-center justify-between text-xs text-muted-foreground py-1 px-2 rounded bg-muted/50"
                      >
                        <span className="truncate">{track.title}</span>
                        <Badge variant="outline" className="ml-2 text-xs">
                          {track.attendanceCount}
                        </Badge>
                      </div>
                    ))}
                    {event.tracks.length > 3 && (
                      <div className="text-xs text-muted-foreground text-center py-1">
                        +{event.tracks.length - 3} trilhas
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

      <EventFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onSuccess={fetchEvents}
      />
    </div>
  )
}
