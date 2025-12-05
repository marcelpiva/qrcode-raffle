import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// GET: Get talk details with attendances and raffles
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const talk = await prisma.talk.findUnique({
      where: { id },
      include: {
        track: {
          select: { id: true, title: true, startDate: true, endDate: true, eventId: true }
        },
        attendances: {
          orderBy: { name: 'asc' }
        },
        raffles: {
          orderBy: { createdAt: 'desc' },
          include: {
            _count: { select: { participants: true } },
            winner: true
          }
        },
        _count: {
          select: { attendances: true, raffles: true }
        }
      }
    })

    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    return NextResponse.json({
      id: talk.id,
      trackId: talk.trackId,
      track: {
        id: talk.track.id,
        title: talk.track.title,
        startDate: talk.track.startDate.toISOString(),
        endDate: talk.track.endDate.toISOString(),
        eventId: talk.track.eventId
      },
      title: talk.title,
      speaker: talk.speaker,
      startTime: talk.startTime?.toISOString() || null,
      endTime: talk.endTime?.toISOString() || null,
      description: talk.description,
      createdAt: talk.createdAt.toISOString(),
      attendanceCount: talk._count.attendances,
      raffleCount: talk._count.raffles,
      attendances: talk.attendances.map(a => ({
        id: a.id,
        name: a.name,
        email: a.email,
        createdAt: a.createdAt.toISOString()
      })),
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
    })
  } catch (error) {
    console.error('Error fetching talk:', error)
    return NextResponse.json({ error: 'Failed to fetch talk' }, { status: 500 })
  }
}

// PUT: Update talk
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { title, speaker, startTime, endTime, description } = body

    const existing = await prisma.talk.findUnique({ where: { id } })
    if (!existing) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    const updateData: Record<string, unknown> = {}

    if (title !== undefined) updateData.title = title
    if (speaker !== undefined) updateData.speaker = speaker || null
    if (description !== undefined) updateData.description = description || null

    if (startTime !== undefined) {
      if (startTime === null) {
        updateData.startTime = null
      } else {
        const parsedStartTime = new Date(startTime)
        if (isNaN(parsedStartTime.getTime())) {
          return NextResponse.json({ error: 'Horário de início inválido' }, { status: 400 })
        }
        updateData.startTime = parsedStartTime
      }
    }

    if (endTime !== undefined) {
      if (endTime === null) {
        updateData.endTime = null
      } else {
        const parsedEndTime = new Date(endTime)
        if (isNaN(parsedEndTime.getTime())) {
          return NextResponse.json({ error: 'Horário de fim inválido' }, { status: 400 })
        }
        updateData.endTime = parsedEndTime
      }
    }

    const talk = await prisma.talk.update({
      where: { id },
      data: updateData,
      include: {
        _count: {
          select: { attendances: true, raffles: true }
        }
      }
    })

    return NextResponse.json({
      id: talk.id,
      trackId: talk.trackId,
      title: talk.title,
      speaker: talk.speaker,
      startTime: talk.startTime?.toISOString() || null,
      endTime: talk.endTime?.toISOString() || null,
      description: talk.description,
      createdAt: talk.createdAt.toISOString(),
      attendanceCount: talk._count.attendances,
      raffleCount: talk._count.raffles
    })
  } catch (error) {
    console.error('Error updating talk:', error)
    return NextResponse.json({ error: 'Failed to update talk' }, { status: 500 })
  }
}

// DELETE: Remove talk and all attendances (cascade)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const talk = await prisma.talk.findUnique({ where: { id } })
    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    await prisma.talk.delete({ where: { id } })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting talk:', error)
    return NextResponse.json({ error: 'Failed to delete talk' }, { status: 500 })
  }
}
