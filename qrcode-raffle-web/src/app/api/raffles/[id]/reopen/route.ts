import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Check for mode parameter: 'registrations' to reopen registrations, default to reopen raffle (from drawn)
    const url = new URL(request.url)
    const mode = url.searchParams.get('mode') || 'raffle'

    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        drawHistory: true
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    // Mode: reopen registrations (closed -> active)
    if (mode === 'registrations') {
      if (raffle.status !== 'closed') {
        return NextResponse.json({ error: 'Raffle is not closed' }, { status: 400 })
      }

      const updatedRaffle = await prisma.raffle.update({
        where: { id },
        data: {
          status: 'active',
          closedAt: null
        },
        include: {
          participants: true,
          winner: true,
          _count: { select: { participants: true } }
        }
      })

      return NextResponse.json({
        success: true,
        raffle: updatedRaffle
      })
    }

    // Mode: reopen raffle (drawn -> closed, so user can draw again)
    // Also handle inconsistent state where status is 'closed' but has a winner
    const hasWinner = raffle.winnerId !== null
    if (raffle.status !== 'drawn' && !(raffle.status === 'closed' && hasWinner)) {
      return NextResponse.json({ error: 'Raffle is not finalized' }, { status: 400 })
    }

    // Reset raffle: clear winner, delete draw history, set status to closed (ready to draw again)
    const updatedRaffle = await prisma.$transaction(async (tx) => {
      // Delete all draw history
      await tx.drawHistory.deleteMany({
        where: { raffleId: id }
      })

      // Reset raffle to closed (ready to draw again)
      return tx.raffle.update({
        where: { id },
        data: {
          status: 'closed',
          winnerId: null
        },
        include: {
          participants: true,
          winner: true,
          _count: { select: { participants: true } }
        }
      })
    })

    return NextResponse.json({
      success: true,
      raffle: updatedRaffle
    })
  } catch (error) {
    console.error('Error reopening raffle:', error)
    return NextResponse.json({ error: 'Failed to reopen raffle' }, { status: 500 })
  }
}
