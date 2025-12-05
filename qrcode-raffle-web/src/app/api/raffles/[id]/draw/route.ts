import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Get the raffle with participants and draw history
    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        participants: true,
        drawHistory: {
          include: { participant: true },
          orderBy: { drawNumber: 'asc' }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    if (raffle.status === 'drawn') {
      return NextResponse.json({ error: 'Raffle already drawn' }, { status: 400 })
    }

    // Get IDs of participants who were already drawn (and marked as absent)
    const alreadyDrawnIds = raffle.drawHistory.map(h => h.participantId)

    // Filter eligible participants (exclude those already drawn)
    const eligibleParticipants = raffle.participants.filter(
      p => !alreadyDrawnIds.includes(p.id)
    )

    if (eligibleParticipants.length === 0) {
      return NextResponse.json({
        error: 'No eligible participants remaining'
      }, { status: 400 })
    }

    // Random selection from eligible participants
    const randomIndex = Math.floor(Math.random() * eligibleParticipants.length)
    const winner = eligibleParticipants[randomIndex]

    // Calculate next draw number
    const nextDrawNumber = raffle.drawHistory.length + 1

    // Create draw history entry and update raffle in a transaction
    const [drawHistoryEntry, updatedRaffle] = await prisma.$transaction([
      // Create draw history entry (wasPresent defaults to false)
      prisma.drawHistory.create({
        data: {
          raffleId: id,
          participantId: winner.id,
          drawNumber: nextDrawNumber,
          wasPresent: false
        },
        include: { participant: true }
      }),
      // Update raffle with current winner (but don't mark as 'drawn' yet)
      prisma.raffle.update({
        where: { id },
        data: {
          winnerId: winner.id,
          closedAt: raffle.closedAt || new Date()
        },
        include: {
          winner: true,
          participants: true,
          drawHistory: {
            include: { participant: true },
            orderBy: { drawNumber: 'asc' }
          }
        }
      })
    ])

    return NextResponse.json({
      raffle: updatedRaffle,
      winner,
      allParticipants: raffle.participants,
      drawHistory: updatedRaffle.drawHistory,
      eligibleCount: eligibleParticipants.length - 1 // remaining after this draw
    })
  } catch (error) {
    console.error('Error drawing winner:', error)
    return NextResponse.json({ error: 'Failed to draw winner' }, { status: 500 })
  }
}
