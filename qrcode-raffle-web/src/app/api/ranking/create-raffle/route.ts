import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const {
      name,
      prize,
      description,
      // Track-based selection (gets talks from tracks)
      sourceTrackIds,
      // Event-based selection (gets all talks from all tracks)
      sourceEventIds,
      // Filtering criteria
      minParticipation,
      requireAll,
      // Link to event or talk (optional)
      eventId,
      talkId
    } = body

    // Validations
    if (!name || !prize) {
      return NextResponse.json(
        { error: 'Nome e prêmio são obrigatórios' },
        { status: 400 }
      )
    }

    if (!sourceTrackIds?.length && !sourceEventIds?.length) {
      return NextResponse.json(
        { error: 'Selecione trilhas ou eventos para filtrar participantes' },
        { status: 400 }
      )
    }

    let trackIds: string[] = []

    // If event-based, get all tracks from those events
    if (sourceEventIds?.length) {
      const events = await prisma.event.findMany({
        where: { id: { in: sourceEventIds } },
        include: { tracks: { select: { id: true } } }
      })
      trackIds = events.flatMap(e => e.tracks.map(t => t.id))
    } else if (sourceTrackIds?.length) {
      trackIds = sourceTrackIds
    }

    if (trackIds.length === 0) {
      return NextResponse.json(
        { error: 'Nenhuma trilha encontrada nos eventos selecionados' },
        { status: 400 }
      )
    }

    // Get all talks from selected tracks
    const tracks = await prisma.track.findMany({
      where: { id: { in: trackIds } },
      include: { talks: { select: { id: true } } }
    })
    const talkIds = tracks.flatMap(t => t.talks.map(talk => talk.id))

    if (talkIds.length === 0) {
      return NextResponse.json(
        { error: 'Nenhuma palestra encontrada nas trilhas selecionadas' },
        { status: 400 }
      )
    }

    // Create a map from talkId to trackId
    const talkToTrack = new Map<string, string>()
    for (const track of tracks) {
      for (const talk of track.talks) {
        talkToTrack.set(talk.id, track.id)
      }
    }

    // Get attendances from talks in selected tracks
    const attendances = await prisma.talkAttendance.findMany({
      where: { talkId: { in: talkIds } },
      select: { email: true, name: true, talkId: true }
    })

    // Group by normalized email, counting unique tracks participated
    const emailMap = new Map<string, { name: string; originalEmail: string; trackIds: Set<string> }>()
    for (const a of attendances) {
      const normalizedEmail = normalizeEmail(a.email)
      const trackId = talkToTrack.get(a.talkId)
      if (!trackId) continue

      const existing = emailMap.get(normalizedEmail)
      if (existing) {
        existing.trackIds.add(trackId)
        existing.name = a.name
      } else {
        emailMap.set(normalizedEmail, {
          name: a.name,
          originalEmail: a.email,
          trackIds: new Set([trackId])
        })
      }
    }

    // Filter by participation criteria
    const minRequired = requireAll ? trackIds.length : (minParticipation || 1)
    const eligible = Array.from(emailMap.entries())
      .filter(([, data]) => data.trackIds.size >= minRequired)
      .map(([, data]) => ({ email: data.originalEmail, name: data.name }))

    if (eligible.length === 0) {
      return NextResponse.json(
        { error: 'Nenhum participante atende aos critérios de participação' },
        { status: 400 }
      )
    }

    // Verify optional linkages exist
    if (eventId) {
      const event = await prisma.event.findUnique({ where: { id: eventId } })
      if (!event) {
        return NextResponse.json({ error: 'Evento não encontrado' }, { status: 404 })
      }
    }
    if (talkId) {
      const talk = await prisma.talk.findUnique({ where: { id: talkId } })
      if (!talk) {
        return NextResponse.json({ error: 'Palestra não encontrada' }, { status: 404 })
      }
    }

    // Create CLOSED raffle with participants
    const raffle = await prisma.raffle.create({
      data: {
        name,
        prize,
        description: description || null,
        status: 'closed',
        closedAt: new Date(),
        eventId: eventId || null,
        talkId: talkId || null,
        participants: {
          create: eligible.map(p => ({ email: p.email, name: p.name }))
        }
      },
      include: { _count: { select: { participants: true } } }
    })

    return NextResponse.json({
      raffle: {
        id: raffle.id,
        name: raffle.name,
        prize: raffle.prize,
        status: raffle.status,
        participantCount: raffle._count.participants
      },
      participantsImported: eligible.length,
      message: `Sorteio criado com ${eligible.length} participantes`
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating raffle from ranking:', error)
    return NextResponse.json(
      { error: 'Falha ao criar sorteio' },
      { status: 500 }
    )
  }
}
