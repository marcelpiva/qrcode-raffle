import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function GET() {
  try {
    const raffles = await prisma.raffle.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { participants: true }
        },
        winner: true,
        talk: {
          select: {
            id: true,
            title: true,
            track: { select: { id: true, title: true, eventId: true } }
          }
        },
        event: {
          select: { id: true, name: true }
        }
      }
    })
    return NextResponse.json(raffles)
  } catch (error) {
    console.error('Error fetching raffles:', error)
    return NextResponse.json({ error: 'Failed to fetch raffles' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, description, prize, allowedDomain, startsAt, endsAt, autoDrawOnEnd, requireConfirmation, confirmationTimeoutMinutes, eventId, talkId, minDurationMinutes, minTalksCount, allowLinkRegistration } = body

    if (!name || !prize) {
      return NextResponse.json(
        { error: 'Name and prize are required' },
        { status: 400 }
      )
    }

    const raffle = await prisma.raffle.create({
      data: {
        name,
        description: description || null,
        prize,
        allowedDomain: allowedDomain || null,
        startsAt: startsAt ? new Date(startsAt) : null,
        endsAt: endsAt ? new Date(endsAt) : null,
        autoDrawOnEnd: autoDrawOnEnd || false,
        requireConfirmation: requireConfirmation || false,
        confirmationTimeoutMinutes: confirmationTimeoutMinutes || null,
        eventId: eventId || null,
        talkId: talkId || null,
        minDurationMinutes: minDurationMinutes || null,
        minTalksCount: minTalksCount || null,
        allowLinkRegistration: allowLinkRegistration || false
      }
    })

    // For event-type raffles, auto-populate eligible participants
    if (eventId && !talkId) {
      const minDuration = minDurationMinutes || 0
      const minTalks = minTalksCount || 1

      // Get all attendances for this event
      const attendances = await prisma.talkAttendance.findMany({
        where: {
          talk: {
            track: {
              eventId
            }
          }
        },
        select: {
          name: true,
          email: true,
          talkId: true,
          duration: true
        }
      })

      // Group by email -> { name, talkId -> duration }
      const emailData: Map<string, { name: string; talkDurations: Map<string, number> }> = new Map()

      for (const attendance of attendances) {
        const emailLower = attendance.email.toLowerCase()

        if (!emailData.has(emailLower)) {
          emailData.set(emailLower, {
            name: attendance.name,
            talkDurations: new Map()
          })
        }

        const data = emailData.get(emailLower)!
        const currentDuration = data.talkDurations.get(attendance.talkId) || 0
        data.talkDurations.set(attendance.talkId, currentDuration + (attendance.duration || 0))
      }

      // Find eligible participants
      const eligibleParticipants: { name: string; email: string }[] = []

      for (const [email, data] of emailData) {
        // Count talks where person stayed >= minDuration
        let qualifyingTalks = 0

        for (const [, duration] of data.talkDurations) {
          if (duration >= minDuration) {
            qualifyingTalks++
          }
        }

        // Person is eligible if they have enough qualifying talks
        if (qualifyingTalks >= minTalks) {
          // Apply domain filter if set
          if (allowedDomain) {
            const emailDomain = email.split('@')[1]?.toLowerCase()
            if (emailDomain !== allowedDomain.toLowerCase()) {
              continue
            }
          }
          eligibleParticipants.push({ name: data.name, email })
        }
      }

      // Create participants
      if (eligibleParticipants.length > 0) {
        await prisma.participant.createMany({
          data: eligibleParticipants.map(p => ({
            raffleId: raffle.id,
            name: p.name,
            email: p.email
          }))
        })
      }
    }

    // Return raffle with participant count
    const raffleWithCount = await prisma.raffle.findUnique({
      where: { id: raffle.id },
      include: {
        _count: { select: { participants: true } }
      }
    })

    return NextResponse.json(raffleWithCount, { status: 201 })
  } catch (error) {
    console.error('Error creating raffle:', error)
    return NextResponse.json({ error: 'Failed to create raffle' }, { status: 500 })
  }
}
