import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// POST: Create new talk
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { trackId, title, speaker, startTime, endTime, description } = body

    if (!trackId || !title) {
      return NextResponse.json(
        { error: 'Trilha e título são obrigatórios' },
        { status: 400 }
      )
    }

    // Verify track exists
    const track = await prisma.track.findUnique({ where: { id: trackId } })
    if (!track) {
      return NextResponse.json({ error: 'Trilha não encontrada' }, { status: 404 })
    }

    let parsedStartTime = null
    if (startTime) {
      parsedStartTime = new Date(startTime)
      if (isNaN(parsedStartTime.getTime())) {
        return NextResponse.json({ error: 'Horário de início inválido' }, { status: 400 })
      }
    }

    let parsedEndTime = null
    if (endTime) {
      parsedEndTime = new Date(endTime)
      if (isNaN(parsedEndTime.getTime())) {
        return NextResponse.json({ error: 'Horário de fim inválido' }, { status: 400 })
      }
    }

    const talk = await prisma.talk.create({
      data: {
        trackId,
        title,
        speaker: speaker || null,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        description: description || null
      },
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
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating talk:', error)
    return NextResponse.json({ error: 'Failed to create talk' }, { status: 500 })
  }
}
