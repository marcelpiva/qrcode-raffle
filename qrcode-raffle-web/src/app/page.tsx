'use client'

import { useEffect, useState, useCallback } from 'react'
import Image from "next/image"
import { motion, AnimatePresence, PanInfo } from "framer-motion"
import { Calendar, Users, Trophy, Layers, Sparkles, Clock, ChevronLeft, ChevronRight, Mic2, ChevronDown, Info } from "lucide-react"
import { EventTimeline } from "@/components/event-timeline"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"

interface Talk {
  id: string
  title: string
  speaker: string | null
  startTime: string | null
  endTime: string | null
  description: string | null
  attendanceCount: number
  raffleCount: number
}

interface Track {
  id: string
  title: string
  startDate: string
  endDate: string
  talkCount: number
  attendanceCount: number
  raffleCount: number
  talks: Talk[]
}

interface Event {
  id: string
  name: string
  startDate: string
  endDate: string
  speakers: string | null
  trackCount: number
  raffleCount: number
  attendanceCount: number
  tracks: Track[]
}

type EventStatus = 'happening' | 'upcoming' | 'finished'

function getEventStatus(event: Event): EventStatus {
  // Comparar apenas as datas (sem hora) para evitar problemas de timezone
  const now = new Date()
  const todayStr = now.toISOString().split('T')[0]
  const startStr = new Date(event.startDate).toISOString().split('T')[0]
  const endStr = new Date(event.endDate).toISOString().split('T')[0]

  if (todayStr < startStr) return 'upcoming'
  if (todayStr > endStr) return 'finished'
  return 'happening'
}

function formatDateRange(start: string, end: string) {
  const startDate = new Date(start)
  const endDate = new Date(end)

  // Use UTC to avoid timezone shift (dates stored as UTC midnight shift to previous day in Brazil)
  const dayFormat: Intl.DateTimeFormatOptions = { day: '2-digit', timeZone: 'UTC' }
  const monthFormat: Intl.DateTimeFormatOptions = { month: 'short', timeZone: 'UTC' }

  if (startDate.toDateString() === endDate.toDateString()) {
    return `${startDate.toLocaleDateString('pt-BR', dayFormat)} ${startDate.toLocaleDateString('pt-BR', monthFormat).toUpperCase()}`
  }

  return `${startDate.toLocaleDateString('pt-BR', dayFormat)}-${endDate.toLocaleDateString('pt-BR', dayFormat)} ${startDate.toLocaleDateString('pt-BR', monthFormat).toUpperCase()}`
}

function pluralize(count: number, singular: string, plural: string) {
  return count === 1 ? singular : plural
}

const statusConfig = {
  happening: {
    label: 'AO VIVO',
    bgClass: 'bg-emerald-500',
    glowClass: 'shadow-emerald-500/50',
    dotClass: 'bg-emerald-400',
    borderClass: 'border-emerald-500/30',
    icon: Sparkles
  },
  upcoming: {
    label: 'EM BREVE',
    bgClass: 'bg-sky-500',
    glowClass: 'shadow-sky-500/50',
    dotClass: 'bg-sky-400',
    borderClass: 'border-sky-500/30',
    icon: Clock
  },
  finished: {
    label: 'ENCERRADO',
    bgClass: 'bg-zinc-500',
    glowClass: 'shadow-zinc-500/30',
    dotClass: 'bg-zinc-400',
    borderClass: 'border-zinc-500/30',
    icon: Trophy
  }
}

