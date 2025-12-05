'use client'

import { useEffect, useState, use } from 'react'
import { CheckCircle, XCircle, KeyRound, Trophy, Loader2 } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import Image from 'next/image'
import confetti from 'canvas-confetti'

interface RaffleInfo {
  id: string
  name: string
  prize: string
  status: string
  requireConfirmation: boolean
  winner?: { name: string } | null
}

export default function ConfirmPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const [raffle, setRaffle] = useState<RaffleInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [pin, setPin] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [status, setStatus] = useState<'form' | 'success' | 'error'>('form')
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    fetchRaffle()
  }, [id])

  const fetchRaffle = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}`)
      if (res.ok) {
        const data = await res.json()
        setRaffle(data)
      }
    } catch (error) {
      console.error('Error fetching raffle:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setErrorMessage('')

    try {
      const res = await fetch(`/api/raffles/${id}/confirm-pin`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin })
      })

      if (res.ok) {
        setStatus('success')
        // Fire confetti
        confetti({
          particleCount: 100,
          spread: 70,
          origin: { y: 0.6 },
          colors: ['#a855f7', '#ec4899', '#8b5cf6', '#fbbf24', '#22c55e']
        })
      } else {
        const data = await res.json()
        setErrorMessage(data.error || 'Código incorreto')
        setStatus('error')
      }
    } catch (error) {
      setErrorMessage('Erro de conexão')
      setStatus('error')
    } finally {
      setSubmitting(false)
    }
  }

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background to-primary/5">
        <Loader2 className="h-12 w-12 animate-spin text-primary" />
      </div>
    )
  }

  // Raffle not found
  if (!raffle) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <XCircle className="h-16 w-16 text-destructive mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Sorteio não encontrado</h2>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Raffle doesn't require confirmation
  if (!raffle.requireConfirmation) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <h2 className="text-2xl font-bold mb-2">Confirmação não necessária</h2>
            <p className="text-muted-foreground">Este sorteio não requer confirmação por código.</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  // No winner yet
  if (!raffle.winner) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <h2 className="text-2xl font-bold mb-2">Aguardando sorteio</h2>
            <p className="text-muted-foreground">O sorteio ainda não foi realizado.</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Already finalized
  if (raffle.status === 'drawn') {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <Trophy className="h-16 w-16 text-yellow-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Sorteio Finalizado</h2>
            <p className="text-muted-foreground">O ganhador já foi confirmado.</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-background to-primary/5">
      <AnimatePresence mode="wait">
        {status === 'success' ? (
          <motion.div
            key="success"
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="max-w-md w-full"
          >
            <Card className="text-center border-green-500/50">
              <CardContent className="pt-8 pb-8">
                <CheckCircle className="h-20 w-20 text-green-500 mx-auto mb-4" />
                <h2 className="text-2xl font-bold mb-2">Presença Confirmada!</h2>
                <p className="text-muted-foreground mb-4">
                  Parabéns! Você ganhou:
                </p>
                <div className="p-4 rounded-lg bg-primary/10 border border-primary/30">
                  <Trophy className="h-8 w-8 text-yellow-500 mx-auto mb-2" />
                  <p className="text-xl font-bold text-primary">{raffle.prize}</p>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ) : status === 'error' ? (
          <motion.div
            key="error"
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="max-w-md w-full"
          >
            <Card className="text-center border-destructive/50">
              <CardContent className="pt-8 pb-8">
                <XCircle className="h-16 w-16 text-destructive mx-auto mb-4" />
                <h2 className="text-2xl font-bold mb-2">Código Incorreto</h2>
                <p className="text-muted-foreground mb-4">{errorMessage}</p>
                <Button onClick={() => { setStatus('form'); setPin(''); }} variant="outline">
                  Tentar Novamente
                </Button>
              </CardContent>
            </Card>
          </motion.div>
        ) : (
          <motion.div
            key="form"
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="max-w-md w-full"
          >
            <Card>
              <CardHeader className="text-center">
                <div className="flex justify-center mb-4">
                  <Image
                    src="/nava-icon.jpg"
                    alt="Nava Logo"
                    width={64}
                    height={64}
                    className="rounded-2xl shadow-lg"
                  />
                </div>
                <CardTitle className="text-2xl">{raffle.name}</CardTitle>
                <CardDescription>
                  Confirme sua presença como ganhador
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="p-4 rounded-lg bg-gradient-to-r from-yellow-500/10 to-orange-500/10 border border-yellow-500/30 text-center">
                  <Trophy className="h-8 w-8 text-yellow-500 mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">Prêmio</p>
                  <p className="text-xl font-bold text-primary">{raffle.prize}</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="pin" className="flex items-center gap-2">
                      <KeyRound className="h-4 w-4" />
                      Seu Código de 5 Dígitos
                    </Label>
                    <Input
                      id="pin"
                      type="text"
                      inputMode="numeric"
                      pattern="\d{5}"
                      maxLength={5}
                      placeholder="00000"
                      value={pin}
                      onChange={(e) => {
                        const value = e.target.value.replace(/\D/g, '').slice(0, 5)
                        setPin(value)
                      }}
                      className="text-center text-2xl tracking-widest"
                      required
                    />
                    <p className="text-xs text-muted-foreground text-center">
                      Digite o código que você criou ao se inscrever
                    </p>
                  </div>

                  <Button
                    type="submit"
                    className="w-full bg-gradient-to-r from-primary to-secondary"
                    disabled={submitting || pin.length !== 5}
                  >
                    {submitting ? (
                      <>
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        Verificando...
                      </>
                    ) : (
                      'Confirmar Presença'
                    )}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
