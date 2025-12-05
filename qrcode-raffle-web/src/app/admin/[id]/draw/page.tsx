'use client'

import { useEffect, useState, use } from 'react'
import Link from 'next/link'
import { ArrowLeft, Shuffle, Users, Trophy } from 'lucide-react'
import { motion } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { SlotMachine } from '@/components/slot-machine'
import { WinnerCelebration } from '@/components/winner-celebration'

interface Participant {
  id: string
  name: string
  email: string
}

interface Raffle {
  id: string
  name: string
  prize: string
  status: string
  participants: Participant[]
  winner?: Participant | null
}

export default function DrawPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const [raffle, setRaffle] = useState<Raffle | null>(null)
  const [loading, setLoading] = useState(true)
  const [isSpinning, setIsSpinning] = useState(false)
  const [winner, setWinner] = useState<Participant | null>(null)
  const [showCelebration, setShowCelebration] = useState(false)

  useEffect(() => {
    fetchRaffle()
  }, [id])

  const fetchRaffle = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}`)
      const data = await res.json()
      setRaffle(data)
      if (data.winner) {
        setWinner(data.winner)
        setShowCelebration(true)
      }
    } catch (error) {
      console.error('Error fetching raffle:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDraw = async () => {
    if (!raffle || raffle.participants.length === 0) return

    setIsSpinning(true)

    try {
      const res = await fetch(`/api/raffles/${id}/draw`, {
        method: 'POST'
      })
      const data = await res.json()

      if (res.ok) {
        setWinner(data.winner)
        // The slot machine will call onSpinComplete which triggers celebration
      }
    } catch (error) {
      console.error('Error drawing winner:', error)
      setIsSpinning(false)
    }
  }

  const handleSpinComplete = () => {
    setIsSpinning(false)
    setTimeout(() => {
      setShowCelebration(true)
    }, 500)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!raffle) {
    return (
      <div className="text-center py-16">
        <h2 className="text-2xl font-bold mb-2">Sorteio nao encontrado</h2>
        <Link href="/admin">
          <Button>Voltar ao Dashboard</Button>
        </Link>
      </div>
    )
  }

  if (raffle.participants.length === 0) {
    return (
      <div className="max-w-2xl mx-auto text-center py-16">
        <Card>
          <CardContent className="py-12">
            <Users className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Sem participantes</h2>
            <p className="text-muted-foreground mb-6">
              Este sorteio ainda nao tem participantes inscritos.
            </p>
            <Link href={`/admin/${id}`}>
              <Button>Voltar aos Detalhes</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href={`/admin/${id}`}>
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-3xl font-bold">{raffle.name}</h1>
          <p className="text-muted-foreground">Premio: {raffle.prize}</p>
        </div>
      </div>

      {/* Stats */}
      <div className="flex justify-center gap-6">
        <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary">
          <Users className="h-4 w-4" />
          <span className="font-semibold">{raffle.participants.length} participantes</span>
        </div>
        {winner && (
          <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-accent/10 text-accent">
            <Trophy className="h-4 w-4" />
            <span className="font-semibold">Sorteado!</span>
          </div>
        )}
      </div>

      {/* Main Content */}
      {showCelebration && winner ? (
        <WinnerCelebration winner={winner} prize={raffle.prize} />
      ) : (
        <div className="space-y-8">
          {/* Slot Machine */}
          <Card className="overflow-visible">
            <CardHeader className="text-center">
              <CardTitle className="text-xl">
                {isSpinning ? 'Sorteando...' : 'Pronto para sortear!'}
              </CardTitle>
            </CardHeader>
            <CardContent className="py-8">
              <SlotMachine
                names={raffle.participants.map(p => p.name)}
                winner={winner?.name || ''}
                isSpinning={isSpinning}
                onSpinComplete={handleSpinComplete}
              />
            </CardContent>
          </Card>

          {/* Draw Button - show when no winner or when winner is pending confirmation */}
          {(!winner || (raffle.status !== 'drawn')) && (
            <motion.div
              initial={{ scale: 1 }}
              animate={isSpinning ? { scale: [1, 1.02, 1] } : {}}
              transition={{ repeat: Infinity, duration: 0.5 }}
              className="flex justify-center"
            >
              <Button
                size="lg"
                onClick={handleDraw}
                disabled={isSpinning}
                className="px-12 py-6 text-xl font-bold bg-gradient-to-r from-primary via-accent to-secondary hover:opacity-90 transition-all shadow-lg hover:shadow-xl disabled:opacity-50"
              >
                {isSpinning ? (
                  <>
                    <div className="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-3" />
                    Sorteando...
                  </>
                ) : (
                  <>
                    <Shuffle className="h-6 w-6 mr-3" />
                    {winner ? 'SORTEAR NOVAMENTE' : 'SORTEAR AGORA'}
                  </>
                )}
              </Button>
            </motion.div>
          )}
        </div>
      )}

      {/* Back Button */}
      {showCelebration && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 2 }}
          className="flex flex-col items-center gap-4"
        >
          <p className="text-muted-foreground text-center">
            Agora confirme se o ganhador esta presente ou faca um novo sorteio
          </p>
          <div className="flex gap-4">
            <Link href={`/admin/${id}`}>
              <Button size="lg" className="bg-gradient-to-r from-primary to-secondary">
                Confirmar ou Sortear Novamente
              </Button>
            </Link>
          </div>
        </motion.div>
      )}
    </div>
  )
}
