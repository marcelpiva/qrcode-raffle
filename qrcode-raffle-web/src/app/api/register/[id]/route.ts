import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { hashPin, isValidPin } from '@/lib/pin'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { name, email, pin } = body

    if (!name || !email) {
      return NextResponse.json(
        { error: 'Nome e email sao obrigatorios' },
        { status: 400 }
      )
    }

    // Check if raffle exists and is active
    const raffle = await prisma.raffle.findUnique({
      where: { id }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Sorteio nao encontrado' }, { status: 404 })
    }

    if (raffle.status !== 'active') {
      return NextResponse.json(
        { error: 'Este sorteio nao esta mais aceitando inscricoes' },
        { status: 400 }
      )
    }

    // For event raffles: check if link registration is allowed
    const isEventRaffle = raffle.eventId && !raffle.talkId
    if (isEventRaffle && !raffle.allowLinkRegistration) {
      return NextResponse.json(
        { error: 'Este sorteio nao aceita inscricoes por link. Participantes sao selecionados automaticamente.' },
        { status: 400 }
      )
    }

    // Check if registration is within schedule (startsAt/endsAt)
    const now = new Date()

    // Check if registration hasn't started yet
    if (raffle.startsAt && now < new Date(raffle.startsAt)) {
      return NextResponse.json(
        { error: 'As inscricoes ainda nao foram abertas' },
        { status: 400 }
      )
    }

    // Check if timebox has expired
    if (raffle.endsAt && now > new Date(raffle.endsAt)) {
      // Auto-close the raffle
      await prisma.raffle.update({
        where: { id },
        data: { status: 'closed', closedAt: new Date() }
      })
      return NextResponse.json(
        { error: 'O tempo para inscricoes expirou' },
        { status: 400 }
      )
    }

    // Check domain filter
    if (raffle.allowedDomain) {
      const emailDomain = email.split('@')[1]?.toLowerCase()
      const allowedDomain = raffle.allowedDomain.toLowerCase()

      if (emailDomain !== allowedDomain) {
        return NextResponse.json(
          { error: `Apenas e-mails @${raffle.allowedDomain} podem participar deste sorteio` },
          { status: 400 }
        )
      }
    }

    // Validate PIN if required
    if (raffle.requireConfirmation) {
      if (!pin) {
        return NextResponse.json(
          { error: 'Codigo de confirmacao e obrigatorio' },
          { status: 400 }
        )
      }
      if (!isValidPin(pin)) {
        return NextResponse.json(
          { error: 'Codigo deve ter exatamente 5 digitos numericos' },
          { status: 400 }
        )
      }
    }

    // Check if email already registered for this raffle
    const existingParticipant = await prisma.participant.findUnique({
      where: {
        email_raffleId: {
          email,
          raffleId: id
        }
      }
    })

    if (existingParticipant) {
      return NextResponse.json(
        { error: 'Este email ja esta inscrito neste sorteio' },
        { status: 400 }
      )
    }

    // Create participant
    const participant = await prisma.participant.create({
      data: {
        name,
        email,
        raffleId: id,
        pinHash: raffle.requireConfirmation && pin ? hashPin(pin) : null
      }
    })

    return NextResponse.json(participant, { status: 201 })
  } catch (error) {
    console.error('Error registering participant:', error)
    return NextResponse.json({ error: 'Erro ao registrar participante' }, { status: 500 })
  }
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        _count: {
          select: { participants: true }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Sorteio não encontrado' }, { status: 404 })
    }

    return NextResponse.json({
      id: raffle.id,
      name: raffle.name,
      description: raffle.description,
      prize: raffle.prize,
      status: raffle.status,
      allowedDomain: raffle.allowedDomain,
      participantCount: raffle._count.participants,
      // Schedule fields
      startsAt: raffle.startsAt,
      endsAt: raffle.endsAt,
      // PIN confirmation
      requireConfirmation: raffle.requireConfirmation,
      // Event raffle fields
      eventId: raffle.eventId,
      talkId: raffle.talkId,
      allowLinkRegistration: raffle.allowLinkRegistration
    })
  } catch (error) {
    console.error('Error fetching raffle info:', error)
    return NextResponse.json({ error: 'Erro ao buscar informações' }, { status: 500 })
  }
}
