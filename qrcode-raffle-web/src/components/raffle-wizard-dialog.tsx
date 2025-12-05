'use client'

import { useState, useEffect, useMemo } from 'react'
import {
  Trophy,
  Loader2,
  AlertCircle,
  ChevronRight,
  ChevronLeft,
  CheckCircle2,
  Globe,
  Mic2,
  Users,
  Clock,
  QrCode,
  Search,
  Sparkles,
  Timer,
  Mail,
  Filter,
  Link,
  Shuffle
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Checkbox } from '@/components/ui/checkbox'
import { Switch } from '@/components/ui/switch'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

interface Talk {
  id: string
  title: string
  speaker: string | null
  startTime: string | null
  attendanceCount: number
}

interface Track {
  id: string
  title: string
  startDate?: string
  endDate?: string
  talks: Talk[]
}

interface RaffleWizardDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
  eventId: string
  eventName: string
  tracks: Track[]
  preselectedTalkId?: string
  eventUniqueAttendeeCount?: number
}

type RaffleType = 'event' | 'talk'

// Helper to combine time (HH:mm) with today's date
function combineTimeWithToday(time: string): string {
  const today = new Date()
  const [hours, minutes] = time.split(':').map(Number)
  today.setHours(hours, minutes, 0, 0)
  return today.toISOString()
}

