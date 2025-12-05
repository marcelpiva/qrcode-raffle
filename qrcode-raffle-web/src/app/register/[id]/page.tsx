'use client'

import { useEffect, useState, use } from 'react'
import Image from 'next/image'
import { CheckCircle, XCircle, Users, MonitorPlay, KeyRound } from 'lucide-react'
import { CountdownTimer } from '@/components/countdown-timer'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

interface RaffleInfo {
  id: string
  name: string
  description: string | null
  prize: string
  status: string
  allowedDomain: string | null
  participantCount: number
  endsAt: string | null
  requireConfirmation: boolean
}

export default function RegisterPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const [raffle, setRaffle] = useState<RaffleInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [status, setStatus] = useState<'form' | 'success' | 'error'>('form')
  const [errorMessage, setErrorMessage] = useState('')
  const [formData, setFormData] = useState({ name: '', email: '', pin: '' })
  const [savedPin, setSavedPin] = useState('')

  useEffect(() => {
    fetchRaffle()
  }, [id])

  const fetchRaffle = async () => {
    try {
      const res = await fetch(`/api/register/${id}`)
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
      const res = await fetch(`/api/register/${id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })

      if (res.ok) {
        if (formData.pin) {
          setSavedPin(formData.pin)
        }
        setStatus('success')
      } else {
        const data = await res.json()
        setErrorMessage(data.error || 'Erro ao registrar')
        setStatus('error')
      }
    } catch (error) {
      setErrorMessage('Erro de conexão')
      setStatus('error')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!raffle) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <XCircle className="h-16 w-16 text-destructive mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Sorteio não encontrado</h2>
            <p className="text-muted-foreground">Este link pode estar inválido ou expirado.</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (raffle.status !== 'active') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
        <Card className="max-w-md w-full text-center">
          <CardContent className="pt-8 pb-8">
            <XCircle className="h-16 w-16 text-yellow-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Inscrições Encerradas</h2>
            <p className="text-muted-foreground">Este sorteio não está mais aceitando inscrições.</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
      <AnimatePresence mode="wait">
        {status === 'success' ? (
          <motion.div
            key="success"
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.8, opacity: 0 }}
            className="max-w-md w-full"
          >
            <Card className="text-center border-green-500/50">
              <CardContent className="pt-8 pb-8">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
                >
                  <CheckCircle className="h-20 w-20 text-green-500 mx-auto mb-4" />
                </motion.div>
                <motion.h2
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.3 }}
                  className="text-2xl font-bold mb-2"
                >
                  Inscrição Confirmada!
                </motion.h2>
                <motion.p
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.4 }}
                  className="text-muted-foreground"
                >
                  Você está participando do sorteio. Boa sorte!
                </motion.p>

                {/* PIN Reminder - Highlighted */}
                {savedPin && (
                  <motion.div
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ delay: 0.45 }}
                    className="mt-6 p-4 rounded-lg bg-yellow-500/20 border-2 border-yellow-500/50"
                  >
                    <div className="flex items-center justify-center gap-2 mb-2">
                      <KeyRound className="h-5 w-5 text-yellow-600" />
                      <p className="text-sm font-bold text-yellow-600">Seu Código de Confirmação</p>
                    </div>
                    <p className="text-3xl font-mono font-bold tracking-widest text-yellow-700">{savedPin}</p>
                    <p className="text-xs text-yellow-600 mt-2">
                      ⚠️ Guarde este código! Você precisará dele para confirmar sua presença caso seja sorteado.
                    </p>
                  </motion.div>
                )}

                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  className="mt-6 p-4 rounded-lg bg-primary/5 border border-primary/20"
                >
                  <p className="text-sm text-muted-foreground">Prêmio</p>
                  <p className="font-semibold text-primary">{raffle.prize}</p>
                </motion.div>
                <motion.div
                  initial={{ y: 20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.6 }}
                  className="mt-6"
                >
                  <Link href={`/display/${raffle.id}`}>
                    <Button variant="outline" className="w-full gap-2">
                      <MonitorPlay className="h-4 w-4" />
                      Acompanhar Sorteio ao Vivo
                    </Button>
                  </Link>
                </motion.div>
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
                <h2 className="text-2xl font-bold mb-2">Ops!</h2>
                <p className="text-muted-foreground mb-4">{errorMessage}</p>
                <Button onClick={() => setStatus('form')} variant="outline">
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
                {raffle.description && (
                  <CardDescription>{raffle.description}</CardDescription>
                )}
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="p-4 rounded-lg bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/20 text-center">
                  <p className="text-sm text-muted-foreground">Premio</p>
                  <p className="text-xl font-bold text-primary">{raffle.prize}</p>
                </div>

                <div className="flex items-center justify-center gap-2 text-sm text-muted-foreground">
                  <Users className="h-4 w-4" />
                  <span>{raffle.participantCount} participantes inscritos</span>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Seu Nome</Label>
                    <Input
                      id="name"
                      placeholder="Digite seu nome completo"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      required
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email">Seu Email</Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder={raffle.allowedDomain ? `seu@${raffle.allowedDomain}` : 'seu@email.com'}
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      required
                    />
                    {raffle.allowedDomain && (
                      <p className="text-xs text-muted-foreground">
                        Apenas e-mails @{raffle.allowedDomain} podem participar
                      </p>
                    )}
                  </div>

                  {raffle.requireConfirmation && (
                    <div className="space-y-2 p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/30">
                      <Label htmlFor="pin" className="flex items-center gap-2 text-yellow-700">
                        <KeyRound className="h-4 w-4" />
                        Código de Confirmação (5 dígitos)
                      </Label>
                      <Input
                        id="pin"
                        type="text"
                        inputMode="numeric"
                        pattern="\d{5}"
                        maxLength={5}
                        placeholder="00000"
                        value={formData.pin}
                        onChange={(e) => {
                          const value = e.target.value.replace(/\D/g, '').slice(0, 5)
                          setFormData({ ...formData, pin: value })
                        }}
                        className="text-center text-2xl tracking-widest font-mono border-yellow-500/50 focus:border-yellow-500"
                        required
                      />
                      <p className="text-xs text-yellow-700">
                        ⚠️ Crie um código de 5 dígitos. <strong>Guarde-o!</strong> Você precisará dele para confirmar sua presença caso seja sorteado.
                      </p>
                    </div>
                  )}

                  {/* Countdown Timer */}
                  {raffle.endsAt && (
                    <div className="p-3 rounded-lg bg-yellow-500/10 border border-yellow-500/30 text-center">
                      <p className="text-xs text-yellow-600 mb-1">Tempo restante para se inscrever:</p>
                      <CountdownTimer
                        endsAt={raffle.endsAt}
                        onExpire={() => setRaffle(prev => prev ? {...prev, status: 'closed'} : null)}
                        size="sm"
                      />
                    </div>
                  )}

                  <Button
                    type="submit"
                    className="w-full bg-gradient-to-r from-primary to-secondary hover:opacity-90"
                    disabled={submitting || !formData.name || !formData.email || (raffle.requireConfirmation && formData.pin.length !== 5)}
                  >
                    {submitting ? 'Inscrevendo...' : 'Participar do Sorteio'}
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
