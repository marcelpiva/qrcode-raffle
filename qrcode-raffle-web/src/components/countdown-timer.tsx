'use client'

import { useState, useEffect, useCallback } from 'react'
import { motion } from 'framer-motion'
import { Clock, AlertTriangle } from 'lucide-react'

interface CountdownTimerProps {
  endsAt: string | Date
  onExpire?: () => void
  size?: 'sm' | 'md' | 'lg'
  showIcon?: boolean
}

export function CountdownTimer({ endsAt, onExpire, size = 'md', showIcon = true }: CountdownTimerProps) {
  const [timeLeft, setTimeLeft] = useState<number>(0)
  const [serverOffset, setServerOffset] = useState<number>(0)
  const [isMounted, setIsMounted] = useState(false)

  // Sync with server time on mount
  useEffect(() => {
    setIsMounted(true)
    async function syncTime() {
      try {
        const start = Date.now()
        const res = await fetch('/api/time')
        const { serverTime } = await res.json()
        const end = Date.now()
        const latency = (end - start) / 2
        const serverNow = new Date(serverTime).getTime() + latency
        setServerOffset(serverNow - Date.now())
      } catch (error) {
        console.error('Failed to sync time:', error)
      }
    }
    syncTime()
  }, [])

  const calculateTimeLeft = useCallback(() => {
    const now = Date.now() + serverOffset
    const end = new Date(endsAt).getTime()
    return Math.max(0, Math.floor((end - now) / 1000))
  }, [endsAt, serverOffset])

  useEffect(() => {
    if (!isMounted) return

    setTimeLeft(calculateTimeLeft())

    const interval = setInterval(() => {
      const remaining = calculateTimeLeft()
      setTimeLeft(remaining)
      if (remaining <= 0) {
        clearInterval(interval)
        onExpire?.()
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [calculateTimeLeft, onExpire, isMounted])

  const minutes = Math.floor(timeLeft / 60)
  const seconds = timeLeft % 60

  const isUrgent = timeLeft <= 60 && timeLeft > 0 // Last minute
  const isExpired = timeLeft <= 0

  const sizeClasses = {
    sm: 'text-lg',
    md: 'text-2xl',
    lg: 'text-4xl'
  }

  const iconSizes = {
    sm: 'h-4 w-4',
    md: 'h-5 w-5',
    lg: 'h-6 w-6'
  }

  // Don't render until mounted to avoid hydration mismatch
  if (!isMounted) {
    return (
      <div className={`flex items-center gap-2 text-white/50 ${sizeClasses[size]}`}>
        <Clock className={iconSizes[size]} />
        <span className="font-mono font-bold">--:--</span>
      </div>
    )
  }

  if (isExpired) {
    return (
      <motion.div
        className={`flex items-center gap-2 text-red-500 ${sizeClasses[size]}`}
        animate={{ opacity: [1, 0.5, 1] }}
        transition={{ duration: 1, repeat: Infinity }}
      >
        {showIcon && <AlertTriangle className={iconSizes[size]} />}
        <span className="font-mono font-bold">ENCERRADO</span>
      </motion.div>
    )
  }

  return (
    <motion.div
      animate={isUrgent ? { scale: [1, 1.05, 1] } : {}}
      transition={{ duration: 0.5, repeat: isUrgent ? Infinity : 0 }}
      className={`flex items-center gap-2 ${isUrgent ? 'text-red-500' : 'text-white'} ${sizeClasses[size]}`}
    >
      {showIcon && (isUrgent ? <AlertTriangle className={iconSizes[size]} /> : <Clock className={iconSizes[size]} />)}
      <span className="font-mono font-bold tabular-nums">
        {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
      </span>
    </motion.div>
  )
}
