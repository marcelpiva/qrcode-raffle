import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        drawHistory: true
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    if (raffle.status !== 'drawn') {
      return NextResponse.json({ error: 'Raffle is not finalized' }, { status: 400 })
    }

    // Reset raffle: clear winner, delete draw history, set status to active
    const updatedRaffle = await prisma.$transaction(async (tx) => {
      // Delete all draw history
      await tx.drawHistory.deleteMany({
        where: { raffleId: id }
      })

      // Reset raffle
      return tx.raffle.update({
        where: { id },
        data: {
          status: 'active',
          winnerId: null,
          closedAt: null
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
