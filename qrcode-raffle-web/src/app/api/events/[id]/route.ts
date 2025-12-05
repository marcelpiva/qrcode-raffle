import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// GET: Get event details with tracks and talks
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const event = await prisma.event.findUnique({
      where: { id },
      include: {
        tracks: {
          orderBy: { startDate: 'asc' },
          include: {
            talks: {
              orderBy: { startTime: 'asc' },
              include: {
                _count: { select: { attendances: true, raffles: true } },
                raffles: {
                  orderBy: { createdAt: 'desc' },
                  include: {
                    _count: { select: { participants: true } },
                    winner: true
                  }
                }
              }
            },
            _count: {
              select: { talks: true }
            }
          }
        },
        raffles: {
          orderBy: { createdAt: 'desc' },
          include: {
            _count: { select: { participants: true } },
            winner: true
          }
        },
        _count: {
          select: { tracks: true, raffles: true }
        }
      }
    })

    if (!event) {
      return NextResponse.json({ error: 'Event not found' }, { status: 404 })
    }

    // Calculate totals and unique attendees
    let totalAttendances = 0
    let totalRaffles = event._count.raffles
    const uniqueEmails = new Set<string>()

    const tracks = event.tracks.map(track => {
      let trackAttendances = 0
      let trackRaffles = 0

      const talks = track.talks.map(talk => {
        trackAttendances += talk._count.attendances
        trackRaffles += talk._count.raffles

        return {
          id: talk.id,
          title: talk.title,
          speaker: talk.speaker,
          startTime: talk.startTime?.toISOString() || null,
          endTime: talk.endTime?.toISOString() || null,
          description: talk.description,
          attendanceCount: talk._count.attendances,
          raffleCount: talk._count.raffles,
          raffles: talk.raffles.map(raffle => ({
            id: raffle.id,
            name: raffle.name,
            prize: raffle.prize,
            status: raffle.status,
            participantCount: raffle._count.participants,
            winner: raffle.winner ? {
              id: raffle.winner.id,
              name: raffle.winner.name,
              email: raffle.winner.email
            } : null
          }))
        }
      })

      totalAttendances += trackAttendances
      totalRaffles += trackRaffles

      return {
        id: track.id,
        title: track.title,
        startDate: track.startDate.toISOString(),
        endDate: track.endDate.toISOString(),
        talkCount: track._count.talks,
        attendanceCount: trackAttendances,
        raffleCount: trackRaffles,
        talks
      }
    })

    // Get unique attendee emails across all talks in the event
    const allAttendances = await prisma.talkAttendance.findMany({
      where: {
        talk: {
          track: {
            eventId: id
          }
        }
      },
      select: {
        email: true
      }
    })

    for (const attendance of allAttendances) {
      uniqueEmails.add(attendance.email.toLowerCase())
    }

    const uniqueAttendeeCount = uniqueEmails.size

    return NextResponse.json({
      id: event.id,
      name: event.name,
      startDate: event.startDate.toISOString(),
      endDate: event.endDate.toISOString(),
      speakers: event.speakers,
      createdAt: event.createdAt.toISOString(),
      updatedAt: event.updatedAt.toISOString(),
      trackCount: event._count.tracks,
      raffleCount: totalRaffles,
      attendanceCount: totalAttendances,
      uniqueAttendeeCount,
      tracks,
      raffles: event.raffles.map(raffle => ({
        id: raffle.id,
        name: raffle.name,
        prize: raffle.prize,
        status: raffle.status,
        participantCount: raffle._count.participants,
        winner: raffle.winner ? {
          id: raffle.winner.id,
          name: raffle.winner.name,
          email: raffle.winner.email
        } : null
      }))
    })
  } catch (error) {
    console.error('Error fetching event:', error)
    return NextResponse.json({ error: 'Failed to fetch event' }, { status: 500 })
  }
}

// PUT: Update event
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { name, startDate, endDate, speakers } = body

    const existing = await prisma.event.findUnique({ where: { id } })
    if (!existing) {
      return NextResponse.json({ error: 'Event not found' }, { status: 404 })
    }

    const updateData: Record<string, unknown> = {}

    if (name !== undefined) updateData.name = name
    if (speakers !== undefined) updateData.speakers = speakers || null

    if (startDate !== undefined) {
      const start = new Date(startDate)
      if (isNaN(start.getTime())) {
        return NextResponse.json({ error: 'Data de início inválida' }, { status: 400 })
      }
      updateData.startDate = start
    }

    if (endDate !== undefined) {
      const end = new Date(endDate)
      if (isNaN(end.getTime())) {
        return NextResponse.json({ error: 'Data de fim inválida' }, { status: 400 })
      }
      updateData.endDate = end
    }

    const event = await prisma.event.update({
      where: { id },
      data: updateData,
      include: {
        tracks: {
          orderBy: { startDate: 'asc' },
          include: {
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
      tracks: event.tracks.map(track => ({
        id: track.id,
        title: track.title,
        startDate: track.startDate.toISOString(),
        endDate: track.endDate.toISOString(),
        talkCount: track._count.talks
      }))
    })
  } catch (error) {
    console.error('Error updating event:', error)
    return NextResponse.json({ error: 'Failed to update event' }, { status: 500 })
  }
}

// DELETE: Remove event and all tracks (cascade)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const event = await prisma.event.findUnique({
      where: { id }
    })

    if (!event) {
      return NextResponse.json({ error: 'Event not found' }, { status: 404 })
    }

    await prisma.event.delete({
      where: { id }
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting event:', error)
    return NextResponse.json({ error: 'Failed to delete event' }, { status: 500 })
  }
}
