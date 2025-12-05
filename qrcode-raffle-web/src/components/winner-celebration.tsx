'use client'

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import confetti from 'canvas-confetti'
import { Trophy, Mail, PartyPopper } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'

interface WinnerCelebrationProps {
  winner: {
    name: string
    email: string
  }
  prize: string
}

export function WinnerCelebration({ winner, prize }: WinnerCelebrationProps) {
  useEffect(() => {
    // Initial burst
    const count = 200
    const defaults = {
      origin: { y: 0.7 },
      zIndex: 1000,
    }

    function fire(particleRatio: number, opts: confetti.Options) {
      confetti({
        ...defaults,
        ...opts,
        particleCount: Math.floor(count * particleRatio),
      })
    }

    // Fire confetti in sequence
    fire(0.25, {
      spread: 26,
      startVelocity: 55,
      colors: ['#a855f7', '#ec4899', '#8b5cf6'],
    })

    fire(0.2, {
      spread: 60,
      colors: ['#a855f7', '#ec4899', '#8b5cf6'],
    })

    fire(0.35, {
      spread: 100,
      decay: 0.91,
      scalar: 0.8,
      colors: ['#a855f7', '#ec4899', '#8b5cf6'],
    })

    fire(0.1, {
      spread: 120,
      startVelocity: 25,
      decay: 0.92,
      scalar: 1.2,
      colors: ['#a855f7', '#ec4899', '#8b5cf6'],
    })

    fire(0.1, {
      spread: 120,
      startVelocity: 45,
      colors: ['#a855f7', '#ec4899', '#8b5cf6'],
    })

    // Continuous side confetti
    const duration = 3000
    const end = Date.now() + duration

    const frame = () => {
      confetti({
        particleCount: 2,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: ['#a855f7', '#ec4899', '#8b5cf6'],
        zIndex: 1000,
      })
      confetti({
        particleCount: 2,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: ['#a855f7', '#ec4899', '#8b5cf6'],
        zIndex: 1000,
      })

      if (Date.now() < end) {
        requestAnimationFrame(frame)
      }
    }

    frame()
  }, [])

  return (
    <motion.div
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 200, delay: 0.3 }}
      className="w-full max-w-lg mx-auto"
    >
      <Card className="overflow-hidden border-2 border-primary/50 shadow-2xl">
        <div className="absolute inset-0 bg-gradient-to-br from-primary/20 via-transparent to-secondary/20" />

        <CardContent className="relative p-8 text-center">
          <motion.div
            initial={{ y: -50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.5, type: 'spring' }}
            className="flex justify-center mb-6"
          >
            <div className="relative">
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-primary to-secondary shadow-lg animate-pulse-glow">
                <Trophy className="h-12 w-12 text-white" />
              </div>
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.8, type: 'spring' }}
                className="absolute -top-2 -right-2"
              >
                <PartyPopper className="h-8 w-8 text-accent" />
              </motion.div>
            </div>
          </motion.div>

          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.6 }}
          >
            <p className="text-sm text-muted-foreground mb-2">O vencedor e...</p>
            <h2 className="text-4xl font-bold bg-gradient-to-r from-primary via-accent to-secondary bg-clip-text text-transparent mb-4">
              {winner.name}
            </h2>
          </motion.div>

          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.8 }}
            className="flex items-center justify-center gap-2 text-muted-foreground mb-6"
          >
            <Mail className="h-4 w-4" />
            <span>{winner.email}</span>
          </motion.div>

          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 1 }}
            className="p-4 rounded-xl bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/30"
          >
            <p className="text-sm text-muted-foreground">Ganhou</p>
            <p className="text-2xl font-bold text-primary">{prize}</p>
          </motion.div>
        </CardContent>
      </Card>
    </motion.div>
  )
}