export function RaffleWizardDialog({
  open,
  onOpenChange,
  onSuccess,
  eventId,
  eventName,
  tracks,
  preselectedTalkId,
  eventUniqueAttendeeCount = 0
}: RaffleWizardDialogProps) {
  // Wizard step (1, 2, or 3)
  const [step, setStep] = useState(1)

  // Step 1: Type selection
  const [raffleType, setRaffleType] = useState<RaffleType | null>(preselectedTalkId ? 'talk' : null)

  // Step 2: Configuration
  // For Event type
  const [minDurationPerTalk, setMinDurationPerTalk] = useState<number>(0) // minutes per talk
  const [minTalksCount, setMinTalksCount] = useState<number>(1) // minimum talks attended
  const [eligibleCount, setEligibleCount] = useState<number>(eventUniqueAttendeeCount)
  const [totalUniqueCount, setTotalUniqueCount] = useState<number>(eventUniqueAttendeeCount)
  const [totalTalksWithAttendance, setTotalTalksWithAttendance] = useState<number>(0)
  const [loadingEligible, setLoadingEligible] = useState(false)

  // For Talk type
  const [selectedTalkId, setSelectedTalkId] = useState<string | null>(preselectedTalkId || null)
  const [talkSearch, setTalkSearch] = useState('')

  // Step 3: Prize details (shared)
  const [name, setName] = useState('')
  const [prize, setPrize] = useState('')
  const [description, setDescription] = useState('')

  // Advanced options
  const [allowedDomain, setAllowedDomain] = useState('')
  const [enableSchedule, setEnableSchedule] = useState(false)
  const [startsAt, setStartsAt] = useState<string>('')
  const [endsAt, setEndsAt] = useState<string>('')
  const [requireConfirmation, setRequireConfirmation] = useState(false)
  const [confirmationTimeoutMinutes, setConfirmationTimeoutMinutes] = useState<number>(5)
  const [allowLinkRegistration, setAllowLinkRegistration] = useState(false) // For event raffles
  const [autoDrawOnEnd, setAutoDrawOnEnd] = useState(false) // Auto-draw when schedule ends

  // UI state
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Filtered talks based on search
  const filteredTracks = useMemo(() => {
    if (!talkSearch.trim()) return tracks
    const search = talkSearch.toLowerCase()
    return tracks.map(track => ({
      ...track,
      talks: track.talks.filter(talk =>
        talk.title.toLowerCase().includes(search) ||
        (talk.speaker?.toLowerCase().includes(search))
      )
    })).filter(track => track.talks.length > 0)
  }, [tracks, talkSearch])

  // Get selected talk info
  const selectedTalk = useMemo(() => {
    for (const track of tracks) {
      const talk = track.talks.find(t => t.id === selectedTalkId)
      if (talk) return { ...talk, trackTitle: track.title }
    }
    return null
  }, [tracks, selectedTalkId])

  // Total talks count
  const totalTalks = tracks.reduce((sum, t) => sum + t.talks.length, 0)

  // Fetch eligible count when filters change (for event type)
  useEffect(() => {
    if (raffleType === 'event' && step === 2) {
      const fetchEligibleCount = async () => {
        setLoadingEligible(true)
        try {
          let url = `/api/events/${eventId}/eligible-count?minDuration=${minDurationPerTalk}&minTalks=${minTalksCount}`
          if (allowedDomain) {
            url += `&domain=${encodeURIComponent(allowedDomain)}`
          }
          const res = await fetch(url)
          if (res.ok) {
            const data = await res.json()
            setEligibleCount(data.eligibleCount)
            setTotalUniqueCount(data.totalCount)
            setTotalTalksWithAttendance(data.totalTalksWithAttendance)
          }
        } catch (err) {
          console.error('Error fetching eligible count:', err)
        } finally {
          setLoadingEligible(false)
        }
      }
      fetchEligibleCount()
    }
  }, [raffleType, step, minDurationPerTalk, minTalksCount, eventId, allowedDomain])

  const resetForm = () => {
    setStep(1)
    setRaffleType(preselectedTalkId ? 'talk' : null)
    setMinDurationPerTalk(0)
    setMinTalksCount(1)
    setSelectedTalkId(preselectedTalkId || null)
    setTalkSearch('')
    setName('')
    setPrize('')
    setDescription('')
    setAllowedDomain('')
    setEnableSchedule(false)
    setStartsAt('')
    setEndsAt('')
    setRequireConfirmation(false)
    setConfirmationTimeoutMinutes(5)
    setAllowLinkRegistration(false)
    setAutoDrawOnEnd(false)
    setError(null)
  }

  useEffect(() => {
    if (open) {
      if (preselectedTalkId) {
        setRaffleType('talk')
        setSelectedTalkId(preselectedTalkId)
      }
    }
  }, [open, preselectedTalkId])

  const handleClose = () => {
    if (!saving) {
      resetForm()
      onOpenChange(false)
    }
  }

  const canProceedStep1 = () => raffleType !== null

  const canProceedStep2 = () => {
    if (raffleType === 'event') return true
    if (raffleType === 'talk') return selectedTalkId !== null
    return false
  }

  const canSubmit = () => {
    return name.trim() !== '' && prize.trim() !== ''
  }

  const handleSubmit = async () => {
    if (!canSubmit()) {
      setError('Nome e prêmio são obrigatórios')
      return
    }

    setSaving(true)
    setError(null)

    try {
      const res = await fetch('/api/raffles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          prize,
          description: description || null,
          allowedDomain: allowedDomain || null,
          startsAt: enableSchedule && startsAt ? combineTimeWithToday(startsAt) : null,
          endsAt: enableSchedule && endsAt ? combineTimeWithToday(endsAt) : null,
          autoDrawOnEnd: enableSchedule && endsAt && autoDrawOnEnd,
          requireConfirmation,
          confirmationTimeoutMinutes: requireConfirmation ? confirmationTimeoutMinutes : null,
          eventId: raffleType === 'event' ? eventId : null,
          talkId: raffleType === 'talk' ? selectedTalkId : null,
          minDurationMinutes: raffleType === 'event' && minDurationPerTalk > 0 ? minDurationPerTalk : null,
          minTalksCount: raffleType === 'event' && minTalksCount > 1 ? minTalksCount : null,
          allowLinkRegistration: raffleType === 'event' ? allowLinkRegistration : false
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.error || 'Erro ao criar sorteio')
      }

      resetForm()
      onOpenChange(false)
      onSuccess()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao criar sorteio')
    } finally {
      setSaving(false)
    }
  }

  const formatTime = (dateStr: string | null) => {
    if (!dateStr) return ''
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit'
    })
  }

  // Step indicator
  const steps = [
    { number: 1, title: 'Tipo' },
    { number: 2, title: 'Filtros' },
    { number: 3, title: 'Prêmio' }
  ]

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader className="pb-2">
          <DialogTitle className="flex items-center gap-2">
            <Trophy className="h-5 w-5 text-amber-500" />
            Novo Sorteio
          </DialogTitle>
          <DialogDescription className="text-xs">
            {eventName}
          </DialogDescription>
        </DialogHeader>

        {/* Step indicator */}
        <div className="flex items-center justify-center gap-2 py-3">
          {steps.map((s, index) => (
            <div key={s.number} className="flex items-center">
              <div className={cn(
                "flex items-center justify-center w-7 h-7 rounded-full text-xs font-medium transition-all duration-300",
                step >= s.number
                  ? "bg-primary text-primary-foreground scale-100"
                  : "bg-muted text-muted-foreground scale-95"
              )}>
                {step > s.number ? <CheckCircle2 className="h-3.5 w-3.5" /> : s.number}
              </div>
              <span className={cn(
                "ml-1.5 text-xs hidden sm:inline transition-colors duration-300",
                step >= s.number ? "text-foreground" : "text-muted-foreground"
              )}>
                {s.title}
              </span>
              {index < steps.length - 1 && (
                <ChevronRight className="h-3 w-3 mx-1.5 text-muted-foreground/50" />
              )}
            </div>
          ))}
        </div>

        {/* Step 1: Type Selection */}
        {step === 1 && (
          <div className="space-y-4 animate-in fade-in-50 duration-300">
            <div className="text-center mb-4">
              <h3 className="text-sm font-medium">Escolha o tipo de sorteio</h3>
              <p className="text-xs text-muted-foreground mt-1">
                Defina quem poderá participar
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              {/* Event Card */}
              <Card
                className={cn(
                  "cursor-pointer transition-all duration-200 hover:shadow-md",
                  raffleType === 'event'
                    ? "ring-2 ring-primary border-primary bg-primary/5"
                    : "hover:border-primary/50"
                )}
                onClick={() => setRaffleType('event')}
              >
                <CardContent className="p-4 text-center">
                  <div className={cn(
                    "w-10 h-10 rounded-full mx-auto mb-3 flex items-center justify-center transition-colors",
                    raffleType === 'event' ? "bg-primary text-primary-foreground" : "bg-muted"
                  )}>
                    <Globe className="h-5 w-5" />
                  </div>
                  <h4 className="font-medium text-sm mb-1">Evento</h4>
                  <p className="text-[10px] text-muted-foreground leading-tight mb-2">
                    Participantes de todas as palestras
                  </p>
                  <Badge variant="secondary" className="text-[10px]">
                    <Users className="h-2.5 w-2.5 mr-1" />
                    {eventUniqueAttendeeCount} únicos
                  </Badge>
                </CardContent>
              </Card>

              {/* Talk Card */}
              <Card
                className={cn(
                  "cursor-pointer transition-all duration-200 hover:shadow-md",
                  raffleType === 'talk'
                    ? "ring-2 ring-primary border-primary bg-primary/5"
                    : "hover:border-primary/50"
                )}
                onClick={() => setRaffleType('talk')}
              >
                <CardContent className="p-4 text-center">
                  <div className={cn(
                    "w-10 h-10 rounded-full mx-auto mb-3 flex items-center justify-center transition-colors",
                    raffleType === 'talk' ? "bg-primary text-primary-foreground" : "bg-muted"
                  )}>
                    <Mic2 className="h-5 w-5" />
                  </div>
                  <h4 className="font-medium text-sm mb-1">Palestra</h4>
                  <p className="text-[10px] text-muted-foreground leading-tight mb-2">
                    Via QR Code com auto-inscrição
                  </p>
                  <Badge variant="secondary" className="text-[10px]">
                    <QrCode className="h-2.5 w-2.5 mr-1" />
                    {totalTalks} palestras
                  </Badge>
                </CardContent>
              </Card>
            </div>
          </div>
        )}

        {/* Step 2: Configuration */}
        {step === 2 && (
          <div className="space-y-4 animate-in fade-in-50 duration-300">
            {raffleType === 'event' ? (
              <>
                <div className="text-center mb-3">
                  <h3 className="text-sm font-medium flex items-center justify-center gap-2">
                    <Filter className="h-4 w-4" />
                    Filtros de Elegibilidade
                  </h3>
                  <p className="text-xs text-muted-foreground mt-1">
                    Defina os requisitos para participação
                  </p>
                </div>

                {/* Min Duration Per Talk */}
                <div className="space-y-2">
                  <Label className="text-xs flex items-center gap-2">
                    <Clock className="h-3 w-3" />
                    Tempo mínimo por palestra
                  </Label>
                  <div className="flex gap-2">
                    {[0, 15, 30, 45, 60].map((mins) => (
                      <Button
                        key={mins}
                        type="button"
                        variant={minDurationPerTalk === mins ? "default" : "outline"}
                        size="sm"
                        className="flex-1 text-xs"
                        onClick={() => setMinDurationPerTalk(mins)}
                      >
                        {mins === 0 ? 'Sem filtro' : `${mins}min`}
                      </Button>
                    ))}
                  </div>
                  <p className="text-[10px] text-muted-foreground">
                    Participante deve permanecer pelo menos este tempo em cada palestra
                  </p>
                </div>

                {/* Min Talks Count */}
                <div className="space-y-2">
                  <Label className="text-xs flex items-center gap-2">
                    <Mic2 className="h-3 w-3" />
                    Número mínimo de palestras
                  </Label>
                  <div className="flex gap-2">
                    {[1, 2, 3, 4, 5].map((count) => (
                      <Button
                        key={count}
                        type="button"
                        variant={minTalksCount === count ? "default" : "outline"}
                        size="sm"
                        className="flex-1 text-xs"
                        onClick={() => setMinTalksCount(count)}
                        disabled={count > totalTalksWithAttendance && totalTalksWithAttendance > 0}
                      >
                        {count}
                      </Button>
                    ))}
                  </div>
                  <p className="text-[10px] text-muted-foreground">
                    Participante deve ter assistido pelo menos {minTalksCount} palestra{minTalksCount > 1 ? 's' : ''} com o tempo mínimo
                  </p>
                </div>

                {/* Domain filter (for Event type - in Step 2) */}
                <div className="space-y-2">
                  <Label className="text-xs flex items-center gap-2">
                    <Mail className="h-3 w-3" />
                    Filtrar por domínio de email (opcional)
                  </Label>
                  <Input
                    placeholder="ex: nava.com.br"
                    value={allowedDomain}
                    onChange={(e) => setAllowedDomain(e.target.value)}
                    className="h-8 text-sm"
                  />
                  <p className="text-[10px] text-muted-foreground">
                    Deixe vazio para permitir todos os domínios
                  </p>
                </div>

                {/* Eligible count */}
                <div className="p-3 rounded-lg bg-gradient-to-r from-primary/10 to-primary/5 border border-primary/20">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Users className="h-4 w-4 text-primary" />
                      <span className="text-sm font-medium">Participantes elegíveis</span>
                    </div>
                    <div className="text-right">
                      {loadingEligible ? (
                        <Loader2 className="h-5 w-5 animate-spin text-primary" />
                      ) : (
                        <>
                          <span className="text-lg font-bold text-primary">{eligibleCount}</span>
                          <span className="text-xs text-muted-foreground ml-1">
                            de {totalUniqueCount}
                          </span>
                        </>
                      )}
                    </div>
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-1">
                    {minDurationPerTalk > 0 || minTalksCount > 1 || allowedDomain
                      ? `Participantes que assistiram ≥${minTalksCount} palestra${minTalksCount > 1 ? 's' : ''} por ≥${minDurationPerTalk || 0}min${allowedDomain ? ` @${allowedDomain}` : ''}`
                      : 'Todos os participantes únicos do evento'
                    }
                  </p>
                </div>

                {/* Allow link registration */}
                <div className="flex items-start gap-3 p-3 rounded-lg border bg-muted/30">
                  <Checkbox
                    id="allowLinkRegistration"
                    checked={allowLinkRegistration}
                    onCheckedChange={(checked) => setAllowLinkRegistration(checked === true)}
                  />
                  <div className="flex-1">
                    <Label htmlFor="allowLinkRegistration" className="text-xs font-medium flex items-center gap-2 cursor-pointer">
                      <Link className="h-3 w-3" />
                      Permitir inscrições por link
                    </Label>
                    <p className="text-[10px] text-muted-foreground mt-0.5">
                      {allowLinkRegistration
                        ? 'Participantes podem se inscrever via QR Code/link além dos elegíveis automáticos'
                        : 'Apenas participantes elegíveis (presenças) serão incluídos automaticamente'
                      }
                    </p>
                  </div>
                </div>
              </>
            ) : (
              <>
                <div className="text-center mb-3">
                  <h3 className="text-sm font-medium">Selecione a Palestra</h3>
                  <p className="text-xs text-muted-foreground mt-1">
                    Participantes via QR Code
                  </p>
                </div>

                {/* Search */}
                <div className="relative">
                  <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
                  <Input
                    placeholder="Buscar palestra..."
                    value={talkSearch}
                    onChange={(e) => setTalkSearch(e.target.value)}
                    className="pl-8 h-8 text-sm"
                  />
                </div>

                {/* Talks list */}
                <div className="space-y-2 max-h-[200px] overflow-y-auto pr-1">
                  {filteredTracks.map((track) => (
                    <div key={track.id}>
                      <div className="text-[9px] uppercase tracking-wider text-muted-foreground font-medium mb-1 px-1 sticky top-0 bg-background py-0.5">
                        {track.title}
                      </div>
                      <div className="space-y-0.5">
                        {track.talks.map((talk) => (
                          <div
                            key={talk.id}
                            className={cn(
                              "p-2 rounded-md border cursor-pointer transition-all",
                              selectedTalkId === talk.id
                                ? "border-primary bg-primary/5"
                                : "hover:border-primary/50"
                            )}
                            onClick={() => setSelectedTalkId(talk.id)}
                          >
                            <div className="flex items-center justify-between gap-2">
                              <div className="flex items-center gap-2 min-w-0">
                                <div className={cn(
                                  "w-3.5 h-3.5 rounded-full border-2 flex-shrink-0 flex items-center justify-center transition-colors",
                                  selectedTalkId === talk.id
                                    ? "border-primary bg-primary"
                                    : "border-muted-foreground/30"
                                )}>
                                  {selectedTalkId === talk.id && (
                                    <div className="w-1 h-1 rounded-full bg-white" />
                                  )}
                                </div>
                                <p className="text-xs font-medium truncate">{talk.title}</p>
                              </div>
                              <Badge variant="secondary" className="text-[10px] flex-shrink-0">
                                {talk.attendanceCount}
                              </Badge>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                  {filteredTracks.length === 0 && (
                    <div className="text-center py-4 text-muted-foreground text-xs">
                      Nenhuma palestra encontrada
                    </div>
                  )}
                </div>

                {/* Domain filter for Talk */}
                <div className="pt-2 border-t">
                  <div className="flex items-center gap-2">
                    <Mail className="h-3.5 w-3.5 text-muted-foreground" />
                    <Label className="text-xs flex-1">Filtrar por domínio de email</Label>
                    <Input
                      placeholder="ex: nava.com.br"
                      value={allowedDomain}
                      onChange={(e) => setAllowedDomain(e.target.value)}
                      className="h-7 w-32 text-xs"
                    />
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-1 ml-5">
                    Deixe vazio para permitir todos
                  </p>
                </div>
              </>
            )}
          </div>
        )}

        {/* Step 3: Prize Details */}
        {step === 3 && (
          <div className="space-y-4 animate-in fade-in-50 duration-300">
            {/* Name and Prize */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label htmlFor="name" className="text-xs">Nome do Sorteio *</Label>
                <Input
                  id="name"
                  placeholder="Ex: Sorteio Kindle"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  disabled={saving}
                  className="h-9"
                />
              </div>
              <div className="space-y-1">
                <Label htmlFor="prize" className="text-xs">Prêmio *</Label>
                <Input
                  id="prize"
                  placeholder="Ex: Amazon Kindle"
                  value={prize}
                  onChange={(e) => setPrize(e.target.value)}
                  disabled={saving}
                  className="h-9"
                />
              </div>
            </div>

            {/* Description */}
            <div className="space-y-1">
              <Label htmlFor="description" className="text-xs">Descrição (opcional)</Label>
              <Textarea
                id="description"
                placeholder="Detalhes sobre o prêmio..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                disabled={saving}
                rows={2}
                className="min-h-[50px] text-sm resize-none"
              />
            </div>

            {/* Advanced options */}
            <div className="pt-2 border-t space-y-3">
              <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
                Opções Avançadas
              </p>

              {/* Schedule with start/end time */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Timer className="h-3.5 w-3.5 text-muted-foreground" />
                    <Label className="text-xs">Agendar sorteio</Label>
                  </div>
                  <Switch
                    checked={enableSchedule}
                    onCheckedChange={setEnableSchedule}
                    disabled={saving}
                  />
                </div>
                {enableSchedule && (
                  <div className="flex items-center gap-2 ml-5">
                    <div className="flex items-center gap-1">
                      <Label className="text-[10px] text-muted-foreground">Início</Label>
                      <Input
                        type="time"
                        value={startsAt}
                        onChange={(e) => setStartsAt(e.target.value)}
                        disabled={saving}
                        className="h-7 w-24 text-xs"
                      />
                    </div>
                    <span className="text-muted-foreground">→</span>
                    <div className="flex items-center gap-1">
                      <Label className="text-[10px] text-muted-foreground">Fim</Label>
                      <Input
                        type="time"
                        value={endsAt}
                        onChange={(e) => setEndsAt(e.target.value)}
                        disabled={saving}
                        className="h-7 w-24 text-xs"
                      />
                    </div>
                  </div>
                )}
                {enableSchedule && (
                  <p className="text-[10px] text-muted-foreground ml-5">
                    Inscrições abrem e fecham automaticamente nos horários definidos (hoje)
                  </p>
                )}
                {enableSchedule && endsAt && (
                  <div className="flex items-start gap-3 ml-5 p-2 rounded-md bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800">
                    <Checkbox
                      id="autoDrawOnEnd"
                      checked={autoDrawOnEnd}
                      onCheckedChange={(checked) => setAutoDrawOnEnd(checked === true)}
                    />
                    <div className="flex-1">
                      <Label htmlFor="autoDrawOnEnd" className="text-xs font-medium flex items-center gap-2 cursor-pointer">
                        <Shuffle className="h-3 w-3 text-amber-600" />
                        Sortear automaticamente ao encerrar
                      </Label>
                      <p className="text-[10px] text-muted-foreground mt-0.5">
                        Quando o countdown atingir zero, o sorteio será realizado automaticamente
                      </p>
                    </div>
                  </div>
                )}
              </div>

              {/* Winner confirmation */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="h-3.5 w-3.5 text-muted-foreground" />
                  <Label className="text-xs">Confirmação do ganhador</Label>
                </div>
                <div className="flex items-center gap-2">
                  <Switch
                    checked={requireConfirmation}
                    onCheckedChange={setRequireConfirmation}
                    disabled={saving}
                  />
                  {requireConfirmation && (
                    <>
                      <Input
                        type="number"
                        min={1}
                        value={confirmationTimeoutMinutes}
                        onChange={(e) => setConfirmationTimeoutMinutes(parseInt(e.target.value) || 5)}
                        disabled={saving}
                        className="h-7 w-16 text-xs text-center"
                      />
                      <span className="text-xs text-muted-foreground">min</span>
                    </>
                  )}
                </div>
              </div>
              {requireConfirmation && (
                <p className="text-[10px] text-muted-foreground ml-5">
                  Ganhador deve confirmar em até {confirmationTimeoutMinutes} minutos
                </p>
              )}
            </div>

            {/* Summary */}
            <div className="p-3 rounded-lg bg-muted/50 border space-y-2">
              <div className="flex items-center gap-2 text-xs font-medium">
                <Sparkles className="h-3.5 w-3.5 text-amber-500" />
                Resumo
              </div>
              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
                <span className="text-muted-foreground">Tipo:</span>
                <span className="font-medium">
                  {raffleType === 'event' ? 'Evento' : 'Palestra'}
                </span>

                {raffleType === 'event' ? (
                  <>
                    <span className="text-muted-foreground">Filtros:</span>
                    <span className="font-medium">
                      {minDurationPerTalk > 0 || minTalksCount > 1
                        ? `≥${minTalksCount} palestra${minTalksCount > 1 ? 's' : ''} × ≥${minDurationPerTalk}min`
                        : 'Sem filtro'
                      }
                    </span>
                  </>
                ) : (
                  <>
                    <span className="text-muted-foreground">Palestra:</span>
                    <span className="font-medium truncate">
                      {selectedTalk?.title || '-'}
                    </span>
                  </>
                )}

                <span className="text-muted-foreground">Elegíveis:</span>
                <span className="font-medium text-primary">
                  {raffleType === 'event' ? eligibleCount : (selectedTalk?.attendanceCount ?? 0)}
                </span>

                {allowedDomain && (
                  <>
                    <span className="text-muted-foreground">Domínio:</span>
                    <span className="font-medium">@{allowedDomain}</span>
                  </>
                )}

                {raffleType === 'event' && allowLinkRegistration && (
                  <>
                    <span className="text-muted-foreground">Inscrições:</span>
                    <span className="font-medium text-blue-600">Via link permitido</span>
                  </>
                )}

                {enableSchedule && (startsAt || endsAt) && (
                  <>
                    <span className="text-muted-foreground">Horário:</span>
                    <span className="font-medium">{startsAt || '--:--'} → {endsAt || '--:--'}</span>
                  </>
                )}

                {enableSchedule && endsAt && autoDrawOnEnd && (
                  <>
                    <span className="text-muted-foreground">Auto-sorteio:</span>
                    <span className="font-medium text-amber-600 flex items-center gap-1">
                      <Shuffle className="h-3 w-3" />
                      Ao encerrar
                    </span>
                  </>
                )}
              </div>
            </div>
          </div>
        )}

        {error && (
          <div className="p-2.5 rounded-lg bg-destructive/10 border border-destructive/20 text-xs text-destructive flex items-center gap-2">
            <AlertCircle className="h-3.5 w-3.5 flex-shrink-0" />
            {error}
          </div>
        )}

        {/* Navigation buttons */}
        <div className="flex justify-between pt-3 border-t">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => step === 1 ? handleClose() : setStep(step - 1)}
            disabled={saving}
          >
            {step === 1 ? 'Cancelar' : (
              <>
                <ChevronLeft className="h-3.5 w-3.5 mr-1" />
                Voltar
              </>
            )}
          </Button>

          {step < 3 ? (
            <Button
              type="button"
              size="sm"
              onClick={() => setStep(step + 1)}
              disabled={
                (step === 1 && !canProceedStep1()) ||
                (step === 2 && !canProceedStep2())
              }
            >
              Próximo
              <ChevronRight className="h-3.5 w-3.5 ml-1" />
            </Button>
          ) : (
            <Button
              size="sm"
              onClick={handleSubmit}
              disabled={saving || !canSubmit()}
              className="bg-amber-500 hover:bg-amber-600"
            >
              {saving ? (
                <>
                  <Loader2 className="h-3.5 w-3.5 mr-1.5 animate-spin" />
                  Criando...
                </>
              ) : (
                <>
                  <Trophy className="h-3.5 w-3.5 mr-1.5" />
                  Criar Sorteio
                </>
              )}
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
