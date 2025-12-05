import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// GET: Get track details with talks
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const track = await prisma.track.findUnique({
      where: { id },
      include: {
        event: {
          select: { id: true, name: true }
        },
        talks: {
          orderBy: { startTime: 'asc' },
          include: {
            _count: { select: { attendances: true, raffles: true } }
          }
        },
        _count: {
          select: { talks: true }
        }
      }
    })

    if (!track) {
      return NextResponse.json({ error: 'Track not found' }, { status: 404 })
    }

    return NextResponse.json({
      id: track.id,
      eventId: track.eventId,
      event: track.event,
      title: track.title,
      startDate: track.startDate.toISOString(),
      endDate: track.endDate.toISOString(),
      createdAt: track.createdAt.toISOString(),
      talkCount: track._count.talks,
      talks: track.talks.map(talk => ({
        id: talk.id,
        title: talk.title,
        speaker: talk.speaker,
        startTime: talk.startTime?.toISOString() || null,
        description: talk.description,
        createdAt: talk.createdAt.toISOString(),
        attendanceCount: talk._count.attendances,
        raffleCount: talk._count.raffles
      }))
    })
  } catch (error) {
    console.error('Error fetching track:', error)
    return NextResponse.json({ error: 'Failed to fetch track' }, { status: 500 })
  }
}

// PUT: Update track
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { title, startDate, endDate } = body

    const existing = await prisma.track.findUnique({ where: { id } })
    if (!existing) {
      return NextResponse.json({ error: 'Track not found' }, { status: 404 })
    }

    const updateData: Record<string, unknown> = {}

    if (title !== undefined) updateData.title = title

    if (startDate !== undefined) {
      // If only date string (no time), add noon to avoid timezone issues
      let trackStartDate = new Date(startDate)
      if (typeof startDate === 'string' && startDate.length === 10) {
        trackStartDate = new Date(`${startDate}T12:00:00`)
      }
      if (isNaN(trackStartDate.getTime())) {
        return NextResponse.json({ error: 'Data de início inválida' }, { status: 400 })
      }
      updateData.startDate = trackStartDate
    }

    if (endDate !== undefined) {
      // If only date string (no time), add noon to avoid timezone issues
      let trackEndDate = new Date(endDate)
      if (typeof endDate === 'string' && endDate.length === 10) {
        trackEndDate = new Date(`${endDate}T12:00:00`)
      }
      if (isNaN(trackEndDate.getTime())) {
        return NextResponse.json({ error: 'Data de fim inválida' }, { status: 400 })
      }
      updateData.endDate = trackEndDate
    }

    const track = await prisma.track.update({
      where: { id },
      data: updateData,
      include: {
        _count: {
          select: { talks: true }
        }
      }
    })

    return NextResponse.json({
      id: track.id,
      eventId: track.eventId,
      title: track.title,
      startDate: track.startDate.toISOString(),
      endDate: track.endDate.toISOString(),
      createdAt: track.createdAt.toISOString(),
      talkCount: track._count.talks
    })
  } catch (error) {
    console.error('Error updating track:', error)
    return NextResponse.json({ error: 'Failed to update track' }, { status: 500 })
  }
}

// DELETE: Remove track and all talks (cascade)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const track = await prisma.track.findUnique({ where: { id } })
    if (!track) {
      return NextResponse.json({ error: 'Track not found' }, { status: 404 })
    }

    await prisma.track.delete({ where: { id } })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting track:', error)
    return NextResponse.json({ error: 'Failed to delete track' }, { status: 500 })
  }
}
