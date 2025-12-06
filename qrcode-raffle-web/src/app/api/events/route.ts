import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

// GET: List all events with tracks, talks, and counts
export async function GET() {
  try {
    const events = await prisma.event.findMany({
      orderBy: { startDate: 'desc' },
      include: {
        tracks: {
          orderBy: { startDate: 'asc' },
          include: {
            talks: {
              orderBy: { startTime: 'asc' },
              include: {
                attendances: {
                  select: { email: true }
                },
                _count: {
                  select: { attendances: true, raffles: true }
                }
              }
            },
            _count: {
              select: { talks: true }
            }
          }
        },
        _count: {
          select: { tracks: true, raffles: true }
        }
      }
    })

    return NextResponse.json(events.map(event => {
      // Collect all unique emails across all talks in the event
      const uniqueEmails = new Set<string>()
      let totalRaffles = event._count.raffles // Event-level raffles

      const tracks = event.tracks.map(track => {
        // Collect unique emails for this track
        const trackUniqueEmails = new Set<string>()
        let trackRaffles = 0

        const talks = track.talks.map(talk => {
          // Add emails to both track and event sets (normalized)
          talk.attendances.forEach(a => {
            const normalized = normalizeEmail(a.email)
            uniqueEmails.add(normalized)
            trackUniqueEmails.add(normalized)
          })
          trackRaffles += talk._count.raffles
          return {
            id: talk.id,
            title: talk.title,
            speaker: talk.speaker,
            startTime: talk.startTime?.toISOString() || null,
            endTime: talk.endTime?.toISOString() || null,
            description: talk.description,
            attendanceCount: talk._count.attendances,
            raffleCount: talk._count.raffles
          }
        })

        totalRaffles += trackRaffles

        return {
          id: track.id,
          title: track.title,
          startDate: track.startDate.toISOString(),
          endDate: track.endDate.toISOString(),
          talkCount: track._count.talks,
          attendanceCount: trackUniqueEmails.size, // Unique per track
          raffleCount: trackRaffles,
          talks
        }
      })

      return {
        id: event.id,
        name: event.name,
        startDate: event.startDate.toISOString(),
        endDate: event.endDate.toISOString(),
        speakers: event.speakers,
        createdAt: event.createdAt.toISOString(),
        updatedAt: event.updatedAt.toISOString(),
        trackCount: event._count.tracks,
        raffleCount: totalRaffles,
        attendanceCount: uniqueEmails.size, // Unique per event
        tracks
      }
    }))
  } catch (error) {
    console.error('Error fetching events:', error)
    return NextResponse.json({ error: 'Failed to fetch events' }, { status: 500 })
  }
}

// POST: Create new event
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, startDate, endDate, speakers } = body

    if (!name || !startDate || !endDate) {
      return NextResponse.json(
        { error: 'Nome, data de início e data de fim são obrigatórios' },
        { status: 400 }
      )
    }

    const start = new Date(startDate)
    const end = new Date(endDate)

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return NextResponse.json(
        { error: 'Datas inválidas' },
        { status: 400 }
      )
    }

    if (end < start) {
      return NextResponse.json(
        { error: 'Data de fim deve ser igual ou posterior à data de início' },
        { status: 400 }
      )
    }

    const event = await prisma.event.create({
      data: {
        name,
        startDate: start,
        endDate: end,
        speakers: speakers || null
      },
      include: {
        _count: {
          select: { tracks: true, raffles: true }
        }
      }
    })

    return NextResponse.json({
      id: event.id,
      name: event.name,
      startDate: event.startDate.toISOString(),
      endDate: event.endDate.toISOString(),
      speakers: event.speakers,
      createdAt: event.createdAt.toISOString(),
      updatedAt: event.updatedAt.toISOString(),
      trackCount: event._count.tracks,
      raffleCount: event._count.raffles,
      attendanceCount: 0,
      tracks: []
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating event:', error)
    return NextResponse.json({ error: 'Failed to create event' }, { status: 500 })
  }
}