export default function Home() {
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [currentIndex, setCurrentIndex] = useState(0)
  const [direction, setDirection] = useState(0)
  const [showTimeline, setShowTimeline] = useState(false)

  useEffect(() => {
    fetchEvents()
  }, [])

  const fetchEvents = async () => {
    try {
      const res = await fetch('/api/events')
      const data = await res.json()
      if (Array.isArray(data)) {
        // Sort: happening first, then upcoming, then finished
        const sorted = data.sort((a, b) => {
          const statusOrder = { happening: 0, upcoming: 1, finished: 2 }
          const statusA = getEventStatus(a)
          const statusB = getEventStatus(b)
          if (statusOrder[statusA] !== statusOrder[statusB]) {
            return statusOrder[statusA] - statusOrder[statusB]
          }
          // Within same status, sort by date
          return new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
        })
        setEvents(sorted)
      }
    } catch (error) {
      console.error('Error fetching events:', error)
    } finally {
      setLoading(false)
    }
  }

  const paginate = useCallback((newDirection: number) => {
    if (events.length === 0) return
    setDirection(newDirection)
    setCurrentIndex((prev) => {
      if (newDirection === 1) {
        return prev === events.length - 1 ? 0 : prev + 1
      }
      return prev === 0 ? events.length - 1 : prev - 1
    })
  }, [events.length])

  const handleDragEnd = (_: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    const swipeThreshold = 50
    if (info.offset.x > swipeThreshold) {
      paginate(-1)
    } else if (info.offset.x < -swipeThreshold) {
      paginate(1)
    }
  }

  const variants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 300 : -300,
      opacity: 0,
      scale: 0.95
    }),
    center: {
      x: 0,
      opacity: 1,
      scale: 1
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 300 : -300,
      opacity: 0,
      scale: 0.95
    })
  }

  const currentEvent = events[currentIndex]
  const status = currentEvent ? getEventStatus(currentEvent) : null
  const config = status ? statusConfig[status] : null
  const StatusIcon = config?.icon || Sparkles

  return (
    <div className="fixed inset-0 overflow-hidden bg-zinc-950">
      {/* Animated gradient mesh background */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-purple-900/40 via-zinc-950 to-zinc-950" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,_var(--tw-gradient-stops))] from-pink-900/30 via-transparent to-transparent" />
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-purple-600/20 rounded-full blur-[128px] animate-pulse" />
        <div className="absolute bottom-0 right-1/4 w-80 h-80 bg-pink-600/20 rounded-full blur-[100px] animate-pulse" style={{ animationDelay: '1s' }} />

        {/* Grid overlay */}
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
                              linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
            backgroundSize: '50px 50px'
          }}
        />
      </div>

      {/* Content */}
      <div className="relative z-10 h-full flex flex-col">
        {/* Header */}
        <header className="flex-shrink-0 px-6 pt-6 pb-4">
          <motion.div
            className="flex items-center justify-center gap-3"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
          >
            <div className="relative">
              <div className="absolute -inset-1 bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl blur opacity-70" />
              <Image
                src="/nava-icon.jpg"
                alt="Nava Logo"
                width={48}
                height={48}
                className="relative rounded-xl"
              />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-white">
                NAVA<span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">SUMMIT</span>
              </h1>
              <p className="text-[10px] uppercase tracking-[0.3em] text-zinc-500 font-medium">
                Eventos & Sorteios
              </p>
            </div>
          </motion.div>
        </header>

        {/* Main carousel area */}
        <main className="flex-1 flex flex-col items-center justify-center px-4 min-h-0">
          {loading ? (
            <motion.div
              className="flex flex-col items-center gap-4"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            >
              <div className="w-12 h-12 border-2 border-purple-500/30 border-t-purple-500 rounded-full animate-spin" />
              <p className="text-zinc-500 text-sm">Carregando eventos...</p>
            </motion.div>
          ) : events.length === 0 ? (
            <motion.div
              className="text-center"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-pink-500/20 flex items-center justify-center border border-purple-500/20">
                <Calendar className="w-10 h-10 text-purple-400" />
              </div>
              <h2 className="text-xl font-bold text-white mb-2">Em Breve</h2>
              <p className="text-zinc-500 text-sm">Novos eventos em preparação</p>
            </motion.div>
          ) : (
            <div className="w-full max-w-md flex flex-col items-center gap-4">
              {/* Navigation arrows - desktop */}
              <div className="hidden sm:flex absolute inset-x-0 top-1/2 -translate-y-1/2 justify-between px-4 pointer-events-none z-20">
                <motion.button
                  onClick={() => paginate(-1)}
                  className="pointer-events-auto w-10 h-10 rounded-full bg-white/5 backdrop-blur-sm border border-white/10 flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-all"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <ChevronLeft className="w-5 h-5" />
                </motion.button>
                <motion.button
                  onClick={() => paginate(1)}
                  className="pointer-events-auto w-10 h-10 rounded-full bg-white/5 backdrop-blur-sm border border-white/10 flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-all"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <ChevronRight className="w-5 h-5" />
                </motion.button>
              </div>

              {/* Event card carousel */}
              <div className="relative w-full" style={{ minHeight: '420px' }}>
                <AnimatePresence initial={false} custom={direction} mode="wait">
                  <motion.div
                    key={currentIndex}
                    custom={direction}
                    variants={variants}
                    initial="enter"
                    animate="center"
                    exit="exit"
                    transition={{ type: "spring", stiffness: 300, damping: 30 }}
                    drag="x"
                    dragConstraints={{ left: 0, right: 0 }}
                    dragElastic={0.2}
                    onDragEnd={handleDragEnd}
                    className="w-full cursor-grab active:cursor-grabbing"
                  >
                    {currentEvent && config && (
                      <div className={`relative rounded-2xl border ${config.borderClass} bg-zinc-900/80 backdrop-blur-xl overflow-hidden shadow-2xl ${config.glowClass}`}>
                        {/* Status badge */}
                        <div className="absolute top-4 left-4 z-10">
                          <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full ${config.bgClass} shadow-lg ${config.glowClass}`}>
                            {status === 'happening' && (
                              <span className="relative flex h-2 w-2">
                                <span className={`animate-ping absolute inline-flex h-full w-full rounded-full ${config.dotClass} opacity-75`}></span>
                                <span className={`relative inline-flex rounded-full h-2 w-2 ${config.dotClass}`}></span>
                              </span>
                            )}
                            <StatusIcon className="w-3.5 h-3.5 text-white" />
                            <span className="text-[10px] font-bold tracking-wider text-white">{config.label}</span>
                          </div>
                        </div>

                        {/* Card content */}
                        <div className="h-full flex flex-col p-6 pt-16">
                          {/* Event info */}
                          <div className="flex-1 flex flex-col justify-center">
                            <motion.div
                              initial={{ opacity: 0, y: 10 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ delay: 0.1 }}
                            >
                              <div className="flex items-center gap-2 text-zinc-400 text-sm mb-2">
                                <Calendar className="w-4 h-4" />
                                <span className="font-medium tracking-wide">
                                  {formatDateRange(currentEvent.startDate, currentEvent.endDate)}
                                </span>
                              </div>

                              <h2 className="text-3xl sm:text-4xl font-black text-white mb-4 leading-tight">
                                {currentEvent.name}
                              </h2>

                              {currentEvent.speakers && (
                                <p className="text-zinc-400 text-sm line-clamp-2 mb-4">
                                  {currentEvent.speakers}
                                </p>
                              )}
                            </motion.div>

                            {/* Stats */}
                            <motion.div
                              className="grid grid-cols-3 gap-3 mt-auto"
                              initial={{ opacity: 0, y: 10 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ delay: 0.2 }}
                            >
                              <div className="text-center p-3 rounded-xl bg-white/5 border border-white/5">
                                <div className="flex items-center justify-center gap-1.5 text-purple-400 mb-1">
                                  <Layers className="w-4 h-4" />
                                </div>
                                <div className="text-xl font-bold text-white">{currentEvent.trackCount}</div>
                                <div className="text-[10px] text-zinc-500 uppercase tracking-wider">
                                  {pluralize(currentEvent.trackCount, 'Trilha', 'Trilhas')}
                                </div>
                              </div>
                              <TooltipProvider delayDuration={0}>
                                <Tooltip>
                                  <TooltipTrigger asChild>
                                    <div className="text-center p-3 rounded-xl bg-white/5 border border-white/5 cursor-help relative">
                                      <Info className="w-2.5 h-2.5 absolute top-1.5 right-1.5 text-zinc-600" />
                                      <div className="flex items-center justify-center gap-1.5 text-pink-400 mb-1">
                                        <Users className="w-4 h-4" />
                                      </div>
                                      <div className="text-xl font-bold text-white">{currentEvent.attendanceCount}</div>
                                      <div className="text-[10px] text-zinc-500 uppercase tracking-wider">
                                        {pluralize(currentEvent.attendanceCount, 'Presença', 'Presenças')}
                                      </div>
                                    </div>
                                  </TooltipTrigger>
                                  <TooltipContent side="top" className="max-w-[200px] text-center">
                                    <p>Participantes únicos (cada pessoa é contada apenas uma vez)</p>
                                  </TooltipContent>
                                </Tooltip>
                              </TooltipProvider>
                              <div className="text-center p-3 rounded-xl bg-white/5 border border-white/5">
                                <div className="flex items-center justify-center gap-1.5 text-amber-400 mb-1">
                                  <Trophy className="w-4 h-4" />
                                </div>
                                <div className="text-xl font-bold text-white">{currentEvent.raffleCount}</div>
                                <div className="text-[10px] text-zinc-500 uppercase tracking-wider">
                                  {pluralize(currentEvent.raffleCount, 'Sorteio', 'Sorteios')}
                                </div>
                              </div>
                            </motion.div>
                          </div>

                          {/* Ver Programação button */}
                          {currentEvent.tracks.length > 0 && (
                            <motion.div
                              className="mt-4 pt-4 border-t border-white/5"
                              initial={{ opacity: 0 }}
                              animate={{ opacity: 1 }}
                              transition={{ delay: 0.3 }}
                            >
                              <button
                                onClick={() => setShowTimeline(!showTimeline)}
                                className="w-full flex items-center justify-center gap-2 py-2.5 rounded-lg bg-gradient-to-r from-purple-500/20 to-pink-500/20 border border-purple-500/30 text-sm text-purple-300 hover:from-purple-500/30 hover:to-pink-500/30 transition-all"
                              >
                                <Mic2 className="w-4 h-4" />
                                <span>Ver Programação</span>
                                <ChevronDown className={`w-4 h-4 transition-transform ${showTimeline ? 'rotate-180' : ''}`} />
                              </button>
                            </motion.div>
                          )}
                        </div>
                      </div>
                    )}
                  </motion.div>
                </AnimatePresence>
              </div>

              {/* Pagination dots */}
              {events.length > 1 && (
                <motion.div
                  className="flex items-center gap-2 mt-2"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.4 }}
                >
                  {events.map((_, index) => (
                    <button
                      key={index}
                      onClick={() => {
                        setDirection(index > currentIndex ? 1 : -1)
                        setCurrentIndex(index)
                      }}
                      className={`transition-all duration-300 rounded-full ${
                        index === currentIndex
                          ? 'w-6 h-2 bg-gradient-to-r from-purple-500 to-pink-500'
                          : 'w-2 h-2 bg-zinc-700 hover:bg-zinc-600'
                      }`}
                    />
                  ))}
                </motion.div>
              )}

              {/* Swipe hint - mobile */}
              <motion.p
                className="sm:hidden text-zinc-600 text-xs mt-2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
              >
                ← Arraste para navegar →
              </motion.p>
            </div>
          )}
        </main>

        {/* Footer */}
        <footer className="flex-shrink-0 px-6 py-4">
          <motion.div
            className="flex items-center justify-center gap-2 text-zinc-600 text-xs"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6 }}
          >
            <span className="w-1 h-1 rounded-full bg-purple-500" />
            <span>NAVA Summit {new Date().getFullYear()}</span>
            <span className="w-1 h-1 rounded-full bg-pink-500" />
          </motion.div>
        </footer>
      </div>

      {/* Timeline Overlay */}
      <AnimatePresence>
        {showTimeline && currentEvent && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-zinc-950/95 backdrop-blur-sm"
          >
            <div className="h-full flex flex-col">
              {/* Header */}
              <div className="flex items-center justify-between px-4 py-4 border-b border-white/10">
                <div>
                  <h2 className="text-lg font-bold text-white">Programação</h2>
                  <p className="text-xs text-zinc-500">{currentEvent.name}</p>
                </div>
                <button
                  onClick={() => setShowTimeline(false)}
                  className="p-2 rounded-lg bg-white/5 border border-white/10 text-zinc-400 hover:text-white hover:bg-white/10 transition-all"
                >
                  <ChevronDown className="w-5 h-5" />
                </button>
              </div>

              {/* Scrollable timeline */}
              <div className="flex-1 overflow-y-auto px-4 py-6">
                <EventTimeline tracks={currentEvent.tracks} />
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
