'use client'

import { useEffect, useState } from 'react'
import { Users } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

interface ParticipantCounterProps {
  raffleId: string
  initialCount: number
}

export function ParticipantCounter({ raffleId, initialCount }: ParticipantCounterProps) {
  const [count, setCount] = useState(initialCount)
  const [isUpdating, setIsUpdating] = useState(false)

  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/register/${raffleId}`)
        const data = await res.json()
        if (data.participantCount !== count) {
          setIsUpdating(true)
          setCount(data.participantCount)
          setTimeout(() => setIsUpdating(false), 500)
        }
      } catch (error) {
        console.error('Error fetching count:', error)
      }
    }, 3000)

    return () => clearInterval(interval)
  }, [raffleId, count])

  return (
    <div className="flex items-center gap-3 p-4 rounded-xl bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/20">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary/20">
        <Users className="h-6 w-6 text-primary" />
      </div>
      <div>
        <p className="text-sm text-muted-foreground">Participantes</p>
        <AnimatePresence mode="wait">
          <motion.div
            key={count}
            initial={{ scale: 1.2, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.8, opacity: 0 }}
            transition={{ duration: 0.3 }}
            className={`text-3xl font-bold ${isUpdating ? 'text-primary' : ''}`}
          >
            {count}
          </motion.div>
        </AnimatePresence>
      </div>
      {isUpdating && (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          className="ml-auto flex h-3 w-3 rounded-full bg-green-500"
        >
          <span className="animate-ping absolute h-3 w-3 rounded-full bg-green-400 opacity-75"></span>
        </motion.div>
      )}
    </div>
  )
}
