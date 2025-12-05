'use client'

import { useState, useEffect } from 'react'
import { Users, Loader2, Trash2, Clock, Search, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
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

interface Attendance {
  id: string
  name: string
  email: string
  entryTime: string | null
  exitTime: string | null
  duration: number | null
  createdAt: string
}

interface AttendanceListDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  talkId: string
  talkTitle: string
  onUpdate: () => void
}

function formatTime(isoString: string | null): string {
  if (!isoString) return '-'
  return new Date(isoString).toLocaleTimeString('pt-BR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

function formatDuration(minutes: number | null): string {
  if (!minutes) return '-'
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return `${hours}h ${mins}min`
  }
  return `${mins}min`
}

export function AttendanceListDialog({
  open,
  onOpenChange,
  talkId,
  talkTitle,
  onUpdate
}: AttendanceListDialogProps) {
  const [attendances, setAttendances] = useState<Attendance[]>([])
  const [loading, setLoading] = useState(false)
  const [deleting, setDeleting] = useState<string | null>(null)
  const [clearingAll, setClearingAll] = useState(false)
  const [search, setSearch] = useState('')

  const fetchAttendances = async () => {
    setLoading(true)
    try {
      const res = await fetch(`/api/talks/${talkId}/attendance`)
      const data = await res.json()
      if (res.ok) {
        setAttendances(data.attendances || [])
      }
    } catch (error) {
      console.error('Error fetching attendances:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (open) {
      fetchAttendances()
      setSearch('')
    }
  }, [open, talkId])

  const handleDeleteOne = async (attendanceId: string) => {
    setDeleting(attendanceId)
    try {
      const res = await fetch(`/api/talks/${talkId}/attendance/${attendanceId}`, {
        method: 'DELETE'
      })
      if (res.ok) {
        setAttendances(prev => prev.filter(a => a.id !== attendanceId))
        onUpdate()
      }
    } catch (error) {
      console.error('Error deleting attendance:', error)
    } finally {
      setDeleting(null)
    }
  }

  const handleClearAll = async () => {
    setClearingAll(true)
    try {
      const res = await fetch(`/api/talks/${talkId}/attendance`, {
        method: 'DELETE'
      })
      if (res.ok) {
        setAttendances([])
        onUpdate()
      }
    } catch (error) {
      console.error('Error clearing attendances:', error)
    } finally {
      setClearingAll(false)
    }
  }

  const filteredAttendances = attendances.filter(a =>
    a.name.toLowerCase().includes(search.toLowerCase()) ||
    a.email.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl max-h-[80vh] flex flex-col">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Lista de Presenças
          </DialogTitle>
          <DialogDescription>
            {talkTitle} - {attendances.length} {attendances.length === 1 ? 'presença' : 'presenças'}
          </DialogDescription>
        </DialogHeader>

        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por nome ou email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
            {search && (
              <button
                onClick={() => setSearch('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
          {attendances.length > 0 && (
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="destructive" size="sm" disabled={clearingAll}>
                  {clearingAll ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <>
                      <Trash2 className="h-4 w-4 mr-1" />
                      Limpar Tudo
                    </>
                  )}
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Limpar todas as presenças?</AlertDialogTitle>
                  <AlertDialogDescription>
                    Esta ação não pode ser desfeita. Todas as {attendances.length} presenças serão removidas.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancelar</AlertDialogCancel>
                  <AlertDialogAction
                    onClick={handleClearAll}
                    className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                  >
                    Limpar Tudo
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          )}
        </div>

        <div className="flex-1 overflow-y-auto min-h-0">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : attendances.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <Users className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Nenhuma presença registrada</p>
            </div>
          ) : filteredAttendances.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <Search className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Nenhum resultado para "{search}"</p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredAttendances.map((attendance) => (
                <div
                  key={attendance.id}
                  className="flex items-center justify-between p-3 rounded-lg border bg-card hover:bg-muted/50 transition-colors"
                >
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">{attendance.name}</p>
                    <p className="text-sm text-muted-foreground truncate">{attendance.email}</p>
                    {(attendance.entryTime || attendance.exitTime || attendance.duration) && (
                      <div className="flex items-center gap-3 mt-1 text-xs text-muted-foreground">
                        {attendance.entryTime && (
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            Entrada: {formatTime(attendance.entryTime)}
                          </span>
                        )}
                        {attendance.exitTime && (
                          <span>Saída: {formatTime(attendance.exitTime)}</span>
                        )}
                        {attendance.duration && (
                          <span className="text-primary font-medium">
                            {formatDuration(attendance.duration)}
                          </span>
                        )}
                      </div>
                    )}
                  </div>
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="shrink-0 text-muted-foreground hover:text-destructive"
                        disabled={deleting === attendance.id}
                      >
                        {deleting === attendance.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Remover presença?</AlertDialogTitle>
                        <AlertDialogDescription>
                          Deseja remover a presença de {attendance.name}?
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={() => handleDeleteOne(attendance.id)}
                          className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        >
                          Remover
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              ))}
            </div>
          )}
        </div>

        {filteredAttendances.length > 0 && (
          <div className="text-xs text-muted-foreground text-center pt-2 border-t">
            Mostrando {filteredAttendances.length} de {attendances.length} presenças
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
