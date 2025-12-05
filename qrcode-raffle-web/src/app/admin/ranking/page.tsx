'use client'

import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, Trophy, Users, Gift, Loader2, Check, ChevronDown, ChevronUp, Calendar, Layers } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

interface AvailableRaffle {
  id: string
  name: string
  prize: string
  participantCount: number
  createdAt: string
}

interface Track {
  id: string
  title: string
  day: string
  attendanceCount: number
}

interface EventWithTracks {
  id: string
  name: string
  startDate: string
  endDate: string
  tracks: Track[]
}

interface RankingEntry {
  email: string
  name: string
  participatedIn: number
  totalSelected: number
  percentage: number
  raffleIds?: string[]
  trackIds?: string[]
  eventIds?: string[]
  eventsParticipated?: number
  tracksParticipated?: number
}

interface RaffleRankingResponse {
  availableRaffles: AvailableRaffle[]
  selectedRaffles: { id: string; name: string; participantCount: number }[]
  ranking: RankingEntry[]
}

interface TrackRankingResponse {
  events: EventWithTracks[]
  selectedTracks: { id: string; title: string; eventId: string; eventName: string; attendanceCount: number }[]
  ranking: RankingEntry[]
}

export default function RankingPage() {
  const router = useRouter()

  // Tab state
  const [activeTab, setActiveTab] = useState<'sorteios' | 'eventos'>('sorteios')

  // Raffle states
  const [loadingRaffles, setLoadingRaffles] = useState(true)
  const [calculatingRaffles, setCalculatingRaffles] = useState(false)
  const [creatingFromRaffles, setCreatingFromRaffles] = useState(false)
  const [availableRaffles, setAvailableRaffles] = useState<AvailableRaffle[]>([])
  const [selectedRaffleIds, setSelectedRaffleIds] = useState<Set<string>>(new Set())
  const [raffleRanking, setRaffleRanking] = useState<RankingEntry[]>([])
  const [showAllRaffles, setShowAllRaffles] = useState(false)

  // Event/Track states
  const [loadingTracks, setLoadingTracks] = useState(true)
  const [calculatingTracks, setCalculatingTracks] = useState(false)
  const [creatingFromTracks, setCreatingFromTracks] = useState(false)
  const [eventsWithTracks, setEventsWithTracks] = useState<EventWithTracks[]>([])
  const [selectedTrackIds, setSelectedTrackIds] = useState<Set<string>>(new Set())
  const [trackRanking, setTrackRanking] = useState<RankingEntry[]>([])
  const [expandedEventIds, setExpandedEventIds] = useState<Set<string>>(new Set())

  // Form for creating raffle (shared)
  const [raffleFormData, setRaffleFormData] = useState({
    name: '',
    prize: '',
    description: '',
    ruleType: 'minimum' as 'all' | 'minimum',
    minParticipation: 1
  })

  const [trackFormData, setTrackFormData] = useState({
    name: '',
    prize: '',
    description: '',
    ruleType: 'minimum' as 'all' | 'minimum',
    minParticipation: 1
  })

  // Fetch available raffles
  useEffect(() => {
    fetchAvailableRaffles()
  }, [])

  // Fetch available events/tracks when switching to eventos tab
  useEffect(() => {
    if (activeTab === 'eventos' && eventsWithTracks.length === 0) {
      fetchEventsWithTracks()
    }
  }, [activeTab, eventsWithTracks.length])

  const fetchAvailableRaffles = async () => {
    try {
      const res = await fetch('/api/raffles/ranking')
      if (res.ok) {
        const data: RaffleRankingResponse = await res.json()
        setAvailableRaffles(data.availableRaffles)
      }
    } catch (error) {
      console.error('Error fetching raffles:', error)
    } finally {
      setLoadingRaffles(false)
    }
  }

  const fetchEventsWithTracks = async () => {
    setLoadingTracks(true)
    try {
      const res = await fetch('/api/ranking/tracks')
      if (res.ok) {
        const data: TrackRankingResponse = await res.json()
        setEventsWithTracks(data.events)
      }
    } catch (error) {
      console.error('Error fetching events/tracks:', error)
    } finally {
      setLoadingTracks(false)
    }
  }

  // Raffle functions
  const calculateRaffleRanking = async () => {
    if (selectedRaffleIds.size === 0) return

    setCalculatingRaffles(true)
    try {
      const res = await fetch(`/api/raffles/ranking?raffleIds=${Array.from(selectedRaffleIds).join(',')}`)
      if (res.ok) {
        const data: RaffleRankingResponse = await res.json()
        setRaffleRanking(data.ranking)
      }
    } catch (error) {
      console.error('Error calculating ranking:', error)
    } finally {
      setCalculatingRaffles(false)
    }
  }

  const toggleRaffle = (id: string) => {
    const newSelected = new Set(selectedRaffleIds)
    if (newSelected.has(id)) {
      newSelected.delete(id)
    } else {
      newSelected.add(id)
    }
    setSelectedRaffleIds(newSelected)
    setRaffleRanking([])
  }

  const selectAllRaffles = () => {
    setSelectedRaffleIds(new Set(availableRaffles.map(r => r.id)))
    setRaffleRanking([])
  }

  const deselectAllRaffles = () => {
    setSelectedRaffleIds(new Set())
    setRaffleRanking([])
  }

  // Track functions
  const calculateTrackRanking = async () => {
    if (selectedTrackIds.size === 0) return

    setCalculatingTracks(true)
    try {
      const res = await fetch(`/api/ranking/tracks?trackIds=${Array.from(selectedTrackIds).join(',')}`)
      if (res.ok) {
        const data: TrackRankingResponse = await res.json()
        setTrackRanking(data.ranking)
      }
    } catch (error) {
      console.error('Error calculating track ranking:', error)
    } finally {
      setCalculatingTracks(false)
    }
  }

  const toggleTrack = (id: string) => {
    const newSelected = new Set(selectedTrackIds)
    if (newSelected.has(id)) {
      newSelected.delete(id)
    } else {
      newSelected.add(id)
    }
    setSelectedTrackIds(newSelected)
    setTrackRanking([])
  }

  const toggleEvent = (eventId: string) => {
    const event = eventsWithTracks.find(e => e.id === eventId)
    if (!event) return

    const trackIds = event.tracks.map(t => t.id)
    const allSelected = trackIds.every(id => selectedTrackIds.has(id))

    const newSelected = new Set(selectedTrackIds)
    if (allSelected) {
      trackIds.forEach(id => newSelected.delete(id))
    } else {
      trackIds.forEach(id => newSelected.add(id))
    }
    setSelectedTrackIds(newSelected)
    setTrackRanking([])
  }

  const toggleExpandEvent = (eventId: string) => {
    const newExpanded = new Set(expandedEventIds)
    if (newExpanded.has(eventId)) {
      newExpanded.delete(eventId)
    } else {
      newExpanded.add(eventId)
    }
    setExpandedEventIds(newExpanded)
  }

  const selectAllTracks = () => {
    const allTrackIds = eventsWithTracks.flatMap(e => e.tracks.map(t => t.id))
    setSelectedTrackIds(new Set(allTrackIds))
    setTrackRanking([])
  }

  const deselectAllTracks = () => {
    setSelectedTrackIds(new Set())
    setTrackRanking([])
  }

  // Eligible participants calculations
  const eligibleRaffleParticipants = useMemo(() => {
    if (raffleRanking.length === 0 || selectedRaffleIds.size === 0) return []

    const minRequired = raffleFormData.ruleType === 'all'
      ? selectedRaffleIds.size
      : raffleFormData.minParticipation

    return raffleRanking.filter(entry => entry.participatedIn >= minRequired)
  }, [raffleRanking, selectedRaffleIds.size, raffleFormData.ruleType, raffleFormData.minParticipation])

  const eligibleTrackParticipants = useMemo(() => {
    if (trackRanking.length === 0 || selectedTrackIds.size === 0) return []

    const minRequired = trackFormData.ruleType === 'all'
      ? selectedTrackIds.size
      : trackFormData.minParticipation

    return trackRanking.filter(entry => entry.participatedIn >= minRequired)
  }, [trackRanking, selectedTrackIds.size, trackFormData.ruleType, trackFormData.minParticipation])

  // Create raffle functions
  const createRaffleFromRaffles = async () => {
    if (!raffleFormData.name || !raffleFormData.prize || eligibleRaffleParticipants.length === 0) return

    setCreatingFromRaffles(true)
    try {
      const res = await fetch('/api/raffles/create-from-ranking', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: raffleFormData.name,
          prize: raffleFormData.prize,
          description: raffleFormData.description || null,
          sourceRaffleIds: Array.from(selectedRaffleIds),
          minParticipation: raffleFormData.minParticipation,
          requireAll: raffleFormData.ruleType === 'all'
        })
      })

      if (res.ok) {
        const data = await res.json()
        router.push(`/admin/${data.raffle.id}`)
      } else {
        const error = await res.json()
        alert(error.error || 'Erro ao criar sorteio')
      }
    } catch (error) {
      console.error('Error creating raffle:', error)
      alert('Erro ao criar sorteio')
    } finally {
      setCreatingFromRaffles(false)
    }
  }

  const createRaffleFromTracks = async () => {
    if (!trackFormData.name || !trackFormData.prize || eligibleTrackParticipants.length === 0) return

    setCreatingFromTracks(true)
    try {
      const res = await fetch('/api/ranking/create-raffle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: trackFormData.name,
          prize: trackFormData.prize,
          description: trackFormData.description || null,
          sourceTrackIds: Array.from(selectedTrackIds),
          minParticipation: trackFormData.minParticipation,
          requireAll: trackFormData.ruleType === 'all'
        })
      })

      if (res.ok) {
        const data = await res.json()
        router.push(`/admin/${data.raffle.id}`)
      } else {
        const error = await res.json()
        alert(error.error || 'Erro ao criar sorteio')
      }
    } catch (error) {
      console.error('Error creating raffle:', error)
      alert('Erro ao criar sorteio')
    } finally {
      setCreatingFromTracks(false)
    }
  }

  const getMedalEmoji = (position: number) => {
    if (position === 1) return '🥇'
    if (position === 2) return '🥈'
    if (position === 3) return '🥉'
    return `${position}`
  }

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
  }

  const displayedRaffles = showAllRaffles ? availableRaffles : availableRaffles.slice(0, 5)

  const loading = activeTab === 'sorteios' ? loadingRaffles : loadingTracks

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/admin">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <Trophy className="h-8 w-8 text-yellow-500" />
            Ranking de Participacao
          </h1>
          <p className="text-muted-foreground">
            Analise engajamento e crie sorteios para participantes frequentes
          </p>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as 'sorteios' | 'eventos')}>
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="sorteios" className="flex items-center gap-2">
            <Trophy className="h-4 w-4" />
            Sorteios
          </TabsTrigger>
          <TabsTrigger value="eventos" className="flex items-center gap-2">
            <Layers className="h-4 w-4" />
            Eventos / Trilhas
          </TabsTrigger>
        </TabsList>

        {/* Sorteios Tab */}
        <TabsContent value="sorteios" className="mt-6">
          {availableRaffles.length === 0 ? (
            <Card>
              <CardContent className="pt-8 pb-8 text-center">
                <Trophy className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
                <h2 className="text-xl font-bold mb-2">Nenhum sorteio finalizado</h2>
                <p className="text-muted-foreground">
                  O ranking so pode ser calculado com sorteios que ja foram realizados e tiveram vencedores confirmados.
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Column 1: Raffle Selection */}
              <div className="lg:col-span-1 space-y-4">
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg">Selecione os Sorteios</CardTitle>
                    <CardDescription>
                      Apenas sorteios finalizados (com vencedor)
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex gap-2">
                      <Button variant="outline" size="sm" onClick={selectAllRaffles}>
                        Selecionar Todos
                      </Button>
                      <Button variant="outline" size="sm" onClick={deselectAllRaffles}>
                        Limpar
                      </Button>
                    </div>

                    <div className="space-y-2">
                      {displayedRaffles.map((raffle) => (
                        <div
                          key={raffle.id}
                          onClick={() => toggleRaffle(raffle.id)}
                          className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                            selectedRaffleIds.has(raffle.id)
                              ? 'border-primary bg-primary/5'
                              : 'border-border hover:border-primary/50'
                          }`}
                        >
                          <div className="flex items-start gap-3">
                            <div className={`w-5 h-5 rounded border flex items-center justify-center ${
                              selectedRaffleIds.has(raffle.id)
                                ? 'bg-primary border-primary text-primary-foreground'
                                : 'border-muted-foreground'
                            }`}>
                              {selectedRaffleIds.has(raffle.id) && <Check className="h-3 w-3" />}
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="font-medium truncate">{raffle.name}</p>
                              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                <Users className="h-3 w-3" />
                                <span>{raffle.participantCount} participantes</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>

                    {availableRaffles.length > 5 && (
                      <Button
                        variant="ghost"
                        className="w-full"
                        onClick={() => setShowAllRaffles(!showAllRaffles)}
                      >
                        {showAllRaffles ? (
                          <>
                            <ChevronUp className="h-4 w-4 mr-2" />
                            Mostrar menos
                          </>
                        ) : (
                          <>
                            <ChevronDown className="h-4 w-4 mr-2" />
                            Ver todos ({availableRaffles.length})
                          </>
                        )}
                      </Button>
                    )}

                    <Button
                      className="w-full"
                      onClick={calculateRaffleRanking}
                      disabled={selectedRaffleIds.size === 0 || calculatingRaffles}
                    >
                      {calculatingRaffles ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          Calculando...
                        </>
                      ) : (
                        <>
                          <Trophy className="h-4 w-4 mr-2" />
                          Calcular Ranking ({selectedRaffleIds.size} selecionados)
                        </>
                      )}
                    </Button>
                  </CardContent>
                </Card>
              </div>

              {/* Column 2-3: Ranking Table and Create Form */}
              <div className="lg:col-span-2 space-y-4">
                {raffleRanking.length > 0 ? (
                  <>
                    <Card>
                      <CardHeader>
                        <CardTitle className="text-lg flex items-center gap-2">
                          <Trophy className="h-5 w-5 text-yellow-500" />
                          Ranking ({selectedRaffleIds.size} sorteios)
                        </CardTitle>
                        <CardDescription>
                          {raffleRanking.length} participantes unicos encontrados
                        </CardDescription>
                      </CardHeader>
                      <CardContent>
                        <div className="max-h-[400px] overflow-y-auto">
                          <Table>
                            <TableHeader>
                              <TableRow>
                                <TableHead className="w-[60px]">Pos</TableHead>
                                <TableHead>Nome</TableHead>
                                <TableHead>Email</TableHead>
                                <TableHead className="text-right">Participacao</TableHead>
                              </TableRow>
                            </TableHeader>
                            <TableBody>
                              {raffleRanking.map((entry, index) => (
                                <TableRow
                                  key={entry.email}
                                  className={eligibleRaffleParticipants.includes(entry) ? 'bg-green-500/10' : ''}
                                >
                                  <TableCell className="font-bold text-lg">
                                    {getMedalEmoji(index + 1)}
                                  </TableCell>
                                  <TableCell className="font-medium">{entry.name}</TableCell>
                                  <TableCell className="text-muted-foreground">{entry.email}</TableCell>
                                  <TableCell className="text-right">
                                    <Badge variant={entry.percentage === 100 ? 'default' : 'secondary'}>
                                      {entry.participatedIn} de {entry.totalSelected} ({entry.percentage}%)
                                    </Badge>
                                  </TableCell>
                                </TableRow>
                              ))}
                            </TableBody>
                          </Table>
                        </div>
                      </CardContent>
                    </Card>

                    {/* Create Raffle Form */}
                    <Card>
                      <CardHeader>
                        <CardTitle className="text-lg flex items-center gap-2">
                          <Gift className="h-5 w-5 text-primary" />
                          Criar Sorteio por Engajamento
                        </CardTitle>
                        <CardDescription>
                          Crie um sorteio apenas com participantes que atendem aos criterios
                        </CardDescription>
                      </CardHeader>
                      <CardContent className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div className="space-y-2">
                            <Label htmlFor="raffle-name">Nome do Sorteio *</Label>
                            <Input
                              id="raffle-name"
                              placeholder="Ex: Sorteio VIP - Engajados"
                              value={raffleFormData.name}
                              onChange={(e) => setRaffleFormData({ ...raffleFormData, name: e.target.value })}
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="raffle-prize">Premio *</Label>
                            <Input
                              id="raffle-prize"
                              placeholder="Ex: Vale Presente R$500"
                              value={raffleFormData.prize}
                              onChange={(e) => setRaffleFormData({ ...raffleFormData, prize: e.target.value })}
                            />
                          </div>
                        </div>

                        <div className="space-y-2">
                          <Label htmlFor="raffle-description">Descricao (opcional)</Label>
                          <Input
                            id="raffle-description"
                            placeholder="Ex: Sorteio especial para os participantes mais engajados"
                            value={raffleFormData.description}
                            onChange={(e) => setRaffleFormData({ ...raffleFormData, description: e.target.value })}
                          />
                        </div>

                        <div className="space-y-3">
                          <Label>Regra de Participacao</Label>
                          <div className="space-y-2">
                            <div
                              onClick={() => setRaffleFormData({ ...raffleFormData, ruleType: 'all' })}
                              className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                                raffleFormData.ruleType === 'all'
                                  ? 'border-primary bg-primary/5'
                                  : 'border-border hover:border-primary/50'
                              }`}
                            >
                              <div className="flex items-center gap-3">
                                <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                                  raffleFormData.ruleType === 'all' ? 'border-primary' : 'border-muted-foreground'
                                }`}>
                                  {raffleFormData.ruleType === 'all' && (
                                    <div className="w-2 h-2 rounded-full bg-primary" />
                                  )}
                                </div>
                                <div>
                                  <p className="font-medium">Participou de todos os sorteios</p>
                                  <p className="text-sm text-muted-foreground">
                                    {selectedRaffleIds.size} de {selectedRaffleIds.size} sorteios
                                  </p>
                                </div>
                              </div>
                            </div>

                            <div
                              onClick={() => setRaffleFormData({ ...raffleFormData, ruleType: 'minimum' })}
                              className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                                raffleFormData.ruleType === 'minimum'
                                  ? 'border-primary bg-primary/5'
                                  : 'border-border hover:border-primary/50'
                              }`}
                            >
                              <div className="flex items-center gap-3">
                                <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                                  raffleFormData.ruleType === 'minimum' ? 'border-primary' : 'border-muted-foreground'
                                }`}>
                                  {raffleFormData.ruleType === 'minimum' && (
                                    <div className="w-2 h-2 rounded-full bg-primary" />
                                  )}
                                </div>
                                <div className="flex-1">
                                  <p className="font-medium">Participou de pelo menos</p>
                                  <div className="flex items-center gap-2 mt-1">
                                    <select
                                      value={raffleFormData.minParticipation}
                                      onChange={(e) => setRaffleFormData({
                                        ...raffleFormData,
                                        minParticipation: parseInt(e.target.value)
                                      })}
                                      onClick={(e) => e.stopPropagation()}
                                      className="h-8 px-2 rounded border border-input bg-background text-sm"
                                      disabled={raffleFormData.ruleType !== 'minimum'}
                                    >
                                      {Array.from({ length: selectedRaffleIds.size }, (_, i) => i + 1).map(n => (
                                        <option key={n} value={n}>{n}</option>
                                      ))}
                                    </select>
                                    <span className="text-sm text-muted-foreground">
                                      de {selectedRaffleIds.size} sorteios
                                    </span>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>

                        {/* Preview eligible participants */}
                        <div className="p-4 rounded-lg bg-muted/50 border">
                          <div className="flex items-center justify-between mb-2">
                            <p className="font-medium">Participantes elegiveis:</p>
                            <Badge variant={eligibleRaffleParticipants.length > 0 ? 'default' : 'secondary'}>
                              {eligibleRaffleParticipants.length} pessoas
                            </Badge>
                          </div>
                          {eligibleRaffleParticipants.length > 0 ? (
                            <div className="max-h-[150px] overflow-y-auto space-y-1">
                              {eligibleRaffleParticipants.slice(0, 10).map(p => (
                                <div key={p.email} className="text-sm text-muted-foreground flex items-center gap-2">
                                  <Check className="h-3 w-3 text-green-500" />
                                  <span>{p.name}</span>
                                  <span className="text-xs">({p.email})</span>
                                </div>
                              ))}
                              {eligibleRaffleParticipants.length > 10 && (
                                <p className="text-sm text-muted-foreground">
                                  ... e mais {eligibleRaffleParticipants.length - 10} pessoas
                                </p>
                              )}
                            </div>
                          ) : (
                            <p className="text-sm text-muted-foreground">
                              Nenhum participante atende aos criterios selecionados
                            </p>
                          )}
                        </div>

                        <Button
                          className="w-full"
                          onClick={createRaffleFromRaffles}
                          disabled={creatingFromRaffles || !raffleFormData.name || !raffleFormData.prize || eligibleRaffleParticipants.length === 0}
                        >
                          {creatingFromRaffles ? (
                            <>
                              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                              Criando...
                            </>
                          ) : (
                            <>
                              <Gift className="h-4 w-4 mr-2" />
                              Criar Sorteio com {eligibleRaffleParticipants.length} Participantes
                            </>
                          )}
                        </Button>

                        <p className="text-xs text-muted-foreground text-center">
                          O sorteio sera criado fechado, sem aceitar novas inscricoes
                        </p>
                      </CardContent>
                    </Card>
                  </>
                ) : (
                  <Card>
                    <CardContent className="pt-8 pb-8 text-center">
                      <Trophy className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
                      <h2 className="text-xl font-bold mb-2">Selecione sorteios para ver o ranking</h2>
                      <p className="text-muted-foreground">
                        Escolha os sorteios na coluna ao lado e clique em &quot;Calcular Ranking&quot;
                      </p>
                    </CardContent>
                  </Card>
                )}
              </div>
            </div>
          )}
        </TabsContent>

        {/* Eventos / Trilhas Tab */}
        <TabsContent value="eventos" className="mt-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Column 1: Event/Track Selection */}
            <div className="lg:col-span-1 space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Selecione Eventos / Trilhas</CardTitle>
                  <CardDescription>
                    Clique no evento para expandir e ver as trilhas
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex gap-2">
                      <Button variant="outline" size="sm" onClick={selectAllTracks}>
                        Todas
                      </Button>
                      <Button variant="outline" size="sm" onClick={deselectAllTracks}>
                        Limpar
                      </Button>
                    </div>
                    <Link href="/admin/events">
                      <Button variant="link" size="sm" className="text-primary">
                        Gerenciar Eventos
                      </Button>
                    </Link>
                  </div>

                  {eventsWithTracks.length === 0 ? (
                    <div className="text-center py-8">
                      <Calendar className="h-12 w-12 text-muted-foreground mx-auto mb-2" />
                      <p className="text-sm text-muted-foreground mb-4">
                        Nenhum evento cadastrado
                      </p>
                      <Link href="/admin/events">
                        <Button variant="outline" size="sm">
                          Criar Evento
                        </Button>
                      </Link>
                    </div>
                  ) : (
                    <div className="space-y-2 max-h-[400px] overflow-y-auto">
                      {eventsWithTracks.map((event) => {
                        const trackIds = event.tracks.map(t => t.id)
                        const selectedCount = trackIds.filter(id => selectedTrackIds.has(id)).length
                        const allSelected = trackIds.length > 0 && selectedCount === trackIds.length
                        const someSelected = selectedCount > 0 && !allSelected
                        const isExpanded = expandedEventIds.has(event.id)

                        return (
                          <div key={event.id} className="border rounded-lg overflow-hidden">
                            <div
                              className={`p-3 cursor-pointer transition-colors ${
                                allSelected
                                  ? 'bg-primary/10 border-primary'
                                  : someSelected
                                  ? 'bg-primary/5'
                                  : 'hover:bg-muted/50'
                              }`}
                            >
                              <div className="flex items-center gap-3">
                                <div
                                  onClick={(e) => { e.stopPropagation(); toggleEvent(event.id) }}
                                  className={`w-5 h-5 rounded border flex items-center justify-center ${
                                    allSelected
                                      ? 'bg-primary border-primary text-primary-foreground'
                                      : someSelected
                                      ? 'bg-primary/50 border-primary text-primary-foreground'
                                      : 'border-muted-foreground'
                                  }`}
                                >
                                  {(allSelected || someSelected) && <Check className="h-3 w-3" />}
                                </div>
                                <div
                                  className="flex-1 min-w-0"
                                  onClick={() => toggleExpandEvent(event.id)}
                                >
                                  <p className="font-medium truncate">{event.name}</p>
                                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Calendar className="h-3 w-3" />
                                    <span>{formatDate(event.startDate)}</span>
                                    <span>•</span>
                                    <Layers className="h-3 w-3" />
                                    <span>{event.tracks.length} trilhas</span>
                                  </div>
                                </div>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className="h-6 w-6"
                                  onClick={() => toggleExpandEvent(event.id)}
                                >
                                  {isExpanded ? (
                                    <ChevronUp className="h-4 w-4" />
                                  ) : (
                                    <ChevronDown className="h-4 w-4" />
                                  )}
                                </Button>
                              </div>
                            </div>

                            {isExpanded && event.tracks.length > 0 && (
                              <div className="border-t bg-muted/30 px-3 py-2 space-y-1">
                                {event.tracks.map((track) => (
                                  <div
                                    key={track.id}
                                    onClick={() => toggleTrack(track.id)}
                                    className={`p-2 rounded cursor-pointer transition-colors flex items-center gap-2 ${
                                      selectedTrackIds.has(track.id)
                                        ? 'bg-primary/10'
                                        : 'hover:bg-muted'
                                    }`}
                                  >
                                    <div className={`w-4 h-4 rounded border flex items-center justify-center ${
                                      selectedTrackIds.has(track.id)
                                        ? 'bg-primary border-primary text-primary-foreground'
                                        : 'border-muted-foreground'
                                    }`}>
                                      {selectedTrackIds.has(track.id) && <Check className="h-2 w-2" />}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                      <p className="text-sm truncate">{track.title}</p>
                                      <p className="text-xs text-muted-foreground">
                                        {formatDate(track.day)} • {track.attendanceCount} presencas
                                      </p>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        )
                      })}
                    </div>
                  )}

                  <Button
                    className="w-full"
                    onClick={calculateTrackRanking}
                    disabled={selectedTrackIds.size === 0 || calculatingTracks}
                  >
                    {calculatingTracks ? (
                      <>
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        Calculando...
                      </>
                    ) : (
                      <>
                        <Trophy className="h-4 w-4 mr-2" />
                        Calcular Ranking ({selectedTrackIds.size} trilhas)
                      </>
                    )}
                  </Button>
                </CardContent>
              </Card>
            </div>

            {/* Column 2-3: Track Ranking Table and Create Form */}
            <div className="lg:col-span-2 space-y-4">
              {trackRanking.length > 0 ? (
                <>
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-lg flex items-center gap-2">
                        <Trophy className="h-5 w-5 text-yellow-500" />
                        Ranking ({selectedTrackIds.size} trilhas)
                      </CardTitle>
                      <CardDescription>
                        {trackRanking.length} participantes unicos encontrados
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <div className="max-h-[400px] overflow-y-auto">
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead className="w-[60px]">Pos</TableHead>
                              <TableHead>Nome</TableHead>
                              <TableHead>Email</TableHead>
                              <TableHead className="text-right">Presenca</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {trackRanking.map((entry, index) => (
                              <TableRow
                                key={entry.email}
                                className={eligibleTrackParticipants.includes(entry) ? 'bg-green-500/10' : ''}
                              >
                                <TableCell className="font-bold text-lg">
                                  {getMedalEmoji(index + 1)}
                                </TableCell>
                                <TableCell className="font-medium">{entry.name}</TableCell>
                                <TableCell className="text-muted-foreground">{entry.email}</TableCell>
                                <TableCell className="text-right">
                                  <Badge variant={entry.percentage === 100 ? 'default' : 'secondary'}>
                                    {entry.participatedIn} de {entry.totalSelected} ({entry.percentage}%)
                                  </Badge>
                                </TableCell>
                              </TableRow>
                            ))}
                          </TableBody>
                        </Table>
                      </div>
                    </CardContent>
                  </Card>

                  {/* Create Raffle Form from Tracks */}
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-lg flex items-center gap-2">
                        <Gift className="h-5 w-5 text-primary" />
                        Criar Sorteio por Presenca
                      </CardTitle>
                      <CardDescription>
                        Crie um sorteio apenas com participantes que estiveram presentes
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label htmlFor="track-name">Nome do Sorteio *</Label>
                          <Input
                            id="track-name"
                            placeholder="Ex: Sorteio VIP - Presentes"
                            value={trackFormData.name}
                            onChange={(e) => setTrackFormData({ ...trackFormData, name: e.target.value })}
                          />
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="track-prize">Premio *</Label>
                          <Input
                            id="track-prize"
                            placeholder="Ex: Vale Presente R$500"
                            value={trackFormData.prize}
                            onChange={(e) => setTrackFormData({ ...trackFormData, prize: e.target.value })}
                          />
                        </div>
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="track-description">Descricao (opcional)</Label>
                        <Input
                          id="track-description"
                          placeholder="Ex: Sorteio especial para os participantes mais frequentes"
                          value={trackFormData.description}
                          onChange={(e) => setTrackFormData({ ...trackFormData, description: e.target.value })}
                        />
                      </div>

                      <div className="space-y-3">
                        <Label>Regra de Presenca</Label>
                        <div className="space-y-2">
                          <div
                            onClick={() => setTrackFormData({ ...trackFormData, ruleType: 'all' })}
                            className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                              trackFormData.ruleType === 'all'
                                ? 'border-primary bg-primary/5'
                                : 'border-border hover:border-primary/50'
                            }`}
                          >
                            <div className="flex items-center gap-3">
                              <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                                trackFormData.ruleType === 'all' ? 'border-primary' : 'border-muted-foreground'
                              }`}>
                                {trackFormData.ruleType === 'all' && (
                                  <div className="w-2 h-2 rounded-full bg-primary" />
                                )}
                              </div>
                              <div>
                                <p className="font-medium">Esteve presente em todas as trilhas</p>
                                <p className="text-sm text-muted-foreground">
                                  {selectedTrackIds.size} de {selectedTrackIds.size} trilhas
                                </p>
                              </div>
                            </div>
                          </div>

                          <div
                            onClick={() => setTrackFormData({ ...trackFormData, ruleType: 'minimum' })}
                            className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                              trackFormData.ruleType === 'minimum'
                                ? 'border-primary bg-primary/5'
                                : 'border-border hover:border-primary/50'
                            }`}
                          >
                            <div className="flex items-center gap-3">
                              <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                                trackFormData.ruleType === 'minimum' ? 'border-primary' : 'border-muted-foreground'
                              }`}>
                                {trackFormData.ruleType === 'minimum' && (
                                  <div className="w-2 h-2 rounded-full bg-primary" />
                                )}
                              </div>
                              <div className="flex-1">
                                <p className="font-medium">Esteve presente em pelo menos</p>
                                <div className="flex items-center gap-2 mt-1">
                                  <select
                                    value={trackFormData.minParticipation}
                                    onChange={(e) => setTrackFormData({
                                      ...trackFormData,
                                      minParticipation: parseInt(e.target.value)
                                    })}
                                    onClick={(e) => e.stopPropagation()}
                                    className="h-8 px-2 rounded border border-input bg-background text-sm"
                                    disabled={trackFormData.ruleType !== 'minimum'}
                                  >
                                    {Array.from({ length: selectedTrackIds.size }, (_, i) => i + 1).map(n => (
                                      <option key={n} value={n}>{n}</option>
                                    ))}
                                  </select>
                                  <span className="text-sm text-muted-foreground">
                                    de {selectedTrackIds.size} trilhas
                                  </span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Preview eligible participants */}
                      <div className="p-4 rounded-lg bg-muted/50 border">
                        <div className="flex items-center justify-between mb-2">
                          <p className="font-medium">Participantes elegiveis:</p>
                          <Badge variant={eligibleTrackParticipants.length > 0 ? 'default' : 'secondary'}>
                            {eligibleTrackParticipants.length} pessoas
                          </Badge>
                        </div>
                        {eligibleTrackParticipants.length > 0 ? (
                          <div className="max-h-[150px] overflow-y-auto space-y-1">
                            {eligibleTrackParticipants.slice(0, 10).map(p => (
                              <div key={p.email} className="text-sm text-muted-foreground flex items-center gap-2">
                                <Check className="h-3 w-3 text-green-500" />
                                <span>{p.name}</span>
                                <span className="text-xs">({p.email})</span>
                              </div>
                            ))}
                            {eligibleTrackParticipants.length > 10 && (
                              <p className="text-sm text-muted-foreground">
                                ... e mais {eligibleTrackParticipants.length - 10} pessoas
                              </p>
                            )}
                          </div>
                        ) : (
                          <p className="text-sm text-muted-foreground">
                            Nenhum participante atende aos criterios selecionados
                          </p>
                        )}
                      </div>

                      <Button
                        className="w-full"
                        onClick={createRaffleFromTracks}
                        disabled={creatingFromTracks || !trackFormData.name || !trackFormData.prize || eligibleTrackParticipants.length === 0}
                      >
                        {creatingFromTracks ? (
                          <>
                            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                            Criando...
                          </>
                        ) : (
                          <>
                            <Gift className="h-4 w-4 mr-2" />
                            Criar Sorteio com {eligibleTrackParticipants.length} Participantes
                          </>
                        )}
                      </Button>

                      <p className="text-xs text-muted-foreground text-center">
                        O sorteio sera criado fechado, sem aceitar novas inscricoes
                      </p>
                    </CardContent>
                  </Card>
                </>
              ) : (
                <Card>
                  <CardContent className="pt-8 pb-8 text-center">
                    <Layers className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
                    <h2 className="text-xl font-bold mb-2">
                      {eventsWithTracks.length === 0
                        ? 'Crie um evento para comecar'
                        : 'Selecione trilhas para ver o ranking'}
                    </h2>
                    <p className="text-muted-foreground">
                      {eventsWithTracks.length === 0
                        ? 'Acesse "Gerenciar Eventos" para criar eventos e trilhas'
                        : 'Escolha as trilhas na coluna ao lado e clique em "Calcular Ranking"'}
                    </p>
                  </CardContent>
                </Card>
              )}
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
