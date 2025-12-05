'use client'

import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, Trophy, Users, Gift, Loader2, Check, ChevronDown, ChevronUp } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
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

interface RankingEntry {
  email: string
  name: string
  participatedIn: number
  totalSelected: number
  percentage: number
  raffleIds: string[]
}

interface RankingResponse {
  availableRaffles: AvailableRaffle[]
  selectedRaffles: { id: string; name: string; participantCount: number }[]
  ranking: RankingEntry[]
}

export default function RankingPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [calculating, setCalculating] = useState(false)
  const [creating, setCreating] = useState(false)
  const [availableRaffles, setAvailableRaffles] = useState<AvailableRaffle[]>([])
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [ranking, setRanking] = useState<RankingEntry[]>([])
  const [showAllRaffles, setShowAllRaffles] = useState(false)

  // Formulário para criar sorteio
  const [formData, setFormData] = useState({
    name: '',
    prize: '',
    description: '',
    ruleType: 'minimum' as 'all' | 'minimum',
    minParticipation: 1
  })

  // Carregar sorteios disponíveis
  useEffect(() => {
    fetchAvailableRaffles()
  }, [])

  const fetchAvailableRaffles = async () => {
    try {
      const res = await fetch('/api/raffles/ranking')
      if (res.ok) {
        const data: RankingResponse = await res.json()
        setAvailableRaffles(data.availableRaffles)
      }
    } catch (error) {
      console.error('Error fetching raffles:', error)
    } finally {
      setLoading(false)
    }
  }

  const calculateRanking = async () => {
    if (selectedIds.size === 0) return

    setCalculating(true)
    try {
      const res = await fetch(`/api/raffles/ranking?raffleIds=${Array.from(selectedIds).join(',')}`)
      if (res.ok) {
        const data: RankingResponse = await res.json()
        setRanking(data.ranking)
      }
    } catch (error) {
      console.error('Error calculating ranking:', error)
    } finally {
      setCalculating(false)
    }
  }

  const toggleRaffle = (id: string) => {
    const newSelected = new Set(selectedIds)
    if (newSelected.has(id)) {
      newSelected.delete(id)
    } else {
      newSelected.add(id)
    }
    setSelectedIds(newSelected)
    // Limpar ranking ao mudar seleção
    setRanking([])
  }

  const selectAll = () => {
    setSelectedIds(new Set(availableRaffles.map(r => r.id)))
    setRanking([])
  }

  const deselectAll = () => {
    setSelectedIds(new Set())
    setRanking([])
  }

  // Calcular participantes elegíveis baseado nas regras
  const eligibleParticipants = useMemo(() => {
    if (ranking.length === 0 || selectedIds.size === 0) return []

    const minRequired = formData.ruleType === 'all'
      ? selectedIds.size
      : formData.minParticipation

    return ranking.filter(entry => entry.participatedIn >= minRequired)
  }, [ranking, selectedIds.size, formData.ruleType, formData.minParticipation])

  const createRaffle = async () => {
    if (!formData.name || !formData.prize || eligibleParticipants.length === 0) return

    setCreating(true)
    try {
      const res = await fetch('/api/raffles/create-from-ranking', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.name,
          prize: formData.prize,
          description: formData.description || null,
          sourceRaffleIds: Array.from(selectedIds),
          minParticipation: formData.minParticipation,
          requireAll: formData.ruleType === 'all'
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
      setCreating(false)
    }
  }

  const getMedalEmoji = (position: number) => {
    if (position === 1) return '🥇'
    if (position === 2) return '🥈'
    if (position === 3) return '🥉'
    return `${position}`
  }

  const displayedRaffles = showAllRaffles ? availableRaffles : availableRaffles.slice(0, 5)

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
            Ranking de Participação
          </h1>
          <p className="text-muted-foreground">
            Analise engajamento e crie sorteios para participantes frequentes
          </p>
        </div>
      </div>

      {availableRaffles.length === 0 ? (
        <Card>
          <CardContent className="pt-8 pb-8 text-center">
            <Trophy className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h2 className="text-xl font-bold mb-2">Nenhum sorteio finalizado</h2>
            <p className="text-muted-foreground">
              O ranking só pode ser calculado com sorteios que já foram realizados e tiveram vencedores confirmados.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Coluna 1: Seleção de Sorteios */}
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
                  <Button variant="outline" size="sm" onClick={selectAll}>
                    Selecionar Todos
                  </Button>
                  <Button variant="outline" size="sm" onClick={deselectAll}>
                    Limpar
                  </Button>
                </div>

                <div className="space-y-2">
                  {displayedRaffles.map((raffle) => (
                    <div
                      key={raffle.id}
                      onClick={() => toggleRaffle(raffle.id)}
                      className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                        selectedIds.has(raffle.id)
                          ? 'border-primary bg-primary/5'
                          : 'border-border hover:border-primary/50'
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className={`w-5 h-5 rounded border flex items-center justify-center ${
                          selectedIds.has(raffle.id)
                            ? 'bg-primary border-primary text-primary-foreground'
                            : 'border-muted-foreground'
                        }`}>
                          {selectedIds.has(raffle.id) && <Check className="h-3 w-3" />}
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
                  onClick={calculateRanking}
                  disabled={selectedIds.size === 0 || calculating}
                >
                  {calculating ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Calculando...
                    </>
                  ) : (
                    <>
                      <Trophy className="h-4 w-4 mr-2" />
                      Calcular Ranking ({selectedIds.size} selecionados)
                    </>
                  )}
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Coluna 2: Tabela de Ranking */}
          <div className="lg:col-span-2 space-y-4">
            {ranking.length > 0 ? (
              <>
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                      <Trophy className="h-5 w-5 text-yellow-500" />
                      Ranking ({selectedIds.size} sorteios)
                    </CardTitle>
                    <CardDescription>
                      {ranking.length} participantes únicos encontrados
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
                            <TableHead className="text-right">Participação</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {ranking.map((entry, index) => (
                            <TableRow
                              key={entry.email}
                              className={eligibleParticipants.includes(entry) ? 'bg-green-500/10' : ''}
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

                {/* Formulário para criar sorteio */}
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                      <Gift className="h-5 w-5 text-primary" />
                      Criar Sorteio por Engajamento
                    </CardTitle>
                    <CardDescription>
                      Crie um sorteio apenas com participantes que atendem aos critérios
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="name">Nome do Sorteio *</Label>
                        <Input
                          id="name"
                          placeholder="Ex: Sorteio VIP - Engajados"
                          value={formData.name}
                          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="prize">Prêmio *</Label>
                        <Input
                          id="prize"
                          placeholder="Ex: Vale Presente R$500"
                          value={formData.prize}
                          onChange={(e) => setFormData({ ...formData, prize: e.target.value })}
                        />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="description">Descrição (opcional)</Label>
                      <Input
                        id="description"
                        placeholder="Ex: Sorteio especial para os participantes mais engajados"
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      />
                    </div>

                    <div className="space-y-3">
                      <Label>Regra de Participação</Label>
                      <div className="space-y-2">
                        <div
                          onClick={() => setFormData({ ...formData, ruleType: 'all' })}
                          className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                            formData.ruleType === 'all'
                              ? 'border-primary bg-primary/5'
                              : 'border-border hover:border-primary/50'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                              formData.ruleType === 'all' ? 'border-primary' : 'border-muted-foreground'
                            }`}>
                              {formData.ruleType === 'all' && (
                                <div className="w-2 h-2 rounded-full bg-primary" />
                              )}
                            </div>
                            <div>
                              <p className="font-medium">Participou de todos os sorteios</p>
                              <p className="text-sm text-muted-foreground">
                                {selectedIds.size} de {selectedIds.size} sorteios
                              </p>
                            </div>
                          </div>
                        </div>

                        <div
                          onClick={() => setFormData({ ...formData, ruleType: 'minimum' })}
                          className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                            formData.ruleType === 'minimum'
                              ? 'border-primary bg-primary/5'
                              : 'border-border hover:border-primary/50'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                              formData.ruleType === 'minimum' ? 'border-primary' : 'border-muted-foreground'
                            }`}>
                              {formData.ruleType === 'minimum' && (
                                <div className="w-2 h-2 rounded-full bg-primary" />
                              )}
                            </div>
                            <div className="flex-1">
                              <p className="font-medium">Participou de pelo menos</p>
                              <div className="flex items-center gap-2 mt-1">
                                <select
                                  value={formData.minParticipation}
                                  onChange={(e) => setFormData({
                                    ...formData,
                                    minParticipation: parseInt(e.target.value)
                                  })}
                                  onClick={(e) => e.stopPropagation()}
                                  className="h-8 px-2 rounded border border-input bg-background text-sm"
                                  disabled={formData.ruleType !== 'minimum'}
                                >
                                  {Array.from({ length: selectedIds.size }, (_, i) => i + 1).map(n => (
                                    <option key={n} value={n}>{n}</option>
                                  ))}
                                </select>
                                <span className="text-sm text-muted-foreground">
                                  de {selectedIds.size} sorteios
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Preview de participantes elegíveis */}
                    <div className="p-4 rounded-lg bg-muted/50 border">
                      <div className="flex items-center justify-between mb-2">
                        <p className="font-medium">Participantes elegíveis:</p>
                        <Badge variant={eligibleParticipants.length > 0 ? 'default' : 'secondary'}>
                          {eligibleParticipants.length} pessoas
                        </Badge>
                      </div>
                      {eligibleParticipants.length > 0 ? (
                        <div className="max-h-[150px] overflow-y-auto space-y-1">
                          {eligibleParticipants.slice(0, 10).map(p => (
                            <div key={p.email} className="text-sm text-muted-foreground flex items-center gap-2">
                              <Check className="h-3 w-3 text-green-500" />
                              <span>{p.name}</span>
                              <span className="text-xs">({p.email})</span>
                            </div>
                          ))}
                          {eligibleParticipants.length > 10 && (
                            <p className="text-sm text-muted-foreground">
                              ... e mais {eligibleParticipants.length - 10} pessoas
                            </p>
                          )}
                        </div>
                      ) : (
                        <p className="text-sm text-muted-foreground">
                          Nenhum participante atende aos critérios selecionados
                        </p>
                      )}
                    </div>

                    <Button
                      className="w-full"
                      onClick={createRaffle}
                      disabled={creating || !formData.name || !formData.prize || eligibleParticipants.length === 0}
                    >
                      {creating ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          Criando...
                        </>
                      ) : (
                        <>
                          <Gift className="h-4 w-4 mr-2" />
                          Criar Sorteio com {eligibleParticipants.length} Participantes
                        </>
                      )}
                    </Button>

                    <p className="text-xs text-muted-foreground text-center">
                      O sorteio será criado fechado, sem aceitar novas inscrições
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
                    Escolha os sorteios na coluna ao lado e clique em "Calcular Ranking"
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
