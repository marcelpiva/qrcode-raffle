'use client'

import { useEffect, useState, use, useRef, useCallback } from 'react'
import Image from 'next/image'
import { Trophy, Users, Sparkles, PartyPopper, Gift, Star, KeyRound } from 'lucide-react'
import { CountdownTimer } from '@/components/countdown-timer'
import { motion, AnimatePresence } from 'framer-motion'
import { QRCodeSVG } from 'qrcode.react'
import confetti from 'canvas-confetti'

interface Participant {
  id: string
  name: string
  email?: string
  createdAt: string
}

interface DrawHistoryItem {
  id: string
  createdAt: string
  wasPresent: boolean
}

interface Raffle {
  id: string
  name: string
  description: string | null
  prize: string
  status: string
  winner?: { id: string; name: string; email: string } | null
  _count: { participants: number }
  endsAt?: string | null
  requireConfirmation?: boolean
  confirmationTimeoutMinutes?: number | null
  drawHistory?: DrawHistoryItem[]
}

type DrawPhase = 'idle' | 'spinning' | 'celebration'

// Calcula o status efetivo considerando o timeout
function getEffectiveStatus(raffle: Raffle): string {
  if (raffle.status === 'drawn') return 'drawn'
  if (raffle.status === 'closed') return 'closed'
  // Se active mas endsAt expirou, considerar como closed
  if (raffle.status === 'active' && raffle.endsAt) {
    const now = new Date()
    const endsAt = new Date(raffle.endsAt)
    if (now > endsAt) return 'closed'
  }
  return raffle.status
}

