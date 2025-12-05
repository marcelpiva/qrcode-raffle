import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// POST: Create new track
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { eventId, title, startDate, endDate } = body

    if (!eventId || !title || !startDate || !endDate) {
      return NextResponse.json(
        { error: 'Evento, título, data de início e data de fim são obrigatórios' },
        { status: 400 }
      )
    }

    // Verify event exists
    const event = await prisma.event.findUnique({ where: { id: eventId } })
    if (!event) {
      return NextResponse.json({ error: 'Evento não encontrado' }, { status: 404 })
    }

    // Parse dates - if only date string (no time), add noon to avoid timezone issues
    let trackStartDate = new Date(startDate)
    let trackEndDate = new Date(endDate)

    // If the date string doesn't include time info, it's interpreted as UTC midnight
    // which shifts to previous day in negative UTC offset timezones
    if (typeof startDate === 'string' && startDate.length === 10) {
      trackStartDate = new Date(`${startDate}T12:00:00`)
    }
    if (typeof endDate === 'string' && endDate.length === 10) {
      trackEndDate = new Date(`${endDate}T12:00:00`)
    }

    if (isNaN(trackStartDate.getTime())) {
      return NextResponse.json({ error: 'Data de início inválida' }, { status: 400 })
    }

    if (isNaN(trackEndDate.getTime())) {
      return NextResponse.json({ error: 'Data de fim inválida' }, { status: 400 })
    }

    const track = await prisma.track.create({
      data: {
        eventId,
        title,
        startDate: trackStartDate,
        endDate: trackEndDate
      },
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
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating track:', error)
    return NextResponse.json({ error: 'Failed to create track' }, { status: 500 })
  }
}
