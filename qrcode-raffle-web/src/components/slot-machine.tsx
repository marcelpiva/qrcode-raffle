'use client'

import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

interface SlotMachineProps {
  names: string[]
  winner: string
  isSpinning: boolean
  onSpinComplete: () => void
}

export function SlotMachine({ names, winner, isSpinning, onSpinComplete }: SlotMachineProps) {
  const [displayedNames, setDisplayedNames] = useState<string[]>([])
  const [currentIndex, setCurrentIndex] = useState(0)
  const intervalRef = useRef<NodeJS.Timeout | null>(null)

  useEffect(() => {
    if (isSpinning && names.length > 0) {
      // Create a shuffled list of names for display
      const shuffled = [...names].sort(() => Math.random() - 0.5)
      setDisplayedNames([...shuffled, ...shuffled, ...shuffled]) // Triple for smooth spinning

      let speed = 50 // Start fast
      let iterations = 0
      const maxIterations = 30 + Math.random() * 20 // Random stop point

      const spin = () => {
        setCurrentIndex((prev) => (prev + 1) % (shuffled.length * 3))
        iterations++

        // Gradually slow down
        if (iterations > maxIterations * 0.6) {
          speed = Math.min(speed * 1.15, 400)
        }

        if (iterations >= maxIterations) {
          // Find winner index and animate to it
          const winnerIndex = shuffled.indexOf(winner)
          setCurrentIndex(winnerIndex >= 0 ? winnerIndex : 0)
          onSpinComplete()
          return
        }

        intervalRef.current = setTimeout(spin, speed)
      }

      intervalRef.current = setTimeout(spin, speed)

      return () => {
        if (intervalRef.current) {
          clearTimeout(intervalRef.current)
        }
      }
    }
  }, [isSpinning, names, winner, onSpinComplete])

  const visibleNames = displayedNames.length > 0
    ? [
        displayedNames[(currentIndex - 2 + displayedNames.length) % displayedNames.length],
        displayedNames[(currentIndex - 1 + displayedNames.length) % displayedNames.length],
        displayedNames[currentIndex % displayedNames.length],
        displayedNames[(currentIndex + 1) % displayedNames.length],
        displayedNames[(currentIndex + 2) % displayedNames.length],
      ]
    : names.slice(0, 5)

  return (
    <div className="relative w-full max-w-md mx-auto">
      {/* Slot machine container */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-b from-background to-muted border-4 border-primary/30 shadow-2xl">
        {/* Top shadow gradient */}
        <div className="absolute top-0 left-0 right-0 h-16 bg-gradient-to-b from-background to-transparent z-10 pointer-events-none" />

        {/* Bottom shadow gradient */}
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-background to-transparent z-10 pointer-events-none" />

        {/* Center highlight */}
        <div className="absolute top-1/2 left-0 right-0 -translate-y-1/2 h-16 border-y-2 border-primary/50 bg-primary/5 z-5 pointer-events-none" />

        {/* Names container */}
        <div className="py-8 px-4">
          <AnimatePresence mode="popLayout">
            {visibleNames.map((name, index) => {
              const isCenter = index === 2
              const distance = Math.abs(index - 2)

              return (
                <motion.div
                  key={`${name}-${index}-${currentIndex}`}
                  initial={{ y: -20, opacity: 0 }}
                  animate={{
                    y: 0,
                    opacity: isCenter ? 1 : 0.3 - distance * 0.1,
                    scale: isCenter ? 1.1 : 1 - distance * 0.1,
                  }}
                  exit={{ y: 20, opacity: 0 }}
                  transition={{ duration: 0.1 }}
                  className={`
                    py-3 px-6 text-center font-bold transition-all
                    ${isCenter
                      ? 'text-2xl text-primary'
                      : 'text-lg text-muted-foreground blur-[1px]'
                    }
                  `}
                >
                  {name}
                </motion.div>
              )
            })}
          </AnimatePresence>
        </div>
      </div>

      {/* Decorative elements */}
      <div className="absolute -left-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-gradient-to-br from-primary to-secondary shadow-lg" />
      <div className="absolute -right-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-gradient-to-br from-primary to-secondary shadow-lg" />
    </div>
  )
}