export default function DisplayPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const [raffle, setRaffle] = useState<Raffle | null>(null)
  const [participants, setParticipants] = useState<Participant[]>([])
  const [latestParticipant, setLatestParticipant] = useState<Participant | null>(null)
  const [loading, setLoading] = useState(true)
  const [origin, setOrigin] = useState('')
  const lastNotifiedIdRef = useRef<string | null>(null)
  const hadWinnerRef = useRef<boolean>(false)
  const isFirstLoadRef = useRef<boolean>(true)
  const [drawPhase, setDrawPhase] = useState<DrawPhase>('idle')
  const [detectedWinner, setDetectedWinner] = useState<{ name: string; email: string } | null>(null)

  // Slot machine state
  const [spinningNames, setSpinningNames] = useState<string[]>([])
  const [currentSpinIndex, setCurrentSpinIndex] = useState(0)
  const spinIntervalRef = useRef<NodeJS.Timeout | null>(null)

  // Timeout countdown state
  const [timeoutRemaining, setTimeoutRemaining] = useState<number | null>(null)
  const autoDrawingRef = useRef(false)
  const previousWinnerIdRef = useRef<string | null>(null)

  // Fire confetti
  const fireConfetti = useCallback(() => {
    const duration = 8000
    const animationEnd = Date.now() + duration
    const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 1000 }

    function randomInRange(min: number, max: number) {
      return Math.random() * (max - min) + min
    }

    const interval = setInterval(function() {
      const timeLeft = animationEnd - Date.now()

      if (timeLeft <= 0) {
        return clearInterval(interval)
      }

      const particleCount = 50 * (timeLeft / duration)

      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 },
        colors: ['#a855f7', '#ec4899', '#8b5cf6', '#fbbf24', '#22c55e'],
      })
      confetti({
        ...defaults,
        particleCount,
        origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 },
        colors: ['#a855f7', '#ec4899', '#8b5cf6', '#fbbf24', '#22c55e'],
      })
    }, 250)
  }, [])

  // Start spinning animation
  const startSpinning = useCallback((names: string[], winnerName: string) => {
    if (names.length === 0) return

    const shuffledNames = [...names].sort(() => Math.random() - 0.5)
    setSpinningNames(shuffledNames)

    let speed = 50
    let iterations = 0
    const maxIterations = 40 + Math.random() * 20

    const spin = () => {
      setCurrentSpinIndex(prev => (prev + 1) % shuffledNames.length)
      iterations++

      if (iterations > maxIterations * 0.7) {
        speed = Math.min(speed * 1.2, 500)
      }

      if (iterations >= maxIterations) {
        // Find and show winner
        const winnerIndex = shuffledNames.findIndex(n => n === winnerName)
        if (winnerIndex >= 0) {
          setCurrentSpinIndex(winnerIndex)
        }

        setTimeout(() => {
          setDrawPhase('celebration')
          fireConfetti()
        }, 800)
        return
      }

      spinIntervalRef.current = setTimeout(spin, speed)
    }

    spinIntervalRef.current = setTimeout(spin, speed)

    return () => {
      if (spinIntervalRef.current) {
        clearTimeout(spinIntervalRef.current)
      }
    }
  }, [fireConfetti])

  // Auto-draw function when timeout expires
  const triggerAutoDraw = useCallback(async () => {
    if (autoDrawingRef.current) return
    autoDrawingRef.current = true

    try {
      const res = await fetch(`/api/raffles/${id}/draw`, { method: 'POST' })
      if (!res.ok) {
        console.error('Auto-draw failed:', await res.text())
      }
      // Next poll will detect the new winner
    } catch (error) {
      console.error('Auto-draw error:', error)
    } finally {
      autoDrawingRef.current = false
    }
  }, [id])

  useEffect(() => {
    setOrigin(window.location.origin)
    fetchRaffle()
    fetchParticipants()

    const interval = setInterval(() => {
      // Poll in idle phase OR in celebration with pending confirmation
      const shouldPoll = drawPhase === 'idle' ||
        (drawPhase === 'celebration' && raffle?.requireConfirmation && raffle?.status !== 'drawn')

      if (shouldPoll) {
        fetchRaffle()
        if (drawPhase === 'idle') {
          fetchParticipants()
        }
      }
    }, 2000)

    return () => {
      clearInterval(interval)
      if (spinIntervalRef.current) {
        clearTimeout(spinIntervalRef.current)
      }
    }
  }, [id, drawPhase, raffle?.requireConfirmation, raffle?.status])

  // Start spinning when draw is detected
  useEffect(() => {
    if (drawPhase === 'spinning' && detectedWinner && participants.length > 0) {
      startSpinning(participants.map(p => p.name), detectedWinner.name)
    }
  }, [drawPhase, detectedWinner, participants, startSpinning])

  const fetchRaffle = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}`)
      if (res.ok) {
        const data = await res.json()

        // Track previous winner for change detection
        const currentWinnerId = data.winner?.id || null
        const prevWinnerId = previousWinnerIdRef.current

        // Detect when winner changes during celebration (redraw or reopen)
        if (hadWinnerRef.current && drawPhase === 'celebration') {
          if (!data.winner) {
            // Winner removed (reopen) → go to idle
            hadWinnerRef.current = false
            previousWinnerIdRef.current = null
            setDetectedWinner(null)
            setDrawPhase('idle')
            setTimeoutRemaining(null)
          } else if (currentWinnerId !== prevWinnerId) {
            // Winner changed (new draw) → show spinning
            previousWinnerIdRef.current = currentWinnerId
            setDetectedWinner(data.winner)
            setDrawPhase('spinning')
            setTimeoutRemaining(null)
          }
        }
        // Detect first draw
        else if (data.winner && !hadWinnerRef.current) {
          hadWinnerRef.current = true
          previousWinnerIdRef.current = currentWinnerId
          setDetectedWinner(data.winner)

          // If page loads with winner already set, go straight to celebration
          // If winner is detected during polling, show spinning animation
          if (isFirstLoadRef.current) {
            setDrawPhase('celebration')
            fireConfetti()
          } else {
            setDrawPhase('spinning')
          }
        }

        isFirstLoadRef.current = false

        setRaffle(data)
      }
    } catch (error) {
      console.error('Error fetching raffle:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchParticipants = async () => {
    try {
      const res = await fetch(`/api/raffles/${id}/participants`)
      if (res.ok) {
        const data = await res.json()

        if (data.length > 0 && data[0].id !== lastNotifiedIdRef.current) {
          if (lastNotifiedIdRef.current !== null) {
            setLatestParticipant(data[0])
            setTimeout(() => setLatestParticipant(null), 5000)
          }
          lastNotifiedIdRef.current = data[0].id
        }

        setParticipants(data)
      }
    } catch (error) {
      console.error('Error fetching participants:', error)
    }
  }

  // Countdown timer for confirmation timeout
  useEffect(() => {
    // Only run countdown in celebration phase with pending confirmation
    if (drawPhase !== 'celebration' || !raffle?.requireConfirmation || !raffle?.confirmationTimeoutMinutes) {
      setTimeoutRemaining(null)
      return
    }

    // Get last draw
    const lastDraw = raffle.drawHistory?.[raffle.drawHistory.length - 1]
    if (!lastDraw || lastDraw.wasPresent) {
      setTimeoutRemaining(null)
      return
    }

    const drawTime = new Date(lastDraw.createdAt).getTime()
    const timeoutMs = raffle.confirmationTimeoutMinutes * 60 * 1000

    const updateRemaining = () => {
      const remaining = Math.max(0, (drawTime + timeoutMs) - Date.now())
      setTimeoutRemaining(Math.ceil(remaining / 1000))

      // Auto-draw when timeout expires
      if (remaining <= 0 && !autoDrawingRef.current) {
        triggerAutoDraw()
      }
    }

    updateRemaining()
    const interval = setInterval(updateRemaining, 1000)
    return () => clearInterval(interval)
  }, [raffle, drawPhase, triggerAutoDraw])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-black">
        <div className="animate-spin rounded-full h-20 w-20 border-4 border-purple-500 border-t-transparent"></div>
      </div>
    )
  }

  if (!raffle) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-black">
        <p className="text-3xl text-white">Sorteio não encontrado</p>
      </div>
    )
  }

  const registerUrl = `${origin}/register/${raffle.id}`

  // ========== SPINNING PHASE ==========
  if (drawPhase === 'spinning') {
    const displayName = spinningNames[currentSpinIndex] || '...'

    return (
      <div className="min-h-screen bg-black overflow-hidden relative">
        {/* Animated background */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-br from-purple-900/50 via-black to-pink-900/50" />
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
            className="absolute -top-1/2 -left-1/2 w-[200%] h-[200%] bg-[conic-gradient(from_0deg,transparent,purple,transparent,pink,transparent)] opacity-20"
          />
        </div>

        <div className="relative z-10 flex flex-col items-center justify-center min-h-screen p-4 md:p-8">
          {/* Title */}
          <motion.div
            initial={{ y: -50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="text-center mb-6 md:mb-12"
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1] }}
              transition={{ duration: 0.5, repeat: Infinity }}
              className="text-4xl md:text-7xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-500 mb-2 md:mb-4"
            >
              SORTEANDO...
            </motion.div>
            <p className="text-lg md:text-2xl text-white/60">Quem será o grande vencedor?</p>
          </motion.div>

          {/* Slot Machine Display */}
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="relative w-full max-w-[90vw] md:max-w-[600px]"
          >
            {/* Glow effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-purple-500 via-pink-500 to-purple-500 rounded-2xl md:rounded-3xl blur-xl opacity-50 animate-pulse" />

            {/* Main display */}
            <div className="relative bg-gradient-to-br from-gray-900 to-black rounded-2xl md:rounded-3xl p-1.5 md:p-2 border-2 md:border-4 border-purple-500/50">
              <div className="bg-black rounded-xl md:rounded-2xl px-4 md:px-16 py-8 md:py-12">
                <motion.div
                  key={currentSpinIndex}
                  initial={{ y: -30, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  exit={{ y: 30, opacity: 0 }}
                  transition={{ duration: 0.1 }}
                  className="text-3xl md:text-6xl font-bold text-center text-white truncate"
                >
                  {displayName}
                </motion.div>
              </div>
            </div>

            {/* Side decorations - hidden on mobile */}
            <div className="hidden md:block absolute -left-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 shadow-lg shadow-yellow-500/50" />
            <div className="hidden md:block absolute -right-6 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 shadow-lg shadow-yellow-500/50" />
          </motion.div>

          {/* Prize info */}
          <motion.div
            initial={{ y: 50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="mt-6 md:mt-12 flex items-center gap-2 md:gap-4"
          >
            <Gift className="h-6 w-6 md:h-10 md:w-10 text-yellow-400" />
            <span className="text-xl md:text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 to-orange-500">
              {raffle.prize}
            </span>
          </motion.div>
        </div>
      </div>
    )
  }

  // ========== CELEBRATION PHASE ==========
  if (drawPhase === 'celebration' && detectedWinner) {
    return (
      <div className="min-h-screen bg-black overflow-hidden relative">
        {/* Animated background */}
        <div className="absolute inset-0">
          <motion.div
            animate={{
              background: [
                'radial-gradient(circle at 50% 50%, #7c3aed 0%, #000 70%)',
                'radial-gradient(circle at 30% 70%, #ec4899 0%, #000 70%)',
                'radial-gradient(circle at 70% 30%, #f59e0b 0%, #000 70%)',
                'radial-gradient(circle at 50% 50%, #7c3aed 0%, #000 70%)',
              ]
            }}
            transition={{ duration: 4, repeat: Infinity }}
            className="absolute inset-0"
          />
        </div>

        {/* Floating stars - fewer on mobile */}
        {[...Array(10)].map((_, i) => (
          <motion.div
            key={i}
            initial={{
              x: Math.random() * (typeof window !== 'undefined' ? window.innerWidth : 1000),
              y: -50,
              rotate: 0,
              scale: Math.random() * 0.5 + 0.5
            }}
            animate={{
              y: (typeof window !== 'undefined' ? window.innerHeight : 800) + 50,
              rotate: 360,
            }}
            transition={{
              duration: Math.random() * 3 + 3,
              repeat: Infinity,
              delay: Math.random() * 2
            }}
            className="absolute"
          >
            <Star className="h-5 w-5 md:h-8 md:w-8 text-yellow-400 fill-yellow-400" />
          </motion.div>
        ))}

        <div className="relative z-10 flex flex-col items-center justify-center min-h-screen p-4 md:p-8">
          {/* Trophy */}
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ type: 'spring', stiffness: 200, delay: 0.2 }}
            className="relative mb-4 md:mb-8"
          >
            <motion.div
              animate={{ scale: [1, 1.1, 1] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="relative"
            >
              <div className="absolute inset-0 bg-yellow-400 rounded-full blur-3xl opacity-50" />
              <div className="relative flex h-28 w-28 md:h-48 md:w-48 items-center justify-center rounded-full bg-gradient-to-br from-yellow-300 via-yellow-400 to-orange-500 shadow-2xl">
                <Trophy className="h-14 w-14 md:h-24 md:w-24 text-white drop-shadow-lg" />
              </div>
            </motion.div>

            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.8, type: 'spring' }}
              className="absolute -top-2 -right-2 md:-top-4 md:-right-4"
            >
              <PartyPopper className="h-10 w-10 md:h-16 md:w-16 text-pink-400 drop-shadow-lg" />
            </motion.div>
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 1, type: 'spring' }}
              className="absolute -bottom-1 -left-3 md:-bottom-2 md:-left-6"
            >
              <Sparkles className="h-8 w-8 md:h-14 md:w-14 text-purple-400 drop-shadow-lg" />
            </motion.div>
          </motion.div>

          {/* Winner Text */}
          <motion.div
            initial={{ y: 50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.4 }}
            className="text-center px-4"
          >
            <motion.p
              className="text-xl md:text-4xl font-bold text-white/80 mb-2 md:mb-4"
              animate={{ opacity: [0.5, 1, 0.5] }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              O VENCEDOR E...
            </motion.p>

            <motion.h1
              initial={{ scale: 0.5 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.6, type: 'spring', stiffness: 150 }}
              className="text-4xl sm:text-6xl md:text-8xl lg:text-9xl font-black mb-4 md:mb-6"
            >
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 via-yellow-400 to-orange-400 drop-shadow-[0_0_30px_rgba(250,204,21,0.5)]">
                {detectedWinner.name}
              </span>
            </motion.h1>
          </motion.div>

          {/* Prize Box */}
          <motion.div
            initial={{ y: 50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 1 }}
            className="mt-4 md:mt-8 w-full max-w-md px-4"
          >
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl md:rounded-2xl blur-lg opacity-50" />
              <div className="relative bg-gradient-to-r from-purple-600/90 to-pink-600/90 backdrop-blur-lg rounded-xl md:rounded-2xl px-6 py-4 md:px-12 md:py-8 border border-white/20">
                <p className="text-sm md:text-xl text-white/70 mb-1 md:mb-2 text-center">GANHOU</p>
                <div className="flex items-center justify-center gap-2 md:gap-4">
                  <Gift className="h-6 w-6 md:h-12 md:w-12 text-yellow-400" />
                  <span className="text-2xl md:text-5xl font-bold text-white">{raffle.prize}</span>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Email */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.5 }}
            className="mt-4 md:mt-8 text-sm md:text-2xl text-white/50 px-4 text-center break-all"
          >
            {detectedWinner.email}
          </motion.p>

          {/* Confirmation QR Code - Only shown when requireConfirmation is enabled and raffle not finalized */}
          {raffle.requireConfirmation && raffle.status !== 'drawn' && (
            <motion.div
              initial={{ opacity: 0, y: 50 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 2 }}
              className="mt-6 md:mt-10 w-full max-w-md px-4"
            >
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-xl md:rounded-2xl blur-lg opacity-50" />
                <div className="relative bg-gradient-to-br from-gray-900/95 to-black/95 backdrop-blur-lg rounded-xl md:rounded-2xl p-4 md:p-6 border border-blue-500/50 text-center">
                  <div className="flex items-center justify-center gap-2 mb-3">
                    <KeyRound className="h-5 w-5 md:h-6 md:w-6 text-blue-400" />
                    <p className="text-base md:text-xl text-white font-bold">Confirme sua presença</p>
                  </div>

                  {/* Countdown Timer */}
                  {timeoutRemaining !== null && (
                    <div className="mb-4">
                      <p className="text-xs text-white/50 mb-1">Tempo para confirmar:</p>
                      <motion.p
                        animate={timeoutRemaining <= 30 ? { scale: [1, 1.05, 1] } : {}}
                        transition={{ duration: 0.5, repeat: Infinity }}
                        className={`text-3xl md:text-4xl font-bold ${
                          timeoutRemaining <= 30
                            ? 'text-red-400'
                            : timeoutRemaining <= 60
                            ? 'text-yellow-400'
                            : 'text-blue-400'
                        }`}
                      >
                        {Math.floor(timeoutRemaining / 60)}:{String(timeoutRemaining % 60).padStart(2, '0')}
                      </motion.p>
                      {timeoutRemaining <= 30 && (
                        <p className="text-xs text-red-400 mt-1 animate-pulse">Novo sorteio em breve!</p>
                      )}
                    </div>
                  )}

                  <p className="text-xs md:text-sm text-white/60 mb-4">
                    Escaneie o QR Code e digite seu código de 5 dígitos
                  </p>
                  <div className="bg-white rounded-xl p-3 mx-auto w-fit shadow-lg shadow-blue-500/30">
                    <QRCodeSVG value={`${origin}/confirm/${raffle.id}`} size={140} level="H" />
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </div>
      </div>
    )
  }

  // ========== IDLE PHASE - Main Display ==========
  return (
    <div className="min-h-screen bg-black text-white overflow-hidden">
      {/* Animated gradient background */}
      <div className="fixed inset-0">
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/30 via-black to-pink-900/30" />
        <motion.div
          animate={{
            background: [
              'radial-gradient(circle at 20% 80%, rgba(168, 85, 247, 0.15) 0%, transparent 50%)',
              'radial-gradient(circle at 80% 20%, rgba(236, 72, 153, 0.15) 0%, transparent 50%)',
              'radial-gradient(circle at 20% 80%, rgba(168, 85, 247, 0.15) 0%, transparent 50%)',
            ]
          }}
          transition={{ duration: 10, repeat: Infinity }}
          className="absolute inset-0"
        />
      </div>

      <div className="relative z-10 p-3 md:p-8 min-h-screen flex flex-col">
        {/* ===== MOBILE LAYOUT ===== */}
        <div className="md:hidden flex flex-col h-full">
          {/* Hero Section - Full width, vibrant */}
          <div className="relative mb-3">
            {/* Animated background glow */}
            <motion.div
              animate={{
                opacity: [0.4, 0.7, 0.4],
                scale: [1, 1.05, 1]
              }}
              transition={{ duration: 3, repeat: Infinity }}
              className="absolute inset-0 bg-gradient-to-br from-purple-600 via-pink-500 to-orange-500 rounded-3xl blur-2xl"
            />

            <div className="relative bg-gradient-to-br from-gray-900/95 to-black/95 rounded-3xl p-5 border border-purple-500/50">
              {/* Top: Logo + Live badge */}
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <Image
                    src="/nava-icon.jpg"
                    alt="Nava Logo"
                    width={44}
                    height={44}
                    className="rounded-xl shadow-lg shadow-purple-500/50"
                  />
                  <div>
                    <h1 className="text-lg font-bold text-white leading-tight">{raffle.name}</h1>
                    {raffle.description && (
                      <p className="text-xs text-white/50 truncate max-w-[150px]">{raffle.description}</p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {/* Countdown Timer - Mobile - só mostra se ainda não expirou */}
                  {raffle.endsAt && getEffectiveStatus(raffle) === 'active' && (
                    <div className="px-3 py-1.5 bg-red-500/30 border-2 border-red-400 rounded-full">
                      <CountdownTimer
                        endsAt={raffle.endsAt}
                        onExpire={() => fetchRaffle()}
                        size="sm"
                      />
                    </div>
                  )}
                  {getEffectiveStatus(raffle) === 'active' ? (
                    <motion.div
                      animate={{ scale: [1, 1.1, 1] }}
                      transition={{ duration: 1.5, repeat: Infinity }}
                      className="flex items-center gap-2 px-3 py-1.5 bg-green-500/30 border-2 border-green-400 rounded-full shadow-lg shadow-green-500/30"
                    >
                      <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-400"></span>
                      </span>
                      <span className="text-green-400 font-black text-xs tracking-wide">AO VIVO</span>
                    </motion.div>
                  ) : getEffectiveStatus(raffle) === 'closed' ? (
                    <div className="flex items-center gap-2 px-3 py-1.5 bg-yellow-500/30 border-2 border-yellow-400 rounded-full">
                      <span className="text-yellow-400 font-black text-xs tracking-wide">ENCERRADO</span>
                    </div>
                  ) : null}
                </div>
              </div>

              {/* Prize - Prominent */}
              <motion.div
                animate={{ y: [0, -3, 0] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="text-center py-3"
              >
                <div className="inline-flex items-center gap-3 px-5 py-3 bg-gradient-to-r from-yellow-500/30 to-orange-500/30 rounded-2xl border border-yellow-400/50">
                  <motion.div
                    animate={{ rotate: [0, 15, -15, 0], scale: [1, 1.1, 1] }}
                    transition={{ duration: 2, repeat: Infinity }}
                  >
                    <Trophy className="h-10 w-10 text-yellow-400 drop-shadow-[0_0_8px_rgba(250,204,21,0.5)]" />
                  </motion.div>
                  <div className="text-left">
                    <p className="text-[10px] text-yellow-400/80 uppercase tracking-widest font-bold">Premio</p>
                    <p className="text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 via-yellow-400 to-orange-400 drop-shadow-lg">
                      {raffle.prize}
                    </p>
                  </div>
                </div>
              </motion.div>
            </div>
          </div>

          {/* QR Code + Counter Row */}
          <div className="grid grid-cols-2 gap-3 mb-3">
            {/* QR Code */}
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="relative"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl blur-lg opacity-40" />
              <div className="relative bg-gradient-to-br from-gray-900/95 to-black/95 rounded-2xl p-3 border border-purple-500/50 h-full flex flex-col items-center justify-center">
                <p className="text-[10px] text-purple-400 uppercase tracking-wider font-bold mb-2">Escaneie</p>
                <div className="bg-white rounded-xl p-2 shadow-lg shadow-purple-500/30">
                  <QRCodeSVG value={registerUrl} size={90} level="H" />
                </div>
              </div>
            </motion.div>

            {/* Counter */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              className="relative"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-2xl blur-lg opacity-40" />
              <div className="relative bg-gradient-to-br from-gray-900/95 to-black/95 rounded-2xl p-3 border border-blue-500/50 h-full flex flex-col items-center justify-center">
                <Users className="h-8 w-8 text-blue-400 mb-1" />
                <p className="text-[10px] text-blue-400/80 uppercase tracking-wider font-bold">Participantes</p>
                <AnimatePresence mode="wait">
                  <motion.p
                    key={raffle._count.participants}
                    initial={{ scale: 2, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-cyan-400 to-blue-400"
                  >
                    {raffle._count.participants}
                  </motion.p>
                </AnimatePresence>
              </div>
            </motion.div>
          </div>

          {/* New Participant Alert - Mobile */}
          <AnimatePresence>
            {latestParticipant && (
              <motion.div
                initial={{ opacity: 0, y: -20, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -20, scale: 0.9 }}
                className="mb-3"
              >
                <div className="bg-gradient-to-r from-green-500/40 to-emerald-500/40 rounded-2xl p-3 border-2 border-green-400/70 shadow-lg shadow-green-500/30">
                  <div className="flex items-center gap-3">
                    <motion.div
                      animate={{ scale: [1, 1.3, 1] }}
                      transition={{ duration: 0.5, repeat: Infinity }}
                    >
                      <span className="flex h-4 w-4 relative">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-4 w-4 bg-green-400"></span>
                      </span>
                    </motion.div>
                    <span className="text-green-400 font-black text-sm">NOVO!</span>
                    <span className="text-xl font-black text-white truncate flex-1">{latestParticipant.name}</span>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Participants List - Takes remaining space */}
          <div className="flex-1 min-h-0 relative">
            <div className="absolute inset-0 bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-2xl blur-xl opacity-30" />
            <div className="relative h-full bg-gradient-to-br from-gray-900/90 to-black/90 rounded-2xl p-3 border border-white/20 flex flex-col">
              <div className="flex items-center gap-2 mb-3">
                <Sparkles className="h-5 w-5 text-yellow-400" />
                <h3 className="text-sm font-bold text-white">Participantes</h3>
              </div>

              <div className="flex-1 overflow-y-auto">
                {participants.length > 0 ? (
                  <div className="grid grid-cols-2 gap-2">
                    <AnimatePresence>
                      {participants.map((participant, index) => (
                        <motion.div
                          key={participant.id}
                          initial={{ opacity: 0, scale: 0.8 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: index * 0.02 }}
                          className="bg-white/10 rounded-xl p-2.5 border border-white/20"
                        >
                          <p className="font-bold text-sm text-white truncate">{participant.name}</p>
                          <p className="text-[10px] text-white/50">
                            {new Date(participant.createdAt).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
                          </p>
                        </motion.div>
                      ))}
                    </AnimatePresence>
                  </div>
                ) : (
                  <div className="flex-1 flex flex-col items-center justify-center text-white/40 py-8">
                    <motion.div
                      animate={{ y: [0, -5, 0] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    >
                      <Users className="h-12 w-12 mb-2" />
                    </motion.div>
                    <p className="text-sm font-bold">Aguardando participantes...</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* ===== DESKTOP HEADER ===== */}
        <div className="hidden md:flex items-center justify-between mb-8">
          <div className="flex items-center gap-6">
            <motion.div
              animate={{ rotate: [0, 5, -5, 0] }}
              transition={{ duration: 4, repeat: Infinity }}
            >
              <Image
                src="/nava-icon.jpg"
                alt="Nava Logo"
                width={100}
                height={100}
                className="rounded-2xl shadow-2xl shadow-purple-500/30"
              />
            </motion.div>
            <div>
              <h1 className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-white via-purple-200 to-pink-200">
                {raffle.name}
              </h1>
              {raffle.description && (
                <p className="text-xl text-white/50 mt-1">{raffle.description}</p>
              )}
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Countdown Timer - Desktop - só mostra se ainda não expirou */}
            {raffle.endsAt && getEffectiveStatus(raffle) === 'active' && (
              <motion.div
                animate={{ boxShadow: ['0 0 20px rgba(239,68,68,0.3)', '0 0 40px rgba(239,68,68,0.5)', '0 0 20px rgba(239,68,68,0.3)'] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="px-6 py-3 bg-red-500/20 border-2 border-red-500 rounded-full"
              >
                <CountdownTimer
                  endsAt={raffle.endsAt}
                  onExpire={() => fetchRaffle()}
                  size="md"
                />
              </motion.div>
            )}
            {getEffectiveStatus(raffle) === 'active' ? (
              <motion.div
                animate={{ scale: [1, 1.05, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="flex items-center gap-3 px-6 py-3 bg-green-500/20 border-2 border-green-500 rounded-full"
              >
                <span className="relative flex h-4 w-4">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-4 w-4 bg-green-500"></span>
                </span>
                <span className="text-green-400 font-bold text-xl">AO VIVO</span>
              </motion.div>
            ) : getEffectiveStatus(raffle) === 'closed' ? (
              <div className="flex items-center gap-3 px-6 py-3 bg-yellow-500/20 border-2 border-yellow-500 rounded-full">
                <span className="text-yellow-400 font-bold text-xl">ENCERRADO</span>
              </div>
            ) : null}
          </div>
        </div>

        {/* Main Content - Desktop Only */}
        <div className="hidden md:flex flex-1 lg:grid lg:grid-cols-12 gap-8 overflow-hidden">
          {/* Left Column - QR & Prize & Counter */}
          <div className="hidden lg:block lg:col-span-4 space-y-6">
            {/* QR Code Card */}
            <motion.div
              initial={{ x: -50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              className="relative group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-purple-500 to-pink-500 rounded-3xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity" />
              <div className="relative bg-gradient-to-br from-gray-900/90 to-black/90 backdrop-blur-xl rounded-3xl p-8 border border-white/10">
                <h3 className="text-2xl font-bold text-center mb-6 text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">
                  Escaneie para Participar
                </h3>
                <div className="bg-white rounded-2xl p-4 mx-auto w-fit shadow-2xl shadow-purple-500/20">
                  <QRCodeSVG value={registerUrl} size={220} level="H" includeMargin={true} />
                </div>
              </div>
            </motion.div>

            {/* Prize Card */}
            <motion.div
              initial={{ x: -50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="relative group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-yellow-500 to-orange-500 rounded-3xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity" />
              <div className="relative bg-gradient-to-br from-gray-900/90 to-black/90 backdrop-blur-xl rounded-3xl p-8 border border-yellow-500/30">
                <div className="flex items-center gap-4 mb-4">
                  <div className="p-3 bg-yellow-500/20 rounded-xl">
                    <Trophy className="h-10 w-10 text-yellow-400" />
                  </div>
                  <h3 className="text-2xl font-bold text-yellow-400">Premio</h3>
                </div>
                <p className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 to-orange-400">
                  {raffle.prize}
                </p>
              </div>
            </motion.div>

            {/* Counter */}
            <motion.div
              initial={{ x: -50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="relative group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-blue-500 to-purple-500 rounded-3xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity" />
              <div className="relative bg-gradient-to-br from-gray-900/90 to-black/90 backdrop-blur-xl rounded-3xl p-8 border border-blue-500/30">
                <div className="flex items-center gap-6">
                  <div className="p-4 bg-blue-500/20 rounded-2xl">
                    <Users className="h-12 w-12 text-blue-400" />
                  </div>
                  <div>
                    <p className="text-lg text-white/50">Participantes</p>
                    <AnimatePresence mode="wait">
                      <motion.p
                        key={raffle._count.participants}
                        initial={{ scale: 1.5, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        className="text-6xl font-black text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400"
                      >
                        {raffle._count.participants}
                      </motion.p>
                    </AnimatePresence>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>

          {/* Right Column - Participants */}
          <div className="lg:col-span-8 flex-1 min-h-0">
            <motion.div
              initial={{ x: 50, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              className="h-full relative"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-3xl blur-xl opacity-30" />
              <div className="relative h-full bg-gradient-to-br from-gray-900/80 to-black/80 backdrop-blur-xl rounded-3xl p-8 border border-white/10 flex flex-col">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-3xl font-bold flex items-center gap-3">
                    <Sparkles className="h-8 w-8 text-yellow-400" />
                    <span className="text-transparent bg-clip-text bg-gradient-to-r from-white to-purple-200">
                      Participantes
                    </span>
                  </h3>
                </div>

                {/* New Participant Alert */}
                <AnimatePresence>
                  {latestParticipant && (
                    <motion.div
                      initial={{ x: 300, opacity: 0 }}
                      animate={{ x: 0, opacity: 1 }}
                      exit={{ x: -300, opacity: 0 }}
                      className="mb-6"
                    >
                      <div className="bg-gradient-to-r from-green-500/30 to-emerald-500/30 rounded-2xl p-5 border-2 border-green-500/50">
                        <div className="flex items-center gap-4">
                          <span className="relative flex h-5 w-5">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-5 w-5 bg-green-500"></span>
                          </span>
                          <span className="text-green-400 font-bold text-xl">NOVO!</span>
                          <span className="text-3xl font-black text-white truncate">{latestParticipant.name}</span>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Participants Grid */}
                <div className="flex-1 overflow-y-auto">
                  <div className="grid grid-cols-3 gap-4 pr-1">
                    <AnimatePresence>
                      {participants.map((participant, index) => (
                        <motion.div
                          key={participant.id}
                          initial={{ opacity: 0, scale: 0.8 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: index * 0.02 }}
                          className="bg-white/5 hover:bg-white/10 rounded-xl p-4 border border-white/10 hover:border-purple-500/50 transition-all"
                        >
                          <p className="font-semibold text-lg truncate">{participant.name}</p>
                          <p className="text-sm text-white/40">
                            {new Date(participant.createdAt).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
                          </p>
                        </motion.div>
                      ))}
                    </AnimatePresence>
                  </div>
                </div>

                {participants.length === 0 && (
                  <div className="flex-1 flex flex-col items-center justify-center text-white/30">
                    <Users className="h-20 w-20 mb-4" />
                    <p className="text-2xl font-bold text-center">Aguardando participantes...</p>
                  </div>
                )}
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}
