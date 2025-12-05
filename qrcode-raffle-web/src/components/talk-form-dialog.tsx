'use client'

import { useState, useEffect } from 'react'
import { Mic2, Loader2, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface TalkFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
  trackId: string
  trackStartDate?: string
  trackEndDate?: string
  editTalk?: {
    id: string
    title: string
    speaker: string | null
    startTime: string | null
    endTime: string | null
    description: string | null
  }
}

const pad = (n: number) => n.toString().padStart(2, '0')

// Helper to extract date from ISO string (YYYY-MM-DD) in local timezone
function extractDate(isoString: string | null | undefined): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

// Helper to extract time from ISO string (HH:MM) in local timezone
function extractTime(isoString: string | null | undefined): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`
}

// Helper to format date for display
function formatDateForInput(isoString: string | undefined): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

export function TalkFormDialog({
  open,
  onOpenChange,
  onSuccess,
  trackId,
  trackStartDate,
  trackEndDate,
  editTalk
}: TalkFormDialogProps) {
  const [title, setTitle] = useState('')
  const [speaker, setSpeaker] = useState('')
  const [date, setDate] = useState('')
  const [startTime, setStartTime] = useState('')
  const [endTime, setEndTime] = useState('')
  const [description, setDescription] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Get min/max dates from track period
  const minDate = trackStartDate ? formatDateForInput(trackStartDate) : ''
  const maxDate = trackEndDate ? formatDateForInput(trackEndDate) : ''

  // Update form when editTalk changes or dialog opens
  useEffect(() => {
    if (open) {
      if (editTalk) {
        setTitle(editTalk.title)
        setSpeaker(editTalk.speaker || '')
        // Extract date from startTime (or endTime as fallback)
        const dateFromStart = extractDate(editTalk.startTime)
        const dateFromEnd = extractDate(editTalk.endTime)
        setDate(dateFromStart || dateFromEnd || '')
        setStartTime(extractTime(editTalk.startTime))
        setEndTime(extractTime(editTalk.endTime))
        setDescription(editTalk.description || '')
      } else {
        setTitle('')
        setSpeaker('')
        setDate('')
        setStartTime('')
        setEndTime('')
        setDescription('')
      }
      setError(null)
    }
  }, [open, editTalk])

  const resetForm = () => {
    if (!editTalk) {
      setTitle('')
      setSpeaker('')
      setDate('')
      setStartTime('')
      setEndTime('')
      setDescription('')
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

    if (!title) {
      setError('Preencha o título da palestra')
      return
    }

    // Validate date is within track period
    if (date && minDate && maxDate) {
      if (date < minDate || date > maxDate) {
        const startFormatted = new Date(trackStartDate!).toLocaleDateString('pt-BR')
        const endFormatted = new Date(trackEndDate!).toLocaleDateString('pt-BR')
        setError(`A data deve estar dentro do período da trilha (${startFormatted} a ${endFormatted})`)
        return
      }
    }

    // Validate end time is after start time
    if (startTime && endTime && endTime <= startTime) {
      setError('Horário de fim deve ser posterior ao horário de início')
      return
    }

    setSaving(true)
    setError(null)

    try {
      // Build full datetime strings from date + time
      let fullStartTime: string | null = null
      let fullEndTime: string | null = null

      if (date) {
        if (startTime) {
          fullStartTime = `${date}T${startTime}:00`
        }
        if (endTime) {
          fullEndTime = `${date}T${endTime}:00`
        }
      }

      const url = editTalk ? `/api/talks/${editTalk.id}` : '/api/talks'
      const method = editTalk ? 'PUT' : 'POST'

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          trackId,
          title,
          speaker: speaker || null,
          startTime: fullStartTime,
          endTime: fullEndTime,
          description: description || null
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.error || 'Erro ao salvar palestra')
      }

      resetForm()
      onOpenChange(false)
      onSuccess()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar palestra')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Mic2 className="h-5 w-5" />
            {editTalk ? 'Editar Palestra' : 'Nova Palestra'}
          </DialogTitle>
          <DialogDescription>
            {editTalk ? 'Atualize as informações da palestra' : 'Preencha os dados da nova palestra'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="talkTitle">Título da Palestra *</Label>
            <Input
              id="talkTitle"
              placeholder="Ex: Introdução ao Machine Learning"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={saving}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="talkSpeaker">Palestrante</Label>
            <Input
              id="talkSpeaker"
              placeholder="Nome do palestrante"
              value={speaker}
              onChange={(e) => setSpeaker(e.target.value)}
              disabled={saving}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="talkDate">Data</Label>
            <Input
              id="talkDate"
              type="date"
              value={date}
              min={minDate}
              max={maxDate}
              onChange={(e) => setDate(e.target.value)}
              disabled={saving}
            />
            {minDate && maxDate && (
              <p className="text-xs text-muted-foreground">
                Período da trilha: {new Date(trackStartDate!).toLocaleDateString('pt-BR')} a {new Date(trackEndDate!).toLocaleDateString('pt-BR')}
              </p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="talkStartTime">Hora Início</Label>
              <Input
                id="talkStartTime"
                type="time"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                disabled={saving}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="talkEndTime">Hora Fim</Label>
              <Input
                id="talkEndTime"
                type="time"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                disabled={saving}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="talkDescription">Descrição</Label>
            <Textarea
              id="talkDescription"
              placeholder="Descrição da palestra (opcional)"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={saving}
              rows={3}
            />
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
            <Button type="submit" disabled={saving || !title}>
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : editTalk ? (
                'Salvar'
              ) : (
                'Criar Palestra'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
