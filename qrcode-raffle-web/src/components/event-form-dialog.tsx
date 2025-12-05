'use client'

import { useState } from 'react'
import { Calendar, Loader2, AlertCircle } from 'lucide-react'
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

interface EventFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
  editEvent?: {
    id: string
    name: string
    startDate: string
    endDate: string
    speakers: string | null
  }
}

export function EventFormDialog({ open, onOpenChange, onSuccess, editEvent }: EventFormDialogProps) {
  const [name, setName] = useState(editEvent?.name || '')
  const [startDate, setStartDate] = useState(editEvent?.startDate?.split('T')[0] || '')
  const [endDate, setEndDate] = useState(editEvent?.endDate?.split('T')[0] || '')
  const [speakers, setSpeakers] = useState(editEvent?.speakers || '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const resetForm = () => {
    if (!editEvent) {
      setName('')
      setStartDate('')
      setEndDate('')
      setSpeakers('')
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

    if (!name || !startDate || !endDate) {
      setError('Preencha todos os campos obrigatórios')
      return
    }

    if (new Date(endDate) < new Date(startDate)) {
      setError('Data de fim deve ser igual ou posterior à data de início')
      return
    }

    setSaving(true)
    setError(null)

    try {
      const url = editEvent ? `/api/events/${editEvent.id}` : '/api/events'
      const method = editEvent ? 'PUT' : 'POST'

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          startDate,
          endDate,
          speakers: speakers || null
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.error || 'Erro ao salvar evento')
      }

      resetForm()
      onOpenChange(false)
      onSuccess()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar evento')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            {editEvent ? 'Editar Evento' : 'Novo Evento'}
          </DialogTitle>
          <DialogDescription>
            {editEvent ? 'Atualize as informações do evento' : 'Preencha os dados do novo evento'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="eventName">Nome do Evento *</Label>
            <Input
              id="eventName"
              placeholder="Ex: NAVA Summit 2025"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={saving}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="startDate">Data Início *</Label>
              <Input
                id="startDate"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={saving}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="endDate">Data Fim *</Label>
              <Input
                id="endDate"
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                disabled={saving}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="speakers">Palestrantes</Label>
            <Textarea
              id="speakers"
              placeholder="Lista de palestrantes do evento (opcional)"
              value={speakers}
              onChange={(e) => setSpeakers(e.target.value)}
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
            <Button type="submit" disabled={saving || !name || !startDate || !endDate}>
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Salvando...
                </>
              ) : editEvent ? (
                'Salvar'
              ) : (
                'Criar Evento'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
