'use client'

import { motion } from 'framer-motion'
import { Calendar, Clock, Mic2, Users, ChevronDown, ChevronUp } from 'lucide-react'
import { useState } from 'react'

interface Talk {
  id: string
  title: string
  speaker: string | null
  startTime: string | null
  endTime: string | null
  description: string | null
  attendanceCount: number
}

interface Track {
  id: string
  title: string
  startDate: string
  endDate: string
  talkCount: number
  attendanceCount: number
  talks: Talk[]
}

interface EventTimelineProps {
  tracks: Track[]
}

// Format time from ISO string (HH:MM) - use local timezone since times are entered locally
function formatTime(isoString: string | null): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleTimeString('pt-BR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Format date for display (weekday, day, month)
function formatDate(isoString: string): string {
  const date = new Date(isoString)
  return date.toLocaleDateString('pt-BR', {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    timeZone: 'UTC'
  })
}

// Format short date for talk (day month)
function formatShortDate(isoString: string | null): string {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'short',
    timeZone: 'UTC'
  }).toUpperCase()
}

// Format talk datetime: "02 DEZ às 17:50 - 19:00"
function formatTalkDateTime(startTime: string | null, endTime: string | null): string {
  if (!startTime && !endTime) return ''

  const dateStr = formatShortDate(startTime || endTime)
  const startTimeStr = formatTime(startTime)
  const endTimeStr = formatTime(endTime)

  if (startTimeStr && endTimeStr) {
    return `${dateStr} às ${startTimeStr} - ${endTimeStr}`
  } else if (startTimeStr) {
    return `${dateStr} às ${startTimeStr}`
  } else {
    return `${dateStr} até ${endTimeStr}`
  }
}

export function EventTimeline({ tracks }: EventTimelineProps) {
  const [expandedTracks, setExpandedTracks] = useState<Set<string>>(new Set(tracks.map(t => t.id)))

  const toggleTrack = (trackId: string) => {
    setExpandedTracks(prev => {
      const next = new Set(prev)
      if (next.has(trackId)) {
        next.delete(trackId)
      } else {
        next.add(trackId)
      }
      return next
    })
  }

  if (tracks.length === 0) return null

  return (
    <div className="w-full max-w-lg mx-auto">
      <div className="relative">
        {/* Vertical line */}
        <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gradient-to-b from-purple-500/50 via-pink-500/50 to-purple-500/50" />

        <div className="space-y-4">
          {tracks.map((track, trackIndex) => (
            <motion.div
              key={track.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: trackIndex * 0.1 }}
              className="relative"
            >
              {/* Track node */}
              <div className="absolute left-2 top-4 w-4 h-4 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 border-2 border-zinc-950 z-10" />

              {/* Track card */}
              <div className="ml-10">
                <button
                  onClick={() => toggleTrack(track.id)}
                  className="w-full text-left"
                >
                  <div className="p-4 rounded-xl bg-white/5 border border-white/10 backdrop-blur-sm hover:bg-white/10 transition-all">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 text-xs text-zinc-400 mb-1">
                          <Calendar className="w-3 h-3" />
                          <span>{formatDate(track.startDate)}</span>
                        </div>
                        <h3 className="text-lg font-semibold text-white mb-2">{track.title}</h3>
                        <div className="flex items-center gap-4 text-xs text-zinc-500">
                          <div className="flex items-center gap-1">
                            <Mic2 className="w-3 h-3" />
                            <span>{track.talkCount} {track.talkCount === 1 ? 'palestra' : 'palestras'}</span>
                          </div>
                          <div className="flex items-center gap-1">
                            <Users className="w-3 h-3" />
                            <span>{track.attendanceCount}</span>
                          </div>
                        </div>
                      </div>
                      <div className="text-zinc-500">
                        {expandedTracks.has(track.id) ? (
                          <ChevronUp className="w-5 h-5" />
                        ) : (
                          <ChevronDown className="w-5 h-5" />
                        )}
                      </div>
                    </div>
                  </div>
                </button>

                {/* Talks */}
                {expandedTracks.has(track.id) && track.talks.length > 0 && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    className="mt-2 ml-4 space-y-2"
                  >
                    {track.talks.map((talk, talkIndex) => (
                      <motion.div
                        key={talk.id}
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: talkIndex * 0.05 }}
                        className="relative"
                      >
                        {/* Talk connector line */}
                        <div className="absolute -left-4 top-5 w-4 h-0.5 bg-purple-500/30" />
                        <div className="absolute -left-4 top-3 w-2 h-2 rounded-full bg-purple-500/50 border border-purple-400/50" />

                        <div className="p-3 rounded-lg bg-zinc-900/50 border border-white/5">
                          <div className="space-y-2">
                            <p className="text-sm font-medium text-zinc-200">{talk.title}</p>
                            {talk.speaker && (
                              <p className="text-xs text-zinc-500">{talk.speaker}</p>
                            )}
                            {talk.description && (
                              <p className="text-xs text-zinc-400 leading-relaxed whitespace-pre-line">{talk.description}</p>
                            )}
                            <div className="flex items-center flex-wrap gap-2">
                              <div className="flex items-center gap-2 ml-auto">
                                {(talk.startTime || talk.endTime) && (
                                  <div className="flex items-center gap-1 text-xs text-pink-400 bg-pink-500/10 px-2 py-0.5 rounded-full">
                                    <Calendar className="w-3 h-3" />
                                    <span>{formatShortDate(talk.startTime || talk.endTime)}</span>
                                  </div>
                                )}
                                {(talk.startTime || talk.endTime) && (
                                  <div className="flex items-center gap-1 text-xs text-purple-400 bg-purple-500/10 px-2 py-0.5 rounded-full">
                                    <Clock className="w-3 h-3" />
                                    <span>
                                      {talk.startTime && talk.endTime
                                        ? `${formatTime(talk.startTime)} - ${formatTime(talk.endTime)}`
                                        : talk.startTime
                                          ? formatTime(talk.startTime)
                                          : `até ${formatTime(talk.endTime)}`
                                      }
                                    </span>
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </motion.div>
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  )
}
