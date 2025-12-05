import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Get the raffle with draw history
    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        winner: true,
        drawHistory: {
          orderBy: { drawNumber: 'desc' },
          take: 1,
          include: { participant: true }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    if (raffle.status === 'drawn') {
      return NextResponse.json({ error: 'Raffle already finalized' }, { status: 400 })
    }

    if (!raffle.winnerId || raffle.drawHistory.length === 0) {
      return NextResponse.json({ error: 'No draw has been made yet' }, { status: 400 })
    }

    const lastDraw = raffle.drawHistory[0]

    // Update the last draw history entry to mark as present and finalize raffle
    const [updatedDrawHistory, updatedRaffle] = await prisma.$transaction([
      prisma.drawHistory.update({
        where: { id: lastDraw.id },
        data: { wasPresent: true },
        include: { participant: true }
      }),
      prisma.raffle.update({
        where: { id },
        data: { status: 'drawn' },
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
      success: true,
      raffle: updatedRaffle,
      confirmedWinner: updatedDrawHistory.participant
    })
  } catch (error) {
    console.error('Error confirming winner:', error)
    return NextResponse.json({ error: 'Failed to confirm winner' }, { status: 500 })
  }
}
