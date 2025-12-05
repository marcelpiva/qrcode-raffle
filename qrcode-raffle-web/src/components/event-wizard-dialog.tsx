'use client'

import { useState } from 'react'
import {
  Calendar,
  Loader2,
  AlertCircle,
  ChevronRight,
  ChevronLeft,
  CheckCircle2,
  Plus,
  Trash2,
  Layers,
  Mic2
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

interface TrackData {
  id: string
  title: string
  startDate: string
  endDate: string
  talks: TalkData[]
}

interface TalkData {
  id: string
  title: string
  speaker: string
  startTime: string
  endTime: string
  description: string
}

interface EventWizardDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: (eventId: string) => void
}

// Helper to generate unique IDs
function generateId() {
  return `temp-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

// Helper to format datetime for input
function formatDateTimeLocal(isoString: string | undefined): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function EventWizardDialog({
  open,
  onOpenChange,
  onSuccess
}: EventWizardDialogProps) {
  // Wizard state
  const [step, setStep] = useState(1)

  // Step 1: Event details
  const [name, setName] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [speakers, setSpeakers] = useState('')

  // Step 2: Tracks
  const [tracks, setTracks] = useState<TrackData[]>([])

  // UI state
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const resetForm = () => {
    setStep(1)
    setName('')
    setStartDate('')
    setEndDate('')
    setSpeakers('')
    setTracks([])
    setError(null)
  }

  const handleClose = () => {
    if (!saving) {
      resetForm()
      onOpenChange(false)
    }
  }

  // Step 1 validation
  const canProceedStep1 = () => {
    if (!name || !startDate || !endDate) return false
    if (new Date(endDate) < new Date(startDate)) return false
    return true
  }

  // Add new track
  const addTrack = () => {
    const newTrack: TrackData = {
      id: generateId(),
      title: '',
      startDate: startDate || '',
      endDate: endDate || '',
      talks: []
    }
    setTracks([...tracks, newTrack])
  }

  // Update track
  const updateTrack = (trackId: string, field: keyof TrackData, value: string) => {
    setTracks(tracks.map(t =>
      t.id === trackId ? { ...t, [field]: value } : t
    ))
  }

  // Remove track
  const removeTrack = (trackId: string) => {
    setTracks(tracks.filter(t => t.id !== trackId))
  }

  // Add talk to track
  const addTalk = (trackId: string) => {
    const track = tracks.find(t => t.id === trackId)
    const newTalk: TalkData = {
      id: generateId(),
      title: '',
      speaker: '',
      startTime: track?.startDate ? `${track.startDate}T09:00` : '',
      endTime: track?.startDate ? `${track.startDate}T10:00` : '',
      description: ''
    }
    setTracks(tracks.map(t =>
      t.id === trackId ? { ...t, talks: [...t.talks, newTalk] } : t
    ))
  }

  // Update talk
  const updateTalk = (trackId: string, talkId: string, field: keyof TalkData, value: string) => {
    setTracks(tracks.map(t =>
      t.id === trackId
        ? {
            ...t,
            talks: t.talks.map(talk =>
              talk.id === talkId ? { ...talk, [field]: value } : talk
            )
          }
        : t
    ))
  }

  // Remove talk
  const removeTalk = (trackId: string, talkId: string) => {
    setTracks(tracks.map(t =>
      t.id === trackId
        ? { ...t, talks: t.talks.filter(talk => talk.id !== talkId) }
        : t
    ))
  }

  // Submit
  const handleSubmit = async () => {
    if (!canProceedStep1()) {
      setError('Preencha os dados do evento')
      return
    }

    setSaving(true)
    setError(null)

    try {
      // 1. Create event
      const eventRes = await fetch('/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          startDate,
          endDate,
          speakers: speakers || null
        }),
      })

      const eventData = await eventRes.json()
      if (!eventRes.ok) {
        throw new Error(eventData.error || 'Erro ao criar evento')
      }

      const eventId = eventData.id

      // 2. Create tracks
      for (const track of tracks) {
        if (!track.title || !track.startDate || !track.endDate) continue

        const trackRes = await fetch('/api/tracks', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            eventId,
            title: track.title,
            startDate: new Date(track.startDate).toISOString(),
            endDate: new Date(track.endDate).toISOString()
          }),
        })

        const trackData = await trackRes.json()
        if (!trackRes.ok) {
          console.error('Error creating track:', trackData.error)
          continue
        }

        // 3. Create talks for this track
        for (const talk of track.talks) {
          if (!talk.title) continue

          await fetch('/api/talks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              trackId: trackData.id,
              title: talk.title,
              speaker: talk.speaker || null,
              startTime: talk.startTime ? new Date(talk.startTime).toISOString() : null,
              endTime: talk.endTime ? new Date(talk.endTime).toISOString() : null,
              description: talk.description || null
            }),
          })
        }
      }

      resetForm()
      onOpenChange(false)
      onSuccess(eventId)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao criar evento')
    } finally {
      setSaving(false)
    }
  }

  const formatDate = (dateStr: string) => {
    if (!dateStr) return ''
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    })
  }

  const formatTime = (dateStr: string) => {
    if (!dateStr) return ''
    return new Date(dateStr).toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  // Step indicator
  const steps = [
    { number: 1, title: 'Evento' },
    { number: 2, title: 'Trilhas' },
    { number: 3, title: 'Confirmar' }
  ]

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Novo Evento
          </DialogTitle>
          <DialogDescription>
            Crie um novo evento com trilhas e palestras
          </DialogDescription>
        </DialogHeader>

        {/* Step indicator */}
        <div className="flex items-center justify-center gap-4 py-4">
          {steps.map((s, index) => (
            <div key={s.number} className="flex items-center">
              <div className={cn(
                "flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium transition-colors",
                step >= s.number
                  ? "bg-primary text-primary-foreground"
                  : "bg-muted text-muted-foreground"
              )}>
                {step > s.number ? <CheckCircle2 className="h-4 w-4" /> : s.number}
              </div>
              <span className={cn(
                "ml-2 text-sm hidden sm:inline",
                step >= s.number ? "text-foreground" : "text-muted-foreground"
              )}>
                {s.title}
              </span>
              {index < steps.length - 1 && (
                <ChevronRight className="h-4 w-4 mx-2 text-muted-foreground" />
              )}
            </div>
          ))}
        </div>

        {/* Step 1: Event Details */}
        {step === 1 && (
          <div className="space-y-4">
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
                <Label htmlFor="startDate">Data Inicio *</Label>
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
              <Label htmlFor="speakers">Palestrantes (opcional)</Label>
              <Textarea
                id="speakers"
                placeholder="Lista de palestrantes do evento"
                value={speakers}
                onChange={(e) => setSpeakers(e.target.value)}
                disabled={saving}
                rows={3}
              />
            </div>
          </div>
        )}

        {/* Step 2: Tracks and Talks */}
        {step === 2 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label className="text-base">Trilhas do Evento</Label>
              <Button type="button" variant="outline" size="sm" onClick={addTrack}>
                <Plus className="h-4 w-4 mr-1" />
                Nova Trilha
              </Button>
            </div>

            {tracks.length === 0 ? (
              <Card className="border-dashed">
                <CardContent className="flex flex-col items-center justify-center py-8">
                  <Layers className="h-10 w-10 text-muted-foreground mb-3" />
                  <p className="text-muted-foreground text-sm text-center mb-3">
                    Nenhuma trilha adicionada ainda
                  </p>
                  <Button type="button" variant="outline" size="sm" onClick={addTrack}>
                    <Plus className="h-4 w-4 mr-1" />
                    Adicionar Trilha
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-4">
                {tracks.map((track, trackIndex) => (
                  <Card key={track.id}>
                    <CardHeader className="pb-3">
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-base flex items-center gap-2">
                          <Layers className="h-4 w-4" />
                          Trilha {trackIndex + 1}
                        </CardTitle>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-destructive"
                          onClick={() => removeTrack(track.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="space-y-2">
                        <Label>Titulo *</Label>
                        <Input
                          placeholder="Ex: Inteligencia Artificial"
                          value={track.title}
                          onChange={(e) => updateTrack(track.id, 'title', e.target.value)}
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label>Data Início *</Label>
                          <Input
                            type="date"
                            value={track.startDate}
                            onChange={(e) => updateTrack(track.id, 'startDate', e.target.value)}
                          />
                        </div>
                        <div className="space-y-2">
                          <Label>Data Fim *</Label>
                          <Input
                            type="date"
                            value={track.endDate}
                            onChange={(e) => updateTrack(track.id, 'endDate', e.target.value)}
                          />
                        </div>
                      </div>

                      {/* Talks section */}
                      <div className="border-t pt-4">
                        <div className="flex items-center justify-between mb-3">
                          <Label className="text-sm flex items-center gap-2">
                            <Mic2 className="h-3 w-3" />
                            Palestras
                          </Label>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            className="h-7 text-xs"
                            onClick={() => addTalk(track.id)}
                          >
                            <Plus className="h-3 w-3 mr-1" />
                            Palestra
                          </Button>
                        </div>

                        {track.talks.length === 0 ? (
                          <p className="text-xs text-muted-foreground text-center py-2">
                            Nenhuma palestra (pode adicionar depois)
                          </p>
                        ) : (
                          <div className="space-y-2">
                            {track.talks.map((talk) => (
                              <div key={talk.id} className="p-3 rounded-lg bg-muted/30 space-y-2">
                                <div className="flex items-center justify-between">
                                  <Input
                                    placeholder="Titulo da palestra"
                                    value={talk.title}
                                    onChange={(e) => updateTalk(track.id, talk.id, 'title', e.target.value)}
                                    className="flex-1 mr-2"
                                  />
                                  <Button
                                    type="button"
                                    variant="ghost"
                                    size="icon"
                                    className="h-7 w-7 text-muted-foreground hover:text-destructive"
                                    onClick={() => removeTalk(track.id, talk.id)}
                                  >
                                    <Trash2 className="h-3 w-3" />
                                  </Button>
                                </div>
                                <div className="space-y-2">
                                  <Input
                                    placeholder="Palestrante"
                                    value={talk.speaker}
                                    onChange={(e) => updateTalk(track.id, talk.id, 'speaker', e.target.value)}
                                  />
                                  <div className="grid grid-cols-2 gap-2">
                                    <div>
                                      <Label className="text-xs text-muted-foreground">Início</Label>
                                      <Input
                                        type="datetime-local"
                                        value={talk.startTime}
                                        onChange={(e) => updateTalk(track.id, talk.id, 'startTime', e.target.value)}
                                      />
                                    </div>
                                    <div>
                                      <Label className="text-xs text-muted-foreground">Fim</Label>
                                      <Input
                                        type="datetime-local"
                                        value={talk.endTime}
                                        onChange={(e) => updateTalk(track.id, talk.id, 'endTime', e.target.value)}
                                      />
                                    </div>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Step 3: Confirmation */}
        {step === 3 && (
          <div className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">{name}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Periodo</span>
                  <span>{formatDate(startDate)} - {formatDate(endDate)}</span>
                </div>

                {speakers && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Palestrantes</span>
                    <span className="text-right max-w-[60%] truncate">{speakers}</span>
                  </div>
                )}

                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Trilhas</span>
                  <Badge variant="outline">{tracks.length}</Badge>
                </div>

                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Palestras</span>
                  <Badge variant="outline">
                    {tracks.reduce((sum, t) => sum + t.talks.length, 0)}
                  </Badge>
                </div>
              </CardContent>
            </Card>

            {tracks.length > 0 && (
              <div className="space-y-2">
                <Label className="text-sm">Trilhas e Palestras:</Label>
                {tracks.filter(t => t.title).map((track) => (
                  <Card key={track.id} className="bg-muted/30">
                    <CardContent className="p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <Layers className="h-4 w-4 text-primary" />
                        <span className="font-medium">{track.title}</span>
                        <Badge variant="outline" className="text-xs">
                          {track.startDate === track.endDate
                            ? formatDate(track.startDate)
                            : `${formatDate(track.startDate)} - ${formatDate(track.endDate)}`
                          }
                        </Badge>
                      </div>
                      {track.talks.filter(t => t.title).length > 0 && (
                        <div className="pl-6 space-y-1">
                          {track.talks.filter(t => t.title).map((talk) => (
                            <div key={talk.id} className="flex items-center gap-2 text-sm">
                              <Mic2 className="h-3 w-3 text-muted-foreground" />
                              <span>{talk.title}</span>
                              {talk.speaker && (
                                <span className="text-muted-foreground">({talk.speaker})</span>
                              )}
                            </div>
                          ))}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {error && (
          <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-sm text-destructive flex items-center gap-2">
            <AlertCircle className="h-4 w-4" />
            {error}
          </div>
        )}

        {/* Navigation buttons */}
        <div className="flex justify-between pt-4 border-t">
          <Button
            type="button"
            variant="outline"
            onClick={() => step === 1 ? handleClose() : setStep(step - 1)}
            disabled={saving}
          >
            {step === 1 ? 'Cancelar' : (
              <>
                <ChevronLeft className="h-4 w-4 mr-1" />
                Voltar
              </>
            )}
          </Button>

          {step < 3 ? (
            <Button
              type="button"
              onClick={() => setStep(step + 1)}
              disabled={step === 1 && !canProceedStep1()}
            >
              Proximo
              <ChevronRight className="h-4 w-4 ml-1" />
            </Button>
          ) : (
            <Button
              onClick={handleSubmit}
              disabled={saving}
            >
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Criando...
                </>
              ) : (
                <>
                  <Calendar className="h-4 w-4 mr-2" />
                  Criar Evento
                </>
              )}
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
