'use client'

import { useState, useEffect } from 'react'
import { Layers, Loader2, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface TrackFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
  eventId: string
  editTrack?: {
    id: string
    title: string
    startDate: string
    endDate: string
  }
}

// Helper to format date for input (use UTC to avoid timezone shift)
function formatDateLocal(isoString: string | undefined): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  const pad = (n: number) => n.toString().padStart(2, '0')
  // Use UTC methods to avoid timezone conversion issues
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}`
}

export function TrackFormDialog({ open, onOpenChange, onSuccess, eventId, editTrack }: TrackFormDialogProps) {
  const [title, setTitle] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Update form when editTrack changes or dialog opens
  useEffect(() => {
    if (open) {
      if (editTrack) {
        setTitle(editTrack.title)
        setStartDate(formatDateLocal(editTrack.startDate))
        setEndDate(formatDateLocal(editTrack.endDate))
      } else {
        setTitle('')
        setStartDate('')
        setEndDate('')
      }
      setError(null)
    }
  }, [open, editTrack])

  const resetForm = () => {
    if (!editTrack) {
      setTitle('')
      setStartDate('')
      setEndDate('')
    }
    setError(null)
  }

  const handleClose = () => {
    if (!saving) {
      resetForm()
      onOpenChange(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!title || !startDate || !endDate) {
      setError('Preencha todos os campos obrigatórios')
      return
    }

    // Add noon time to avoid timezone issues (dates shift when UTC midnight converts to local time)
    const trackStartDate = new Date(`${startDate}T12:00:00`)
    const trackEndDate = new Date(`${endDate}T12:00:00`)

    if (isNaN(trackStartDate.getTime())) {
      setError('Data de início inválida')
      return
    }

    if (isNaN(trackEndDate.getTime())) {
      setError('Data de fim inválida')
      return
    }

    if (trackEndDate < trackStartDate) {
      setError('Data de fim deve ser igual ou posterior à data de início')
      return
    }

    setSaving(true)
    setError(null)

    try {
      const url = editTrack ? `/api/tracks/${editTrack.id}` : '/api/tracks'
      const method = editTrack ? 'PUT' : 'POST'

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          eventId,
          title,
          startDate: trackStartDate.toISOString(),
          endDate: trackEndDate.toISOString()
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.error || 'Erro ao salvar trilha')
      }

      resetForm()
      onOpenChange(false)
      onSuccess()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar trilha')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Layers className="h-5 w-5" />
            {editTrack ? 'Editar Trilha' : 'Nova Trilha'}
          </DialogTitle>
          <DialogDescription>
            {editTrack ? 'Atualize as informações da trilha' : 'Preencha os dados da nova trilha'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="trackTitle">Título da Trilha *</Label>
            <Input
              id="trackTitle"
              placeholder="Ex: Inteligência Artificial"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={saving}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="trackStartDate">Data Início *</Label>
              <Input
                id="trackStartDate"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={saving}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="trackEndDate">Data Fim *</Label>
              <Input
                id="trackEndDate"
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                disabled={saving}
              />
            </div>
          </div>

          {error && (
            <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-sm text-destructive flex items-center gap-2">
              <AlertCircle className="h-4 w-4" />
              {error}
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              disabled={saving}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={saving || !title || !startDate || !endDate}>
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : editTrack ? (
                'Salvar'
              ) : (
                'Criar Trilha'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
